import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var userPreferences: AppUserPreferences
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var entitlementManager: EntitlementManager
    
    @StateObject private var viewModel = ReportsViewModel()
    @State private var showingPaywall = false
    @State private var showingComingSoon = false
    
    private var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = userPreferences.locale
        return formatter.string(from: viewModel.currentDate)
    }
    
    private func changeMonth(by value: Int) {
        viewModel.changeMonth(by: value)
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Month Selector
                        monthSelector
                        
                        // Summary Card
                        summaryCard
                        
                        // Category Breakdown
                        categoryBreakdown
                        
                        // Export Section
                        exportSection
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .scrollContentBackground(.hidden)
                .background(DesignSystem.Colors.background.ignoresSafeArea()) // Fix overscroll
            }
            .navigationTitle("reports_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onAppear {
                FirestoreReceiptRepository.shared.startListening()
            }
            .alert("service_coming_soon_title".localized, isPresented: $showingComingSoon) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("service_coming_soon_message".localized)
            }
        }
    }
    
    // MARK: - Month Selector
    private var monthSelector: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(formattedMonth)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("total_expense".localized)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(formatCurrency(viewModel.totalExpense))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Color(hex: "4F46E5"))
            }
            .padding(.bottom, 8)
            
            HStack(spacing: 16) {
                // Receipt Count
                VStack(alignment: .leading, spacing: 8) {
                    Circle()
                        .fill(Color(hex: "FFCC00").opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "FFCC00"))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("receipt_count".localized)
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text("\(viewModel.receiptCount)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
                
                // Top Category
                VStack(alignment: .leading, spacing: 8) {
                    Circle()
                        .fill(Color(hex: "34C759").opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "cart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "34C759"))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("top_category".localized)
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(viewModel.topCategory.localized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
            }
        }
        .padding(20)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(24)
    }
    
    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("category_detail".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: AllCategoriesView()) {
                    Text("view_all".localized)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "4F46E5"))
                }
            }
            
            VStack(spacing: 12) {
                if viewModel.categoryBreakdown.isEmpty {
                    Text("reports_no_data".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                        .padding()
                } else {
                    ForEach(viewModel.categoryBreakdown.prefix(3)) { summary in
                        CategoryRow(
                            name: summary.name.localized,
                            amount: summary.amount,
                            count: summary.count,
                            percent: summary.percent,
                            color: summary.color
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Export Section
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color(hex: "FFCC00"))
                Text("export".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: { 
                        if entitlementManager.isPro {
                            exportPDF()
                        } else {
                            showingPaywall = true 
                        }
                    }) {
                        ExportButtonContent(title: "export_pdf".localized, icon: "doc.text.fill", color: Color(hex: "FF3B30"), isLocked: !entitlementManager.isPro)
                    }
                    
                    Button(action: { 
                        if entitlementManager.isPro {
                            exportCSV()
                        } else {
                            showingPaywall = true 
                        }
                    }) {
                        ExportButtonContent(title: "export_csv".localized, icon: "tablecells.fill", color: Color(hex: "34C759"), isLocked: !entitlementManager.isPro)
                    }
                }
                
                Button(action: { 
                    if entitlementManager.isPro {
                        shareAccountingLink()
                    } else {
                        showingPaywall = true 
                    }
                }) {
                    ExportButtonContent(title: "export_link".localized, icon: "link", color: Color(hex: "007AFF"), isLocked: !entitlementManager.isPro)
                }
            }
        }
    }
    
    private func exportPDF() {
        guard let url = ExportService.shared.generatePDF(
            receipts: viewModel.filteredReceipts,
            month: formattedMonth,
            totalExpense: viewModel.totalExpense,
            totalVat: viewModel.totalVat,
            currencyCode: userPreferences.currencyCode
        ) else { return }
        shareFile(url: url)
    }
    
    private func exportCSV() {
        guard let url = ExportService.shared.generateCSV(receipts: viewModel.filteredReceipts, month: formattedMonth) else { return }
        shareFile(url: url)
    }
    
    private func shareAccountingLink() {
        if entitlementManager.isPro {
            showingComingSoon = true
        } else {
            showingPaywall = true
        }
    }
    
    private func shareFile(url: URL) {
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // Fix for iPad and general presentation stability
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            
            let topVC = getTopViewController(from: rootVC)
            
            // For iPad
            if let popoverController = av.popoverPresentationController {
                popoverController.sourceView = topVC.view
                popoverController.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            topVC.present(av, animated: true)
        }
    }
    
    private func getTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return getTopViewController(from: presented)
        }
        if let nav = viewController as? UINavigationController {
            return getTopViewController(from: nav.visibleViewController ?? nav)
        }
        if let tab = viewController as? UITabBarController {
            return getTopViewController(from: tab.selectedViewController ?? tab)
        }
        return viewController
    }
    
    // ... formatCurrency unchanged ...
}

// ... CategoryRow unchanged ...

struct ExportButtonContent: View {
    let title: String
    let icon: String
    let color: Color
    let isLocked: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 14))
                )
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "FFCC00"))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
    }
}
    


struct CategoryRow: View {
    let name: String
    let amount: Double
    let count: Int
    let percent: Double
    let color: Color
    @EnvironmentObject var userPreferences: AppUserPreferences
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "bag.fill") // Generic icon for now
                            .foregroundColor(color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Text("\(count) " + "receipt_suffix".localized)
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Text(formatCurrency(amount))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            // Progress Bar
            HStack {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DesignSystem.Colors.inputBackground)
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(color)
                            .frame(width: geometry.size.width * CGFloat(percent), height: 6)
                    }
                }
                .frame(height: 6)
                
                Text("%\(Int(percent * 100))")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 30, alignment: .trailing)
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
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

struct ExportButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Stub action
        }) {
            HStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.system(size: 14))
                    )
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "FFCC00"))
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(16)
        }
    }
}

#Preview {
    ReportsView()
}
