import SwiftUI
import Combine
import StoreKit
import FirebaseFirestore
import FirebaseAuth

class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    private let productIDs = ["slipbox_pro_monthly", "slipbox_pro_yearly"]
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
            print("Loaded \(products.count) products")
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateEntitlements(for: transaction)
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
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func updateEntitlements(for transaction: StoreKit.Transaction) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let plan: SubscriptionPlan = transaction.productID == "slipbox_pro_yearly" ? .proYearly : .proMonthly
        let expiresDate = transaction.expirationDate
        
        let data: [String: Any] = [
            "isPro": true,
            "plan": plan.rawValue,
            "source": PurchaseSource.appstore.rawValue,
            "status": SubscriptionStatus.active.rawValue,
            "startedAt": FieldValue.serverTimestamp(),
            "expiresAt": expiresDate ?? FieldValue.delete(),
            "updatedAt": FieldValue.serverTimestamp(),
            "originalTransactionId": String(transaction.originalID),
            "lastVerifiedAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await Firestore.firestore().collection("entitlements").document(uid).setData(data, merge: true)
        } catch {
            print("Error updating entitlements in Firestore: \(error)")
        }
    }
    
    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await updateEntitlements(for: transaction)
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
