//
//  DateFormatterHelpers.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-22.
//

import Foundation

enum DateFormatterHelpers {
    static func date(from rawValue: String) -> Date {
        let internetDateTimeFormatter = ISO8601DateFormatter()
        internetDateTimeFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = internetDateTimeFormatter.date(from: rawValue) {
            return date
        }
        
        let fullDateFormatter = ISO8601DateFormatter()
        fullDateFormatter.formatOptions = [.withFullDate]
        
        return fullDateFormatter.date(from: rawValue) ?? .distantPast
    }
}
