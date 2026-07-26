//
//  AssetFeatureCollection.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-03.
//

import Foundation
import Apollo

struct TrackedAssetFeatureCollection: Decodable {
    /// Tracked assets decoded from the remote collection.
    let features: [Feature]
    
    struct Feature: Decodable {
        /// Metadata associated with this tracked asset.
        let properties: Properties
        
        struct Properties: Decodable {
            /// Stable tracked-asset identifier.
            let id: String
            /// User-facing asset name.
            let name: String
            /// Short description of the asset.
            let summary: String
            /// Filename of the 3D model.
            let modelFileName: String
            /// Filename of the orbital elements.
            let tleFileName: String
            /// Optional preview-image filename.
            let snapFileName: String?
            /// Optional remote path of the preview image.
            let snapStoragePath: String?
            /// Remote path of the 3D model.
            let modelStoragePath: String
            /// Remote path of the orbital elements.
            let tleStoragePath: String
            /// Date of the latest remote update.
            let updatedAt: Date
        }
    }
}

// Fetch the data
extension TrackedAssetFeatureCollection {
    /// Gets and decodes the asset data from the Storage.
    static func fetchAssets() async throws -> TrackedAssetFeatureCollection {
        let store = ApolloStore(cache: InMemoryNormalizedCache())
        let transport = RequestChainNetworkTransport(
            urlSession: URLSession(configuration: .default),
            interceptorProvider: DefaultInterceptorProvider.shared,
            store: store,
            endpointURL: URL(string: AppEnv.graphql_endpoint)!,
            additionalHeaders: [
                "apikey": AppEnv.key
            ]
        )
        let client = ApolloClient(networkTransport: transport, store: store)
        
        let result = try await client.fetch(query: AstroAPI.TrackedAssetQuery())
        guard let data = result.data else { throw URLError(.badServerResponse) }
        
        let features: [TrackedAssetFeatureCollection.Feature] = (data.tracked_assetCollection?.edges ?? []).map { edge in
            TrackedAssetFeatureCollection.Feature(
                properties: .init(
                    id: edge.node.id,
                    name: edge.node.name,
                    summary: edge.node.summary,
                    modelFileName: edge.node.model_file_name,
                    tleFileName: edge.node.tle_file_name,
                    snapFileName: edge.node.snapshot_file_name,
                    snapStoragePath: edge.node.snapshot_storage_path,
                    modelStoragePath: edge.node.model_storage_path,
                    tleStoragePath: edge.node.tle_storage_path,
                    updatedAt: {
                        let raw = edge.node.updated_at
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime]
                        return formatter.date(from: raw) ?? Date.distantPast
                    }()
                )
            )
        }
        
        return TrackedAssetFeatureCollection(features: features)
    }
}
