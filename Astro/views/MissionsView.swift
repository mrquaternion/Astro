//
//  MissionsView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-23.
//

import SwiftUI
import MapboxMaps
import SwiftUIIntrospect

struct MissionsView: View {
    /// Mission state supplied by the app root so it survives tab switches.
    @ObservedObject var viewModel: MissionsViewModel

    /// Reports the UIKit scroll view that backs the mission list.
    var onScrollViewResolved: (UIScrollView) -> Void = { _ in }

    /// Network monitor used to display connection status.
    @EnvironmentObject var network: NetworkMonitor
    
    /// App manager that holds variables available across the app.
    @Environment(AppState.self) private var appState
    
    /// Subscription store that loads products and performs purchases.
    @Environment(SubscriptionManager.self) private var store
    
    /// Environment value supplying isPad.
    @Environment(\.isPad) var isPad
    
    /// Launch identifiers currently pushed onto the missions navigation stack.
    @State private var navigationPath: [String] = []
    
    /// Value used for launches.
    var launches: [LaunchFeatureCollection.Feature] { viewModel.launches?.features ?? [] }
    
    /// Value used for layoutMetrics.
    var layoutMetrics: MissionsLayoutMetrics { .init(isPad: isPad) }
    
    var body: some View {
        Group {
            // fetching launches
            if viewModel.areLaunchesBeingFetch && viewModel.launches == nil && viewModel.error == nil {
                MissionsLoadingTemplateView(metrics: layoutMetrics)
            } else { // finished
                if viewModel.error != nil {
                    ContentUnavailableView {
                        Label("network_no_connection".localizedFirstCapitalized, systemImage: "wifi.slash")
                    } description: {
                        Text("network_check_connection".localizedFirstCapitalized)
                    } actions: {
                        Button("common_retry".localizedFirstCapitalized) {
                            Task {
                                try? await viewModel.fetchLaunchesMetadata(networkMonitor: network)
                            }
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.primary)
                    }
                } else {
                    missionsList
                }
            }
        }
        .task {
            try? await viewModel.loadLaunchesIfNeeded(networkMonitor: network)
            navigateToPendingLaunchIfPossible()
        }
        .onChange(of: appState.pendingMissionLaunchID, initial: true) { _, _ in
            navigateToPendingLaunchIfPossible()
        }
        .onChange(of: launches.map(\.id)) { _, _ in
            navigateToPendingLaunchIfPossible()
        }
    }
    
    /// View content rendered for missionsList.
    private var missionsList: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {                
                LazyVStack(alignment: .leading, spacing: layoutMetrics.spacing) {
                    ForEach(Array(launches.enumerated()), id: \.offset) { index, launch in
                        Divider()
                        
                        NavigationLink(value: launch.id) {
                            LaunchRow(properties: launch.properties, metrics: layoutMetrics)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        
                        if index == launches.count - 1 { Divider() }
                    }
                }
                .padding()
                .padding(.bottom, CustomTabBarLayout.height + CustomTabBarLayout.yOffset)
            }
            .introspect(.scrollView, on: .iOS(.v26), customize: onScrollViewResolved)
            .navigationTitle("tab_missions".localizedFirstCapitalized)
            .navigationSubtitle("missions_navigation_subtitle".localizedFirstCapitalized)
            .scrollBounceBehavior(.basedOnSize)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: isPad ? 12 : 8) {
                        Text("missions_next".localized)
                            .fontDesign(.monospaced)
                            
                        if let net = nextLaunchNET() {
                            ToolbarCountdown(net: net)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(isPad ? .title2 : .footnote)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal)
                }
            }
            .navigationDestination(for: String.self, destination: destination)
        }
        .onChange(of: navigationPath.isEmpty, initial: true) { _, isAtRoot in
            appState.setBottomBarVisible(isAtRoot, animated: false)
        }
    }
    
    @ViewBuilder
    private func destination(for launchID: String) -> some View {
        if let launch = launches.first(where: { $0.id == launchID }) {
            LaunchDetailView(launch: launch.properties)
                .navigationBarBackButtonHidden()
                .toolbarVisibility(.hidden, for: .navigationBar)
                .environment(store)
        } else {
            ContentUnavailableView("missions_launch_unavailable".localizedFirstCapitalized, systemImage: "paperplane")
        }
    }
    
    private func nextLaunchNET() -> Date? {
        launches
            .sorted { $0.properties.net < $1.properties.net }
            .first { $0.properties.net > .now }?
            .properties.net
    }

    private func navigateToPendingLaunchIfPossible() {
        guard
            let launchID = appState.pendingMissionLaunchID,
            launches.contains(where: { $0.id == launchID })
        else {
            return
        }

        navigationPath = [launchID]
        appState.consumePendingMissionLaunchID()
    }
}

#Preview("iPad") {
    MissionsView(viewModel: MissionsViewModel())
        .environment(\.isPhone, false)
        .environment(AppState())
        .environmentObject(NetworkMonitor())
}

#Preview("iPhone") {
    MissionsView(viewModel: MissionsViewModel())
        .environment(\.isPhone, true)
        .environment(AppState())
        .environmentObject(NetworkMonitor())
}
