//
//  VirtualEnvironmentContainerView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-08.
//

import SwiftUI

fileprivate struct GestureInfo: Identifiable {
    /// Value used for id.
    let id = UUID()
    /// Value used for icon.
    let icon: String
    /// Value used for iconCount.
    let iconCount: Int
    /// Value used for gestureName.
    let gestureName: String
    /// Value used for action.
    let action: String
}

struct VirtualEnvironmentContainerView: View {
    /// Whether the current device is an iPad.
    @Environment(\.isPad) var isPad
    
    /// Whether the current interface space is wider than it is tall.
    @Environment(\.isLandscape) private var isLandscape
    
    /// Environment value supplying horizontalSizeClass.
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    /// Environment value supplying learnViewModel.
    @EnvironmentObject private var learnViewModel: LearnViewModel
    
    /// Whether the model is in its original state or not.
    @State private var isModelCentered = true
    
    /// Whether the gestures help popover is visible.
    @State private var gesturesMenuOn = false
    
    /// Mutable view state tracking componentModelData.
    @State private var componentModelData: Data?
    
    /// Binding supplying selectedComponent.
    @Binding var selectedComponent: CachedLearnAsset.LearnComponent
    
    /// Show the model virtual environment in fullscreen.
    @Binding var toggleFullscreen: Bool
    
    /// The asset selected from the learn list.
    let asset: CachedLearnAsset
    
    /// Dismisses the current learn detail.
    var onDismiss: () -> Void = { }
    
    /// List of gestures.
    private let gestures: [GestureInfo] = [
        GestureInfo(
            icon: "plus.magnifyingglass",
            iconCount: 1,
            gestureName: "gesture_double_tap".localizedFirstCapitalized,
            action: "gesture_zoom".localizedFirstCapitalized
        ),
        GestureInfo(
            icon: "minus.magnifyingglass",
            iconCount: 2,
            gestureName: "gesture_double_tap".localizedFirstCapitalized,
            action: "gesture_zoom_out".localizedFirstCapitalized
        ),
        GestureInfo(
            icon: "hand.draw.fill",
            iconCount: 2,
            gestureName: "gesture_drag".localizedFirstCapitalized,
            action: "gesture_pan".localizedFirstCapitalized
        ),
        GestureInfo(
            icon: "rotate.3d.fill",
            iconCount: 1,
            gestureName: "gesture_drag".localizedFirstCapitalized,
            action: "gesture_rotate".localizedFirstCapitalized
        )
    ]
    
    var body: some View {
        Group {
            if let componentModelData {
                VirtualEnvironment(componentModelData: componentModelData, isModelCentered: $isModelCentered)
            } else {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                }
            }
        }
        .frame(width: isLandscape ? (toggleFullscreen ? nil : 500) : nil, height: isLandscape ? nil : (toggleFullscreen ? nil : (horizontalSizeClass == .regular ? 600 : 300)))
        .frame(maxWidth: isLandscape ? (toggleFullscreen ? .infinity : nil) : .infinity, maxHeight: isLandscape ? .infinity : (toggleFullscreen ? .infinity : nil))
        .overlay(alignment: .top) {
            HStack(alignment: .top, spacing: 0) {
                GlassIconButton(systemName: "chevron.left", size: isPad ? 24 : 16) { onDismiss() }
                    .padding(.leading)
                
                Spacer()
                
                GlassEffectContainer(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 16) {
                        HStack(spacing: 16) {
                            GlassIconButton(
                                systemName: toggleFullscreen ? "rectangle.compress.vertical" : (isLandscape ? "rectangle.expand.diagonal" : "rectangle.expand.vertical"),
                                size: isPad ? 24 : 16
                            ) {
                                withAnimation { toggleFullscreen.toggle() }
                            }
                            
                            GlassIconButton(systemName: "info", size: isPad ? 24 : 16) { gesturesMenuOn = true }
                                .popover(isPresented: $gesturesMenuOn, arrowEdge: .top) {
                                    gesturesPopover
                                }
                        }
                        
                        if !isModelCentered {
                            GlassIconButton(systemName: "scope", size: isPad ? 24 : 16) { isModelCentered = true }
                        }
                    }
                }
                .padding(.trailing)
            }
            .padding(.top)
        }
        .animation(.easeInOut, value: isModelCentered)
        .task(id: selectedComponent.componentId) {
            await loadSelectedComponentModel()
        }
    }
    
    /// View content rendered for gesturesPopover.
    @ViewBuilder
    private var gesturesPopover: some View {
        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
            ForEach(gestures) { gesture in
                GridRow {
                    Label(
                        "gesture_action_format".localizedFormat(gesture.action),
                        systemImage: gesture.icon
                    )
                    Text(
                        gesture.iconCount == 2
                            ? "gesture_two_finger_format".localizedFormat(gesture.gestureName)
                            : gesture.gestureName
                    )
                }
            }
        }
        .padding()
        .presentationCompactAdaptation(.popover)
    }
    
    @MainActor
    private func loadSelectedComponentModel() async {
        self.componentModelData = nil
        
        do {
            let modelData = try await learnViewModel.loadModelData(for: selectedComponent, from: asset)
            
            guard !Task.isCancelled else { return }
            self.componentModelData = modelData
        } catch {
            guard !Task.isCancelled else { return }
        }
    }
}
