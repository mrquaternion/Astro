//
//  VirtualEnvironmentViewModel.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-07.
//

import Foundation
import RealityKit
import Combine

@MainActor
final class VirtualEnvironmentViewModel: ObservableObject {
    /// Scale currently applied to the model.
    @Published var modelCurrentScale: SIMD3<Float>
    /// Scale captured at the end of the previous gesture.
    @Published var modelLastScale: SIMD3<Float>
    /// Position currently applied to the model.
    @Published var modelCurrentPosition: SIMD3<Float> = .zero
    /// Position captured at the end of the previous gesture.
    @Published var modelLastPosition: SIMD3<Float> = .zero
    /// Rotation currently applied to the model.
    @Published var modelCurrentRotation: simd_quatf = .init()
    /// Rotation captured at the end of the previous gesture.
    @Published var modelLastRotation: simd_quatf = .init()
    
    /// Position used when recentering the model.
    let centeredPosition: SIMD3<Float> = .zero
    
    /// Bounds of the view presenting the RealityKit scene.
    @Published var envScreenBounds: CGSize?
    /// Root entity containing the loaded model and scene content.
    @Published var sceneRoot = Entity()
    
    init(modelInitScale: SIMD3<Float>) {
        self.modelCurrentScale = modelInitScale
        self.modelLastScale = modelInitScale
    }
    
    func createSphericalSkybox(name: String) -> Entity? {
        let largeSphere = MeshResource.generateSphere(radius: 20)
        var skyboxMaterial = UnlitMaterial()
        
        do {
            let texture = try TextureResource.load(named: "equirectangular_galactic")
            skyboxMaterial.faceCulling = .none
            skyboxMaterial.color = .init(texture: .init(texture))
        } catch {
            print("Failed to create skybox material: \(error)")
            return nil
        }
        
        let skyboxEntity = Entity()
        skyboxEntity.name = name
        skyboxEntity.components.set(ModelComponent(mesh: largeSphere, materials: [skyboxMaterial]))
        return skyboxEntity
    }
    
    func isPositionValid(_ proposedPosition: SIMD3<Float>, modelName: String, cameraName: String) -> Bool {
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
    
    /// Whether the model has moved away from its centered position.
    var isOffCenter: Bool {
        simd_distance(modelCurrentPosition, centeredPosition) > 0.0001
    }
    
    func resetPosition() {
        modelCurrentPosition = .zero
        modelLastPosition = .zero
    }
    
    func printHierarchy(_ entity: Entity, depth: Int = 0) {
        let indent = String(repeating: "  ", count: depth)
        let type = entity is ModelEntity ? "ModelEntity" : "Entity"
        print("\(indent)\(entity.name) — \(type)")
        for child in entity.children {
            printHierarchy(child, depth: depth + 1)
        }
    }
    
    /*
    func createSkybox(name: String) -> Entity? {
        let boxSize: Float = 20
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
        skyboxEntity.name = name
        skyboxEntity.components.set(ModelComponent(mesh: boxMesh, materials: materials))
        return skyboxEntity
    }
     */
}
