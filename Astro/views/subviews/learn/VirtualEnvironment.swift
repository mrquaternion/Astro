//
//  VirtualEnvironment.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-04.
//

import SwiftUI
import RealityKit

struct VirtualEnvironment: View {
    /// Shared value used for initScale.
    private static let initScale: Float = 1
    /// Shared value used for maxScale.
    private static let maxScale: Float = 5
    /// Value used for modelName.
    private let modelName = "main_model"
    /// Value used for cameraName.
    private let cameraName = "main_camera"
    /// Value used for skyboxName.
    private let skyboxName = "skybox"
    
    /// Mutable view state tracking vEnvViewModel.
    @StateObject private var vEnvViewModel: VirtualEnvironmentViewModel
    
    /// Value used for componentModelData.
    var componentModelData: Data
    /// Binding supplying isModelCentered.
    @Binding var isModelCentered: Bool
    
    init(componentModelData: Data, isModelCentered: Binding<Bool>) {
        self.componentModelData = componentModelData
        _isModelCentered = isModelCentered
        _vEnvViewModel = StateObject(wrappedValue: VirtualEnvironmentViewModel(
            modelInitScale: SIMD3<Float>(repeating: Self.initScale))
        )
    }
    
    var body: some View {
        GeometryReader { proxy in
            RealityView { content in
                content.camera = .virtual
                content.add(vEnvViewModel.sceneRoot)
                await initRealityViewContent()
            } update: { _ in
                updateRealityViewContent()
            } placeholder: {
                loadingViewPlaceholder
            }
            .onAppear {
                vEnvViewModel.envScreenBounds = CGSize(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .ignoresSafeArea()
        .gesturesModifier(
            vEnvViewModel: vEnvViewModel,
            modelName: modelName,
            cameraName: cameraName,
            maxScale: Self.maxScale
        )
        .onChange(of: vEnvViewModel.modelCurrentPosition) { _, newPosition in
            let isCenteredNow = simd_distance(newPosition, .zero) <= 0.0001
            isModelCentered = isCenteredNow
        }
        .onChange(of: isModelCentered) { _, isCentered in
            if isCentered {
                vEnvViewModel.resetPosition()
            }
        }
    }
    
    /// View content rendered for loadingViewPlaceholder.
    @ViewBuilder
    private var loadingViewPlaceholder: some View {
        HStack {
            ProgressView()
                .tint(.white)
            Text("Loading model...")
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
    
    private func initRealityViewContent() async {
        // model
        do {
            let model = try await Entity(from: componentModelData)
            model.name = modelName
            model.scale = vEnvViewModel.modelCurrentScale
            model.components.set(InputTargetComponent())
            model.generateCollisionShapes(recursive: true)
            vEnvViewModel.printHierarchy(model)
            vEnvViewModel.sceneRoot.addChild(model)
        } catch {
            print("Impossible to load model: \(error)")
        }
        
        // sun
        let pointLight = PointLight()
        pointLight.light.intensity = 20_000
        pointLight.light.attenuationFalloffExponent = 3
        let lightAnchor = AnchorEntity(world: [0, 1, 0])
        lightAnchor.addChild(pointLight)
        vEnvViewModel.sceneRoot.addChild(lightAnchor)
        
        // camera
        let cameraEntity = Entity()
        cameraEntity.name = cameraName
        cameraEntity.components.set(PerspectiveCameraComponent())
        let cameraAnchor = AnchorEntity()
        let cameraPosition: SIMD3<Float> = [0, 0, 2]
        cameraEntity.look(at: .zero, from: cameraPosition, relativeTo: nil)
        cameraAnchor.addChild(cameraEntity)
        vEnvViewModel.sceneRoot.addChild(cameraAnchor)
        
        // skybox
        let skybox = vEnvViewModel.createSphericalSkybox(name: skyboxName)
        vEnvViewModel.sceneRoot.addChild(skybox!)
    }
    
    private func updateRealityViewContent() {
        if let modelEntity = vEnvViewModel.sceneRoot.findEntity(named: modelName) {
            modelEntity.position = vEnvViewModel.modelCurrentPosition
            modelEntity.scale = vEnvViewModel.modelCurrentScale
            modelEntity.transform.rotation = vEnvViewModel.modelCurrentRotation
        }
        
        if let skyboxEntity = vEnvViewModel.sceneRoot.findEntity(named: skyboxName) {
            skyboxEntity.transform.rotation = vEnvViewModel.modelCurrentRotation
        }
    }
}

private extension View {
    func gesturesModifier(
        vEnvViewModel: VirtualEnvironmentViewModel,
        modelName: String,
        cameraName: String,
        maxScale: Float
    ) -> some View {
        modifier(VirtualEnvGesturesModifier(
            vEnvViewModel: vEnvViewModel,
            modelName: modelName,
            cameraName: cameraName,
            maxScale: maxScale
        ))
    }
}

#Preview {
    VirtualEnvironment(componentModelData: Data(), isModelCentered: .constant(true))
}
