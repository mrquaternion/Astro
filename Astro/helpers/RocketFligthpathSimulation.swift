//
//  RocketFligthPathSimulation.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-18.
//

import Foundation
import CoreLocation
import simd

struct TrajectoryPoint {
    /// Value used for coordinate.
    let coordinate: CLLocationCoordinate2D
    /// Value used for altitude.
    let altitude: Double
}

final class RocketFligthPathSimulation {
    /// Computed trajectory.
    var trajectory: [TrajectoryPoint]?
    
    /// The maximum altitude reachable, in meters.
    var maxAltitude: Double
    
    /// If the trajectory should stop at `maxAltitude`.
    var shouldGoBackDown: Bool
    
    init(maxAltitude: Double, shouldGoBackDown: Bool) {
        self.maxAltitude = maxAltitude
        self.shouldGoBackDown = shouldGoBackDown
    }
    
    func simulate(from tp1: TrajectoryPoint, to tp2: TrajectoryPoint) {
        let c1 = tp1.coordinate
        let c2 = tp2.coordinate
        
        let start = GeoMaths.geodeticToUnitSphereSpherical(p: c1)
        let end = GeoMaths.geodeticToUnitSphereSpherical(p: c2)
        
        // flight path profile
        var bezierPoints: [SIMD2<Double>] = []
        for i in 0...Constants.totalSteps {
            let step = Double(i) / Double(Constants.totalSteps)
            let point = Self.bezier(Double(step))
            bezierPoints.append(point)
        }

        // altitude projection scale
        let yMaxPoint = bezierPoints.max(by: { $0.y < $1.y })
        guard yMaxPoint != nil, let yMax = yMaxPoint?.y else { return }
        let scale = maxAltitude / yMax
        
        // conditioning regarding mission type
        let stepsToKeep: [SIMD2<Double>]
        if shouldGoBackDown {
            stepsToKeep = bezierPoints
        } else {
            guard let apexIndex = bezierPoints.firstIndex(where: { $0.y == yMax }) else { return }
            stepsToKeep = Array(bezierPoints[0...apexIndex])
        }
        
        // final trajectory
        var trajectoryPoints: [TrajectoryPoint] = []
        for point in stepsToKeep {
            let ground = GeoMaths.slerp(p0: start, p1: end, t: point.x)
            
            let h = scale * point.y
            let earthRadius = (GeoMaths.EARTH_EQU_RAD + GeoMaths.EARTH_POL_RAD) / 2
            let normalizedAltitude = h / earthRadius
            
            let finalUnit = ground * (1.0 + normalizedAltitude)

            let coordinate = GeoMaths.unitSphereToGeodeticSpherical(p: finalUnit)
            trajectoryPoints.append(TrajectoryPoint(coordinate: CLLocationCoordinate2D(latitude: coordinate.y, longitude: coordinate.x), altitude: h))
        }
        
        trajectory = trajectoryPoints
    }
    
    private static func bezier(_ t: Double) -> SIMD2<Double> {
        let points: [SIMD2<Double>] = [
            Constants.P0, Constants.P1,
            Constants.P2, Constants.P3
        ]
        
        var polys: [SIMD2<Double>] = []
        for i in 0...Constants.degree {
            let bPoly = bernsteinPoly(t, step: i)
            let poly = bPoly * points[i]
            polys.append(poly)
        }
        
        return polys.reduce(.zero, +)
    }
    
    private static func bernsteinPoly(_ t: Double, step: Int) -> Double {
        return (
            binomialCoeff(n: Constants.degree, k: step) *
            pow(1 - t, Double(Constants.degree - step)) *
            pow(t, Double(step))
        )
    }
    
    private static func binomialCoeff(n: Int, k: Int) -> Double {
        let num = factorial(n)
        let denum = factorial(k) * factorial(n - k)
        return Double(num) / Double(denum)
    }
    
    /// Only using up to factorial 3, can't go higher than 20
    private static func factorial(_ num: Int) -> Int {
        if num == 0 {
            return 1
        } else {
            return num * factorial(num - 1)
        }
    }
}

private enum Constants {
    /// Shared value used for totalSteps.
    static let totalSteps = 100
    /// Shared value used for degree.
    static let degree = 3
    
    /// Shared value used for P0.
    static let P0 = SIMD2<Double>(0, 0)
    /// Shared value used for P1.
    static let P1 = SIMD2<Double>(0, 1)
    /// Shared value used for P2.
    static let P2 = SIMD2<Double>(0.8, 0.3)
    /// Shared value used for P3.
    static let P3 = SIMD2<Double>(1, 0)
}
