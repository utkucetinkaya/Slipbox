import SwiftUI

struct OnboardingView: View {
    @Binding var showPermissions: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            title: "Fişi Çek",
            description: "Fişlerinizi saniyeler içinde tarayın. Akıllı kameramız detayları otomatik yakalar.",
            imageName: "download-4"
        ),
        OnboardingPage(
            title: "Otomatik Kategorile",
            description: "Fişlerinizi tarayın, yapay zeka onları saniyeler içinde harcama türüne göre ayırsın.",
            imageName: "download-5"
        ),
        OnboardingPage(
            title: "Raporla",
            description: "Harcamalarınızı grafiklerle analiz edin ve bütçenizi kontrol altında tutun.",
            imageName: "download-6"
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
                .frame(height: 550) // Increased height for better layout
                
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
                    Text(currentPage == pages.count - 1 ? "Başlayalım" : "Devam Et")
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
                    Button("Atla") {
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
            if let uiImage = UIImage(named: page.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit) // Changed to .fit for better display
                    .frame(maxWidth: .infinity)
                    .frame(height: 350)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 24)
            } else {
                // Fallback
                RoundedRectangle(cornerRadius: 24)
                    .fill(DesignSystem.Colors.inputBackground)
                    .frame(height: 350)
                    .padding(.horizontal, 24)
                    .overlay(Text("Görsel: \(page.imageName)").foregroundColor(.gray))
            }
            
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
