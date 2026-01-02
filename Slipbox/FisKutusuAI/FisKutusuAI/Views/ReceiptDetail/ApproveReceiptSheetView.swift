import SwiftUI

struct ApproveReceiptSheetView: View {
    let receipt: Receipt
    let onApprove: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Drag Indicator
                Capsule()
                    .fill(DesignSystem.Colors.textSecondary.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "4F46E5").opacity(0.2))
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                    
                    Circle()
                        .stroke(Color(hex: "4F46E5").opacity(0.5), lineWidth: 1)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(Color(hex: "4F46E5").opacity(0.1))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "4F46E5"))
                }
                
                VStack(spacing: 12) {
                    Text("approve_receipt_title".localized)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("approve_receipt_message".localized)
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Mini Receipt Card
                HStack(spacing: 16) {
                    // Thumbnail
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color(hex: "2C2C2E"))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Group {
                                    if let uiImage = ImageStorageService.shared.loadImage(from: receipt.imageLocalPath) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 48, height: 48)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            )
                        
                        Circle()
                            .fill(Color(hex: "34C759"))
                            .frame(width: 16, height: 16)
                            .offset(x: 2, y: 2)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(receipt.displayMerchant)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text(formatDate(receipt.displayDate))
                                .font(.system(size: 12))
                        }
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(formatAmount(receipt.displayAmount))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .padding(16)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: onApprove) {
                        HStack {
                            Text("yes_approve".localized)
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "4F46E5"))
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "4F46E5").opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("cancel".localized)
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.height(550)])
        .presentationCornerRadius(32)
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = AppUserPreferences.shared.currencyCode
        formatter.locale = AppUserPreferences.shared.locale
        return formatter.string(from: amount as NSDecimalNumber) ?? "0,00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, HH:mm"
        formatter.locale = AppUserPreferences.shared.locale
        return formatter.string(from: date)
    }
}

#Preview {
    ApproveReceiptSheetView(
        receipt: Receipt(
            id: "preview_approve",
            status: .pendingReview,
            imageLocalPath: "",
            merchantName: "Global Market",
            date: Date(),
            total: 250.00,
            currency: "USD",
            categoryName: "category_food",
            source: .camera
        ),
        onApprove: {}
    )
}
