//
//  AppEnv.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-03.
//

import Foundation

/// The app's environment keys.
public enum AppEnv {
    /// The public keys to get through the app's environment.
    enum Keys {
        static let supabaseURL = "SUPABASE_URL"
        static let supabaseKey = "SUPABASE_KEY"
        static let endpoint = "GRAPHQL_ENDPOINT"
    }
    
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("plist file not found")
        }
        return dict
    }()
    
    /// The Supabase URL used to create the client.
    static let url: URL = {
        guard let baseURLString = infoDictionary[Keys.supabaseURL] as? String else {
            fatalError("Base URL for Supabase not set in plist")
        }
        return URL(string: baseURLString)!
    }()
    
    /// The Supabase API publishable key used to create the client.
    static let key: String = {
        guard let apiKeyString = infoDictionary[Keys.supabaseKey] as? String else {
            fatalError("API key for Supabase not set in plist")
        }
        return apiKeyString
    }()
    
    /// The Supabase GraphQL endpoint used to query collections of data.
    static let graphql_endpoint: String = {
        guard let graphqlEndpointString = infoDictionary[Keys.endpoint] as? String else {
            fatalError("GraphQL endpoint URL not set in plist")
        }
        return graphqlEndpointString
    }()
}
