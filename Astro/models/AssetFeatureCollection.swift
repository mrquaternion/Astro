//
//  AssetFeatureCollection.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-03.
//

import Foundation
import Apollo

struct AssetFeatureCollection: Decodable {
    let features: [Feature]
    
    struct Feature: Decodable {
        let properties: Properties
        
        struct Properties: Decodable {
            let id: String
            let name: String
            let summary: String
            let modelFileName: String
            let tleFileName: String
            let snapFileName: String?
            let snapStoragePath: String?
            let modelStoragePath: String
            let tleStoragePath: String
            let updatedAt: Date
        }
    }
}

// Fetch the data
extension AssetFeatureCollection {
    /// Gets and decodes the asset data from the Storage.
    static func fetchAssets() async throws -> AssetFeatureCollection {
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
        
        let result = try await client.fetch(query: AstroAPI.AssetQuery())
        guard let data = result.data else { throw URLError(.badServerResponse) }
        
        let features: [AssetFeatureCollection.Feature] = (data.assetCollection?.edges ?? []).map { edge in
            AssetFeatureCollection.Feature(
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
        
        return AssetFeatureCollection(features: features)
    }
}
