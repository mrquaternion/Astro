//
//  OnboardingScreenView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-30.
//

import SwiftUI
import AVKit

enum OnboardingSteps: CaseIterable {
    case `init`
    case first
    case second
    case third
    case fourth
    
    func next() -> Self? {
        let cases = Self.allCases
        guard let index = cases.firstIndex(of: self), index < cases.count - 1 else { return nil }
        return cases[index + 1]
    }
    
    func previous() -> Self? {
        let cases = Self.allCases
        guard let index = cases.firstIndex(of: self), index > 0 else { return nil }
        return cases[index - 1]
    }
    
    var targetTime: Double {
        switch self {
        case .`init`:  return 0.0
        case .first:  return 1.5
        case .second: return 3.0
        case .third:  return 4.5
        case .fourth: return 6.0
        }
    }
}

struct OnboardingScreenView: View {
    
    @State private var currentStep: OnboardingSteps = .`init`
    
    @State private var timeObserver: Any?
    
    @State private var player: AVPlayer = {
        guard let url = Bundle.main.url(forResource: "onboarding_astro_anim", withExtension: "mp4") else {
            fatalError("Video file not found")
        }
        let player = AVPlayer(url: url)
        player.automaticallyWaitsToMinimizeStalling = false
        return player
    }()
    
    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .disabled(true)
                .ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            HStack {
                // back button
                Button {
                    if let prevStep = currentStep.previous() {
                        currentStep = prevStep
                    }
                } label: {
                    Image(systemName: "arrow.left")
                }
                .buttonStyle(.glass)
                .disabled(currentStep == .`init`)
                
                Spacer()
                
                // forward button
                Button {
                    if let nextStep = currentStep.next() {
                        currentStep = nextStep
                    }
                } label: {
                    Image(systemName: "arrow.right")
                }
                .buttonStyle(.glass)
                .disabled(currentStep == .fourth)
            }
            .padding(.horizontal)
        }
        .onAppear {
            setupTimeObserver()
        }
        .onDisappear {
            removeTimeObserver()
        }
        .onChange(of: currentStep) { _, newStep in
            transitionToStep(newStep)
        }
    }
    
    private func setupTimeObserver() {
        let interval = CMTime(value: 1, timescale: 30)
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak player] time in
            guard let player = player else { return }
            let currentSeconds = time.seconds
            let targetSeconds = currentStep.targetTime
            
            if player.rate > 0 {
                if currentSeconds >= targetSeconds {
                    player.pause()
                    // snap exactly to target frame to eliminate over-travel drift
                    player.seek(to: CMTime(seconds: targetSeconds, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
                }
            } else if player.rate < 0 {
                if currentSeconds <= targetSeconds {
                    player.pause()
                    player.rate = 0
                    player.seek(to: CMTime(seconds: targetSeconds, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
                }
            }
        }
    }
    
    private func transitionToStep(_ step: OnboardingSteps) {
        let currentSeconds = player.currentTime().seconds
        let targetSeconds = step.targetTime
        
        if targetSeconds > currentSeconds {
            player.rate = 1.0
        } else if targetSeconds < currentSeconds {
            player.rate = -1.0
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
}


#Preview {
    OnboardingScreenView()
}
