import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreReceiptRepository: ReceiptRepository {
    static let shared = FirestoreReceiptRepository()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    private init() {
        // Enable offline persistence
        // Default persistence is enabled by default
        // db.settings = ... is removed to prevent "instance already started" crash
    }
    
    // MARK: - ReceiptRepository Protocol
    
    func fetchReceipts(status: ReceiptStatus?) async throws -> [Receipt] {
        guard let uid = auth.currentUser?.uid else {
            throw RepositoryError.notAuthenticated
        }
        
        // Build query with correct path structure
        var query: Query = db.collection("users")
            .document(uid)
            .collection("receipts")
        
        if let status = status {
            query = query.whereField("status", isEqualTo: status.rawValue)
        }
        
        // Always order by createdAt (newest first)
        query = query.order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Receipt.self) }
    }
    
    func fetchReceipt(id: String) async throws -> Receipt? {
        guard let uid = auth.currentUser?.uid else {
            throw RepositoryError.notAuthenticated
        }
        
        let docRef = db.collection("users")
            .document(uid)
            .collection("receipts")
            .document(id)
        
        let snapshot = try await docRef.getDocument()
        return try? snapshot.data(as: Receipt.self)
    }
    
    func saveReceipt(_ receipt: Receipt) async throws {
        guard let uid = auth.currentUser?.uid else {
            throw RepositoryError.notAuthenticated
        }
        
        guard let receiptId = receipt.id else {
            throw RepositoryError.invalidData
        }
        
        let docRef = db.collection("users")
            .document(uid)
            .collection("receipts")
            .document(receiptId)
        
        try docRef.setData(from: receipt, merge: true)
    }
    
    func deleteReceipt(id: String) async throws {
        guard let uid = auth.currentUser?.uid else {
            throw RepositoryError.notAuthenticated
        }
        
        let docRef = db.collection("users")
            .document(uid)
            .collection("receipts")
            .document(id)
        
        try await docRef.delete()
    }
}

// MARK: - Repository Error
enum RepositoryError: LocalizedError {
    case notAuthenticated
    case invalidData
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be signed in"
        case .invalidData:
            return "Invalid receipt data"
        case .notFound:
            return "Receipt not found"
        }
    }
}
