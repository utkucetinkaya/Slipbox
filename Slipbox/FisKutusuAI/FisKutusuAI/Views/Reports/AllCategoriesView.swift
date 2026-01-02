import SwiftUI


struct AllCategoriesView: View {
    @EnvironmentObject var userPreferences: AppUserPreferences
    @StateObject private var viewModel = ReportsViewModel()
    
    private var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = userPreferences.locale
        return formatter.string(from: viewModel.currentDate)
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Month Selector
                HStack {
                    Spacer()
                    Menu {
                        ForEach(0..<12, id: \.self) { i in
                            let date = Calendar.current.date(byAdding: .month, value: -i, to: Date()) ?? Date()
                            Button(action: {
                                viewModel.currentDate = date
                            }) {
                                Text(formatMonth(date))
                            }
                        }
                    } label: {
                        HStack {
                            Text(formattedMonth)
                            Image(systemName: "chevron.down")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(20)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                
                // Total Expense
                VStack(spacing: 4) {
                    Text("total_spending_label".localized)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(formatCurrency(viewModel.totalExpense))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .padding(.bottom, 24)
                
                // Category List
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.categoryBreakdown.isEmpty {
                            Text("reports_no_data".localized)
                                .font(.system(size: 14))
                                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.7))
                                .padding(.top, 40)
                        } else {
                            ForEach(viewModel.categoryBreakdown) { summary in
                                AllCategoryRow(summary: summary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("view_all".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = userPreferences.locale
        return formatter.string(from: date)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = userPreferences.currencyCode
        formatter.currencySymbol = userPreferences.currencySymbol
        formatter.locale = userPreferences.locale
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(userPreferences.currencySymbol)0.00"
    }
}

struct AllCategoryRow: View {
    let summary: ReportsViewModel.CategorySummary
    @EnvironmentObject var userPreferences: AppUserPreferences
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Icon
                Circle()
                    .fill(summary.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "cart.fill") // We can map this later if needed
                            .foregroundColor(summary.color)
                            .font(.system(size: 20))
                    )
                
                // Name & Count
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.name.localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    let suffix = summary.count == 1 ? "transaction_suffix_singular".localized : "transaction_suffix_plural".localized
                    Text("\(summary.count) \(suffix)")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // Amount & Percentage
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(summary.amount))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("%\(Int(summary.percent * 100))")
                        .font(.system(size: 14))
                        .foregroundColor(summary.color)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DesignSystem.Colors.inputBackground)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(summary.color)
                        .frame(width: geometry.size.width * CGFloat(summary.percent), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(20)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = userPreferences.currencyCode
        formatter.currencySymbol = userPreferences.currencySymbol
        formatter.locale = userPreferences.locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0 
        return formatter.string(from: NSNumber(value: value)) ?? "\(userPreferences.currencySymbol)0"
    }
}

#Preview {
    NavigationStack {
        AllCategoriesView()
    }
}
