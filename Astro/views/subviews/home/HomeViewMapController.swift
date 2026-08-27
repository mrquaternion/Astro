//
//  HomeViewMapController.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-05.
//

import SwiftUI
import Combine
@_spi(Experimental) import MapboxMaps

@objc(ViewController)
class HomeViewMapController: UIViewController {
    
    /// Mapbox view rendered by this controller.
    private var mapView: MapView!
    
    /// Subscriptions retained for Mapbox style events.
    private var cancellables = Set<AnyCancellable>()
    
    /// Whether the Mapbox style has finished loading.
    private var isStyleLoaded = false
    
    /// Latest model update waiting for the map style to load.
    private var pendingUpdate: (lon: Double, lat: Double, alt: Double, bearing: Double)?
    
    /// Identifier of the model currently registered with Mapbox.
    private var registeredModelId: String?
    
    /// URI of the model currently registered with Mapbox.
    private var registeredModelUri: String?
    
    /// Identifier of the selected satellite model.
    var selectedModelId: String?
    
    /// On-device asset URI for the selected satellite model.
    var selectedModelUri: String?
    
    /// Upcoming route for the selected satellite.
    var route: Model3DRoute?
    
    /// Visible region (based on angulra radius) of the satellite.
    var visibleRegionCoordinates: [[Double]]?
    
    /// Route between the satellite and the user.
    var proximityRoute: ProximityRoute?
    
    /// Map layers configuration.
    var config: MapConfiguration?
    
    /// Light preset of the device.
    private var colorScheme: ColorScheme = .light
    
    /// Callback fired when the user moves the map manually.
    var onUserInteraction: (() -> Void)?
    
