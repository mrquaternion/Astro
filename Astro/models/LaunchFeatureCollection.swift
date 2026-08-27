//
//  LaunchFeatureCollection.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-22.
//

import Foundation
import Apollo

struct LaunchFeatureCollection {
    /// Launches decoded from the remote collection.
    let features: [Feature]
    
    struct Feature: Identifiable {
        /// Metadata associated with this launch.
        let properties: Properties
        
        /// Stable launch identifier.
        var id: String { properties.id }
        
        struct Properties {
            /// Stable launch identifier.
            let id: String
            /// Full launch name.
            let name: String
            /// Abbreviated launch name.
            let shortName: String
            /// Current launch status.
            let status: Status
            /// Organization providing the launch service.
            let serviceProvider: ServiceProvider
            /// Optional mission carried by the launch.
            let mission: Mission?
            /// Rocket assigned to the launch.
            let rocket: Rocket
            /// Pad from which the launch occurs.
            let pad: Pad
            /// Current no-earlier-than launch date.
            let net: Date
            /// Beginning of the launch window.
            let windowStart: Date
            /// End of the launch window.
            let windowEnd: Date
            /// Optional full-size launch image.
            let imageURL: URL?
            /// Optional launch thumbnail image.
            let thumbnailURL: URL?
            /// Available live or recorded video feeds.
            let videoFeedURLs: [URL]
            /// Date of the latest metadata update.
            let lastUpdated: Date
        }
    }
    
    struct Status {
        /// Stable status identifier.
        let statusId: String
        /// Full status name.
        let name: String
        /// Abbreviated status name.
        let abbrev: String
    }
    
    struct ServiceProvider {
        /// Stable service-provider identifier.
        let serviceProviderId: String
        /// User-facing service-provider name.
        let name: String
    }
    
    struct Mission {
        /// Stable mission identifier.
        let missionId: String
        /// Mission name.
        let name: String
        /// Mission category.
        let type: String
        /// Mission overview.
        let description: String
        /// Stable target-orbit identifier.
        let orbitId: String
        /// Full target-orbit name.
        let orbitName: String
        /// Abbreviated target-orbit name.
        let orbitAbbrev: String
    }
    
    struct Rocket {
        /// Stable rocket identifier.
        let rocketId: String
        /// Full rocket configuration name.
        let fullName: String
        /// Rocket manufacturer.
        let manufacturer: String
    }
    
    struct Pad {
        /// Stable launch-pad identifier.
        let padId: String
        /// Launch-pad name.
        let name: String
        /// Launch-pad latitude.
        let latitude: Double
        /// Launch-pad longitude.
        let longitude: Double
        /// User-facing launch-pad location.
        let location: String
        /// Country containing the launch pad.
        let country: String
        /// Three-letter country code.
        let alphaCode: String
    }
}

