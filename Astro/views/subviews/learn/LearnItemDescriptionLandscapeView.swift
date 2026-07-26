//
//  LearnItemDescriptionLandscapeView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-08.
//

import SwiftUI

struct LearnItemDescriptionLandscapeView: View {
    /// Environment value supplying isPad.
    @Environment(\.isPad) var isPad
    
    /// Value used for items.
    var items: LearnDescriptionItemContainer
    
    /// Value used for layout.
    private var layout: LearnDescriptionLayoutConstants {
        isPad ? LearnDescriptionLayoutConstants.ipad : LearnDescriptionLayoutConstants.iphone
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    items.summary.destination
                    
                    if let details = items.details {
                        details.destination
                    }
                    
                    items.timeline.destination
                    
                    items.extras.destination
                }
                .padding(layout.textOuterPadding)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
            .ignoresSafeArea()
        }
    }
}

#Preview {
    let component = {
        let c =  CachedLearnAsset.LearnComponent.mock
        c.summary = .loremExtraLarge
        return c
    }()

    /// Value used for secondaryContents.
    var secondaryContents: LearnDescriptionItemContainer {
        LearnDescriptionItemContainer(
            summary: LearnDescriptionItem(
                destination: AnyView(LearnItemSummaryView(component: component))
            ),
            details: LearnDescriptionItem(
                destination: AnyView(LearnItemDetailsView(component: component))
            ),
            timeline: LearnDescriptionItem(
                destination: AnyView(LearnItemTimelineView(component: component))
            ),
            extras: LearnDescriptionItem(
                destination: AnyView(LearnItemExtrasView(component: component))
            )
        )
    }
    
    LearnItemDescriptionLandscapeView(items: secondaryContents)
}
