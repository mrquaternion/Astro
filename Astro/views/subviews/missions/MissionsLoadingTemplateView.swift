//
//  MissionsLoadingTemplateView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-22.
//

import SwiftUI

struct MissionsLoadingTemplateView: View {
    /// Environment value supplying colorScheme.
    @Environment(\.colorScheme) var colorScheme
    
    /// Value used for metrics.
    var metrics: MissionsLayoutMetrics
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        let count = 10
                        ForEach(Array(0..<count), id: \.self) { i in
                            templateLaunchRow(proxy)
                        }
                    }
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationTitle("tab_missions".localizedFirstCapitalized)
                .navigationSubtitle("missions_navigation_subtitle".localizedFirstCapitalized)
            }
        }
    }
    
    @ViewBuilder
    private func templateLaunchRow(_ proxy: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            Color(.secondarySystemBackground)
            
            HStack(spacing: 20) {
                // Thumbnail
                Rectangle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: metrics.thumbnailSize, height: metrics.thumbnailSize)
                    .overlay(
                        Image("rocket")
                            .font(.title3)
                            .foregroundStyle(Color(.secondaryLabel))
                    )
                    .shimmer(.default(for: colorScheme))
                
                // Shortname and mission name
                VStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(.systemGray))
                        .frame(width: 90, height: 20)
                        .shimmer(.default(for: colorScheme))
                    
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(.systemGray))
                        .frame(width: 120, height: 10)
                        .shimmer(.default(for: colorScheme))
                }
                
                Spacer()
                
                // NET
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(.systemGray))
                    .frame(width: 50, height: 12)
                    .shimmer(.default(for: colorScheme))
            }
            .padding()
        }
        .frame(width: proxy.size.width * 0.95)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    MissionsLoadingTemplateView(metrics: .init(isPad: false))
}
