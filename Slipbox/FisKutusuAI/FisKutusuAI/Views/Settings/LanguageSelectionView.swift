import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var userPreferences: AppUserPreferences
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var uiState: AppUIState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "050511").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(userPreferences.languages, id: \.0) { language in
                        Button(action: {
                            userPreferences.languageCode = language.0
                            // Update LocalizationManager to trigger UI refresh
                            localizationManager.setLanguage(language.0)
                            dismiss()
                        }) {
                            HStack {
                                Text(language.1)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if userPreferences.languageCode == language.0 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "4F46E5"))
                                }
                            }
                            .padding()
                            .background(Color(hex: "1C1C1E"))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("language")
        .onAppear {
            uiState.isTabBarHidden = true
        }
        .onDisappear {
            uiState.isTabBarHidden = false
        }
    }
}
