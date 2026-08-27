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
        case .exploration: "moon"
        case .photography: "camera.aperture"
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
    
    /// Localized title displayed for this tab.
    var localizedTitle: String {
        switch self {
        case .home: "tab_home".localizedFirstCapitalized
        case .news: "tab_news".localizedFirstCapitalized
        case .missions: "tab_missions".localizedFirstCapitalized
        case .learn: "tab_learn".localizedFirstCapitalized
        case .lookup: "tab_lookup".localizedFirstCapitalized
        case .community: "tab_community".localizedFirstCapitalized
        }
    }
    
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
