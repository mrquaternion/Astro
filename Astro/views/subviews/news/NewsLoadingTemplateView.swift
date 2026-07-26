//
//  NewsLoadingTemplateView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-25.
//

import SwiftUI

struct NewsLoadingTemplateView: View {
    /// Environment value supplying colorScheme.
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(0..<10) { _ in
                            templateArticleCard(proxy)
                        }
                    }
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("News")
                .navigationSubtitle("Recent space-related news across the globe")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 12) {
                            // placeholders
                            Button { } label: {
                                Image(systemName: "arrow.down.circle")
                                    .font(.footnote)
                            }
                            Menu { } label: {
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.footnote)
                            }
                            Menu { } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.footnote)
                            }
                        }
                    }
                }
            }
        }
        // placeholder
        .searchable(text: .constant(""), placement: .navigationBarDrawer, prompt: Text("Filter on title or summary"))
    }
    
    @ViewBuilder
    private func templateArticleCard(_ proxy: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            Color(.secondarySystemBackground)
            
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 16) {
                    // Image
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray))
                        .frame(height: 150)
                        .shimmer(.default(for: colorScheme))
                    
                    HStack(alignment: .top) {
                        // News site placement
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(.systemGray))
                            .frame(width: 100, height: 20)
                            .shimmer(.default(for: colorScheme))
                        
                        Spacer()
                        
                        // Published date placement
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(.systemGray))
                            .frame(width: 70, height: 15)
                            .shimmer(.default(for: colorScheme))
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title placement
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(.systemGray))
                        .frame(width: 250, height: 30)
                        .shimmer(.default(for: colorScheme))
                    
                    // Summary placement
                    VStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color(.systemGray))
                            .frame(height: 15)
                            .shimmer(.default(for: colorScheme))
                        
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color(.systemGray))
                            .frame(width: 120, height: 15)
                            .shimmer(.default(for: colorScheme))
                    }
                }
            }
            .padding()
        }
        .frame(width: proxy.size.width * 0.95)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NewsLoadingTemplateView()
}
