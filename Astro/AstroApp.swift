//
//  AstroApp.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-02.
//

import SwiftUI
import SwiftData
import Combine
import CoreLocation

enum ScreenshotMode {
    #if DEBUG
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("--screenshot-mode")
    #else
    static let isEnabled = false
    #endif
    
    /// A stable point in the orbit, measured from the epoch of the latest TLE.
    static var satelliteMinutesAfterEpoch: Double {
        argument(named: "--screenshot-satellite-minutes-after-epoch") ?? 30
    }
    
    /// Optional camera center. When omitted, the camera remains centered on the satellite.
    static var cameraCenter: CLLocationCoordinate2D? {
        guard
            let latitude: Double = argument(named: "--screenshot-camera-latitude"),
            let longitude: Double = argument(named: "--screenshot-camera-longitude")
        else {
            return nil
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static var cameraZoom: CGFloat? {
        let value: Double? = argument(named: "--screenshot-camera-zoom")
        return value.map { CGFloat($0) }
    }
    
    static var cameraBearing: CGFloat? {
        let value: Double? = argument(named: "--screenshot-camera-bearing")
        return value.map { CGFloat($0) }
    }
    
    static var cameraPitch: CGFloat? {
        let value: Double? = argument(named: "--screenshot-camera-pitch")
        return value.map { CGFloat($0) }
    }
    
    private static func argument<Value: LosslessStringConvertible>(named name: String) -> Value? {
        let arguments = ProcessInfo.processInfo.arguments
        let assignmentPrefix = "\(name)="
        
        if let assignment = arguments.first(where: { $0.hasPrefix(assignmentPrefix) }) {
            return Value(String(assignment.dropFirst(assignmentPrefix.count)))
        }
        
        guard
            let nameIndex = arguments.firstIndex(of: name),
            arguments.indices.contains(arguments.index(after: nameIndex))
        else {
            return nil
        }
        
        return Value(arguments[arguments.index(after: nameIndex)])
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard
            let urlString = response.notification.request.content.userInfo["url"] as? String,
            let url = URL(string: urlString)
        else { return }
        await UIApplication.shared.open(url)
    }
}

@main
struct AstroApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// The app scene that hosts Astro's root view.
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: AppConstants.modelTypes)
    }
}

private extension URL {
    /// Launch ID carried by Astro notification deep links.
    var launchDeepLinkID: String? {
        if
            let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
            let queryLaunchID = components.queryItems?.first(where: { $0.name == "launch_id" })?.value
        {
            return queryLaunchID
        }

        guard let host else { return nil }
        let parts = host.split(separator: "=", maxSplits: 1)
        guard parts.count == 2, parts[0] == "launch_id" else { return nil }
        return String(parts[1])
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
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    /// The root view content shown after bootstrap completes.
    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.isLandscape
            
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                Group {
                    if
                        !bootstrapper.isLoading,
                        let dataController,
                        let homeViewModel,
                        let learnViewModel,
                        let missionsViewModel,
                        let newsViewModel
                    {
                        if !hasCompletedOnboarding && !ScreenshotMode.isEnabled {
                            OnboardingScreenView(onFinish: { hasCompletedOnboarding = true })
                                .transition(.opacity)
                        } else {
                            MainView(
                                homeViewModel: homeViewModel,
                                learnViewModel: learnViewModel,
                                missionsViewModel: missionsViewModel,
                                newsViewModel: newsViewModel,
                                dataController: dataController
                            )
                            .transition(.opacity)
                        }
                    } else {
                        SplashScreenView()
                            .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.8), value: bootstrapper.isLoading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(bootstrapper)
            .environmentObject(networkMonitor)
            .environment(store)
            .environment(appState)
            .environment(\.isPhone, DeviceIdiom.isPhone)
            .environment(\.isPad, DeviceIdiom.isPad)
            .environment(\.isLandscape, isLandscape)
            .onOpenURL { url in
                guard let launchID = url.launchDeepLinkID else { return }
                appState.requestMissionLaunchDetails(for: launchID)
            }
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
