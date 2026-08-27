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
                            Text("subscription_free_title".localizedFirstCapitalized)
                        } else {
                            Text("subscription_pro_thanks_title".localizedFirstCapitalized)
                        }
                    }
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    
                    Group {
                        if store.purchasedProductIds.isEmpty {
                            Text("subscription_free_description".localizedFirstCapitalized)
                        } else {
                            Text("subscription_pro_thanks_description".localizedFirstCapitalized)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("subscription_current_plan".localizedFirstCapitalized)
                        .foregroundStyle(Color(.tertiaryLabel))
                        .bold()
                    
                    if store.purchasedProductIds.isEmpty {
                        HStack(spacing: 12) {
                            Text("subscription_astro_free".localized)
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
                                            Text(
                                                "subscription_product_option_format".localizedFormat(
                                                    StoreProduct(productId: product.id)?.displayName
                                                        ?? "common_unknown".localizedFirstCapitalized,
                                                    product.displayPrice
                                                )
                                            )
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
                                        Text(
                                            StoreProduct(productId: selectedProduct.id)?.displayName
                                                ?? "subscription_plan".localizedFirstCapitalized
                                        )
                                            .font(.headline)
                                            .foregroundStyle(.blue)
                                    } else {
                                        Text("subscription_choose_plan".localizedFirstCapitalized)
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
                            Text("subscription_astro_pro_format".localizedFormat(product.displayName))
                                .font(.headline)
                                .bold()
                                .foregroundStyle(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                            
                            Spacer()
                            Text(
                                "subscription_renews_format".localizedFormat(
                                    expiringDate.formatted(.dateTime.month(.abbreviated).day().year())
                                )
                            )
                                .font(.footnote)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 24, style: .continuous))
                
                VStack(alignment: .leading) {
                    Text("subscription_advantages".localizedFirstCapitalized)
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
                        Text("subscription_restore_purchases".localizedFirstCapitalized)
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
            Button("common_ok".localized, role: .cancel) { }
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
                    title: "purchase_pending_title".localizedFirstCapitalized,
                    description: "purchase_pending_description".localizedFirstCapitalized
                )
                
            case .userCancelled:
                break
                
            case .unverified(let message):
                showPurchaseAlert(
                    title: "purchase_unverified_title".localizedFirstCapitalized,
                    description: message
                )
                
            case .failed(let error):
                showPurchaseAlert(
                    title: "purchase_failed_title".localizedFirstCapitalized,
                    description: error.localizedDescription
                )
            }
        } catch {
            showPurchaseAlert(
                title: "purchase_failed_title".localizedFirstCapitalized,
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
        VStack(alignment: .leading, spacing: 6) {
            VStack(spacing: 0) {
                HStack {
                    Text("subscription_feature".localizedFirstCapitalized)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("subscription_free".localizedFirstCapitalized)
                        .frame(width: 52)
                    
                    Text("subscription_pro".localized)
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
                                HStack(alignment: .top, spacing: 4) {
                                    Text(feature.title)
                                        .foregroundStyle(.primary)
                                    
                                    if feature.isComingSoon {
                                        Text("(∗)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
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
                                    ? "subscription_included_free".localizedFirstCapitalized
                                    : "subscription_not_included_free".localizedFirstCapitalized
                            )
                        
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                            .frame(width: 52)
                            .accessibilityLabel("subscription_included_pro".localizedFirstCapitalized)
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
            
            HStack {
                Text("(∗)")
                Text("coming_soon".localizedFirstCapitalized)
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SubscriptionSettings()
        .environment(SubscriptionManager())
}
