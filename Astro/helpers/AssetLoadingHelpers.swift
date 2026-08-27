//
//  AssetLoadingHelpers.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-25.
//

import Foundation
import SatelliteKit

class AssetLoadingHelpers {
    static func parseStoragePath(_ path: String?) -> (filepath: String, bucket: String)? {
        guard let pathParts = path?.split(separator: "%").map(String.init),
              pathParts.count == 2 else {
            return nil
        }
        return (filepath: pathParts[1], bucket: pathParts[0])
    }
    
    static func computeDataUri(data: Data, id: String) throws -> String {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MapboxModels", isDirectory: true)
        
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        
        let url = directory.appendingPathComponent("\(id).glb")
        try data.write(to: url, options: .atomic)
        return url.absoluteString
    }
    
    static func computeRoute(elements: Elements) throws -> Model3DRoute {
        let satellite = Satellite(elements: elements)
        var coordinates: [[Double]] = []
        var elevations: [Double] = []
        let startMinutesAfterEpoch = ScreenshotMode.isEnabled
            ? ScreenshotMode.satelliteMinutesAfterEpoch
            : satellite.minsAfterEpoch
        
        let period = Int(2 * .pi / elements.n₀)
        for timeOffset in 0..<(period + 1) {
            let lla = try satellite.geoPosition(minsAfterEpoch: startMinutesAfterEpoch + Double(timeOffset))
            let fixedLng = lla.lon > 180 ? lla.lon - 360 : lla.lon
            coordinates.append([fixedLng, lla.lat])
            elevations.append(lla.alt)
        }
        
        return Model3DRoute(coordinates: coordinates, elevations: elevations)
    }
    
    static func getPathOfAssetAsURL(filename: String) -> URL? {
        guard
            let path = FileManager
                .default
                .urls(for: .cachesDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("\(filename)")
        else {
            print("Error saving path after asset download.")
            return nil
        }
        return path
    }
    
    static func decodeTLE(data: Data) throws -> Elements {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Micros)
        
        let elements = try jsonDecoder.decode([Elements].self, from: data)
        return elements[0]
    }
}
