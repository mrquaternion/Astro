//
//  SplitFlapDisplay.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-21.
//

import SwiftUI
import NTPClient

struct SplitFlapDisplay: View {
    
    /// Mutable view state tracking currentDate.
    @State private var currentDate: Date?
    /// Mutable view state tracking ntpError.
    @State private var ntpError: Error?

    /// Value used for net.
    let net: Date
    /// Value used for withTimeComponentDescription.
    let withTimeComponentDescription: Bool
    
    /// Value used for displayTime.
    var displayTime: SplitFlapTime {
        guard let currentDate else { return SplitFlapTime.zero }
        return SplitFlapTime(currentDate: currentDate, targetDate: net)
    }
    
    init(net: Date = .init(timeIntervalSinceNow: 60), withTimeComponentDescription: Bool = true) {
        self.net = net
        self.withTimeComponentDescription = withTimeComponentDescription
    }
  
    var body: some View {
        HStack(spacing: 12) {
            ForEach(displayTime.components, id: \.unit) { component in
                VStack {
                    HStack(spacing: 4) {
                        ForEach(Array(component.digits.enumerated()), id: \.offset) { _, digit in
                            FlapDigit(value: digit)
                        }
                    }
                    
                    if withTimeComponentDescription {
                        Text(component.unit.rawValue.capitalized)
                            .font(.footnote)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .task {
            do {
                try await autoUpdatingDate()
            } catch {
                ntpError = error
            }
        }
    }
    
    func autoUpdatingDate() async throws {
        let config = NTPClient.Config(version: .v4)
        let ntp = NTPClient(
            config: config,
            server: "time.apple.com"
        )
        let response = try await ntp.query(timeout: .seconds(10))
        let (seconds, attoseconds) = response.offset.components
        let offsetTimeInterval = TimeInterval(seconds) + TimeInterval(attoseconds) * 1e-18
        
        while true {
            let now = Date.now
            currentDate = now + offsetTimeInterval
            try await Task.sleep(for: .milliseconds(33))
        }
    }
}

#Preview {
    @Previewable @Environment(\.colorScheme) var colorScheme
    
    SplitFlapDisplay()
}

struct FlapDigit: View {
    /// Environment value supplying colorScheme.
    @Environment(\.colorScheme) var colorScheme
    
    /// Value used for value.
    let value: String
    
    /// Mutable view state tracking settledValue.
    @State private var settledValue: String
    /// Mutable view state tracking outgoingValue.
    @State private var outgoingValue: String
    /// Mutable view state tracking incomingValue.
    @State private var incomingValue: String
    /// Mutable view state tracking queuedValue.
    @State private var queuedValue: String?
    /// Mutable view state tracking isFlipping.
    @State private var isFlipping = false
    /// Mutable view state tracking topAngle.
    @State private var topAngle: Double = 0
    /// Mutable view state tracking bottomAngle.
    @State private var bottomAngle: Double = 90
    
    /// Value used for width.
    let width: CGFloat = 40
    /// Value used for height.
    let height: CGFloat = 60
    /// Value used for topFlipDuration.
    let topFlipDuration = 0.25
    /// Value used for bottomFlipDuration.
    let bottomFlipDuration = 0.10
    
    /// Value used for flapTopColor.
    let flapTopColor: Color = .init(red: 51 / 255, green: 43 / 255, blue: 44 / 255)
    /// Value used for flapBotColor.
    let flapBotColor: Color = .init(red: 68 / 255, green: 64 / 255, blue: 64 / 255)
    
    init(value: String) {
        self.value = value
        _settledValue = State(initialValue: value)
        _outgoingValue = State(initialValue: value)
        _incomingValue = State(initialValue: value)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                half(isFlipping ? incomingValue : settledValue, top: true)
                half(isFlipping ? outgoingValue : settledValue, top: false)
            }
            
            half(incomingValue, top: false)
                .rotation3DEffect(
                    .degrees(bottomAngle),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.4
                )
                .frame(width: width, height: height, alignment: .bottom)
                .opacity(isFlipping ? 1 : 0)
                .zIndex(2)
            
            half(outgoingValue, top: true)
                .rotation3DEffect(
                    .degrees(topAngle),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.4
                )
                .frame(width: width, height: height, alignment: .top)
                .opacity(isFlipping ? 1 : 0)
                .zIndex(3)
            
            hinge
                .zIndex(4)
            
            HStack(spacing: .zero) {
                Rectangle()
                    .fill(
                        colorScheme == .light
                            ? AnyShapeStyle(Color(.lightGray))
                            : AnyShapeStyle(.tertiary)
                    )
                    .frame(width: 2, height: 8)
                
                Spacer()
                
                Rectangle()
                    .fill(
                        colorScheme == .light
                            ? AnyShapeStyle(Color(.lightGray))
                            : AnyShapeStyle(.tertiary)
                    )
                    .frame(width: 2, height: 8)
            }
            .zIndex(5)
        }
        .frame(width: width, height: height)
        .clipped()
        .onChange(of: value) { _, newValue in
            flip(to: newValue)
        }
    }
    
    func flip(to newValue: String) {
        if isFlipping {
            queuedValue = newValue
            return
        }
        
        guard newValue != settledValue else { return }
        
        outgoingValue = settledValue
        incomingValue = newValue
        topAngle = 0
        bottomAngle = 90
        isFlipping = true
        
        DispatchQueue.main.async {
            withAnimation(.easeIn(duration: topFlipDuration)) {
                topAngle = -90
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + topFlipDuration) {
            withAnimation(.easeOut(duration: bottomFlipDuration)) {
                bottomAngle = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + topFlipDuration + bottomFlipDuration) {
            settledValue = newValue
            isFlipping = false
            topAngle = 0
            bottomAngle = 90
            
            if let queuedValue, queuedValue != settledValue {
                self.queuedValue = nil
                flip(to: queuedValue)
            } else {
                queuedValue = nil
            }
        }
    }
    
    @ViewBuilder
    private func half(_ digit: String, top: Bool) -> some View {
        let outerCorners = UnevenRoundedRectangle(
            topLeadingRadius: top ? 4 : 0,
            bottomLeadingRadius: top ? 0 : 4,
            bottomTrailingRadius: top ? 0 : 4,
            topTrailingRadius: top ? 4 : 0
        )
        
        Text(digit)
            .font(.title.weight(.regular))
            .fontDesign(.monospaced)
            .monospacedDigit()
            .foregroundStyle(.white)
            .frame(width: width, height: height)
            .background(
                LinearGradient(
                    colors: [flapTopColor, flapBotColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .shadow(.inner(color: .black.opacity(0.5), radius: 20))
            )
            .overlay {
                if top {
                    LinearGradient(
                        colors: [.white.opacity(0.1), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.24)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .frame(height: height / 2, alignment: top ? .top : .bottom)
            .clipShape(outerCorners)
    }
    
    /// View content rendered for hinge.
    var hinge: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.black.opacity(0.6))
                .frame(height: 1)
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
        }
        .frame(width: width, height: 2)
    }
}

struct TimeComponent {
    /// Value used for value.
    let value: Int
    /// Value used for unit.
    let unit: TimeUnit
    
    enum TimeUnit: String, Hashable {
        case days, hours, minutes, seconds
    }
    
    /// Value used for digits.
    var digits: [String] {
        String(format: "%02d", value).map(String.init)
    }
}

struct SplitFlapTime {
    /// Value used for components.
    var components: [TimeComponent]
    
    /// Whether isCountdownDone is currently true.
    var isCountdownDone: Bool = false
    
    /// Shared value used for zero.
    static let zero = SplitFlapTime(components: [
        .init(value: 0, unit: .days),
        .init(value: 0, unit: .hours),
        .init(value: 0, unit: .minutes),
        .init(value: 0, unit: .seconds)
    ])
    
    init(components: [TimeComponent]) {
        self.components = components
    }
    
    init(currentDate: Date, targetDate: Date, calendar: Calendar = .current) {
        isCountdownDone = currentDate >= targetDate
            
        if isCountdownDone {
            components = [
                .init(value: 0, unit: .days),
                .init(value: 0, unit: .hours),
                .init(value: 0, unit: .minutes),
                .init(value: 0, unit: .seconds),
            ]
        } else {
            let diff = calendar.dateComponents(
                Set([.day, .hour, .minute, .second]),
                from: currentDate,
                to: targetDate
            )
            components = [
                .init(value: diff.day ?? 0, unit: .days),
                .init(value: diff.hour ?? 0, unit: .hours),
                .init(value: diff.minute ?? 0, unit: .minutes),
                .init(value: diff.second ?? 0, unit: .seconds),
            ]
        }
    }
}
