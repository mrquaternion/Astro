//
//  AppEnv.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-03.
//

import Foundation

public enum AppEnv {
    
    enum Keys {
        static let supabaseURL = "SUPABASE_URL"
        static let supabaseKey = "SUPABASE_KEY"
    }
    
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("plist file not found")
        }
        return dict
    }()
    
    static let url: URL = {
        guard let baseURLString = infoDictionary[Keys.supabaseURL] as? String else {
            fatalError("Base URL for Supabase not set in plist")
        }
        return URL(string: baseURLString)!
    }()
    
    static let key: String = {
        guard let apiKeyString = infoDictionary[Keys.supabaseKey] as? String else {
            fatalError("API key for Supabase not set in plist")
        }
        return apiKeyString
    }()
}
