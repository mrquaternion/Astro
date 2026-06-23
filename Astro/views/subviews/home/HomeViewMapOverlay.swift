//
//  HomeViewMapOverlay.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-21.
//

import SwiftUI
import MapboxMaps

struct HomeViewMapOverlay: View {
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) var colorScheme
    
    /// Whether the current device is an iPhone.
    @Environment(\.isPhone) private var isPhone
    
    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad
    
    /// Shared home state that provides selected satellite metadata.
    @EnvironmentObject var viewViewModel: HomeViewModel
    
    /// Live satellite tracking state shown by the overlay.
    @ObservedObject var tracker: SatelliteTrackingViewModel
    
    /// Current selected mode controlled by the overlay.
    @Binding var mode: CustomMode
    
    /// Network monitor used to display connection status.
    @StateObject private var network = NetworkMonitor()
    
    /// Check if current device is in landscape mode.
    private var isInLandscape: Bool {
        UIDevice.current.orientation.isLandscape
    }
    
    /// Check if current device is iPhone and in landscape mode.
    private var isPhoneAndLandscape: Bool {
        isPhone && isInLandscape
    }
    
    /// The map overlay with status, stats, and recenter controls.
    var body: some View {
        VStack {
            VStack(spacing: 12) {
                if !network.isConnected {
                    HStack {
                        Image(systemName: AstroError.noWifiConnection.symbol)
                        Text(AstroError.noWifiConnection.description)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .glassEffect(.regular, in: .capsule)
                }
                
                issStats()
                
                HStack {
                    Spacer()
                    GlassEffectContainer(spacing: 12) {
                        VStack(spacing: 12) {
                            // modeButton()
                            // only if user moved from camera's centerpoint
                            recenterISSButton()
                        }
                    }
                }
            }
            .padding(.top, ((isPad || isPhoneAndLandscape) ? 16 : 0))
            .padding(.horizontal, (isPad ? 16 : 0))
            
            // pushes the content up
            Spacer()
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func modeButton() -> some View {
        ZStack {
            Button {
                if mode == .exploration {
                    mode = .photography
                } else {
                    mode = .exploration
                }
            } label: {
                Image(systemName: mode.symbol)
                    .font(.system(size: (isPad ? 22 : 20), weight: .medium))
                    .foregroundStyle(.glassBackgroundContent(colorScheme))
                    .symbolVariant(.fill)
            }
            .buttonStyle(.plain)
        }
        .frame(width: (isPad ? 55 : 50), height: (isPad ? 55 : 50))
        .contentShape(.circle)
        .glassEffect(.regular.interactive().tint(.glassBackground(colorScheme)), in: .circle)
    }
    
    @ViewBuilder
    func recenterISSButton() -> some View {
        if !tracker.isTrackingModel {
            ZStack {
                Button {
                    tracker.camera = CameraState(
                        center: CLLocationCoordinate2D(
                            latitude: tracker.model.position[1],
                            longitude: tracker.model.position[0]
                        ),
                        padding: tracker.camera.padding,
                        zoom: tracker.camera.zoom,
                        bearing: tracker.camera.bearing,
                        pitch: tracker.camera.pitch
                    )
                    tracker.isTrackingModel = true
                } label: {
                    Image(systemName: "scope")
                        .font(.system(size: (isPad ? 22 : 20), weight: .medium))
                        .foregroundStyle(.glassBackgroundContent(colorScheme))
                }
                .buttonStyle(.plain)
            }
            .frame(width: (isPad ? 55 : 50), height: (isPad ? 55 : 50))
            .contentShape(.circle)
            .glassEffect(.regular.interactive().tint(.glassBackground(colorScheme)), in: .circle)
        }
    }
    
    @ViewBuilder
    func issStats() -> some View {
        VStack(alignment: .center, spacing: 8) {
            HStack {
                Text("\(viewViewModel.selectedSatellite?.shortName ?? "Satellite") Stats")
                Image(systemName: "antenna.radiowaves.left.and.right")
            }
            .font(isPad ? .title3 : .callout)
            .fontWeight(.semibold)
            
            Divider()
                .padding(.horizontal)
            
            Grid(alignment: .center, verticalSpacing: 4) {
                GridRow {
                    Text("Latitude:").frame(maxWidth: .infinity)
                    Text("Longitude:").frame(maxWidth: .infinity)
                    Text("Altitude:").frame(maxWidth: .infinity)
                    Text("Velocity:").frame(maxWidth: .infinity)
                }
                GridRow {
                    Text("\(String(format: "%.2f", tracker.model.position[1]))°").frame(maxWidth: .infinity)
                    Text("\(String(format: "%.2f", tracker.model.position[0]))°").frame(maxWidth: .infinity)
                    Text("\(String(format: "%.1f", tracker.model.altitude)) km").frame(maxWidth: .infinity)
                    Text("\(String(format: "%.2f", tracker.model.velocity)) km/s").frame(maxWidth: .infinity)
                }
            }
            .font(isPad ? .body : .footnote)
            .monospacedDigit()
        }
        .foregroundStyle(.glassBackgroundContent(colorScheme))
        .padding(12)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(.glassBackground(colorScheme)), in: .rect(cornerRadius: 16))
    }
}

#Preview {
    HomeViewMapOverlay(tracker: SatelliteTrackingViewModel(), mode: .constant(CustomMode.exploration))
        .environmentObject(HomeViewModel())
}
