//
//  BootstrapViewModel.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-05.
//

import Foundation
import Combine
import SwiftData
import SatelliteKit

@MainActor
final class BootstrapViewModel: ObservableObject {
    /// Defer main page display while TLE download.
    @Published var isLoading = true
    
    init() { }
    
    /// Satlls the `AppRouteView` to be sure that the the default satellite is fetched and ready to display in the `MainView`.
    func bootstrap(homeViewModel: HomeViewModel) async {
        
        do {
            let collection = try await TrackedAssetFeatureCollection.fetchAssets()
            
            var assets: [CachedTrackedAsset] = []
            for feature in collection.features {
                let asset = CachedTrackedAsset(
                    id: feature.properties.id,
                    name: feature.properties.name,
                    summary: feature.properties.summary,
                    modelFileName: feature.properties.modelFileName,
                    tleFileName: feature.properties.tleFileName,
                    snapFileName: feature.properties.snapFileName,
                    modelStoragePath: feature.properties.modelStoragePath,
                    tleStoragePath: feature.properties.tleStoragePath,
                    snapStoragePath: feature.properties.snapStoragePath,
                    updatedAt: .now
                )

                assets.append(asset)
            }
            
            // get the default asset (ISS)
            guard let defaultSelectedSatellite = assets.first(where: { Self.isInitialAsset($0) }) else {
                throw BootstrapError.initialAssetNotFound
            }
            
            try await loadDefaultSatellite(defaultSelectedSatellite, homeViewModel: homeViewModel)
            
        } catch {
            print(error)
        }
        
        let splashDelay = ScreenshotMode.isEnabled ? 0.0 : 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + splashDelay) {
            self.isLoading = false
        }
    }
    
    /// Loads the default satellite (available in free-tier, ISS) and makes it available for the Mapbox map controller.
    private func loadDefaultSatellite(_ satellite: CachedTrackedAsset, homeViewModel: HomeViewModel) async throws {
        var modelData: Data?
        var tleElements: Elements?
        
        // 3D Model
        if let (filepath, bucket) = AssetLoadingHelpers.parseStoragePath(satellite.modelStoragePath) {
            modelData = try await SupabaseService.shared.fetchAssetData(filepath, in: bucket)
        }
        
        // TLE JSON
        if let (filepath, bucket) = AssetLoadingHelpers.parseStoragePath(satellite.tleStoragePath) {
            tleElements = try await SupabaseService.shared.fetchTLEJson(filepath, in: bucket)
        }
        
        guard let modelData, let tleElements else {
            throw BootstrapError.missingRequiredData
        }
        
        homeViewModel.selectedSatellite = SelectedSatellite(
            id: satellite.id,
            name: satellite.displayName,
            modelUri: try AssetLoadingHelpers.computeDataUri(
                data: modelData,
                id: satellite.id
            ),
            elements: tleElements,
            route: try AssetLoadingHelpers.computeRoute(elements: tleElements)
        )
    }
    
    private static func isInitialAsset(_ asset: CachedTrackedAsset) -> Bool {
        SubscriptionHelper.isFree(.satellite(fileName: asset.modelFilename))
    }
}

enum BootstrapError: LocalizedError {
    case initialAssetNotFound
    case missingRequiredData
    
    /// Value used for errorDescription.
    var errorDescription: String? {
        switch self {
        case .initialAssetNotFound:
            "The initial ISS asset was not found in the asset metadata."
        case .missingRequiredData:
            "Missing data for loading default satellite."
        }
    }
}
