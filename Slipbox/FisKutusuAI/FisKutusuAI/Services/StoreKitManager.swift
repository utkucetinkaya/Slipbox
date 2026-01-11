import SwiftUI
import Combine
import StoreKit
import FirebaseFirestore
import FirebaseAuth

class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    private let productIDs = ["com.slipbox.pro.monthly", "com.slipbox.pro.yearly"]
    private var updates: Task<Void, Never>? = nil
    
    init() {
        updates = newTransactionListenerTask()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    @MainActor
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            print("Loaded \(products.count) products from App Store")
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }
    
    @MainActor
    func updatePurchasedProducts() async {
        var purchasedIDs = Set<String>()
        
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedIDs.insert(transaction.productID)
            }
        }
        
        self.purchasedProductIDs = purchasedIDs
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await transaction.finish()
                    await updatePurchasedProducts()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
