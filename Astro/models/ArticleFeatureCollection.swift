//
//  ArticleFeatureCollection.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-21.
//

import Foundation
import Apollo

struct ArticleFeatureCollection: Decodable {
    let features: [Feature]
    
    struct Feature: Decodable {
        let properties: Properties
        
        struct Properties: Decodable {
            let id: String
            let title: String
            let summary: String
            let urlString: String
            let publishedAt: Date
            let websiteName: String
            let imageUrlString: String
            let launches: [String?]
            let events: [String?]
        }
    }
}

// Fetch the data
extension ArticleFeatureCollection {
    /// Gets and decodes the news JSON from the Space News API (from the SpaceDevs).
    static func fetchArticles() async throws -> ArticleFeatureCollection {
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
        
        let result = try await client.fetch(query: AstroAPI.ArticleQuery())
        guard let data = result.data else { throw URLError(.badServerResponse) }
        
        let features: [ArticleFeatureCollection.Feature] = (data.articleCollection?.edges ?? []).map { edge in
            ArticleFeatureCollection.Feature(
                properties: .init(
                    id: edge.node.id,
                    title: edge.node.title,
                    summary: edge.node.summary,
                    urlString: edge.node.url_string,
                    publishedAt: {
                        let raw = edge.node.published_at
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime]
                        return formatter.date(from: raw) ?? Date.distantPast
                    }(),
                    websiteName: edge.node.website_name,
                    imageUrlString: edge.node.image_url_string,
                    launches: edge.node.launches,
                    events: edge.node.events
                )
            )
        }
        
        return ArticleFeatureCollection(features: features)
    }
}
