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
    private(set) var showBottomBar = true
    
    func toggleBottomBar() {
        withAnimation {
            showBottomBar.toggle()
        }
    }
}
