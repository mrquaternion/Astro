//
//  AstroTests.swift
//  AstroTests
//
//  Created by Mathias La Rochelle on 2026-06-02.
//

import Testing
@testable import Astro

struct AstroTests {
    @Test func freeSatelliteAccessIsCaseInsensitive() {
        #expect(SubscriptionHelper.isFree(.satellite(fileName: "ISS_LOWPOLY.GLB")))
        #expect(!SubscriptionHelper.isFree(.satellite(fileName: "hubble.glb")))
    }
    
    @Test func freeNewsSourceAccessIsCaseInsensitive() {
        #expect(SubscriptionHelper.isFree(.newsSource("nasa")))
        #expect(!SubscriptionHelper.isFree(.newsSource("SpaceNews")))
    }
    
    @Test func offlineDownloadsRequireSubscriptionByDefault() {
        #expect(!SubscriptionHelper.isFree(.offlineDownload))
    }
}
