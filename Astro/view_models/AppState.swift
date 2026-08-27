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

    /// Launch detail requested from outside the missions navigation stack.
    private(set) var pendingMissionLaunchID: String?
    
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

    /// Requests navigation to a launch detail from app-level events such as notifications.
    func requestMissionLaunchDetails(for launchID: String) {
        pendingMissionLaunchID = launchID
    }

    /// Clears a pending launch navigation request after the missions stack handles it.
    func consumePendingMissionLaunchID() {
        pendingMissionLaunchID = nil
    }
}
