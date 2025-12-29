import SwiftUI

// MARK: - App Colors (Dark Mode Support)
enum AppColors {
    // Adaptive colors - defined in Assets.xcassets Color Set
    static let primary = Color("AccentColor")
    static let secondary = Color("SecondaryAccent")
    static let background = Color("Background")
    static let cardBackground = Color("CardBackground")
    
    // Semantic colors
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // Status colors
    static let statusProcessing = Color.blue
    static let statusNeedsReview = Color.orange
    static let statusApproved = Color.green
    static let statusError = Color.red
}

// MARK: - App Fonts (Dynamic Type Support)
enum AppFonts {
    static func largeTitle() -> Font { .largeTitle.weight(.bold) }
    static func title() -> Font { .title.weight(.bold) }
    static func title2() -> Font { .title2.weight(.semibold) }
    static func headline() -> Font { .headline.weight(.semibold) }
    static func body() -> Font { .body }
    static func callout() -> Font { .callout }
    static func caption() -> Font { .caption }
    static func caption2() -> Font { .caption2 }
}

// MARK: - App Spacing
enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - App Corner Radius
enum AppCornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Helper Extensions
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.md)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    func primaryButton() -> some View {
        self
            .font(AppFonts.headline())
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppColors.primary)
            .cornerRadius(AppCornerRadius.md)
    }
    
    func secondaryButton() -> some View {
        self
            .font(AppFonts.headline())
            .foregroundColor(AppColors.primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .stroke(AppColors.primary, lineWidth: 2)
            )
    }
}
