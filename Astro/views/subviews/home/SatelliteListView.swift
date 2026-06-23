//
//  SatelliteListView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-13.
//

import SwiftUI
import SwiftData

struct SatelliteListView: View {
    /// Shared home state used to read and change the selected satellite.
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    /// Subscription store used to decide whether locked assets can be opened.
    @Environment(SubscriptionManager.self) private var store
    
    /// Cached satellite assets displayed in the list.
    @Query(sort: \CachedAsset.name) private var assets: [CachedAsset]
    
    /// Binding that controls presentation of the satellite list.
    @Binding var isPresented: Bool
    
    /// Controls presentation of the paywall for locked satellites.
    @State private var showPaywall = false
    
    /// The selectable list of cached satellite assets.
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(assets) { asset in
                        Button {
                            select(asset)
                        } label: {
                            SatelliteListItemView(
                                asset: asset,
                                isSelected: asset.id == homeViewModel.selectedSatellite?.id,
                                isLocked: !store.hasActivateSubscription
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(homeViewModel.isAssetLoading)
                    }
                }
                .padding()
            }
            .overlay {
                if assets.isEmpty {
                    ContentUnavailableView(
                        "No Satellites",
                        systemImage: "antenna.radiowaves.left.and.right"
                    )
                }
            }
            .navigationTitle("Satellites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close", systemImage: "xmark") {
                    isPresented = false
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            Paywall()
                .environment(store)
        }
    }
    
    private func select(_ asset: CachedAsset) {
        if asset.id == homeViewModel.selectedSatellite?.id {
            isPresented = false
        } else if !store.hasActivateSubscription {
            showPaywall = true
        } else {
            isPresented = false
            
            Task {
                asset.lastAccessedAt = .now
                await homeViewModel.downloadAsset(for: asset)
            }
        }
    }
}

#Preview {
    SatelliteListView(isPresented: .constant(true))
        .environmentObject(HomeViewModel())
        .environment(SubscriptionManager())
}
