//
//  Launch3DEventView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-17.
//

import SwiftUI
@_spi(Experimental) import MapboxMaps
import Charts

struct Launch3DEventView: View {
    /// Mutable view state tracking rocket.
    @State private var rocket = Rocket()
    /// Mutable view state tracking flightRoute.
    @State private var flightRoute: FlightRoute?
    /// Mutable view state tracking animationPhase.
    @State private var animationPhase: Double = 0
    /// Mutable view state tracking displayLink.
    @State private var displayLink: DisplayLink?
    /// Mutable view state tracking openChart.
    @State private var openChart = false
    
    /// Value used for animationDuration.
    private var animationDuration: TimeInterval = 600000.0
    
    /// DEBUG
    @State private var debugTimestamp: Double?
    /// Mutable view state tracking elapsedTime.
    @State private var elapsedTime: TimeInterval = 0
    
    /// DEBUG
    private var debugTimestampFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
    
    /// Value used for chartData.
    var chartData: [TrajectoryChartData]? {
        guard let flightRoute, flightRoute.distances.count == flightRoute.elevation.count else { return nil }

        var data: [TrajectoryChartData] = []
        for i in 0..<flightRoute.elevation.count {
            data.append(TrajectoryChartData(
                distance: flightRoute.distances[i] / 1000,
                value: flightRoute.elevation[i] / 1000
            ))
        }

        return data
    }

    /// Value used for data.
    var data: [LocationCoordinate2D] {
        flightRoute?.coordinates.map {
            CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
        } ?? []
    }

