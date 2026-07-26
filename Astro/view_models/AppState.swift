//
//  AppState.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-06.
//

import Foundation
import SwiftUI

@Observable
final class AppState {
    /// Whether the custom bottom tab bar is visible.
    private(set) var showBottomBar = true
    
    /// Updates bottom tab bar visibility without relying on the current state.
    func setBottomBarVisible(_ isVisible: Bool, animated: Bool = true) {
        guard showBottomBar != isVisible else { return }
        
        if animated {
            withAnimation(.snappy) {
                showBottomBar = isVisible
            }
        } else {
            showBottomBar = isVisible
        }
    }
    
    /// Toggles the bottom tab bar visibility.
    func toggleBottomBar() {
        setBottomBarVisible(!showBottomBar)
    }
}
