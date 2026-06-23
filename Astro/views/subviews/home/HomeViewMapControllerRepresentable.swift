//
//  HomeViewMapControllerRepresentable.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-21.
//

import SwiftUI
@_spi(Experimental) import MapboxMaps

struct HomeViewMapControllerRepresentable: UIViewControllerRepresentable {
    /// The selected model's identifier.
    let modelId: String?
    
    /// The selected model's on-device asset URL.
    let modelURL: URL?
    
    /// The object's model containing it's current position.
    @Binding var model: Model3D
    
    /// The object's model upcoming route (~90 min).
    let route: Model3DRoute?
    
    /// The camera's state tracking (or not) the model's asset.
    @Binding var camera: CameraState
    
    /// The state whether the user has moved away from its centerpoint or not.
    @Binding var isTrackingModel: Bool
    
    func makeUIViewController(context: Context) -> HomeViewMapController {
        let viewController = HomeViewMapController()
        viewController.selectedModelId = modelId
        viewController.selectedModelURL = modelURL
        viewController.route = route
        viewController.onUserInteraction = {
            isTrackingModel = false
        }
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: HomeViewMapController, context: Context) {
        uiViewController.onUserInteraction = {
            isTrackingModel = false
        }
        
        uiViewController.updateSelectedModel(id: modelId, url: modelURL)
        uiViewController.updateRoute(route)
        uiViewController.updateModel(
            longitude: model.position[0],
            latitude: model.position[1],
            altitude: model.altitude,
            bearing: model.bearing
        )
        
        if isTrackingModel {
            uiViewController.updateCamera(camera)
        }
    }
}
