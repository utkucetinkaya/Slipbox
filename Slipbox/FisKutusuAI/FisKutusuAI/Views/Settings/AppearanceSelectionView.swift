import SwiftUI

struct AppearanceSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userPreferences: AppUserPreferences
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button(action: {
                            withAnimation {
                                userPreferences.appTheme = theme
                            }
                        }) {
                            HStack {
                                Text(theme.localizedName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                if userPreferences.appTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .padding()
                            .background(DesignSystem.Colors.surface)
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("appearance".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceSelectionView()
            .environmentObject(AppUserPreferences.shared)
    }
}
