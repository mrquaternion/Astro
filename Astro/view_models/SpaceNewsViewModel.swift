//
//  SpaceNewsViewModel.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-22.
//

import Foundation
import Combine

@MainActor
final class SpaceNewsViewModel: ObservableObject {
    private let dataController: DataController
    private let subscriptionManager: SubscriptionManager
    private static let selectedNewsSitesKey = "newsListSelectedNewsSites"
    private static let sortOrderKey = "newsListSortOrder"
    
    /// The array of ready-to-use `CachedArticle` in the views.
    @Published var articles: [CachedArticle] = []
    
    /// The current state of articles loading.
    @Published private(set) var areArticlesLoading = false
    
    /// Controls presentation of the paywall for locked satellites.
    @Published var showPaywall = false
    
    /// The error to display on screen.
    @Published var error: Error?
    
    /// Option to sort the articles.
    @Published var storedSortOrder: String {
        didSet {
            UserDefaults.standard.set(storedSortOrder, forKey: Self.sortOrderKey)
        }
    }
    
    /// Multi-selection of news sites.
    @Published var storedSelectedNewsSites: String {
        didSet {
            UserDefaults.standard.set(storedSelectedNewsSites, forKey: Self.selectedNewsSitesKey)
        }
    }
    
    init(dataController: DataController, subscriptionManager: SubscriptionManager) {
        self.dataController = dataController
        self.subscriptionManager = subscriptionManager
        
        self.storedSortOrder = UserDefaults.standard.string(forKey: Self.sortOrderKey) ?? SortOrder.dateReverse.rawValue
        self.storedSelectedNewsSites = UserDefaults.standard.string(forKey: Self.selectedNewsSitesKey) ?? ""
    }
    
    /// Saves the article metadata and its web archive to the model context on-disk (available when user is an active subscriber).
    func saveOffline(for article: CachedArticle, downloadManager: LocalDownloadManager) async throws {
        guard SubscriptionHelper.isEligibleTo(.offlineDownload, with: subscriptionManager) else {
            error = AstroError.noActiveSubscription
            showPaywall = true
            return
        }
        
        guard let url = article.url else {
            throw URLError(.badURL)
        }
        
        try await Task.sleep(for: .seconds(1.5))
        
        let webArchiveManager = WebArchiveDataManager()
        try await webArchiveManager.saveWebArchive(
            from: url,
            withName: article.id,
            onProgress: { progress in
                Task { @MainActor in
                    downloadManager.setProgress(progress, for: article.id)
                }
            }
        )
        let imageData = try? await fetchImageData(from: article.imageUrl)
        
        let savedArticles = try dataController.fetchSaved(CachedArticle.self)
        let savedArticlesById = Dictionary(uniqueKeysWithValues: savedArticles.map { ($0.id, $0) })
        
        if let savedArticle = savedArticlesById[article.id] {
            savedArticle.title = article.title
            savedArticle.summary = article.summary
            savedArticle.url = article.url
            savedArticle.publishedAt = article.publishedAt
            savedArticle.websiteName = article.websiteName
            savedArticle.imageUrl = article.imageUrl
            savedArticle.imageData = imageData
            savedArticle.launches = article.launches
            savedArticle.events = article.events
            savedArticle.isDownloadedLocally = true
            try dataController.saveChanges()
        } else {
            article.isDownloadedLocally = true
            article.imageData = imageData
            try dataController.save(article)
        }
        
        articles = sortedByMostRecent(articles)
        downloadManager.setProgress(1, for: article.id)
        
        try await Task.sleep(for: .seconds(1.5))
    }
    
    /// Loads the articles saved with `SwiftData`.
    func loadArticles() async {
        areArticlesLoading = true
        defer { areArticlesLoading = false }
        
        do {
            articles = sortedByMostRecent(try dataController.fetchSaved(CachedArticle.self))
            
            do {
                articles = sortedByMostRecent(try await fetchArticlesMetadata())
            } catch {
                if articles.isEmpty {
                    throw error
                }
                
                print("Unable to refresh articles, using local cache: \(error)")
            }
        } catch {
            print("Unable to load articles: \(error)")
        }
    }
    
