//
//  LocalizationManager.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-11.
//

import Foundation
import CoreLocation

@Observable
@MainActor
class LocalizationManager: NSObject, CLLocationManagerDelegate {
    /// Shared localization manager for the application.
    static let shared = LocalizationManager()
    /// Core Location manager providing authorization and updates.
    private let manager = CLLocationManager()
    /// Pending authorization request.
    private var authorizationContinuation: CheckedContinuation<Void, Error>?
    /// Pending one-shot location request.
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    /// Most recently received device location.
    var location: CLLocation? = {
        if let coord = UserDefaults.standard.lastPosition {
            return CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        }
        return nil
    }() {
        didSet {
            guard let coord = location?.coordinate else { return }
            UserDefaults.standard.lastPosition = coord
        }
    }
    
    /// Current device location obtained from Core Location.
    var currentLocation: CLLocation {
        get async throws {
            if self.locationContinuation != nil {
                self.locationContinuation?.resume(throwing: LocalizationError.replacedContinuation)
                self.locationContinuation = nil
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                self.locationContinuation = continuation
                manager.requestLocation()
            }
        }
    }
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func verifyAuthorization() async throws {
        switch manager.authorizationStatus {
        case .notDetermined:
            try await withCheckedThrowingContinuation { continuation in
                self.authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        case .denied, .restricted:
            throw LocalizationError.permissionDenied
        default:
            return
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                authorizationContinuation?.resume()
                authorizationContinuation = nil
            case .denied, .restricted:
                authorizationContinuation?.resume(throwing: LocalizationError.permissionDenied)
                authorizationContinuation = nil
            default:
                break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let lastLocation = locations.last {
                self.location = lastLocation
                locationContinuation?.resume(returning: lastLocation)
                locationContinuation = nil
            } else {
                locationContinuation?.resume(throwing: LocalizationError.noLocationFound)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
    }
    
    enum LocalizationError: Error {
        case replacedContinuation
        case noLocationFound
        case permissionDenied

        var description: String {
            switch self {
            case .replacedContinuation:
                "location_error_replaced_continuation".localizedFirstCapitalized
            case .noLocationFound:
                "location_error_not_found".localizedFirstCapitalized
            case .permissionDenied:
                "location_error_permission_denied".localizedFirstCapitalized
            }
        }
    }
}

extension UserDefaults {
    private enum Keys {
        static let latitude = "lastLatitude"
        static let longitude = "lastLongitude"
    }
    
    /// Coordinate of the most recently stored location.
    var lastPosition: CLLocationCoordinate2D? {
        get {
            guard object(forKey: Keys.latitude) != nil,
                  object(forKey: Keys.longitude) != nil else { return nil }
            let lat = double(forKey: Keys.latitude)
            let lng = double(forKey: Keys.longitude)
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        set {
            if let newValue = newValue {
                set(newValue.latitude, forKey: Keys.latitude)
                set(newValue.longitude, forKey: Keys.longitude)
            }
        }
    }
}
