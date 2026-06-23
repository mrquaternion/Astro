//
//  SatelliteTrackingViewModel.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-10.
//

import Foundation
import MapboxMaps
import Combine
import UIKit

@MainActor
final class SatelliteTrackingViewModel: ObservableObject {
    /// The selected satellite's live position and movement.
    @Published var model = Model3D()
    
    /// If current view is following the satellite trajectory.
    @Published var isTrackingModel = true
    
    /// Satellite dedicated camera following its live trajectory,
    @Published var camera = CameraState(
        center: CLLocationCoordinate2D(
            latitude: 45.5,
            longitude: 75.5
        ),
        padding: .zero,
        zoom: 3,
        bearing: .zero,
        pitch: .zero
    )
}