    init(config: MapConfiguration, colorScheme: ColorScheme) {
        self.config = config
        self.colorScheme = colorScheme
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Value used for displayedVisibleRegionCoordinates.
    private var displayedVisibleRegionCoordinates: [[Double]]? {
        guard config?.indicator == .angularRadius else { return nil }
        return visibleRegionCoordinates
    }
    
    /// Value used for displayedProximityRouteCoordinates.
    private var displayedProximityRouteCoordinates: [[Double]]? {
        displayedProximityRoute?.coordinates
    }
    
    /// Value used for displayedProximityRoute.
    private var displayedProximityRoute: ProximityRoute? {
        guard config?.indicator == .proximityRoute else { return nil }
        return proximityRoute
    }
    
    /// Value used for indicatorColor.
    private var indicatorColor: UIColor {
        config?.indicatorColor ?? .clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // init
        mapView = MapView(frame: view.bounds, mapInitOptions: .init(
            mapStyle: config?.basemap.style(for: colorScheme)
        ))
        mapView.gestures.delegate = self
        
        // load the style
        mapView.mapboxMap.onStyleLoaded.observe { [weak self] _ in
            guard let self else { return }
            self.handleStyleLoaded()
        }
        .store(in: &cancellables)
        
        // set up mabpox required ornaments
        let hiddenOrnamentMargins = CGPoint(x: -100.0, y: -100.0)
        mapView.ornaments.options = .init(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            compass: CompassViewOptions(visibility: .hidden),
            logo: LogoViewOptions(
                position: .bottomTrailing,
                margins: ScreenshotMode.isEnabled
                    ? hiddenOrnamentMargins
                    : CGPoint(x: Constants.logoTrailingMargin, y: Constants.defaultOrnamentBottomMargin)
            ),
            attributionButton: AttributionButtonOptions(
                position: .bottomTrailing,
                margins: ScreenshotMode.isEnabled
                    ? hiddenOrnamentMargins
                    : CGPoint(x: Constants.attributionTrailingMargin, y: Constants.defaultOrnamentBottomMargin),
                tintColor: UIColor(white: 0.6, alpha: 1)
            )
        )
        
        // defining the puck
        var puckConfiguration = Puck2DConfiguration.makeDefault(showBearing: true)
        puckConfiguration.pulsing = .default
        puckConfiguration.showsAccuracyRing = true
        puckConfiguration.layerPosition = .above(Constants.visibleRegionLayerId)
        mapView.location.options.puckType = .puck2D(puckConfiguration)
        mapView.location.options.puckBearing = .heading
        mapView.location.options.puckBearingEnabled = true
        
        // defining the visible satellite
        var modelFeature = Feature(geometry: Constants.defaultCoordinates)
        modelFeature.properties = [Constants.modelIdKey: .string(selectedModelId ?? "")]
        
        let initialVisibleRegionCoordinates = displayedVisibleRegionCoordinates
        let initialIndicatorColor = indicatorColor
        
        // defining the route between the satellite and user
        let initialProximityRouteCoordinates = displayedProximityRouteCoordinates
        
        mapView.mapboxMap.setMapStyleContent {
            // satellite model layer
            GeoJSONSource(id: Constants.modelsSourceId)
                .data(.featureCollection(FeatureCollection(features: [modelFeature])))
            ModelLayer(id: Constants.modelLayerId, source: Constants.modelsSourceId)
                .modelId(Exp(.get) { Constants.modelIdKey })
                .modelType(.common3d)
                .modelScale(x: 60_000, y: 60_000, z: 60_000)
                .modelTranslation(x: 0, y: 0, z: 1_000_000)
                .modelRotation(x: 0, y: 0, z: 0)
                .modelOpacity(1)
                .modelEmissiveStrength(1)
            
            // satellite route line layer
            GeoJSONSource(id: Constants.routeSourceId)
                .data(Self.routeGeoJSON(route?.coordinates))
            LineLayer(id: Constants.routeLayerId, source: Constants.routeSourceId)
                .lineColor(.init(UIColor(ciColor: .white)))
                .lineWidth(5.0)
                .lineEmissiveStrength(0.8)
                .lineJoin(.round)
            // .lineZOffset(_:) upcoming for globe projection
            
            // satellite visible region line layer
            GeoJSONSource(id: Constants.visibleRegionSourceId)
                .data(Self.routeGeoJSON(initialVisibleRegionCoordinates))
            LineLayer(id: Constants.visibleRegionLayerId, source: Constants.visibleRegionSourceId)
                .lineColor(initialIndicatorColor)
                .lineWidth(2.0)
                .lineEmissiveStrength(0.8)
                .lineJoin(.round)
                .lineDashArray([4, 3])
            // .lineZOffset(_:) upcoming for globe projection
            
            // route between the satellite and the user
            GeoJSONSource(id: Constants.proximityRouteSourceId)
                .data(Self.routeGeoJSON(initialProximityRouteCoordinates))
            LineLayer(id: Constants.proximityRouteLayerId, source: Constants.proximityRouteSourceId)
                .lineColor(initialIndicatorColor)
                .lineWidth(4.0)
                .lineEmissiveStrength(0.8)
                .lineJoin(.round)
                .lineDashArray([4, 2])
            
            // the route label
            // MARK: - TICKET CODE
            GeoJSONSource(id: Constants.proximityRouteLabelSourceId)
                .data(Self.proximityLabelGeoJSON(displayedProximityRoute))
            SymbolLayer(id: Constants.proximityRouteLabelLayerId, source: Constants.proximityRouteLabelSourceId)
                .textField(Exp(.get) { Constants.proximityLabelKey })
                .textColor(initialIndicatorColor)
                .textSize(20)
                .textEmissiveStrength(0.8)
            //.textRotate(90 - (proximityRoute?.midpointBearing ?? 0))
                .textRotationAlignment(.viewport)
                .textAllowOverlap(true)
        }
        
        view.addSubview(mapView)
    }
    
    func updateModel(longitude: Double, latitude: Double, altitude: Double, bearing: Double) {
        pendingUpdate = (longitude, latitude, altitude, bearing)
        
        guard isStyleLoaded else { return }
        
        updateModel(lon: longitude, lat: latitude, alt: altitude, bearing: bearing)
        pendingUpdate = nil
    }
    
    private func updateModel(lon: Double, lat: Double, alt: Double, bearing: Double) {
        guard let selectedModelId else { return }
        
        var modelFeature = Feature(geometry: Point(CLLocationCoordinate2D(latitude: lat, longitude: lon)))
        modelFeature.properties = [Constants.modelIdKey: .string(selectedModelId)]
        
        mapView.mapboxMap.updateGeoJSONSource(
            withId: Constants.modelsSourceId,
            geoJSON: .featureCollection(FeatureCollection(features: [modelFeature]))
        )
        
        try? mapView.mapboxMap.setLayerProperty(
            for: Constants.modelLayerId,
            property: "model-translation",
            value: [0, 0, (alt + Constants.zOffset) * 1000]
        )
        
        try? mapView.mapboxMap.setLayerProperty(
            for: Constants.modelLayerId,
            property: "model-rotation",
            value: [0, 0, bearing]
        )
    }
    
    private static func routeGeoJSON(_ route: [[Double]]?) -> GeoJSONSourceData {
        guard let route, let item = route.first, item.count == 2 else {
            return .featureCollection(FeatureCollection(features: []))
        }
        
        var routeSegments: [[CLLocationCoordinate2D]] = []
        var currentSegment: [CLLocationCoordinate2D] = []
        
        for coordinate in route {
            let nextCoordinate = CLLocationCoordinate2D(
                latitude: coordinate[1],
                longitude: coordinate[0]
            )
            
            if
                let previousCoordinate = currentSegment.last,
                abs(nextCoordinate.longitude - previousCoordinate.longitude) > 180
            {
                let crossesEastward = previousCoordinate.longitude > 0
                let previousBoundary = crossesEastward ? 180.0 : -180.0
                let nextBoundary = -previousBoundary
                let unwrappedNextLongitude = nextCoordinate.longitude + (crossesEastward ? 360.0 : -360.0)
                let progress = (previousBoundary - previousCoordinate.longitude) / (unwrappedNextLongitude - previousCoordinate.longitude)
                let crossingLatitude = previousCoordinate.latitude + progress * (nextCoordinate.latitude - previousCoordinate.latitude)
                
                currentSegment.append(
                    CLLocationCoordinate2D(latitude: crossingLatitude, longitude: previousBoundary)
                )
                
                if currentSegment.count >= 2 {
                    routeSegments.append(currentSegment)
                }
                
                currentSegment = [
                    CLLocationCoordinate2D(latitude: crossingLatitude, longitude: nextBoundary)
                ]
            }
            
            currentSegment.append(nextCoordinate)
        }
        
        if currentSegment.count >= 2 {
            routeSegments.append(currentSegment)
        }
        
        return .feature(Feature(geometry: .multiLineString(MultiLineString(routeSegments))))
    }
    
    private static func proximityLabelGeoJSON(_ route: ProximityRoute?) -> GeoJSONSourceData {
        guard
            let route,
            let midpoint = route.midpoint,
            midpoint.count == 2,
            let label = route.label
        else {
            return .featureCollection(FeatureCollection(features: []))
        }
        
        var feature = Feature(geometry: Point(CLLocationCoordinate2D(
            latitude: midpoint[1],
            longitude: midpoint[0]
        )))
        feature.properties = [
            Constants.proximityLabelKey: .string(label)
        ]
        return .feature(feature)
    }
    
    private func makeCloudLayer() -> RasterLayer {
        var rasterLayer = RasterLayer(id: Constants.cloudLayerId, source: Constants.cloudSourceId)
        rasterLayer.rasterOpacity = .constant(Constants.cloudOpacity)
        rasterLayer.rasterEmissiveStrength = .constant(Constants.cloudEmissiveStrength)
        return rasterLayer
    }
    
    private func makeLightPollutionLayer() -> RasterLayer {
        var rasterLayer = RasterLayer(id: Constants.lightPollutionLayerId, source: Constants.lightPollutionSourceId)
        rasterLayer.rasterOpacity = .constant(Constants.lightPollutionOpacity)
        rasterLayer.rasterEmissiveStrength = .constant(0.7)
        return rasterLayer
    }
    
}

extension HomeViewMapController {
    
