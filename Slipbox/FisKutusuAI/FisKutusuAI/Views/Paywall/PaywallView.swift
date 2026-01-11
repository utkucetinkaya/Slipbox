import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var storeKitManager: StoreKitManager
    @EnvironmentObject var entitlementManager: EntitlementManager
    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false
    
    enum Plan {
        case monthly
        case yearly
    }
    
    var body: some View {
        ZStack {
            // Dark Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.background,
                    DesignSystem.Colors.surface
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer(minLength: 20) // Moved significantly higher
                        
                        // --- TOP SECTION ---
                        VStack(spacing: 24) {
                            ZStack {
                                // Background Glows
                                Circle()
                                    .fill(DesignSystem.Colors.primary.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 40)
                                
                                Circle()
                                    .fill(DesignSystem.Colors.primary.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 20)
                                
                                Image("AppLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 72, height: 72)
                                    .cornerRadius(18)
                                    .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 15, x: 0, y: 0)
                            }
                            
                            VStack(spacing: 8) {
                                Text("paywall_title".localized)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text("paywall_subtitle".localized)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                
                                Text("paywall_description".localized)
                                    .font(.system(size: 16))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                            }
                            .multilineTextAlignment(.center)
                        }
                        
                        // Features
                        VStack(alignment: .leading, spacing: 16) {
                            FeatureRow(text: "paywall_feature_unlimited".localized)
                            FeatureRow(text: "paywall_feature_export".localized)
                            FeatureRow(text: "paywall_feature_filters".localized)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer(minLength: 80) // Pushes the following plans and button lower
                        
                        // --- BOTTOM SECTION ---
                        VStack(spacing: 32) {
                            // Plans
                            HStack(spacing: 12) {
                                let monthlyProduct = storeKitManager.products.first(where: { $0.id == "com.slipbox.pro.monthly" })
                                let yearlyProduct = storeKitManager.products.first(where: { $0.id == "com.slipbox.pro.yearly" })
                                
                                PlanCard(
                                    title: "paywall_monthly".localized,
                                    price: monthlyProduct?.displayPrice ?? "₺29.99",
                                    period: "/mo",
                                    isSelected: selectedPlan == .monthly,
                                    action: { selectedPlan = .monthly }
                                )
                                
                                PlanCard(
                                    title: "paywall_yearly".localized,
                                    price: yearlyProduct?.displayPrice ?? "₺299.99",
                                    period: "/yr",
                                    badge: "paywall_badge_best".localized,
                                    isSelected: selectedPlan == .yearly,
                                    action: { selectedPlan = .yearly }
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                let productID = selectedPlan == .yearly ? "com.slipbox.pro.yearly" : "com.slipbox.pro.monthly"
                                let isLoaded = storeKitManager.products.contains(where: { $0.id == productID })
                                
                                Button(action: {
                                    purchase()
                                }) {
                                    ZStack {
                                        if isPurchasing {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else if !isLoaded {
                                            HStack(spacing: 8) {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                Text("paywall_loading_products".localized)
                                            }
                                        } else {
                                            Text("paywall_cta".localized)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "4F46E5").opacity((isPurchasing || !isLoaded) ? 0.6 : 1.0))
                                    .cornerRadius(28)
                                    .shadow(color: Color(hex: "4F46E5").opacity(0.4), radius: 10, x: 0, y: 5)
                                }
                                .disabled(isPurchasing || !isLoaded)
                                
                                Spacer(minLength: 16) // Brings the button and the text closer together
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 12))
                                    Text("paywall_easy_cancel".localized)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                HStack(spacing: 16) {
                                    Button("paywall_restore".localized) {
                                        restore()
                                    }
                                    Text("•")
                                    Link("terms".localized, destination: URL(string: "https://slipbox.app/terms")!)
                                    Text("•")
                                    Link("privacy".localized, destination: URL(string: "https://slipbox.app/privacy")!)
                                }
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10) // Reduced bottom padding to allow spacer to push content closer to edge
                        }
                    }
                }
                
                // Close Button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                            .padding() // Touch target
                    }
                }
                .padding(.top, 10) // Small status bar buffer if needed
                .padding(.trailing, 10)
            }
        }
        .onChange(of: entitlementManager.isPro) { isPro in
            if isPro {
                dismiss()
            }
        }
    }
    
    private func purchase() {
        let productID = selectedPlan == .yearly ? "com.slipbox.pro.yearly" : "com.slipbox.pro.monthly"
        guard let product = storeKitManager.products.first(where: { $0.id == productID }) else { return }
        
        isPurchasing = true
        Task {
            do {
                try await storeKitManager.purchase(product)
                // View will dismiss via onChange of isPro
            } catch {
                print("Purchase failed: \(error)")
                isPurchasing = false
            }
        }
    }
    
    private func restore() {
        Task {
            do {
                try await storeKitManager.restorePurchases()
            } catch {
                print("Restore failed: \(error)")
            }
        }
    }
}

// MARK: - Components

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "4F46E5"))
                .font(.system(size: 20))
            
            Text(text)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    var badge: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(period)
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border, lineWidth: 2)
                )
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "4F46E5"))
                        .cornerRadius(8)
                        .offset(x: -8, y: 8)
                }
            }
        }
    }
}

#Preview {
    PaywallView()
}
