import SwiftUI
import Combine
import FirebaseFirestore

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @State private var selectedMonth = Date()
    @State private var showingExportOptions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Month Picker
                    monthPickerSection
                    
                    // Summary Card
                    summaryCard
                    
                    // Category Breakdown
                    categoryBreakdown
                    
                    // Export Actions (Pro Gated)
                    exportActions
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Raporlar")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadReceipts(for: selectedMonth)
        }
    }
    
    // MARK: - Month Picker
    private var monthPickerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Dönem")
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textSecondary)
            
            DatePicker("", selection: $selectedMonth, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: selectedMonth) { newMonth in
                    Task {
                        await viewModel.loadReceipts(for: newMonth)
                    }
                }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        HStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Toplam Harcama")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
                
                Text(formatCurrency(viewModel.totalAmount))
                    .font(AppFonts.largeTitle())
                    .foregroundColor(AppColors.primary)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Fiş Sayısı")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
                
                Text("\(viewModel.receiptCount)")
                    .font(AppFonts.title())
                    .foregroundColor(AppColors.textPrimary)
                font(.caption.weight(.black))
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Kategoriye Göre")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
            
            if viewModel.categoryBreakdown.isEmpty {
                Text("Bu dönemde harcama yok")
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary)
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity)
                    .cardStyle()
            } else {
                ForEach(viewModel.categoryBreakdown) { item in
                    CategoryBreakdownRow(item: item)
                }
            }
        }
    }
    
    // MARK: - Export Actions
    private var exportActions: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Dışa Aktar")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: { exportPDF() }) {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("PDF İndir")
                    Spacer()
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                }
                .font(AppFonts.body())
                .foregroundColor(AppColors.textPrimary)
                .padding()
                .cardStyle()
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { exportCSV() }) {
                HStack {
                    Image(systemName: "tablecells")
                    Text("CSV İndir")
                    Spacer()
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                }
                .font(AppFonts.body())
                .foregroundColor(AppColors.textPrimary)
                .padding()
                .cardStyle()
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { createShareLink() }) {
                HStack {
                    Image(systemName: "link")
                    Text("Muhasebeci Linki")
                    Spacer()
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                }
                .font(AppFonts.body())
                .foregroundColor(AppColors.textPrimary)
                .padding()
                .cardStyle()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Actions
    @State private var shareURL: URL?
    
    // Helper to open Share Sheet
    private func shareFile(url: URL) {
        shareURL = url
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // Find topmost view controller to present
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            // iPad support
            if let popover = av.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(av, animated: true)
        }
    }
    
    private func exportPDF() {
        // Enforce Pro check locally if needed (StoreKit)
        // For now just generate
        let monthName = DateFormatter().monthSymbols[Calendar.current.component(.month, from: selectedMonth) - 1]
        
        if let url = ExportService.shared.generatePDF(receipts: viewModel.receipts, month: monthName) {
            shareFile(url: url)
        }
    }
    
    private func exportCSV() {
         let monthName = DateFormatter().monthSymbols[Calendar.current.component(.month, from: selectedMonth) - 1]
        
        if let url = ExportService.shared.generateCSV(receipts: viewModel.receipts, month: monthName) {
            shareFile(url: url)
        }
    }
    
    private func createShareLink() {
        // v1: Removed or simply share CSV file as "link" alternative
         let monthName = DateFormatter().monthSymbols[Calendar.current.component(.month, from: selectedMonth) - 1]
        
        if let url = ExportService.shared.generatePDF(receipts: viewModel.receipts, month: monthName) {
             shareFile(url: url)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr-TR")
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) TL"
    }
}

// MARK: - Category Breakdown Row
struct CategoryBreakdownRow: View {
    let item: CategoryBreakdownItem
    
    var body: some View {
        HStack {
            // Category Icon
            if let category = Category.defaults.first(where: { $0.id == item.categoryId }) {
                Image(systemName: category.icon)
                    .foregroundColor(AppColors.primary)
                    .frame(width: 32)
            }
            
            // Category Name
            VStack(alignment: .leading, spacing: 2) {
                Text(item.categoryName)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(item.count) fiş")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(item.total))
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(Int(item.percentage))%")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr-TR")
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) TL"
    }
}

// MARK: - ViewModel
@MainActor
class ReportsViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var totalAmount: Double = 0
    @Published var receiptCount: Int = 0
    @Published var categoryBreakdown: [CategoryBreakdownItem] = []
    
    // Use Firestore repository (Phase 3)
    private let repository: ReceiptRepository = FirestoreReceiptRepository.shared
    
    func loadReceipts(for month: Date) async {
        do {
            // Fetch all approved receipts
            let allReceipts = try await repository.fetchReceipts(status: .approved)
            
            // Filter by month
            let calendar = Calendar.current
            receipts = allReceipts.filter { receipt in
                guard let receiptDate = receipt.date else { return false }
                return calendar.isDate(receiptDate, equalTo: month, toGranularity: .month)
            }
            
            // Calculate summary
            receiptCount = receipts.count
            totalAmount = receipts.compactMap { $0.total }.reduce(0, +)
            
            // Calculate category breakdown
            calculateCategoryBreakdown()
        } catch {
            print("Error loading receipts: \(error)")
        }
    }
    
    private func calculateCategoryBreakdown() {
        var breakdown: [String: (count: Int, total: Double)] = [:]
        
        for receipt in receipts {
            guard let categoryId = receipt.categoryId,
                  let total = receipt.total else { continue }
            
            if var existing = breakdown[categoryId] {
                existing.count += 1
                existing.total += total
                breakdown[categoryId] = existing
            } else {
                breakdown[categoryId] = (count: 1, total: total)
            }
        }
        
        categoryBreakdown = breakdown.map { categoryId, data in
            let category = Category.defaults.first { $0.id == categoryId }
            return CategoryBreakdownItem(
                categoryId: categoryId,
                categoryName: category?.name ?? categoryId,
                count: data.count,
                total: data.total,
                percentage: totalAmount > 0 ? (data.total / totalAmount) * 100 : 0
            )
        }.sorted { $0.total > $1.total }
    }
}

// MARK: - Models
struct CategoryBreakdownItem: Identifiable {
    let id = UUID()
    let categoryId: String
    let categoryName: String
    let count: Int
    let total: Double
    let percentage: Double
}

// MARK: - Preview
#Preview {
    ReportsView()
}
