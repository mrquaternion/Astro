//
//  HomeView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-04.
//

import SwiftUI
import MapboxMaps

struct HomeView: View {
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) var colorScheme
    
    /// Shared home state that provides the selected satellite.
    @EnvironmentObject var viewViewModel: HomeViewModel
    
    /// Tracks the selected satellite's live position and camera state.
    @StateObject private var satelliteTracker = SatelliteTrackingViewModel()
    
    /// To help redraw the map.
    @State private var orientation = UIDevice.current.orientation
    
    /// Current selected mode.
    @Binding var activeMode: CustomMode

    /// The home map with its satellite tracking overlay.
    var body: some View {
        ZStack {
            HomeViewMap()
                .environmentObject(satelliteTracker)
                // redraw the map when switching orientation on iPad devices
                .id(orientation.isLandscape)
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIDevice.orientationDidChangeNotification
                    )
                ) { _ in
                    orientation = UIDevice.current.orientation
                }
            
            HomeViewMapOverlay(tracker: satelliteTracker, mode: $activeMode)
        }
        .animation(.default, value: satelliteTracker.isTrackingModel)
    }
}

#Preview {
    HomeView(activeMode: .constant(CustomMode.exploration))
        .environmentObject(HomeViewModel())
}

extension ShapeStyle where Self == Color {
    static func glassBackgroundContent(_ scheme: ColorScheme) -> Color {
        return scheme == .dark ? .white : .black
    }
    
    static func glassBackground(_ scheme: ColorScheme) -> Color {
        return scheme == .dark ? .black.mix(with: .white, by: 0.4) : .white.mix(with: .black, by: 0.2)
    }
}

extension UIDeviceOrientation {
    /// The device orientation reported by UIKit.
    static var current: UIDeviceOrientation { UIDevice.current.orientation }
}
