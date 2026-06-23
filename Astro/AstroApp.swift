//
//  AstroApp.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-02.
//

import SwiftUI
import SwiftData

@main
struct AstroApp: App {
    /// The app scene that hosts Astro's root view.
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: [
            CachedAsset.self,
            CachedArticle.self,
            CachedArticle.ArticleLaunch.self,
            CachedArticle.ArticleEvent.self
        ])
    }
}

struct AppRootView: View {
    /// The SwiftData context used during app bootstrap.
    @Environment(\.modelContext) private var modelContext
    
    /// Loads the app's startup data before the main interface is shown.
    @StateObject private var bootstrapper = BootstrapViewModel()
    
    /// Shared home state injected into the main view hierarchy.
    @StateObject private var homeViewModel = HomeViewModel()
    
    /// Shared subscription store injected into views that need purchase state.
    @State private var store = SubscriptionManager()
    
    /// The root view content shown after bootstrap completes.
    var body: some View {
        Group {
            if !bootstrapper.isLoading {
                MainView()
            } else {
                SplashScreenView()
            }
        }
        .environmentObject(bootstrapper)
        .environmentObject(homeViewModel)
        .environment(store)
        .environment(\.isPhone, DeviceIdiom.isPhone)
        .environment(\.isPad, DeviceIdiom.isPad)
        .task {
            await bootstrapper.bootstrap(modelContext: modelContext, homeViewModel: homeViewModel)
        }
    }
}
