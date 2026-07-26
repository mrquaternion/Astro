    //
    //  HomeViewMapOverlay.swift
    //  Astro
    //
    //  Created by Mathias La Rochelle on 2026-06-21.
    //

    import SwiftUI
    import MapboxMaps
    import SwiftData

    struct HomeViewMapOverlay: View {
        /// Color scheme of the app, based on system appearance.
        @Environment(\.colorScheme) var colorScheme
        
        /// Whether the current device is an iPad.
        @Environment(\.isPad) private var isPad
        
        /// Shared home state that provides selected satellite metadata.
        @EnvironmentObject var viewViewModel: HomeViewModel
        
        /// Network monitor used to display connection status.
        @EnvironmentObject var network: NetworkMonitor
        
        /// Live satellite tracking state shown by the overlay.
        @ObservedObject var tracker: SatelliteTrackingViewModel
        
        /// Current selected mode controlled by the overlay.
        @Binding var mode: CustomMode
        
        /// Whether the modal sheet for the types of layers shows up or not.
        @Binding var openLayerMenu: Bool
        
        init(
            tracker: SatelliteTrackingViewModel,
            mode: Binding<CustomMode>,
            openLayerMenu: Binding<Bool>
        ) {
            _tracker = ObservedObject(wrappedValue: tracker)
            _mode = mode
            _openLayerMenu = openLayerMenu
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
                        expandingControlCapsule()
                    }
                }
                .padding(.top, (isPad ? 16 : 0))
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
                        .font(.title2)
                        .foregroundStyle(.mapGlassBackgroundContent())
                        .symbolVariant(.fill)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
            }
            .frame(width: (isPad ? 55 : 50), height: (isPad ? 55 : 50))
            .contentShape(.circle)
            .background(Circle().fill(.mapGlassBackground()))
            .glassEffect(.clear.interactive(), in: .circle)
        }
        
        @ViewBuilder
        func expandingControlCapsule() -> some View {
            let isExpanded = !tracker.isTrackingModel

            GlassEffectContainer(spacing: 20) {
                VStack(spacing: 20) {
                    Button {
                        openLayerMenu.toggle()
                    } label: {
                        Image(systemName: "square.3.layers.3d.top.filled")
                            .font(.title2)
                            .foregroundStyle(.mapGlassBackgroundContent())
                            .symbolVariant(.fill)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)

                    if isExpanded {
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
                                .foregroundStyle(.mapGlassBackgroundContent())
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .frame(width: isPad ? 55 : 50, height: isExpanded ? (isPad ? 110 : 100) : (isPad ? 55 : 50))
                .background(
                    (isExpanded ? AnyShape(Capsule()) : AnyShape(Circle()))
                        .fill(.mapGlassBackground())
                )
                .glassEffect(
                    .clear.interactive(),
                    in: isExpanded ? AnyShape(Capsule()) : AnyShape(Circle())
                )
            }
            .animation(.smooth, value: isExpanded)
        }
        
        @ViewBuilder
        func layerButton() -> some View {
            ZStack {
                Button {
                    openLayerMenu.toggle()
                } label: {
                    Image(systemName: "square.3.layers.3d.top.filled")
                        .font(.title2)
                        .foregroundStyle(.mapGlassBackgroundContent())
                        .symbolVariant(.fill)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
            }
            .frame(width: (isPad ? 55 : 50), height: (isPad ? 55 : 50))
            .contentShape(.circle)
            .background(Circle().fill(.mapGlassBackground()))
            .glassEffect(.clear.interactive(), in: .circle)
        }
        
        @ViewBuilder
        func recenterISSButton() -> some View {
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
                        .foregroundStyle(.mapGlassBackgroundContent())
                }
                .buttonStyle(.plain)
            }
            .frame(width: (isPad ? 55 : 50), height: (isPad ? 55 : 50))
            .contentShape(.circle)
            .background(Circle().fill(.mapGlassBackground()))
            .glassEffect(.clear.interactive(), in: .circle)
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
            .foregroundStyle(.mapGlassBackgroundContent())
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(.mapGlassBackground()))
            .glassEffect(.clear, in: .rect(cornerRadius: 16))
        }
    }

    #Preview {
        @Previewable @State var mode: CustomMode = .photography
        
        HomeViewMapOverlay(
            tracker: SatelliteTrackingViewModel(),
            mode: .constant(.exploration),
            openLayerMenu: .constant(false)
        )
        .environmentObject(HomeViewModel(dataController: SwiftDataController(modelContext: previewContainer.mainContext), subscriptionManager: SubscriptionManager()))
        .environmentObject(NetworkMonitor())
    }
