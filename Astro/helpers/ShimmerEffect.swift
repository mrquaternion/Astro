//
//  ShimmerEffect.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-22.
//  Inspired by https://www.youtube.com/watch?app=desktop&v=yhFz_DXFxec&ra=m

import SwiftUI

extension View {
    @ViewBuilder
    func shimmer(_ config: ShimmerConfig) -> some View {
        self
            .modifier(ShimmerEffectHelper(config: config))
    }
}

fileprivate struct ShimmerEffectHelper: ViewModifier {
    /// Value used for config.
    var config: ShimmerConfig
    /// Mutable view state tracking moveTo.
    @State private var moveTo: CGFloat = -0.7
    
    func body(content: Content) -> some View {
        content
            .hidden()
            .overlay {
                Rectangle()
                    .fill(config.tint)
                    .mask { content }
                    .overlay {
                        GeometryReader {
                            let size = $0.size
                            let extraOffset = size.height / 2.5
                            
                            Rectangle()
                                .fill(config.highlight)
                                .mask {
                                    Rectangle()
                                        .fill(
                                            .linearGradient(
                                                colors: [.white.opacity(0), config.highlight.opacity(config.highlightOpacity), .white.opacity(0)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .blur(radius: config.blur)
                                        .rotationEffect(.init(degrees: -70))
                                        .offset(x: moveTo > 0 ? extraOffset : -extraOffset)
                                        .offset(x: size.width * moveTo)
                                }
                        }
                        .mask { content }
                    }
                    .onAppear { DispatchQueue.main.async { moveTo = 0.7 } }
                    .animation(.linear(duration: config.speed).repeatForever(autoreverses: false), value: moveTo)
            }
    }
}

struct ShimmerConfig {
    /// Value used for tint.
    var tint: Color
    /// Value used for highlight.
    var highlight: Color
    /// Value used for blur.
    var blur: CGFloat = 0
    /// Value used for highlightOpacity.
    var highlightOpacity: CGFloat = 1
    /// Value used for speed.
    var speed: CGFloat = 2
}

extension ShimmerConfig {
    static func `default`(for colorScheme: ColorScheme, speed: CGFloat = 1) -> ShimmerConfig {
        .init(
            tint: colorScheme == .light ? .gray.opacity(0.3) : .black.opacity(0.3),
            highlight: colorScheme == .light ? .white.opacity(0.7) : .gray.opacity(0.3),
            blur: 2,
            speed: speed
        )
    }
}
