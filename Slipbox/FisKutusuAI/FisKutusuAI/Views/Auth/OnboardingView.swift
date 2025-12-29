import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "camera.fill",
            title: "Fişi Çek",
            description: "Fişi fotoğrafla, yapay zeka otomatik olarak bilgileri çıkarsın"
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "Otomatik Kategorile",
            description: "Akıllı sistem harcamalarını otomatik olarak kategorize eder"
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Raporla ve Paylaş",
            description: "PDF/CSV raporları oluştur, muhasebeci ile paylaş"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Geç") {
                    dismiss()
                }
                .font(AppFonts.callout())
                .foregroundColor(AppColors.primary)
                .padding(AppSpacing.md)
            }
            
            // Page Content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // Bottom Action
            bottomAction
                .padding(AppSpacing.lg)
        }
    }
    
    // MARK: - Bottom Action
    private var bottomAction: some View {
        Button(action: {
            if currentPage < pages.count - 1 {
                withAnimation {
                    currentPage += 1
                }
            } else {
                dismiss()
            }
        }) {
            Text(currentPage < pages.count - 1 ? "Devam" : "Başla")
                .primaryButton()
        }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundColor(AppColors.primary)
            }
            
            // Title
            Text(page.title)
                .font(AppFonts.largeTitle())
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            // Description
            Text(page.description)
                .font(AppFonts.body())
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            
            Spacer()
        }
    }
}

// MARK: - Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Preview
#Preview {
    OnboardingView()
}
