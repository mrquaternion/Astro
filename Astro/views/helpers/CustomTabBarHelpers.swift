//
//  CustomTabBarHelpers.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-04.
//

import SwiftUI

enum CustomMode: String, CaseIterable {
    case exploration
    case photography
    
    /// The SF Symbol used for this mode's control.
    var symbol: String {
        switch self {
        case .exploration: "binoculars"
        case .photography: "camera"
        }
    }
    
    /// The tabs that should be available while this mode is active.
    var tabs: [CustomTab] {
        switch self {
        case .exploration:
            [.news, .missions, .learn]
        case .photography:
            [.lookup, .community]
        }
    }
}

enum CustomTab: String, CaseIterable {
    case home
    case news = "News"
    case missions = "Missions"
    case learn = "Learn"
    
    case lookup = "Lookup"
    case community = "Community"
    
    /// The SF Symbol used for this tab.
    var symbol: String {
        switch self {
        case .home: "house"
        case .missions: "paperplane"
        case .news: "newspaper"
        case .learn: "book"
        case .lookup: "magnifyingglass"
        case .community: "person.2"
        }
    }
    
    /// The tab's index in the complete tab list.
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
