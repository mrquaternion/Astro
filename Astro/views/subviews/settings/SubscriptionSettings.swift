//
//  SubscriptionSettings.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-24.
//

import SwiftUI
import StoreKit

struct SubscriptionSettings: View {
    /// Subscription store that provides purchasable products.
    @Environment(SubscriptionManager.self) private var store
    
    /// Environment value supplying colorScheme.
    @Environment(\.colorScheme) var colorScheme
    
    /// Product currently selected for purchase.
    @State private var selectedProduct: Product?
    
    /// Whether a purchase request is currently in progress.
    @State private var isPurchasing = false
    
    /// Controls the presentation of the payment message UI.
    @State private var isShowingAlert = false
    
    /// Holds the title of the presentation coming from the payment.
    @State private var alertTitle = ""
    
    /// Holds the description of the presentation coming from the payment.
    @State private var alertDescription = ""
    
    /// Value used for buttonLabelColor.
    var buttonLabelColor: Color {
        colorScheme == .light ? .white : .black
    }
    
    /// Value used for buttonBackgroundColor.
    var buttonBackgroundColor: Color {
        colorScheme == .light ? .black : .white
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                VStack(spacing: 12) {
                    Group {
                        if store.purchasedProductIds.isEmpty {
                            Text("Learn more about space.")
                        } else {
                            Text("Thank you for being Pro!")
                        }
                    }
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    
                    Group {
                        if store.purchasedProductIds.isEmpty {
                            Text("Discover more space missions, track plenty of\nsatellites and get ready to become a bigger\nspace-nerd than you were.")
                        } else {
                            Text("Support like yours helps us keep building an\namazing app for space enthusiasts like\nyou. We truly appreciate it.")
                        }
                    }
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current plan")
                        .foregroundStyle(Color(.tertiaryLabel))
                        .bold()
                    
                    if store.purchasedProductIds.isEmpty {
                        HStack(spacing: 12) {
                            Text("Astro Free")
                                .font(.headline)
                                .bold()
                                .foregroundStyle(Color(.secondaryLabel))
                            
                            Spacer()
                            
                            Menu {
                                ForEach(store.products, id: \.id) { product in
                                    Button {
                                        selectedProduct = product
                                    } label: {
                                        HStack {
                                            Text("\(StoreProduct(productId: product.id)?.displayName ?? "Unknown") – \(product.displayPrice)/month")
                                            if product.id == selectedProduct?.id {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    if let selectedProduct {
                                        Text("\(StoreProduct(productId: selectedProduct.id)?.displayName ?? "Plan")")
                                            .font(.headline)
                                            .foregroundStyle(.blue)
                                    } else {
                                        Text("Choose plan")
                                            .font(.body)
                                            
                                    }
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(selectedProduct != nil ? .blue : .primary)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(store.products.isEmpty)
                            
                            Button {
                                Task {
                                    await handlePurchase()
                                }
                            } label: {
                                Group {
                                    if isPurchasing {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "dollarsign.circle.fill")
                                            .font(.system(size: 17))
                                    }
                                }
                                .padding(6)
                                .glassEffect(.clear.interactive(), in: .circle)
                            }
                            .buttonBorderShape(.circle)
                            .buttonStyle(.plain)
                            .disabled(isPurchasing || selectedProduct == nil)
                        }
                    } else if
                        (!store.purchasedProductIds.isEmpty),
                        let item = store.purchasedProductIds.first,
                        let product = StoreProduct(productId: item),
                        let expiringDate = store.subscriptionExpiryDates[item]
                    {
                        HStack {
                            Text("Astro Pro – \(product.displayName)")
                                .font(.headline)
                                .bold()
                                .foregroundStyle(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                            
                            Spacer()
                            Text("Renews on \(expiringDate, format: .dateTime.month(.abbreviated).day().year())")
                                .font(.footnote)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 24, style: .continuous))
                
                VStack(alignment: .leading) {
                    Text("Advantages")
                        .font(.title2)
                        .bold()
                    
                    SubscriptionFeatureComparison()
                }
                
                Button {
                    Task {
                        await store.restorePurchases()
                    }
                } label: {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                        Text("Restore purchases")
                    }
                    .bold()
                    .padding(.vertical)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(buttonBackgroundColor)
                .foregroundStyle(buttonLabelColor)
            }
            .padding(.horizontal)
        }
        .alert(alertTitle, isPresented: $isShowingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertDescription)
        }
    }
    
    private func handlePurchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let outcome = try await store.purchase(product)
            
            switch outcome {
            case .success:
                break
                
            case .pending:
                showPurchaseAlert(
                    title: "Purchase Pending",
                    description: "Your purchase is awaiting approval or payment confirmation."
                )
                
            case .userCancelled:
                break
                
            case .unverified(let message):
                showPurchaseAlert(
                    title: "Purchase Unverified",
                    description: message
                )
                
            case .failed(let error):
                showPurchaseAlert(
                    title: "Purchase Failed",
                    description: error.localizedDescription
                )
            }
        } catch {
            showPurchaseAlert(
                title: "Purchase Failed",
                description: error.localizedDescription
            )
        }
    }
    
    private func showPurchaseAlert(title: String, description: String) {
        alertTitle = title
        alertDescription = description
        isShowingAlert = true
    }
}

private struct SubscriptionFeatureComparison: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Feature")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Free")
                    .frame(width: 52)
                
                Text("Pro")
                    .frame(width: 52)
                    .foregroundStyle(.blue)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.bottom, 12)
            
            Divider()
            
            ForEach(Array(ProFeature.subscriptionComparison.enumerated()), id: \.element.id) { index, feature in
                HStack(spacing: 12) {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(feature.title)
                                .foregroundStyle(.primary)
                            
                            Text(feature.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } icon: {
                        Group {
                            if feature.isCustom {
                                Image(feature.icon)
                            } else {
                                Image(systemName: feature.icon)
                            }
                        }
                        .foregroundStyle(feature.tint)
                        .frame(width: 24)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: feature.isIncludedInFree ? "checkmark" : "minus")
                        .fontWeight(feature.isIncludedInFree ? .semibold : .regular)
                        .foregroundStyle(feature.isIncludedInFree ? Color.green : Color.secondary)
                        .frame(width: 52)
                        .accessibilityLabel(
                            feature.isIncludedInFree
                                ? "Included with Astro Free"
                                : "Not included with Astro Free"
                        )
                    
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                        .frame(width: 52)
                        .accessibilityLabel("Included with Astro Pro")
                }
                .padding(.vertical, 14)
                
                if index < ProFeature.subscriptionComparison.count - 1 {
                    Divider()
                }
            }
        }
        .padding([.top, .horizontal])
        .background(
            Color(.secondarySystemBackground),
            in: .rect(cornerRadius: 24, style: .continuous)
        )
    }
}

#Preview {
    SubscriptionSettings()
        .environment(SubscriptionManager())
}
