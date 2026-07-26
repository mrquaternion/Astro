//
//  MapConfiguration.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-13.
//

import MapboxMaps
import UIKit.UIColor

struct MapConfiguration: Equatable {
    
    enum MapIndicator: CaseIterable {
        case angularRadius
        case proximityRoute
        
        var name: String {
            switch self {
            case .angularRadius: "Visibility radius"
            case .proximityRoute: "Distance to satellite"
            }
        }
        
        var image: String {
            switch self {
            case .angularRadius: "angular_radius_indicator"
            case .proximityRoute: "proximity_route_indicator"
            }
        }
    }
    
    enum MapOverlay: CaseIterable {
        case clouds
        case lightPollution
        
        var name: String {
            switch self {
            case .clouds: "Clouds"
            case .lightPollution: "Light pollution"
            }
        }
        
        var image: String {
            switch self {
            case .clouds: "clouds_overlay"
            case .lightPollution: "light_pollution_overlay"
            }
        }
        
        var requiredBasemap: MapBasemap {
            switch self {
            case .clouds: .satellite
            case .lightPollution: .night
            }
        }
    }
    
    enum MapBasemap: CaseIterable {
        case standard
        case satellite
        case night
        
        var name: String {
            switch self {
            case .standard: "Standard"
            case .satellite: "Satellite imagery"
            case .night: "Night map"
            }
        }
        
        var image: String {
            switch self {
            case .standard: "standard_map"
            case .satellite: "satellite_map"
            case .night: "night_map"
            }
        }
        
        var style: MapStyle {
            switch self {
            case .standard: .standard(lightPreset: .day, showPointOfInterestLabels: false, showPlaceLabels: false, showRoadLabels: false)
            case .satellite: .standardSatellite(lightPreset: .day, showPointOfInterestLabels: false, showPlaceLabels: false, showRoadLabels: false, showRoadsAndTransit: false)
            case .night: .standard(theme: .monochrome, lightPreset: .night, showPointOfInterestLabels: false, showTransitLabels: false, showPlaceLabels: false, showRoadLabels: false, showPedestrianRoads: false, showAdminBoundaries: false)
            }
        }
    }
    
    /// Value used for indicator.
    var indicator: MapIndicator?
    /// Value used for overlay.
    var overlay: MapOverlay?
    /// Value used for basemap.
    var basemap: MapBasemap
    
    init(indicator: MapIndicator? = nil, overlay: MapOverlay? = nil, basemap: MapBasemap = .satellite) {
        self.indicator = indicator
        self.overlay = overlay
        self.basemap = basemap
    }
    
    /// Value used for indicatorColor.
    var indicatorColor: UIColor {
        guard indicator != .none else { return .clear }
        
        switch (basemap, overlay) {
        case (.night, .lightPollution):
            return UIColor(white: 1.0, alpha: 0.7)
        case (.satellite, .clouds):
            // light blue
            return UIColor(red: 0.537, green: 0.812, blue: 0.941, alpha: 1.0)
        case (.satellite, .none):
            return UIColor(white: 1.0, alpha: 0.7)
        case (.standard, _):
            return UIColor(white: 0.0, alpha: 0.7)
        default:
            return UIColor(white: 1.0, alpha: 0.7)
        }
    }
    
    mutating func selectOverlay(_ overlay: MapOverlay) {
        guard overlay != self.overlay else {
            self.overlay = nil
            return
        }
        
        self.overlay = overlay
        
        basemap = overlay.requiredBasemap
    }
    
    mutating func selectIndicator(_ indicator: MapIndicator) {
        guard indicator != self.indicator else {
            self.indicator = nil
            return
        }
        
        self.indicator = indicator
    }
    
    mutating func selectBasemap(_ basemap: MapBasemap) {
        self.basemap = basemap
        
        if let required = overlay?.requiredBasemap,
           required != basemap {
            overlay = nil
        }
    }
}
