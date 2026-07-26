//
//  CachedArticle.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-21.
//

import Foundation
import SwiftData

@Model
class CachedArticle: LocalDataProviding, Downloadable {
    /// A unique identifier associated with each article.
    @Attribute(.unique) var id: String
    
    /// The model type for easy identification.
    static var modelKind: LocalDataKind { .webArchive }

    /// Stable identity used by download settings.
    var localDataID: String { id }

    /// Website name used for the individual download row.
    var localDataName: String { websiteName }

    /// Article title shown below the website name.
    var localDataDetail: String? { title }
    
    var localFiles: [LocalFileReference] {
        guard isDownloadedLocally else { return [] }
        return [.webArchive(name: id)]
    }
    
    /// The title of the article.
    var title: String
    
    /// The short summary of the article's content.
    var summary: String
    
    /// The URL of the article.
    var url: URL?
    
    /// The time at which the article was published.
    var publishedAt: Date
    
    /// The name of the article's news site.
    var websiteName: String
    
    /// The URL of the article's frontpage image.
    var imageUrl: URL?
    
    /// The article's frontpage image data saved for offline display.
    var imageData: Data?
    
    /// The list of launches identifiers associated to the article's content (can be empty).
    var launches: [ArticleLaunch]
    
    /// The list of events identifiers associated to the article's content (can be empty).
    var events: [ArticleEvent]
    
    /// Whether the article web archive is available locally.
    var isDownloadedLocally: Bool = false
    
    @Model class ArticleLaunch {
        /// Stable identifier of the launch referenced by an article.
        @Attribute(.unique) var launchId: String
        
        init(launchId: String) { self.launchId = launchId }
    }
    
    @Model class ArticleEvent {
        /// Stable identifier of the event referenced by an article.
        @Attribute(.unique) var eventId: String
        
        init(eventId: String) { self.eventId = eventId }
    }
    
    /// Whether the article references at least one launch.
    var hasLaunches: Bool { !launches.isEmpty }
    /// Whether the article references at least one event.
    var hasEvents: Bool { !events.isEmpty }
    
    init(
        id: String,
        title: String,
        summary: String,
        urlString: String,
        publishedAt: Date,
        websiteName: String,
        imageUrlString: String,
        launches: [ArticleLaunch],
        events: [ArticleEvent]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.url = URL(string: urlString)
        self.publishedAt = publishedAt
        self.websiteName = websiteName
        self.imageUrl = URL(string: imageUrlString)
        self.imageData = nil
        self.launches = launches
        self.events = events
        self.isDownloadedLocally = false
    }
}
