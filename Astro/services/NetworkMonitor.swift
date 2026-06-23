//
//  NetworkMonitor.swift
//  Astro
//
//  Generated with Claude AI on 2026-06-10.
//

import Network
import Combine

/// Monitors network connectivity and publishes changes to observers.
/// Works with both SwiftUI (via @StateObject / @ObservedObject) and UIKit (via Combine or closure).
final class NetworkMonitor: ObservableObject {

    // MARK: - Published State

    /// `true` when the device has a usable network path.
    @Published private(set) var isConnected: Bool = false

    /// `true` when the active connection goes through cellular or a cellular hotspot.
    @Published private(set) var isExpensive: Bool = false

    /// The type of interface currently in use (wifi, cellular, wiredEthernet, loopback, other).
    @Published private(set) var connectionType: NWInterface.InterfaceType? = nil

    // MARK: - Private

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.app.NetworkMonitor")

    // MARK: - Init / Deinit

    /// Creates a monitor that watches **all** interface types.
    init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    /// Creates a monitor restricted to a single interface type.
    /// - Parameter interfaceType: e.g. `.wifi`, `.cellular`, `.wiredEthernet`
    init(requiredInterfaceType interfaceType: NWInterface.InterfaceType) {
        monitor = NWPathMonitor(requiredInterfaceType: interfaceType)
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Private Helpers

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            let connected = path.status == .satisfied
            let expensive = path.isExpensive
            let type = Self.currentInterfaceType(for: path)

            // Always publish on the main thread so the UI updates safely.
            DispatchQueue.main.async {
                self.isConnected     = connected
                self.isExpensive     = expensive
                self.connectionType  = type
            }
        }

        monitor.start(queue: queue)
    }

    /// Returns the first recognised interface type for the given path.
    private static func currentInterfaceType(for path: NWPath) -> NWInterface.InterfaceType? {
        let types: [NWInterface.InterfaceType] = [.wifi, .cellular, .wiredEthernet, .loopback]
        return types.first { path.usesInterfaceType($0) }
    }
}
