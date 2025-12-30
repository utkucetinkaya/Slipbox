import SwiftUI
import Combine

class AppUserPreferences: ObservableObject {
    @Published var currencyCode: String {
        didSet {
            UserDefaults.standard.set(currencyCode, forKey: "selectedCurrencyCode")
        }
    }
    
    @Published var currencySymbol: String {
        didSet {
            UserDefaults.standard.set(currencySymbol, forKey: "selectedCurrencySymbol")
        }
    }
    
    @Published var languageCode: String {
        didSet {
            UserDefaults.standard.set(languageCode, forKey: "selectedLanguageCode")
        }
    }
    
    init() {
        self.currencyCode = UserDefaults.standard.string(forKey: "selectedCurrencyCode") ?? "TRY"
        self.currencySymbol = UserDefaults.standard.string(forKey: "selectedCurrencySymbol") ?? "₺"
        self.languageCode = UserDefaults.standard.string(forKey: "selectedLanguageCode") ?? "tr"
    }
    
    // Helper to get Locale
    var locale: Locale {
        return Locale(identifier: languageCode == "tr" ? "tr_TR" : "en_US")
    }
    
    let currencies = [
        ("TRY", "₺", "Türk Lirası"),
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound")
    ]
    
    let languages = [
        ("tr", "Türkçe (TR)"),
        ("en", "English (EN)")
    ]
    
    func languageName(for code: String) -> String {
        return languages.first(where: { $0.0 == code })?.1 ?? code
    }
}
