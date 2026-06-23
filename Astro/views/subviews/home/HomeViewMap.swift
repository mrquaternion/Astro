//
//  Animated3DModelMapView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-04.
//

import SwiftUI
import SatelliteKit
import MapboxMaps

struct HomeViewMap: View {
    /// Shared home state that identifies the selected satellite.
    @EnvironmentObject var viewViewModel: HomeViewModel
    
    /// Tracker state that drives the 3D model and camera.
    @EnvironmentObject var trackerViewModel: SatelliteTrackingViewModel
    
    /// The Mapbox-backed satellite map.
    var body: some View {
        HomeViewMapControllerRepresentable(
            modelId: viewViewModel.selectedSatellite?.id,
            modelURL: viewViewModel.selectedSatellite?.modelURL,
            model: $trackerViewModel.model,
            route: viewViewModel.selectedSatellite?.route,
            camera: $trackerViewModel.camera,
            isTrackingModel: $trackerViewModel.isTrackingModel
        )
        .ignoresSafeArea()
        .task(id: viewViewModel.selectedSatellite?.id) {
            guard viewViewModel.selectedSatellite != nil else { return }
            trackerViewModel.isTrackingModel = true

            do {
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
    }

    private func loadSelectedSatellitePosition() throws {
        guard let selectedSatellite = viewViewModel.selectedSatellite else { return }
        
        let satellite = Satellite(elements: selectedSatellite.elements)
        let lla = try satellite.geoPosition(minsAfterEpoch: satellite.minsAfterEpoch)
        let dt = 0.01
        let nextLla = try satellite.geoPosition(minsAfterEpoch: satellite.minsAfterEpoch + dt)
        let avgSpeed = try satellite.velocity(minsAfterEpoch: satellite.minsAfterEpoch)
        
        let longitude = lla.lon > 180 ? lla.lon - 360 : lla.lon
        let bearing = Animated3DModelHelpers.bearing(lat1: lla.lat, lon1: lla.lon, lat2: nextLla.lat, lon2: nextLla.lon)
                
        trackerViewModel.model = Model3D(
            position: [longitude, lla.lat],
            altitude: lla.alt,
            bearing: bearing,
            velocity: avgSpeed.magnitude()
        )
        
        if trackerViewModel.isTrackingModel {
            trackerViewModel.camera = CameraState(
                center: LocationCoordinate2D(
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
            
            let newSegment = Animated3DModelHelpers.haversine(p1: p1, p2: p2)
            distances.append(distances[i - 1] + newSegment)
        }
        
        self.distances = distances
    }
}

public class Animated3DModelHelpers {
    /// Source: https://www.movable-type.co.uk/scripts/latlong.html#:~:text=a%20constant%20bearing!-,Bearing,-In%20general%2C%20your
    static func bearing(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let phi1 = lat1 * .pi / 180
        let phi2 = lat2 * .pi / 180
        let deltaLambda = (lon2 - lon1) * .pi / 180
        
        let y = sin(deltaLambda) * cos(phi2)
        let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda)
        let theta = atan2(y, x)
        let normalized = (theta * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        return normalized
    }
    
    static func haversine(p1: [Double], p2: [Double]) -> Double {
        let toRad = Double.pi / 180
        
        let phi1 = p1[1]  * toRad
        let phi2 = p2[1]  * toRad
        let deltaLambda = (p2[0] - p1[0]) * toRad
        let deltaPhi = phi2 - phi1
        
        let havTheta = (1 - cos(deltaPhi) + cos(phi1) * cos(phi2) * (1 - cos(deltaLambda))) / 2
        
        let theta = acos(1 - 2 * havTheta)
        
        // not the mathematically correct way of doing it
        let r = Double(Constants.equatorialRadius + Constants.polarRadius) / 2
        return r * theta
    }
}

private enum Constants {
    /// Fallback position used before a satellite update arrives.
    static let defaultPosition = [-98.0, 39.5]
    
    /// Fallback altitude used before a satellite update arrives.
    static let defaultAltitude = 400.0
    
    /// Earth equatorial radius in meters.
    static let equatorialRadius = 6_378_137
    
    /// Earth polar radius in meters.
    static let polarRadius = 6_356_752
}