    var body: some View {
        MapReader { mapProxy in
            Map {
                GeoJSONSource(id: Constants.flightPathSourceId)
                    .data(.geometry(.lineString(LineString(data))))
                LineLayer(id: "flight-path-line", source: Constants.flightPathSourceId)
                    .lineColor(.init(UIColor(red: 0, green: 124/255, blue: 191/255, alpha: 1)))
                    .lineWidth(8.0)
                    .lineEmissiveStrength(1.0)
                    .lineCap(.round)
                    .lineJoin(.round)

                ModelSource(id: Constants.modelsSourceId)
                    .models([createAirplaneModel()])
                ModelLayer(id: "3d-model-layer", source: Constants.modelsSourceId)
                    .modelType(.common3d)
                    .modelTranslation(
                        Exp(arguments:
                            [.number(0), .number(0), .stringArray(["feature-state", "z-elevation"])]
                        )
                    )
                    .modelRotation(x: 0, y: 0, z: 180)
                
                Atmosphere()
                    .verticalRange(start: 0, end: 400000)
                
                Terrain(sourceId: "terrain-dem")
                    .exaggeration(1.5)
                
                RasterDemSource(id: "terrain-dem")
                    .url("mapbox://mapbox.mapbox-terrain-dem-v1")
            }
            .debugOptions([.modelBounds, .camera])
            .ornamentOptions(OrnamentOptions(scaleBar: .init(visibility: .hidden)))
            .mapStyle(.standard(lightPreset: .dusk, showPointOfInterestLabels: false, showTransitLabels: false, showPlaceLabels: false, showRoadLabels: false, showPedestrianRoads: false))
            .onStyleLoaded { _ in
                startAnimation(mapProxy: mapProxy)
            }
            .task { flightRoute = loadFlightRoute() }
            .onDisappear { displayLink = nil }
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                HStack(spacing: 16) {
                    Button {
                        openChart = true
                    } label: {
                        Text("Trajectory")
                            .font(.footnote)
                    }
                    .buttonStyle(.glass)
                    .frame(maxWidth: .infinity, alignment: .leading)
                 
                    // for debugging
                    if let debugTimestamp {
                        Text(formattedElapsed(debugTimestamp))
                            .font(.footnote)
                            .fontDesign(.monospaced)
                            .monospacedDigit()
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .glassEffect(.regular, in: .capsule)
                    }
                    
                    VStack { }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal)
            }
            .sheet(isPresented: $openChart) {
                TrajectoryChart(data: chartData)
                    .padding(24)
                    .presentationDetents([.medium])
            }
        }
    }
    
    // for debugging
    private func formattedElapsed(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        let millis = Int((seconds - Double(totalSeconds)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, secs, millis)
    }

    private func createAirplaneModel() -> Model {
        let model = Model(
            id: Constants.rocketModelKey,
            uri: URL(string: Constants.rocketModelUri)!,
            position: rocket.position,
            orientation: [rocket.roll, rocket.pitch, rocket.bearing + 90.0]
        )
        print("(MDL-POS)", debugTimestampFormatter.string(from: Date()), "– Position:", rocket.position)
        return model
    }

    private func startAnimation(mapProxy: MapProxy) {
        guard let map = mapProxy.map else { return }
        
        displayLink = DisplayLink { deltaTime in
            guard let route = flightRoute else { return }

            animationPhase += deltaTime / animationDuration
            elapsedTime += deltaTime // for debugging
            
            if animationPhase > 1.0 {
                animationPhase = 0.0
            }

            if let target = route.sample(distance: route.totalLength * animationPhase) {
                rocket = rocket.update(target: target, dtimeMs: deltaTime * 1000.0)

                print("(OBJ)", debugTimestampFormatter.string(from: Date()), "– Rocket altitude: \(rocket.altitude), rocket position: \(rocket.position.description)")
                updateFeatureState(map: map)
                updateCamera(map: map)
                print("\n")
                
                // for debugging
                debugTimestamp = elapsedTime
            }
        }
    }

    private func updateFeatureState(map: MapboxMap) {
        map.setFeatureState(
            sourceId: Constants.modelsSourceId,
            sourceLayerId: nil,
            featureId: Constants.rocketModelKey,
            state: ["z-elevation": rocket.altitude],
            callback: { _ in
                map.getFeatureState(
                    sourceId: Constants.modelsSourceId,
                    sourceLayerId: nil,
                    featureId: Constants.rocketModelKey) { result in
                        switch result {
                        case .success(let success):
                            print("(MDL-ALT)", debugTimestampFormatter.string(from: Date()), "– Feature state:", success)
                        case .failure(let failure):
                            print("(MDL) getFeatureState error:", failure)
                        }
                    }
            }
        )
    }

    private func updateCamera(map: MapboxMap) {
        let lat = rocket.position[1]
        let lng = rocket.position[0]
        let alt = rocket.altitude

        let rocketPosition = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let cameraPosition = CLLocationCoordinate2D(latitude: lat - 0.001, longitude: lng)
        let cameraAltitude = rocket.altitude + 200

        let freeCameraOptions = map.freeCameraOptions
        freeCameraOptions.setLocationForLocation(
            cameraPosition,
            altitude: cameraAltitude
        )

        freeCameraOptions.lookAtPoint(
            forLocation: rocketPosition,
            altitude: alt
        )

        map.freeCameraOptions = freeCameraOptions
        
        print("(CAM)", debugTimestampFormatter.string(from: Date()), "– Camera altitude: \(cameraAltitude), camera position:", [cameraPosition.longitude, cameraPosition.latitude])
    }

    private func loadFlightRoute() -> FlightRoute? {

        let simulator = RocketFligthPathSimulation(maxAltitude: 400_000, shouldGoBackDown: true)
        simulator.simulate(
            from: TrajectoryPoint(
                coordinate: CLLocationCoordinate2D(latitude: 28.43942, longitude: -80.573301),
                altitude: 3
            ),
            to: TrajectoryPoint(
                coordinate: CLLocationCoordinate2D(latitude: 37.3425, longitude: -132.4486),
                altitude: 0
            )
        )

        guard simulator.trajectory != nil, let trajectory = simulator.trajectory else { return nil }

        let coordinates: [[Double]] = trajectory.map { [$0.coordinate.longitude, $0.coordinate.latitude] }
        let elevation: [Double] = trajectory.map { $0.altitude }

        return FlightRoute(coordinates: coordinates, elevation: elevation)
    }

    static func clamp(_ value: Double) -> Double {
        max(0.0, min(value, 1.0))
    }

    static func mix(_ a: Double, _ b: Double, _ t: Double) -> Double {
        let f = clamp(t)
        return a * (1 - f) + b * f
    }
}

#Preview {
    Launch3DEventView()
}

private struct Rocket {
    /// Value used for position.
    var position: [Double] = [-80.573301, 28.43942]
    /// Value used for altitude.
    var altitude: Double = 0.0
    /// Value used for bearing.
    var bearing: Double = -60.0
    /// Value used for pitch.
    var pitch: Double = 0.0
    /// Value used for roll.
    var roll: Double = 0.0
    /// Value used for animTimeS.
    var animTimeS: Double = 0.0

    func update(target: RoutePoint, dtimeMs: Double) -> Rocket {
        let newAnimTimeS = animTimeS + dtimeMs / 1000.0
        return Rocket(
            position: [
                Launch3DEventView.mix(position[0], target.position[0], dtimeMs * 0.05),
                Launch3DEventView.mix(position[1], target.position[1], dtimeMs * 0.05)
            ],
            altitude: Launch3DEventView.mix(altitude, target.altitude, dtimeMs * 0.05),
            bearing: bearing,
            pitch: pitch,
            roll: 0.0,
            animTimeS: newAnimTimeS
        )
    }

