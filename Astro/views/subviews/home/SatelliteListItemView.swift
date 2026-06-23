//
//  SatelliteListItemView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-13.
//

import SwiftUI

struct SatelliteListItemView: View {
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) private var colorScheme
    
    /// Satellite asset represented by this row.
    let asset: CachedAsset
    
    /// Whether this asset is currently selected.
    let isSelected: Bool
    
    /// Whether this asset is locked behind the subscription.
    let isLocked: Bool
    
    /// The satellite row content.
    var body: some View {
        HStack(spacing: 16) {
            snapshot
            
            Divider()
                .frame(width: 1)
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(asset.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                Text(asset.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke((isSelected ? (colorScheme == .light ? Color.accentColor : Color.gray) : .clear), lineWidth: 2)
        }
    }
    
    /// Snapshot thumbnail shown on the leading edge of the row.
    private var snapshot: some View {
        Group {
            if let data = asset.snapImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Image(systemName: "satellite")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 100)
        .clipped()
    }
}
