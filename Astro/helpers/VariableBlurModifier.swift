//
//  VariableBlurModifier.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-22.
//

import SwiftUI
import VariableBlur

struct BlurOverlayModifier: ViewModifier {
    enum Edge {
        case bottom
        case top
    }
    
    /// Height of the variable blur container.
    let height: CGFloat
    
    /// Maximum radius to which the blur reaches.
    let maxBlurRadius: CGFloat
    
    /// The alignment that the modifier uses to position. Default: `BlurOverlayModifier.Edge.bottom`.
    let edge: Edge?

    /// Whether the blur overlay is currently visible.
    let isVisible: Bool
    
    /// Value used for overlayAlignment.
    private var overlayAlignment: Alignment {
        switch edge {
        case .bottom: .bottom
        case .top: .top
        case nil: .bottom
        }
    }
    
    /// Value used for blurDirection.
    private var blurDirection: VariableBlurDirection {
        switch edge {
        case .bottom: .blurredBottomClearTop
        case .top: .blurredTopClearBottom
        case nil: .blurredBottomClearTop
        }
    }

    /// Value used for hiddenOffset.
    private var hiddenOffset: CGFloat {
        switch edge {
        case .top: -height
        case .bottom, nil: height
        }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: overlayAlignment) {
                if isVisible {
                    VariableBlurView(
                        maxBlurRadius: maxBlurRadius,
                        direction: blurDirection
                    )
                    .frame(height: height)
                    .allowsHitTesting(false)
                    .animation(.easeInOut, value: isVisible)
                }
            }
    }
}

extension View {
    func blurOverlay(
        height: CGFloat,
        maxBlurRadius: CGFloat,
        edge: BlurOverlayModifier.Edge? = nil,
        isVisible: Bool = true
    ) -> some View {
        modifier(
            BlurOverlayModifier(
                height: height,
                maxBlurRadius: maxBlurRadius,
                edge: edge,
                isVisible: isVisible
            )
        )
    }
}
