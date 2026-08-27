//
//  OnboardingScreenView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-30.
//

import SwiftUI
import AVKit
import Combine

private final class OnboardingVideoController: ObservableObject {
    let player: AVQueuePlayer
    private let looper: AVPlayerLooper
    
    init() {
        guard let url = Bundle.main.url(forResource: "onboarding_animation_24fps", withExtension: "mov") else {
            fatalError("Video file not found")
        }
        
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        player.isMuted = true
        
        self.player = player
        self.looper = AVPlayerLooper(player: player, templateItem: item)
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
}

private final class OnboardingPlayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct OnboardingVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> OnboardingPlayerView {
        let view = OnboardingPlayerView()
        view.playerLayer.player = player
        return view
    }
    
    func updateUIView(_ uiView: OnboardingPlayerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

enum OnboardingSteps: CaseIterable {
    case `init`
    case first
    case second
    case third
    case fourth
    case fifth
    
    func next() -> Self? {
        let cases = Self.allCases
        guard let index = cases.firstIndex(of: self), index < cases.count - 1 else { return nil }
        return cases[index + 1]
    }
    
    var tabEquivalent: CustomTab? {
        get {
            switch self {
            case .`init`: nil
            case .first: .home
            case .second: .news
            case .third: .missions
            case .fourth: .learn
            case .fifth: nil
            }
        }
        set {
            switch newValue {
            case nil: self = .`init`
            case .home: self = .first
            case .news: self = .second
            case .missions: self = .third
            case .learn: self = .fourth
            default: self = .`init`
            }
        }
    }
}

struct OnboardingStepContent {
    let icon: String
    let title: String
    let description: String
}

extension OnboardingSteps {
    var content: OnboardingStepContent? {
        switch self {
        case .`init`:
            return .init(
                icon: "sparkles",
                title: "onboarding_welcome_title".localizedFirstCapitalized,
                description: "onboarding_welcome_description".localizedFirstCapitalized
            )
        case .first:
            return .init(
                icon: "house",
                title: "onboarding_track_title".localizedFirstCapitalized,
                description: "onboarding_track_description".localizedFirstCapitalized
            )
        case .second:
            return .init(
                icon: "newspaper",
                title: "onboarding_news_title".localizedFirstCapitalized,
                description: "onboarding_news_description".localizedFirstCapitalized
            )
        case .third:
            return .init(
                icon: "paperplane",
                title: "onboarding_missions_title".localizedFirstCapitalized,
                description: "onboarding_missions_description".localizedFirstCapitalized
            )
        case .fourth:
            return .init(
                icon: "book",
                title: "onboarding_learn_title".localizedFirstCapitalized,
                description: "onboarding_learn_description".localizedFirstCapitalized
            )
        case .fifth:
            return nil
        }
    }
}

struct OnboardingScreenView: View {
    
    /// Mutable view state tracking currentStep.
    @State private var currentStep: OnboardingSteps = .`init`
    
    @State private var showReadyToEnterPrompt: Bool = false
    
    @State private var activeTabIndex: Int = 0
    
    /// Looped background video independent from onboarding navigation.
    @StateObject private var videoController = OnboardingVideoController()
    
    var onFinish: () -> Void
    
    var body: some View {
        ZStack {
            OnboardingVideoPlayer(player: videoController.player)
                .allowsHitTesting(false)
                .ignoresSafeArea()
            
            if let content = currentStep.content {
                currentStepContent(content)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: currentStep == .`init` ? .center : .top
                    )
                    .padding(.top, currentStep == .`init` ? 0 : 32)
            }
            
            Group {
                if showReadyToEnterPrompt {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white)
                            .symbolEffect(.pulse)
                        
                        Text("onboarding_ready_title".localizedFirstCapitalized)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("onboarding_launch_subtitle".localizedFirstCapitalized)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Button {
                            onFinish()
                        } label: {
                            Text("onboarding_enter_button".localizedFirstCapitalized)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 28)
                                .background(Capsule().fill(Color(.systemBackground)))
                        }
                        .padding(.top, 8)
                        .buttonStyle(.plain)
                    }
                    .padding(24)
                    .frame(maxWidth: 320)
                    .background(RoundedRectangle(cornerRadius: 24).fill(.mapGlassBackground()))
                    .glassEffect(.clear, in: .rect(cornerRadius: 24))
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 32) {
                if currentStep != .`init` && currentStep != .fifth {
                    templateTabBar
                }
                
                forwardButton
            }
            .padding(.horizontal)
        }
        .onAppear {
            videoController.play()
        }
        .onDisappear {
            videoController.pause()
        }
        .onChange(of: currentStep) { _, newStep in
            if newStep == .fifth {
                withAnimation(.easeInOut(duration: 1.5)) {
                    showReadyToEnterPrompt = true
                }
                return
            }
            
            let tabs: [CustomTab] = [.home, .news, .missions, .learn]
            if let tab = newStep.tabEquivalent, let newIndex = tabs.firstIndex(of: tab) {
                withAnimation(.easeInOut(duration: 1.5)) {
                    activeTabIndex = newIndex
                }
            }
        }
    }
    
    private func currentStepContent(_ content: OnboardingStepContent) -> some View {
        VStack(spacing: 6) {
            Image(systemName: content.icon)
                .font(.title2)
                .symbolVariant(.fill)
                .foregroundStyle(.white)
            Text(content.title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(content.description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: 600)
        .background(RoundedRectangle(cornerRadius: 16).fill(.mapGlassBackground()))
        .glassEffect(.clear, in: .rect(cornerRadius: 16))
        .id(currentStep)
        .transition(.blurReplace)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var templateTabBar: some View {
        HStack(spacing: 8) {
            ZStack {
                Image(systemName: CustomTab.home.symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolVariant(currentStep.tabEquivalent == .home ? .fill : .none)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: CustomTabBarLayout.height, height: CustomTabBarLayout.height)
            .contentShape(.circle)
            .background(Circle().fill(.mapGlassBackground()))
            .glassEffect(.clear, in: .circle)
            .accessibilityLabel("tab_home".localizedFirstCapitalized)
            
            GeometryReader {
                CustomTabBar(
                    size: $0.size,
                    tabs: [.news, .missions, .learn],
                    activeTab: Binding(
                        get: { currentStep.tabEquivalent ?? .home },
                        set: { currentStep.tabEquivalent = $0 }
                    )
                ) { tab, isSelected in
                    VStack {
                        Image(systemName: tab.symbol)
                            .font(.title3)
                        
                        Text(tab.localizedTitle)
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(isSelected ? .blue.mix(with: .white, by: 0.2) : .mapGlassBackgroundContent())
                    .symbolVariant(.fill)
                }
                .background(Capsule().fill(.mapGlassBackground()))
                .glassEffect(.clear, in: .capsule)
                .allowsHitTesting(false)
            }
            .frame(height: CustomTabBarLayout.height)
        }
        .frame(maxWidth: 600)
        .overlay(alignment: .top) {
            GeometryReader { barGeometry in
                let homeWidth = CustomTabBarLayout.height
                let segmentedBarStart = homeWidth + 8
                let segmentedTabWidth = (barGeometry.size.width - segmentedBarStart) / 3
                let arrowX = activeTabIndex == 0
                    ? homeWidth / 2
                    : segmentedBarStart
                        + segmentedTabWidth * CGFloat(activeTabIndex - 1)
                        + segmentedTabWidth / 2
                
                Image(systemName: "arrow.down")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .position(x: arrowX, y: -15)
            }
        }
    }
    
    @ViewBuilder
    private var forwardButton: some View {
        ZStack {
            HStack(spacing: 6) {
                ForEach(OnboardingSteps.allCases, id: \.self) { step in
                    Circle()
                        .fill(
                            step == currentStep
                            ? AnyShapeStyle(.white)
                            : AnyShapeStyle(.secondary.opacity(0.8))
                        )
                        .frame(width: 6, height: 6)
                }
            }
            
            HStack {
                Spacer()
                
                Button {
                    if let nextStep = currentStep.next() {
                        withAnimation(.easeInOut(duration: 1.5)) {
                            currentStep = nextStep
                        }
                    }
                } label: {
                    Image(systemName: "arrow.right")
                        .foregroundStyle(currentStep == .fifth ? .gray : .primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(.capsule)
                }
                .disabled(currentStep == .fifth)
            }
        }
    }
}


#Preview {
    OnboardingScreenView(onFinish: { })
}
