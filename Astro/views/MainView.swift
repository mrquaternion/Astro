//
//  ContentView.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-02.
//

import SwiftUI
import SwiftData

struct MainView: View {
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) var colorScheme
    
    /// Detect device orientation.
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    /// Whether the current device is an iPhone.
    @Environment(\.isPhone) private var isPhone
    
    /// Whether the current device is an iPad.
    @Environment(\.isPad) private var isPad
    
    /// Shared home state used by the selected tab and satellite picker.
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    /// Current selected mode.
    @State private var activeMode: CustomMode = .exploration
    
    /// Current selected tab.
    @State private var activeTab: CustomTab = .home
    
    /// Present different satellites.
    @State private var isSatelliteListPresented = false
    
    /// Current selected mode's tabs.
    var currentTabs: [CustomTab] { activeMode.tabs }
    
    /// The adaptive tab shell that switches between phone and pad layouts.
    var body: some View {
        GeometryReader { proxy in
            Group {
                if isPad {
                    padLayout(screenWidth: proxy.size.width)
                } else {
                    phoneLayout()
                }
            }
            .overlay {
                if homeViewModel.isAssetLoading {
                    ProgressView("Loading satellite...")
                        .padding()
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                }
            }
        }
        .onChange(of: activeMode) { _, newMode in
            activeTab = .home
        }
        .onChange(of: activeTab) { _, _ in
            isSatelliteListPresented = false
        }
    }
    
    @ViewBuilder
    func padLayout(screenWidth: CGFloat) -> some View {
        phoneLayout()
            .inspector(isPresented: $isSatelliteListPresented) {
                SatelliteListView(isPresented: $isSatelliteListPresented)
                    .environmentObject(homeViewModel)
                    .inspectorColumnWidth(horizontalSizeClass == .regular ? screenWidth * 0.4 : screenWidth * 0.2)
            }
    }
    
    @ViewBuilder
    func phoneLayout() -> some View {
        ZStack {
            tabsContent()
            
            VStack(spacing: 12) {
                // pushes the content down
                Spacer()
                
                GlassEffectContainer(spacing: 6) {
                  HStack(spacing: 12) {
                      homeButton()
                      tabBar()

                      if activeTab == .home {
                          satelliteButton()
                      }
                  }
              }
            }
            .padding(.horizontal)
            .sheet(isPresented: Binding(
                get: { isPhone && isSatelliteListPresented }, // only for iPhone users
                set: { if !$0 { isSatelliteListPresented = false } })
            ) {
                SatelliteListView(isPresented: $isSatelliteListPresented)
                    .environmentObject(homeViewModel)
                    .presentationDetents([.fraction(0.45), .fraction(0.8)])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    func tabsContent() -> some View {
        Group {
            switch activeTab {
            case .home:
                HomeView(activeMode: $activeMode)
                    .environmentObject(homeViewModel)
                
            case .missions:
                Text("Missions View")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.mix(with: .gray, by: 0.4).mix(with: .blue, by: 0.3))
                
            case .news:
                NewsView()
                    
            case .learn:
                Text("Learn View")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.mix(with: .gray, by: 0.4).mix(with: .blue, by: 0.3))
                
            case .lookup:
                Text("Lookup View")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.mix(with: .gray, by: 0.4).mix(with: .blue, by: 0.3))
                
            case .community:
                Text("Community View")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.mix(with: .gray, by: 0.4).mix(with: .blue, by: 0.3))
            }
        }
    }
    
    @ViewBuilder
    func homeButton() -> some View {
        ZStack {
            Button {
                activeTab = .home
            } label: {
                Image(systemName: CustomTab.home.symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.glassBackgroundContent(colorScheme))
                    .symbolVariant(activeTab == .home ? .fill : .none)
            }
        }
        .frame(width: CustomTabBarLayout.height, height: CustomTabBarLayout.height)
        .contentShape(.circle)
        .glassEffect(.regular.tint(.glassBackground(colorScheme)), in: .circle)
    }
    
    @ViewBuilder
    func tabBar() -> some View {
            GeometryReader {
                CustomTabBar(size: $0.size, tabs: currentTabs, activeTab: $activeTab) { tab in
                    VStack {
                        Image(systemName: tab.symbol)
                            .font(.title3)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.glassBackgroundContent(colorScheme))
                    .symbolVariant(.fill)
                }
                .glassEffect(.regular.interactive().tint(.glassBackground(colorScheme)), in: .capsule)
            }
            .frame(height: CustomTabBarLayout.height)
    }
    
    @ViewBuilder
      func satelliteButton() -> some View {
          Button {
              isSatelliteListPresented.toggle()
          } label: {
              Image("satellite")
                  .font(.title2)
                  .foregroundStyle(.glassBackgroundContent(colorScheme))
                  .frame(width: CustomTabBarLayout.height, height: CustomTabBarLayout.height)
          }
          .buttonStyle(.plain)
          .contentShape(.circle)
          .glassEffect(
              .regular.interactive().tint(.glassBackground(colorScheme)),
              in: .circle
          )
          .accessibilityLabel("Choose satellite")
      }
}

#Preview {
    MainView()
        .environmentObject(HomeViewModel())
        .environment(SubscriptionManager())
}

enum CustomTabBarLayout {
    static let height: CGFloat = 55
    static let yOffset: CGFloat = 16
}
