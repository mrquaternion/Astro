//
//  ContentView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-02.
//

import SwiftUI
import SwiftData
import UIKit

enum ActionButtonState {
    case satellite
    case settings
    
    /// The image shown inside the trailing action button.
    var image: Image {
        switch self {
        case .satellite:
            Image("satellite")
        case .settings:
            Image(systemName: "gearshape.fill")
        }
    }
}

struct MainView: View {
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) var colorScheme
    
    /// Detect device orientation.
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    /// Subscription store that loads products and performs purchases.
    @Environment(SubscriptionManager.self) private var store
    
    /// App manager that holds variables available across the app
    @Environment(AppState.self) private var appState
    
    /// Network monitor used to display connection status.
    @EnvironmentObject var network: NetworkMonitor
    
    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad
    
    /// Shared home state used by the selected tab and satellite picker.
    @ObservedObject var homeViewModel: HomeViewModel
    
    /// Observable model supplying learnViewModel.
    @ObservedObject var learnViewModel: LearnViewModel

    /// Observable model supplying missionsViewModel.
    @ObservedObject var missionsViewModel: MissionsViewModel

    /// Observable model supplying newsViewModel.
    @ObservedObject var newsViewModel: SpaceNewsViewModel

    /// Manages persistent data displayed and modified from settings.
    let dataController: DataController
    
    /// Current selected mode.
    @State private var activeMode: CustomMode = .exploration
    
    /// Present the different selectable layers.
    @State private var openLayerMenu = false
    
    /// Current selected tab.
    @State private var activeTab: CustomTab = .home

    /// UIKit scroll view underneath the currently selected tab.
    @State private var activeScrollView: UIScrollView?
    
    /// Present different satellites.
    @State private var isSatelliteListPresented = false
    
    /// Present settings.
    @State private var isSettingsPresented = false
    
    /// Map layers configuration.
    @State private var mapConfig = MapConfiguration()
    
    /// The trailing action shown for the current selected tab.
    private var actionButtonState: ActionButtonState {
        activeTab == .home ? .satellite : .settings
    }
    
    /// Current selected mode's tabs.
    var currentTabs: [CustomTab] { activeMode.tabs }
    
    init(
        homeViewModel: HomeViewModel,
        learnViewModel: LearnViewModel,
        missionsViewModel: MissionsViewModel,
        newsViewModel: SpaceNewsViewModel,
        dataController: DataController
    ) {
        self.homeViewModel = homeViewModel
        self.learnViewModel = learnViewModel
        self.missionsViewModel = missionsViewModel
        self.newsViewModel = newsViewModel
        self.dataController = dataController
    }
    
    /// The adaptive tab shell that switches between phone and pad layouts.
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                tabsContent()
                
                VStack(spacing: 12) {
                    // pushes the content down
                    Spacer()
                    
                    if appState.showBottomBar {
                        GlassEffectContainer(spacing: 6) {
                            HStack(spacing: 12) {
                                homeButton()
                                tabBar()
                                
                                actionButton()
                            }
                        }
                        .animation(.easeInOut, value: appState.showBottomBar)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if homeViewModel.isAssetLoading {
                    ProgressView("Loading satellite...")
                        .padding()
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                }
            }
            .conditionalPresentationAlt(isPresented: $isSatelliteListPresented, isPad: isPad) {
                SatelliteListView(isPresented: $isSatelliteListPresented)
                    .environmentObject(homeViewModel)
                    .presentationDetents([.fraction(0.4), .fraction(0.9)])
                    .inspectorColumnWidth(horizontalSizeClass == .regular ? proxy.size.width * 0.4 : proxy.size.width * 0.2)
            }
        }
        .fullScreenCover(isPresented: $isSettingsPresented) {
            SettingsView(
                dataController: dataController,
                isPresented: $isSettingsPresented
            )
            .environment(store)
        }
        // toggle the inspector off on iPad
        .onChange(of: activeTab) { _, newValue in
            activeScrollView = nil
            if newValue != .home {
                isSatelliteListPresented = false
            }
        }
        .task {
            do {
                try await homeViewModel.fetchAssetsMetadata(networkMonitor: network)
                try await learnViewModel.fetchAssetsMetadata(networkMonitor: network)
            } catch {
                print(error)
            }
        }
    }
    
    @ViewBuilder
    func tabsContent() -> some View {
        Group {
            switch activeTab {
            case .home:
                HomeView(activeMode: $activeMode, openLayerMenu: $openLayerMenu, config: $mapConfig)
                    .environmentObject(homeViewModel)
                
            case .missions:
                MissionsView(
                    viewModel: missionsViewModel,
                    onScrollViewResolved: resolveScrollView(for: .missions)
                )
                
            case .news:
                NewsView(
                    viewModel: newsViewModel,
                    onScrollViewResolved: resolveScrollView(for: .news)
                )
                
            case .learn:
                LearnView(onScrollViewResolved: resolveScrollView(for: .learn))
                    .environmentObject(learnViewModel)
                
            case .lookup:
                Text("Lookup View")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.mix(with: .gray, by: 0.4).mix(with: .blue, by: 0.3))
                
            case .community:
                Text("Community View")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.mix(with: .gray, by: 0.4).mix(with: .blue, by: 0.3))
            }
        }
    }
    
    @ViewBuilder
    func homeButton() -> some View {
        ZStack {
            Button {
                activeTab = .home
            } label: {
                Image(systemName: CustomTab.home.symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.mapGlassBackgroundContent())
                    .symbolVariant(activeTab == .home ? .fill : .none)
            }
        }
        .frame(width: CustomTabBarLayout.height, height: CustomTabBarLayout.height)
        .contentShape(.circle)
        .background(Circle().fill(.mapGlassBackground()))
        .glassEffect(.clear.interactive(), in: .circle)
        .accessibilityLabel("Home")
    }
    
    @ViewBuilder
    func tabBar() -> some View {
        GeometryReader {
            CustomTabBar(
                size: $0.size,
                barTint: colorScheme == .light ? .gray : .gray.opacity(0.3),
                tabs: currentTabs,
                activeTab: $activeTab,
                scrollView: activeScrollView
            ) { tab, isSelected in
                VStack {
                    Image(systemName: tab.symbol)
                        .font(.title3)
                    
                    Text(tab.rawValue)
                        .font(.system(size: 10))
                        .fontWeight(.medium)
                }
                .foregroundStyle(isSelected ? .blue.mix(with: .white, by: 0.2) : .mapGlassBackgroundContent())
                .symbolVariant(.fill)
            }
            .background(Capsule().fill(.mapGlassBackground()))
            .glassEffect(.clear.interactive(), in: .capsule)
        }
        .frame(height: CustomTabBarLayout.height)
    }
    
    @ViewBuilder
    func actionButton() -> some View {
        Button {
            if actionButtonState == .satellite {
                isSatelliteListPresented.toggle()
            } else {
                isSettingsPresented.toggle()
            }
        } label: {
            actionButtonState.image
                .font(.title2)
                .foregroundStyle(.mapGlassBackgroundContent())
                .frame(width: CustomTabBarLayout.height, height: CustomTabBarLayout.height)
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
        }
        .buttonStyle(.plain)
        .contentShape(.circle)
        .glassEffect(.clear.interactive().tint(.mapGlassBackground()), in: .circle)
        .accessibilityLabel("Choose satellite")
    }

    /// Accepts scroll views only from the tab that is still selected.
    private func resolveScrollView(for tab: CustomTab) -> (UIScrollView) -> Void {
        { scrollView in
            guard activeTab == tab, activeScrollView !== scrollView else { return }
            activeScrollView = scrollView
        }
    }
}

enum CustomTabBarLayout {
    /// Shared tab bar height for circular controls and the segmented bar.
    static let height: CGFloat = 55
    
    /// Vertical offset used by tab bar animations.
    static let yOffset: CGFloat = 16
}
