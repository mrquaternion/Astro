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
    /// SwiftData model types included in the app container.
    static let modelTypes: [any PersistentModel.Type] = [
        BaseAsset.self,
        CachedTrackedAsset.self,
        CachedLearnAsset.self,
        CachedLearnAsset.LearnComponent.self,
        CachedLearnAsset.LearnComponentTimelineEvent.self,
        CachedLearnAsset.LearnComponentDetail.self,
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
    
    /// App manager that holds variables available across the app
    @State private var appState = AppState()
    
    /// Manages the state and data for the home view, including selected satellite and route information.
    @State private var homeViewModel: HomeViewModel?
    
    /// Mutable view state tracking learnViewModel.
    @State private var learnViewModel: LearnViewModel?

    /// Mission state retained for the lifetime of the main interface.
    @State private var missionsViewModel: MissionsViewModel?

    /// News state retained for the lifetime of the main interface.
    @State private var newsViewModel: SpaceNewsViewModel?
    
    /// The root view content shown after bootstrap completes.
    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.isLandscape
            
            Group {
                if
                    !bootstrapper.isLoading,
                    let dataController,
                    let homeViewModel,
                    let learnViewModel,
                    let missionsViewModel,
                    let newsViewModel
                {
                    MainView(
                        homeViewModel: homeViewModel,
                        learnViewModel: learnViewModel,
                        missionsViewModel: missionsViewModel,
                        newsViewModel: newsViewModel,
                        dataController: dataController
                    )
                } else {
                    SplashScreenView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(bootstrapper)
            .environmentObject(networkMonitor)
            .environment(store)
            .environment(appState)
            .environment(\.isPhone, DeviceIdiom.isPhone)
            .environment(\.isPad, DeviceIdiom.isPad)
            .environment(\.isLandscape, isLandscape)
            .task {
                guard dataController == nil else { return }
                
                let controller = SwiftDataController(modelContext: modelContext)
                dataController = controller
                
                homeViewModel = HomeViewModel(
                    dataController: controller,
                    subscriptionManager: store
                )
                
                learnViewModel = LearnViewModel(
                    dataController: controller,
                    subscriptionManager: store
                )

                missionsViewModel = MissionsViewModel()

                newsViewModel = SpaceNewsViewModel(
                    dataController: controller,
                    subscriptionManager: store
                )
                
                await bootstrapper.bootstrap(homeViewModel: homeViewModel!)
            }
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

    /// Model context backing all persistence operations.
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
