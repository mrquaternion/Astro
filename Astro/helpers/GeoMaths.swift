//
//  GeoMaths.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-10.
//

import CoreGraphics
import CoreLocation
import simd

class GeoMaths {
    
    /// Shared value used for EARTH_EQU_RAD.
    static let EARTH_EQU_RAD: Double = 6_378_137.0
    /// Shared value used for EARTH_POL_RAD.
    static let EARTH_POL_RAD: Double = 6_356_752.3142
    /// Shared value used for deg2rad.
    static let deg2rad: Double = .pi / 180
    
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
    
    static func haversine(p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D) -> Double {
        let toRad = Double.pi / 180
        
        let phi1 = p1.latitude  * toRad
        let phi2 = p2.latitude  * toRad
        let deltaLambda = (p2.longitude - p1.longitude) * toRad
        let deltaPhi = phi2 - phi1
        
        let havTheta = (1 - cos(deltaPhi) + cos(phi1) * cos(phi2) * (1 - cos(deltaLambda))) / 2
        
        let theta = acos(1 - 2 * havTheta)
        
        let r = (EARTH_EQU_RAD + EARTH_POL_RAD) / 2
        return r * theta
    }
    
    // source: https://www.reddit.com/r/askmath/comments/50adaz/comment/d752vfa/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
    static func sphericalCircle(lat1: Double, lng1: Double, alt: Double) -> [[Double]] {
        let r = visibilityRadius(altitude: alt)
        let eps: Double = 5e-8
        let lat1Rad = lat1 * .pi / 180
        let lng1Rad = lng1 * .pi / 180
        
        var points: [[Double]] = []
        for course in stride(from: -.pi, to: .pi, by: 0.01) {
            
            if (abs(cos(lat1Rad)) < eps) && !(abs(sin(course)) < eps) {
                print("Only N-S courses are meaningful, starting at a pole!")
            }
            
            let lat2 = asin(
                sin(lat1Rad) * cos(r) +
                cos(lat1Rad) * sin(r) * cos(course)
            )
            
            var lng2: Double
            
            if (abs(cos(lat2)) < eps) {
                lng2 = 0 // endpoint at pole
            } else {
                let deltaLng = atan2(
                    sin(course) * sin(r) * cos(lat1Rad),
                    cos(r) - sin(lat1Rad) * sin(lat2)
                )
                
                lng2 = mod(lng1Rad - deltaLng + .pi, 2 * .pi) - .pi
            }
            
            points.append([lng2 * 180 / .pi, lat2 * 180 / .pi])
        }
        
        if let first = points.first {
            points.append(first)
        }
        
        return points
    }
    
    static func geodeticToUnitSphere(p: CLLocationCoordinate2D, h: Double) -> SIMD3<Double> {
        return simd.normalize(geodeticToECEF(p: p, h: h))
    }
    
    static func geodeticToUnitSphereSpherical(p: CLLocationCoordinate2D) -> SIMD3<Double> {
        let phi = p.latitude * deg2rad
        let lambda = p.longitude * deg2rad

        return SIMD3(
            cos(phi) * cos(lambda),
            cos(phi) * sin(lambda),
            sin(phi)
        )
    }
    
    static func unitSphereToGeodetic(p: SIMD3<Double>) -> SIMD3<Double> {
        return ECEFToGeodetic(p0: p * (EARTH_EQU_RAD + EARTH_POL_RAD) / 2)
    }
    
    static func unitSphereToGeodeticSpherical(p: SIMD3<Double>) -> SIMD3<Double> {
        let r = simd.length(p)
        let lat = asin(p.z / r) / deg2rad
        let lon = atan2(p.y, p.x) / deg2rad
        return SIMD3(lon, lat, 0)
    }
    
    // source: https://en.wikipedia.org/wiki/Spherical_linear_interpolation#Geometric_slerp
    static func slerp(p0: SIMD3<Double>, p1: SIMD3<Double>, t: Double) -> SIMD3<Double> {
        let dp = acos(Swift.min(1, Swift.max(-1, simd.dot(p0, p1))))
        let lhs = sin((1.0 - t) * dp) / sin(dp) * p0
        let rhs = sin(t * dp) / sin(dp) * p1
        return lhs + rhs
    }
    
    // source: https://en.wikipedia.org/wiki/Geographic_coordinate_conversion#From_geodetic_to_ECEF_coordinates
    static func geodeticToECEF(p: CLLocationCoordinate2D, h: Double) -> SIMD3<Double> {
        let phi = p.latitude * deg2rad
        let lambda = p.longitude * deg2rad
        
        func N(_ phi: Double) -> Double {
            let eer2 = EARTH_EQU_RAD * EARTH_EQU_RAD
            let epr2 = EARTH_POL_RAD * EARTH_POL_RAD
            let num = eer2 * eer2
            let denum = eer2 * cos(phi) * cos(phi) + epr2 * sin(phi) * sin(phi)
            return num / denum
        }
        
        let X = (N(phi) + h) * cos(phi) * cos(lambda)
        let Y = (N(phi) + h) * cos(phi) * sin(lambda)
        let Z = (((EARTH_POL_RAD * EARTH_POL_RAD) / (EARTH_EQU_RAD * EARTH_EQU_RAD)) * N(phi) + h) * sin(phi)
        
        return SIMD3<Double>(x: X, y: Y, z: Z)
    }
    
    // source: https://en.wikipedia.org/wiki/Geographic_coordinate_conversion#From_ECEF_to_geodetic_coordinates
    private static func ECEFToGeodetic(p0: SIMD3<Double>) -> SIMD3<Double> {
        let a = EARTH_EQU_RAD
        let b = EARTH_POL_RAD
        let e2 = (a * a - b * b) / (a * a)
        let e2Prime = (a * a - b * b) / (b * b)
        let p = sqrt(p0.x * p0.x + p0.y * p0.y)
        let theta = atan2(a * p0.z, b * p)
        let sinTheta = sin(theta)
        let cosTheta = cos(theta)
        let latitude = atan2(
            p0.z + e2Prime * b * sinTheta * sinTheta * sinTheta,
            p - e2 * a * cosTheta * cosTheta * cosTheta
        )
        let longitude = atan2(p0.y, p0.x)
        let n = a / sqrt(1 - e2 * sin(latitude) * sin(latitude))
        let altitude = p / cos(latitude) - n

        return SIMD3(longitude / deg2rad, latitude / deg2rad, altitude)
    }
    
    private static func visibilityRadius(altitude: Double) -> Double {
        let r = (EARTH_EQU_RAD + EARTH_POL_RAD) / 2
        let cosTheta = r / (r + altitude * 1000)
        let theta = acos(cosTheta)
        return theta
    }
    
    private static func mod(_ x: Double, _ m: Double) -> Double {
        (x.truncatingRemainder(dividingBy: m) + m)
            .truncatingRemainder(dividingBy: m)
    }
}
