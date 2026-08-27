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
        case .noWifiConnection: "error_no_connection".localizedFirstCapitalized
        case .noActiveSubscription: "error_no_subscription".localizedFirstCapitalized
        case .unableToFetchProducts(let message):
            "error_fetch_products_format".localizedFormat(message)
        case .unableToRestorePurchases(let message):
            "error_restore_purchases_format".localizedFormat(message)
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
