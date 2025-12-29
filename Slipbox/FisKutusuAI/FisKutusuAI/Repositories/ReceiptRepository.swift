import FirebaseCore
import FirebaseFirestore

// MARK: - Receipt Repository Protocol
protocol ReceiptRepository {
    func fetchReceipts(status: ReceiptStatus?) async throws -> [Receipt]
    func fetchReceipt(id: String) async throws -> Receipt?
    func saveReceipt(_ receipt: Receipt) async throws
    func deleteReceipt(id: String) async throws
}

// MARK: - Mock Receipt Repository
class MockReceiptRepository: ReceiptRepository {
    static let shared = MockReceiptRepository()
    
    private var receipts: [Receipt] = MockData.sampleReceipts
    
    func fetchReceipts(status: ReceiptStatus?) async throws -> [Receipt] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        if let status = status {
            return receipts.filter { $0.status == status }
        }
        return receipts.sorted { ($0.createdAt?.dateValue() ?? Date()) > ($1.createdAt?.dateValue() ?? Date()) }
    }
    
    func fetchReceipt(id: String) async throws -> Receipt? {
        try await Task.sleep(nanoseconds: 300_000_000)
        return receipts.first { $0.id == id }
    }
    
    func saveReceipt(_ receipt: Receipt) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        if let index = receipts.firstIndex(where: { $0.id == receipt.id }) {
            receipts[index] = receipt
        } else {
            receipts.append(receipt)
        }
    }
    
    func deleteReceipt(id: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        receipts.removeAll { $0.id == id }
    }
}

// Phase 3: Replace with FirestoreReceiptRepository
// class FirestoreReceiptRepository: ReceiptRepository {
//     func fetchReceipts(status: ReceiptStatus?) async throws -> [Receipt] {
//         let query = Firestore.firestore()
//             .collection("users/\(uid)/receipts")
//         // ... implement Firestore logic
//     }
// }