    private func fetchArticlesMetadata() async throws -> [CachedArticle] {
        let collection = try await ArticleFeatureCollection.fetchArticles()
        let cachedArticles = try dataController.fetchSaved(CachedArticle.self)
        let cachedArticlesById = Dictionary(uniqueKeysWithValues: cachedArticles.map { ($0.id, $0) })
        var remoteArticles: [CachedArticle] = []
        var didUpdateCachedArticles = false
        
        for feature in collection.features {
            let p = feature.properties
            
            if let existing = cachedArticlesById[p.id] {
                if update(existing, with: p) {
                    didUpdateCachedArticles = true
                }
                
                remoteArticles.append(existing)
            } else {
                let article = CachedArticle(
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
                
                remoteArticles.append(article)
            }
        }

        if didUpdateCachedArticles {
            try dataController.saveChanges()
        }
        
        return remoteArticles
    }
    
    private func sortedByMostRecent(_ articles: [CachedArticle]) -> [CachedArticle] {
        articles.sorted { $0.publishedAt > $1.publishedAt }
    }
    
    private func fetchImageData(from url: URL?) async throws -> Data? {
        guard let url else { return nil }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard
            let httpResponse = response as? HTTPURLResponse,
            200..<300 ~= httpResponse.statusCode
        else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
    
    @discardableResult
    private func update(_ article: CachedArticle, with properties: ArticleFeatureCollection.Feature.Properties) -> Bool {
        let url = URL(string: properties.urlString)
        let imageUrl = URL(string: properties.imageUrlString)
        let launchIds = properties.launches.compactMap(\.self)
        let eventIds = properties.events.compactMap(\.self)
        
        let hasChanges =
        article.title != properties.title ||
        article.summary != properties.summary ||
        article.url != url ||
        article.publishedAt != properties.publishedAt ||
        article.websiteName != properties.websiteName ||
        article.imageUrl != imageUrl ||
        article.launches.map(\.launchId) != launchIds ||
        article.events.map(\.eventId) != eventIds
        
        guard hasChanges else { return false }
        
        article.title = properties.title
        article.summary = properties.summary
        article.url = url
        article.publishedAt = properties.publishedAt
        article.websiteName = properties.websiteName
        article.imageUrl = imageUrl
        article.launches = launchIds.map { .init(launchId: $0) }
        article.events = eventIds.map { .init(eventId: $0) }
        
        return true
    }
    
    /// Loads the user's selected news sites from the app's storage.
    func decodeSelectedNewsSites() -> Set<String> {
        guard
            let data = storedSelectedNewsSites.data(using: .utf8),
            let sites = try? JSONDecoder().decode([String].self, from: data)
        else {
            return ["NASA"]
        }
        
        let selectedSites = Set(sites)
        return selectedSites.isEmpty ? ["NASA"] : selectedSites
    }
    
    /// Stores the selected news sites by the user inside the app's storage.
    func storeSelectedNewsSites(_ sites: Set<String>) {
        let sortedSites = Array(sites).sorted()
        
        guard !sortedSites.isEmpty else { return }
        
        guard
            let data = try? JSONEncoder().encode(sortedSites),
            let json = String(data: data, encoding: .utf8)
        else {
            return
        }
        
        storedSelectedNewsSites = json
    }
    
    /// Updates the selected news sites when the user has access to the requested source.
    @discardableResult
    func setNewsSite(
        _ site: String,
        isSelected: Bool,
        selectedNewsSites: Set<String>,
        store: SubscriptionManager
    ) -> Bool {
        var updatedSites = selectedNewsSites
        
        if
            isSelected,
            !SubscriptionHelper.isEligibleTo(.newsSource(site), with: store)
        {
            return false
        }
        
        if isSelected {
            updatedSites.insert(site)
        } else {
            updatedSites.remove(site)
        }
        
        if !updatedSites.isEmpty {
            storeSelectedNewsSites(updatedSites)
        }
        
        return true
    }
}
