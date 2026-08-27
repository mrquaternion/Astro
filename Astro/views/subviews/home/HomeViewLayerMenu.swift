import SwiftUI
import Charts
import SwiftUIIntrospect

enum HomeViewLayerDestination: Hashable {
    case basemaps
    case overlays
    case indicators
    
    /// Value used for title.
    var title: String {
        switch self {
        case .basemaps: "map_basemaps".localizedFirstCapitalized
        case .overlays: "map_overlays".localizedFirstCapitalized
        case .indicators: "map_indicators".localizedFirstCapitalized
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
                layerSection("map_basemaps".localizedFirstCapitalized) {
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
                
                layerSection("map_overlays".localizedFirstCapitalized, destination: .overlays) {
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
                
                layerSection("map_indicators".localizedFirstCapitalized, destination: .indicators) {
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
    
    /// Mutable view state tracking selectedOverlay.
    @State private var selectedOverlay: MapConfiguration.MapOverlay = .clouds
    
    /// Mutable view state tracking selectedIndicator.
    @State private var selectedIndicator: MapConfiguration.MapIndicator = .angularRadius
    
    var body: some View {
        Group {
            switch destination {
            case .basemaps:
                EmptyView()
            case .overlays:
                HomeViewLayerOverlayDetail(selectedOverlay: $selectedOverlay, destination: destination)
            case .indicators:
                HomeViewLayerIndicatorDetail(selectedIndicator: $selectedIndicator, destination: destination)
            }
        }
    }
}

private struct HomeViewLayerOverlayDetail: View {
    
    /// Mutable view state tracking selectedOverlay.
    @Binding var selectedOverlay: MapConfiguration.MapOverlay
    
    /// Edge interaction for the scroll view and the picker bar.
    @State private var edgeInteraction = UIScrollEdgeElementContainerInteraction()
    
    /// Value used for destination.
    let destination: HomeViewLayerDestination
    
    struct ColorScaleLevel: Identifiable {
        let id: String
        let zone: String
        let zoneColor: Color
        let lpi: (Double, Double)
        let mparc: (Double, Double)
    }
    
    /// Value used for colorScaleLevels.
    let colorScaleLevels: [ColorScaleLevel] = [
        ColorScaleLevel(id: "0", zone: "0",  zoneColor: .init(red: 0 / 255, green: 0 / 255, blue: 0 / 255),
                        lpi: (0.00, 0.01),    mparc: (21.99, 22.00)),
        ColorScaleLevel(id: "1a", zone: "1a", zoneColor: .init(red: 34 / 255, green: 34 / 255, blue: 34 / 255),
                        lpi: (0.01, 0.06),    mparc: (21.93, 21.99)),
        ColorScaleLevel(id: "1b", zone: "1b", zoneColor: .init(red: 66 / 255, green: 66 / 255, blue: 66 / 255),
                        lpi: (0.06, 0.11),    mparc: (21.89, 21.93)),
        ColorScaleLevel(id: "2a", zone: "2a", zoneColor: .init(red: 21 / 255, green: 47 / 255, blue: 114 / 255),
                        lpi: (0.11, 0.19),    mparc: (21.81, 21.89)),
        ColorScaleLevel(id: "2b", zone: "2b", zoneColor: .init(red: 33 / 255, green: 84 / 255, blue: 216 / 255),
                        lpi: (0.19, 0.33),    mparc: (21.69, 21.81)),
        ColorScaleLevel(id: "3a", zone: "3a", zoneColor: .init(red: 16 / 255, green: 87 / 255, blue: 19 / 255),
                        lpi: (0.33, 0.58),    mparc: (21.51, 21.69)),
        ColorScaleLevel(id: "3b", zone: "3b", zoneColor: .init(red: 30 / 255, green: 161 / 255, blue: 41 / 255),
                        lpi: (0.58, 1.00),    mparc: (21.25, 21.51)),
        ColorScaleLevel(id: "4a", zone: "4a", zoneColor: .init(red: 110 / 255, green: 100 / 255, blue: 31 / 255),
                        lpi: (1.00, 1.73),    mparc: (20.91, 21.25)),
        ColorScaleLevel(id: "4b", zone: "4b", zoneColor: .init(red: 184 / 255, green: 165 / 255, blue: 38 / 255),
                        lpi: (1.73, 3.00),    mparc: (20.49, 20.91)),
        ColorScaleLevel(id: "5a", zone: "5a", zoneColor: .init(red: 191 / 255, green: 100 / 255, blue: 29 / 255),
                        lpi: (3.00, 5.20),    mparc: (20.02, 20.49)),
        ColorScaleLevel(id: "5b", zone: "5b", zoneColor: .init(red: 253 / 255, green: 150 / 255, blue: 80 / 255),
                        lpi: (5.20, 9.00),    mparc: (19.50, 20.02)),
        ColorScaleLevel(id: "6a", zone: "6a", zoneColor: .init(red: 250 / 255, green: 90 / 255, blue: 73 / 255),
                        lpi: (9.00, 15.59),   mparc: (18.95, 19.50)),
        ColorScaleLevel(id: "6b", zone: "6b", zoneColor: .init(red: 250 / 255, green: 153 / 255, blue: 138 / 255),
                        lpi: (15.59, 27.00),  mparc: (18.38, 18.95)),
        ColorScaleLevel(id: "7a", zone: "7a", zoneColor: .init(red: 160 / 255, green: 160 / 255, blue: 160 / 255),
                        lpi: (27.00, 46.77),  mparc: (17.80, 18.38)),
        ColorScaleLevel(id: "7b", zone: "7b", zoneColor: .init(red: 242 / 255, green: 242 / 255, blue: 242 / 255),
                        lpi: (46.77, .infinity), mparc: (17, 17.80))
    ]
    
    var body: some View {
        ScrollView {
            Group {
                switch selectedOverlay {
                case .clouds:
                    cloudsDetail
                case .lightPollution:
                    lightPollutionDetail
                }
            }
            .padding(.vertical, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .introspect(.scrollView, on: .iOS(.v26)) { scrollView in
            edgeInteraction.scrollView = scrollView
        }
        .safeAreaBar(edge: .top) {
            Picker(destination.title, selection: $selectedOverlay) {
                ForEach(MapConfiguration.MapOverlay.allCases, id: \.self) { overlay in
                    Text(overlay.name)
                }
            }
            .pickerStyle(.segmented)
            .introspect(.picker(style: .segmented), on: .iOS(.v26)) { control in
                edgeInteraction.edge = .top
                
                if !control.interactions.contains(where: { $0 === edgeInteraction }) {
                    control.addInteraction(edgeInteraction)
                }
            }
        }
        .mask(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
        .ignoresSafeArea()
    }
    
    /// View content rendered for cloudsDetail.
    @ViewBuilder
    private var cloudsDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("map_cloud_map_title".localizedFirstCapitalized)
                .font(.title2.weight(.semibold))
            
            Text("map_cloud_map_description".localizedFirstCapitalized)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
            
            HStack(spacing: .zero) {
                Text("map_attribution".localizedFirstCapitalized + ": ")
                    .foregroundStyle(.secondary)
                Link(
                    "map_live_cloud_maps".localizedFirstCapitalized,
                    destination: URL(string: "https://github.com/matteason/live-cloud-maps")!
                )
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
            Text("map_light_pollution".localizedFirstCapitalized)
                .font(.title2.weight(.semibold))
            
            Text("map_light_pollution_description".localizedFirstCapitalized)
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
                        x: .value("map_zone".localizedFirstCapitalized, level.zone),
                        yStart: .value("map_surface_brightness_min".localizedFirstCapitalized, level.mparc.0),
                        yEnd: .value("map_surface_brightness_max".localizedFirstCapitalized, level.mparc.1),
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
            .chartXAxisLabel("map_zone".localizedFirstCapitalized)
            .chartYAxisLabel("map_surface_brightness_unit".localizedFirstCapitalized)
            .chartYScale(domain: 17...22)
            .padding()
            .background(Color(.tertiarySystemBackground))
            .frame(height: 300)
            .clipShape(.rect(cornerRadius: 8))
            
            HStack(spacing: .zero) {
                Text("map_more_info_prefix".localizedFirstCapitalized + " ")
                    .foregroundStyle(.secondary)
                Link(
                    "map_light_pollution_atlas".localizedFirstCapitalized,
                    destination: URL(string: "https://djlorenz.github.io/astronomy/lp/colors.html")!
                )
                .foregroundStyle(.blue)
                .underline()
            }
            .font(.footnote)
        }
    }
}

struct HomeViewLayerIndicatorDetail: View {
    
    /// Mutable view state tracking selectedIndicator.
    @Binding var selectedIndicator: MapConfiguration.MapIndicator
    
    /// Edge interaction for the scroll view and the picker bar.
    @State private var edgeInteraction = UIScrollEdgeElementContainerInteraction()
    
    /// Value used for destination.
    let destination: HomeViewLayerDestination
    
    var body: some View {
        ScrollView {
            Group {
                switch selectedIndicator {
                case .angularRadius:
                    angularRadiusDetail
                case .proximityRoute:
                    proximityRouteDetail
                }
            }
            .padding(.vertical, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .safeAreaBar(edge: .top) {
            Picker(destination.title, selection: $selectedIndicator) {
                ForEach(MapConfiguration.MapIndicator.allCases, id: \.self) { indicator in
                    Text(indicator.name)
                }
            }
            .pickerStyle(.segmented)
            .introspect(.picker(style: .segmented), on: .iOS(.v26)) { control in
                edgeInteraction.edge = .top
                
                if !control.interactions.contains(where: { $0 === edgeInteraction }) {
                    control.addInteraction(edgeInteraction)
                }
            }
        }
        .mask(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
        .ignoresSafeArea()
    }
    
    /// View content rendered for angularRadiusDetail.
    @ViewBuilder
    private var angularRadiusDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("map_satellite_visibility_title".localizedFirstCapitalized)
                .font(.title2.weight(.semibold))
            
            Text("map_satellite_visibility_description".localizedFirstCapitalized)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }
    
    /// View content rendered for proximityRouteDetail.
    @ViewBuilder
    private var proximityRouteDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("map_distance_to_satellite".localizedFirstCapitalized)
                .font(.title2.weight(.semibold))
            
            Text("map_distance_to_satellite_description".localizedFirstCapitalized)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }
}

#Preview {
    @Previewable @State var showSheet = false
    @Previewable @State var config: MapConfiguration = .init()
    
    VStack {
        Button("Click") {
            showSheet.toggle()
        }
        .buttonStyle(.borderedProminent)
    }
    .sheet(isPresented: $showSheet) {
        HomeViewLayerMenu(config: $config)
            .presentationDetents([.medium])
    }
}