extension LaunchFeatureCollection {
    /// Gets and decodes the launch data from Supabase.
    static func fetchLaunches() async throws -> LaunchFeatureCollection {
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
        
        let result = try await client.fetch(query: AstroAPI.LaunchQuery())
        guard let data = result.data else { throw URLError(.badServerResponse) }
        
        // decoding
        let statusById = data.launchStatusNodes.reduce(into: [String: Status]()) { partialResult, node in
            partialResult[node.status_id] = Status(statusId: node.status_id, name: node.name, abbrev: node.abbrev)
        }
        
        let serviceProviderById = data.launchServiceProviderNodes.reduce(into: [String: ServiceProvider]()) { partialResult, node in
            partialResult[node.launch_service_provider_id] = ServiceProvider(serviceProviderId: node.launch_service_provider_id, name: node.name)
        }
        
        let missionsById = data.launchMissionNodes.reduce(into: [String: Mission]()) { partialResult, node in
            partialResult[node.mission_id] = Mission(missionId: node.mission_id, name: node.name, type: node.type, description: node.description, orbitId: node.orbit_id, orbitName: node.orbit_name, orbitAbbrev: node.orbit_abbrev)
        }
        
        let rocketsById = data.launchRocketNodes.reduce(into: [String: Rocket]()) { partialResult, node in
            partialResult[node.rocket_id] = Rocket(rocketId: node.rocket_id, fullName: node.full_name, manufacturer: node.manufacturer)
        }

        let padsById = data.launchPadNodes.reduce(into: [String: Pad]()) { partialResult, node in
            partialResult[node.pad_id] = Pad(padId: node.pad_id, name: node.name, latitude: node.latitude, longitude: node.longitude, location: node.location, country: node.country, alphaCode: node.alpha_3_code)
        }
        
        let videoURLsById = data.launchVideoURLNodes.reduce(into: [String: [String]]()) { partialResult, node in
            partialResult[node.launch_id, default: []].append(node.video_url)
        }
        
        let features = try data.launchNodes.map { launchNode in
            guard let status = statusById[launchNode.status_id] else {
                throw LaunchDecodeError.missingComponent("status \(launchNode.status_id) for launch \(launchNode.launch_id)")
            }
            guard let serviceProvider = serviceProviderById[launchNode.launch_service_provider_id] else {
                throw LaunchDecodeError.missingComponent("serviceProvider \(launchNode.launch_service_provider_id) for launch \(launchNode.launch_id)")
            }
            guard let rocket = rocketsById[launchNode.rocket_id] else {
                throw LaunchDecodeError.missingComponent("rocket \(launchNode.rocket_id) for launch \(launchNode.launch_id)")
            }
            guard let pad = padsById[launchNode.pad_id] else {
                throw LaunchDecodeError.missingComponent("pad \(launchNode.pad_id) for launch \(launchNode.launch_id)")
            }
            
            var missionObj: Mission?
            if let missionId = launchNode.mission_id {
                missionObj = missionsById[missionId]
            }
            
            return Feature(properties: .init(
                id: launchNode.launch_id,
                name: launchNode.name,
                shortName: {
                    let parts = launchNode.name.split(separator: "|", maxSplits: 1)
                    guard parts.count == 2 else { return "common_unknown".localizedFirstCapitalized }
                    return String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                }(),
                status: status,
                serviceProvider: serviceProvider,
                mission: missionObj,
                rocket: rocket,
                pad: pad,
                net: DateFormatterHelpers.date(from: launchNode.net),
                windowStart: DateFormatterHelpers.date(from: launchNode.window_start),
                windowEnd: DateFormatterHelpers.date(from: launchNode.window_end),
                imageURL: {
                    guard let imageURLString = launchNode.image_url_string else { return nil }
                    return URL(string: imageURLString)
                }(),
                thumbnailURL: {
                    guard let thumbnailURLString = launchNode.thumbnail_url_string else { return nil }
                    return URL(string: thumbnailURLString)
                }(),
                videoFeedURLs: (videoURLsById[launchNode.launch_id] ?? []).compactMap(URL.init(string:)),
                lastUpdated: DateFormatterHelpers.date(from: launchNode.last_updated)
            ))
        }
        
        return LaunchFeatureCollection(features: features)
    }
}

private extension AstroAPI.LaunchQuery.Data {
    /// Flattened launch nodes returned by GraphQL.
    var launchNodes: [LaunchCollection.Edge.Node] {
        launchCollection?.edges.map(\.node) ?? []
    }
    
    /// Flattened launch-status nodes returned by GraphQL.
    var launchStatusNodes: [Launch_statusCollection.Edge.Node] {
        launch_statusCollection?.edges.map(\.node) ?? []
    }
    
    /// Flattened service-provider nodes returned by GraphQL.
    var launchServiceProviderNodes: [Launch_service_providerCollection.Edge.Node] {
        launch_service_providerCollection?.edges.map(\.node) ?? []
    }
    
    /// Flattened mission nodes returned by GraphQL.
    var launchMissionNodes: [Launch_missionCollection.Edge.Node] {
        launch_missionCollection?.edges.map(\.node) ?? []
    }
    
    /// Flattened rocket nodes returned by GraphQL.
    var launchRocketNodes: [Launch_rocketCollection.Edge.Node] {
        launch_rocketCollection?.edges.map(\.node) ?? []
    }
    
    /// Flattened launch-pad nodes returned by GraphQL.
    var launchPadNodes: [Launch_padCollection.Edge.Node] {
        launch_padCollection?.edges.map(\.node) ?? []
    }
    
    /// Flattened launch-video nodes returned by GraphQL.
    var launchVideoURLNodes: [Launch_video_urlCollection.Edge.Node] {
        launch_video_urlCollection?.edges.map(\.node) ?? []
    }
}

private enum LaunchDecodeError: Error {
    case missingComponent(String)
}
