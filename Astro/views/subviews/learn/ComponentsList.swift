//
//  ComponentsList.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-04.
//

import SwiftUI

struct ComponentsList: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<10) { i in
                    HStack {
                        Text("Item \(i+1)")
                        Spacer()
                    }
                    .padding()
                    .glassEffect(.clear)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, CustomTabBarLayout.height + CustomTabBarLayout.yOffset)
        }
    }
}

#Preview {
    ComponentsList()
}
