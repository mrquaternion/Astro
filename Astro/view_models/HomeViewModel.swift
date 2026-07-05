//
//  HomeViewModel.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-07.
//

import Foundation
import Combine
import SatelliteKit
import SwiftData
import SystemConfiguration

@MainActor
final class HomeViewModel: ObservableObject {
    private let dataController: DataController
    private let subscriptionManager: SubscriptionManager
    
    /// The array of ready-to-use `CachedAsset` in the views.
    @Published var assets: [CachedAsset] = []
    
    /// The satellite currently displayed on the map.
    @Published var selectedSatellite: SelectedSatellite?
    
    /// The current state of asset loading.
    @Published private(set) var isAssetLoading = false
    
    /// The message to display when loading an asset (download or local cache).
    @Published private(set) var loadingMessage : String?
    
    /// Controls presentation of the paywall for locked satellites.
    @Published var showPaywall = false
    
    /// The error to display on screen.
    @Published var error: Error?
    
    init(dataController: DataController, subscriptionManager: SubscriptionManager) {
        self.dataController = dataController
        self.subscriptionManager = subscriptionManager
    }
    
    /// Saves the asset metadata and its data to the model context on-disk (available when user is an active subscriber).
    func saveOffline(for asset: CachedAsset, downloadManager: LocalDownloadManager) async throws {
        guard SubscriptionHelper.isEligibleTo(.offlineDownload, with: subscriptionManager) else {
            error = AstroError.noActiveSubscription
            showPaywall = true
            return
        }
        
        try await Task.sleep(for: .seconds(1.5))
        
        // save the asset
        try dataController.save(asset) // instantaneous
        downloadManager.setProgress(0.05, for: asset.id)
        
        
        // save its model
        let (modelData, modelPath) = try await getAssetModelDataAndPathWithProgress(
            storagePath: asset.modelStoragePath,
            filename: asset.modelFileName,
            onProgress: { modelProgress in
                Task { @MainActor in
                    downloadManager.setProgress(0.05 + (0.45 * modelProgress), for: asset.id)
                }
            }
        )
        try dataController.saveFile(data: modelData, at: modelPath) // instantaneous
        
        // save its most recent tle
        let (tleData, tlePath) = try await getAssetModelDataAndPathWithProgress(
            storagePath: asset.tleStoragePath,
            filename: asset.tleFileName,
            onProgress: { tleProgress in
                Task { @MainActor in
                    downloadManager.setProgress(0.5 + (0.45 * tleProgress), for: asset.id)
                }
            }
        )
        try dataController.saveFile(data: tleData, at: tlePath) // instantaneous
        
        asset.isDownloadedLocally = true
        downloadManager.setProgress(1, for: asset.id)
        
        try await Task.sleep(for: .seconds(1.5))
    }
    
    /// Fetches the files relative to an asset as data while updating the progress of the "download".
    private func getAssetModelDataAndPathWithProgress(storagePath: String, filename: String, onProgress: @escaping (Double) -> Void) async throws -> (Data, URL) {
        guard let (filepath, bucket) = AssetLoadingHelpers.parseStoragePath(storagePath) else {
            throw URLError(.cannotCreateFile)
        }
        
        let data = try await SupabaseService.shared.fetchDataWithProgress(
            filepath,
            in: bucket,
            onProgress: onProgress
        )
        
        guard let path = AssetLoadingHelpers.getPathOfAssetAsURL(filename: filename) else { throw URLError(.badURL) }
        
        return (data, path)
    }
    
    /// Fetches all assets metadata to display in the view.
    func fetchAssetsMetadata(networkMonitor: NetworkMonitor) async throws {
        let localAssets = try dataController.fetchSaved(CachedAsset.self)
        let localById = Dictionary(uniqueKeysWithValues: localAssets.map({ ($0.id, $0) }))
        
        // no connection? take only local assets
        // P.S.: non-subs will have nothing since they can't download in the first place
        guard networkMonitor.isConnected else {
            self.assets = localAssets
            return
        }
        
        do {
            let collection = try await AssetFeatureCollection.fetchAssets()
            
            var remoteAssets: [CachedAsset] = []
            var didUpdateLocalAssets = false
            
            for feature in collection.features {
                let properties = feature.properties
                
                if let local = localById[properties.id] {
                    // in case paths or filenames changes
                    let hasChanges =
                    local.name != properties.name ||
                    local.summary != properties.summary ||
                    local.modelFileName != properties.modelFileName ||
                    local.tleFileName != properties.tleFileName ||
                    local.snapFileName != properties.snapFileName ||
                    local.modelStoragePath != properties.modelStoragePath ||
                    local.tleStoragePath != properties.tleStoragePath ||
                    local.snapStoragePath != properties.snapStoragePath
                    
                    // if any change, then update "updateAt" property
                    if local.isDownloadedLocally {
                        try await refreshDownloadedFiles(
                            modelStoragePath: properties.modelStoragePath,
                            modelFileName: properties.modelFileName,
                            tleStoragePath: properties.tleStoragePath,
                            tleFileName: properties.tleFileName
                        )
                    }
                    
                    if hasChanges {
                        local.name = properties.name
                        local.summary = properties.summary
                        local.modelFileName = properties.modelFileName
                        local.tleFileName = properties.tleFileName
                        local.snapFileName = properties.snapFileName
                        local.modelStoragePath = properties.modelStoragePath
                        local.tleStoragePath = properties.tleStoragePath
                        local.snapStoragePath = properties.snapStoragePath
                        local.updatedAt = .now
                        
                        didUpdateLocalAssets = true
                    }
                    
                    remoteAssets.append(local)
                    continue
                }
                
                let asset = CachedAsset(
                    id: properties.id,
                    name: properties.name,
                    summary: properties.summary,
                    modelFileName: properties.modelFileName,
                    tleFileName: properties.tleFileName,
                    snapFileName: properties.snapFileName,
                    modelStoragePath: properties.modelStoragePath,
                    tleStoragePath: properties.tleStoragePath,
                    snapStoragePath: properties.snapStoragePath,
                    updatedAt: properties.updatedAt
                )
                
                // Snapshot image
                if let (filepath, bucket) = AssetLoadingHelpers.parseStoragePath(asset.snapStoragePath) {
                    asset.snapImageData = try await SupabaseService.shared.fetchAssetData(filepath, in: bucket)
                }
                
                remoteAssets.append(asset)
            }
            
            if didUpdateLocalAssets {
                try dataController.saveChanges()
            }
            
            self.assets = remoteAssets
        } catch {
            // connectivity may disappear after the monitor check.
            self.assets = localAssets
            
            if localAssets.isEmpty {
                throw error
            }
        }
    }
    
