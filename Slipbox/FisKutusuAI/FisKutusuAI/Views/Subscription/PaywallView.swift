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
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) { // AppSpacing.xl -> 32
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
                .padding(24) // AppSpacing.lg -> 24
            }
            .background(
                LinearGradient(
                    colors: [DesignSystem.Colors.primary.opacity(0.1), DesignSystem.Colors.background],
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
            .background(DesignSystem.Colors.background.ignoresSafeArea())
        }
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 16) { // AppSpacing.md -> 16
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Pro'ya Yükselt")
                .font(.system(size: 32, weight: .bold)) // AppFonts.largeTitle
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Sınırsız fiş, dışa aktarma ve paylaşım")
                .font(.system(size: 16)) // AppFonts.body
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Features
    private var features: some View {
        VStack(alignment: .leading, spacing: 16) { // AppSpacing.md
            FeatureRow(icon: "infinity", title: "Sınırsız Fiş", description: "Aylık 20 fiş limiti kalkıyor")
            FeatureRow(icon: "doc.fill", title: "PDF Raporları", description: "Profesyonel PDF raporları oluştur")
            FeatureRow(icon: "tablecells", title: "CSV Dışa Aktar", description: "Verilerini Excel'e aktar")
            FeatureRow(icon: "link", title: "Muhasebeci Paylaş", description: "Güvenli paylaşım linkleri oluştur")
            FeatureRow(icon: "sparkles", title: "Gelecek Özellikler", description: "Yeni Pro özelliklere ilk erişim")
        }
        .padding(16) // AppSpacing.md
        .background(DesignSystem.Colors.cardBackground) // cardStyle expansion
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
    
    // MARK: - Plan Selection
    private var planSelection: some View {
        VStack(spacing: 8) { // AppSpacing.sm -> 8
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
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(DesignSystem.Colors.primary)
        .foregroundColor(.white)
        .cornerRadius(16) // manual primaryButton style
        .disabled(isPurchasing)
    }
    
    // MARK: - Footer Actions
    private var footerActions: some View {
        VStack(spacing: 8) { // AppSpacing.sm
            Button("Satın Alımları Geri Yükle") {
                restorePurchases()
            }
            .font(.callout)
            .foregroundColor(DesignSystem.Colors.primary)
            
            Button("Ücretsiz Devam Et") {
                dismiss()
            }
            .font(.callout)
            .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
    
    // MARK: - Terms
    private var terms: some View {
        Text("Abonelik otomatik olarak yenilenir. İptal etmek için App Store ayarlarını kullanın.")
            .font(.caption)
            .foregroundColor(DesignSystem.Colors.textSecondary)
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
        HStack(spacing: 16) { // AppSpacing.md
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
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
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if let discount = plan.discount {
                        Text(discount)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(plan.price)
                        .font(.title2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fontWeight(.bold)
                    
                    Text(plan.period)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                    .font(.title3)
            }
            .padding(16) // AppSpacing.md
            .background(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.cardBackground)
            .cornerRadius(12) // AppCornerRadius.md
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    PaywallView()
}
