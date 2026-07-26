//
//  CachedTrackedAsset.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-03.
//

import Foundation
import SwiftData

@available(iOS 26, *)
@Model
class CachedTrackedAsset: BaseAsset, LocalDataProviding, Downloadable {
    /// A unique identifier associated with each 3D model.
    @Attribute(.unique) var id: String
    
    /// The model type for easy identification.
    static var modelKind: LocalDataKind { .trackedAsset }

    /// Stable identity used by download settings.
    var localDataID: String { id }

    /// User-facing name used by download settings.
    var localDataName: String { displayName }

    /// Model, preview, and orbital data files belonging to the download.
    var localFiles: [LocalFileReference] {
        guard isDownloadedLocally else { return [] }
        return assetLocalFiles + [.asset(filename: tleFilename)]
    }
    
    /// The given name of the asset.
    var displayName: String
    
    /// The short description of the asset.
    var summary: String
    
    /// The filename of the asset's TLE.
    var tleFilename: String
    
    /// The path of the TLE record in Storage.
    var tleStoragePath: String
    
    /// The time at which the asset was updated in Storage.
    var updatedAt: Date
    
    /// The time at which the asset was lastly accessed locally.
    var lastAccessedAt: Date
    
    /// The state of the download status of the asset.
    var isDownloadedLocally: Bool
    
    /// Creates a new model from the specified values.
    init(
        id: String,
        name: String,
        summary: String,
        modelFileName: String,
        tleFileName: String,
        snapFileName: String?,
        modelStoragePath: String,
        tleStoragePath: String,
        snapStoragePath: String?,
        updatedAt: Date
    ) {
        self.id = id
        self.displayName = name
        self.summary = summary
        self.tleFilename = tleFileName
        self.tleStoragePath = tleStoragePath
        self.updatedAt = updatedAt
        self.lastAccessedAt = .now
        self.isDownloadedLocally = false
        
        super.init(
            modelFilename: modelFileName,
            snapFilename: snapFileName,
            modelStoragePath: modelStoragePath,
            snapStoragePath: snapStoragePath
        )
    }
}
