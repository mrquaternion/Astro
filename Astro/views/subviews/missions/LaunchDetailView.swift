//
//  LaunchDetailView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-21.
//

import SwiftUI
import VariableBlur
import MapboxMaps
import UserNotifications

class NotificationCenter {
    static let requestIdFormat = "launch:%@"
    
    static func requestAuthorization() async throws {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }
    
    static func sendLaunchLocalNotificationRequest(launchId: String, rocketName: String, at launchTime: Date) async throws {
        let reminderDate = launchTime.addingTimeInterval(-(10 * 60))
        guard reminderDate > .now else { return }
        
        let center = UNUserNotificationCenter.current()
        let timeInterval = reminderDate.timeIntervalSinceNow

        let content = UNMutableNotificationContent()
        content.title = String(format: "launch_notification_title_template".localizedFirstCapitalized, rocketName)
        content.body = String(format: "launch_notification_body_template".localizedFirstCapitalized, rocketName)
        content.userInfo = ["url": "astro://launch_id=\(launchId)"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: String(format: requestIdFormat, launchId),
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
    static func removeLaunchLocalNotificationRequest(launchId: String) {
        let center = UNUserNotificationCenter.current()
        let requestId = String(format: requestIdFormat, launchId)
        
        center.removePendingNotificationRequests(withIdentifiers: [requestId])
        print("Removed local app notification.")
    }
}

struct LaunchDetailView: View {
    /// Launch displayed by the detail screen.
    var launch: LaunchFeatureCollection.Feature.Properties
    
    var body: some View {
        GeometryReader { proxy in
            let safeArea = proxy.safeAreaInsets
            let size = proxy.size
            
            LaunchDetailContentView(
                safeArea: safeArea,
                size: size,
                launch: launch
            )
            .ignoresSafeArea(.container, edges: .top)
        }
    }
}

fileprivate struct LaunchDetailContentView: View {
    /// Dismiss action for the current navigation destination.
    @Environment(\.dismiss) var dismiss
    
    /// Active interface color scheme.
    @Environment(\.colorScheme) var colorScheme
    
    /// Subscription store that loads products and performs purchases.
    @Environment(SubscriptionManager.self) private var subscriptionManager
    
    /// Whether the current device is an iPad.
    @Environment(\.isPad) var isPad
    
    /// Whether launch notifications are enabled.
    @State private var turnNotificationsOn: Bool
    
    /// Controls presentation of the paywall for notification..
    @State private var showPaywall = false
    
    /// Safe-area insets used to size the custom header.
    var safeArea: SwiftUI.EdgeInsets
    /// Available detail-view size.
    var size: CGSize
    /// Launch displayed by this content view.
    var launch: LaunchFeatureCollection.Feature.Properties

    /// Height of the parallax image header.
    private var headerHeight: CGFloat { size.height * 0.45 + safeArea.top }
    /// Height reserved for the custom navigation controls.
    private var navigationHeaderHeight: CGFloat { safeArea.top + (isPad ? 64 : 56) }
    /// Height reserved for the split-flap countdown.
    private var splitFlapHeight: CGFloat { isPad ? 164 : 110 }
    /// Height of the sticky blur background.
    private var stickyBlurHeight: CGFloat { safeArea.top + splitFlapHeight }
    
    init(safeArea: SwiftUI.EdgeInsets, size: CGSize, launch: LaunchFeatureCollection.Feature.Properties) {
        self.safeArea = safeArea
        self.size = size
        self.launch = launch
        _turnNotificationsOn = State(wrappedValue: UserDefaults.standard.bool(forKey: launch.id))
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .top) {
                VStack(spacing: .zero) {
                    headerImageContainer()
                    Color.clear
                        .frame(height: splitFlapHeight)
                    LaunchDetailScrollableContent(launch: launch)
                }

                headerBlurBackground()
                    .zIndex(1)

                VStack(spacing: .zero) {
                    Color.clear
                        .frame(height: headerHeight)
                    splitFlapContainer()
                }
                .zIndex(2)

                headerView()
                    .zIndex(3)
            }
        }
        .coordinateSpace(name: "scroll")
        .onChange(of: turnNotificationsOn) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: launch.id)
            
