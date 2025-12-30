import SwiftUI


struct AllCategoriesView: View {
    @EnvironmentObject var userPreferences: AppUserPreferences
    @State private var currentDate = Date()
    
    // Mock Data based on design
    struct CategoryData: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: Color
        let count: Int
        let amount: Double
        let percentage: Double
    }
    
    let categories: [CategoryData] = [
        CategoryData(name: "Market", icon: "cart.fill", color: Color(hex: "4F46E5"), count: 32, amount: 8200.00, percentage: 0.334),
        CategoryData(name: "Ulaşım", icon: "car.fill", color: Color(hex: "FF9500"), count: 18, amount: 4500.00, percentage: 0.183),
        CategoryData(name: "Restoran & Kafe", icon: "fork.knife", color: Color(hex: "FF2D55"), count: 12, amount: 3200.00, percentage: 0.13),
        CategoryData(name: "Faturalar", icon: "doc.text.fill", color: Color(hex: "FFCC00"), count: 4, amount: 2100.00, percentage: 0.085),
        CategoryData(name: "Giyim", icon: "tshirt.fill", color: Color(hex: "AF52DE"), count: 2, amount: 1800.00, percentage: 0.073),
        CategoryData(name: "Sağlık", icon: "heart.fill", color: Color(hex: "34C759"), count: 3, amount: 950.00, percentage: 0.038),
        CategoryData(name: "Eğlence", icon: "film.fill", color: Color(hex: "FF3B30"), count: 5, amount: 600.00, percentage: 0.024),
        CategoryData(name: "Diğer", icon: "ellipsis", color: .gray, count: 8, amount: 3150.00, percentage: 0.128)
    ]
    
    private var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = userPreferences.locale
        return formatter.string(from: currentDate)
    }
    
    var body: some View {
        ZStack {
            Color(hex: "050511")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Month Selector
                HStack {
                    Spacer()
                    Menu {
                        ForEach(0..<12, id: \.self) { i in
                            let date = Calendar.current.date(byAdding: .month, value: -i, to: Date()) ?? Date()
                            Button(action: {
                                currentDate = date
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
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(20)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                
                // Total Expense
                VStack(spacing: 4) {
                    Text("TOPLAM HARCAMA")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(formatCurrency(24500.00))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 24)
                
                // Category List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(categories) { category in
                            AllCategoryRow(data: category)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Tüm Kategoriler")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.white)
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
    let data: AllCategoriesView.CategoryData
    @EnvironmentObject var userPreferences: AppUserPreferences
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Icon
                Circle()
                    .fill(data.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: data.icon)
                            .foregroundColor(data.color)
                            .font(.system(size: 20))
                    )
                
                // Name & Count
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(data.count) İşlem")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Amount & Percentage
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(data.amount))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("%\(String(format: "%.1f", data.percentage * 100))")
                        .font(.system(size: 14))
                        .foregroundColor(data.color)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "2C2C2E"))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(data.color)
                        .frame(width: geometry.size.width * CGFloat(data.percentage), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color(hex: "1C1C1E"))
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
