import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirestoreReceiptRepository: ObservableObject {
    static let shared = FirestoreReceiptRepository()
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    @Published var receipts: [Receipt] = []
    
    private init() {}
    
    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        stopListening()
        
        listener = db.collection("users").document(uid).collection("receipts")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to receipts: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.receipts = documents.compactMap { doc in
                    try? doc.data(as: Receipt.self)
                }
                
                print("📦 Firestore synced: \(self?.receipts.count ?? 0) receipts")
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func addReceipt(_ receipt: Receipt) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(uid).collection("receipts").document()
        var newReceipt = receipt
        newReceipt.id = docRef.documentID
        newReceipt.createdAt = Timestamp(date: Date())
        newReceipt.updatedAt = Timestamp(date: Date())
        
        try docRef.setData(from: newReceipt)
    }
    
    func updateReceipt(_ receipt: Receipt) async throws {
        guard let uid = Auth.auth().currentUser?.uid, let id = receipt.id else { return }
        
        var updated = receipt
        updated.updatedAt = Timestamp(date: Date())
        
        try await db.collection("users").document(uid).collection("receipts").document(id)
            .setData(from: updated, merge: true)
    }
    
    func deleteReceipt(_ receipt: Receipt) async throws {
        guard let uid = Auth.auth().currentUser?.uid, let id = receipt.id else { return }
        
        // 1. Delete Firestore doc
        try await db.collection("users").document(uid).collection("receipts").document(id).delete()
        
        // 2. Delete Local image
        ImageStorageService.shared.deleteImage(at: receipt.imageLocalPath)
    }
    
    func checkDuplicate(hash: String) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        
        do {
            let snapshot = try await db.collection("users").document(uid).collection("receipts")
                .whereField("duplicateHash", isEqualTo: hash)
                .getDocuments()
            
            return !snapshot.documents.isEmpty
        } catch {
            print("Error checking duplicate: \(error.localizedDescription)")
            return false
        }
    }
}
