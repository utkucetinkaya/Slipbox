import SwiftUI
import Combine
import FirebaseFirestore

class ReportsViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var totalExpense: Double = 0
    @Published var receiptCount: Int = 0
    @Published var topCategory: String = "n/a"
    @Published var categoryBreakdown: [CategorySummary] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let repository = FirestoreReceiptRepository.shared
    private let currencyService = CurrencyService.shared
    private let userPreferences = AppUserPreferences.shared // Access singleton directly or inject if preferred. Using shared for simplicity as VM is @StateObject.
    
    struct CategorySummary: Identifiable {
        let id = UUID()
        let categoryId: String?
        let name: String
        let amount: Double
        let count: Int
        let percent: Double
        
        var color: Color {
            // Map common IDs to colors
            switch categoryId {
            case "food_drink": return Color(hex: "34C759")
            case "transport": return Color(hex: "FFCC00")
            case "equipment": return Color(hex: "FF3B30")
            case "service": return Color(hex: "06B6D4")
            default: return Color(hex: "4F46E5")
            }
        }
    }
    
    init() {
        setupSubscription()
    }
    
    private func setupSubscription() {
        // Observe receipts, date, currency changes, AND rates availability from the service
        Publishers.CombineLatest4(
            repository.$receipts,
            $currentDate,
            userPreferences.$currencyCode,
            currencyService.$rates // Listen for rate updates from API
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] receipts, date, currencyCode, _ in
            self?.calculateStats(receipts: receipts, for: date, targetCurrency: currencyCode)
        }
        .store(in: &cancellables)
    }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func calculateStats(receipts: [Receipt], for date: Date, targetCurrency: String) {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        // Calculate the first day of next month, then subtract 1 second to get the very end of the last day of current month
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        let monthEnd = calendar.date(byAdding: .second, value: -1, to: nextMonth)!
        
        let monthReceipts = receipts.filter { receipt in
            // Effective Date Logic:
            // 1. If the receipt has a Recognized Date -> Use it.
            // 2. If not, fallback to the Scan/Creation Date.
            // This ensures a receipt appears in ONE specific month only.
            let effectiveDate = receipt.date ?? receipt.createdAt?.dateValue() ?? Date()
            
            let inMonth = effectiveDate >= monthStart && effectiveDate <= monthEnd
            
            return inMonth && receipt.status == .approved
        }
        
        self.receiptCount = monthReceipts.count
        
        // Calculate Total Expense with Currency Conversion
        self.totalExpense = monthReceipts.reduce(0) { total, receipt in
            let receiptAmount = receipt.total ?? 0
            let receiptCurrency = receipt.currency ?? "TRY" // Default/Fallback
            let convertedAmount = currencyService.convert(receiptAmount, from: receiptCurrency, to: targetCurrency)
            return total + convertedAmount
        }
        
        let grouped = Dictionary(grouping: monthReceipts) { $0.categoryId ?? "other" }
        
        var breakdown: [CategorySummary] = []
        for (catId, items) in grouped {
            
            // Calculate Category Total with Currency Conversion
            let amount = items.reduce(0) { total, item in
                let itemAmount = item.total ?? 0
                let itemCurrency = item.currency ?? "TRY"
                return total + currencyService.convert(itemAmount, from: itemCurrency, to: targetCurrency)
            }
            
            let name = items.first?.displayCategoryName ?? catId
            breakdown.append(CategorySummary(
                categoryId: catId,
                name: name,
                amount: amount,
                count: items.count,
                percent: totalExpense > 0 ? (amount / totalExpense) : 0
            ))
        }
        
        self.categoryBreakdown = breakdown.sorted(by: { $0.amount > $1.amount })
        self.topCategory = categoryBreakdown.first?.name ?? "n/a"
    }
}
