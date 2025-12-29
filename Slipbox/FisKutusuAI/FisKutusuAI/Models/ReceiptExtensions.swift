import SwiftUI
import FirebaseFirestore

// MARK: - Receipt Display Helpers
extension Receipt {
    var displayMerchant: String {
        merchant ?? "Bilinmeyen"
    }
    
    var displayDate: Date {
        date ?? (createdAt?.dateValue() ?? Date())
    }
    
    var displayAmount: Decimal {
        Decimal(total ?? 0)
    }
    
    var displayCategoryName: String? {
        if let id = categoryId {
            return Category.defaults.first(where: { $0.id == id })?.name ?? id.uppercased()
        }
        return nil
    }
    
    var displayCategoryColor: Color {
        // Map category IDs to colors
        switch categoryId {
        case "food_drink":
            return Color(hex: "34C759")
        case "transport":
            return Color(hex: "FFCC00")
        case "equipment":
            return Color(hex: "FF3B30")
        case "service":
            return Color(hex: "06B6D4")
        default:
            return Color(hex: "4F46E5")
        }
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: displayAmount as NSDecimalNumber) ?? "₺0,00"
    }
}

// MARK: - ReceiptStatus Display Helpers
extension ReceiptStatus {
    var displayText: String {
        switch self {
        case .processing:
            return "İşleme alınıyor..."
        case .needsReview:
            return "İnceleme Gerekli"
        case .approved:
            return "Onaylandı"
        case .error:
            return "Hata"
        }
    }
    
    var iconName: String {
        switch self {
        case .processing:
            return "clock.fill"
        case .needsReview:
            return "exclamationmark.circle.fill"
        case .approved:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .processing:
            return Color(hex: "4F46E5")
        case .needsReview:
            return Color(hex: "FFCC00")
        case .approved:
            return Color(hex: "34C759")
        case .error:
            return Color(hex: "FF3B30")
        }
    }
}
