//
//  TwoFingerDoubleTapGesture.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-05.
//

import SwiftUI

struct TwoFingerDoubleTapGesture: UIGestureRecognizerRepresentable {
    /// Value used for onToggledAction.
    private var onToggledAction: (() -> Void)?
    
    func onToggled(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onToggledAction = action
        return copy
    }
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(onToggledAction: onToggledAction)
    }
    
    func makeUIGestureRecognizer(context: Context) -> UITapGestureRecognizer {
        let recognizer = UITapGestureRecognizer()
        recognizer.numberOfTapsRequired = 2
        recognizer.numberOfTouchesRequired = 2
        recognizer.delegate = context.coordinator
        return recognizer
    }
    
    func handleUIGestureRecognizerAction(_ recognizer: UITapGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .recognized, .ended:
            onToggledAction?()
        default:
            break
        }
    }
    
    func updateUIGestureRecognizer(_ recognizer: UIGestureRecognizerType, context: Context) { }
    
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onToggledAction: (() -> Void)?
        
        init(onToggledAction: (() -> Void)?) {
            self.onToggledAction = onToggledAction
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
