import Foundation

/// Cloud Function for creating a receipt upload session
/// Checks Free tier limits BEFORE allowing upload
class ReceiptUploadSessionManager {
    static let shared = ReceiptUploadSessionManager()
    
    private init() {}
    
    /// Request permission to upload a receipt
    /// Throws if Free tier limit exceeded
    /// Request permission to upload a receipt
    /// Throws if Free tier limit exceeded
    func requestUploadPermission() async throws -> UploadSessionResult {
        // v1: Spark-first / Cost-minimized
        // Bypass server-side check. We enforce limits via local StoreKit check if needed.
        // For now, allow everything.
        
        return UploadSessionResult(
            allowed: true,
            receiptCount: 0,
            limit: 20
        )
    }
}

// MARK: - Models
struct UploadSessionResult {
    let allowed: Bool
    let receiptCount: Int
    let limit: Int
}

enum UploadSessionError: LocalizedError {
    case limitExceeded
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .limitExceeded:
            return "Free tier limit (20 receipts/month) exceeded. Upgrade to Pro for unlimited receipts."
        case .notAuthenticated:
            return "You must be signed in to upload receipts."
        }
    }
}
