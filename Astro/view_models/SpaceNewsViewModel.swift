//
//  SpaceNewsViewModel.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-22.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class SpaceNewsViewModel: ObservableObject {
    
    /// The current state of articles loading.
    @Published private(set) var areArticlesLoading = false
    
    init() { }
    
    func loadArticles(modelContext: ModelContext) async {
        areArticlesLoading = true
        defer { areArticlesLoading = false }
        
        do {
            try await fetchAndCacheArticlesMetadata(context: modelContext)
        } catch {
            print("Unable to load articles: \(error)")
        }
    }
    
    private func fetchAndCacheArticlesMetadata(context: ModelContext) async throws {
        let collection = try await ArticleFeatureCollection.fetchArticles()
        let cachedArticles = try context.fetch(FetchDescriptor<CachedArticle>())
        let cachedAssetsById = Dictionary(uniqueKeysWithValues: cachedArticles.map { ($0.id, $0) })
        let remoteIds = Set(collection.features.map(\.properties.id))
        
        for feature in collection.features {
            let p = feature.properties
            let existing = cachedAssetsById[p.id]
            
            if existing == nil {
                let a = CachedArticle(
                    id: p.id,
                    title: p.title,
                    summary: p.summary,
                    urlString: p.urlString,
                    publishedAt: p.publishedAt,
                    websiteName: p.websiteName,
                    imageUrlString: p.imageUrlString,
                    launches: p.launches.compactMap({ launchId in
                        launchId.map({ .init(launchId: $0) })
                    }),
                    events: p.events.compactMap({ eventId in
                        eventId.map({ .init(eventId: $0) })
                    })
                )
                
                context.insert(a)
            }
        }
        
        for article in cachedArticles where !remoteIds.contains(article.id) {
            context.delete(article)
        }
        
        try context.save()
    }
}
