import Foundation
import Combine

class CurrencyService: ObservableObject {
    static let shared = CurrencyService()
    
    @Published var rates: [String: Double] = [:]
    
    private let ratesKey = "cached_currency_rates"
    private let lastFetchKey = "last_currency_fetch_date"
    private let session = URLSession.shared
    
    // Default fallback rates (relative to TRY)
    private let defaultRates: [String: Double] = [
        "TRY": 1.0,
        "USD": 0.029, // ~1/34
        "EUR": 0.027, // ~1/37
        "GBP": 0.023  // ~1/43
    ]
    
    private init() {
        loadCachedRates()
        fetchRates()
    }
    
    // MARK: - API
    
    func fetchRates() {
        // Check if we need to fetch (e.g. once every hour)
        if let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date,
           Date().timeIntervalSince(lastFetch) < 3600 {
            // Data is fresh enough
            return
        }
        
        guard let url = URL(string: "https://api.frankfurter.app/latest?from=TRY") else { return }
        
        Task {
            do {
                let (data, _) = try await session.data(from: url)
                let response = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
                
                DispatchQueue.main.async {
                    var newRates = response.rates
                    newRates["TRY"] = 1.0 // Base is TRY
                    
                    self.rates = newRates
                    self.saveRates(newRates)
                }
            } catch {
                print("Failed to fetch currency rates: \(error)")
                // Keep using cached or default values
            }
        }
    }
    
    // MARK: - Logic
    
    /// Converts an amount from one currency to another using the latest rates.
    /// Base assumption: 'rates' dictionary contains values relative to 1 TRY.
    /// Example from API: "USD": 0.029 (1 TRY = 0.029 USD)
    func convert(_ amount: Double, from fromCode: String, to toCode: String) -> Double {
        let normalizedFrom = fromCode.uppercased()
        let normalizedTo = toCode.uppercased()
        
        if normalizedFrom == normalizedTo {
            return amount
        }
        
        // 1. Convert 'from' currency to TRY (Base)
        // If 1 TRY = 0.029 USD, then 1 USD = 1/0.029 TRY = ~34.48 TRY
        // So AmountInTRY = AmountInFrom / RateOfFrom
        guard let rateFrom = rates[normalizedFrom] ?? defaultRates[normalizedFrom],
              let rateTo = rates[normalizedTo] ?? defaultRates[normalizedTo] else {
            return amount // Fallback if unknown
        }
        
        // Example: Convert 100 USD to EUR.
        // rateFrom (USD) = 0.029
        // rateTo (EUR) = 0.027
        
        // AmountInTRY = 100 / 0.029 = 3448.27 TRY
        let amountInTRY = amount / rateFrom
        
        // AmountInEUR = AmountInTRY * rateTo
        // = 3448.27 * 0.027 = 93.10 EUR
        let amountInTarget = amountInTRY * rateTo
        
        return amountInTarget
    }
    
    // MARK: - Persistence
    
    private func loadCachedRates() {
        if let data = UserDefaults.standard.data(forKey: ratesKey),
           let cached = try? JSONDecoder().decode([String: Double].self, from: data) {
            self.rates = cached
        } else {
            self.rates = defaultRates
        }
    }
    
    private func saveRates(_ newRates: [String: Double]) {
        if let data = try? JSONEncoder().encode(newRates) {
            UserDefaults.standard.set(data, forKey: ratesKey)
            UserDefaults.standard.set(Date(), forKey: lastFetchKey)
        }
    }
}

// MARK: - Response Model
struct FrankfurterResponse: Codable {
    let amount: Double
    let base: String
    let date: String
    let rates: [String: Double]
}
