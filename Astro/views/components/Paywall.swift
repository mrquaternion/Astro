//
//  Paywall.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-11.
//

import SwiftUI
import StoreKit
import VariableBlur

struct Paywall: View {
    /// Color scheme of the app, based on system appearance.
    @Environment(\.colorScheme) var colorScheme
    
    /// Subscription store that loads products and performs purchases.
    @Environment(SubscriptionManager.self) private var store
    
    /// Dismiss action for closing the paywall.
    @Environment(\.dismiss) private var dismiss
    
    /// Product currently selected for purchase.
    @State private var selectedProduct: Product?
    
    /// Whether a purchase request is currently in progress.
    @State private var isPurchasing = false
    
    /// Controls the presentation of the payment error UI.
    @State private var isShowingError = false
    
    /// Size of the fixed bottom payment area used to pad scroll content.
    @State private var botPaymentMarginsSize: CGSize?
    
    /// The paywall content shown while products load and after they are ready.
    var body: some View {
        if store.isLoading {
            ZStack {
                Group {
                    if colorScheme == .light {
                        Color.white
                    } else {
                        Color.black
                    }
                }
                .ignoresSafeArea()
                
                ProgressView()
                    .tint(.gray)
            }
        } else {
            NavigationStack {
                GeometryReader { proxy in
                    let contentWidth = min(
                        proxy.size.width * PaywallLayout.contentWidthRatio,
                        PaywallLayout.maxContentWidth
                    )
                    let heroHeight = min(
                        max(
                            proxy.size.height * PaywallLayout.heroHeightRatio,
                            PaywallLayout.minHeroHeight
                        ),
                        PaywallLayout.maxHeroHeight
                    )

                    ZStack(alignment: .top) {
                        PaywallBackgroundView(
                            containerSize: proxy.size,
                            heroHeight: heroHeight
                        )
                        PaywallContentView(
                            selectedProduct: $selectedProduct,
                            contentWidth: contentWidth,
                            topPadding: heroHeight * PaywallLayout.contentTopPaddingRatio,
                            botPaymentMarginsSize: $botPaymentMarginsSize
                        )
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .overlay(alignment: .bottom) {
                        bottomPaymentMargins()
                    }
                    .overlay(alignment: .top) {
                        VariableBlurView(maxBlurRadius: 5, direction: .blurredTopClearBottom)
                            .frame(height: PaywallLayout.topBlurHeight)
                    }
                }
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .onAppear {
                selectedProduct = store.products.first
            }
            .alert("Purchase Failed", isPresented: $isShowingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(store.error?.description ?? "Something went wrong.")
            }
        }
    }
    
    @ViewBuilder
    private func bottomPaymentMargins() -> some View {
        VStack(spacing: 16) {
            Button {
                Task {
                    await handlePurchase()
                }
            } label: {
                if isPurchasing {
                    ProgressView()
                        .tint(.gray)
                        .frame(width: 300, height: 50)
                        .contentShape(.capsule)
                        .glassEffect(.clear.interactive(), in: .capsule)
                } else {
                    Text("Subscribe \(selectedProduct.flatMap { StoreProduct(productId: $0.id) }?.displayName ?? "")")
                        .font(.headline.weight(.semibold))
                        .kerning(1)
                        .foregroundStyle(.white)
                        .frame(width: 300, height: 50)
                        .contentShape(.capsule)
                        .glassEffect(.clear.interactive(), in: .capsule)
                }
            }
            
            Text("Recurring billing. Cancel anytime.")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity)
        .safeAreaPadding(.bottom)
        .background(
            .accent,
            in: UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 16,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: 16
                ),
                style: .continuous
            )
        )
        .shadow(radius: 10)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            botPaymentMarginsSize = newValue
        }
    }
    
    private func handlePurchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            try await store.purchase(product)
            dismiss()
        } catch {
            isShowingError = true
        }
    }
}

fileprivate enum PaywallLayout {
    /// Fraction of the available width used by paywall content.
    static let contentWidthRatio: CGFloat = 0.9
    
    /// Maximum width for the main paywall content column.
    static let maxContentWidth: CGFloat = 680
    
    /// Fraction of the available height used by the hero artwork.
    static let heroHeightRatio: CGFloat = 0.28
    
    /// Minimum hero artwork height.
    static let minHeroHeight: CGFloat = 220
    
    /// Maximum hero artwork height.
    static let maxHeroHeight: CGFloat = 320
    
    /// Fraction of the hero height used as top padding for paywall content.
    static let contentTopPaddingRatio: CGFloat = 0.8
    
    /// Height of the blur applied at the top edge.
    static let topBlurHeight: CGFloat = 80
    
    /// Padding used around the close button.
    static let closeButtonPadding: CGFloat = 16
}

#Preview {
    /// Controls presentation of the paywall preview sheet.
    @Previewable @State var isShowing = false
    
    Group {
        Button {
            isShowing.toggle()
        } label: {
            Text("Hello, World!")
        }
        .buttonStyle(.bordered)
    }
    .sheet(isPresented: $isShowing) {
        Paywall()
            .environment(SubscriptionManager())
    }
}

#Preview {
    Paywall()
        .environment(SubscriptionManager())
}

