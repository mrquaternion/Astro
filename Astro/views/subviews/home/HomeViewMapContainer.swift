//
//  Animated3DModelMapView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-04.
//

import SwiftUI
import SatelliteKit
import MapboxMaps

struct HomeViewMapContainer: View {
    /// Shared home state that identifies the selected satellite.
    @EnvironmentObject var viewViewModel: HomeViewModel
    
    /// Tracker state that drives the 3D model and camera.
    @EnvironmentObject var trackerViewModel: SatelliteTrackingViewModel
    
    /// Mutable view state tracking localizationManager.
    @State private var localizationManager = LocalizationManager.shared
    
    /// Mutable view state tracking errorMessage.
    @State private var errorMessage: String?
    
    ///  Map layers configuration.
    @Binding var config: MapConfiguration
    
    /// The Mapbox-backed satellite map.
    var body: some View {
        HomeViewMapControllerRepresentable(
            modelId: viewViewModel.selectedSatellite?.id,
            modelUri: viewViewModel.selectedSatellite?.modelUri,
            model: $trackerViewModel.model,
            route: viewViewModel.selectedSatellite?.route,
            visibleRegionCoordinates: GeoMaths.sphericalCircle(
                lat1: trackerViewModel.model.position[1],
                lng1: trackerViewModel.model.position[0],
                alt: trackerViewModel.model.altitude
            ),
            proximityRoute: ScreenshotMode.isEnabled
                ? nil
                : viewViewModel.routeFromUser(from: trackerViewModel.model),
            camera: $trackerViewModel.camera,
            isTrackingModel: $trackerViewModel.isTrackingModel,
            config: config
        )
        .ignoresSafeArea()
        .task(id: viewViewModel.selectedSatellite?.id) {
            guard viewViewModel.selectedSatellite != nil else { return }
            trackerViewModel.isTrackingModel = true
            
            do {
                if ScreenshotMode.isEnabled {
                    try loadSelectedSatellitePosition(
                        minutesAfterEpoch: ScreenshotMode.satelliteMinutesAfterEpoch
                    )
                    return
                }
                
                while true {
                    try Task.checkCancellation()
                    try loadSelectedSatellitePosition()
                    try await Task.sleep(for: .milliseconds(33))
                }
            } catch is CancellationError {
                return
            } catch {
                print(error)
            }
        }
        .task {
            guard !ScreenshotMode.isEnabled else { return }
            
            do {
                try await localizationManager.verifyAuthorization()
                let _ = try await localizationManager.currentLocation
            } catch {
                errorMessage = (error as? LocalizationManager.LocalizationError)?.description
                    ?? error.localizedDescription
            }
        }
        .alert("location_error_title".localizedFirstCapitalized, isPresented: .constant(errorMessage != nil)) {
            Button("common_ok".localized) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func loadSelectedSatellitePosition(minutesAfterEpoch: Double? = nil) throws {
        guard let selectedSatellite = viewViewModel.selectedSatellite else { return }
        
        let satellite = Satellite(elements: selectedSatellite.elements)
        let propagationTime = minutesAfterEpoch ?? satellite.minsAfterEpoch
        let lla = try satellite.geoPosition(minsAfterEpoch: propagationTime)
        let dt = 0.01
        let nextLla = try satellite.geoPosition(minsAfterEpoch: propagationTime + dt)
        let avgSpeed = try satellite.velocity(minsAfterEpoch: propagationTime)
        
        let longitude = lla.lon > 180 ? lla.lon - 360 : lla.lon
        let bearing = GeoMaths.bearing(lat1: lla.lat, lon1: lla.lon, lat2: nextLla.lat, lon2: nextLla.lon)
        
        trackerViewModel.model = Model3D(
            position: [longitude, lla.lat],
            altitude: lla.alt,
            bearing: bearing,
            velocity: avgSpeed.magnitude()
        )
        
        if trackerViewModel.isTrackingModel {
            trackerViewModel.camera = CameraState(
                center: ScreenshotMode.cameraCenter ?? LocationCoordinate2D(
                    latitude: lla.lat,
                    longitude: longitude
                ),
                padding: trackerViewModel.camera.padding,
                zoom: trackerViewModel.camera.zoom,
                bearing: trackerViewModel.camera.bearing,
                pitch: trackerViewModel.camera.pitch
            )
        }
    }
}

struct Model3D {
    /// The current position of the model.
    var position: [Double] = Constants.defaultPosition
    
    /// The current altitude of the model.
    var altitude: Double = Constants.defaultAltitude
    
    /// The current bearing of the model.
    var bearing: Double = 0.0
    
    /// The average speed of the model.
    var velocity: Double = 0.0
}

struct Model3DRoute {
    /// The coordinates of the route.
    let coordinates: [[Double]]
    
    /// The heights at which the model is at every coordinates along the route.
    let elevations: [Double]
    
    /// The distances of every coordinates by the starting point.
    let distances: [Double]
    
    /// Total route length measured from the cumulative route distances.
    var totalLength: Double {
        distances.last ?? 0.0
    }
    
    init(coordinates: [[Double]], elevations: [Double]) {
        self.coordinates = coordinates
        self.elevations = elevations
        
        var distances: [Double] = [0.0]
        for i in 1..<coordinates.count {
            let p1 = coordinates[i - 1]
            let p2 = coordinates[i]
            
            // the ISS goes pretty fast compared to a plane, 7.67 km/s in average
            // thus, every minute, it travels 460 km
            // this means that simple euclidean geometry is not accurate anymore
            // we must use haversine formulae
            
            let newSegment = GeoMaths.haversine(
                p1: CLLocationCoordinate2D(latitude: p1[1], longitude: p1[0]),
                p2: CLLocationCoordinate2D(latitude: p2[1], longitude: p2[0])
            )
            distances.append(distances[i - 1] + newSegment)
        }
        
        self.distances = distances
    }
}

private enum Constants {
    /// Fallback position used before a satellite update arrives.
    static let defaultPosition = [-98.0, 39.5]
    
    /// Fallback altitude used before a satellite update arrives.
    static let defaultAltitude = 400.0
}
