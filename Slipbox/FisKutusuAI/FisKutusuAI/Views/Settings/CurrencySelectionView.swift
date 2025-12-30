import SwiftUI

struct CurrencySelectionView: View {
    @EnvironmentObject var userPreferences: AppUserPreferences
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "050511").ignoresSafeArea()
            
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
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if userPreferences.currencyCode == currency.0 {
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
        .navigationTitle("Para Birimi")
    }
}
