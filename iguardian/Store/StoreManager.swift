//
//  StoreManager.swift
//  iguardian
//
//  Created by Sukru Demir on 14.01.2026.
//

import StoreKit
import SwiftUI
import Combine

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // Product IDs - configure these in App Store Connect
    private let productIds = [
        "com.sukrudemir.sentinel.premium.monthly",
        "com.sukrudemir.sentinel.premium.yearly"
    ]
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    
    // DEBUG: Toggle this to test premium features without purchase
    #if DEBUG
    @AppStorage("debug_premium_enabled") var debugPremiumEnabled = false
    #endif
    
    var isPremium: Bool {
        #if DEBUG
        if debugPremiumEnabled { return true }
        #endif
        return !purchasedProductIDs.isEmpty
    }
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIds)
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print("Failed to restore: \(error)")
        }
    }
    
    // MARK: - Check Purchased Status
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchased.insert(transaction.productID)
            }
        }
        
        purchasedProductIDs = purchased
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }
    
    // MARK: - Verify Transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}

// MARK: - Product Extension
extension Product {
    var priceFormatted: String {
        displayPrice
    }
    
    var periodFormatted: String {
        guard let subscription = subscription else { return "" }
        let unit = subscription.subscriptionPeriod.unit
        switch unit {
        case .month: return "/month"
        case .year: return "/year"
        case .week: return "/week"
        case .day: return "/day"
        @unknown default: return ""
        }
    }
}
