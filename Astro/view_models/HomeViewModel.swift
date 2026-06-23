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
    /// The satellite currently displayed on the map.
    @Published private(set) var selectedSatellite: SelectedSatellite?

    /// The current state of asset loading.
    @Published private(set) var isAssetLoading = false
    
    /// The message to display when loading an asset (download or local cache).
    @Published private(set) var loadingMessage : String?

    /// Verify and download the selected satellite. Then, assign the data to a SelectedSatellite object.
    func downloadAsset(for asset: CachedAsset) async {
        isAssetLoading = true
        defer { isAssetLoading = false }
        
        do {
            let modelLocation = try Self.storageLocation(from: asset.modelStoragePath)
            let tleLocation = try Self.storageLocation(from: asset.tleStoragePath)
            guard let modelURL = try await SupabaseService.shared.downloadAsset(
                fileName: asset.modelFileName,
                in: modelLocation.bucket,
                at: modelLocation.path
            ) else {    
                throw URLError(.cannotCreateFile)
            }
            let elements = try await SupabaseService.shared.downloadTLE(
                fileName: asset.tleFileName,
                in: tleLocation.bucket,
                at: tleLocation.path
            )

            selectedSatellite = SelectedSatellite(
                id: asset.id,
                name: asset.name,
                modelURL: modelURL,
                elements: elements,
                route: try Self.computeRoute(elements: elements)
            )
        } catch _ as URLError { // in the case that the user is offline
            guard
                let modelPath = SupabaseService.shared.getPathOfAsset(assetFileName: asset.modelFileName),
                let tlePath = SupabaseService.shared.getPathOfAsset(assetFileName: asset.tleFileName),
                FileManager.default.fileExists(atPath: modelPath.path()),
                FileManager.default.fileExists(atPath: tlePath.path())
            else {
                print("Error getting path of asset or it's TLE.")
                return
            }
            
            do {
                let elements = try SupabaseService.shared.decodeTLE(data: Data(contentsOf: tlePath))
                selectedSatellite = SelectedSatellite(
                    id: asset.id,
                    name: asset.name,
                    modelURL: modelPath,
                    elements: elements,
                    route: try Self.computeRoute(elements: elements)
                )
            } catch {
                print("Impossible to decode existing TLE and asset on user's device.")
                return
            }
            
        } catch let error as CocoaError {
            print("Unable to write the model's asset: \(error)")
        } catch {
            print(error)
        }
    }

    private static func storageLocation(from storagePath: String) throws -> (bucket: String, path: String) {
        let components = storagePath.split(separator: "%", maxSplits: 1).map(String.init)
        guard components.count == 2 else { throw URLError(.badURL) }
        return (components[0], components[1])
    }

    private static func computeRoute(elements: Elements) throws -> Model3DRoute {
        let satellite = Satellite(elements: elements)
        var coordinates: [[Double]] = []
        var elevations: [Double] = []

        for timeOffset in 0..<(Constants.avgOrbitCompletionTime + 1) {
            let lla = try satellite.geoPosition(minsAfterEpoch: satellite.minsAfterEpoch + Double(timeOffset))
            let fixedLng = lla.lon > 180 ? lla.lon - 360 : lla.lon
            coordinates.append([fixedLng, lla.lat])
            elevations.append(lla.alt)
        }

        return Model3DRoute(coordinates: coordinates, elevations: elevations)
    }
}

struct SelectedSatellite {
    let id: String
    let name: String
    let modelURL: URL
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

private enum Constants {
    static let avgOrbitCompletionTime = 90
}

enum AstroError: LocalizedError {
    case noWifiConnection
    case unableToFetchProducts(message: String)
    case unableToRestorePurchases(message: String)
    
    var description: String {
        switch self {
        case .noWifiConnection: "No internet connection available."
        case .unableToFetchProducts(let message): "Unable to fetch products: \(message)"
        case .unableToRestorePurchases(let message): "Unable to restore purchases: \(message)"
        }
    }
    
    var symbol: String {
        switch self {
        case .noWifiConnection: "wifi.slash"
        case .unableToFetchProducts(_): "cart.badge.questionmark"
        case .unableToRestorePurchases(_): "storefront"
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
