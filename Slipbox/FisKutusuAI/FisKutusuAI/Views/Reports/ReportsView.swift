import SwiftUI

struct ReportsView: View {
    // Mock Data State
    @State private var currentMonth = "Ekim 2023"
    @State private var totalExpense: Double = 12450.00
    @State private var receiptCount = 42
    @State private var topCategory = "Gıda"
    
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "050511")
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
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .scrollContentBackground(.hidden) // Fix for overscroll background
            }
            .navigationTitle("Raporlar")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Month Selector
    private var monthSelector: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(currentMonth)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(12)
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Toplam Gider")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(formatCurrency(totalExpense))
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
                        Text("Fiş Sayısı")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(receiptCount)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "2C2C2E"))
                .cornerRadius(16)
                
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
                        Text("En Çok")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Text(topCategory)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "2C2C2E"))
                .cornerRadius(16)
            }
        }
        .padding(20)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(24)
    }
    
    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Kategori Detayı")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: AllCategoriesView()) {
                    Text("Tümü")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "4F46E5"))
                }
            }
            
            VStack(spacing: 12) {
                CategoryRow(name: "Market", amount: 4200.00, count: 14, percent: 0.35, color: Color(hex: "4F46E5"))
                CategoryRow(name: "Ulaşım", amount: 2100.00, count: 8, percent: 0.17, color: Color(hex: "A855F7"))
                CategoryRow(name: "Eğlence", amount: 1500.00, count: 5, percent: 0.12, color: Color(hex: "FF3B30"))
            }
        }
    }
    
    // MARK: - Export Section
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color(hex: "FFCC00"))
                Text("Dışa Aktar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 16) {
                Button(action: { showingPaywall = true }) {
                    ExportButtonContent(title: "PDF İndir", icon: "doc.text.fill", color: Color(hex: "FF3B30"))
                }
                
                Button(action: { showingPaywall = true }) {
                    ExportButtonContent(title: "CSV İndir", icon: "tablecells.fill", color: Color(hex: "34C759"))
                }
            }
        }
    }
    
    // ... formatCurrency unchanged ...
}

// ... CategoryRow unchanged ...

struct ExportButtonContent: View {
    let title: String
    let icon: String
    let color: Color
    
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
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "FFCC00"))
        }
        .padding()
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(16)
    }
}
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "₺0,00"
    }

struct CategoryRow: View {
    let name: String
    let amount: Double
    let count: Int
    let percent: Double
    let color: Color
    
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
                        .foregroundColor(.white)
                    Text("\(count) Fiş")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(formatCurrency(amount))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Progress Bar
            HStack {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "2C2C2E"))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(color)
                            .frame(width: geometry.size.width * CGFloat(percent), height: 6)
                    }
                }
                .frame(height: 6)
                
                Text("%\(Int(percent * 100))")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 30, alignment: .trailing)
            }
        }
        .padding()
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(16)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "₺0,00"
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
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(16)
        }
    }
}

#Preview {
    ReportsView()
}
