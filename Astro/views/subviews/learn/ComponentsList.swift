//
//  ComponentsList.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-04.
//

import SwiftUI
import VariableBlur

struct ComponentsList: View {
    /// Dismisses the current learn detail.
    @Environment(\.dismiss) var dismiss
    
    /// The asset whose components can be selected.
    let asset: CachedLearnAsset
    
    /// The component currently shown in the learn detail.
    @Binding var selectedComponent: CachedLearnAsset.LearnComponent
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                componentRow(for: asset.defaultComponent, isMain: true)

                if !asset.components.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subcomponents")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 28)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(asset.components) { component in
                                componentRow(for: component)
                            }
                        }
                        .padding(.leading, 28)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(.quaternary)
                                .frame(width: 1)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .top) {
            ZStack {
                Text("Components")
                    .font(.headline)

                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .tint(.primary)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 24)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
    }
    
    private func componentRow(for component: CachedLearnAsset.LearnComponent, isMain: Bool = false) -> some View {
        Button {
            selectedComponent = component
            dismiss()
        } label: {
            HStack(spacing: 20) {
                if isMain {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
                
                Text(component.displayName)
                
                Spacer()
                
                if selectedComponent.componentId == component.componentId {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview("iPad") {
    @Previewable @State var toggledOn = true
    
    VStack {
        Button {
            toggledOn.toggle()
        } label: {
            Text("Tap here")
        }
        .buttonStyle(.borderedProminent)
    }
    .conditionalPresentationAlt(isPresented: $toggledOn, isPad: true) {
        ComponentsList(
            asset: {
                let mockAsset = CachedLearnAsset.mock
                mockAsset.components = Array(repeating: CachedLearnAsset.LearnComponent.mock, count: 2)
                return mockAsset
            }(),
            selectedComponent: .constant(CachedLearnAsset.LearnComponent.mock)
        )
    }
}

#Preview("iPhone") {
    @Previewable @State var toggledOn = true
    
    VStack {
        Button {
            toggledOn.toggle()
        } label: {
            Text("Tap here")
        }
        .buttonStyle(.borderedProminent)
    }
    .conditionalPresentationAlt(isPresented: $toggledOn, isPad: false) {
        ComponentsList(
            asset: {
                let mockAsset = CachedLearnAsset.mock
                mockAsset.components = Array(repeating: CachedLearnAsset.LearnComponent.mock, count: 2)
                return mockAsset
            }(),
            selectedComponent: .constant(CachedLearnAsset.LearnComponent.mock)
        )
    }
}
