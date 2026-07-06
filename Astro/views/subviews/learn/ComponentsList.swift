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
                            .foregroundStyle(.black)
                        Spacer()
                    }
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ComponentsList()
}
