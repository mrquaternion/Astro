//
//  LearnItemDescriptionViews.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-10.
//

import SwiftUI

struct LearnItemSummaryView: View {
    /// Environment value supplying colorScheme.
    @Environment(\.colorScheme) var colorScheme
    
    /// Environment value supplying isPad.
    @Environment(\.isPad) var isPad
    
    /// Value used for component.
    var component: CachedLearnAsset.LearnComponent
    
    /// Value used for layout.
    private var layout: LearnDescriptionLayoutConstants {
        isPad ? LearnDescriptionLayoutConstants.ipad : LearnDescriptionLayoutConstants.iphone
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    summaryTitle
                    summaryBadges
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    summaryTitle
                    summaryBadges
                }
            }
            
            Text(component.summary)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(layout.textLineSpacing)
        }
    }
    
    /// View content rendered for summaryTitle.
    private var summaryTitle: some View {
        Text(component.displayName)
            .font(.title)
            .bold()
            .fixedSize(horizontal: false, vertical: true)
    }
    
    /// View content rendered for summaryBadges.
    @ViewBuilder
    private var summaryBadges: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                badges
            }
            
            VStack(alignment: .leading, spacing: 8) {
                badges
            }
        }
    }
    
    /// View content rendered for badges.
    @ViewBuilder
    private var badges: some View {
        if let group = component.group {
            Text(group)
                .font(.footnote)
                .foregroundStyle(colorScheme == .light ? .green.mix(with: .black, by: 0.1) : .white)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(.green.opacity(0.1), in: .capsule)
        }
        
        Text(component.category)
            .font(.footnote)
            .foregroundStyle(colorScheme == .light ? .blue.mix(with: .black, by: 0.1) : .white)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(.blue.opacity(0.1), in: .capsule)
    }
}

struct LearnItemDetailsView: View {
    /// Environment value supplying isPad.
    @Environment(\.isPad) var isPad
    
    /// Value used for component.
    var component: CachedLearnAsset.LearnComponent
    
    /// Value used for layout.
    private var layout: LearnDescriptionLayoutConstants {
        isPad ? LearnDescriptionLayoutConstants.ipad : LearnDescriptionLayoutConstants.iphone
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            ForEach(component.details, id: \.id) { detail in
                VStack(alignment: .leading, spacing: 16) {
                    Text(detail.title)
                        .font(.title2)
                        .bold()
                    
                    Text(detail.body)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(layout.textLineSpacing)
                }
            }
        }
    }
}

struct LearnItemTimelineView: View {
    /// Value used for component.
    var component: CachedLearnAsset.LearnComponent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("learn_timeline".localizedFirstCapitalized)
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(component.timeline.enumerated()), id: \.offset) { index, event in
                    TimelineRowView(event: event, isLast: index == component.timeline.count - 1)
                }
            }
        }
    }
}

private struct RowHeightKey: PreferenceKey {
    /// Shared value used for defaultValue.
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct TimelineRowView: View {
    /// Value used for event.
    let event: CachedLearnAsset.LearnComponentTimelineEvent
    /// Whether isLast is currently true.
    let isLast: Bool

    /// Value used for circleSize.
    private let circleSize: CGFloat = 20
    /// Value used for outerCircleSize.
    private let outerCircleSize: CGFloat = 32
    /// Value used for lineWidth.
    private let lineWidth: CGFloat = 2
    /// Value used for bottomRowInset.
    private let bottomRowInset: CGFloat = 30

    /// Mutable view state tracking contentHeight.
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(.skyBackgroundLightTone)
                    .frame(width: circleSize, height: circleSize)
                    .background {
                        if isLast {
                            Circle()
                                .fill(.skyBackgroundLightTone.opacity(0.4))
                                .frame(width: outerCircleSize, height: outerCircleSize)
                        }
                    }

                if !isLast {
                    Rectangle()
                        .fill(.primary)
                        .frame(width: lineWidth, height: max(0, contentHeight - circleSize + bottomRowInset))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.date, format: .dateTime.year().month(.abbreviated).day(.twoDigits))
                    .font(.headline)

                Text(event.event)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, isLast ? 0 : 24)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: RowHeightKey.self, value: proxy.size.height)
                }
            )
        }
        .onPreferenceChange(RowHeightKey.self) { contentHeight = $0 }
    }
}

#Preview {
    LearnItemTimelineView(component: CachedLearnAsset.LearnComponent.mock)
        .padding()
        .background(Color(.secondarySystemBackground))
}

struct LearnItemExtrasView: View {
    /// Value used for component.
    var component: CachedLearnAsset.LearnComponent
    
    /// Value used for agenciesResourcesName.
    private var agenciesResourcesName: [String] {
        component.agencies.map { "\($0.lowercased())-logo" }
    }
    
    /// Value used for logoColumns.
    private var logoColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 64), spacing: 32, alignment: .leading)]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                Text("learn_composed_of".localizedFirstCapitalized)
                    .font(.title2.weight(.semibold))
                
                Text(component.materials.map({ $0.capitalized }).joined(separator: ", "))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("learn_manufacturers".localizedFirstCapitalized)
                    .font(.title2.weight(.semibold))
                
                Text(component.manufacturers.joined(separator: ", "))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("learn_contributions".localizedFirstCapitalized)
                    .font(.title2.weight(.semibold))
                
                LazyVGrid(columns: logoColumns, alignment: .leading, spacing: 12) {
                    ForEach(agenciesResourcesName, id: \.self) { resourceName in
                        Image(resourceName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                    }
                }
            }
        }
    }
}

enum LearnDescriptionLayoutConstants {
    case ipad
    case iphone
    
    /// Value used for textOuterPadding.
    var textOuterPadding: CGFloat {
        switch self {
        case .ipad: 36
        case .iphone: 18
        }
    }
    
    /// Value used for textLineSpacing.
    var textLineSpacing: CGFloat {
        switch self {
        case .ipad: 8
        case .iphone: 4
        }
    }
}
