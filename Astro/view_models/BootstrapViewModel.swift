//
//  BootstrapViewModel.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-05.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class BootstrapViewModel: ObservableObject {
    /// Defer main page display while TLE download.
    @Published var isLoading = true
    
    init() { }
    
    /// Downloads and loads proper data before app launch.
    /// P.S.: should be revisited to avoid stalling.
    func bootstrap(modelContext: ModelContext, homeViewModel: HomeViewModel) async {
        defer { isLoading = false }
        
        do {
            try await fetchAndCacheAssetsMetadata(context: modelContext)
            let assets = try modelContext.fetch(FetchDescriptor<CachedAsset>())
            guard let initialAsset = assets.first(where: Self.isInitialAsset) else {
                throw BootstrapError.initialAssetNotFound
            }
            await homeViewModel.downloadAsset(for: initialAsset)
        } catch {
            print("Unable to bootstrap assets: \(error)")
        }
    }

    private static func isInitialAsset(_ asset: CachedAsset) -> Bool {
        asset.modelFileName.localizedCaseInsensitiveCompare("iss_lowpoly.glb") == .orderedSame
    }
    
    /// Fetch upstream and local assets metadata, download upstream asset snapshot images only if new or
    /// updated, upsert the local copy, and delete any local assets no longer present up.
    private func fetchAndCacheAssetsMetadata(context: ModelContext) async throws {
        let collection = try await AssetFeatureCollection.fetchAssets()
        let cachedAssets = try context.fetch(FetchDescriptor<CachedAsset>())
        let cachedAssetsById = Dictionary(uniqueKeysWithValues: cachedAssets.map { ($0.id, $0) })
        let remoteIds = Set(collection.features.map(\.properties.id))
        
        for feature in collection.features {
            let p = feature.properties
            let existing = cachedAssetsById[p.id]
            
            var data: Data? = existing?.snapImageData
            let needsDownload = existing == nil || existing?.updatedAt != p.updatedAt
            if
                needsDownload,
                let bucket = p.snapStoragePath?.split(separator: "%").map(String.init),
                let fileName = p.snapFileName
            {
                data = try await SupabaseService.shared.downloadAssetData(
                    fileName: fileName,
                    in: bucket[0],
                    at: bucket[1]
                )
            }
            
            let asset = existing ?? {
                let a = CachedAsset(
                    id: p.id,
                    name: p.name,
                    summary: p.summary,
                    modelFileName: p.modelFileName,
                    tleFileName: p.tleFileName,
                    snapFileName: p.snapFileName,
                    modelStoragePath: p.modelStoragePath,
                    tleStoragePath: p.tleStoragePath,
                    snapStoragePath: p.snapStoragePath,
                    updatedAt: p.updatedAt
                )
                context.insert(a)
                return a
            }()
            
            asset.name = p.name
            asset.summary = p.summary
            asset.modelFileName = p.modelFileName
            asset.tleFileName = p.tleFileName
            asset.snapFileName = p.snapFileName
            asset.modelStoragePath = p.modelStoragePath
            asset.tleStoragePath = p.tleStoragePath
            asset.snapStoragePath = p.snapStoragePath
            asset.snapImageData = data
            asset.updatedAt = p.updatedAt
        }
        
        for asset in cachedAssets where !remoteIds.contains(asset.id) {
            context.delete(asset)
        }
        
        try context.save()
    }
}

enum BootstrapError: LocalizedError {
    case initialAssetNotFound

    var errorDescription: String? {
        switch self {
        case .initialAssetNotFound:
            "The initial ISS asset was not found in the asset metadata."
        }
    }
}
