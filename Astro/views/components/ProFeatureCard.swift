//
//  ProFeatureCard.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-23.
//

import SwiftUI

struct ProFeatureCard: View {
    /// Feature data rendered by this card.
    let feature: ProFeature

    /// The feature card content.
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        if feature.isCustom {
                            Image(feature.icon)
                                .font(feature.isHandmade ? .title3 : .body)
                                .fontWeight(.regular)
                        } else {
                            Image(systemName: feature.icon)
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(feature.tint)
                    .frame(width: 32, height: 32)
                    .background(feature.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                    HStack(alignment: .top, spacing: 4) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                        
                        if feature.isComingSoon {
                            Text("(∗)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }

            Text(feature.description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct ProFeature: Identifiable {
    /// Stable identity for rendering the feature in a grid.
    let id = UUID()
    
    /// Image asset or SF Symbol used for the feature icon.
    let icon: String
    
    /// Short feature title shown on the card.
    let title: String
    
    /// Supporting description shown below the title.
    let description: String
    
    /// Accent color applied to the feature icon.
    let tint: Color
    
    /// Whether the icon should be loaded from the asset catalog.
    var isCustom: Bool = false
    
    /// Whether the custom icon needs handmade sizing.
    var isHandmade: Bool = false
    
    /// Whether the feature is also available without a subscription.
    var isIncludedInFree: Bool = false
    
    /// Whether the feature is already implemented or coming soon.
    var isComingSoon: Bool = false

    /// Features advertised in the paywall grid.
    static let all: [ProFeature] = [
        .init(
            icon: "satellite",
            title: "feature_more_satellites_title".localizedFirstCapitalized,
            description: "feature_more_satellites_description".localizedFirstCapitalized,
            tint: .blue,
            isCustom: true,
            isHandmade: true
        ),
        .init(
            icon: "wifi.slash",
            title: "feature_offline_access_title".localizedFirstCapitalized,
            description: "feature_offline_access_description".localizedFirstCapitalized,
            tint: .secondary
        ),
        .init(
            icon: "books.vertical.fill",
            title: "feature_deep_history_title".localizedFirstCapitalized,
            description: "feature_deep_history_description".localizedFirstCapitalized,
            tint: .red
        ),
        .init(
            icon: "rocket",
            title: "feature_live_launches_title".localizedFirstCapitalized,
            description: "feature_live_launches_description".localizedFirstCapitalized,
            tint: .teal,
            isCustom: true,
            isHandmade: true,
            isComingSoon: true
        ),
        .init(
            icon: "bell.badge.fill",
            title: "feature_notifications_title".localizedFirstCapitalized,
            description: "feature_notifications_description".localizedFirstCapitalized,
            tint: .orange
        ),
        .init(
            icon: "iphone.radiowaves.left.and.right",
            title: "feature_live_activities_title".localizedFirstCapitalized,
            description: "feature_live_activities_description".localizedFirstCapitalized,
            tint: .purple,
            isComingSoon: true
        )
    ]
    
    /// Core features available to every Astro user.
    static let freeTierFeatures: [ProFeature] = [
        .init(
            icon: "globe.americas.fill",
            title: "feature_iss_tracking_title".localizedFirstCapitalized,
            description: "feature_iss_tracking_description".localizedFirstCapitalized,
            tint: .blue,
            isIncludedInFree: true
        ),
        .init(
            icon: "newspaper.fill",
            title: "feature_nasa_news_title".localizedFirstCapitalized,
            description: "feature_nasa_news_description".localizedFirstCapitalized,
            tint: .orange,
            isIncludedInFree: true
        ),
        .init(
            icon: "calendar.badge.clock",
            title: "feature_launch_schedules_title".localizedFirstCapitalized,
            description: "feature_launch_schedules_description".localizedFirstCapitalized,
            tint: .teal,
            isIncludedInFree: true
        )
    ]
    
    /// Complete feature set used by the Free and Pro comparison.
    static let subscriptionComparison = freeTierFeatures + all
}

#Preview {
    ProFeatureCard(feature: ProFeature.all[3])
}
