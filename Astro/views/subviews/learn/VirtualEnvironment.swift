//
//  VirtualEnvironment.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-04.
//

import SwiftUI
import RealityKit

struct VirtualEnvironment: View {
    @Environment(\.isPad) var isPad
    
    @State private var entityCurrentScale: SIMD3<Float>
    @State private var entityLastScale: SIMD3<Float>
    
    @State private var entityCurrentPosition: SIMD3<Float> = .zero
    @State private var entityLastPosition: SIMD3<Float> = .zero
    
    @State private var entityCurrentRotation: simd_quatf = .init()
    @State private var entityLastRotation: simd_quatf = .init()
    
    @State private var gesturesMenuOn = false
    
    init(entityCurrentScaleMagnitude: Float = 1, entityLastScaleMagnitude: Float = 1) {
        self.entityCurrentScale = SIMD3<Float>(repeating: entityCurrentScaleMagnitude)
        self.entityLastScale = SIMD3<Float>(repeating: entityLastScaleMagnitude)
    }
    
    var body: some View {
        RealityView { content in
            content.camera = .virtual
            if let entity = try? await ModelEntity(named: "acims") {
                entity.scale = entityCurrentScale
                entity.components.set(InputTargetComponent())
                entity.generateCollisionShapes(recursive: true)
                content.add(entity)
            }
            
            /*
             let cameraEntity = Entity()
             cameraEntity.components.set(OrthographicCameraComponent())
             let cameraAnchor = AnchorEntity()
             
             let cameraPosition: SIMD3<Float> = [0, 0, 2]
             cameraEntity.look(at: .zero, from: cameraPosition, relativeTo: nil)
             
             cameraAnchor.transform.rotation = simd_quatf(vector: .init([1, 1, 1], 1))
             cameraAnchor.addChild(cameraEntity)
             
             content.add(cameraAnchor)
             */
        } update: { content in
            if let entity = content.entities.first {
                entity.position = entityCurrentPosition
                entity.scale = entityCurrentScale
                entity.transform.rotation = entityCurrentRotation
            }
        } placeholder: {
            ProgressView()
        }
        .background(.accent)
        .onTapGesture(count: 2, coordinateSpace: .local) { _ in
            let magnitude: Float = 0.5
            entityCurrentScale = entityCurrentScale + SIMD3<Float>(repeating: magnitude)
        }
        .gesture(
            TwoFingerDoubleTapGesture()
                .onToggled {
                    let magnitude: Float = 0.5
                    guard entityCurrentScale.x - magnitude > 0 else { return }
                    entityCurrentScale = entityCurrentScale - SIMD3<Float>(repeating: magnitude)
                }
        )
        .gesture(
            TwoFingerPanGesture()
                .onChanged { value in
                    let speed: Float = 0.01
                    let dx = Float(value.translation.width) * speed
                    let dy = Float(value.translation.height) * speed
                   
                    // screen y is down, RealityKit y is up -> flip dy
                    entityCurrentPosition = entityLastPosition + SIMD3<Float>(dx, -dy, 0)
                }
                .onEnded { value in
                    entityLastPosition = entityCurrentPosition
                }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let speed: Float = 0.01
                    let dx = Float(value.location.x - value.startLocation.x) * speed
                    let dy = Float(value.location.y - value.startLocation.y) * speed
                    
                    let yawRotation = simd_quatf(angle: dx, axis: [0, 1, 0])
                    let pitchRotation = simd_quatf(angle: dy, axis: [1, 0, 0])
                    
                    // even though "entityLastRotation" is an entity rotation,
                    // entityCurrentRotation = yawRotation * pitchRotation * entityLastRotation
                    // seemed like picking the init rotation
                    if entityLastRotation == simd_quatf() {
                        entityCurrentRotation = yawRotation * pitchRotation
                    } else {
                        entityCurrentRotation = yawRotation * pitchRotation * entityLastRotation
                    }
                }
                .onEnded { _ in
                    entityLastRotation = entityCurrentRotation
                }
        )
        .overlay(alignment: .topTrailing) {
            Button {
                gesturesMenuOn = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title)
                    .foregroundStyle(.thickMaterial)
                    .padding(4)
            }
            
            .popover(isPresented: $gesturesMenuOn, arrowEdge: isPad ? .trailing : .top) {
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                    ForEach(gestures) { gesture in
                        GridRow {
                            HStack {
                                Image(systemName: gesture.icon)
                                Text(gesture.action)
                            }
                            Text(gesture.iconCount == 2 ? "2-Finger \(gesture.gestureName)" : gesture.gestureName)
                        }
                    }
                }
                .padding()
                .presentationCompactAdaptation(.popover)
            }
            .padding([.top, .trailing], 24)
        }
    }
}

struct GestureInfo: Identifiable {
    let id = UUID()
    let icon: String
    let iconCount: Int
    let gestureName: String
    let action: String
}

let gestures: [GestureInfo] = [
    GestureInfo(icon: "plus.magnifyingglass", iconCount: 1, gestureName: "Double Tap", action: "Zoom"),
    GestureInfo(icon: "minus.magnifyingglass", iconCount: 2, gestureName: "Double Tap", action: "Zoom Out"),
    GestureInfo(icon: "hand.draw.fill", iconCount: 2, gestureName: "Drag", action: "Pan"),
    GestureInfo(icon: "rotate.3d.fill", iconCount: 1, gestureName: "Drag", action: "Rotate")
]

#Preview {
    VirtualEnvironment()
}


