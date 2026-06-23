//
//  SplashScreenView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-06.
//

import SwiftUI

struct SplashScreenView: View {
    /// The launch placeholder shown while bootstrap work completes.
    var body: some View {
        ZStack(alignment: .center) {
            Color.black
            
            Text("Welcome to Astro")
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashScreenView()
}
