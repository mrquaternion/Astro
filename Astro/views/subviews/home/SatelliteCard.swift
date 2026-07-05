//
//  SatelliteCard.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-13.
//

import SwiftUI
import SwiftData

struct SatelliteCard: View {
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) private var colorScheme
    
    /// Shared home state used to read and change the selected satellite.
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @EnvironmentObject private var downloadManager: LocalDownloadManager
    
    @State private var isDownloadToggled = false
    
    /// Satellite asset represented by this row.
    let asset: CachedAsset
    
    /// Whether this asset is currently selected.
    let isSelected: Bool
    
    /// Whether this asset is locked behind the subscription.
    let isLocked: Bool
    
    /// The satellite row content.
    var body: some View {
        HStack(spacing: 20) {
            satelliteImage
            
            Divider()
                .frame(width: 1)
                .padding(.vertical, 8)
            
            satelliteText
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke((isSelected ? (colorScheme == .light ? Color.accentColor : Color.gray) : .clear), lineWidth: 2)
        }
        .contextMenu {
            Button {
                isDownloadToggled = true
            } label: {
                Label(
                    asset.isDownloadedLocally ? "Already downloaded" : "Download",
                    systemImage: asset.isDownloadedLocally ? "arrow.down.circle.fill" : "arrow.down.circle"
                )
            }
            .disabled(asset.isDownloadedLocally)
        }
        .onChange(of: isDownloadToggled) { _, newValue in
            if newValue {
                Task {
                    do {
                        try await homeViewModel.saveOffline(
                            for: asset,
                            downloadManager: downloadManager
                        )
                    } catch is CancellationError {
                        return
                    } catch {
                        print("Offline download failed:", error)
                    }
                    
                    withAnimation {
                        isDownloadToggled = false
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var satelliteImage: some View {
        Group {
            if let data = asset.snapImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            } else {
                Image(systemName: "satellite")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 100)
        .clipped()
    }
    
    
    @ViewBuilder
    private var satelliteText: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(asset.name)
                    .font(.headline)
                
                Spacer()
                
                DownloadSFSymbolAnimation(
                    isDownloadToggled: $isDownloadToggled,
                    id: asset.id,
                    symbolAlreadyInUse: isSelected ? "checkmark.circle.fill" : nil,
                    symbolColorAlreadyInUse: .green
                )
                .environmentObject(downloadManager)
            }
            
            Text(asset.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
    }
    
}