    private func handleStyleLoaded() {
        applyTerrain()
        applyAtmosphere()
        
        isStyleLoaded = true
        
        applySelectedModel()
        applyRoute()
        applyMapIndicators()
        applyMapOverlays()
        
        if let pending = pendingUpdate {
            updateModel(lon: pending.lon, lat: pending.lat, alt: pending.alt, bearing: pending.bearing)
            pendingUpdate = nil
        }
    }
    
    private func applyTerrain() {
        var terrain = Terrain(sourceId: "terrain-dem")
        terrain.exaggeration = .constant(1.5)
        
        if !mapView.mapboxMap.sourceExists(withId: "terrain-dem") {
            var source = RasterDemSource(id: "terrain-dem")
            source.url = "mapbox://mapbox.mapbox-terrain-dem-v1"
            
            try? mapView.mapboxMap.addSource(source)
        }
        
        try? mapView.mapboxMap.setTerrain(terrain)
    }
    
    private func applyAtmosphere() {
        var atmosphere = Atmosphere()
            .starIntensity(3)
            .horizonBlend(0.02)
        
        if config?.basemap == .night {
            atmosphere = atmosphere
                .color(StyleColor(UIColor(white: 0.55, alpha: 1)))
                .highColor(StyleColor(UIColor(white: 0.35, alpha: 1)))
                .spaceColor(StyleColor(UIColor(white: 0.05, alpha: 1)))
        }
        
        try? mapView.mapboxMap.setAtmosphere(atmosphere)
    }
    
