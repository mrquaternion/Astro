//
//  LearnAssetFeatureCollection.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-08.
//

import Foundation
import Apollo

struct LearnAssetFeatureCollection {
    /// Learning assets decoded from the remote collection.
    let features: [Feature]
    
    struct Feature {
        /// Metadata associated with this learning asset.
        let properties: Properties
        
        struct Properties {
            /// Stable learning-asset identifier.
            let id: String
            /// Identifier of the initially selected component.
            let defaultComponentId: String
            /// Component selected when the asset first opens.
            let defaultComponent: Component
            /// Components available for this asset.
            let components: [Component]
            /// Date of the latest remote update.
            let updatedAt: Date
        }
    }
    
    struct Component {
        /// Stable component identifier.
        let componentId: String
        /// Filename of the component's 3D model.
        let modelFileName: String
        /// Optional preview-image filename.
        let snapFileName: String?
        /// Remote path of the 3D model.
        let modelStoragePath: String
        /// Optional remote path of the preview image.
        let snapStoragePath: String?
        /// Optional abbreviated component name.
        let shortName: String?
        /// Full user-facing component name.
        let displayName: String
        /// Functional category of the component.
        let category: String
        /// Optional larger system containing the component.
        let group: String?
        /// Agencies associated with the component.
        let agencies: [String]
        /// Organizations that manufactured the component.
        let manufacturers: [String]
        /// Principal materials used by the component.
        let materials: [String]
        /// Chronological events associated with the component.
        let timeline: [TimelineEvent]
        /// Detailed informational sections.
        let details: [Detail]
        /// Short overview of the component.
        let summary: String
        /// Identifiers of information sources.
        let sourceIds: [String]
        /// Whether this component is selected by default.
        let isDefaultSelection: Bool
    }
    
    struct TimelineEvent {
        /// Date on which the event occurred.
        let date: Date
        /// User-facing description of the event.
        let event: String
    }
    
    struct Detail {
        /// Heading of the detail section.
        let title: String
        /// Body text of the detail section.
        let body: String
    }
}

extension LearnAssetFeatureCollection {
    /// Gets and decodes the learn asset data from Supabase.
    static func fetchAssets() async throws -> LearnAssetFeatureCollection {
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
        
        let result = try await client.fetch(query: AstroAPI.LearnAssetQuery())
        guard let data = result.data else { throw URLError(.badServerResponse) }
        
        let componentsById = try data.componentNodes.reduce(into: [String: Component]()) { partialResult, node in
            partialResult[node.component_id] = try makeComponent(from: node)
        }
        
        let features = try data.assetNodes.map { assetNode in
            guard let defaultComponent = componentsById[assetNode.default_component] else {
                throw LearnAssetDecodeError.missingComponent(assetNode.default_component)
            }
            
            let componentIds = assetNode.components.compactMap(\.self)
            let components = try componentIds.map { componentId in
                guard let component = componentsById[componentId] else {
                    throw LearnAssetDecodeError.missingComponent(componentId)
                }
                
                return component
            }
            
            return Feature(properties: .init(
                id: assetNode.learn_asset_id,
                defaultComponentId: assetNode.default_component,
                defaultComponent: defaultComponent,
                components: components,
                updatedAt: DateFormatterHelpers.date(from: assetNode.updated_at)
            ))
        }
        
        return LearnAssetFeatureCollection(features: features)
    }
    
    private static func makeComponent(
        from node: AstroAPI.LearnAssetQuery.Data.Learn_componentCollection.Edge.Node
    ) throws -> Component {
        let timeline = try decodeTimeline(from: node.timeline)
        let details = try decodeDetails(from: node.details)
        
        return Component(
            componentId: node.component_id,
            modelFileName: node.model_file_name,
            snapFileName: node.snapshot_file_name,
            modelStoragePath: node.model_storage_path,
            snapStoragePath: node.snapshot_storage_path,
            shortName: node.short_name,
            displayName: node.display_name,
            category: node.category,
            group: node.group,
            agencies: node.agencies.compactMap(\.self),
            manufacturers: node.manufacturers.compactMap(\.self),
            materials: node.materials.compactMap(\.self),
            timeline: timeline,
            details: details,
            summary: node.summary,
            sourceIds: node.source_ids.compactMap(\.self),
            isDefaultSelection: node.is_default_selection
        )
    }
    
    private static func decodeTimeline(from jsonString: String) throws -> [TimelineEvent] {
        try JSONDecoder().decode([TimelineEventDTO].self, from: Data(jsonString.utf8)).map {
            TimelineEvent(
                date: DateFormatterHelpers.date(from: $0.date),
                event: $0.event
            )
        }
    }
    
    private static func decodeDetails(from jsonString: String) throws -> [Detail] {
        try JSONDecoder().decode([DetailDTO].self, from: Data(jsonString.utf8)).map {
            Detail(title: $0.title, body: $0.body)
        }
    }
}

private extension AstroAPI.LearnAssetQuery.Data {
    /// Flattened learning-asset nodes returned by GraphQL.
    var assetNodes: [Learn_assetCollection.Edge.Node] {
        learn_assetCollection?.edges.map(\.node) ?? []
    }
    
    /// Flattened component nodes returned by GraphQL.
    var componentNodes: [Learn_componentCollection.Edge.Node] {
        learn_componentCollection?.edges.map(\.node) ?? []
    }
}

private enum LearnAssetDecodeError: Error {
    case missingComponent(String)
}

private struct TimelineEventDTO: Decodable {
    /// Value used for date.
    let date: String
    /// Value used for event.
    let event: String
}

private struct DetailDTO: Decodable {
    /// Value used for title.
    let title: String
    /// Value used for body.
    let body: String
}
