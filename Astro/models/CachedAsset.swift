//
//  CachedAsset.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-03.
//

import Foundation
import SwiftData

/// A representation of a 3D model.
@Model
class CachedAsset {
    /// A unique identifier associated with each 3D model.
    @Attribute(.unique) var id: String
    
    /// The given name of the asset.
    var name: String
    
    /// The short description of the asset.
    var summary: String
    
    /// The file name of the asset.
    var modelFileName: String
    
    /// The filename of the asset's TLE.
    var tleFileName: String
    
    /// The filename of the asset's image snapshot.
    var snapFileName: String?
    
    /// The path of the asset in Storage.
    var modelStoragePath: String
    
    /// The path of the TLE record in Storage.
    var tleStoragePath: String
    
    /// The path of the snapshot image in Storage.
    var snapStoragePath: String?
    
    /// The snapshot image's data.
    var snapImageData: Data?
    
    /// The time at which the asset was updated in Storage.
    var updatedAt: Date
    
    /// The time at which the asset was lastly accessed locally.
    var lastAccessedAt: Date
    
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
        self.name = name
        self.summary = summary
        self.modelFileName = modelFileName
        self.tleFileName = tleFileName
        self.snapFileName = snapFileName
        self.modelStoragePath = modelStoragePath
        self.tleStoragePath = tleStoragePath
        self.snapStoragePath = snapStoragePath
        self.updatedAt = updatedAt
        self.lastAccessedAt = .now
    }
}
