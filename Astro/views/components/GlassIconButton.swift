//
//  GlassIconButton.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-08.
//

import SwiftUI


struct GlassIconButton: View {
    /// Value used for systemName.
    let systemName: String
    /// Value used for size.
    let size: CGFloat
    /// Value used for padding.
    var padding: CGFloat = 16
    /// Value used for foregroundColor.
    var foregroundColor: Color = .white
    /// Value used for action.
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(foregroundColor)
                .padding(padding)
                .background(Circle().fill(.mapGlassBackground()))
                .glassEffect(.clear.interactive(), in: .circle)
        }
    }
}
