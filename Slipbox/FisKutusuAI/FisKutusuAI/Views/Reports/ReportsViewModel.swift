import SwiftUI
import Combine

class ReportsViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var totalExpense: Double = 0
    @Published var receiptCount: Int = 0
    @Published var topCategory: String = "n/a"
    @Published var categoryBreakdown: [CategorySummary] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let repository = FirestoreReceiptRepository.shared
    
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
        Publishers.CombineLatest(repository.$receipts, $currentDate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] receipts, date in
                self?.calculateStats(receipts: receipts, for: date)
            }
            .store(in: &cancellables)
    }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func calculateStats(receipts: [Receipt], for date: Date) {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        
        let monthReceipts = receipts.filter { receipt in
            let receiptDate = receipt.displayDate
            return receiptDate >= monthStart && receiptDate <= monthEnd && receipt.status == .approved
        }
        
        self.receiptCount = monthReceipts.count
        self.totalExpense = monthReceipts.reduce(0) { $0 + ($1.total ?? 0) }
        
        let grouped = Dictionary(grouping: monthReceipts) { $0.categoryId ?? "other" }
        
        var breakdown: [CategorySummary] = []
        for (catId, items) in grouped {
            let amount = items.reduce(0) { $0 + ($1.total ?? 0) }
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