            if newValue {
                Task {
                    do {
                        try await NotificationCenter.sendLaunchLocalNotificationRequest(
                            launchId: launch.id,
                            rocketName: launch.shortName,
                            at: launch.net
                        )
                        print("Registered local app notification.")
                    } catch {
                        print("Failed to register local app notification.")
                    }
                }
            } else {
                NotificationCenter.removeLaunchLocalNotificationRequest(launchId: launch.id)
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            Paywall()
                .environment(subscriptionManager)
        }
    }
    
    @ViewBuilder
    private func headerImageContainer() -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            let minY = proxy.frame(in: .named("scroll")).minY
            let progress = minY / (headerHeight * (minY > 0 ? 0.5 : 0.8))
            
            LaunchParallaxHeaderView(
                colorScheme: colorScheme,
                launch: launch,
                progress: progress,
                size: size,
                minY: minY
            )
        }
        .frame(height: headerHeight)
    }
    
    @ViewBuilder
    private func splitFlapContainer() -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("scroll")).minY - safeArea.top
            let isSticky = minY < 50
            
            SplitFlapDisplay(net: launch.net, withTimeComponentDescription: (isSticky ? false : true))
                .scaleEffect(isPad ? (isSticky ? 1.0 : 1.2) : (isSticky ? 0.7 : 0.8))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: minY < 50 ? -(minY - 30) : 0) // 30 - 24 = 6, extra offset caused by GeometryReader
                .animation(.easeInOut, value: isSticky)
        }
        .frame(height: splitFlapHeight)
    }

    @ViewBuilder
    private func headerBlurBackground() -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("scroll")).minY
            let progress = minY / (headerHeight * (minY > 0 ? 0.5 : 0.8))

            VariableBlurView(maxBlurRadius: 10, direction: .blurredTopClearBottom)
                .frame(height: stickyBlurHeight, alignment: .top)
                .opacity(-progress > 1 ? 1 : 0)
                .offset(y: -minY)
                .allowsHitTesting(false)
        }
        .frame(height: stickyBlurHeight)
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("scroll")).minY
            let titleProgress = minY / headerHeight
            
            HStack(spacing: .zero) {
                GlassIconButton(
                    systemName: "chevron.left",
                    size: isPad ? 24 : 18,
                    padding: isPad ? 16 : 12
                ) {
                    dismiss()
                }
                
                Spacer()
                
                GlassIconButton(
                    systemName: turnNotificationsOn ? "bell.badge.fill" : "bell",
                    size: isPad ? 24 : 18,
                    padding: isPad ? 16 : 12
                ) {
                    guard SubscriptionHelper.isEligibleTo(.offlineDownload, with: subscriptionManager) else {
                        showPaywall = true
                        return
                    }
                    
                    turnNotificationsOn.toggle()
                }
            }
            .overlay(content: {
                Text(launch.shortName)
                    .font(isPad ? .title2 : .title3)
                    .fontWeight(.semibold)
                    .offset(y: -titleProgress > 0.75 ? 0 : 45)
                    .clipped()
                    .animation(.easeOut(duration: 0.25), value: -titleProgress > 0.75)
            })
            .padding(.top, safeArea.top + 10)
            .padding(.horizontal, isPad ? 32 : 16)
            .offset(y: -minY)
        }
        .frame(height: 35)
    }
}

fileprivate struct LaunchParallaxHeaderView: View {
    /// Whether the current device is an iPad.
    @Environment(\.isPad) var isPad

    /// Launch represented by the header image.
    var launch: LaunchFeatureCollection.Feature.Properties
    
    /// Color blended into the image gradient.
    var gradientColor: Color
    /// Current parallax-scroll progress.
    var progress: Double
    /// Offset applied to gradient interpolation.
    var gradientProgressOffset: Double
    /// Available header size.
    var size: CGSize
    /// Current vertical position in the scroll coordinate space.
    var minY: CGFloat
    
    init(
        colorScheme: ColorScheme,
        launch: LaunchFeatureCollection.Feature.Properties,
        progress: Double,
        gradientProgressOffset: Double = 0.2,
        size: CGSize,
        minY: CGFloat
    ) {
        self.gradientColor = colorScheme == .light ? Color.white: Color.black
        self.launch = launch
        self.progress = progress
        self.gradientProgressOffset = gradientProgressOffset
        self.size = size
        self.minY = minY
    }
    
    var body: some View {
        AsyncImage(url: launch.imageURL) { phase in
            switch phase {
            case .empty:
                EmptyView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height + (minY > 0 ? minY : 0))
                    .clipped()
                    .overlay(content: {
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(
                                    .linearGradient(colors: [
                                        gradientColor.opacity(0 - progress - gradientProgressOffset),
                                        gradientColor.opacity(0.1 - progress - gradientProgressOffset),
                                        gradientColor.opacity(0.3 - progress - gradientProgressOffset),
                                        gradientColor.opacity(0.5 - progress - gradientProgressOffset),
                                        gradientColor.opacity(0.8 - progress - gradientProgressOffset),
                                        gradientColor.opacity(1),
                                    ], startPoint: .top, endPoint: .bottom)
                                )
                            
                            VStack(alignment: .center, spacing: .zero) {
                                Text(launch.shortName)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                
                                Text(launch.serviceProvider.name.uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: isPad ? .infinity : 300)
                                    .padding(.top, 15)
                            }
                            .opacity(1 + (progress > 0 ? -progress : progress))
                            .padding(.bottom, 50)
                            .offset(y: minY < 0 ? minY : 0 )
                        }
                    })
                    .offset(y: -minY)
            case .failure:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }
    }
}

