//
//  NewsListView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-22.
//

import SwiftUI
import SwiftData

enum SortOrder: String, Identifiable, CaseIterable {
    case title, titleReverse, date, dateReverse
    
    var id: Self {
        self
    }
    
    var displayName: String {
        switch self {
        case .title:
            "Title (A-Z)"
        case .titleReverse:
            "Title (Z-A)"
        case .date:
            "Oldest first"
        case .dateReverse:
            "Newest first"
        }
    }
}

struct NewsListView: View {
    private static let selectedNewsSitesKey = "newsListSelectedNewsSites"
    private static let sortOrderKey = "newsListSortOrder"
    
    /// The SwiftData context used during app bootstrap.
    @Environment(\.modelContext) private var modelContext
    
    /// Saves and loads space news articles.
    @EnvironmentObject var viewModel: SpaceNewsViewModel
    
    /// Cached articles displayed in the list.
    @Query private var articles: [CachedArticle]
    
    /// Text used to filter articles from the search field.
    @State private var filter = ""
    
    /// Option to sort the articles.
    @AppStorage(Self.sortOrderKey) private var storedSortOrder = SortOrder.dateReverse.rawValue
    
    /// Multi-selection of news sites.
    @AppStorage(Self.selectedNewsSitesKey) private var storedSelectedNewsSites = ""
    
    /// Destination of the article to show in WebView.
    @Binding var selectedDestination: ArticleDestination?
    
    var newsSites: Set<String> {
        Set(articles.map { $0.websiteName })
    }
    
    var sortOrder: SortOrder {
        SortOrder(rawValue: storedSortOrder) ?? .dateReverse
    }
    
    var selectedNewsSites: Set<String> {
        decodeSelectedNewsSites()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ArticleList(
                    filter: filter,
                    sortOrder: sortOrder,
                    selectedNewsSites: selectedNewsSites,
                    selectedDestination: $selectedDestination
                )
            }
            .refreshable {
                await viewModel.loadArticles(modelContext: modelContext)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("News")
            .navigationSubtitle("Recent space-related news across the globe")
            .toolbar {
                Menu {
                    ForEach(Array(newsSites).sorted(), id: \.self) { site in
                        Toggle(isOn: Binding(
                            get: { isSelected(site) },
                            set: { isOn in
                                setNewsSite(site, isSelected: isOn)
                            }
                        )) {
                            Text(site)
                        }
                        .menuActionDismissBehavior(.disabled)
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.footnote)
                }
                
                Menu {
                    Picker("Sort", selection: Binding(
                        get: { sortOrder },
                        set: { storedSortOrder = $0.rawValue }
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
        }
        .searchable(text: $filter, placement: .navigationBarDrawer, prompt: Text("Filter on title or summary"))
    }
    
    private func decodeSelectedNewsSites() -> Set<String> {
        guard
            let data = storedSelectedNewsSites.data(using: .utf8),
            let sites = try? JSONDecoder().decode([String].self, from: data)
        else {
            return ["NASA"]
        }
        
        let selectedSites = Set(sites)
        return selectedSites.isEmpty ? ["NASA"] : selectedSites
    }
    
    private func storeSelectedNewsSites(_ sites: Set<String>) {
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
    
    private func setNewsSite(_ site: String, isSelected: Bool) {
        var updatedSites = selectedNewsSites
        
        if isSelected {
            updatedSites.insert(site)
        } else {
            updatedSites.remove(site)
        }
        
        if !updatedSites.isEmpty {
            storeSelectedNewsSites(updatedSites)
        }
    }
    
    private func isSelected(_ site: String) -> Bool {
        selectedNewsSites.contains(site)
    }
}

#Preview {
    NewsListView(selectedDestination: .constant(.none))
}
