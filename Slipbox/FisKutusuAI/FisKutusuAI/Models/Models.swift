import Foundation
import FirebaseFirestore

// MARK: - Receipt Model
struct Receipt: Codable, Identifiable {
    @DocumentID var id: String?
    var status: ReceiptStatus
    var imagePath: String
    var rawText: String?
    var merchant: String?
    var date: Date? // Changed from String to Date
    var total: Double?
    var currency: String?
    var categoryId: String?
    var categorySuggestedId: String?
    var confidence: Double?
    var notes: String?
    var source: ReceiptSource
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
    var error: String?
    var autoCategorizeMerchant: Bool? // New field for auto-categorization toggle
    
    enum CodingKeys: String, CodingKey {
        case id
        case status
        case imagePath
        case rawText
        case merchant
        case date
        case total
        case currency
        case categoryId
        case categorySuggestedId
        case confidence
        case notes
        case source
        case createdAt
        case updatedAt
        case error
        case autoCategorizeMerchant
    }
}

// MARK: - Receipt Status (State Machine)
enum ReceiptStatus: String, Codable {
    case processing      // Initial state: OCR in progress
    case needsReview = "needs_review"  // Low confidence (<0.8) - user must approve
    case approved        // High confidence (≥0.8) or user-approved
    case error          // Processing failed
    
    // State transitions:
    // processing → needsReview (confidence < 0.8)
    // processing → approved (confidence >= 0.8)
    // processing → error (OCR failed)
    // needsReview → approved (user confirms)
}

// MARK: - Receipt Source
enum ReceiptSource: String, Codable {
    case camera
    case gallery
}

// MARK: - Category Model
struct Category: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var icon: String
    var order: Int
    var isDefault: Bool?
    
    // Default categories
    static let defaults: [Category] = [
        Category(id: "food_drink", name: "Yeme-İçme", icon: "fork.knife", order: 1, isDefault: true),
        Category(id: "transport", name: "Ulaşım", icon: "car.fill", order: 2, isDefault: true),
        Category(id: "equipment", name: "Ekipman", icon: "desktopcomputer", order: 3, isDefault: true),
        Category(id: "service", name: "Hizmet", icon: "wrench.fill", order: 4, isDefault: true),
        Category(id: "other", name: "Diğer", icon: "folder.fill", order: 5, isDefault: true),
    ]
}

// MARK: - Entitlements Model
struct Entitlements: Codable {
    var isPro: Bool
    var receiptCount: Int
    var monthKey: String
    var expiresAt: Timestamp?
    var productId: String?
    var originalTransactionId: String?
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
}

// MARK: - Export Model
struct Export: Codable, Identifiable {
    @DocumentID var id: String?
    var month: String
    var createdAt: Timestamp?
    var pdfPath: String
    var csvPath: String
    var totals: ExportTotals
}

struct ExportTotals: Codable {
    var sum: Double
    var currency: String
    var count: Int
}

// MARK: - Rule Model
struct Rule: Codable, Identifiable {
    @DocumentID var id: String?
    var type: RuleType
    var match: String
    var categoryId: String
    var enabled: Bool
    var createdAt: Timestamp?
}

enum RuleType: String, Codable {
    case merchantContains = "merchant_contains"
    case merchantEquals = "merchant_equals"
}

// MARK: - User Model
struct UserProfile: Codable {
    var createdAt: Timestamp?
    var locale: String
    var currencyDefault: String
}
