//
//  DownloadSFSymbolAnimation.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-24.
//

import SwiftUI
import Combine

enum DownloadState {
    case cloud
    case downloading
    case complete
    
    var symbol: String {
        switch self {
        case .cloud:
            "arrow.down.circle.dotted"
        case .downloading:
            "circle"
        case .complete:
            "arrow.down.circle.fill"
        }
    }
}

struct DownloadSFSymbolAnimation: View {
    @EnvironmentObject var downloadManager: LocalDownloadManager
    
    @Binding var isDownloadToggled: Bool
    
    let id: String
    
    var symbolAlreadyInUse: String?
    
    var symbolColorAlreadyInUse: Color?
    
    var symbolInUse: String? {
        isDownloadToggled ? downloadState.symbol : symbolAlreadyInUse
    }
    
    var symbolColorInUse: Color? {
        isDownloadToggled ? .secondary : symbolColorAlreadyInUse
    }
    
    private var progress: CGFloat {
        downloadManager.progress(for: id)
    }
    
    private var downloadState: DownloadState {
        switch progress {
        case ...0:
            return .cloud
        case 1...:
            return .complete
        default:
            return .downloading
        }
    }
    
    var body: some View {
        Group {
            if downloadState == .downloading {
                ProgressRing(progress: progress)
                    .animation(.linear(duration: 0.15), value: progress)
            } else if let symbolInUse, let symbolColorInUse {
                Image(systemName: symbolInUse)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(symbolColorInUse)
                    .transition(.opacity)
            }
        }
        .frame(width: 17, height: 17) // `Group` contains an implicit `EmptyView`
        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
    }
}

struct ProgressRing: View {
    let progress: CGFloat
    let strokeColor: Color = .blue
    let backgroundColor: Color = .gray.opacity(0.3)
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(strokeColor, style: .init(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview("Option 1") {
    @Previewable @State var downloadState: DownloadState = .cloud
    @Previewable @State var isDownloadToggled = false
    
    HStack {
        Button {
            isDownloadToggled = true
        } label: {
            Text("Download")
                .font(.footnote)
        }
        .buttonStyle(.glassProminent)
        
        Spacer()
        
        DownloadSFSymbolAnimation(
            isDownloadToggled: $isDownloadToggled,
            id: CachedAsset.mock.id,
            symbolAlreadyInUse: "checkmark.circle.fill",
            symbolColorAlreadyInUse: .green
        )
    }
    .padding(.horizontal)
    .environmentObject(LocalDownloadManager())
}

#Preview("Option 2") {
    @Previewable @State var downloadState: DownloadState = .cloud
    @Previewable @State var isDownloadToggled = false
    
    HStack {
        Button {
            withAnimation {
                isDownloadToggled = true
            }
        } label: {
            Text("Download")
                .font(.footnote)
        }
        .buttonStyle(.glassProminent)
        
        Spacer()
        
        DownloadSFSymbolAnimation(
            isDownloadToggled: $isDownloadToggled,
            id: CachedAsset.mock.id
        )
    }
    .padding(.horizontal)
    .environmentObject(LocalDownloadManager())
}

extension CachedAsset {
    static var mock: CachedAsset {
        .init(
            id: "1",
            name: "ISS",
            summary: "This is a crazy spaceship",
            modelFileName: "",
            tleFileName: "",
            snapFileName: "",
            modelStoragePath: "",
            tleStoragePath: "",
            snapStoragePath: "",
            updatedAt: .now
        )
    }
}
