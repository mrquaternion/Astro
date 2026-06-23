//
//  ArticleCard.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-22.
//

import SwiftUI
import WebKit

struct ArticleCard: View {
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) private var colorScheme
    
    /// Whether the current device is an iPhone.
    @Environment(\.isPhone) private var isPhone
    
    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad
    
    /// Article rendered by this card.
    let article: CachedArticle
    
    /// Whether the article summary is expanded.
    let isExpanded: Bool
    
    /// Action fired by the iPhone summary expansion button.
    let onToggleSummary: () -> Void
    
    /// Action fired when the main card content is tapped.
    let onOpen: () -> Void
    
    /// The tappable news article card.
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onOpen()
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    articleImage
                        .frame(height: imageHeight)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        articleMetadata
                        articleText
                    }
                    .padding(16)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            
            if isPhone {
                Divider()
                    .padding(.horizontal, 16)
                
                Button {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    
                    // opt-out of the parent subtree animation (caused by the
                    // animation on satelliteTracker.isTrackingModel)
                    withTransaction(transaction) {
                        onToggleSummary()
                    }
                } label: {
                    Text(isExpanded ? "See less" : "See more")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.blue)
                        .contentTransition(.identity)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .transaction { transaction in
                    transaction.animation = nil
                    transaction.disablesAnimations = true
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                .stroke(.white.opacity(colorScheme == .dark ? 0.14 : 0.2), lineWidth: 0.5)
        }
    }
    
    @ViewBuilder
    private var articleMetadata: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(article.websiteName)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(article.publishedAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var articleText: some View {
        Text(article.title)
            .font(isPad ? .title3.weight(.semibold) : .headline.weight(.semibold))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
        
        Text(article.summary.trimmingCharacters(in: .whitespacesAndNewlines))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .lineLimit(summaryLineLimit)
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
    }
    
    @ViewBuilder
    private var articleImage: some View {
        GeometryReader { proxy in
            AsyncImage(url: article.imageUrl) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(.secondary.opacity(0.16))
                        .shimmer(.default(for: colorScheme))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    ZStack {
                        Rectangle()
                            .fill(.secondary.opacity(0.16))
                        
                        Image(systemName: "newspaper")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .clipped()
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: Constants.cornerRadius,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: Constants.cornerRadius
                ),
                style: .continuous
            )
        )
    }
    
    private var imageHeight: CGFloat {
        isPad ? 260 : 180
    }
    
    private var summaryLineLimit: Int? {
        guard isPhone else { return nil }
        return isExpanded ? nil : 3
    }
}

struct ArticleDestination: Identifiable {
    /// Stable identity for the selected article URL.
    let id: String
    
    /// Article URL displayed by the web view.
    let url: URL
    
    init(url: URL) {
        self.id = url.absoluteString
        self.url = url
    }
}

struct ArticleWebView: UIViewRepresentable {
    /// Article URL loaded in the web view.
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}

fileprivate enum Constants {
    static let cornerRadius: CGFloat = 16
}
