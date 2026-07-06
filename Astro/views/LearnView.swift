//
//  LearnView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-23.
//

import SwiftUI
import VariableBlur

struct LearnItemView: View {
    /// App manager that holds variables available across the app
    @Environment(AppState.self) private var appState
    
    @Environment(\.dismiss) var dismiss
    
    @Environment(\.isPad) var isPad
    
    @State private var showComponentsList = false
    @State private var gesturesMenuOn = false
    
    var isHorizontal: Bool
    var modelFilename: String
    
    /// Check if current device is iPhone and in landscape mode.
    private var isPhoneAndLandscape: Bool
    
    init(isHorizontal: Bool, modelFilename: String, isPhone: Bool) {
        self.isHorizontal = isHorizontal
        self.modelFilename = modelFilename
        self.isPhoneAndLandscape = isPhone && isHorizontal
    }
    
    var body: some View {
        AdaptiveStack(isHorizontal: isHorizontal) {
            VirtualEnvironment(gesturesMenuOn: $gesturesMenuOn, modelFilename: modelFilename)
                .ignoresSafeArea()
                .overlay(alignment: .topTrailing) {
                    Button {
                        gesturesMenuOn = true
                    } label: {
                        Image(systemName: "info")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding()
                            .glassEffect()
                    }
                    .popover(isPresented: $gesturesMenuOn, arrowEdge: isPad ? .trailing : .top) {
                        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                            ForEach(gestures) { gesture in
                                GridRow {
                                    HStack {
                                        Image(systemName: gesture.icon)
                                        Text("\(gesture.action) :")
                                    }
                                    Text(gesture.iconCount == 2 ? "2-Finger \(gesture.gestureName)" : gesture.gestureName)
                                }
                            }
                        }
                        .padding()
                        .presentationCompactAdaptation(.popover)
                    }
                    .padding(.trailing)
                    .padding(.top, ((isPad || isPhoneAndLandscape) ? 16 : 0))
                }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        showComponentsList = true
                    } label: {
                        Image(systemName: "cube.transparent")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding()
                            .glassEffect()
                    }
                    .padding(.trailing)
                    .padding(.top, ((isPad || isPhoneAndLandscape) ? 16 : 0))
                }
                .overlay(alignment: .topLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding()
                            .glassEffect()
                    }
                    .padding(.leading)
                }
        }
        .sheet(isPresented: $showComponentsList) {
            ComponentsList()
                .safeAreaPadding([.top, .horizontal])
                .presentationDetents([.fraction(0.33), .fraction(0.66)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            appState.toggleBottomBar()
        }
        .onDisappear {
            appState.toggleBottomBar()
        }
    }
}

struct LearnView: View {
    
    @Environment(\.isPhone) var isPhone

    var items = ["acims"]
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isHorizontal = geometry.size.width > geometry.size.height
                
                List {
                    ForEach(items, id: \.self) { modelFilename in
                        NavigationLink {
                            LearnItemView(isHorizontal: isHorizontal, modelFilename: modelFilename, isPhone: isPhone)
                                .navigationBarBackButtonHidden()
                        } label: {
                            Text(modelFilename)
                        }
                    }
                }
            }
        }
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
        .environment(AppState())
}