    private func refreshDownloadedFiles(
        modelStoragePath: String,
        modelFileName: String,
        tleStoragePath: String,
        tleFileName: String
    ) async throws {
        let (modelData, modelPath) = try await getAssetModelDataAndPath(
            storagePath: modelStoragePath,
            filename: modelFileName
        )
        let (tleData, tlePath) = try await getAssetModelDataAndPath(
            storagePath: tleStoragePath,
            filename: tleFileName
        )
        
        try dataController.saveFile(data: modelData, at: modelPath)
        try dataController.saveFile(data: tleData, at: tlePath)
    }
    
    private func getAssetModelDataAndPath(storagePath: String, filename: String) async throws -> (Data, URL) {
        guard let (filepath, bucket) = AssetLoadingHelpers.parseStoragePath(storagePath) else {
            throw URLError(.cannotCreateFile)
        }
        
        let data = try await SupabaseService.shared.fetchAssetData(filepath, in: bucket)
        
        guard let path = AssetLoadingHelpers.getPathOfAssetAsURL(filename: filename) else {
            throw URLError(.badURL)
        }
        
        return (data, path)
    }
    
    /// Loads the `CachedAsset` and assign it with its data to the `@Published` selected satellite.
    func loadAsset(for asset: CachedAsset) async {
        isAssetLoading = true
        defer { isAssetLoading = false }
        
        do {
            var modelData: Data
            var tleElements: Elements
            
            // load asset and its data if downloaded
            if asset.isDownloadedLocally,
               let modelURL = AssetLoadingHelpers.getPathOfAssetAsURL(filename: asset.modelFileName),
               let tleURL = AssetLoadingHelpers.getPathOfAssetAsURL(filename: asset.tleFileName),
               FileManager.default.fileExists(atPath: modelURL.path),
               FileManager.default.fileExists(atPath: tleURL.path) {
                modelData = try Data(contentsOf: modelURL)
                let tleData = try Data(contentsOf: tleURL)
                tleElements = try AssetLoadingHelpers.decodeTLE(data: tleData)
            } else { // fallback to wifi if network available
                guard let (modelPath, modelBucket) =
                        AssetLoadingHelpers.parseStoragePath(asset.modelStoragePath),
                      let (tlePath, tleBucket) =
                        AssetLoadingHelpers.parseStoragePath(asset.tleStoragePath)
                else {
                    throw BootstrapError.missingRequiredData
                }
                
                modelData = try await SupabaseService.shared.fetchAssetData(modelPath, in: modelBucket)
                tleElements = try await SupabaseService.shared.fetchTLEJson(tlePath, in: tleBucket)
            }
            
            // update the selected satellite
            selectedSatellite = SelectedSatellite(
                id: asset.id,
                name: asset.name,
                modelUri: try AssetLoadingHelpers.computeDataUri(
                    data: modelData,
                    id: asset.id
                ),
                elements: tleElements,
                route: try AssetLoadingHelpers.computeRoute(elements: tleElements)
            )
        } catch {
            print(error)
        }
    }
}

/// Structure defining the user's selected satellite and its relative information useful for
/// displaying it in the Mapbox map.
struct SelectedSatellite {
    let id: String
    let name: String
    let modelUri: String
    let elements: Elements
    let route: Model3DRoute
    
    var shortName: String {
        guard
            let openingParenthesis = name.firstIndex(of: "("),
            let closingParenthesis = name[openingParenthesis...].firstIndex(of: ")"),
            openingParenthesis < closingParenthesis
        else {
            return name
        }
        
        let shortName = name[name.index(after: openingParenthesis)..<closingParenthesis]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return shortName.isEmpty ? name : shortName
    }
}

enum AstroError: LocalizedError {
    case noWifiConnection
    case noActiveSubscription
    case unableToFetchProducts(message: String)
    case unableToRestorePurchases(message: String)
    
    var description: String {
        switch self {
        case .noWifiConnection: "No internet connection available."
        case .noActiveSubscription : "Can't perform this action, no subscription active."
        case .unableToFetchProducts(let message): "Unable to fetch products: \(message)"
        case .unableToRestorePurchases(let message): "Unable to restore purchases: \(message)"
        }
    }
    
    var symbol: String {
        switch self {
        case .noWifiConnection: "wifi.slash"
        case .noActiveSubscription: "arrow.down.circle.badge.xmark"
        case .unableToFetchProducts(_): "cart.badge.questionmark"
        case .unableToRestorePurchases(_): "storefront"
        }
    }
}