fileprivate struct PaywallBackgroundView: View {
    /// Full size of the paywall container.
    let containerSize: CGSize

    /// Height reserved for the star field hero artwork.
    let heroHeight: CGFloat
    
    /// The gradient and star background behind the paywall.
    var body: some View {
        LinearGradient(
            colors: [
                Color("SkyBackgroundDarkTone"),
                Color("SkyBackgroundMediumTone"),
                Color("SkyBackgroundLightTone")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            Image("PaywallBackgroundStars")
                .resizable()
                .scaledToFill()
                .frame(width: containerSize.width, height: heroHeight)
                .clipped()
                .blur(radius: 5)
        }
    }
}

fileprivate struct PaywallContentView: View {
    /// Subscription store that provides purchasable products.
    @Environment(SubscriptionManager.self) private var store

    /// Selected product.
    @Binding var selectedProduct: Product?
    
    /// Fixed width used for text, product rows, and feature cards.
    let contentWidth: CGFloat

    /// Top spacing that positions the scroll content below the hero artwork.
    let topPadding: CGFloat
    
    /// Size of the bottom payment area used to avoid content overlap.
    @Binding var botPaymentMarginsSize: CGSize?
    
    /// The scrollable product picker and feature list.
    var body: some View {
        ScrollView {
            VStack(spacing: 34) {
                VStack(spacing: 12) {
                    Text("Explore space like never before.")
                        .font(.largeTitle.weight(.bold))
                    Text("Track satellites, discover space missions, and plan your next night under the stars.")
                        .font(.callout)
                }
                .frame(width: contentWidth)
                
                VStack(spacing: 48) {
                    VStack(spacing: 16) {
                        ForEach(store.products, id: \.id) { product in
                            let storeProduct = StoreProduct(productId: product.id)

                            HStack {
                                if storeProduct == .yearly {
                                    VStack(alignment: .leading) {
                                        Text(storeProduct?.displayName ?? "")
                                            .font(.title2.weight(.semibold))
                                        Text("Billed at \(product.displayPrice)/year")
                                            .font(.subheadline.weight(.medium))
                                    }
                                    Spacer()
                                    Text("$\(yearlyPriceMonthly(product.price))/month")
                                        .font(.callout)
                                } else {
                                    Text(storeProduct?.displayName ?? "")
                                        .font(.title3.weight(.semibold))
                                    Spacer()
                                    Text("\(product.displayPrice)/month")
                                        .font(.callout)
                                }
                            }
                            .padding()
                            .frame(width: contentWidth)
                            .foregroundStyle(selectedProduct == product ? .white : .black)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedProduct == product ? .accent : .white)
                                    .stroke(selectedProduct == product ? .white : .clear)
                            )
                            .onTapGesture {
                                withAnimation {
                                    selectedProduct = product
                                }
                            }
                        }
                    }
                    
                    VStack(spacing: 16) {
                        Text("Everything included")
                            .font(.caption.weight(.medium))
                            .kerning(1)
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(ProFeature.all) { feature in
                                ProFeatureCard(feature: feature)
                            }
                        }
                    }
                    .padding()
                    .frame(width: contentWidth)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.08)))
                }
                .padding(.bottom, (botPaymentMarginsSize?.height ?? 0) + 20)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.top, topPadding)
        }
    }
    
    private func yearlyPriceMonthly(_ fullPrice: Decimal, numMonths: Int = 12) -> Decimal {
        var monthlyPrice = fullPrice / Decimal(numMonths)
        var truncated = Decimal()
        
        NSDecimalRound(&truncated, &monthlyPrice, 2, .down)
        
        return truncated
    }
}

struct ProFeature: Identifiable {
    /// Stable identity for rendering the feature in a grid.
    let id = UUID()
    
    /// Image asset or SF Symbol used for the feature icon.
    let icon: String
    
    /// Short feature title shown on the card.
    let title: String
    
    /// Supporting description shown below the title.
    let description: String
    
    /// Accent color applied to the feature icon.
    let tint: Color
    
    /// Whether the icon should be loaded from the asset catalog.
    var isCustom: Bool = false
    
    /// Whether the custom icon needs handmade sizing.
    var isHandmade: Bool = false

    /// Features advertised in the paywall grid.
    static let all: [ProFeature] = [
        .init(
            icon: "satellite",
            title: "More satellites",
            description: "Track tens of additional orbits in real time.",
            tint: .blue,
            isCustom: true,
            isHandmade: true
        ),
        .init(
            icon: "rocket",
            title: "Live missions",
            description: "Stay updated on upcoming launches.",
            tint: .teal,
            isCustom: true,
            isHandmade: true
        ),
        .init(
            icon: "books.vertical.fill",
            title: "Deep history",
            description: "Explore the origins of rockets, satellites, and spaceships.",
            tint: .red
        ),
        .init(
            icon: "moon.stars.fill",
            title: "Night sky planner",
            description: "Find the best times to photograph the Milky Way and planets.",
            tint: .purple
        ),
        .init(
            icon: "custom.megaphone.slash.fill",
            title: "No ads",
            description: "Read the news without interruptions.",
            tint: .orange,
            isCustom: true
        )
    ]
}

fileprivate struct ProFeatureCard: View {
    /// Feature data rendered by this card.
    let feature: ProFeature

    /// The feature card content.
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        if feature.isCustom {
                            Image(feature.icon)
                                .font(feature.isHandmade ? .title3 : .body)
                                .fontWeight(.regular)
                        } else {
                            Image(systemName: feature.icon)
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(feature.tint)
                    .frame(width: 32, height: 32)
                    .background(feature.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                    Text(feature.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
            }

            Text(feature.description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}
