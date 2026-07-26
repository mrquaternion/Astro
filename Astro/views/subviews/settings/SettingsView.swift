//
//  SettingsView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-25.
//

import SwiftUI
import SwiftData
import WebKit

struct WebView: UIViewRepresentable {
    /// Value used for url.
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}

struct SettingsView: View {
    /// Subscription store that provides purchasable products.
    @Environment(SubscriptionManager.self) private var store

    /// Manages persistent data used by download settings.
    let dataController: DataController
    
    /// Binding supplying isPresented.
    @Binding var isPresented: Bool
    
    /// Mutable view state tracking webView.
    @State private var webView: WebView?
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section("Account") {
                        NavigationLink("Subscription") {
                            SubscriptionSettings()
                                .environment(store)
                                .navigationTitle("Subscription")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                        NavigationLink("Downloads") {
                            DownloadSettings(dataController: dataController)
                                .navigationTitle("Downloads")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                    
                    Section("About") {
                        NavigationLink("Privacy Policy") {
                            WebView(url: URL(string: "https://someonelostinspace.github.io/astro-web/privacy.html")!)
                                .ignoresSafeArea()
                        }
                        NavigationLink("Terms of Service") {
                            WebView(url: URL(string: "https://someonelostinspace.github.io/astro-web/terms.html")!)
                                .ignoresSafeArea()
                        }
                        
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
            .navigationDestination(isPresented: Binding(get: { webView != nil }, set: { _ in })) {
                webView
            }
        }
    }
}

#Preview {
    SettingsView(
        dataController: SwiftDataController(modelContext: previewContainer.mainContext),
        isPresented: .constant(true)
    )
        .environment(SubscriptionManager())
}
