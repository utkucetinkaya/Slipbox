import Foundation
import FirebaseFirestore

// MARK: - Receipt Model
struct Receipt: Codable, Identifiable {
    @DocumentID var id: String?
    var status: ReceiptStatus
    var imageLocalPath: String
    var rawText: String?
    var merchantName: String?
    var date: Date?
    var total: Double?
    var currency: String?
    var categoryId: String?
    var categoryName: String?
    var confidence: Double?
    var note: String?
    var source: ReceiptSource
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
    var error: String?
    
    // MARK: - Tax & Accounting Fields
    var duplicateHash: String?
    var isUTTS: Bool?
    var vatRate: Double?
    var vatAmount: Double?
    var baseAmount: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case status
        case imageLocalPath
        case rawText
        case merchantName
        case date
        case total
        case currency
        case categoryId
        case categoryName
        case confidence
        case note
        case source
        case createdAt
        case updatedAt
        case error
        case duplicateHash
        case isUTTS
        case vatRate
        case vatAmount
        case baseAmount
    }
}

// MARK: - Receipt Status (State Machine)
enum ReceiptStatus: String, Codable {
    case new             // OCR finished, waiting for categorization/initial state
    case pendingReview = "pending_review"  // Uncertain extraction
    case approved        // User confirmed
    case rejected        // User rejected
    case processing      // Internal: OCR in progress
    case error          // Processing failed
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
    
    // Default initial categories for seeding
    static let defaults: [Category] = [
        Category(id: "food_drink", name: "Gıda & İçecek", icon: "fork.knife", order: 1, isDefault: true),
        Category(id: "transport", name: "Ulaşım", icon: "car.fill", order: 2, isDefault: true),
        Category(id: "equipment", name: "Ekipman", icon: "desktopcomputer", order: 3, isDefault: true),
        Category(id: "service", name: "Hizmet", icon: "wrench.fill", order: 4, isDefault: true),
        Category(id: "other", name: "Diğer", icon: "folder.fill", order: 5, isDefault: true),
    ]
    
    // Additional categories available in the picker
    static let additional: [Category] = [
        Category(id: "market", name: "Market", icon: "cart.fill", order: 6, isDefault: false),
        Category(id: "entertainment", name: "Eğlence", icon: "theatermasks.fill", order: 7, isDefault: false),
        Category(id: "bills", name: "Faturalar", icon: "doc.plaintext.fill", order: 8, isDefault: false),
        Category(id: "clothing", name: "Giyim", icon: "tshirt.fill", order: 9, isDefault: false),
        Category(id: "health", name: "Sağlık", icon: "cross.fill", order: 10, isDefault: false),
        Category(id: "education", name: "Eğitim", icon: "book.fill", order: 11, isDefault: false),
        Category(id: "shopping", name: "Alışveriş", icon: "bag.fill", order: 12, isDefault: false),
        Category(id: "tax", name: "Vergi", icon: "percent", order: 13, isDefault: false),
        Category(id: "travel", name: "Seyahat", icon: "airplane", order: 14, isDefault: false),
        Category(id: "rent", name: "Kira", icon: "house.fill", order: 15, isDefault: false),
    ]
}

// MARK: - Entitlements Model
enum SubscriptionPlan: String, Codable {
    case free = "free"
    case proMonthly = "pro_monthly"
    case proYearly = "pro_yearly"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .proMonthly: return "Pro Monthly"
        case .proYearly: return "Pro Yearly"
        }
    }
}

enum SubscriptionStatus: String, Codable {
    case active = "active"
    case expired = "expired"
    case grace = "grace"
    case revoked = "revoked"
}

enum PurchaseSource: String, Codable {
    case appstore = "appstore"
}

struct Entitlements: Codable, Equatable {
    var isPro: Bool
    var plan: SubscriptionPlan
    var source: PurchaseSource
    var status: SubscriptionStatus
    var expiresAt: Date?
    var startedAt: Date
    var updatedAt: Date
    var originalTransactionId: String?
    var lastVerifiedAt: Date?
    var debugNote: String?
    
    static var free: Entitlements {
        Entitlements(
            isPro: false,
            plan: .free,
            source: .appstore,
            status: .expired,
            startedAt: Date(),
            updatedAt: Date()
        )
    }
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
    var uid: String?
    var email: String?
    var displayName: String?
    var phoneNumber: String?
    var profileImageUrl: String?
    var locale: String
    var currencyDefault: String
    var onboardingCompleted: Bool
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
}
