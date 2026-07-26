//
//  VirtualEnvGesturesModifier.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-07.
//

import SwiftUI
import simd

struct VirtualEnvGesturesModifier: ViewModifier {
    /// Observable model supplying vEnvViewModel.
    @ObservedObject var vEnvViewModel: VirtualEnvironmentViewModel
    /// Value used for modelName.
    let modelName: String
    /// Value used for cameraName.
    let cameraName: String
    /// Value used for maxScale.
    let maxScale: Float

    func body(content: Content) -> some View {
        content
            .onTapGesture(count: 2, coordinateSpace: .local) { _ in
                let magnitude: Float = 0.5
                guard vEnvViewModel.modelCurrentScale.x + magnitude < maxScale else { return }
                vEnvViewModel.modelCurrentScale += SIMD3<Float>(repeating: magnitude)
            }
            .gesture(
                TwoFingerDoubleTapGesture()
                    .onToggled {
                        let magnitude: Float = 0.5
                        guard vEnvViewModel.modelCurrentScale.x - magnitude > 0 else { return }
                        vEnvViewModel.modelCurrentScale -= SIMD3<Float>(repeating: magnitude)
                    }
            )
            .gesture(
                TwoFingerPanGesture()
                    .onChanged { value in
                        let speed: Float = 0.01
                        let dx = Float(value.translation.width) * speed
                        let dy = Float(value.translation.height) * speed

                        // screen y is down, RealityKit y is up -> flip dy
                        let proposedPosition = vEnvViewModel.modelLastPosition + SIMD3<Float>(dx, -dy, 0)

                        if vEnvViewModel.isPositionValid(proposedPosition, modelName: modelName, cameraName: cameraName) {
                            vEnvViewModel.modelCurrentPosition = proposedPosition
                        }
                    }
                    .onEnded { _ in
                        vEnvViewModel.modelLastPosition = vEnvViewModel.modelCurrentPosition
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
                        if vEnvViewModel.modelLastRotation == simd_quatf() {
                            vEnvViewModel.modelCurrentRotation = yawRotation * pitchRotation
                        } else {
                            vEnvViewModel.modelCurrentRotation = yawRotation * pitchRotation * vEnvViewModel.modelLastRotation
                        }
                    }
                    .onEnded { _ in
                        vEnvViewModel.modelLastRotation = vEnvViewModel.modelCurrentRotation
                    }
            )
    }
}
