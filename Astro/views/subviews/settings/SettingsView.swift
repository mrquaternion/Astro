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
                    Section("settings_account".localizedFirstCapitalized) {
                        NavigationLink("settings_subscription".localizedFirstCapitalized) {
                            SubscriptionSettings()
                                .environment(store)
                                .navigationTitle("settings_subscription".localizedFirstCapitalized)
                                .navigationBarTitleDisplayMode(.inline)
                        }
                        NavigationLink("settings_downloads".localizedFirstCapitalized) {
                            DownloadSettings(dataController: dataController)
                                .navigationTitle("settings_downloads".localizedFirstCapitalized)
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                    
                    Section("settings_about".localizedFirstCapitalized) {
                        NavigationLink("settings_privacy_policy".localizedFirstCapitalized) {
                            WebView(url: URL(string: "https://someonelostinspace.github.io/astro-web/privacy.html")!)
                                .ignoresSafeArea()
                        }
                        NavigationLink("settings_terms_of_service".localizedFirstCapitalized) {
                            WebView(url: URL(string: "https://someonelostinspace.github.io/astro-web/terms.html")!)
                                .ignoresSafeArea()
                        }
                        
                        HStack {
                            Text("settings_version".localizedFirstCapitalized)
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("settings_title".localizedFirstCapitalized)
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
