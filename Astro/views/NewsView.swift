//
//  NewsView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-21.
//

import SwiftUI
import Combine
import VariableBlur
import UIKit

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
    /// News state supplied by the app root so it survives tab switches.
    @ObservedObject var viewModel: SpaceNewsViewModel

    /// Reports the UIKit scroll view that backs the news list.
    var onScrollViewResolved: (UIScrollView) -> Void

    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) var colorScheme

    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad

    /// Article URL selected for in-app reading.
    @State private var selectedDestination: ArticleDestination?
    
    init(
        viewModel: SpaceNewsViewModel,
        onScrollViewResolved: @escaping (UIScrollView) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.onScrollViewResolved = onScrollViewResolved
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
                        selectedDestination: $selectedDestination,
                        onScrollViewResolved: onScrollViewResolved
                    )
                    .environmentObject(viewModel)
                }
            }
        }
        .task {
            await viewModel.loadArticlesIfNeeded()
        }
        .conditionalPresentation(item: $selectedDestination, isPad: isPad) { destination in
            ArticlePresentation(destination: destination)
        }
    }
}
