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
    
    private let filter: String
    private let sortOrder: SortOrder
    private let showDownloadedOnly: Bool
    
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
        articles: [],
        filter: "",
        sortOrder: .date,
        selectedNewsSites: Set(),
        showDownloadedOnly: false,
        selectedDestination: .constant(.none)
    )
}
