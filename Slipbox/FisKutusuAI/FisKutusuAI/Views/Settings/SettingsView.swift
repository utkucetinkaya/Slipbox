import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var userPreferences: AppUserPreferences
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var entitlementManager: EntitlementManager
    @State private var showingPaywall = false
    @State private var showingFeedback = false
    @State private var remainingScans: Int? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Card
                        profileCard
                        
                        // Preferences
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("preferences".localized.uppercased())
                            
                            NavigationLink(destination: AppearanceSelectionView()) {
                                SettingsRow(icon: "paintbrush.fill", title: "appearance".localized, value: userPreferences.appTheme.localizedName, color: Color(hex: "4F46E5"))
                            }
                            
                            NavigationLink(destination: CurrencySelectionView()) {
                                SettingsRow(icon: "arrow.triangle.2.circlepath", title: "currency".localized, value: "\(userPreferences.currencySymbol) (\(userPreferences.currencyCode))", color: Color(hex: "4F46E5"))
                            }
                            
                            NavigationLink(destination: LanguageSelectionView()) {
                                SettingsRow(icon: "globe", title: "language".localized, value: userPreferences.languageName(for: userPreferences.languageCode), color: Color(hex: "4F46E5"))
                            }
                        }
                        
                        // Support & Legal
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("support_legal".localized)
                            
                            Button(action: { showingFeedback = true }) {
                                SettingsRow(icon: "bubble.left.fill", title: "send_feedback".localized, color: Color(hex: "06B6D4"))
                            }
                            
                            NavigationLink(destination: PrivacyPolicyView()) {
                                SettingsRow(icon: "lock.fill", title: "privacy".localized, color: Color(hex: "A855F7"))
                            }
                            
                            NavigationLink(destination: TermsOfServiceView()) {
                                SettingsRow(icon: "doc.text.fill", title: "terms".localized, color: Color(hex: "FFCC00"))
                            }
                        }
                        
                        // Danger Zone (Only Account Actions)
                        // Simplified for Production - Removed "Danger Zone" Label if redundant or keep minimal
                        VStack(alignment: .leading, spacing: 8) {
                           sectionHeader("account".localized.uppercased())
                            
                            Button(action: { try? AuthenticationManager.shared.signOut() }) {
                                SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "sign_out".localized, color: .red)
                            }

                            NavigationLink(destination: DeleteAccountView()) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: "FF3B30").opacity(0.1))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(Color(hex: "FF3B30"))
                                                .font(.system(size: 14))
                                        )
                                    
                                    Text("delete_account".localized)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(hex: "FF3B30"))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "FF3B30").opacity(0.5))
                                }
                                .padding()
                                .background(DesignSystem.Colors.surface)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "FF3B30").opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        
                        Text("SlipBox v1.0.0 (Build 1)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 20)
                        
                        // Bottom spacing for custom TabBar
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 0) // Removed extra top padding
                }
            }
            .navigationTitle("settings".localized)
            .navigationBarTitleDisplayMode(.inline) // Ensure title is visible and compact
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingFeedback) {
                FeedbackView()
            }
            .onAppear {
                updateRemainingScans()
            }
            .onChange(of: entitlementManager.isPro) { _ in
                updateRemainingScans()
            }
        }
    }
    
    private func updateRemainingScans() {
        Task {
            let remaining = await UsageLimiterService.shared.remainingScans()
            await MainActor.run {
                self.remainingScans = remaining
            }
        }
    }
    
    // MARK: - Components
    
    private var profileCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    if let base64String = authManager.profile?.profileImageUrl,
                       let data = Data(base64Encoded: base64String),
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(hex: "2C2C2E"))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Circle()
                        .fill(Color(hex: "34C759"))
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(DesignSystem.Colors.surface, lineWidth: 2))
                        .offset(x: 22, y: 22)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authManager.profile?.displayName?.isEmpty == false ? authManager.profile!.displayName! : (authManager.user?.email ?? "User"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if entitlementManager.isPro {
                        Text(entitlementManager.planName.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "4F46E5"))
                            .cornerRadius(8)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Button(action: { showingPaywall = true }) {
                                Text("upgrade_now".localized)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(hex: "4F46E5"), Color(hex: "7C3AED")]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: Color(hex: "4F46E5").opacity(0.4), radius: 6, x: 0, y: 3)
                            }
                        }
                    }
                }
                
                Spacer()
                
                NavigationLink(destination: EditProfileView()) {
                    Circle()
                        .fill(DesignSystem.Colors.inputBackground)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        )
                }
            }
            .padding(20)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(20)
            
            // Usage Bar for Free Users
            if !entitlementManager.isPro, let remaining = remainingScans {
                UsageProgressBar(used: 30 - remaining, total: 30)
                    .padding(.top, -12) // Bring closer to profile card
            }
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .padding(.leading, 4)
            .padding(.top, 8)
    }
}

struct UsageProgressBar: View {
    let used: Int
    let total: Int
    
    var progress: Double {
        Double(used) / Double(total)
    }
    
    var progressColor: Color {
        if progress > 0.9 { return .red }
        if progress > 0.7 { return .orange }
        return Color(hex: "4F46E5")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("usage_limit_label".localized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text("\(used) / \(total)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DesignSystem.Colors.inputBackground)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(min(progress, 1.0)), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
        )
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 14))
                )
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
        .contentShape(Rectangle()) // Improves tap area when wrapped
    }
}

#Preview {
    SettingsView()
}
