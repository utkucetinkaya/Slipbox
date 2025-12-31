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
                    Color(hex: "0A0A14"),
                    Color(hex: "1C1C1E")
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
                                Circle()
                                    .fill(Color(hex: "1C1C1E"))
                                    .frame(width: 100, height: 100)
                                    .shadow(color: DesignSystem.Colors.primary.opacity(0.5), radius: 20, x: 0, y: 0) // Glow effect
                                
                                Image("AppLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(14)
                            }
                            
                            VStack(spacing: 8) {
                                Text("paywall_title".localized)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("paywall_subtitle".localized)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(hex: "4F46E5"))
                                
                                Text("paywall_description".localized)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
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
                                let monthlyProduct = storeKitManager.products.first(where: { $0.id == "slipbox_pro_monthly" })
                                let yearlyProduct = storeKitManager.products.first(where: { $0.id == "slipbox_pro_yearly" })
                                
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
                                Button(action: {
                                    purchase()
                                }) {
                                    ZStack {
                                        if isPurchasing {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("paywall_cta".localized)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "4F46E5").opacity(isPurchasing ? 0.6 : 1.0))
                                    .cornerRadius(28)
                                    .shadow(color: Color(hex: "4F46E5").opacity(0.4), radius: 10, x: 0, y: 5)
                                }
                                .disabled(isPurchasing)
                                
                                Spacer(minLength: 16) // Brings the button and the text closer together
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 12))
                                    Text("paywall_easy_cancel".localized)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.white.opacity(0.7))
                                
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
                                .foregroundColor(.white.opacity(0.4))
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
                            .foregroundColor(.white.opacity(0.3))
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
        let productID = selectedPlan == .yearly ? "slipbox_pro_yearly" : "slipbox_pro_monthly"
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
                .foregroundColor(.white)
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
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(period)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(hex: "1C1C1E"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color(hex: "4F46E5") : Color.white.opacity(0.1), lineWidth: 2)
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
