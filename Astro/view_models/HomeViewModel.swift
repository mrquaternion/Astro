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
import CoreLocation
import simd

@MainActor
final class HomeViewModel: ObservableObject {
    /// Persistent storage used for tracked-asset metadata.
    private let dataController: DataController
    /// Subscription state used to gate premium assets.
    private let subscriptionManager: SubscriptionManager
    
    /// The array of ready-to-use `CachedTrackedAsset` in the views.
    @Published var assets: [CachedTrackedAsset] = []
    
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
    func saveOffline(for asset: CachedTrackedAsset, downloadManager: LocalDownloadManager) async throws {
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
        let (modelData, modelPath) = try await AssetFileLoader.dataAndCacheURLWithProgress(
            storagePath: asset.modelStoragePath,
            filename: asset.modelFilename,
            onProgress: { modelProgress in
                Task { @MainActor in
                    downloadManager.setProgress(0.05 + (0.45 * modelProgress), for: asset.id)
                }
            }
        )
        try dataController.saveFile(data: modelData, at: modelPath) // instantaneous
        
        // save its most recent tle
        let (tleData, tlePath) = try await AssetFileLoader.dataAndCacheURLWithProgress(
            storagePath: asset.tleStoragePath,
            filename: asset.tleFilename,
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
    
    /// Fetches all assets metadata to display in the view.
    func fetchAssetsMetadata(networkMonitor: NetworkMonitor) async throws {
        let localAssets = try dataController.fetchSaved(CachedTrackedAsset.self)
        let localById = Dictionary(uniqueKeysWithValues: localAssets.map({ ($0.id, $0) }))
        
        // no connection? take only local assets
        // P.S.: non-subs will have nothing since they can't download in the first place
        guard networkMonitor.isConnected else {
            self.assets = localAssets
            return
        }
        
        do {
            let collection = try await TrackedAssetFeatureCollection.fetchAssets()
            
            var remoteAssets: [CachedTrackedAsset] = []
            var didUpdateLocalAssets = false
            
            for feature in collection.features {
                let properties = feature.properties
                
                if let local = localById[properties.id] {
                    // in case paths or filenames changes
                    let hasChanges =
                    local.displayName != properties.name ||
                    local.summary != properties.summary ||
                    local.modelFilename != properties.modelFileName ||
                    local.tleFilename != properties.tleFileName ||
                    local.snapFilename != properties.snapFileName ||
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
                        local.displayName = properties.name
                        local.summary = properties.summary
                        local.modelFilename = properties.modelFileName
                        local.tleFilename = properties.tleFileName
                        local.snapFilename = properties.snapFileName
                        local.modelStoragePath = properties.modelStoragePath
                        local.tleStoragePath = properties.tleStoragePath
                        local.snapStoragePath = properties.snapStoragePath
                        local.updatedAt = .now
                        
                        didUpdateLocalAssets = true
                    }
                    
                    remoteAssets.append(local)
                    continue
                }
                
                let asset = makeAsset(from: properties)
                asset.snapImageData = try await AssetFileLoader.data(storagePath: asset.snapStoragePath)
                
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
        let (modelData, modelPath) = try await AssetFileLoader.dataAndCacheURL(
            storagePath: modelStoragePath,
            filename: modelFileName
        )
        let (tleData, tlePath) = try await AssetFileLoader.dataAndCacheURL(
            storagePath: tleStoragePath,
            filename: tleFileName
        )
        
        try dataController.saveFile(data: modelData, at: modelPath)
        try dataController.saveFile(data: tleData, at: tlePath)
    }
    
    /// Loads the `CachedTrackedAsset` and assign it with its data to the `@Published` selected satellite.
    func loadAsset(for asset: CachedTrackedAsset) async {
        isAssetLoading = true
        defer { isAssetLoading = false }
        
        do {
            var modelData: Data
            var tleElements: Elements
            
            // load asset and its data if downloaded
            if
                asset.isDownloadedLocally,
                let modelURL = AssetLoadingHelpers.getPathOfAssetAsURL(filename: asset.modelFilename),
                let tleURL = AssetLoadingHelpers.getPathOfAssetAsURL(filename: asset.tleFilename),
                FileManager.default.fileExists(atPath: modelURL.path),
                FileManager.default.fileExists(atPath: tleURL.path)
            {
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
                name: asset.displayName,
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
    
    private func makeAsset(from properties: TrackedAssetFeatureCollection.Feature.Properties) -> CachedTrackedAsset {
        CachedTrackedAsset(
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
    }
}

/// Structure defining the user's selected satellite and its relative information useful for
/// displaying it in the Mapbox map.
struct SelectedSatellite {
    /// Stable identifier of the selected satellite.
    let id: String
    /// User-facing satellite name.
    let name: String
    /// Data URI used to load the satellite model.
    let modelUri: String
    /// Orbital elements used to propagate the satellite position.
    let elements: Elements
    /// Precomputed route displayed on the map.
    let route: Model3DRoute
    
    /// Abbreviated name used in compact interfaces.
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

extension HomeViewModel {
    func routeFromUser(from model: Model3D) -> ProximityRoute? {
        guard let currentUserLocation = LocalizationManager.shared.location else { return nil }
        
        var points: [[Double]] = []
        points.append([model.position[0], model.position[1]])
        
        // step 1
        let p0 = GeoMaths.geodeticToUnitSphere(
            p: CLLocationCoordinate2D(latitude: model.position[1], longitude: model.position[0]),
            h: model.altitude
        )
        let p1 = GeoMaths.geodeticToUnitSphere(p: currentUserLocation.coordinate, h: 0)
        
        // step 2
        /*
         let pathDirection = GeoMaths.bearing(
             lat1: model.position[1], lon1: model.position[0],
             lat2: currentUserLocation.coordinate.latitude, lon2: currentUserLocation.coordinate.longitude
         )
         var diff = abs(pathDirection - model.bearing).truncatingRemainder(dividingBy: 360)
         if diff > 180 { diff = 360 - diff }
         */
        
        // step 3
        let s = 0.0
        let f = 1.0
        var midpoint: [Double]?
        var pathDirection: Double?
        var shouldCaptureNext = false
        for t in stride(from: s, to: f, by: 0.01) {
            let slerp = GeoMaths.slerp(p0: p0, p1: p1, t: t)
            let out = GeoMaths.unitSphereToGeodetic(p: slerp)
            
            if shouldCaptureNext, let midpoint {
                pathDirection = GeoMaths.bearing(
                    lat1: midpoint[1], lon1: midpoint[0],
                    lat2: out.y, lon2: out.x
                )
                shouldCaptureNext = false
            }
            
            if abs(t - (s + f) / 2) < 0.005 {
                midpoint = [out.x, out.y]
                shouldCaptureNext = true
            }
            points.append([out.x, out.y])
        }
        
        points.append([currentUserLocation.coordinate.longitude, currentUserLocation.coordinate.latitude])
        
        return ProximityRoute(
            coordinates: points,
            midpoint: midpoint,
            midpointBearing: pathDirection,
            label: distanceFromUser(from: points)
        )
    }
    
    private func distanceFromUser(from points: [[Double]]?) -> String? {
        guard let points else { return nil }
        
        var totalDistance: Double = 0
        for i in 0..<(points.count - 1) {
            let distance = GeoMaths.haversine(
                p1: CLLocationCoordinate2D(latitude: points[i][1], longitude: points[i][0]),
                p2: CLLocationCoordinate2D(latitude: points[i+1][1], longitude: points[i+1][0])
            )
            
            totalDistance += distance
        }
        
        totalDistance /= 1000
    
        return String(format: "%.1f km", totalDistance)
    }
}

struct ProximityRoute {
    /// Coordinates forming the visible proximity route.
    var coordinates: [[Double]]?
    /// Coordinate at the middle of the route.
    var midpoint: [Double]?
    /// Bearing of the route at its midpoint.
    var midpointBearing: Double?
    /// Optional label displayed for the route.
    var label: String?
}
