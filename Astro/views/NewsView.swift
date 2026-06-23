//
//  NewsView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-21.
//

import SwiftUI
import Combine
import SwiftData
import VariableBlur

struct NewsView: View {
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) var colorScheme
    
    /// The SwiftData context used during app bootstrap.
    @Environment(\.modelContext) private var modelContext
    
    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad
    
    /// Cached articles displayed in the list.
    @Query(sort: \CachedArticle.publishedAt, order: .reverse) private var articles: [CachedArticle]
    
    /// View model of the current view.
    @StateObject private var viewModel = SpaceNewsViewModel()
    
    /// Article URL selected for in-app reading.
    @State private var selectedDestination: ArticleDestination?
    
    /// The news feed content.
    var body: some View {
        Group {
            if viewModel.areArticlesLoading && articles.isEmpty {
                ProgressView()
                    .tint(.white)
            } else {
                if articles.isEmpty {
                    ContentUnavailableView("No articles available", systemImage: "newspaper")
                        .foregroundStyle(.white)
                } else {
                    NewsListView(selectedDestination: $selectedDestination)
                        .environmentObject(viewModel)
                }
            }
        }
        .overlay(alignment: .bottom) {
            VariableBlurView(maxBlurRadius: 5, direction: .blurredBottomClearTop)
                .frame(height: 100)
        }
        .ignoresSafeArea()
        .background(colorScheme == .light ? .white : .accent)
        .task {
            await viewModel.loadArticles(modelContext: modelContext)
        }
        .conditionalPresentation(item: $selectedDestination, isPad: isPad) { destination in
            ArticlePresentation(destination: destination)
        }
    }
}

struct ArticlePresentation: View {
    @Environment(\.dismiss) var dismiss
    
    let destination: ArticleDestination
    
    var body: some View {
        NavigationStack {
            ArticleWebView(url: destination.url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(destination.url.host() ?? "Article")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                        }
                    }
                }
        }
    }
}

#Preview {
    NewsView()
}

