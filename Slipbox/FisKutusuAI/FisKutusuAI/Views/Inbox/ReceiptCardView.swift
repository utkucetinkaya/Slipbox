import SwiftUI

struct ReceiptCardView: View {
    let receipt: Receipt
   

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Receipt thumbnail/icon
            receiptThumbnail
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Merchant name
                Text(receipt.merchant ?? "Bilinmiyor")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                // Date and amount
                HStack {
                    if let date = receipt.date {
                        Text(formatDate(date))
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if let total = receipt.total {
                        Text(formatCurrency(total, currency: receipt.currency ?? "TRY"))
                            .font(AppFonts.title2())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                    }
                }
                
                // Category badge or status
                HStack {
                    if receipt.status == .approved, let categoryId = receipt.categoryId {
                        categoryBadge(for: categoryId)
                    } else if receipt.status == .needsReview, let suggestedId = receipt.categorySuggestedId {
                        suggestedCategoryBadge(for: suggestedId, confidence: receipt.confidence ?? 0)
                    } else if receipt.status == .processing {
                        processingBadge
                    } else if receipt.status == .error {
                        errorBadge
                    }
                    
                    Spacer()
                    
                    // Confidence indicator for needs review
                    if receipt.status == .needsReview {
                        confidenceIndicator
                    }
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    // MARK: - Thumbnail
    private var receiptThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                .fill(AppColors.cardBackground)
                .frame(width: 60, height: 60)
            
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Category Badge (Approved)
    private func categoryBadge(for categoryId: String) -> some View {
        let category = Category.defaults.first { $0.id == categoryId }
        
        return HStack(spacing: 4) {
            if let icon = category?.icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(category?.name ?? categoryId)
                .font(AppFonts.caption2())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppColors.success)
        .cornerRadius(AppCornerRadius.sm)
    }
    
    // MARK: - Suggested Category Badge (Needs Review)
    private func suggestedCategoryBadge(for categoryId: String, confidence: Double) -> some View {
        let category = Category.defaults.first { $0.id == categoryId }
        
        return HStack(spacing: 4) {
            if let icon = category?.icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(category?.name ?? categoryId)
                .font(AppFonts.caption2())
            Text("?")
                .font(AppFonts.caption2())
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppColors.warning)
        .cornerRadius(AppCornerRadius.sm)
    }
    
    // MARK: - Processing Badge
    private var processingBadge: some View {
        HStack(spacing: 4) {
            ProgressView()
                .scaleEffect(0.7)
            Text("İşleniyor")
                .font(AppFonts.caption2())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppColors.statusProcessing)
        .cornerRadius(AppCornerRadius.sm)
    }
    
    // MARK: - Error Badge
    private var errorBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
            Text("Hata")
                .font(AppFonts.caption2())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppColors.error)
        .cornerRadius(AppCornerRadius.sm)
    }
    
    // MARK: - Confidence Indicator
    private var confidenceIndicator: some View {
        let confidence = receipt.confidence ?? 0
        let percentage = Int(confidence * 100)
        
        return Text("\(percentage)%")
            .font(AppFonts.caption())
            .foregroundColor(confidenceColor(confidence))
            .fontWeight(.semibold)
    }
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr-TR")
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "tr-TR")
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return AppColors.success
        } else if confidence >= 0.5 {
            return AppColors.warning
        } else {
            return AppColors.error
        }
    }
}

// MARK: - Preview
#Preview("Needs Review") {
    VStack {
        ReceiptCardView(receipt: MockData.sampleReceipts[1])
        ReceiptCardView(receipt: MockData.sampleReceipts[2])
    }
    .padding()
}

#Preview("Approved") {
    VStack {
        ReceiptCardView(receipt: MockData.sampleReceipts[3])
        ReceiptCardView(receipt: MockData.sampleReceipts[4])
    }
    .padding()
}

#Preview("Processing & Error") {
    VStack {
        ReceiptCardView(receipt: MockData.sampleReceipts[0])
        ReceiptCardView(receipt: MockData.sampleReceipts[6])
    }
    .padding()
}