    private func applySelectedModel() {
        guard let selectedModelId, let selectedModelUri else { return }
        
        do {
            if registeredModelId != selectedModelId || registeredModelUri != selectedModelUri {
                if let registeredModelId, mapView.mapboxMap.hasStyleModel(modelId: registeredModelId) {
                    try mapView.mapboxMap.removeStyleModel(modelId: registeredModelId)
                }
                
                registeredModelId = selectedModelId
                registeredModelUri = selectedModelUri
            }
            
            // could be moved to above but adds a layer of security since style can be reloaded
            // outside of the model's style
            if !mapView.mapboxMap.hasStyleModel(modelId: selectedModelId) {
                try mapView.mapboxMap.addStyleModel(
                    modelId: selectedModelId,
                    modelUri: selectedModelUri
                )
            }
            
            if let pendingUpdate {
                updateModel(
                    lon: pendingUpdate.lon,
                    lat: pendingUpdate.lat,
                    alt: pendingUpdate.alt,
                    bearing: pendingUpdate.bearing
                )
            }
        } catch {
            print("Unable to display selected model: \(error)")
        }
    }
    
    private func applyRoute() {
        mapView.mapboxMap.updateGeoJSONSource(
            withId: Constants.routeSourceId,
            data: Self.routeGeoJSON(route?.coordinates)
        )
    }
    
    private func applyMapIndicators() {
        applyVisibleRegion()
        applyProximityRoute()
    }
    
    private func applyVisibleRegion() {
        mapView.mapboxMap.updateGeoJSONSource(
            withId: Constants.visibleRegionSourceId,
            data: Self.routeGeoJSON(displayedVisibleRegionCoordinates)
        )
        
        try? mapView.mapboxMap.setLayerProperty(
            for: Constants.visibleRegionLayerId,
            property: "line-color",
            value: StyleColor(indicatorColor).rawValue
        )
    }
    
    private func applyProximityRoute() {
        mapView.mapboxMap.updateGeoJSONSource(
            withId: Constants.proximityRouteSourceId,
            data: Self.routeGeoJSON(displayedProximityRouteCoordinates)
        )
        
        mapView.mapboxMap.updateGeoJSONSource(
            withId: Constants.proximityRouteLabelSourceId,
            data: Self.proximityLabelGeoJSON(displayedProximityRoute)
        )
        
        try? mapView.mapboxMap.setLayerProperty(
            for: Constants.proximityRouteLayerId,
            property: "line-color",
            value: StyleColor(indicatorColor).rawValue
        )
        
        // MARK: - TICKET CODE
        let bearing = 90 - (displayedProximityRoute?.midpointBearing ?? 0)
        
        /*
         try? mapView.mapboxMap.setLayerProperty(
         for: Constants.proximityRouteLabelLayerId,
         property: "text-rotate",
         value: bearing
         )
         */
        
        try? mapView.mapboxMap.setLayerProperty(
            for: Constants.proximityRouteLabelLayerId,
            property: "text-color",
            value: StyleColor(indicatorColor).rawValue
        )
    }
    
    private func applyMapOverlays() {
        applyCloudOverlay()
        applyLightPollutionOverlay()
    }
    
    private func applyCloudOverlay() {
        guard config?.overlay == .clouds else {
            // remove cloud overlay
            do {
                if mapView.mapboxMap.layerExists(withId: Constants.cloudLayerId) {
                    try mapView.mapboxMap.removeLayer(withId: Constants.cloudLayerId)
                }
                
                if mapView.mapboxMap.sourceExists(withId: Constants.cloudSourceId) {
                    try mapView.mapboxMap.removeSource(withId: Constants.cloudSourceId)
                }
            } catch {
                print("Unable to remove cloud overlay: \(error)")
            }
            return
        }
        
        do {
            if !mapView.mapboxMap.sourceExists(withId: Constants.cloudSourceId) {
                // add cloud source
                var imageSource = ImageSource(id: Constants.cloudSourceId)
                imageSource.url = Constants.cloudImageURL
                imageSource.coordinates = Constants.cloudImageCoordinates
                try mapView.mapboxMap.addSource(imageSource)
            }
            
            if !mapView.mapboxMap.layerExists(withId: Constants.cloudLayerId) {
                try mapView.mapboxMap.addLayer(
                    makeCloudLayer(),
                    layerPosition: .below(Constants.routeLayerId)
                )
            }
        } catch {
            print("Unable to display cloud overlay: \(error)")
        }
    }
    
