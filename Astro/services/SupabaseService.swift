//
//  SupabaseService.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-03.
//

import Foundation
import Supabase

final class SupabaseService {
    
    static let shared = SupabaseService()
    
    private(set) var client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: AppEnv.url,
            supabaseKey: AppEnv.key
        )
    }
}
