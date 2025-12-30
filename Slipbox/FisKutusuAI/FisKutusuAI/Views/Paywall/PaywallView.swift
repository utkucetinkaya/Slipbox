import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: Plan = .yearly
    
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
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
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
                                Text("paywall_title")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("paywall_subtitle")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(hex: "4F46E5"))
                                
                                Text("paywall_description")
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
                            FeatureRow(text: "paywall_feature_unlimited")
                            FeatureRow(text: "paywall_feature_export")
                            FeatureRow(text: "paywall_feature_filters")
                        }
                        .padding(.horizontal, 32)
                        
                        // Plans
                        HStack(spacing: 16) {
                            PlanCard(
                                title: "paywall_monthly",
                                price: "₺29.99",
                                period: "/mo",
                                isSelected: selectedPlan == .monthly,
                                action: { selectedPlan = .monthly }
                            )
                            
                            PlanCard(
                                title: "paywall_yearly",
                                price: "₺299.99",
                                period: "/yr",
                                badge: "paywall_badge_best",
                                isSelected: selectedPlan == .yearly,
                                action: { selectedPlan = .yearly }
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Bottom Section (Moved inside ScrollView or kept at bottom? Kept at bottom of scroll usually for long content, but here fits.)
                        // BUT common pattern is sticky bottom button OR scrollable.
                        // Let's keep it scrollable for safety on small screens.
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                print("🛒 Purchase initiated for \(selectedPlan)")
                                // Mock purchase success
                                dismiss()
                            }) {
                                Text("paywall_cta")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "4F46E5"))
                                    .cornerRadius(28)
                                    .shadow(color: Color(hex: "4F46E5").opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 12))
                                Text("paywall_easy_cancel")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.white.opacity(0.7)) // More neutral and clean
                            
                            HStack(spacing: 16) {
                                Button("paywall_restore") {}
                                Text("•")
                                Button("terms") {}
                                Text("•")
                                Button("privacy") {}
                            }
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(20)
                        // Removed discordant background to blend with page
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 60) // Space for the close button
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
