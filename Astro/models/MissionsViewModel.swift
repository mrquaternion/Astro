//
//  MissionsViewModel.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-22.
//

import Combine

@MainActor
final class MissionsViewModel: ObservableObject {
    
    /// The array of launches to use in the view.
    @Published var launches: LaunchFeatureCollection?
    
    /// The current state of launches fetching.
    @Published private(set) var areLaunchesBeingFetch = false
    
    /// Value used for error.
    @Published var error: Error?

    /// Loads launches only when this retained view model has no collection yet.
    func loadLaunchesIfNeeded(networkMonitor: NetworkMonitor) async throws {
        guard launches == nil, !areLaunchesBeingFetch else { return }
        try await fetchLaunchesMetadata(networkMonitor: networkMonitor)
    }
    
    func fetchLaunchesMetadata(networkMonitor: NetworkMonitor) async throws {
        areLaunchesBeingFetch = true
        defer { areLaunchesBeingFetch = false }
        
        guard networkMonitor.isConnected else {
            self.error = AstroError.noWifiConnection
            return
        }
        
        self.launches = try await LaunchFeatureCollection.fetchLaunches()
        self.error = nil
    }
}
