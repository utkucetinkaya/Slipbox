import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

class EntitlementManager: ObservableObject {
    static let shared = EntitlementManager()
    
    @Published var isPro: Bool = false
    @Published var isLoading: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    private let storeKitManager = StoreKitManager.shared
    
    // UI computed fields
    var planName: String {
        guard isPro else { return "Free" }
        // Determine plan from purchased IDs if needed, otherwise just "Pro"
        if storeKitManager.purchasedProductIDs.contains("com.slipbox.pro.yearly") {
            return "Pro Yearly"
        } else if storeKitManager.purchasedProductIDs.contains("com.slipbox.pro.monthly") {
            return "Pro Monthly"
        }
        return "Pro"
    }
    
    private init() {
        // 1. Observe StoreKitManager's purchasedProductIDs
        storeKitManager.$purchasedProductIDs
            .receive(on: RunLoop.main)
            .sink { [weak self] ids in
                guard let self = self else { return }
                // Only set to true if StoreKit says so. 
                // We'll combine this with Firestore logic below.
                self.updatePremiumStatus(storeKitHasPro: !ids.isEmpty)
                self.isLoading = false
            }
            .store(in: &cancellables)
            
        // 2. Observe Firestore for manual overrides (Testing/Support)
        observeFirestoreEntitlements()
    }
    
    private var firestorePro: Bool = false
    private var storeKitPro: Bool = false
    
    private func observeFirestoreEntitlements() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let data = snapshot?.data() else { return }
                
                let isPremium = data["isPremium"] as? Bool ?? false
                self.firestorePro = isPremium
                self.updatePremiumStatus()
            }
    }
    
    private func updatePremiumStatus(storeKitHasPro: Bool? = nil) {
        if let sk = storeKitHasPro {
            self.storeKitPro = sk
            print("🛒 StoreKit Pro Status: \(sk)")
        }
        
        print("🔥 Firestore Pro Status: \(firestorePro)")
        
        // isPro is true if EITHER StoreKit OR Firestore says so
        let newStatus = storeKitPro || firestorePro
        print("🆔 Final Entitlement Status (isPro): \(newStatus)")
        
        if self.isPro != newStatus {
            self.isPro = newStatus
            print("🚀 Entitlement Manager: isPro updated to \(newStatus)")
            
            // Only sync StoreKit status TO Firestore if it's true and Firestore is false
            if storeKitPro && !firestorePro {
                print("🔄 Syncing StoreKit Pro status to Firestore...")
                self.syncToFirestore(isPro: true)
            }
        }
    }
    
    private func syncToFirestore(isPro: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await Firestore.firestore().collection("users").document(uid).setData([
                    "isPremium": isPro,
                    "premiumUpdatedAt": FieldValue.serverTimestamp()
                ], merge: true)
            } catch {
                print("Error syncing entitlement to Firestore: \(error)")
            }
        }
    }
    
    func refresh() async {
        isLoading = true
        await storeKitManager.updatePurchasedProducts()
    }
}
