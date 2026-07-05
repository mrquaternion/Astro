//
//  NewsView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-21.
//

import SwiftUI
import Combine
import VariableBlur

struct ArticleDestination: Identifiable {
    /// Stable identity for the selected article.
    let id: String
    
    /// Article URL displayed by the web view.
    let url: URL
    
    /// Whether the article should load from its local web archive.
    let isDownloadedLocally: Bool
    
    init(id: String, url: URL, isDownloadedLocally: Bool) {
        self.id = id
        self.url = url
        self.isDownloadedLocally = isDownloadedLocally
    }
}

struct NewsView: View {
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) var colorScheme

    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad

    /// View model of the current view.
    @StateObject private var viewModel: SpaceNewsViewModel
    
    /// Article URL selected for in-app reading.
    @State private var selectedDestination: ArticleDestination?
    
    init(dataController: DataController, subscriptionManager: SubscriptionManager) {
        _viewModel = StateObject(
            wrappedValue: SpaceNewsViewModel(
                dataController: dataController,
                subscriptionManager: subscriptionManager
            )
        )
    }
    
    /// The news feed content.
    var body: some View {
        Group {
            // fetching articles
            if viewModel.areArticlesLoading && viewModel.articles.isEmpty {
                NewsLoadingTemplateView()
            } else { // finished
                if viewModel.articles.isEmpty {
                    ContentUnavailableView("No articles available", systemImage: "newspaper")
                        .foregroundStyle(.white)
                } else {
                    NewsListView(
                        articles: viewModel.articles,
                        selectedDestination: $selectedDestination
                    )
                    .environmentObject(viewModel)
                }
            }
        }
        .overlay(alignment: .bottom) {
            VariableBlurView(maxBlurRadius: 5, direction: .blurredBottomClearTop)
                .frame(height: 100)
        }
        .ignoresSafeArea()
        .task {
            await viewModel.loadArticles()
        }
        .conditionalPresentation(item: $selectedDestination, isPad: isPad) { destination in
            ArticlePresentation(destination: destination)
        }
    }
}
