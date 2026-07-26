//
//  SubscriptionHelper.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-23.
//

import Foundation

enum SubscriptionContent {
    case satellite(fileName: String)
    case newsSource(String)
    case offlineDownload
}

enum SubscriptionHelper {
    /// Shared value used for freeSatelliteFileNames.
    static let freeSatelliteFileNames: Set<String> = [
        "iss_lowpoly.glb"
    ]
    
    /// Shared value used for freeNewsSourceNames.
    static let freeNewsSourceNames: Set<String> = [
        "NASA"
    ]
    
    /// Shared value used for canDownloadOfflineWithoutSubscription.
    static let canDownloadOfflineWithoutSubscription = false
    
    static func isEligibleTo(
        _ content: SubscriptionContent,
        with store: SubscriptionManager
    ) -> Bool {
        store.hasActivateSubscription || isFree(content)
    }
    
    static func isFree(_ content: SubscriptionContent) -> Bool {
        switch content {
        case .satellite(let fileName):
            containsCaseInsensitive(fileName, in: freeSatelliteFileNames)
            
        case .newsSource(let sourceName):
            containsCaseInsensitive(sourceName, in: freeNewsSourceNames)
            
        case .offlineDownload:
            canDownloadOfflineWithoutSubscription
        }
    }
    
    private static func containsCaseInsensitive(
        _ value: String,
        in allowedValues: Set<String>
    ) -> Bool {
        allowedValues.contains {
            $0.localizedCaseInsensitiveCompare(value) == .orderedSame
        }
    }
}
