//  LearnItemLinkLabelView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-09.
//

import SwiftUI

struct LearnItemLinkLabelView: View {
    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad
    
    /// Environment value supplying downloadManager.
    @EnvironmentObject private var downloadManager: LocalDownloadManager
    /// Environment value supplying learnViewModel.
    @EnvironmentObject private var learnViewModel: LearnViewModel
    
    /// Value used for asset.
    var asset: CachedLearnAsset
    
    /// Mutable view state tracking isDownloadToggled.
    @State private var isDownloadToggled = false

    var body: some View {
        let component = asset.defaultComponent
        let imageHeight: CGFloat = isPad ? 400 : 200
        
        VStack(spacing: 0) {
            Group {
                if
                    let imageData = component.snapImageData,
                    let uiImage = UIImage(data: imageData)
                {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 34, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: imageHeight)
            .frame(maxWidth: .infinity)
            .background(.tertiary)
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 16,
                        bottomLeading: 0,
                        bottomTrailing: 0,
                        topTrailing: 16
                    ),
                    style: .continuous
                )
            )
            
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 16) {
                        Text(component.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        DownloadSFSymbolAnimation(
                            isDownloadToggled: $isDownloadToggled,
                            id: asset.id
                        )
                        .environmentObject(downloadManager)
                    }
                    
                    Text(component.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 8)
                
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
        }
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                        try await learnViewModel.saveOffline(
                            for: asset,
                            downloadManager: downloadManager
                        )
                    } catch is CancellationError {
                        return
                    } catch {
                        print("Offline learn asset download failed:", error)
                    }

                    withAnimation {
                        isDownloadToggled = false
                    }
                }
            }
        }
    }
}

#Preview {
    LearnItemLinkLabelView(asset: CachedLearnAsset.mock)
}

extension CachedLearnAsset {
    /// Shared value used for mock.
    static var mock: CachedLearnAsset {
        CachedLearnAsset(
            id: UUID().uuidString,
            defaultComponent: CachedLearnAsset.LearnComponent.mock,
            components: [],
            updatedAt: .now
        )
    }
}

extension CachedLearnAsset.LearnComponent {
    /// Shared value used for mock.
    static var mock: CachedLearnAsset.LearnComponent {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        
        let component = CachedLearnAsset.LearnComponent(
            componentId: "iss-stationary",
            modelFilename: "",
            snapFilename: nil,
            modelStoragePath: "",
            snapStoragePath: nil,
            displayName: "International Space Station",
            category: "station-overview",
            group: "Full Station",
            agencies: ["NASA", "Roscosmos", "ESA", "JAXA", "CSA"],
            manufacturers: ["International partnership with major elements built in the United States, Russia, Europe, Japan, and Canada"],
            materials: [
                "Aluminum pressure shells",
                "steel and titanium structural fittings",
                "composite solar-array blankets",
                "multi-layer insulation",
                "micrometeoroid and orbital-debris shielding"
            ],
            timeline: [
                .init(
                    date: { formatter.date(from: "1984-01-25") ?? Date.distantPast }(),
                    event: "NASA formally began Space Station Freedom, the U.S. program that later became part of the ISS partnership."
                ),
                .init(
                    date: { formatter.date(from: "1993-09-02") ?? Date.distantPast }(),
                    event: "The United States and Russia announced plans to merge station efforts into a joint international station program."
                )
            ],
            details: [
                .init(
                    title: "Purpose",
                    body: "The station gives researchers a long-duration microgravity environment with crew, power, cooling, communications, and regular cargo access. It is also a proving ground for spacecraft operations, life-support systems, robotics, international mission control, and commercial activity in low Earth orbit."
                ),
                .init(
                    title: "Architecture",
                    body: "The ISS is organized around pressurized laboratory and habitation modules connected to an external truss backbone. The truss carries large solar arrays, thermal radiators, external logistics carriers, spare hardware, and robotics interfaces."
                )
            ],
            summary: "The International Space Station is a permanently crewed orbital laboratory assembled from pressurized modules, truss structures, solar arrays, radiators, docking ports, airlocks, robotics, and external payload platforms. It supports research in microgravity, human health, materials, Earth observation, technology demonstration, and long-duration space operations.",
            sourceIds: []
        )
        
        component.snapImageData = UIImage(named: "iss_mock")?.pngData()
        
        return component
    }
}
