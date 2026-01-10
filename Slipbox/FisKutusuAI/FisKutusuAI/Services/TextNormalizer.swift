import Foundation

/// Utility for normalizing Turkish text for categorization matching
struct TextNormalizer {
    
    /// Turkish character mapping to ASCII equivalents
    private static let turkishCharMap: [Character: Character] = [
        "ı": "i", "İ": "i", "I": "i",
        "ş": "s", "Ş": "s",
        "ğ": "g", "Ğ": "g",
        "ç": "c", "Ç": "c",
        "ö": "o", "Ö": "o",
        "ü": "u", "Ü": "u"
    ]
    
    /// Company suffixes to normalize
    private static let companySuffixes = [
        "A.Ş.", "A.Ş", "AŞ.", "AŞ",
        "LTD.", "LTD", "LİMİTED", "LIMITED",
        "TİC.", "TİC", "TIC.", "TIC",
        "SAN.", "SAN", "SANAYİ", "SANAYI",
        "ŞTİ.", "ŞTİ", "STI.", "STI",
        "A.O.", "A.O"
    ]
    
    /// Normalize a single string - lowercase + Turkish char mapping
    static func normalize(_ text: String) -> String {
        var result = text.lowercased()
        result = String(result.map { turkishCharMap[$0] ?? $0 })
        return result
    }
    
    /// Normalize and tokenize text into unique words
    static func tokenize(_ text: String) -> [String] {
        let normalized = normalize(text)
        
        // Split by whitespace and punctuation
        let separators = CharacterSet.whitespacesAndNewlines
            .union(.punctuationCharacters)
            .union(CharacterSet(charactersIn: "0123456789"))
        
        let tokens = normalized
            .components(separatedBy: separators)
            .filter { $0.count >= 2 } // Min 2 chars
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Return unique tokens
        return Array(Set(tokens))
    }
    
    /// Normalize merchant name by removing company suffixes
    static func normalizeMerchant(_ merchant: String) -> String {
        var result = normalize(merchant)
        
        // Remove common company suffixes
        for suffix in companySuffixes {
            let normalizedSuffix = normalize(suffix)
            result = result.replacingOccurrences(of: normalizedSuffix, with: "")
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extract tokens from first N lines (for top-line matching)
    static func extractTopLineTokens(from lines: [String], count: Int = 5) -> [String] {
        let topLines = lines.prefix(count).joined(separator: " ")
        return tokenize(topLines)
    }
    
    /// Extract tokens from items zone (lines before TOPLAM/KDV markers)
    static func extractItemsZoneTokens(from lines: [String]) -> [String] {
        let stopKeywords = ["toplam", "genel toplam", "tutar", "odenecek", "odeme", 
                           "kdv", "nakit", "pos", "kart", "kredi", "banka"]
        
        var itemsLines: [String] = []
        
        for line in lines {
            let normalizedLine = normalize(line)
            
            // Check if this line contains a stop keyword
            let hasStopKeyword = stopKeywords.contains { normalizedLine.contains($0) }
            
            if hasStopKeyword {
                break // Stop collecting lines
            }
            
            itemsLines.append(line)
        }
        
        // Skip first 3 lines (usually header/merchant info) and last line before totals
        let skipStart = min(3, itemsLines.count)
        let endIndex = max(skipStart, itemsLines.count)
        
        if skipStart < endIndex {
            let zoneLinesSlice = itemsLines[skipStart..<endIndex]
            let zoneText = zoneLinesSlice.joined(separator: " ")
            return tokenize(zoneText)
        }
        
        return []
    }
    
    /// Check if normalized text contains a keyword
    static func textContains(_ text: String, keyword: String) -> Bool {
        let normalizedText = normalize(text)
        let normalizedKeyword = normalize(keyword)
        return normalizedText.contains(normalizedKeyword)
    }
    
    /// Count keyword matches in tokenized text
    static func countMatches(tokens: [String], keywords: [String]) -> Int {
        var count = 0
        for keyword in keywords {
            let normalizedKeyword = normalize(keyword)
            if tokens.contains(where: { $0.contains(normalizedKeyword) || normalizedKeyword.contains($0) }) {
                count += 1
            }
        }
        return count
    }
}
