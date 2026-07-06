//
//  VirtualEnvironment.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-04.
//

import SwiftUI
import RealityKit

struct VirtualEnvironment: View {
    private let initScale: Float = 1
    private let maxScale: Float = 5
    private let modelName = "main_model"
    private let cameraName = "main_camera"
    private let skyboxName = "skybox"
    
    @State private var entityCurrentScale: SIMD3<Float>
    @State private var entityLastScale: SIMD3<Float>
    
    @State private var entityCurrentPosition: SIMD3<Float> = .zero
    @State private var entityLastPosition: SIMD3<Float> = .zero
    
    @State private var entityCurrentRotation: simd_quatf = .init()
    @State private var entityLastRotation: simd_quatf = .init()
    
    @State private var envScreenBounds: CGSize?
    @State private var sceneRoot = Entity()
    
    @Binding var gesturesMenuOn: Bool
    var modelFilename: String
    
    init(gesturesMenuOn: Binding<Bool>, modelFilename: String) {
        _gesturesMenuOn = gesturesMenuOn
        self.modelFilename = modelFilename
        self.entityCurrentScale = SIMD3<Float>(repeating: initScale)
        self.entityLastScale = SIMD3<Float>(repeating: initScale)
    }
    
    var body: some View {
        GeometryReader { proxy in
            RealityView { content in
                content.camera = .virtual
                content.add(sceneRoot)
                
                // model
                if let modelEntity = try? await ModelEntity(named: modelFilename) {
                    modelEntity.name = modelName
                    modelEntity.scale = entityCurrentScale
                    modelEntity.components.set(InputTargetComponent())
                    modelEntity.generateCollisionShapes(recursive: true)
                    sceneRoot.addChild(modelEntity)
                }
                
                // sun
                let pointLight = PointLight()
                pointLight.light.intensity = 20_000
                pointLight.light.attenuationFalloffExponent = 3
                let lightAnchor = AnchorEntity(world: [0, 1, 0])
                lightAnchor.addChild(pointLight)
                sceneRoot.addChild(lightAnchor)
                
                // camera
                let cameraEntity = Entity()
                cameraEntity.name = cameraName
                cameraEntity.components.set(PerspectiveCameraComponent())
                let cameraAnchor = AnchorEntity()
                let cameraPosition: SIMD3<Float> = [0, 0, 2]
                cameraEntity.look(at: .zero, from: cameraPosition, relativeTo: nil)
                cameraAnchor.addChild(cameraEntity)
                sceneRoot.addChild(cameraAnchor)
                
                // skybox
                let skybox = createSkybox()
                sceneRoot.addChild(skybox!)
            } update: { content in
                if let modelEntity = sceneRoot.findEntity(named: modelName) {
                    modelEntity.position = entityCurrentPosition
                    modelEntity.scale = entityCurrentScale
                    modelEntity.transform.rotation = entityCurrentRotation
                }
                
                if let skyboxEntity = sceneRoot.findEntity(named: skyboxName) {
                    skyboxEntity.transform.rotation = entityCurrentRotation
                }
            } placeholder: {
                ProgressView()
            }
            .onAppear {
                envScreenBounds = CGSize(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .onTapGesture(count: 2, coordinateSpace: .local) { _ in
            let magnitude: Float = 0.5
            guard entityCurrentScale.x + magnitude < maxScale else { return }
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
                    let proposedPosition = entityLastPosition + SIMD3<Float>(dx, -dy, 0)
                            
                    if isPositionValid(proposedPosition) {
                        entityCurrentPosition = proposedPosition
                    }
                }
                .onEnded { _ in
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
    }
    
    private func createSkybox() -> Entity? {
        let boxSize: Float = 4
        let boxMesh = MeshResource.generateBox(width: boxSize, height: boxSize, depth: boxSize, splitFaces: true)
        
        // https://developer.apple.com/documentation/realitykit/meshresource/generatebox(width:height:depth:cornerradius:splitfaces:)#discussion
        let faceTextureNames = ["front", "top", "back", "bottom", "right", "left"]
        
        var materials: [UnlitMaterial] = []
        for name in faceTextureNames {
            var material = UnlitMaterial()
            do {
                let texture = try TextureResource.load(named: name)
                material.color = .init(texture: .init(texture))
            } catch {
                print("Failed to create skybox material: \(error)")
            }
            material.faceCulling = .none
            materials.append(material)
        }
        
        
        let skyboxEntity = Entity()
        skyboxEntity.name = skyboxName
        skyboxEntity.components.set(ModelComponent(mesh: boxMesh, materials: materials))
        return skyboxEntity
    }
    
    func isPositionValid(_ proposedPosition: SIMD3<Float>) -> Bool {
        guard
            let modelEntity = sceneRoot.findEntity(named: modelName),
            let cameraEntity = sceneRoot.findEntity(named: cameraName),
            let camera = cameraEntity.components[PerspectiveCameraComponent.self],
            let screenBounds = envScreenBounds
        else {
            return false
        }
        
        // get local bounds relative to the model itself (untranslated)
        let cameraTransform = cameraEntity.transformMatrix(relativeTo: nil)
        let localBounds = modelEntity.visualBounds(relativeTo: modelEntity)
        let min = localBounds.min
        let max = localBounds.max
        
        // apply the proposed position to the bounding box corners in world space
        let cornersWorldSpace: [SIMD4<Float>] = [
            [min.x + proposedPosition.x, min.y + proposedPosition.y, min.z + proposedPosition.z, 1.0],
            [min.x + proposedPosition.x, min.y + proposedPosition.y, max.z + proposedPosition.z, 1.0],
            [min.x + proposedPosition.x, max.y + proposedPosition.y, min.z + proposedPosition.z, 1.0],
            [min.x + proposedPosition.x, max.y + proposedPosition.y, max.z + proposedPosition.z, 1.0],
            [max.x + proposedPosition.x, min.y + proposedPosition.y, min.z + proposedPosition.z, 1.0],
            [max.x + proposedPosition.x, min.y + proposedPosition.y, max.z + proposedPosition.z, 1.0],
            [max.x + proposedPosition.x, max.y + proposedPosition.y, min.z + proposedPosition.z, 1.0],
            [max.x + proposedPosition.x, max.y + proposedPosition.y, max.z + proposedPosition.z, 1.0]
        ]
        
        let V = cameraTransform.inverse
        let cornersViewSpace: [SIMD4<Float>] = cornersWorldSpace.map { V * $0 }
        
        let near = camera.near
        let far = camera.far
        let fov = camera.fieldOfViewInDegrees * .pi / 180
        let ratio = Float(screenBounds.width / screenBounds.height)
        let f = 1 / tan(fov / 2)
        let P = simd_float4x4(
            SIMD4<Float>(f / ratio, 0, 0, 0),
            SIMD4<Float>(0, f, 0, 0),
            SIMD4<Float>(0, 0, far / (near - far), -1),
            SIMD4<Float>(0, 0, (far * near) / (near - far), 0)
        )
        
        let cornersClipSpace: [SIMD4<Float>] = cornersViewSpace.map { P * $0 }
        
        return cornersClipSpace.contains { clipPoint in
            let ndcX = clipPoint.x / clipPoint.w
            let ndcY = clipPoint.y / clipPoint.w
            
            return (
                clipPoint.w > 0 &&
                (-1 <= ndcX && ndcX <= 1) &&
                (-1 <= ndcY && ndcY <= 1)
            )
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
    VirtualEnvironment(gesturesMenuOn: .constant(true), modelFilename: "acims")
}


