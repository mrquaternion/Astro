//
//  ArticleList.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-22.
//

import SwiftUI
import SwiftData

struct ArticleList: View {
    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad
    
    /// Cached articles displayed in the list.
    @Query private var articles: [CachedArticle]
    
    /// Article identifiers whose summaries are expanded on iPhone.
    @State private var expandedArticleIds = Set<String>()
    
    /// Destination of the article to show in WebView.
    @Binding var selectedDestination: ArticleDestination?
    
    let selectedNewsSites: Set<String>
    
    init(
        filter: String,
        sortOrder: SortOrder,
        selectedNewsSites: Set<String>,
        selectedDestination: Binding<ArticleDestination?>
    ) {
        self.selectedNewsSites = selectedNewsSites
        _selectedDestination = selectedDestination
        
        let sortDescriptors: [SortDescriptor<CachedArticle>] = switch sortOrder {
        case .title:
            [SortDescriptor(\CachedArticle.title)]
        case .titleReverse:
            [SortDescriptor(\CachedArticle.title, order: .reverse)]
        case .date:
            [SortDescriptor(\CachedArticle.publishedAt)]
        case .dateReverse:
            [SortDescriptor(\CachedArticle.publishedAt, order: .reverse)]
        }
        
        let predicate = #Predicate<CachedArticle> { article in
            filter.isEmpty ||
            article.title.localizedStandardContains(filter) ||
            article.summary.localizedStandardContains(filter)
        }
        
        _articles = Query(filter: predicate, sort: sortDescriptors)
    }
    
    var filtered: [CachedArticle] {
        articles.filter {
            selectedNewsSites
                .map({ $0.lowercased() })
                .contains($0.websiteName.lowercased())
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
        selectedDestination = ArticleDestination(url: url)
    }
}

#Preview {
    ArticleList(filter: "", sortOrder: .date, selectedNewsSites: Set(), selectedDestination: .constant(.none))
}
