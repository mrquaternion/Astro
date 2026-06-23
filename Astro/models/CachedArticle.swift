//
//  CachedArticle.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-21.
//

import Foundation
import SwiftData

@Model
class CachedArticle {
    /// A unique identifier associated with each article.
    @Attribute(.unique) var id: String
    
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
    
    /// The list of launches identifiers associated to the article's content (can be empty).
    var launches: [ArticleLaunch]
    
    /// The list of events identifiers associated to the article's content (can be empty).
    var events: [ArticleEvent]
    
    @Model class ArticleLaunch {
        @Attribute(.unique) var launchId: String

        init(launchId: String) { self.launchId = launchId }
    }
    
    @Model class ArticleEvent {
        @Attribute(.unique) var eventId: String
        
        init(eventId: String) { self.eventId = eventId }
    }
    
    var hasLaunches: Bool { !launches.isEmpty }
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
        self.launches = launches
        self.events = events
    }
}

