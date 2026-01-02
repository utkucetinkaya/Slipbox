import Foundation
import Combine

class CategoryService: ObservableObject {
    static let shared = CategoryService()
    

    
    private let kCustomCategoriesKey = "custom_categories"
    
    private init() {
        self.customCategories = getCustomCategories()
    }
    
    // MARK: - Category Management
    
    @Published var customCategories: [Category] = []
    
    // MARK: - Category Management
    
    var allCategories: [Category] {
        return Category.defaults + Category.additional + customCategories
    }
    
    func addCustomCategory(_ category: Category) {
        customCategories.append(category)
        saveCustomCategories(customCategories)
    }
    
    private func getCustomCategories() -> [Category] {
        guard let data = UserDefaults.standard.data(forKey: kCustomCategoriesKey),
              let categories = try? JSONDecoder().decode([Category].self, from: data) else {
            return []
        }
        return categories
    }
    
    private func saveCustomCategories(_ categories: [Category]) {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: kCustomCategoriesKey)
        }
    }

    
    /// Suggest a category based on merchant name and OCR text
    func suggestCategory(merchant: String?, rawText: String?) -> String {
        let text = (rawText ?? "").lowercased()
        let merchantName = (merchant ?? "").lowercased()
        let combined = "\(merchantName) \(text)"
        
        // 1. Check merchant name specific rules (High confidence)
        if merchantName.contains("starbucks") || merchantName.contains("cafe") || merchantName.contains("restaurant") || merchantName.contains("burger") {
            return "food_drink"
        }
        
        if merchantName.contains("uber") || merchantName.contains("taksi") || merchantName.contains("bi taksi") || merchantName.contains("shell") || merchantName.contains("opet") {
            return "transport"
        }
        
        if merchantName.contains("migros") || merchantName.contains("carrefour") || merchantName.contains("bim") || merchantName.contains("sok") || merchantName.contains("market") {
            return "food_drink" // Groceries usually go here or create a new 'market' category
        }
        
        if merchantName.contains("apple") || merchantName.contains("teknosa") || merchantName.contains("media markt") {
            return "equipment"
        }
        
        // 2. Check keywords in full text (Medium confidence)
        if combined.contains("yemek") || combined.contains("restoran") || combined.contains("kahve") || combined.contains("çay") {
            return "food_drink"
        }
        
        if combined.contains("benzin") || combined.contains("mazot") || combined.contains("otopark") || combined.contains("bilet") {
            return "transport"
        }
        
        if combined.contains("bilgisayar") || combined.contains("kablo") || combined.contains("kulaklık") || combined.contains("elektronik") {
            return "equipment"
        }
        
        if combined.contains("tamir") || combined.contains("bakım") || combined.contains("hizmet") || combined.contains("kuaför") {
            return "service"
        }
        
        // Default
        return "other"
    }
}
