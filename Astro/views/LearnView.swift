//
//  LearnView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-23.
//

import SwiftUI
import SwiftUIIntrospect

struct LearnView: View {
    
    /// Environment value supplying learnViewModel.
    @EnvironmentObject private var learnViewModel: LearnViewModel
    
    /// Reports the UIKit scroll view that backs the learn list.
    var onScrollViewResolved: (UIScrollView) -> Void = { _ in }
    
    var body: some View {
        Group {
            // fetching assets
            if learnViewModel.areLearnAssetsLoading && learnViewModel.assets.isEmpty {
                LearnLoadingTemplateView()
            } else { // fetched
                if learnViewModel.assets.isEmpty {
                    ContentUnavailableView("No assets available", systemImage: "book")
                        .foregroundStyle(.white)
                } else {
                    LearnListView(onScrollViewResolved: onScrollViewResolved)
                }
            }
        }
    }
}

struct LearnListView: View {
    /// Subscription store used to decide whether locked assets can be opened.
    @Environment(SubscriptionManager.self) private var store
    
    /// App manager that holds variables available across the app.
    @Environment(AppState.self) private var appState
    
    /// Environment value supplying learnViewModel.
    @EnvironmentObject private var learnViewModel: LearnViewModel
   
    /// Reports the UIKit scroll view that backs the learn list.
    var onScrollViewResolved: (UIScrollView) -> Void = { _ in }
    
    /// Asset identifiers currently pushed onto the learn navigation stack.
    @State private var navigationPath: [String] = []
    
    /// Mutable view state tracking downloadManager.
    @StateObject private var downloadManager = LocalDownloadManager()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(learnViewModel.assets, id: \.id) { asset in
                        NavigationLink(value: asset.id) {
                            LearnItemLinkLabelView(asset: asset)
                                .environmentObject(downloadManager)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .padding(.bottom, CustomTabBarLayout.height + CustomTabBarLayout.yOffset)
            }
            .introspect(.scrollView, on: .iOS(.v26), customize: onScrollViewResolved)
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("Learn")
            .fullScreenCover(isPresented: $learnViewModel.showPaywall) {
                Paywall()
                    .environment(store)
            }
            .navigationDestination(for: String.self, destination: destination)
        }
        .onChange(of: navigationPath.isEmpty, initial: true) { _, isAtRoot in
            appState.setBottomBarVisible(isAtRoot, animated: false)
        }
    }
    
    @ViewBuilder
    private func destination(for assetID: String) -> some View {
        if let asset = learnViewModel.assets.first(where: { $0.id == assetID }) {
            LearnItemView(asset: asset)
                .navigationBarBackButtonHidden()
                .toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            ContentUnavailableView("Asset unavailable", systemImage: "cube.transparent")
        }
    }
}
