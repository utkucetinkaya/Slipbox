import SwiftUI


struct OnboardingView: View {
    @Binding var showPermissions: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            title: "onboarding_scan_title".localized,
            description: "onboarding_scan_description".localized,
            imageName: "onboarding1"
        ),
        OnboardingPage(
            title: "onboarding_ai_title".localized,
            description: "onboarding_ai_description".localized,
            imageName: "onboarding_ai"
        ),
        OnboardingPage(
            title: "onboarding_report_title".localized,
            description: "onboarding_report_description".localized,
            imageName: "onboarding_report"
        )
    ]
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 650) // Increased height for better layout
                
                Spacer()
                
                // Styled Indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? DesignSystem.Colors.primary : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 40)
                
                // Button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        // Go to Permissions
                        withAnimation {
                            showPermissions = true
                        }
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "baslayalim".localized : "devam_et".localized)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(DesignSystem.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                // Skip Button
                if currentPage < pages.count - 1 {
                    Button("atla".localized) {
                        withAnimation {
                            showPermissions = true
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.bottom, 20)
                } else {
                    Spacer().frame(height: 40) // Placeholder
                }
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            // Image with Styling
            ZStack {
                // Background Glow Effects
                // Background Glow Effects
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.4))
                    .frame(width: 300, height: 300) // Increased glow size
                    .blur(radius: 70) // Increased blur
                    .offset(x: -40, y: -40)
                
                Circle()
                    .fill(Color(hex: "A855F7").opacity(0.3)) // Secondary purple glow
                    .frame(width: 250, height: 250) // Increased glow size
                    .blur(radius: 60) // Increased blur
                    .offset(x: 40, y: 40)
                
                if let uiImage = UIImage(named: page.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 420) // Increased image height from 350
                        // .cornerRadius(48) // Removed to allow transparent PNG to blend nicely if needed, or keep if card style
                        .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 30, x: 0, y: 0) // Glow effect
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10) // Depth shadow
                } else {
                    // Fallback
                    RoundedRectangle(cornerRadius: 48)
                        .fill(DesignSystem.Colors.inputBackground)
                        .frame(height: 420) // Increased fallback height
                        .overlay(Text("Görsel: \(page.imageName)").foregroundColor(.gray))
                }
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 17))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}
