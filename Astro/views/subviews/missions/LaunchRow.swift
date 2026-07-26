//
//  LaunchRow.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-22.
//

import SwiftUI

struct MissionsLayoutMetrics {
    /// Whether metrics should use the iPad layout.
    let isPad: Bool

    /// Size of a launch thumbnail.
    var thumbnailSize: CGFloat { isPad ? 144 : 72 }
    /// Font used for the launch name.
    var launchNameFont: Font { isPad ? .title.bold() : .headline }
    /// Font used for the mission name.
    var missionNameFont: Font { isPad ? .title2.weight(.medium) : .subheadline }
    /// Font used for the launch date.
    var netFont: Font { isPad ? .headline.weight(.medium) : .footnote }
    /// Spacing between row elements.
    var spacing: CGFloat { isPad ? 24 : 16 }
}

struct LaunchRow: View {
    /// Launch metadata rendered by the row.
    let properties: LaunchFeatureCollection.Feature.Properties
    /// Adaptive layout metrics for the row.
    let metrics: MissionsLayoutMetrics

    var body: some View {
        HStack(spacing: 20) {
            AsyncImage(url: properties.thumbnailURL) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: metrics.thumbnailSize, height: metrics.thumbnailSize)
                } else {
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: metrics.thumbnailSize, height: metrics.thumbnailSize)
                        .overlay(
                            Image("rocket")
                                .font(.title3)
                                .foregroundStyle(Color(.secondaryLabel))
                        )
                }
            }

            VStack(alignment: .leading) {
                Text(properties.shortName)
                    .font(metrics.launchNameFont)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(properties.mission?.name ?? "")
                    .font(metrics.missionNameFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(properties.net, format: .dateTime.month(.abbreviated).day().year())
                .font(metrics.netFont)
                .foregroundStyle(.secondary)
        }
    }
}
