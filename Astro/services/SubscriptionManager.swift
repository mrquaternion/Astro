//
//  SubscriptionManager.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-06-11.
//

import StoreKit
import SwiftUI

enum StoreProduct: String, CaseIterable {
    case monthly
    case yearly

    init?(productId: String) {
        guard let product = Self.allCases.first(where: { $0.productId == productId }) else {
            return nil
        }
        self = product
    }
    
    var productId: String {
        switch self {
        case .monthly: "com.mlr.astro.monthly"
        case .yearly: "com.mlr.astro.yearly"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

@Observable
class SubscriptionManager {
    var products: [Product] = []
    var purchasedProductIds: Set<String> = []
    var isLoading = false
    var error: AstroError?
    
    var hasActivateSubscription: Bool {
        !purchasedProductIds.isEmpty
    }
    
    private let productIds: [String] = StoreProduct.allCases.map(\.productId)
    
    private var transactionListener: Task<Void, Error>?
    
    init() {
        transactionListener = listenForTransaction()
        
        Task {
            await fetchProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    func fetchProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: productIds)
            products.sort { $0.price > $1.price }
            print("Products: \(products)")
        } catch {
            self.error = AstroError.unableToFetchProducts(message: error.localizedDescription)
        }
    }
    
    @discardableResult
    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            let (outcome, transaction) = try checkVerified(verificationResult)
            guard let transaction else { return .failed(NSError(domain: "Purchase", code: -1)) }
            
            await updatePurchasedProducts()
            await transaction.finish()
            return outcome
            
        case .userCancelled:
            return .userCancelled
            
        case .pending:
            return .pending
            
        @unknown default:
            return .failed(NSError(domain: "Purchase", code: -1))
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            self.error = AstroError.unableToRestorePurchases(message: error.localizedDescription)
        }
    }
    
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard let (_, transaction) = try? checkVerified(result) else { continue }
            guard let transaction else { continue }
            
            if transaction.revocationDate == nil {
                purchasedProductIds.insert(transaction.productID)
            } else {
                purchasedProductIds.remove(transaction.productID)
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> (PurchaseOutcome, T?) {
        switch result {
        case .unverified(_, let error):
            return (.unverified(error.localizedDescription), nil)
        case .verified(let signedType):
            return (.success, signedType)
        }
    }
    
    private func listenForTransaction() -> Task<Void, Error> {
        Task {
            for await result in Transaction.updates {
                guard let (_, transaction) = try? self.checkVerified(result) else { continue }
                guard let transaction else { continue }
                await self.updatePurchasedProducts()
                await transaction.finish()
            }
        }
    }
}

enum PurchaseOutcome {
    case success
    case pending
    case userCancelled
    case unverified(String)
    case failed(Error)
}
