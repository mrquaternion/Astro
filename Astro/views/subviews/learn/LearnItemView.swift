//
//  LearnItemView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-06.
//

import SwiftUI

/// View that display the model in `RealityKit` virtual environment and a fair description about it.
struct LearnItemView: View {
    /// Dismisses the current learn detail.
    @Environment(\.dismiss) var dismiss
    
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) var colorScheme
    
    /// Detect device orientation.
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad
    
    /// Whether the current interface space is wider than it is tall.
    @Environment(\.isLandscape) private var isLandscape
    
    /// Environment value supplying learnViewModel.
    @EnvironmentObject private var learnViewModel: LearnViewModel
    
    /// Whether the components sheet is visible.
    @State private var showComponentsList = false
    
    /// Show the model virtual environment in fullscreen.
    @State private var toggleFullscreen = false
    
    /// The component currently shown in this detail view.
    @State private var selectedComponent: CachedLearnAsset.LearnComponent
    
    /// The asset selected from the learn list.
    let asset: CachedLearnAsset

    init(asset: CachedLearnAsset) {
        self.asset = asset
        _selectedComponent = State(initialValue: asset.defaultComponent)
    }
    
    var body: some View {
        AdaptiveStack(
            isHorizontal: isLandscape,
            hideSecondary: toggleFullscreen,
            component: selectedComponent
        ) {
            VirtualEnvironmentContainerView(
                selectedComponent: $selectedComponent,
                toggleFullscreen: $toggleFullscreen,
                asset: asset,
                onDismiss: { dismiss() }
            )
            .id(selectedComponent.componentId)
        }
        // components toggle button
        .overlay(alignment: .bottomTrailing) {
            GlassIconButton(
                systemName: "cube.transparent", size: isPad ? 24 : 20,
                foregroundColor: .white
            ) {
                showComponentsList.toggle()
            }
            .padding(.trailing, 24)
        }
        .conditionalPresentationAlt(isPresented: $showComponentsList, isPad: isPad) {
            ComponentsList(
                asset: asset,
                selectedComponent: $selectedComponent
            )
            .presentationDetents([.fraction(0.33), .fraction(0.66)])
            .presentationDragIndicator(.visible)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}


fileprivate struct AdaptiveStack<Content: View>: View {
    /// Whether the stack should lay out horizontally.
    var isHorizontal: Bool
    
    /// Spacing between arranged content.
    var spacing: CGFloat? = 0
    
    /// Whether the content primary content is fullscreen or not.
    var hideSecondary: Bool
    
    /// Value used for component.
    var component: CachedLearnAsset.LearnComponent
    
    /// Value used for content.
    @ViewBuilder var content: () -> Content
    
    /// Value used for secondaryContents.
    private var secondaryContents: LearnDescriptionItemContainer {
        LearnDescriptionItemContainer(
            summary: LearnDescriptionItem(
                destination: AnyView(LearnItemSummaryView(component: component))
            ),
            details: component.details.isEmpty ? nil : LearnDescriptionItem(
                destination: AnyView(LearnItemDetailsView(component: component))
            ),
            timeline: LearnDescriptionItem(
                destination: AnyView(LearnItemTimelineView(component: component))
            ),
            extras: LearnDescriptionItem(
                destination: AnyView(LearnItemExtrasView(component: component))
            )
        )
    }
    
    var body: some View {
        let layout = isHorizontal
        ? AnyLayout(HStackLayout(spacing: spacing))
        : AnyLayout(VStackLayout(spacing: spacing))
        
        layout {
            content()
            
            if !hideSecondary {
                Group {
                    if isHorizontal {
                        LearnItemDescriptionLandscapeView(items: secondaryContents)
                    } else {
                        LearnItemDescriptionPortraitView(items: secondaryContents)
                    }
                }
                .background(Color(.secondarySystemBackground))
            }
        }
    }
}

struct LearnDescriptionItemContainer {
    /// Value used for summary.
    var summary: LearnDescriptionItem
    /// Value used for details.
    var details: LearnDescriptionItem?
    /// Value used for timeline.
    var timeline: LearnDescriptionItem
    /// Value used for extras.
    var extras: LearnDescriptionItem

    /// Value used for ordered.
    var ordered: [LearnDescriptionItem] {
        [summary, details, timeline, extras].compactMap(\.self)
    }
}

// https://stackoverflow.com/questions/64051363/swiftui-array-of-objects-with-anyview
struct LearnDescriptionItem: Hashable, Equatable {
    static func == (lhs: LearnDescriptionItem, rhs: LearnDescriptionItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Value used for id.
    let id = UUID()
    /// Value used for destination.
    var destination: AnyView
}
