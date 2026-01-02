import SwiftUI

struct CurrencySelectionView: View {
    @EnvironmentObject var userPreferences: AppUserPreferences
    @EnvironmentObject var uiState: AppUIState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(userPreferences.currencies, id: \.0) { currency in
                        Button(action: {
                            userPreferences.currencyCode = currency.0
                            userPreferences.currencySymbol = currency.1
                            dismiss()
                        }) {
                            HStack {
                                Text("\(currency.1) \(currency.0)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                if userPreferences.currencyCode == currency.0 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "4F46E5"))
                                }
                            }
                            .padding()
                            .background(DesignSystem.Colors.surface)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Para Birimi")
        .onAppear {
            uiState.isTabBarHidden = true
        }
        .onDisappear {
            uiState.isTabBarHidden = false
        }
    }
}
