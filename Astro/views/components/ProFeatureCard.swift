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
            icon: "rocket",
            title: "Live missions",
            description: "Stay updated on upcoming launches.",
            tint: .teal,
            isCustom: true,
            isHandmade: true
        ),
        .init(
            icon: "books.vertical.fill",
            title: "Deep history",
            description: "Explore the origins of rockets, satellites, and spaceships.",
            tint: .red
        ),
        .init(
            icon: "moon.stars.fill",
            title: "Night sky planner",
            description: "Find the best times to photograph the Milky Way and planets.",
            tint: .purple
        ),
        .init(
            icon: "custom.megaphone.slash.fill",
            title: "No ads",
            description: "Read the news without interruptions.",
            tint: .orange,
            isCustom: true
        ),
        .init(
            icon: "wifi.slash",
            title: "Offline access",
            description: "Download satellites, articles and more.",
            tint: .secondary
        )
    ]
}

#Preview {
    ProFeatureCard(feature: ProFeature.all.first!)
}
