//
//  ArticleWebView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-25.
//

import SwiftUI
import WebKit

struct ArticleWebView: UIViewRepresentable {
    /// Article URL loaded in the web view.
    let url: URL
    
    /// The local web archive name to prefer when available.
    let webArchiveName: String?
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let webArchiveName {
            let webArchiveManager = WebArchiveDataManager()
            
            if webArchiveManager.webArchiveExists(named: webArchiveName) {
                webArchiveManager.loadWebArchive(named: webArchiveName, into: webView)
                return
            }
        }
        
        webView.load(URLRequest(url: url))
    }
}

struct ArticlePresentation: View {
    /// Environment value supplying dismiss.
    @Environment(\.dismiss) var dismiss
    
    /// Value used for destination.
    let destination: ArticleDestination
    
    var body: some View {
        NavigationStack {
            ArticleWebView(
                url: destination.url,
                webArchiveName: destination.isDownloadedLocally ? destination.id : nil
            )
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(destination.url.host() ?? "Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}
