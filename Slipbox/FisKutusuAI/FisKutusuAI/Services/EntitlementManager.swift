import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

class EntitlementManager: ObservableObject {
    static let shared = EntitlementManager()
    
    @Published var entitlements: Entitlements?
    @Published var isLoading: Bool = true
    
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private var currentUserId: String?
    
    var isPro: Bool {
        entitlements?.isPro ?? false
    }
    
    var plan: SubscriptionPlan {
        entitlements?.plan ?? .free
    }
    
    var status: SubscriptionStatus {
        entitlements?.status ?? .expired
    }
    
    private init() {
        // Initial setup if user is already logged in
        if let uid = Auth.auth().currentUser?.uid {
            startListening(uid: uid)
        }
    }
    
    func startListening(uid: String) {
        if currentUserId == uid && listener != nil {
            return
        }
        
        stopListening()
        currentUserId = uid
        isLoading = true
        
        listener = db.collection("entitlements").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                print("Error listening to entitlements: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                do {
                    self.entitlements = try snapshot.data(as: Entitlements.self)
                } catch {
                    print("Error decoding entitlements: \(error)")
                    self.entitlements = .free
                }
            } else {
                // If no doc exists, default to free
                self.entitlements = .free
            }
        }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
        entitlements = nil
        currentUserId = nil
    }
    
    func reset() {
        stopListening()
        entitlements = nil
        isLoading = false
    }
}
