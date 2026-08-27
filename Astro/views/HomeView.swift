//
//  HomeView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-04.
//

import SwiftUI
import MapboxMaps
import SwiftData
import UIKit

struct HomeView: View {
    /// Whether the current interface space is wider than it is tall.
    @Environment(\.isLandscape) private var isLandscape
    
    /// Environment value supplying horizontalSizeClass.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// Tracks the selected satellite's live position and camera state.
    @StateObject private var satelliteTracker = SatelliteTrackingViewModel()
    
    /// Current selected mode controlled by the overlay.
    @Binding var activeMode: CustomMode
    
    /// Whether the modal sheet for the types of layers shows up or not.
    @Binding var openLayerMenu: Bool
    
    ///  Map layers configuration.
    @Binding var config: MapConfiguration
    
    /// Trailing screen-space inset reserved for the satellite inspector.
    let mapTrailingPadding: CGFloat
    
    /// The home map with its satellite tracking overlay.
    var body: some View {
        ZStack {
            HomeViewMapContainer(config: $config)
                .environmentObject(satelliteTracker)
                // redraw the map when switching orientation on iPad devices
                .id(isLandscape)
            
            HomeViewMapOverlay(
                tracker: satelliteTracker,
                mode: $activeMode,
                openLayerMenu: $openLayerMenu
            )
        }
        .onAppear {
            updateCameraPadding()
        }
        .onChange(of: mapTrailingPadding) {
            updateCameraPadding()
        }
        .animation(.default, value: satelliteTracker.isTrackingModel)
        .sheet(isPresented: $openLayerMenu) {
            HomeViewLayerMenu(config: $config)
                .presentationDetents(horizontalSizeClass == .compact ? [.medium] : [])
        }
    }
    
    private func updateCameraPadding() {
        satelliteTracker.camera = CameraState(
            center: satelliteTracker.camera.center,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: mapTrailingPadding),
            zoom: satelliteTracker.camera.zoom,
            bearing: satelliteTracker.camera.bearing,
            pitch: satelliteTracker.camera.pitch
        )
    }
}

#Preview {
    HomeView(
        activeMode: .constant(CustomMode.exploration),
        openLayerMenu: .constant(true),
        config: .constant(MapConfiguration()),
        mapTrailingPadding: .zero
    )
    .environmentObject(HomeViewModel(dataController: SwiftDataController(modelContext: previewContainer.mainContext), subscriptionManager: SubscriptionManager()))
    .environmentObject(NetworkMonitor())
}

extension ShapeStyle where Self == Color {
    static func mapGlassBackgroundContent() -> Color {
        Color.white
    }
    
    static func mapGlassBackground() -> Color {
        Color(.black)
            .mix(with: .gray, by: 0.4)
            .opacity(0.5)
    }
}
