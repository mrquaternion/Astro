//
//  SatelliteListView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-13.
//

import SwiftUI
import SwiftData
import VariableBlur

struct SatelliteListView: View {
    /// Shared home state used to read and change the selected satellite.
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    /// Subscription store used to decide whether locked assets can be opened.
    @Environment(SubscriptionManager.self) private var store
    
    /// Mutable view state tracking downloadManager.
    @StateObject private var downloadManager = LocalDownloadManager()
    
    /// Binding that controls presentation of the satellite list.
    @Binding var isPresented: Bool
    
    /// The selectable list of cached satellite assets.
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(homeViewModel.assets, id: \.id) { asset in
                    Button {
                        select(asset)
                    } label: {
                        SatelliteCard(
                            asset: asset,
                            isSelected: asset.id == homeViewModel.selectedSatellite?.id,
                            isLocked: !SubscriptionHelper.isEligibleTo(
                                .satellite(fileName: asset.modelFilename),
                                with: store
                            )
                        )
                        .environmentObject(downloadManager)
                    }
                    .buttonStyle(.plain)
                    .disabled(homeViewModel.isAssetLoading)
                }
            }
            .padding()
        }
        .overlay {
            if homeViewModel.assets.isEmpty {
                ContentUnavailableView(
                    "satellite_none".localizedFirstCapitalized,
                    systemImage: "antenna.radiowaves.left.and.right"
                )
            }
        }
        .safeAreaInset(edge: .top) {
            ZStack {
                Text("satellite_plural".localizedFirstCapitalized)
                    .font(.headline)
                
                HStack {
                    Spacer()
                    
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .tint(.primary)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 24)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $homeViewModel.showPaywall) {
            Paywall()
                .environment(store)
        }
    }
    
    private func select(_ asset: CachedTrackedAsset) {
        print("Has active subscription: \(store.hasActivateSubscription)")
        if asset.id == homeViewModel.selectedSatellite?.id {
            isPresented = false
        } else if !SubscriptionHelper.isEligibleTo(
            .satellite(fileName: asset.modelFilename),
            with: store
        ) {
            homeViewModel.showPaywall = true
        } else {
            isPresented = false
            
            Task {
                asset.lastAccessedAt = .now
                await homeViewModel.loadAsset(for: asset)
            }
        }
    }
}

#Preview {
    SatelliteListView(isPresented: .constant(true))
        .environmentObject(HomeViewModel(dataController: SwiftDataController(modelContext: previewContainer.mainContext), subscriptionManager: SubscriptionManager()))
        .environment(SubscriptionManager())
}
