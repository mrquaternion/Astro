//
//  SupabaseService.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-03.
//

import Foundation
import Supabase
import SatelliteKit

final class SupabaseService {
    /// SupabaseService singleton to use through the view models.
    static let shared = SupabaseService()
    
    private(set) var client: SupabaseClient
    
    /// Creates the Supabase client.
    private init() {
        self.client = SupabaseClient(
            supabaseURL: AppEnv.url,
            supabaseKey: AppEnv.key,
        )
    }
    
    func downloadTLE(fileName: String, in bucket: String, at filePath: String) async throws -> Elements {
        let response = try await client.storage.from(bucket).download(path: filePath)
        
        // save in the user's device beforehand
        guard let path = getPathOfAsset(assetFileName: fileName) else { throw URLError(.badURL) }
        try response.write(to: path)
        
        let element = try decodeTLE(data: response)
        return element
    }
    
    func downloadAsset(fileName: String, in bucket: String, at filePath: String) async throws -> URL? {
        let response = try await downloadAssetData(fileName: fileName, in: bucket, at: filePath)
        guard let path = getPathOfAsset(assetFileName: fileName) else { throw URLError(.badURL) }
        
        try response.write(to: path)
        
        return path
    }
    
    func downloadAssetData(fileName: String, in bucket: String, at filePath: String) async throws -> Data {
        try await client.storage.from(bucket).download(path: filePath)
    }
    
    func decodeTLE(data: Data) throws -> Elements {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Micros)
        
        let elements = try jsonDecoder.decode([Elements].self, from: data)
        return elements[0]
    }
    
    func getPathOfAsset(assetFileName: String) -> URL? {
        guard
            let path = FileManager
                .default
                .urls(for: .cachesDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("\(assetFileName)")
        else {
            print("Error saving path after asset download.")
            return nil
        }
        return path
    }
}