    private func animSinPhaseFromTime(_ animTimeS: Double, _ phaseLen: Double) -> Double {
        return sin(((animTimeS.truncatingRemainder(dividingBy: phaseLen)) / phaseLen) * .pi * 2.0) * 0.5 + 0.5
    }
}

private struct RoutePoint {
    /// Value used for position.
    let position: [Double]
    /// Value used for altitude.
    let altitude: Double
    /// Value used for bearing.
    let bearing: Double
    /// Value used for pitch.
    let pitch: Double
}

private struct FlightRoute {
    /// Value used for coordinates.
    let coordinates: [[Double]]
    /// Value used for elevation.
    let elevation: [Double]
    /// Value used for distances.
    let distances: [Double]
    /// Value used for maxElevation.
    let maxElevation: Double

    /// Value used for totalLength.
    var totalLength: Double {
        distances.last ?? 0.0
    }

    init(coordinates: [[Double]], elevation: [Double]) {
        self.coordinates = coordinates
        self.elevation = elevation

        var distances: [Double] = [0.0]
        var maxElevation = elevation[0]

        for i in 1..<coordinates.count {
            let p1 = coordinates[i - 1]
            let p2 = coordinates[i]

            let dlat = p2[1] - p1[1]
            let dlng = p2[0] - p1[0]
            let segmentDistance = sqrt(dlat * dlat + dlng * dlng) * 111000.0 // rough conversion to meters

            distances.append(distances[i - 1] + segmentDistance)
            maxElevation = max(maxElevation, elevation[i])
        }

        self.distances = distances
        self.maxElevation = maxElevation
    }

    func sample(distance: Double) -> RoutePoint? {
        guard !distances.isEmpty else { return nil }

        var segmentIndex = distances.firstIndex { $0 >= distance } ?? 0
        segmentIndex = max(0, segmentIndex - 1)
        segmentIndex = min(coordinates.count - 2, segmentIndex)

        let p1 = coordinates[segmentIndex]
        let p2 = coordinates[segmentIndex + 1]
        let segmentLength = distances[segmentIndex + 1] - distances[segmentIndex]
        let segmentRatio = (distance - distances[segmentIndex]) / segmentLength

        let e1 = elevation[segmentIndex]
        let e2 = elevation[segmentIndex + 1]
        let altitude = e1 + (e2 - e1) * segmentRatio

        let bearing = atan2(p2[0] - p1[0], p2[1] - p1[1]) * 180.0 / .pi
        let pitch = atan2(e2 - e1, segmentLength) * 180.0 / .pi

        return RoutePoint(
            position: [
                p1[0] + (p2[0] - p1[0]) * segmentRatio,
                p1[1] + (p2[1] - p1[1]) * segmentRatio
            ],
            altitude: altitude,
            bearing: bearing,
            pitch: pitch
        )
    }
}

private class DisplayLink {
    /// Value used for displayLink.
    private var displayLink: CADisplayLink?
    /// Value used for callback.
    private var callback: (Double) -> Void
    /// Value used for lastTimestamp.
    private var lastTimestamp: CFTimeInterval = 0

    private class WeakProxy {
        weak var target: DisplayLink?

        init(target: DisplayLink) {
            self.target = target
        }

        @objc func frame(displayLink: CADisplayLink) {
            target?.frame(displayLink: displayLink)
        }
    }

    init(callback: @escaping (Double) -> Void) {
        self.callback = callback
        let proxy = WeakProxy(target: self)
        self.displayLink = CADisplayLink(target: proxy, selector: #selector(WeakProxy.frame(displayLink:)))
        self.displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func frame(displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
        }

        let deltaTime = displayLink.timestamp - lastTimestamp
        lastTimestamp = displayLink.timestamp

        callback(deltaTime)
    }

    deinit {
        displayLink?.invalidate()
    }
}

private enum Constants {
    /// Shared value used for flightPathJsonUri.
    static let flightPathJsonUri = "https://docs.mapbox.com/mapbox-gl-js/assets/flightpath.json"
    /// Shared value used for flightPathSourceId.
    static let flightPathSourceId = "flightpath"
    /// Shared value used for rocketModelUri.
    static let rocketModelUri = "https://bxmogibkelbcnqaupgob.supabase.co/storage/v1/object/public/glbs/rockets/falcon_heavy-spacex.glb"
    /// Shared value used for modelsSourceId.
    static let modelsSourceId = "rocket-model-source"
    /// Shared value used for rocketModelKey.
    static let rocketModelKey = "rocket"
    /// Shared value used for modelIdKey.
    static let modelIdKey = "model-id-key"

    /// Shared value used for flightTravelAltitudeMin.
    static let flightTravelAltitudeMin: Double = 0.0
    /// Shared value used for flightTravelAltitudeMax.
    static let flightTravelAltitudeMax: Double = 400_000.0
}
