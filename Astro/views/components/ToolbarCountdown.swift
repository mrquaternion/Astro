//
//  ToolbarCountdown.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-23.
//

import SwiftUI
import NTPClient

struct ToolbarCountdown: View {
    /// Mutable view state tracking currentDate.
    @State private var currentDate: Date?
    /// Mutable view state tracking ntpError.
    @State private var ntpError: Error?

    /// Value used for net.
    let net: Date
    
    /// Value used for displayTime.
    var displayTime: SplitFlapTime {
        guard let currentDate else { return SplitFlapTime.zero }
        return SplitFlapTime(currentDate: currentDate, targetDate: net)
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(displayTime.components.enumerated()), id: \.offset) { index, component in
                HStack(spacing: .zero) {
                    ForEach(Array(component.digits.enumerated()), id: \.offset) { _, digit in
                        Text(digit)
                    }
                }
                
                if index != displayTime.components.count - 1 {
                    Text(":")
                }
            }
        }
        .monospacedDigit()
        .fontDesign(.monospaced)
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
    ToolbarCountdown(net: .now)
}
