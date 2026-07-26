//
//  NewsList.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-22.
//

import SwiftUI

struct NewsList: View {
    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad

    /// Cached articles displayed in the list.
    let articles: [CachedArticle]
    
    /// Article identifiers whose summaries are expanded on iPhone.
    @State private var expandedArticleIds = Set<String>()
    
    /// Destination of the article to show in WebView.
    @Binding var selectedDestination: ArticleDestination?
    
    /// Value used for selectedNewsSites.
    let selectedNewsSites: Set<String>

    init(
        articles: [CachedArticle],
        filter: String,
        sortOrder: SortOrder,
        selectedNewsSites: Set<String>,
        showDownloadedOnly: Bool,
        selectedDestination: Binding<ArticleDestination?>
    ) {
        self.articles = articles
        self.selectedNewsSites = selectedNewsSites
        _selectedDestination = selectedDestination
        self.filter = filter
        self.sortOrder = sortOrder
        self.showDownloadedOnly = showDownloadedOnly
    }
    
    /// Value used for filter.
    private let filter: String
    /// Value used for sortOrder.
    private let sortOrder: SortOrder
    /// Value used for showDownloadedOnly.
    private let showDownloadedOnly: Bool
    
    /// Value used for filtered.
    var filtered: [CachedArticle] {
        let matchingArticles = articles.filter { article in
            let matchesFilter =
            filter.isEmpty ||
            article.title.localizedStandardContains(filter) ||
            article.summary.localizedStandardContains(filter)
            
            let matchesSite = selectedNewsSites
                .map({ $0.lowercased() })
                .contains(article.websiteName.lowercased())
            
            let matchesDownloadState = !showDownloadedOnly || article.isDownloadedLocally
            
            return matchesFilter && matchesSite && matchesDownloadState
        }
        
        return matchingArticles.sorted {
            switch sortOrder {
            case .title:
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            case .titleReverse:
                $0.title.localizedStandardCompare($1.title) == .orderedDescending
            case .date:
                $0.publishedAt < $1.publishedAt
            case .dateReverse:
                $0.publishedAt > $1.publishedAt
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            LazyVStack(spacing: 20) {
                ForEach(filtered) { article in
                    ArticleCard(
                        article: article,
                        isExpanded: isSummaryExpanded(for: article),
                        onToggleSummary: {
                            toggleSummary(for: article)
                        },
                        onOpen: {
                            openArticle(article)
                        }
                    )
                }
            }
            .padding(.horizontal, isPad ? 28 : 16)
            .padding(.bottom, CustomTabBarLayout.height + CustomTabBarLayout.yOffset)
        }
    }
    
    private func isSummaryExpanded(for article: CachedArticle) -> Bool {
        expandedArticleIds.contains(article.id)
    }
    
    private func toggleSummary(for article: CachedArticle) {
        if isSummaryExpanded(for: article) {
            expandedArticleIds.remove(article.id)
        } else {
            expandedArticleIds.insert(article.id)
        }
    }
    
    private func openArticle(_ article: CachedArticle) {
        guard let url = article.url else { return }
        selectedDestination = ArticleDestination(
            id: article.id,
            url: url,
            isDownloadedLocally: article.isDownloadedLocally
        )
    }
}

#Preview {
    NewsList(
        articles: [CachedArticle.mock],
        filter: "",
        sortOrder: .date,
        selectedNewsSites: ["NASA"],
        showDownloadedOnly: false,
        selectedDestination: .constant(.none)
    )
    .environmentObject(LocalDownloadManager())
}

extension CachedArticle {
    /// Shared value used for mock.
    static var mock: CachedArticle {
        CachedArticle(
            id: "1",
            title: "NASA Scientists Take to Air and Space to Study Arctic Sea ice",
            summary: "This month, engineers at NASA’s Jet Propulsion Laboratory in Southern California are testing a spacecraft sensor that will help measure how quickly Arctic sea ice is disappearing. And while that instrument won’t launch for another year, scientists started preparing for its use during a recent field campaign in the Canadian wilderness. Researchers spent two weeks […]",
            urlString: "https://www.nasa.gov/missions/airborne-science/nasa-scientists-take-to-air-and-space-to-study-arctic-sea-ice/",
            publishedAt: .now,
            websiteName: "NASA",
            imageUrlString: "https://www.nasa.gov/wp-content/uploads/2026/07/1-sea-ice-quadriptych.jpg",
            launches: [],
            events: []
        )
    }
}
