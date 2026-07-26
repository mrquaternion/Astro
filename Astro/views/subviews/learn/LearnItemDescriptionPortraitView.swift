//
//  LearnItemDescriptionPortraitView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-10.
//

import SwiftUI

struct LearnItemDescriptionPortraitView: View {
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
            TabView {
                ForEach(items.ordered, id: \.id) { content in
                    ScrollView {
                        content.destination
                            .padding(layout.textOuterPadding)
                            .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicators(.hidden)
                }
            }
            .tabViewStyle(.page)
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
    
    LearnItemDescriptionPortraitView(items: secondaryContents)
}
