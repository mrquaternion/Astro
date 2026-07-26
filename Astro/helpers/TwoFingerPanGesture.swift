//
//  TwoFingerPanGesture.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-05.
//

import SwiftUI

struct TwoFingerPanGesture: UIGestureRecognizerRepresentable {
    struct Value {
        /// Translation accumulated by the two-finger pan.
        var translation: CGSize
        /// Current gesture location in the attached view.
        var location: CGPoint
        /// Current pan velocity.
        var velocity: CGSize
    }
    
    /// Value used for onChangedAction.
    private var onChangedAction: ((Value) -> Void)?
    /// Value used for onEndedAction.
    private var onEndedAction: ((Value) -> Void)?
    
    func onChanged(_ action: @escaping (Value) -> Void) -> Self {
        var copy = self
        copy.onChangedAction = action
        return copy
    }
    
    func onEnded(_ action: @escaping (Value) -> Void) -> Self {
        var copy = self
        copy.onEndedAction = action
        return copy
    }
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(onChangedAction: onChangedAction, onEndedAction: onEndedAction)
    }
    
    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.minimumNumberOfTouches = 2
        recognizer.maximumNumberOfTouches = 2
        recognizer.delegate = context.coordinator
        return recognizer
    }
    
    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        guard let view = recognizer.view else { return }
        
        let value = Value(
            translation: CGSize(
                width: recognizer.translation(in: view).x,
                height: recognizer.translation(in: view).y
            ),
            location: recognizer.location(in: view),
            velocity: CGSize(
                width: recognizer.velocity(in: view).x,
                height: recognizer.velocity(in: view).y
            )
        )
        
        switch recognizer.state {
        case .changed:
            onChangedAction?(value)
        case .ended, .cancelled:
            onEndedAction?(value)
        default:
            break
        }
    }
    
    func updateUIGestureRecognizer(_ recognizer: UIGestureRecognizerType, context: Context) { }
    
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onChangedAction: ((Value) -> Void)?
        let onEndedAction: ((Value) -> Void)?
        
        init(onChangedAction: ((Value) -> Void)?, onEndedAction: ((Value) -> Void)?) {
            self.onChangedAction = onChangedAction
            self.onEndedAction = onEndedAction
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
