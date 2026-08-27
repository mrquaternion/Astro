//
//  CachedLearnAsset.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-08.
//

import Foundation
import SwiftData

@Model
class CachedLearnAsset: LocalDataProviding, Downloadable {
    /// A unique identifier associated with each 3D model.
    @Attribute(.unique) var id: String

    /// The model type for easy identification.
    static var modelKind: LocalDataKind { .learnAsset }

    /// Stable identity used by download settings.
    var localDataID: String { id }

    /// The parent asset name used throughout the Learn interface.
    var localDataName: String { defaultComponent.displayName }

    /// Number of unique components included in this Learn download.
    var localDataDetail: String? {
        let count = uniqueComponents.count
        let key = count == 1 ? "component_count_singular" : "component_count_plural"
        return key.localizedFormat(count)
    }

    /// Combined local files for every component in this Learn asset.
    var localFiles: [LocalFileReference] {
        guard isDownloadedLocally else { return [] }
        return uniqueComponents.flatMap(\.assetLocalFiles)
    }

    /// The component, by default, of the asset.
    var defaultComponent: LearnComponent
    
    /// The list of the asset's components.
    var components: [LearnComponent]
    
    /// The time at which the asset was updated in Storage.
    var updatedAt: Date
    
    /// The time at which the asset was lastly accessed locally.
    var lastAccessedAt: Date
    
    /// The state of the download status of the asset.
    var isDownloadedLocally: Bool

    /// Components belonging to the asset, without duplicating the default component.
    private var uniqueComponents: [LearnComponent] {
        var seenComponentIDs = Set<String>()
        return ([defaultComponent] + components).filter {
            seenComponentIDs.insert($0.componentId).inserted
        }
    }
    
    init(
        id: String,
        defaultComponent: LearnComponent,
        components: [LearnComponent],
        updatedAt: Date
    ) {
        self.id = id
        self.defaultComponent = defaultComponent
        self.components = components
        self.updatedAt = updatedAt
        self.lastAccessedAt = .now
        self.isDownloadedLocally = false
    }
    
    @available(iOS 26, *)
    @Model class LearnComponent: BaseAsset {
        /// A stable identifier associated with this component.
        @Attribute(.unique) var componentId: String
        
        /// The abbreviated name commonly used for this component.
        var shortName: String?
        
        /// The full display name shown to users.
        var displayName: String
        
        /// The functional category of the component.
        var category: String
        
        /// The larger station area or system group this component belongs to.
        var group: String?
        
        /// The agencies associated with this component.
        var agencies: [String]
        
        /// The organizations or manufacturers that built this component.
        var manufacturers: [String]
        
        /// The primary materials or systems that make up this component.
        var materials: [String]
        
        /// The chronological events associated with this component.
        var timeline: [LearnComponentTimelineEvent]
        
        /// The detailed sections associated with this component.
        var details: [LearnComponentDetail]
        
        /// A short overview of the component's purpose and role.
        var summary: String
        
        /// The identifiers of the sources used for this component's information.
        var sourceIds: [String]
        
        init(
            componentId: String,
            modelFilename: String,
            snapFilename: String?,
            modelStoragePath: String,
            snapStoragePath: String?,
            shortName: String? = nil,
            displayName: String,
            category: String,
            group: String? = nil,
            agencies: [String],
            manufacturers: [String],
            materials: [String],
            timeline: [LearnComponentTimelineEvent],
            details: [LearnComponentDetail],
            summary: String,
            sourceIds: [String]
        ) {
            self.componentId = componentId
            self.shortName = shortName
            self.displayName = displayName
            self.category = category
            self.group = group
            self.agencies = agencies
            self.manufacturers = manufacturers
            self.materials = materials
            self.timeline = timeline
            self.details = details
            self.summary = summary
            self.sourceIds = sourceIds
            
            super.init(
                modelFilename: modelFilename,
                snapFilename: snapFilename,
                modelStoragePath: modelStoragePath,
                snapStoragePath: snapStoragePath
            )
        }
    }
    
    @Model class LearnComponentTimelineEvent {
        /// The date on which the timeline event occurred.
        var date: Date
        
        /// The user-facing description of the timeline event.
        var event: String
        
        init(date: Date, event: String) {
            self.date = date
            self.event = event
        }
    }
    
    @Model class LearnComponentDetail {
        /// The title of the detailed information section.
        var title: String
        
        /// The body text of the detailed information section.
        var body: String
        
        init(title: String, body: String) {
            self.title = title
            self.body = body
        }
    }
}
