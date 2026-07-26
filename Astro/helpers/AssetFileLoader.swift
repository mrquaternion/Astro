//
//  AssetFileLoader.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-08.
//

import Foundation

enum AssetFileLoader {
    static func dataAndCacheURL(
        storagePath: String,
        filename: String
    ) async throws -> (data: Data, url: URL) {
        guard let (filepath, bucket) = AssetLoadingHelpers.parseStoragePath(storagePath) else {
            throw URLError(.cannotCreateFile)
        }
        
        let data = try await SupabaseService.shared.fetchAssetData(filepath, in: bucket)
        
        guard let url = AssetLoadingHelpers.getPathOfAssetAsURL(filename: filename) else {
            throw URLError(.badURL)
        }
        
        return (data, url)
    }
    
    static func dataAndCacheURLWithProgress(
        storagePath: String,
        filename: String,
        onProgress: @escaping (Double) -> Void
    ) async throws -> (data: Data, url: URL) {
        guard let (filepath, bucket) = AssetLoadingHelpers.parseStoragePath(storagePath) else {
            throw URLError(.cannotCreateFile)
        }
        
        let data = try await SupabaseService.shared.fetchDataWithProgress(
            filepath,
            in: bucket,
            onProgress: onProgress
        )
        
        guard let url = AssetLoadingHelpers.getPathOfAssetAsURL(filename: filename) else {
            throw URLError(.badURL)
        }
        
        return (data, url)
    }
    
    static func data(storagePath: String?) async throws -> Data? {
        guard let (filepath, bucket) = AssetLoadingHelpers.parseStoragePath(storagePath) else {
            return nil
        }
        
        return try await SupabaseService.shared.fetchAssetData(filepath, in: bucket)
    }
}
