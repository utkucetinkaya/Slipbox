import SwiftUI

struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        static let primary = Color(hex: "4F46E5")
        static let background = Color(hex: "050511")
        static let surface = Color(hex: "1C1C1E")
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "8E8E93")
        static let success = Color(hex: "34C759")
        static let warning = Color(hex: "FFCC00")
        static let error = Color(hex: "FF3B30")
        
        static let cardBackground = Color.white.opacity(0.05)
        static let inputBackground = Color.white.opacity(0.05)
        static let border = Color.white.opacity(0.1)
    }
    
    // MARK: - Typography
    struct Typography {
        static func title1(_ text: String) -> Text {
            Text(text).font(.system(size: 32, weight: .bold))
        }
        
        static func title2(_ text: String) -> Text {
            Text(text).font(.system(size: 24, weight: .bold))
        }
        
        static func headline(_ text: String) -> Text {
            Text(text).font(.system(size: 17, weight: .semibold))
        }
        
        static func body(_ text: String) -> Text {
            Text(text).font(.system(size: 16, weight: .regular))
        }
        
        static func caption(_ text: String) -> Text {
            Text(text).font(.system(size: 12, weight: .regular))
        }
    }
    
    // MARK: - Components
    struct Buttons {
        static func primary(title: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
        }
        
        static func secondary(title: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Colors.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Colors.border, lineWidth: 1)
                )
                .foregroundColor(.white)
                .cornerRadius(16)
            }
        }
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
