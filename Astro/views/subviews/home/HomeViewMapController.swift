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
    
    /// URL of the model currently registered with Mapbox.
    private var registeredModelURL: URL?
    
    /// Identifier of the selected satellite model.
    var selectedModelId: String?
    
    /// On-device asset URL for the selected satellite model.
    var selectedModelURL: URL?
    
    /// Upcoming route for the selected satellite.
    var route: Model3DRoute?
    
    /// Callback fired when the user moves the map manually.
    var onUserInteraction: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MapView(frame: view.bounds, mapInitOptions: .init(
            mapStyle: .standardSatellite(lightPreset: .day, showPointOfInterestLabels: false, showRoadLabels: false)
        ))
        mapView.gestures.delegate = self
        
        mapView.mapboxMap.onStyleLoaded.observeNext { [weak self] _ in
            guard let self else { return }
            try? self.mapView.mapboxMap.setAtmosphere(Atmosphere()
                .starIntensity(3)
                .horizonBlend(0.02)
            )
            self.isStyleLoaded = true
            
            self.applySelectedModel()
            self.applyRoute()
            
            if let pending = self.pendingUpdate {
                self.applyModelUpdate(lon: pending.lon, lat: pending.lat, alt: pending.alt, bearing: pending.bearing)
                self.pendingUpdate = nil
            }
        }.store(in: &cancellables)
        
        mapView.ornaments.options = .init(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            compass: CompassViewOptions(visibility: .hidden),
            logo: LogoViewOptions(
                position: .bottomTrailing,
                margins: CGPoint(x: 50, y: 65)
            ),
            attributionButton: AttributionButtonOptions(
                position: .bottomTrailing,
                margins: CGPoint(x: 10, y: 65),
                tintColor: UIColor(white: 0.6, alpha: 1)
            )
        )
        
        var modelFeature = Feature(geometry: Constants.defaultCoordinates)
        modelFeature.properties = [Constants.modelIdKey: .string(selectedModelId ?? "")]
        
        mapView.mapboxMap.setMapStyleContent {
            GeoJSONSource(id: Constants.modelsSourceId)
                .data(.featureCollection(FeatureCollection(features: [modelFeature])))
            
            ModelLayer(id: Constants.modelLayerId, source: Constants.modelsSourceId)
                .modelId(Exp(.get) { Constants.modelIdKey })
                .modelType(.common3d)
                .modelScale(x: 60_000, y: 60_000, z: 60_000)
                .modelTranslation(x: 0, y: 0, z: 1_000_000)
                .modelRotation(x: 0, y: 0, z: 0)
                .modelOpacity(1)
            
            GeoJSONSource(id: Constants.routeSourceId)
                .data(Self.routeGeoJSON(route))
            
            LineLayer(id: Constants.routeLayerId, source: Constants.routeSourceId)
                .lineColor(.init(UIColor(white: 1, alpha: 1)))
                .lineWidth(5.0)
                .lineEmissiveStrength(1.0)
                .lineJoin(.round)
        }
        
        view.addSubview(mapView)
    }
    
    func updateCamera(_ camera: CameraState) {
        mapView.mapboxMap.setCamera(
            to: CameraOptions(
                center: camera.center,
                zoom: Constants.defaultZoom,
                bearing: Constants.defaultBearing,
                pitch: Constants.defaultPitch
            )
        )
    }
    
    func updateSelectedModel(id: String?, url: URL?) {
        guard selectedModelId != id || selectedModelURL != url else { return }
        selectedModelId = id
        selectedModelURL = url
        
        guard isStyleLoaded else { return }
        applySelectedModel()
    }
    
    func updateRoute(_ route: Model3DRoute?) {
        guard self.route?.coordinates != route?.coordinates else { return }
        self.route = route
        
        guard isStyleLoaded else { return }
        applyRoute()
    }
    
    func updateModel(longitude: Double, latitude: Double, altitude: Double, bearing: Double) {
        pendingUpdate = (longitude, latitude, altitude, bearing)
        
        guard isStyleLoaded else { return }
        
        applyModelUpdate(lon: longitude, lat: latitude, alt: altitude, bearing: bearing)
        pendingUpdate = nil
    }
    
    private func applySelectedModel() {
        guard let selectedModelId, let selectedModelURL else { return }
        
        do {
            if registeredModelId != selectedModelId || registeredModelURL != selectedModelURL {
                if let registeredModelId, mapView.mapboxMap.hasStyleModel(modelId: registeredModelId) {
                    try mapView.mapboxMap.removeStyleModel(modelId: registeredModelId)
                }
                
                if !mapView.mapboxMap.hasStyleModel(modelId: selectedModelId) {
                    try mapView.mapboxMap.addStyleModel(
                        modelId: selectedModelId,
                        modelUri: selectedModelURL.absoluteString
                    )
                }
                
                registeredModelId = selectedModelId
                registeredModelURL = selectedModelURL
            }
            
            if let pendingUpdate {
                applyModelUpdate(
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
            data: Self.routeGeoJSON(route)
        )
    }
    
    private func applyModelUpdate(lon: Double, lat: Double, alt: Double, bearing: Double) {
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
    
    private static func routeGeoJSON(_ route: Model3DRoute?) -> GeoJSONSourceData {
        guard let route else {
            return .featureCollection(FeatureCollection(features: []))
        }
        
        var routeSegments: [[CLLocationCoordinate2D]] = []
        var currentSegment: [CLLocationCoordinate2D] = []
        
        for coordinate in route.coordinates {
            let nextCoordinate = CLLocationCoordinate2D(
                latitude: coordinate[1],
                longitude: coordinate[0]
            )
            
            if let previousCoordinate = currentSegment.last,
               abs(nextCoordinate.longitude - previousCoordinate.longitude) > 180 {
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
