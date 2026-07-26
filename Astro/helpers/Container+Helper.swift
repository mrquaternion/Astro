//
//  Container+Helper.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-09.
//

import SwiftData

@MainActor
/// In-memory model container used by SwiftUI previews.
let previewContainer: ModelContainer = {
    /// Value used for schema.
    let schema = Schema(AppConstants.modelTypes)
    /// Value used for config.
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [config])
}()
