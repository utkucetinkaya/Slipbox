import Foundation
import FirebaseFirestore

struct MockData {
    // MARK: - Sample Receipts
    static let sampleReceipts: [Receipt] = [
        // Processing
        Receipt(
            id: "receipt_processing",
            status: .processing,
            imagePath: "mock/receipt1",
            rawText: nil,
            merchant: nil,
            date: nil,
            total: nil,
            currency: "TRY",
            categoryId: nil,
            categorySuggestedId: nil,
            confidence: nil,
            notes: nil,
            source: .camera,
            createdAt: Timestamp(date: Date()),
            updatedAt: Timestamp(date: Date()),
            error: nil
        ),
        
        // Needs Review - Low Confidence
        Receipt(
            id: "receipt_needs_review_1",
            status: .needsReview,
            imagePath: "mock/receipt2",
            rawText: "MIGROS\n28.12.2024\n45,50 TL",
            merchant: "Migros",
            date: Date(),
            total: 45.50,
            currency: "TRY",
            categoryId: nil,
            categorySuggestedId: "food_drink",
            confidence: 0.65,
            notes: nil,
            source: .camera,
            createdAt: Timestamp(date: Date().addingTimeInterval(-3600)),
            updatedAt: Timestamp(date: Date().addingTimeInterval(-3600)),
            error: nil
        ),
        
        Receipt(
            id: "receipt_needs_review_2",
            status: .needsReview,
            imagePath: "mock/receipt3",
            rawText: "STARBUCKS\n27.12.2024\n85 TL",
            merchant: "Starbucks",
            date: Date().addingTimeInterval(-86400),
            total: 85.0,
            currency: "TRY",
            categoryId: nil,
            categorySuggestedId: "food_drink",
            confidence: 0.72,
            notes: nil,
            source: .gallery,
            createdAt: Timestamp(date: Date().addingTimeInterval(-86400)),
            updatedAt: Timestamp(date: Date().addingTimeInterval(-86400)),
            error: nil
        ),
        
        // Approved - High Confidence
        Receipt(
            id: "receipt_approved_1",
            status: .approved,
            imagePath: "mock/receipt4",
            rawText: "SHELL\n26.12.2024\n250,00 TL",
            merchant: "Shell",
            date: Date().addingTimeInterval(-2 * 86400),
            total: 250.0,
            currency: "TRY",
            categoryId: "transport",
            categorySuggestedId: "transport",
            confidence: 0.95,
            notes: nil,
            source: .camera,
            createdAt: Timestamp(date: Date().addingTimeInterval(-2 * 86400)),
            updatedAt: Timestamp(date: Date().addingTimeInterval(-2 * 86400)),
            error: nil
        ),
        
        Receipt(
            id: "receipt_approved_2",
            status: .approved,
            imagePath: "mock/receipt5",
            rawText: "TEKNOSA\n25.12.2024\n1.250,00 TL",
            merchant: "Teknosa",
            date: Date().addingTimeInterval(-3 * 86400),
            total: 1250.0,
            currency: "TRY",
            categoryId: "equipment",
            categorySuggestedId: "equipment",
            confidence: 0.88,
            notes: "Klavye ve mouse",
            source: .camera,
            createdAt: Timestamp(date: Date().addingTimeInterval(-3 * 86400)),
            updatedAt: Timestamp(date: Date().addingTimeInterval(-3 * 86400)),
            error: nil
        ),
        
        Receipt(
            id: "receipt_approved_3",
            status: .approved,
            imagePath: "mock/receipt6",
            rawText: "A101\n24.12.2024\n120,50 TL",
            merchant: "A101",
            date: Date().addingTimeInterval(-4 * 86400),
            total: 120.50,
            currency: "TRY",
            categoryId: "food_drink",
            categorySuggestedId: "food_drink",
            confidence: 0.91,
            notes: nil,
            source: .camera,
            createdAt: Timestamp(date: Date().addingTimeInterval(-4 * 86400)),
            updatedAt: Timestamp(date: Date().addingTimeInterval(-4 * 86400)),
            error: nil
        ),
        
        // Error
        Receipt(
            id: "receipt_error",
            status: .error,
            imagePath: "mock/receipt7",
            rawText: "Blurry text, unreadable",
            merchant: nil,
            date: nil,
            total: nil,
            currency: "TRY",
            categoryId: nil,
            categorySuggestedId: nil,
            confidence: nil,
            notes: nil,
            source: .camera,
            createdAt: Timestamp(date: Date().addingTimeInterval(-5 * 86400)),
            updatedAt: Timestamp(date: Date().addingTimeInterval(-5 * 86400)),
            error: "OCR failed: Image too blurry"
        )
    ]
    
    // MARK: - Sample Categories
    static let sampleCategories: [Category] = Category.defaults
    
    // MARK: - Sample User Profile
    static let sampleUser = UserProfile(
        createdAt: Timestamp(date: Date().addingTimeInterval(-30 * 86400)),
        locale: "tr-TR",
        currencyDefault: "TRY"
    )
    
    // MARK: - Sample Entitlements
    static let sampleEntitlementsFree = Entitlements(
        isPro: false,
        receiptCount: 15,
        monthKey: currentMonthKey(),
        expiresAt: nil,
        productId: nil,
        originalTransactionId: nil,
        createdAt: Timestamp(date: Date().addingTimeInterval(-30 * 86400)),
        updatedAt: Timestamp(date: Date())
    )
    
    static let sampleEntitlementsPro = Entitlements(
        isPro: true,
        receiptCount: 45,
        monthKey: currentMonthKey(),
        expiresAt: Timestamp(date: Date().addingTimeInterval(30 * 86400)),
        productId: "slipbox_pro_monthly",
        originalTransactionId: "mock_transaction_123",
        createdAt: Timestamp(date: Date().addingTimeInterval(-30 * 86400)),
        updatedAt: Timestamp(date: Date())
    )
    
    // MARK: - Helpers
    private static func currentMonthKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
}
