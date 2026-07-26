//
//  AstroError.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-08.
//

import Foundation

enum AstroError: LocalizedError {
    case noWifiConnection
    case noActiveSubscription
    case unableToFetchProducts(message: String)
    case unableToRestorePurchases(message: String)
    
    /// Value used for description.
    var description: String {
        switch self {
        case .noWifiConnection: "No internet connection available."
        case .noActiveSubscription : "Can't perform this action, no subscription active."
        case .unableToFetchProducts(let message): "Unable to fetch products: \(message)"
        case .unableToRestorePurchases(let message): "Unable to restore purchases: \(message)"
        }
    }
    
    /// Value used for symbol.
    var symbol: String {
        switch self {
        case .noWifiConnection: "wifi.slash"
        case .noActiveSubscription: "arrow.down.circle.badge.xmark"
        case .unableToFetchProducts(_): "cart.badge.questionmark"
        case .unableToRestorePurchases(_): "storefront"
        }
    }
}
