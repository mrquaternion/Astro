//
//  SplashScreenView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-06.
//

import SwiftUI
import SplineRuntime

struct SplashScreenView: View {
    /// Whether the current device is an iPad.
    @Environment(\.isPad) var isPad
    
    /// Whether the loading indicator is visible.
    @State private var isLoading = false
    
    /// The animated splash screen shown during app bootstrap.
    var body: some View {
        let sourceSuffixe = isPad ? "ipad" : "iphone"
        let url = Bundle.main.url(forResource: "astro_loading_screen-\(sourceSuffixe)", withExtension: "splineswift")!

        SplineView(sceneFileURL: url)
            .ignoresSafeArea(.all)
            .scaleEffect(isPad ? 1 : 2)
            .onAppear { isLoading = true }
            .onDisappear { isLoading = false }
            .overlay {
                if isLoading {
                    ProgressView("Setting up satellites...")
                        .padding()
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                }
            }
    }
}

#Preview {
    SplashScreenView()
}
