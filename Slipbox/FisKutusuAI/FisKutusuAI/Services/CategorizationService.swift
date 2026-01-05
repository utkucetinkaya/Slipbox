import Foundation

class CategorizationService {
    static let shared = CategorizationService()
    
    private init() {}
    
    struct CategoryKeywords {
        let id: String
        let keywords: [String]
    }
    
    private let dictionary: [CategoryKeywords] = [
        CategoryKeywords(id: "food_drink", keywords: ["migros","şok","a101","bim","carrefour","starbucks","kahve","cafe","restaurant","yemek","burger","pizza","kfc","mcdonald","dominos","popeyes","yeme","içme","food","drink"]),
        CategoryKeywords(id: "transport", keywords: ["shell","opet","bp","total","petrol","akaryakıt","benzin","dizel","otopark","park","uber","bitaksi","taksi","metro","otobüs","tramvay","utts","tts","taşıt tanıma","plaka","filo","yakıt otomasyon"]),
        CategoryKeywords(id: "equipment", keywords: ["teknosa","vatan","mediamarkt","apple","iphone","bilgisayar","laptop","ekran","klavye","mouse","ofis","donanım","ekipman"]),
        CategoryKeywords(id: "service", keywords: ["netflix","spotify","youtube","google","apple.com","icloud","abonelik","elektrik","su","doğalgaz","internet","fatura","danışmanlık","servis","turkcell","vodafone","türk telekom"]),
        CategoryKeywords(id: "entertainment", keywords: ["sinema","cinema","tiyatro","konser","oyun","playstation","steam","eğlence"]),
        CategoryKeywords(id: "clothing", keywords: ["zara","hm","lcw","defacto","koton","giyim","ayakkabı","mont","pantolon"]),
        CategoryKeywords(id: "health", keywords: ["eczane","pharmacy","hastane","klinik","doktor","sağlık","ilaç"]),
        CategoryKeywords(id: "education", keywords: ["udemy","coursera","kurs","eğitim","kitap","book","akademi"]),
        CategoryKeywords(id: "rent", keywords: ["kira","rent","emlak","apartman","aidat"]),
        CategoryKeywords(id: "tax", keywords: ["vergi","sgk","maliye","harç","ceza","stopaj","ötv","götürü vergi","kdv"]),
        CategoryKeywords(id: "travel", keywords: ["otel","hotel","booking","airbnb","uçak","flight","thy","pegasus","seyahat"])
    ]
    
    func categorize(merchantName: String?, rawText: String?) -> (categoryId: String, confidence: Double) {
        let searchContent = "\(merchantName ?? "") \(rawText ?? "")".lowercased()
        
        var bestCategoryId = "other"
        var maxMatches = 0
        
        for entry in dictionary {
            let matchCount = entry.keywords.filter { searchContent.contains($0) }.count
            if matchCount > maxMatches {
                maxMatches = matchCount
                bestCategoryId = entry.id
            }
        }
        
        // Simple confidence: 1 match = 0.5, 2+ matches = 1.0, 0 matches = 0.0
        let confidence = maxMatches >= 2 ? 1.0 : (maxMatches == 1 ? 0.6 : 0.0)
        
        return (bestCategoryId, confidence)
    }
}
