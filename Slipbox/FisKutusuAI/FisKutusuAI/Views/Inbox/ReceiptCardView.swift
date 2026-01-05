import SwiftUI

struct ReceiptCardView: View {
    let receipt: Receipt
    @EnvironmentObject var userPreferences: AppUserPreferences
    @EnvironmentObject var localizationManager: LocalizationManager
    @ObservedObject var currencyService = CurrencyService.shared // Observe updates
    
    var body: some View {
        HStack(spacing: 16) {
            thumbnailView
            contentView
        }
        .padding(16)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
    
    private var thumbnailView: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(DesignSystem.Colors.inputBackground)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                )
            
            statusBadge
        }
    }
    
    private var statusBadge: some View {
        Circle()
            .fill(receipt.status.badgeColor)
            .frame(width: 24, height: 24)
            .overlay(badgeIcon)
            .offset(x: 4, y: 4)
    }
    
    @ViewBuilder
    private var badgeIcon: some View {
        if receipt.status == .processing || receipt.status == .new {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.7)
        } else {
            Image(systemName: receipt.status.iconName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            headerRow
            dateStatusRow
            categoryRow
        }
    }
    
    private var headerRow: some View {
        HStack {
            Text(receipt.displayMerchant)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            // Calculate converted amount
            let amount = receipt.total ?? 0
            let fromCurrency = receipt.currency ?? "TRY"
            let targetCurrency = userPreferences.currencyCode
            let converted = currencyService.convert(amount, from: fromCurrency, to: targetCurrency)
            
            Text(formatAmount(converted))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "4F46E5"))
        }
    }
    
    private var dateStatusRow: some View {
        HStack(spacing: 8) {
            Text(formatDate(receipt.displayDate))
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("•")
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
            
            Text(receipt.status.displayText)
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
    
    private var categoryRow: some View {
        HStack(spacing: 8) {
            if let categoryName = receipt.displayCategoryName {
                categoryPill(categoryName)
            }
            
            if let confidence = receipt.confidence, receipt.status == .approved {
                confidencePill(confidence)
            }
        }
        .padding(.top, 4)
    }
    
    private func categoryPill(_ name: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(receipt.displayCategoryColor)
                .frame(width: 6, height: 6)
            
            Text(name.localized)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(receipt.displayCategoryColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(receipt.displayCategoryColor.opacity(0.15))
        .cornerRadius(12)
    }
    
    private func confidencePill(_ confidence: Double) -> some View {
        Text("\(Int(confidence * 100))%")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "34C759"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: "34C759").opacity(0.15))
            .cornerRadius(12)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(DesignSystem.Colors.surface.opacity(0.6))
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = userPreferences.currencyCode
        formatter.currencySymbol = userPreferences.currencySymbol // Explicit symbol
        formatter.locale = userPreferences.locale
        return formatter.string(from: NSNumber(value: amount)) ?? "0,00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = userPreferences.locale
        return formatter.string(from: date)
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        VStack(spacing: 16) {
            ReceiptCardView(receipt: Receipt(
                id: "preview_1",
                status: .new,
                imageLocalPath: "",
                merchantName: "Preview Store",
                date: Date(),
                total: 45.99,
                currency: "USD",
                categoryName: "category_food",
                source: .camera
            ))
            
            ReceiptCardView(receipt: Receipt(
                id: "preview_2",
                status: .pendingReview,
                imageLocalPath: "",
                merchantName: "Review Needed",
                date: Date(),
                total: 120.00,
                currency: "USD",
                categoryName: "category_other",
                source: .gallery
            ))
        }
        .padding()
    }
    .environmentObject(AppUserPreferences.shared)
    .environmentObject(LocalizationManager.shared)
}
