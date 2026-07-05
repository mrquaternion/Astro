//
//  ContentView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-02.
//

import SwiftUI
import SwiftData

enum ActionButtonState {
    case satellite
    case settings
    
    var image: Image {
        switch self {
        case .satellite:
            Image("satellite")
        case .settings:
            Image(systemName: "gearshape")
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
    
    /// Network monitor used to display connection status.
    @EnvironmentObject var network: NetworkMonitor
    
    /// Whether the current device is an iPhone.
    @Environment(\.isPhone) private var isPhone
    
    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad
    
    /// Shared home state used by the selected tab and satellite picker.
    @ObservedObject var homeViewModel: HomeViewModel
    
    /// Manages persistent data storage and model access throughout the app.
    private let dataController: DataController
    
    /// Current selected mode.
    @State private var activeMode: CustomMode = .exploration
    
    /// Current selected tab.
    @State private var activeTab: CustomTab = .home
    
    /// Present different satellites.
    @State private var isSatelliteListPresented = false
    
    /// Present settings.
    @State private var isSettingsPresented = false
    
    private var actionButtonState: ActionButtonState {
        activeTab == .home ? .satellite : .settings
    }
    
    /// Current selected mode's tabs.
    var currentTabs: [CustomTab] { activeMode.tabs }
    
    init(homeViewModel: HomeViewModel, dataController: DataController) {
        self.homeViewModel = homeViewModel
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
                    
                    GlassEffectContainer(spacing: 6) {
                        HStack(spacing: 12) {
                            homeButton()
                            tabBar()
                            actionButton()
                        }
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
            SettingsView(isPresented: $isSettingsPresented)
        }
        .task {
            do {
                try await homeViewModel.fetchAssetsMetadata(networkMonitor: network)
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
                HomeView(activeMode: $activeMode)
                    .environmentObject(homeViewModel)
                
            case .missions:
                MissionsView()
                
            case .news:
                NewsView(dataController: dataController, subscriptionManager: store)
                
            case .learn:
                LearnView()
                
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
                    .foregroundStyle(.glassBackgroundContent(colorScheme))
                    .symbolVariant(activeTab == .home ? .fill : .none)
            }
        }
        .frame(width: CustomTabBarLayout.height, height: CustomTabBarLayout.height)
        .contentShape(.circle)
        .glassEffect(.regular.tint(.glassBackground(colorScheme)), in: .circle)
    }
    
    @ViewBuilder
    func tabBar() -> some View {
        GeometryReader {
            CustomTabBar(size: $0.size, tabs: currentTabs, activeTab: $activeTab) { tab in
                VStack {
                    Image(systemName: tab.symbol)
                        .font(.title3)
                    
                    Text(tab.rawValue)
                        .font(.system(size: 10))
                        .fontWeight(.medium)
                }
                .foregroundStyle(.glassBackgroundContent(colorScheme))
                .symbolVariant(.fill)
            }
            .glassEffect(.regular.interactive().tint(.glassBackground(colorScheme)), in: .capsule)
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
                .foregroundStyle(.glassBackgroundContent(colorScheme))
                .frame(width: CustomTabBarLayout.height, height: CustomTabBarLayout.height)
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
        }
        .buttonStyle(.plain)
        .contentShape(.circle)
        .glassEffect(
            .regular.interactive().tint(.glassBackground(colorScheme)),
            in: .circle
        )
        .accessibilityLabel("Choose satellite")
    }
}

enum CustomTabBarLayout {
    static let height: CGFloat = 55
    static let yOffset: CGFloat = 16
}

