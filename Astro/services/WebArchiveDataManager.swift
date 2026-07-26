//
//  WebArchiveDataManager.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-25.
//

import Foundation
import WebKit

// source: https://blog.devgenius.io/storing-wkwebview-content-for-offline-access-in-your-ios-app-b61daf528df2
@MainActor
class WebArchiveDataManager {
    /// Directory containing downloaded web archives.
    let webArchiveDirectoryURL: URL
    
    init() {
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access document directory.")
        }
        
        webArchiveDirectoryURL = documentDirectory.appendingPathComponent("WebArchives")
        
        // creates the web archive directory if doesn't exist
        if !fileManager.fileExists(atPath: webArchiveDirectoryURL.path()) {
            try? fileManager.createDirectory(at: webArchiveDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func saveWebArchive(from webView: WKWebView, withName name: String) {
        webView.createWebArchiveData { result in
            switch result {
            case .success(let archiveData):
                let fileURL = self.webArchiveDirectoryURL.appendingPathComponent("\(name).webarchive")

                do {
                    try archiveData.write(to: fileURL)
                    print("Web archive saved at \(fileURL.path())")
                } catch {
                    print("Error saving web archive: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("Error creating web archive data: \(error.localizedDescription)")
            }
        }
    }
    
    func saveWebArchive(from url: URL, withName name: String, onProgress: @escaping (Double) -> Void) async throws {
        let webView = WKWebView(frame: .zero)
        let delegate = WebArchiveNavigationDelegate(onProgress: onProgress)
        
        webView.navigationDelegate = delegate
        delegate.observeProgress(of: webView)
        
        onProgress(0.05)
        webView.load(URLRequest(url: url))
        
        try await delegate.waitForLoad()
        
        let archiveData = try await webView.createWebArchiveData()
        let fileURL = webArchiveURL(named: name)
        try archiveData.write(to: fileURL, options: .atomic)
        
        onProgress(1)
    }
    
    func loadWebArchive(named name: String, into webView: WKWebView) {
        let fileURL = webArchiveURL(named: name)
        
        do {
            let archiveData = try Data(contentsOf: fileURL)
            webView.load(archiveData, mimeType: "application/x-webarchive", characterEncodingName: "", baseURL: fileURL)
            print("Web archive loaded from \(fileURL.path())")
        } catch {
            print("Error loading web archive: \(error.localizedDescription)")
        }
    }
    
    func webArchiveExists(named name: String) -> Bool {
        FileManager.default.fileExists(atPath: webArchiveURL(named: name).path())
    }
    
    func webArchiveURL(named name: String) -> URL {
        webArchiveDirectoryURL.appendingPathComponent("\(name).webarchive")
    }
}

private final class WebArchiveNavigationDelegate: NSObject, WKNavigationDelegate {
    /// Callback receiving normalized archive-download progress.
    private let onProgress: (Double) -> Void
    /// Continuation completed when the archive finishes loading.
    private var continuation: CheckedContinuation<Void, Error>?
    /// Observation used to report WebKit loading progress.
    private var progressObservation: NSKeyValueObservation?
    
    init(onProgress: @escaping (Double) -> Void) {
        self.onProgress = onProgress
    }
    
    func observeProgress(of webView: WKWebView) {
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [onProgress] webView, _ in
            let progress = 0.05 + (webView.estimatedProgress * 0.75)
            onProgress(min(max(progress, 0.05), 0.8))
        }
    }
    
    func waitForLoad() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onProgress(0.85)
        continuation?.resume()
        continuation = nil
        progressObservation = nil
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        progressObservation = nil
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        progressObservation = nil
    }
}

private extension WKWebView {
    func createWebArchiveData() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            createWebArchiveData { result in
                continuation.resume(with: result)
            }
        }
    }
}
