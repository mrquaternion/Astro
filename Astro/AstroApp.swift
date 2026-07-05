//
//  AstroApp.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-02.
//

import SwiftUI
import SwiftData
import Combine


@main
struct AstroApp: App {
    /// The app scene that hosts Astro's root view.
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: AppConstants.modelTypes)
    }
}

enum AppConstants {
    static let modelTypes: [any PersistentModel.Type] = [
        CachedAsset.self,
        CachedArticle.self,
        CachedArticle.ArticleLaunch.self,
        CachedArticle.ArticleEvent.self
    ]
}

struct AppRootView: View {
    /// The SwiftData context used during app bootstrap.
    @Environment(\.modelContext) private var modelContext
    
    /// Manages persistent data storage and model access throughout the app.
    @State private var dataController: SwiftDataController?
    
    /// Loads the app's startup data before the main interface is shown.
    @StateObject private var bootstrapper = BootstrapViewModel()
    
    /// Network monitor used to display connection status.
    @StateObject private var networkMonitor = NetworkMonitor()
    
    /// Shared subscription store injected into views that need purchase state.
    @State private var store = SubscriptionManager()
    
    /// Manages the state and data for the home view, including selected satellite and route information.
    @State private var homeViewModel: HomeViewModel?
    
    /// The root view content shown after bootstrap completes.
    var body: some View {
        Group {
            if !bootstrapper.isLoading,
                let homeViewModel,
                let dataController
            {
                MainView(homeViewModel: homeViewModel, dataController: dataController)
            } else {
                SplashScreenView()
            }
        }
        .environmentObject(bootstrapper)
        .environmentObject(networkMonitor)
        .environment(store)
        .environment(\.isPhone, DeviceIdiom.isPhone)
        .environment(\.isPad, DeviceIdiom.isPad)
        .task {
            guard dataController == nil else { return }
            
            let controller = SwiftDataController(modelContext: modelContext)
            dataController = controller
            
            homeViewModel = HomeViewModel(
                dataController: controller,
                subscriptionManager: store
            )
            
            await bootstrapper.bootstrap(homeViewModel: homeViewModel!)
        }
    }
}

@MainActor
protocol DataController {
    func saveChanges() throws
    func save<T: PersistentModel>(_ model: T) throws
    func saveFile(data: Data, at path: URL) throws
    func delete<T: PersistentModel>(_ model: T) throws
    func fetchSaved<T: PersistentModel>(_ type: T.Type) throws -> [T]
}

@MainActor
final class SwiftDataController: DataController {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func saveChanges() throws {
        try modelContext.save()
    }

    func save<T: PersistentModel>(_ model: T) throws {
        modelContext.insert(model)
        try modelContext.save()
    }
    
    func saveFile(data: Data, at path: URL) throws {
        try data.write(to: path)
    }

    func delete<T: PersistentModel>(_ model: T) throws {
        modelContext.delete(model)
        try modelContext.save()
    }

    func fetchSaved<T: PersistentModel>(_ type: T.Type) throws -> [T] {
        try modelContext.fetch(FetchDescriptor<T>())
    }
}
