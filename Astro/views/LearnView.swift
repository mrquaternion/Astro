//
//  LearnView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-23.
//

import SwiftUI
import VariableBlur

struct LearnView: View {
    var body: some View {
        GeometryReader { geometry in
            let isHorizontal = geometry.size.width > geometry.size.height
            
            AdaptiveStack(isHorizontal: isHorizontal) {
                VirtualEnvironment()
                ComponentsList()
            }
        }
        .overlay(alignment: .bottom) {
            VariableBlurView(maxBlurRadius: 5, direction: .blurredBottomClearTop)
                .frame(height: 100)
        }
        .ignoresSafeArea()
    }
}

fileprivate struct AdaptiveStack<Content: View>: View {
    var isHorizontal: Bool
    var spacing: CGFloat? = 0
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        let layout = isHorizontal ? AnyLayout(HStackLayout(spacing: spacing)) : AnyLayout(VStackLayout(spacing: spacing))
        
        layout {
            content()
        }
    }
}

#Preview {
    LearnView()
}