    private func applyLightPollutionOverlay() {
        guard config?.overlay == .lightPollution else {
            // remove light pollution overlay
            do {
                if mapView.mapboxMap.layerExists(withId: Constants.lightPollutionLayerId) {
                    try mapView.mapboxMap.removeLayer(withId: Constants.lightPollutionLayerId)
                }
                
                if mapView.mapboxMap.sourceExists(withId: Constants.lightPollutionSourceId) {
                    try mapView.mapboxMap.removeSource(withId: Constants.lightPollutionSourceId)
                }
            } catch {
                print("Unable to remove light pollution overlay: \(error)")
            }
            return
        }
        
        do {
            if !mapView.mapboxMap.sourceExists(withId: Constants.lightPollutionSourceId) {
                // add light pollution source
                var rasterSource = RasterSource(id: Constants.lightPollutionSourceId)
                rasterSource.tiles = [Constants.lightPollutionTileURLTemplate]
                rasterSource.tileSize = Constants.lightPollutionTileSize
                rasterSource.minzoom = Constants.lightPollutionMinZoom
                rasterSource.maxzoom = Constants.lightPollutionMaxZoom
                rasterSource.bounds = Constants.lightPollutionBounds
                rasterSource.volatile = true
                rasterSource.tileCacheBudget = .tiles(Constants.lightPollutionTileCacheBudget)
                
                try mapView.mapboxMap.addSource(rasterSource)
            }
            
            if !mapView.mapboxMap.layerExists(withId: Constants.lightPollutionLayerId) {
                try mapView.mapboxMap.addLayer(
                    makeLightPollutionLayer(),
                    layerPosition: .below(Constants.routeLayerId)
                )
            }
        } catch {
            print("Unable to display light pollution overlay: \(error)")
        }
    }
    
}

extension HomeViewMapController {
    
    func updateCamera(_ camera: CameraState) {
        mapView.mapboxMap.setCamera(
            to: CameraOptions(
                center: ScreenshotMode.cameraCenter ?? camera.center,
                padding: camera.padding,
                zoom: ScreenshotMode.cameraZoom ?? Constants.defaultZoom,
                bearing: ScreenshotMode.cameraBearing ?? Constants.defaultBearing,
                pitch: ScreenshotMode.cameraPitch ?? Constants.defaultPitch
            )
        )
    }
    
    func updateSelectedModel(id: String?, uri: String?) {
        guard selectedModelId != id || selectedModelUri != uri else { return }
        selectedModelId = id
        selectedModelUri = uri
        
        guard isStyleLoaded else { return }
        applySelectedModel()
    }
    
    func updateRoute(_ route: Model3DRoute?) {
        guard self.route?.coordinates != route?.coordinates else { return }
        self.route = route
        
        guard isStyleLoaded else { return }
        applyRoute()
    }
    
    func updateVisibleRegion(_ visibleRegionCoordinates: [[Double]]?) {
        guard self.visibleRegionCoordinates != visibleRegionCoordinates else { return }
        self.visibleRegionCoordinates = visibleRegionCoordinates
        
        guard isStyleLoaded else { return }
        applyVisibleRegion()
    }
    
    func updateProximityRoute(_ proximityRoute: ProximityRoute?) {
        guard self.proximityRoute?.coordinates != proximityRoute?.coordinates else { return }
        self.proximityRoute = proximityRoute
        
        guard isStyleLoaded else { return }
        applyProximityRoute()
    }
    
    func updateMapConfig(_ config: MapConfiguration) {
        let previousConfig = self.config
        guard self.config != config else { return }
        self.config = config
        
        if previousConfig?.basemap != config.basemap {
            applyMapStyleAndOverlays(colorScheme: colorScheme)
        } else if isStyleLoaded {
            applyVisibleRegion()
            applyProximityRoute()
            applyMapOverlays()
        }
    }
    
    func updateColorScheme(_ newValue: ColorScheme) {
        guard colorScheme != newValue else { return }
        
        colorScheme = newValue
        guard isViewLoaded else { return }
        applyMapStyleAndOverlays(colorScheme: newValue)
    }
    
