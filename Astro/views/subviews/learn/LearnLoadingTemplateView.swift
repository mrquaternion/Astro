//
//  LearnLoadingTemplateView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-24.
//

import SwiftUI

struct LearnLoadingTemplateView: View {
    /// Environment value supplying colorScheme.
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(0..<10) { _ in
                            templateLearnCard(proxy)
                        }
                    }
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationTitle("Learn")
            }
        }
    }
    
    @ViewBuilder
    private func templateLearnCard(_ proxy: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            Color(.secondarySystemBackground)
            
            VStack(alignment: .leading, spacing: 24) {
                // Image
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray))
                    .frame(height: 150)
                    .shimmer(.default(for: colorScheme))
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title placement
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(.systemGray))
                        .frame(width: 220, height: 30)
                        .shimmer(.default(for: colorScheme))
                    
                    // Summary placement
                    VStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color(.systemGray))
                            .frame(width: 240, height: 15)
                            .shimmer(.default(for: colorScheme))
                        
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color(.systemGray))
                            .frame(width: 280, height: 15)
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
    LearnLoadingTemplateView()
}
