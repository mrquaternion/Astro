//
//  ArticleFeatureCollection.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-21.
//

import Foundation
import Apollo

struct ArticleFeatureCollection: Decodable {
    /// Articles decoded from the remote collection.
    let features: [Feature]
    
    struct Feature: Decodable {
        /// Metadata associated with this article.
        let properties: Properties
        
        struct Properties: Decodable {
            /// Stable article identifier.
            let id: String
            /// Article headline.
            let title: String
            /// Short article summary.
            let summary: String
            /// Raw URL string for the article.
            let urlString: String
            /// Article publication date.
            let publishedAt: Date
            /// Name of the publishing website.
            let websiteName: String
            /// Raw URL string for the article image.
            let imageUrlString: String
            /// Optional launch identifiers referenced by the article.
            let launches: [String?]
            /// Optional event identifiers referenced by the article.
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