    private func applyMapStyleAndOverlays(colorScheme: ColorScheme) {
        guard let style = config?.basemap.style(for: colorScheme) else { return }
        
        isStyleLoaded = false
        mapView.mapboxMap.mapStyle = style
    }
    
}

extension HomeViewMapController: GestureManagerDelegate {
    
    func gestureManager(_ gestureManager: GestureManager, didBegin gestureType: GestureType) {
        guard gestureType != .singleTap else { return }
        onUserInteraction?()
    }
    
    func gestureManager(_ gestureManager: GestureManager, didEnd gestureType: GestureType, willAnimate: Bool) { }
    
    func gestureManager(_ gestureManager: GestureManager, didEndAnimatingFor gestureType: GestureType) { }
    
}

extension HomeViewMapController {
    
    private enum Constants {
        /// Default bottom margin for Mapbox ornaments.
        static let defaultOrnamentBottomMargin: CGFloat = 65
        
        /// Horizontal margin used by the Mapbox logo ornament.
        static let logoTrailingMargin: CGFloat = 50
        
        /// Horizontal margin used by the Mapbox attribution ornament.
        static let attributionTrailingMargin: CGFloat = 10
        
        /// Fallback coordinate used before the selected model has live data.
        static let defaultCoordinates = Point(CLLocationCoordinate2D(latitude: 39.5, longitude: -98.0))
        
        /// GeoJSON property key used to bind a feature to a style model.
        static let modelIdKey = "model-id-key"
        
        /// Source identifier for the selected satellite model.
        static let modelsSourceId = "source-id"
        
        /// Layer identifier for the selected satellite model.
        static let modelLayerId = "model-layer-id"
        
        /// Source identifier for the satellite route.
        static let routeSourceId = "route-source-id"
        
        /// Layer identifier for the satellite route.
        static let routeLayerId = "route-layer-id"
        
        /// Source identifier for the satellite visible region route.
        static let visibleRegionSourceId = "visible-region-source-id"
        
        /// Layer identifier for the satellite visible region route.
        static let visibleRegionLayerId = "visible-region-layer-id"
        
        /// Source identifier for the route between the selected satellite and the user.
        static let proximityRouteSourceId = "proximity-route-source-id"
        
        /// Layer identifier for the route between the selected satellite and the user.
        static let proximityRouteLayerId = "proximity-route-layer-id"
        
        static let proximityRouteLabelSourceId = "proximity-route-label-source-id"
        static let proximityRouteLabelLayerId = "proximity-route-label-layer-id"
        static let proximityLabelKey = "proximity-label"
        
        static let cloudSourceId = "cloud-image-source"
        static let cloudLayerId = "cloud-image-layer"
        static let cloudImageURL = "https://bxmogibkelbcnqaupgob.supabase.co/storage/v1/object/public/tiling/cloud_latest.png"
        static let cloudImageCoordinates = [
            [-180.0, 90],
            [180.0, 90],
            [180.0, -90],
            [-180.0, -90]
        ]
        static let cloudOpacity = 0.8
        static let cloudEmissiveStrength = 0.8
        
        static let lightPollutionSourceId = "light-pollution-raster-source"
        static let lightPollutionLayerId = "light-pollution-raster-layer"
        static let lightPollutionTileURLTemplate = "https://bxmogibkelbcnqaupgob.supabase.co/storage/v1/object/public/tiling/light_pollution_tiles.bundle/{z}/{x}/{y}.png"
        static let lightPollutionTileSize = 512.0
        static let lightPollutionMinZoom = 0.0
        static let lightPollutionMaxZoom = 6.0
        static let lightPollutionBounds = [-180.0, -65.0, 180.0, 75.0]
        static let lightPollutionTileCacheBudget = 128
        static let lightPollutionOpacity = 0.9
        
        /// Extra altitude applied to keep the 3D model visible above the map.
        static let zOffset: Double = 100
        
        /// Default zoom level adjusted for iPad orientation.
        static var defaultZoom: CGFloat {
            guard UIDevice.current.userInterfaceIdiom == .pad else {
                return 3
            }
            return UIDevice.current.orientation.isLandscape ? 3 : 4
        }
        
        /// Default map camera bearing.
        static let defaultBearing: CGFloat = 25
        
        /// Default map camera pitch.
        static let defaultPitch: CGFloat = 15
    }
    
}
