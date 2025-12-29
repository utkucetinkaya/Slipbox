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
            
            VStack(spacing: 0) {
                // Close Button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "1C1C1E"))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 36))
                                    .foregroundColor(Color(hex: "4F46E5"))
                            }
                            
                            VStack(spacing: 4) {
                                Text("SlipBox Pro ile")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("raporlarını hızlandır.")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(hex: "4F46E5"))
                            }
                            .multilineTextAlignment(.center)
                        }
                        
                        // Features
                        VStack(alignment: .leading, spacing: 16) {
                            FeatureRow(text: "Sınırsız fiş")
                            FeatureRow(text: "PDF/CSV export")
                            FeatureRow(text: "Gelişmiş filtreler")
                        }
                        .padding(.horizontal, 32)
                        
                        // Plans
                        HStack(spacing: 16) {
                            PlanCard(
                                title: "Aylık",
                                price: "₺29.99",
                                period: "/ay",
                                isSelected: selectedPlan == .monthly,
                                action: { selectedPlan = .monthly }
                            )
                            
                            PlanCard(
                                title: "Yıllık",
                                price: "₺299.99",
                                period: "/yıl",
                                badge: "En avantajlı",
                                isSelected: selectedPlan == .yearly,
                                action: { selectedPlan = .yearly }
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 20)
                    }
                }
                
                // Bottom Section
                VStack(spacing: 16) {
                    Button(action: {
                        print("🛒 Purchase initiated for \(selectedPlan)")
                        // Mock purchase success
                        dismiss()
                    }) {
                        Text("Pro'ya Geç")
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
                        Text("İptal etmesi kolay")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "4F46E5").opacity(0.8))
                    
                    HStack(spacing: 16) {
                        Button("Satın alımı geri yükle") {}
                        Text("•")
                        Button("Şartlar") {}
                        Text("•")
                        Button("Gizlilik") {}
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                }
                .padding(20)
                .background(Color(hex: "0A0A14").opacity(0.8))
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
