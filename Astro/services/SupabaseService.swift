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
    
    func fetchDataWithProgress(_ filepath: String, in bucket: String, onProgress: @escaping (Double) -> Void) async throws -> Data {
        let signedURL = try await client.storage
            .from(bucket)
            .createSignedURL(path: filepath, expiresIn: 3600)
        
        return try await downloadWithProgress(from: signedURL, onProgress: onProgress)
    }
    
    func fetchAssetData(_ filepath: String, in bucket: String) async throws -> Data {
        try await client.storage.from(bucket).download(path: filepath)
    }
    
    func fetchTLEJson(_ filepath: String, in bucket: String) async throws -> Elements {
        let data = try await client.storage.from(bucket).download(path: filepath)
        let element = try AssetLoadingHelpers.decodeTLE(data: data)
        return element
    }
    
    // MARK: - Private helpers
    
    private func downloadWithProgress(from url: URL, onProgress: @escaping (Double) -> Void) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = ProgressDelegate(onProgress: onProgress, continuation: continuation)
            
            let session = URLSession(
                configuration: .default,
                delegate: delegate,
                delegateQueue: nil
            )
            
            delegate.session = session
            
            session.dataTask(with: url).resume()
        }
    }
}

private final class ProgressDelegate: NSObject, URLSessionDataDelegate {
    private let onProgress: (Double) -> Void
    private var continuation: CheckedContinuation<Data, Error>?
    private var receivedData = Data()
    private var expectedBytes: Int64 = 0
    
    var session: URLSession?
    
    init(onProgress: @escaping (Double) -> Void, continuation: CheckedContinuation<Data, Error>) {
        self.onProgress = onProgress
        self.continuation = continuation
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        expectedBytes = response.expectedContentLength
        completionHandler(.allow)
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        receivedData.append(data)
        print("Received:", receivedData.count, "Expected:", expectedBytes)
        guard expectedBytes > 0 else { return }
        
        let progress = Double(receivedData.count) / Double(expectedBytes)
        onProgress(min(max(progress, 0), 1))
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        defer {
            continuation = nil
            session.finishTasksAndInvalidate()
            self.session = nil
        }
        
        if let error {
            continuation?.resume(throwing: error)
        } else {
            onProgress(1)
            continuation?.resume(returning: receivedData)
        }
    }
}
