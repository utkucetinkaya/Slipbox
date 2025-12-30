import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userPreferences: AppUserPreferences
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "050511")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Card
                        profileCard
                        
                        // Preferences
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("preferences".localized.uppercased())
                            
                            NavigationLink(destination: CurrencySelectionView()) {
                                SettingsRow(icon: "arrow.triangle.2.circlepath", title: "currency".localized, value: "\(userPreferences.currencySymbol) (\(userPreferences.currencyCode))", color: Color(hex: "4F46E5"))
                            }
                            
                            NavigationLink(destination: LanguageSelectionView()) {
                                SettingsRow(icon: "globe", title: "language".localized, value: userPreferences.languageName(for: userPreferences.languageCode), color: Color(hex: "4F46E5"))
                            }
                        }
                        
                        // Support & Legal
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("SUPPORT & LEGAL")
                            SettingsRow(icon: "bubble.left.fill", title: "Send Feedback", color: Color(hex: "06B6D4"))
                            SettingsRow(icon: "lock.fill", title: "privacy".localized, color: Color(hex: "A855F7"))
                            SettingsRow(icon: "doc.text.fill", title: "terms".localized, color: Color(hex: "FFCC00"))
                        }
                        
                        // Danger Zone
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("DANGER ZONE")
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
                                    
                                    Text("Delete Account")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(hex: "FF3B30"))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "FF3B30").opacity(0.5))
                                }
                                .padding()
                                .background(Color(hex: "1C1C1E"))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "FF3B30").opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Developer / Debug Section
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("DEVELOPER")
                            
                            Button(action: { LaunchManager.shared.resetOnboarding() }) {
                                SettingsRow(icon: "arrow.counterclockwise", title: "Reset Onboarding", color: .orange)
                            }
                            
                            Button(action: { LaunchManager.shared.resetPermissions() }) {
                                SettingsRow(icon: "shield.slash.fill", title: "Reset Permissions", color: .orange)
                            }
                            
                             Button(action: { LaunchManager.shared.resetAll() }) {
                                SettingsRow(icon: "exclamationmark.triangle.fill", title: "Factory Reset Flow", color: .red)
                            }
                            
                            Button(action: { try? AuthenticationManager.shared.signOut() }) {
                                SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", color: .red)
                            }
                        }
                        
                        Text("SlipBox v2.4.0 (Build 412)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 0) // Removed extra top padding
                }
            }
            .navigationTitle("settings".localized)
            .navigationBarTitleDisplayMode(.inline) // Ensure title is visible and compact
        }
    }
    
    // MARK: - Components
    
    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "2C2C2E"))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.5))
                
                Circle()
                    .fill(Color(hex: "34C759"))
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color(hex: "1C1C1E"), lineWidth: 2))
                    .offset(x: 22, y: 22)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("user@example.com")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("PRO PLAN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "4F46E5"))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            NavigationLink(destination: EditProfileView()) {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
            }
        }
        .padding(20)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(20)
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white.opacity(0.4))
            .padding(.leading, 4)
            .padding(.top, 8)
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
                .foregroundColor(.white)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding()
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(16)
        .contentShape(Rectangle()) // Improves tap area when wrapped
    }
}

#Preview {
    SettingsView()
}
