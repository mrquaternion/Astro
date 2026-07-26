//
//  LearnViewModel.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-08.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class LearnViewModel: ObservableObject {
    /// Persistent storage used for learned-asset metadata and files.
    private let dataController: DataController
    /// Subscription state used to gate premium learning content.
    private let subscriptionManager: SubscriptionManager
    
    /// The array of ready-to-use `CachedLearnAsset` in the views.
    @Published var assets: [CachedLearnAsset] = []
    
    /// The current state of assets loading.
    @Published private(set) var areLearnAssetsLoading = false
    
    /// The current state of asset loading.
    @Published private(set) var isComponentLoading = false
    
    /// The message to display when loading an asset (download or local cache).
    @Published private(set) var loadingMessage : String?
    
    /// Controls presentation of the paywall for locked `LearnAsset`.
    @Published var showPaywall = false
    
    /// The error to display on screen.
    @Published var error: Error?
    
    init(dataController: DataController, subscriptionManager: SubscriptionManager) {
        self.dataController = dataController
        self.subscriptionManager = subscriptionManager
    }
    
    /// Saves the asset metadata and its data to the model context on-disk (available when user is an active subscriber).
    func saveOffline(for asset: CachedLearnAsset, downloadManager: LocalDownloadManager) async throws {
        guard SubscriptionHelper.isEligibleTo(.offlineDownload, with: subscriptionManager) else {
            error = AstroError.noActiveSubscription
            showPaywall = true
            return
        }
        
        try await Task.sleep(for: .seconds(1.5))
        
        // save the asset
        try dataController.save(asset) // instantaneous
        downloadManager.setProgress(0.05, for: asset.id)
        
        var seenComponentIds = Set<String>()
        let components = ([asset.defaultComponent] + asset.components).filter { component in
            seenComponentIds.insert(component.componentId).inserted
        }
        
        for (index, component) in components.enumerated() {
            let componentProgressStart = 0.05 + (0.95 * CGFloat(index) / CGFloat(components.count))
            let componentProgressSize = 0.95 / CGFloat(components.count)
            
            let (modelData, modelPath) = try await AssetFileLoader.dataAndCacheURLWithProgress(
                storagePath: component.modelStoragePath,
                filename: component.modelFilename,
                onProgress: { modelProgress in
                    Task { @MainActor in
                        downloadManager.setProgress(componentProgressStart + (componentProgressSize * modelProgress), for: asset.id)
                    }
                }
            )
            try dataController.saveFile(data: modelData, at: modelPath) // instantaneous
        }
        
        asset.isDownloadedLocally = true
        downloadManager.setProgress(1, for: asset.id)
        try dataController.saveChanges()
        
        try await Task.sleep(for: .seconds(1.5))
    }
    
    /// Fetches all assets metadata to display in the view.
    func fetchAssetsMetadata(networkMonitor: NetworkMonitor) async throws {
        areLearnAssetsLoading = true
        defer { areLearnAssetsLoading = false }
        
        let localAssets = try dataController.fetchSaved(CachedLearnAsset.self)
        let localById = Dictionary(uniqueKeysWithValues: localAssets.map({ ($0.id, $0) }))
        
        // no connection? take only local assets
        // P.S.: non-subs will have nothing since they can't download in the first place
        guard networkMonitor.isConnected else {
            self.assets = localAssets
            return
        }
        
        do {
            let collection = try await LearnAssetFeatureCollection.fetchAssets()
            
            var remoteAssets: [CachedLearnAsset] = []
            var didUpdateLocalAssets = false
            
            for feature in collection.features {
                let properties = feature.properties
                
                if let local = localById[properties.id] {
                    let hasChanges = local.updatedAt != properties.updatedAt
                    
                    if hasChanges {
                        local.defaultComponent = makeComponent(from: properties.defaultComponent)
                        local.components = properties.components.map(makeComponent)
                        local.updatedAt = properties.updatedAt
                        
                        if local.isDownloadedLocally {
                            try await refreshDownloadedFiles(for: local)
                        }
                        
                        didUpdateLocalAssets = true
                    }
                    
                    local.defaultComponent.snapImageData = try await AssetFileLoader.data(storagePath: local.defaultComponent.snapStoragePath)
                    remoteAssets.append(local)
                    continue
                }
                
                let asset = makeAsset(from: properties)
                asset.defaultComponent.snapImageData = try await AssetFileLoader.data(storagePath: asset.defaultComponent.snapStoragePath)
                
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
    
    /// Loads the model data for a `CachedLearnAsset.LearnComponent`.
    func loadModelData(
        for component: CachedLearnAsset.LearnComponent,
        from asset: CachedLearnAsset
    ) async throws -> Data {
        isComponentLoading = true
        defer { isComponentLoading = false }
        
        if
            asset.isDownloadedLocally,
            let modelURL = AssetLoadingHelpers.getPathOfAssetAsURL(filename: component.modelFilename),
            FileManager.default.fileExists(atPath: modelURL.path)
        {
            return try Data(contentsOf: modelURL)
        }

        // Fallback to remote storage when the local file is unavailable.
        guard let (modelPath, modelBucket) = AssetLoadingHelpers.parseStoragePath(component.modelStoragePath) else {
            throw BootstrapError.missingRequiredData
        }
        
        return try await SupabaseService.shared.fetchAssetData(modelPath, in: modelBucket)
    }
    
    private func refreshDownloadedFiles(for asset: CachedLearnAsset) async throws {
        var seenComponentIds = Set<String>()
        let components = ([asset.defaultComponent] + asset.components).filter { component in
            seenComponentIds.insert(component.componentId).inserted
        }
        
        for component in components {
            let (modelData, modelPath) = try await AssetFileLoader.dataAndCacheURL(
                storagePath: component.modelStoragePath,
                filename: component.modelFilename
            )
            
            try dataController.saveFile(data: modelData, at: modelPath)
        }
    }
    
    private func makeAsset(from properties: LearnAssetFeatureCollection.Feature.Properties) -> CachedLearnAsset {
        CachedLearnAsset(
            id: properties.id,
            defaultComponent: makeComponent(from: properties.defaultComponent),
            components: properties.components.map(makeComponent),
            updatedAt: properties.updatedAt
        )
    }
    
    private func makeComponent(from component: LearnAssetFeatureCollection.Component) -> CachedLearnAsset.LearnComponent {
        CachedLearnAsset.LearnComponent(
            componentId: component.componentId,
            modelFilename: component.modelFileName,
            snapFilename: component.snapFileName,
            modelStoragePath: component.modelStoragePath,
            snapStoragePath: component.snapStoragePath,
            shortName: component.shortName,
            displayName: component.displayName,
            category: component.category,
            group: component.group,
            agencies: component.agencies,
            manufacturers: component.manufacturers,
            materials: component.materials,
            timeline: component.timeline.map {
                CachedLearnAsset.LearnComponentTimelineEvent(date: $0.date, event: $0.event)
            },
            details: component.details.map {
                CachedLearnAsset.LearnComponentDetail(title: $0.title, body: $0.body)
            },
            summary: component.summary,
            sourceIds: component.sourceIds
        )
    }
}
