//
//  NewsListView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-22.
//

import SwiftUI
import SwiftUIIntrospect

enum SortOrder: String, Identifiable, CaseIterable {
    case title, titleReverse, date, dateReverse
    
    /// Value used for id.
    var id: Self {
        self
    }
    
    /// Value used for displayName.
    var displayName: String {
        switch self {
        case .title:
            "sort_title_ascending".localizedFirstCapitalized
        case .titleReverse:
            "sort_title_descending".localizedFirstCapitalized
        case .date:
            "sort_oldest_first".localizedFirstCapitalized
        case .dateReverse:
            "sort_newest_first".localizedFirstCapitalized
        }
    }
}

struct NewsListView: View {
    /// Saves and loads space news articles.
    @EnvironmentObject var viewModel: SpaceNewsViewModel
    
    /// Subscription store used to decide whether locked assets can be opened.
    @Environment(SubscriptionManager.self) private var store
    
    /// Tracks offline article download progress while the news list is visible.
    @StateObject private var downloadManager = LocalDownloadManager()

    /// Text used to filter articles from the search field.
    @State private var filter = ""
    
    /// Controls presentation of the paywall for locked news sources.
    @State private var showPaywall = false
    
    /// Controls the presentation of the downloaded articles.
    @State private var showDownloadedArticles = false
    
    /// Articles currently displayed in the news section.
    let articles: [CachedArticle]
    
    /// Destination of the article to show in WebView.
    @Binding var selectedDestination: ArticleDestination?

    /// Reports the UIKit scroll view that backs the news list.
    var onScrollViewResolved: (UIScrollView) -> Void = { _ in }
    
    /// Value used for newsSites.
    var newsSites: Set<String> {
        Set(articles.map(\.websiteName))
    }
    
    /// Value used for sortOrder.
    var sortOrder: SortOrder {
        SortOrder(rawValue: viewModel.storedSortOrder) ?? .dateReverse
    }
    
    /// Value used for selectedNewsSites.
    var selectedNewsSites: Set<String> {
        viewModel.decodeSelectedNewsSites()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                NewsList(
                    articles: articles,
                    filter: filter,
                    sortOrder: sortOrder,
                    selectedNewsSites: selectedNewsSites,
                    showDownloadedOnly: showDownloadedArticles,
                    selectedDestination: $selectedDestination
                )
                .environmentObject(downloadManager)
            }
            .introspect(.scrollView, on: .iOS(.v26), customize: onScrollViewResolved)
            .refreshable {
                await viewModel.loadArticles()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("tab_news".localizedFirstCapitalized)
            .navigationSubtitle("news_navigation_subtitle".localizedFirstCapitalized)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showDownloadedArticles.toggle()
                        } label: {
                            Image(systemName: showDownloadedArticles ? "arrow.down.circle.fill" : "arrow.down.circle")
                                .font(.footnote)
                        }
                        
                        Menu {
                            ForEach(Array(newsSites).sorted(), id: \.self) { site in
                                Toggle(isOn: Binding(
                                    get: { isSelected(site) },
                                    set: { isOn in
                                        let didUpdate = viewModel.setNewsSite(
                                            site,
                                            isSelected: isOn,
                                            selectedNewsSites: selectedNewsSites,
                                            store: store
                                        )
                                        
                                        if !didUpdate {
                                            showPaywall = true
                                        }
                                    }
                                )) {
                                    Text(site)
                                }
                                .menuActionDismissBehavior(.disabled)
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.footnote)
                        }
                        
                        Menu {
                            Picker("common_sort".localizedFirstCapitalized, selection: Binding(
                                get: { sortOrder },
                                set: { viewModel.storedSortOrder = $0.rawValue }
                            )) {
                                ForEach(SortOrder.allCases) { sortOrder in
                                    Text(sortOrder.displayName)
                                        .tag(sortOrder)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.footnote)
                        }
                    }
                    .padding(.horizontal, 6)
                }
            }
        }
        .searchable(
            text: $filter,
            placement: .navigationBarDrawer,
            prompt: Text("news_filter_prompt".localizedFirstCapitalized)
        )
        .fullScreenCover(isPresented: Binding(
            get: { showPaywall || viewModel.showPaywall },
            set: {
                if !$0 {
                    showPaywall = false
                    viewModel.showPaywall = false
                }
            }
        )) {
            Paywall()
                .environment(store)
        }
    }
    
    private func isSelected(_ site: String) -> Bool {
        selectedNewsSites.contains(site)
    }
}
