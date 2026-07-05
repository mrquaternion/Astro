//
//  LocalDownloadManager.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-24.
//

import SwiftUI
import Combine
import SwiftData

final class LocalDownloadManager: ObservableObject {
    @Published private(set) var progresses: [String: CGFloat] = [:]
    
    func setProgress(_ progress: CGFloat, for id: String) {
        progresses[id] = min(max(progress, 0), 1)
    }
    
    func progress(for id: String) -> CGFloat {
        progresses[id] ?? 0
    }
}
