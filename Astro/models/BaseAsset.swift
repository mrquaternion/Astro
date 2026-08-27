//
//  BaseAsset.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-08.
//

import Foundation
import SwiftData

@Model
class BaseAsset {
    /// Filename of the asset's 3D model.
    var modelFilename: String
    /// Optional filename of the asset preview image.
    var snapFilename: String?
    /// Remote storage path of the 3D model.
    var modelStoragePath: String
    /// Optional remote storage path of the preview image.
    var snapStoragePath: String?
    /// In-memory preview image data.
    var snapImageData: Data?
    
    init(modelFilename: String, snapFilename: String?, modelStoragePath: String, snapStoragePath: String?) {
        self.modelFilename = modelFilename
        self.snapFilename = snapFilename
        self.modelStoragePath = modelStoragePath
        self.snapStoragePath = snapStoragePath
    }

    /// Local model and preview files shared by asset-based downloads.
    var assetLocalFiles: [LocalFileReference] {
        var files: [LocalFileReference] = [
            .asset(filename: modelFilename)
        ]

        if let snapFilename {
            files.append(.asset(filename: snapFilename))
        }

        return files
    }
}

protocol Downloadable {
    var isDownloadedLocally: Bool { get set }
}

enum LocalDataKind: String, Identifiable {
    case learnAsset
    case trackedAsset
    case webArchive
    
    var id: Self { self }
    
    var menuPage: String {
        switch self {
        case .learnAsset: "tab_learn".localizedFirstCapitalized
        case .trackedAsset: "tab_home".localizedFirstCapitalized
        case .webArchive: "tab_news".localizedFirstCapitalized
        }
    }
    
    var name: String {
        switch self {
        case .learnAsset:
            "downloads_kind_learn".localizedFirstCapitalized
        case .trackedAsset:
            "downloads_kind_satellites".localizedFirstCapitalized
        case .webArchive:
            "downloads_kind_archives".localizedFirstCapitalized
        }
    }
    
    var summary: String {
        "downloads_kind_summary_format".localizedFormat(name, menuPage)
    }
}

protocol LocalDataProviding {
    static var modelKind: LocalDataKind { get }
    var localDataID: String { get }
    var localDataName: String { get }
    var localDataDetail: String? { get }
    var localFiles: [LocalFileReference] { get }
}

extension LocalDataProviding {
    var localDataDetail: String? { nil }
}

enum LocalFileReference {
    case asset(filename: String)
    case webArchive(name: String)
    
    var url: URL? {
        switch self {
        case .asset(let filename):
            AssetLoadingHelpers.getPathOfAssetAsURL(filename: filename)
            
        case .webArchive(let name):
            WebArchiveDataManager().webArchiveURL(named: name)
        }
    }
}

extension LocalDataProviding where Self: BaseAsset {
    var localFiles: [LocalFileReference] {
        assetLocalFiles
    }
}
