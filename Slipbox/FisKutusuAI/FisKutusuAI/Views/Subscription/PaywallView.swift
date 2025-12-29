import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var isPurchasing = false
    
    enum SubscriptionPlan {
        case monthly
        case yearly
        
        var title: String {
            switch self {
            case .monthly: return "Aylık"
            case .yearly: return "Yıllık"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "49,99 ₺"
            case .yearly: return "499,99 ₺"
            }
        }
        
        var period: String {
            switch self {
            case .monthly: return "/ ay"
            case .yearly: return "/ yıl"
            }
        }
        
        var discount: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "%17 İndirim"
            }
        }
        
        var productId: String {
            switch self {
            case .monthly: return "slipbox_pro_monthly"
            case .yearly: return "slipbox_pro_yearly"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header
                    header
                    
                    // Features
                    features
                    
                    // Plan Selection
                    planSelection
                    
                    // CTA Button
                    ctaButton
                    
                    // Restore & Continue Free
                    footerActions
                    
                    // Terms
                    terms
                }
                .padding(AppSpacing.lg)
            }
            .background(
                LinearGradient(
                    colors: [AppColors.primary.opacity(0.1), AppColors.cardBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("SlipBox Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Pro'ya Yükselt")
                .font(AppFonts.largeTitle())
                .foregroundColor(AppColors.textPrimary)
            
            Text("Sınırsız fiş, dışa aktarma ve paylaşım")
                .font(AppFonts.body())
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Features
    private var features: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            FeatureRow(icon: "infinity", title: "Sınırsız Fiş", description: "Aylık 20 fiş limiti kalkıyor")
            FeatureRow(icon: "doc.fill", title: "PDF Raporları", description: "Profesyonel PDF raporları oluştur")
            FeatureRow(icon: "tablecells", title: "CSV Dışa Aktar", description: "Verilerini Excel'e aktar")
            FeatureRow(icon: "link", title: "Muhasebeci Paylaş", description: "Güvenli paylaşım linkleri oluştur")
            FeatureRow(icon: "sparkles", title: "Gelecek Özellikler", description: "Yeni Pro özelliklere ilk erişim")
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    // MARK: - Plan Selection
    private var planSelection: some View {
        VStack(spacing: AppSpacing.sm) {
            PlanCard(plan: .monthly, isSelected: selectedPlan == .monthly) {
                selectedPlan = .monthly
            }
            
            PlanCard(plan: .yearly, isSelected: selectedPlan == .yearly) {
                selectedPlan = .yearly
            }
        }
    }
    
    // MARK: - CTA Button
    private var ctaButton: some View {
        Button(action: purchase) {
            if isPurchasing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Devam Et")
                    .primaryButton()
            }
        }
        .disabled(isPurchasing)
    }
    
    // MARK: - Footer Actions
    private var footerActions: some View {
        VStack(spacing: AppSpacing.sm) {
            Button("Satın Alımları Geri Yükle") {
                restorePurchases()
            }
            .font(AppFonts.callout())
            .foregroundColor(AppColors.primary)
            
            Button("Ücretsiz Devam Et") {
                dismiss()
            }
            .font(AppFonts.callout())
            .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Terms
    private var terms: some View {
        Text("Abonelik otomatik olarak yenilenir. İptal etmek için App Store ayarlarını kullanın.")
            .font(AppFonts.caption())
            .foregroundColor(AppColors.textSecondary)
            .multilineTextAlignment(.center)
    }
    
    // MARK: - Actions
    private func purchase() {
        isPurchasing = true
        
        Task {
            // TODO: Implement StoreKit purchase
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            isPurchasing = false
            dismiss()
        }
    }
    
    private func restorePurchases() {
        // TODO: Implement StoreKit restore
        print("Restore purchases")
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let plan: PaywallView.SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let discount = plan.discount {
                        Text(discount)
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.success)
                    }
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(plan.price)
                        .font(AppFonts.title2())
                        .foregroundColor(AppColors.textPrimary)
                        .fontWeight(.bold)
                    
                    Text(plan.period)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .font(.title3)
            }
            .padding(AppSpacing.md)
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    PaywallView()
}
