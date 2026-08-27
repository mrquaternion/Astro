//
//  CustomTabBar.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-04.
//

import SwiftUI
import UIKit

struct CustomTabBar<TabItemView: View>: UIViewRepresentable {
    /// The size of the tab bar.
    var size: CGSize
    
    /// The foreground color of a tab bar item on selection.
    var activeTint: Color = .green
    
    /// The background color of a tab bar item on selection.
    var barTint: Color = .gray.opacity(0.3)
    
    /// The available tabs depending on selected mode.
    var tabs: [CustomTab]
    
    /// The current selected tab.
    @Binding var activeTab: CustomTab

    /// The scroll view currently underneath the tab bar.
    var scrollView: UIScrollView? = nil
    
    /// The view to display for each tab bar item.
    @ViewBuilder var tabItemView: (CustomTab, Bool) -> TabItemView
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UISegmentedControl {
        let items = tabs.map(\.rawValue)
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        
        // render the views for each tab bar items
        for (index, tab) in tabs.enumerated() {
            let renderer = ImageRenderer(content: tabItemView(tab, tab == activeTab))
            
            renderer.scale = 2
            
            let image = renderer.uiImage?.withRenderingMode(.alwaysOriginal)
            control.setImage(image, forSegmentAt: index)
        }
        
        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView && subview != control.subviews.last {
                    subview.alpha = 0
                }
            }
        }
        
        control.selectedSegmentTintColor = UIColor(barTint)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor(activeTint)
        ], for: .selected)
        
        control.addTarget(context.coordinator, action: #selector(context.coordinator.tabSelected(_:)), for: .valueChanged)
        context.coordinator.scrollEdgeInteraction.scrollView = scrollView
        control.addInteraction(context.coordinator.scrollEdgeInteraction)
        context.coordinator.currentTabs = tabs
        return control
    }
    
    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        // re-assign the coordinator's parent so 'tabs' is updated
        context.coordinator.parent = self
        context.coordinator.scrollEdgeInteraction.scrollView = scrollView
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            uiView.selectedSegmentTintColor = UIColor(barTint)
        }
        
        UIView.performWithoutAnimation {
            if context.coordinator.currentTabs != tabs {
                uiView.removeAllSegments()
                for (index, tab) in tabs.enumerated() {
                    uiView.insertSegment(withTitle: nil, at: index, animated: false)
                    setImage(for: tab, at: index, in: uiView)
                }
                context.coordinator.currentTabs = tabs
            } else {
                for (index, tab) in tabs.enumerated() {
                    setImage(for: tab, at: index, in: uiView)
                }
            }
            
            if let selectedIndex = tabs.firstIndex(of: activeTab) {
                uiView.selectedSegmentIndex = selectedIndex
            } else {
                uiView.selectedSegmentIndex = UISegmentedControl.noSegment
            }
            
            uiView.layoutIfNeeded()
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISegmentedControl, context: Context) -> CGSize? {
        return size
    }
    
    private func setImage(for tab: CustomTab, at index: Int, in control: UISegmentedControl) {
        let renderer = ImageRenderer(content: tabItemView(tab, tab == activeTab))
        renderer.scale = 2
        
        let image = renderer.uiImage?.withRenderingMode(.alwaysOriginal)
        control.setImage(image, forSegmentAt: index)
    }
    
    class Coordinator: NSObject {
        /// The representable instance that owns this coordinator.
        var parent: CustomTabBar
        
        /// The tab set currently installed in the segmented control.
        var currentTabs: [CustomTab]

        /// Shapes the selected scroll view's bottom-edge effect around this control.
        let scrollEdgeInteraction: UIScrollEdgeElementContainerInteraction
        
        init(parent: CustomTabBar) {
            self.parent = parent
            self.currentTabs = parent.tabs
            self.scrollEdgeInteraction = UIScrollEdgeElementContainerInteraction()
            self.scrollEdgeInteraction.edge = .bottom
        }
        
        /// Updates the current tab with the newly selected tab.
        @objc func tabSelected(_ control: UISegmentedControl) {
            guard parent.tabs.indices.contains(control.selectedSegmentIndex) else { return }
            parent.activeTab = parent.tabs[control.selectedSegmentIndex]
        }
    }
}

#Preview {
    @Previewable @State var activeTab: CustomTab = .news
    
    GeometryReader {
        CustomTabBar(size: $0.size, tabs: [.news, .missions, .learn], activeTab: $activeTab) { tab, isSelected in
            VStack {
                Image(systemName: tab.symbol)
                    .font(.title3)
                
                Text(tab.localizedTitle)
                    .font(.system(size: 10))
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .blue.mix(with: .white, by: 0.15) : .mapGlassBackgroundContent())
            .symbolVariant(.fill)
        }
        .background(Capsule().fill(.mapGlassBackground()))
        .glassEffect(.clear.interactive(), in: .capsule)
    }
    .frame(width: 200, height: CustomTabBarLayout.height)
}
