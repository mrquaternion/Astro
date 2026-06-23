//
//  CustomTabBar.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-04.
//

import SwiftUI

struct CustomTabBar<TabItemView: View>: UIViewRepresentable {
    /// The size of the tab bar.
    var size: CGSize
    
    /// The foreground color of a tab bar item on selection.
    var activeTint: Color = .blue
    
    /// The background color of a tab bar item on selection.
    var barTint: Color = .gray.opacity(0.3)
    
    /// The available tabs depending on selected mode.
    var tabs: [CustomTab]
    
    /// The current selected tab.
    @Binding var activeTab: CustomTab
    
    /// The view to display for each tab bar item.
    @ViewBuilder var tabItemView: (CustomTab) -> TabItemView
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UISegmentedControl {
        let items = tabs.map(\.rawValue)
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        
        // render the views for each tab bar items
        for (index, tab) in tabs.enumerated() {
            let renderer = ImageRenderer(content: tabItemView(tab))
            
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
        return control
    }
    
    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        // re-assign the coordinator's parent so 'tabs' is updated
        context.coordinator.parent = self
        
        uiView.removeAllSegments()
        for (index, tab) in tabs.enumerated() {
            uiView.insertSegment(withTitle: nil, at: index, animated: false)
            let renderer = ImageRenderer(content: tabItemView(tab))
            
            renderer.scale = 2
            
            let image = renderer.uiImage?.withRenderingMode(.alwaysOriginal)
            uiView.setImage(image, forSegmentAt: index)
        }
        
        if let selectedIndex = tabs.firstIndex(of: activeTab) {
            uiView.selectedSegmentIndex = selectedIndex
        } else {
            uiView.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISegmentedControl, context: Context) -> CGSize? {
        return size
    }
    
    class Coordinator: NSObject {
        /// The representable instance that owns this coordinator.
        var parent: CustomTabBar
     
        init(parent: CustomTabBar) {
            self.parent = parent
        }
        
        /// Updates the current tab with the newly selected tab.
        @objc func tabSelected(_ control: UISegmentedControl) {
            guard parent.tabs.indices.contains(control.selectedSegmentIndex) else { return }
            parent.activeTab = parent.tabs[control.selectedSegmentIndex]
        }
    }
}
