import Foundation
import FirebaseFirestore
import FirebaseAuth

class UsageLimiterService {
    static let shared = UsageLimiterService()
    
    private let db = Firestore.firestore()
    private let maxFreeScans = 30
    
    private init() {}
    
    /// Checks if the current user can perform a new scan
    func canScan() async -> Bool {
        // Premium users have unlimited scans
        if EntitlementManager.shared.isPro {
            return true
        }
        
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        
        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            let data = userDoc.data() ?? [:]
            
            let currentPeriod = self.currentPeriodKey()
            let storedPeriod = data["monthlyScanPeriodKey"] as? String ?? ""
            let count = data["monthlyScanCount"] as? Int ?? 0
            
            // If period has changed, user can scan (reset will happen during increment)
            if currentPeriod != storedPeriod {
                return true
            }
            
            return count < maxFreeScans
        } catch {
            print("Error checking scan limit: \(error)")
            return false // Default to safe state on error
        }
    }
    
    /// Increments the scan count for the current user
    func incrementScanCount() async {
        // Skip if premium
        if EntitlementManager.shared.isPro {
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let periodKey = self.currentPeriodKey()
        
        do {
            let userRef = db.collection("users").document(uid)
            
            // Atomic update using a transaction to handle period reset and count increment
            try await db.runTransaction { (transaction, errorPointer) -> Any? in
                let userSnapshot: DocumentSnapshot
                do {
                    userSnapshot = try transaction.getDocument(userRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
                
                let data = userSnapshot.data() ?? [:]
                let storedPeriod = data["monthlyScanPeriodKey"] as? String ?? ""
                
                if storedPeriod != periodKey {
                    // Reset for new period
                    transaction.updateData([
                        "monthlyScanCount": 1,
                        "monthlyScanPeriodKey": periodKey
                    ], forDocument: userRef)
                } else {
                    // Increment existing
                    transaction.updateData([
                        "monthlyScanCount": FieldValue.increment(Int64(1))
                    ], forDocument: userRef)
                }
                
                return nil
            }
        } catch {
            print("Error incrementing scan count: \(error)")
        }
    }
    
    /// Returns current period key in "yyyy-MM" format
    private func currentPeriodKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
    
    /// Returns remaining scans for the current period
    func remainingScans() async -> Int {
        if EntitlementManager.shared.isPro { return 999 }
        
        guard let uid = Auth.auth().currentUser?.uid else { return 0 }
        
        let doc = try? await db.collection("users").document(uid).getDocument()
        let data = doc?.data() ?? [:]
        
        let storedPeriod = data["monthlyScanPeriodKey"] as? String ?? ""
        if storedPeriod != currentPeriodKey() {
            return maxFreeScans
        }
        
        let count = data["monthlyScanCount"] as? Int ?? 0
        return max(0, maxFreeScans - count)
    }
}