fileprivate struct LaunchDetailScrollableContent: View {
    
    /// Whether the current device is an iPad.
    @Environment(\.isPad) var isPad
    
    /// Whether the current interface is in landscape orientation.
    @Environment(\.isLandscape) var isLandscape
    
    /// Active interface color scheme.
    @Environment(\.colorScheme) var colorScheme
    
    /// Launch whose details and pad are displayed.
    var launch: LaunchFeatureCollection.Feature.Properties
    /// Current Mapbox viewport.
    @State private var viewport: Viewport
    
    /// Horizontal inset around the content.
    var padding: CGFloat { isPad ? 32 : 16 }
    /// Coordinate of the launch pad.
    var coordinate: CLLocationCoordinate2D
    /// Initial camera configuration for the map.
    var viewportDefaultState: Viewport
    /// Square map dimension.
    var mapSize: CGFloat { UIScreen.main.bounds.width - padding * 2 }
    
    init(launch: LaunchFeatureCollection.Feature.Properties) {
        self.launch = launch
        self.coordinate = .init(latitude: launch.pad.latitude, longitude: launch.pad.longitude)
        self.viewportDefaultState = .camera(
            center: self.coordinate,
            zoom: 14,
            pitch: 60
        )
        self.viewport = self.viewportDefaultState
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("launch_no_earlier_than".localizedFirstCapitalized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .italic()
                
                HStack(spacing: .zero) {
                    Text(launch.windowStart, format: .dateTime.hour().minute().timeZone())
                    Spacer()
                    Text(launch.windowStart, format: .dateTime.month(.abbreviated).day().year())
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("launch_status".localizedFirstCapitalized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .italic()

                HStack(alignment: .center, spacing: 10) {
                    Text(launch.status.name)
                        .font(.headline)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(launch.status.abbrev.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemBackground), in: Capsule())
                }
            }

            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("launch_window".localizedFirstCapitalized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .italic()
                
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("launch_start".localizedFirstCapitalized)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(launch.windowStart, format: .dateTime.month(.abbreviated).day().year())
                        Text(launch.windowStart, format: .dateTime.hour().minute().timeZone())
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    GridRow {
                        Text("launch_end".localizedFirstCapitalized)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(launch.windowEnd, format: .dateTime.month(.abbreviated).day().year())
                        Text(launch.windowEnd, format: .dateTime.hour().minute().timeZone())
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            
            Divider()
           
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("launch_location".localizedFirstCapitalized)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .italic()
                        
                        HStack(alignment: .top, spacing: .zero) {
                            HStack(alignment: .center, spacing: 6) {
                                Text(launch.pad.country.capitalized)
                                    .font(.headline)
                                Text("(\(launch.pad.alphaCode))")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Image(launch.pad.alphaCode)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 36)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("launch_at".localized)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .italic()
                        
                        VStack(alignment:.leading, spacing: 8) {
                            Text(launch.pad.location)
                                .fontWeight(.medium)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "guidepoint.vertical")
                                    Text("\(launch.pad.latitude.description)°")
                                }
                                HStack {
                                    Image(systemName: "guidepoint.horizontal")
                                    Text("\(launch.pad.longitude.description)°")
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                }
                
                Map(viewport: $viewport) {
                    Atmosphere()
                        .starIntensity(2)
                        .horizonBlend(0.01)
                        .color(StyleColor(UIColor(white: 0.55, alpha: 1)))
                        .highColor(StyleColor(UIColor(white: 0.35, alpha: 1)))
                        .spaceColor(StyleColor(UIColor(white: 0.05, alpha: 1)))
                    
                    MapViewAnnotation(coordinate: coordinate) {
                        Image("rocket.square.fill")
                            .font(.title)
                            .foregroundStyle(
                                colorScheme == .light ? .white : .black,
                                colorScheme == .light ? .black : .white
                            )
                    }
                    
                    Terrain(sourceId: "terrain-dem")
                        .exaggeration(1.5)
                    
                    RasterDemSource(id: "terrain-dem")
                        .url("mapbox://mapbox.mapbox-terrain-dem-v1")
                }
                .mapStyle(.standard(theme: .monochrome, lightPreset: colorScheme == .light ? .day : .night))
                .ornamentOptions(OrnamentOptions(
                    scaleBar: .init(visibility: .hidden),
                    compass: .init(visibility: .hidden),
                    logo: .init(position: .topRight),
                    attributionButton: .init(tintColor: colorScheme == .light ? .black : .white)
                ))
                .frame(width: mapSize, height: isPad ? 500 : mapSize)
                .overlay(alignment: .topLeading) {
                    HStack {
                        Image(systemName: "plus.magnifyingglass")
                        Text("launch_locate".localizedFirstCapitalized)
                    }
                    .font(isPad ? .title2.weight(.medium) : .subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.secondary, in: .capsule)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .padding()
                    .onTapGesture {
                        withViewportAnimation(.easeInOut(duration: 1.0)) {
                            self.viewport = self.viewportDefaultState
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 4))
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.black, lineWidth: colorScheme == .light ? 2 : 0)
                }
                .tag(isLandscape && isPad)
            }
            
            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("launch_agency".localizedFirstCapitalized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .italic()
                Text(launch.serviceProvider.name.capitalized)
                    .font(.headline)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if launch.serviceProvider.name.lowercased() != launch.rocket.manufacturer.lowercased() {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("launch_rocket_manufacturer".localizedFirstCapitalized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .italic()
                    Text(launch.rocket.manufacturer.capitalized)
                        .font(.headline)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            if let mission = launch.mission {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("launch_mission".localizedFirstCapitalized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .italic()
                    Text(mission.name)
                        .font(.headline)
                    Text(mission.description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !launch.videoFeedURLs.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("launch_video_feeds".localizedFirstCapitalized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .italic()

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(launch.videoFeedURLs.enumerated()), id: \.offset) { index, url in
                            Link(destination: url) {
                                HStack(alignment: .center, spacing: 10) {
                                    Image(systemName: "play.rectangle.fill")
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(videoFeedTitle(for: url, index: index))
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)

                                        Text(url.absoluteString)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }

                                    Spacer(minLength: 8)

                                    Image(systemName: "arrow.up.forward.square")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(padding)
    }

    private func videoFeedTitle(for url: URL, index: Int) -> String {
        guard let host = url.host?.replacingOccurrences(of: "www.", with: "") else {
            return "launch_video_feed_format".localizedFormat(index + 1)
        }

        return "launch_host_feed_format".localizedFormat(host, index + 1)
    }
}

#Preview {
    LaunchDetailView(launch: .init(
        id: "1b23eb18-e06e-4058-9b42-e95ca0980511",
        name: "Spectrum | Onward and Upward",
        shortName: "Spectrum",
        status: .init(
            statusId: "2",
            name: "To Be Determined",
            abbrev: "TBD"
        ),
        serviceProvider: .init(
            serviceProviderId: "1046",
            name: "Isar Aerospace"
        ),
        mission: .init(
            missionId: "7309",
            name: "Onward and Upward",
            type: "Test Flight",
            description: """
Second test flight of the Isar Spectrum launch vehicle. This launch will carry 5 cubesats and 1 non-separable experiment as part of European Space Agency (ESA)'s “Boost!” program:

* CyBEEsat (TU Berlin)
* TriSat-S (University of Maribor)
* Platform 6 (EnduroSat)
* FramSat-1 (NTNU)
* SpaceTeamSat1 (TU Wien Space Team)
* Let It Go (Dcubed, non-separable experiment)
""",
            orbitId: "17",
            orbitName: "Sun-Synchronous Orbit",
            orbitAbbrev: "SSO"
        ),
        rocket: .init(
            rocketId: "491",
            fullName: "Spectrum",
            manufacturer: "Isar Aerospace"
        ),
        pad: .init(
            padId: "51",
            name: "Orbital Launch Pad",
            latitude: 69.1084,
            longitude: 15.5895,
            location: "Andøya Spaceport",
            country: "Norway",
            alphaCode: "NOR"
        ),
        net: DateFormatterHelpers.date(from: "2026-08-06 00:00:00+00"),
        windowStart: DateFormatterHelpers.date(from: "2026-08-06 00:00:00+00"),
        windowEnd: DateFormatterHelpers.date(from: "2026-08-06 00:00:00+00"),
        imageURL: URL(string: "https://thespacedevs-prod.nyc3.digitaloceanspaces.com/media/images/spectrum_on_the_image_20250321072643.jpeg"),
        thumbnailURL: URL(string: "https://thespacedevs-prod.nyc3.digitaloceanspaces.com/media/images/spectrum_on_the_image_thumbnail_20250321072643.jpeg"),
        videoFeedURLs: [
            URL(string: "https://www.youtube.com/watch?v=Ss1DUqLjecc")!,
            URL(string: "https://www.youtube.com/watch?v=uUc2d_NPBN0")!
        ],
        lastUpdated: DateFormatterHelpers.date(from: "2026-07-10 13:43:25+00")
    ))
}
