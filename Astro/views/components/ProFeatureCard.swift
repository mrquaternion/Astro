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
        VStack(alignment: .leading, spacing: 8) {
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

                    Text(feature.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    /// Features advertised in the paywall grid.
    static let all: [ProFeature] = [
        .init(
            icon: "satellite",
            title: "More satellites",
            description: "Track tens of additional orbits in real time.",
            tint: .blue,
            isCustom: true,
            isHandmade: true
        ),
        .init(
            icon: "wifi.slash",
            title: "Offline access",
            description: "Download satellites, articles and more.",
            tint: .secondary
        ),
        .init(
            icon: "books.vertical.fill",
            title: "Deep history",
            description: "Explore the origins of rockets, satellites, and spaceships.",
            tint: .red
        ),
        .init(
            icon: "rocket",
            title: "Live 3D launches",
            description: "Follow launches in real time with an interactive 3D flight simulation.",
            tint: .teal,
            isCustom: true,
            isHandmade: true
        ),
        .init(
            icon: "bell.badge.fill",
            title: "App notifications",
            description: "Be ready and get timely alerts for launches, missions, and important space events.",
            tint: .orange
        ),
        .init(
            icon: "iphone.radiowaves.left.and.right",
            title: "Live Activities",
            description: "Follow launch progress at a glance from your Lock Screen and Dynamic Island.",
            tint: .purple
        )
    ]
    
    /// Core features available to every Astro user.
    static let freeTierFeatures: [ProFeature] = [
        .init(
            icon: "globe.americas.fill",
            title: "Live ISS tracking",
            description: "Follow the International Space Station around Earth in real time.",
            tint: .blue,
            isIncludedInFree: true
        ),
        .init(
            icon: "newspaper.fill",
            title: "NASA Space news",
            description: "Read the latest stories and discoveries from NASA.",
            tint: .orange,
            isIncludedInFree: true
        ),
        .init(
            icon: "calendar.badge.clock",
            title: "Launch schedules",
            description: "Browse upcoming launches and mission details.",
            tint: .teal,
            isIncludedInFree: true
        )
    ]
    
    /// Complete feature set used by the Free and Pro comparison.
    static let subscriptionComparison = freeTierFeatures + all
}

#Preview {
    ProFeatureCard(feature: ProFeature.all.last!)
}
