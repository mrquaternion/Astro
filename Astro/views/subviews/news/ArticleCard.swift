//
//  ArticleCard.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-22.
//

import SwiftUI
import SwiftData

struct ArticleCard: View {
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) private var colorScheme
    
    /// Saves and loads space news articles.
    @EnvironmentObject private var viewModel: SpaceNewsViewModel
    
    /// Tracks the article web archive download progress.
    @EnvironmentObject private var downloadManager: LocalDownloadManager
    
    /// Whether the current device is an iPhone.
    @Environment(\.isPhone) private var isPhone
    
    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad
    
    /// Whether the download animation is currently active.
    @State private var isDownloadToggled = false
    
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
            cardContentAsButton()
            expandLayout()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                .stroke(.white.opacity(colorScheme == .dark ? 0.14 : 0.2), lineWidth: 0.5)
        }
        // pop-up menu for diverse tappable actions
        .contextMenu {
            Button {
                UIPasteboard.general.string = article.url?.absoluteString
            } label: {
                Label("Copy link", systemImage: "doc.on.doc")
            }
            
            Button {
                isDownloadToggled = true
            } label: {
                Label(
                    article.isDownloadedLocally ? "Already downloaded" : "Download",
                    systemImage: article.isDownloadedLocally ? "arrow.down.circle.fill" : "arrow.down.circle"
                )
            }
            .disabled(article.isDownloadedLocally)
        }
        .onChange(of: isDownloadToggled) { _, newValue in
            if newValue {
                Task {
                    do {
                        try await viewModel.saveOffline(
                            for: article,
                            downloadManager: downloadManager
                        )
                    } catch is CancellationError {
                        return
                    } catch {
                        print("Offline article download failed:", error)
                    }
                    
                    withAnimation {
                        isDownloadToggled = false
                    }
                }
            }
        }
    }
    
    /// View content rendered for articleMetadata.
    @ViewBuilder
    private func cardContentAsButton() -> some View {
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
    }
    
    /// View content rendered for articleText.
    @ViewBuilder
    private func expandLayout() -> some View {
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
    
    /// View content rendered for articleImage.
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
    
    /// View content rendered for imageFallback.
    @ViewBuilder
    private var articleText: some View {
        HStack {
            Text(article.title)
                .font(isPad ? .title3.weight(.semibold) : .headline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            DownloadSFSymbolAnimation(
                isDownloadToggled: $isDownloadToggled,
                id: article.id
            )
            .environmentObject(downloadManager)
        }
        
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
    /// Image displayed alongside the article content.
    private var articleImage: some View {
        GeometryReader { proxy in
            Group {
                if let imageData = article.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
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
                            imageFallback
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
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
    
    @ViewBuilder
    /// Placeholder displayed when the article image is unavailable.
    private var imageFallback: some View {
        ZStack {
            Rectangle()
                .fill(.secondary.opacity(0.16))
            
            Image(systemName: "newspaper")
                .font(.title)
                .foregroundStyle(.secondary)
        }
    }
    
    /// Value used for imageHeight.
    private var imageHeight: CGFloat {
        isPad ? 260 : 180
    }
    
    /// Value used for summaryLineLimit.
    private var summaryLineLimit: Int? {
        guard isPhone else { return nil }
        return isExpanded ? nil : 3
    }
}

fileprivate enum Constants {
    /// Shared value used for cornerRadius.
    static let cornerRadius: CGFloat = 16
}

#Preview {
    ArticleCard(
        article: CachedArticle.mock,
        isExpanded: false,
        onToggleSummary: { },
        onOpen: { }
    )
    .environmentObject(
        SpaceNewsViewModel(
            dataController: SwiftDataController(modelContext: previewContainer.mainContext),
            subscriptionManager: SubscriptionManager()
        )
    )
    .environmentObject(LocalDownloadManager())
}
