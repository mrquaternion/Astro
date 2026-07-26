import SwiftUI
import Charts

enum HomeViewLayerDestination: Hashable {
    case basemaps
    case overlays
    case indicators
    
    /// Value used for title.
    var title: String {
        switch self {
        case .basemaps: "Basemaps"
        case .overlays: "Overlays"
        case .indicators: "Indicators"
        }
    }
}

struct HomeViewLayerMenu: View {
    /// Environment value supplying colorScheme.
    @Environment(\.colorScheme) var colorScheme
    
    /// Binding supplying config.
    @Binding var config: MapConfiguration
    
    /// Mutable view state tracking destination.
    @State private var destination: HomeViewLayerDestination?
    
    var body: some View {
        Group {
            if let destination {
                destinationView(destination)
            } else {
                layerMenu
            }
        }
    }
    
    /// View content rendered for layerMenu.
    private var layerMenu: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                layerSection("Basemaps") {
                    ForEach(MapConfiguration.MapBasemap.allCases, id: \.self) { basemap in
                        Button {
                            config.selectBasemap(basemap)
                        } label: {
                            optionView(
                                image: basemap.image,
                                name: basemap.name,
                                selected: isSelected(basemap, current: config.basemap)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                layerSection("Overlays", destination: .overlays) {
                    ForEach(MapConfiguration.MapOverlay.allCases, id: \.self) { overlay in
                        Button {
                            config.selectOverlay(overlay)
                        } label: {
                            optionView(
                                image: overlay.image,
                                name: overlay.name,
                                selected: isSelected(overlay, current: config.overlay)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                layerSection("Indicators", destination: .indicators) {
                    ForEach(MapConfiguration.MapIndicator.allCases, id: \.self) { indicator in
                        Button {
                            config.selectIndicator(indicator)
                        } label: {
                            optionView(
                                image: indicator.image,
                                name: indicator.name,
                                selected: isSelected(indicator, current: config.indicator)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }
    
    private func destinationView(_ destination: HomeViewLayerDestination) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                self.destination = nil
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    
                    Text(destination.title)
                        .font(.headline)
                        .bold()
                }
                .foregroundStyle(colorScheme == .light ? .black : .white)
            }
            .buttonStyle(.plain)
            
            HomeViewLayerDetails(destination: destination)
        }
        .padding([.top, .horizontal], 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    @ViewBuilder
    private func layerSection<Content: View>(
        _ title: String,
        destination: HomeViewLayerDestination? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(title)
                        .font(.headline)
                        .bold()
                    
                    if let destination {
                        Button {
                            self.destination = destination
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.headline)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                
                Divider()
            }
            
            ScrollView(.horizontal) {
                HStack(spacing: 24, content: content)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .scrollIndicators(.hidden)
        }
    }
    
    private func optionView(image: String, name: String, selected: Bool) -> some View {
        VStack(spacing: 10) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(selected ? Color.primary : Color.clear, lineWidth: 2)
                )
            
            Text(name)
                .font(.footnote)
                .fontWeight(selected ? .medium : .regular)
                .foregroundStyle(selected ? .primary : .secondary)
        }
    }
    
    private func isSelected<T: Equatable>(_ value: T, current: T) -> Bool {
        value == current
    }
}

struct HomeViewLayerDetails: View {
    
    /// Value used for destination.
    let destination: HomeViewLayerDestination
    
    var body: some View {
        Group {
            switch destination {
            case .basemaps:
                EmptyView()
            case .overlays:
                HomeViewLayerOverlayDetail(destination: destination)
            case .indicators:
                HomeViewLayerIndicatorDetail(destination: destination)
            }
        }
    }
}

private struct HomeViewLayerOverlayDetail: View {
    
    /// Mutable view state tracking selectedOverlay.
    @State private var selectedOverlay: MapConfiguration.MapOverlay = .clouds
    
    /// Value used for destination.
    let destination: HomeViewLayerDestination
    
    struct ColorScaleLevel: Identifiable {
        let id = UUID()
        let zone: String
        let zoneColor: Color
        let lpi: (Double, Double)
        let mparc: (Double, Double)
    }
    
    /// Value used for colorScaleLevels.
    let colorScaleLevels: [ColorScaleLevel] = [
        ColorScaleLevel(zone: "0",  zoneColor: .init(red: 0 / 255, green: 0 / 255, blue: 0 / 255),
                        lpi: (0.00, 0.01),    mparc: (21.99, 22.00)),
        ColorScaleLevel(zone: "1a", zoneColor: .init(red: 34 / 255, green: 34 / 255, blue: 34 / 255),
                        lpi: (0.01, 0.06),    mparc: (21.93, 21.99)),
        ColorScaleLevel(zone: "1b", zoneColor: .init(red: 66 / 255, green: 66 / 255, blue: 66 / 255),
                        lpi: (0.06, 0.11),    mparc: (21.89, 21.93)),
        ColorScaleLevel(zone: "2a", zoneColor: .init(red: 21 / 255, green: 47 / 255, blue: 114 / 255),
                        lpi: (0.11, 0.19),    mparc: (21.81, 21.89)),
        ColorScaleLevel(zone: "2b", zoneColor: .init(red: 33 / 255, green: 84 / 255, blue: 216 / 255),
                        lpi: (0.19, 0.33),    mparc: (21.69, 21.81)),
        ColorScaleLevel(zone: "3a", zoneColor: .init(red: 16 / 255, green: 87 / 255, blue: 19 / 255),
                        lpi: (0.33, 0.58),    mparc: (21.51, 21.69)),
        ColorScaleLevel(zone: "3b", zoneColor: .init(red: 30 / 255, green: 161 / 255, blue: 41 / 255),
                        lpi: (0.58, 1.00),    mparc: (21.25, 21.51)),
        ColorScaleLevel(zone: "4a", zoneColor: .init(red: 110 / 255, green: 100 / 255, blue: 31 / 255),
                        lpi: (1.00, 1.73),    mparc: (20.91, 21.25)),
        ColorScaleLevel(zone: "4b", zoneColor: .init(red: 184 / 255, green: 165 / 255, blue: 38 / 255),
                        lpi: (1.73, 3.00),    mparc: (20.49, 20.91)),
        ColorScaleLevel(zone: "5a", zoneColor: .init(red: 191 / 255, green: 100 / 255, blue: 29 / 255),
                        lpi: (3.00, 5.20),    mparc: (20.02, 20.49)),
        ColorScaleLevel(zone: "5b", zoneColor: .init(red: 253 / 255, green: 150 / 255, blue: 80 / 255),
                        lpi: (5.20, 9.00),    mparc: (19.50, 20.02)),
        ColorScaleLevel(zone: "6a", zoneColor: .init(red: 250 / 255, green: 90 / 255, blue: 73 / 255),
                        lpi: (9.00, 15.59),   mparc: (18.95, 19.50)),
        ColorScaleLevel(zone: "6b", zoneColor: .init(red: 250 / 255, green: 153 / 255, blue: 138 / 255),
                        lpi: (15.59, 27.00),  mparc: (18.38, 18.95)),
        ColorScaleLevel(zone: "7a", zoneColor: .init(red: 160 / 255, green: 160 / 255, blue: 160 / 255),
                        lpi: (27.00, 46.77),  mparc: (17.80, 18.38)),
        ColorScaleLevel(zone: "7b", zoneColor: .init(red: 242 / 255, green: 242 / 255, blue: 242 / 255),
                        lpi: (46.77, .infinity), mparc: (17, 17.80))
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Picker(destination.title, selection: $selectedOverlay) {
                ForEach(MapConfiguration.MapOverlay.allCases, id: \.self) { overlay in
                    Text(overlay.name)
                }
            }
            .pickerStyle(.segmented)
            
            ScrollView {
                Group {
                    switch selectedOverlay {
                    case .clouds:
                        cloudsDetail
                    case .lightPollution:
                        lightPollutionDetail
                    }
                }
                .padding(.bottom, 24)
                .padding(.top, 32)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
    }
    
    /// View content rendered for cloudsDetail.
    @ViewBuilder
    private var cloudsDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Cloud Map")
                .font(.title2.weight(.semibold))
            
            Text("Plan your observing sessions with near real-time cloud coverage. The overlay highlights where skies are clear and where clouds may obstruct visibility, allowing you to quickly find the best locations and times for stargazing or astrophotography. Cloud imagery is updated every 3 hours to reflect changing weather conditions.")
                .foregroundStyle(.secondary)
                .lineSpacing(4)
            
            HStack(spacing: .zero) {
                Text("Attribution: ")
                    .foregroundStyle(.secondary)
                Link("Live Cloud Maps", destination: URL(string: "https://github.com/matteason/live-cloud-maps")!)
                    .foregroundStyle(.blue)
                    .underline()
            }
            .font(.footnote)
        }
    }
    
    /// View content rendered for lightPollutionDetail.
    @ViewBuilder
    private var lightPollutionDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Light Pollution")
                .font(.title2.weight(.semibold))
            
            Text("Visualize the brightness of the night sky to quickly identify dark-sky locations for stargazing and astrophotography.")
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: .zero) {
                ForEach(Array(colorScaleLevels.enumerated()), id: \.element.id) { index, level in
                    let foregroundColor: Color = (index <= colorScaleLevels.count / 2) ? .white : .black
                    
                    ZStack {
                        level.zoneColor
                        
                        Text(level.zone)
                            .font(.footnote)
                            .fontDesign(.monospaced)
                            .foregroundStyle(foregroundColor)
                    }
                }
            }
            .frame(height: 50)
            .clipShape(.rect(cornerRadius: 8))
            
            Chart(colorScaleLevels) { level in
                Plot {
                    BarMark(
                        x: .value("Zone", level.zone),
                        yStart: .value("Surface Brightness Min", level.mparc.0),
                        yEnd: .value("Surface Brightness Max", level.mparc.1),
                        width: 10
                    )
                    .clipShape(Capsule())
                    .foregroundStyle(level.zoneColor)
                    .shadow(color: .black.opacity(0.15), radius: 1)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisTick()
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXAxisLabel("Zone")
            .chartYAxisLabel("Surface Brightness (mag/arcsec²)")
            .chartYScale(domain: 17...22)
            .padding()
            .background(Color(.tertiarySystemBackground))
            .frame(height: 300)
            .clipShape(.rect(cornerRadius: 8))
            
            HStack(spacing: .zero) {
                Text("For more info, visit the ")
                    .foregroundStyle(.secondary)
                Link("Light Pollution Atlas", destination: URL(string: "https://djlorenz.github.io/astronomy/lp/colors.html")!)
                    .foregroundStyle(.blue)
                    .underline()
            }
            .font(.footnote)
        }
    }
}

struct HomeViewLayerIndicatorDetail: View {
    
    /// Mutable view state tracking selectedIndicator.
    @State private var selectedIndicator: MapConfiguration.MapIndicator = .angularRadius
    
    /// Value used for destination.
    let destination: HomeViewLayerDestination
    
    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Picker(destination.title, selection: $selectedIndicator) {
                ForEach(MapConfiguration.MapIndicator.allCases, id: \.self) { indicator in
                    Text(indicator.name)
                }
            }
            .pickerStyle(.segmented)
            
            ScrollView {
                Group {
                    switch selectedIndicator {
                    case .angularRadius:
                        angularRadiusDetail
                    case .proximityRoute:
                        proximityRouteDetail
                    }
                }
                .padding(.bottom, 24)
                .padding(.top, 32)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
    }
    
    /// View content rendered for angularRadiusDetail.
    @ViewBuilder
    private var angularRadiusDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Satellite Visibility Radius")
                .font(.title2.weight(.semibold))
            
            Text("Displays the area of Earth's surface where the selected satellite is currently above the horizon. Any location inside the circle can potentially observe the satellite, while locations outside it cannot due to Earth's curvature.")
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }
    
    /// View content rendered for proximityRouteDetail.
    @ViewBuilder
    private var proximityRouteDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Distance to Satellite")
                .font(.title2.weight(.semibold))
            
            Text("Draws the shortest path from your selected location to the satellite's current position on Earth. The route updates continuously as the satellite moves, making it easy to visualize its relative location and ground distance.")
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }
}

#Preview {
    @Previewable @State var config: MapConfiguration = .init()
    
    VStack { }
        .sheet(isPresented: .constant(true)) {
            HomeViewLayerMenu(config: $config)
        }
}
