import Foundation

/// Result of categorization with scoring details
struct CategorizationResult {
    let primaryCategory: String
    let primaryScore: Int
    let confidence: Double
    let alternatives: [(category: String, score: Int)]
    let requiresReview: Bool
    let matchDetails: [String] // Debug: what matched
}

/// Precision scoring-based categorization service
class CategorizationService {
    static let shared = CategorizationService()
    
    private init() {}
    
    // MARK: - Scoring Weights
    private struct Weights {
        static let merchantMatch = 8
        static let productMatch = 4
        static let productMatchInItemsZone = 6
        static let generalMatch = 2
        static let topLineBonus = 3
        static let negativeMatch = -8
    }
    
    // MARK: - Thresholds
    private struct Thresholds {
        static let autoAssign = 10      // Score >= 10: auto-assign
        static let pendingReview = 6    // Score 6-9: pending review with suggestions
        static let conflictMargin = 3   // If top 2 scores differ by < 3: show both
    }
    
    /// Main categorization function with enhanced OCR data
    func categorize(
        merchantName: String?,
        rawText: String?,
        lines: [String] = [],
        topLinesTokens: [String] = [],
        itemsAreaTokens: [String] = []
    ) -> CategorizationResult {
        
        // Prepare normalized data
        let merchantNormalized = merchantName.map { TextNormalizer.normalizeMerchant($0) } ?? ""
        let allTextTokens = TextNormalizer.tokenize(rawText ?? "")
        let topTokens = topLinesTokens.isEmpty ? 
            TextNormalizer.extractTopLineTokens(from: lines) : topLinesTokens
        let itemsTokens = itemsAreaTokens.isEmpty ? 
            TextNormalizer.extractItemsZoneTokens(from: lines) : itemsAreaTokens
        
        // Calculate scores for all categories
        var categoryScores: [(id: String, score: Int, matches: [String])] = []
        
        for category in KeywordCatalog.categories {
            let (score, matches) = calculateScore(
                for: category,
                merchantNormalized: merchantNormalized,
                allTextTokens: allTextTokens,
                topLinesTokens: topTokens,
                itemsAreaTokens: itemsTokens
            )
            categoryScores.append((category.id, score, matches))
        }
        
        // Sort by score descending
        categoryScores.sort { $0.score > $1.score }
        
        // Apply conflict resolution
        let resolved = resolveConflicts(scores: categoryScores, rawText: rawText ?? "")
        
        // Determine final category and status
        let topCategory = resolved.first ?? (id: "other", score: 0, matches: [])
        let alternatives = resolved.dropFirst().prefix(2).map { ($0.id, $0.score) }
        
        // Calculate confidence
        let matchCount = topCategory.matches.count
        var confidence = calculateConfidence(score: topCategory.score, matchCount: matchCount)
        
        // Determine if review is needed
        let requiresReview: Bool
        if topCategory.score >= Thresholds.autoAssign {
            requiresReview = false
        } else if topCategory.score >= Thresholds.pendingReview {
            // Check if there's a close alternative
            if let secondScore = resolved.dropFirst().first?.score,
               topCategory.score - secondScore < Thresholds.conflictMargin {
                requiresReview = true
                confidence = min(confidence, 0.6) // Cap confidence when ambiguous
            } else {
                requiresReview = true
            }
        } else {
            requiresReview = true
        }
        
        return CategorizationResult(
            primaryCategory: topCategory.score > 0 ? topCategory.id : "other",
            primaryScore: topCategory.score,
            confidence: confidence,
            alternatives: Array(alternatives),
            requiresReview: requiresReview,
            matchDetails: topCategory.matches
        )
    }
    
    /// Simplified categorization for backward compatibility
    func categorize(merchantName: String?, rawText: String?) -> (categoryId: String, confidence: Double) {
        let lines = (rawText ?? "").components(separatedBy: "\n")
        let result = categorize(
            merchantName: merchantName,
            rawText: rawText,
            lines: lines
        )
        return (result.primaryCategory, result.confidence)
    }
    
    // MARK: - Private Methods
    
    private func calculateScore(
        for category: KeywordCatalog.CategoryKeywordSet,
        merchantNormalized: String,
        allTextTokens: [String],
        topLinesTokens: [String],
        itemsAreaTokens: [String]
    ) -> (score: Int, matches: [String]) {
        
        var score = 0
        var matches: [String] = []
        
        // 1. Merchant keyword matches (+8 each)
        for keyword in category.merchantKeywords {
            let normalizedKeyword = TextNormalizer.normalize(keyword)
            if merchantNormalized.contains(normalizedKeyword) ||
               allTextTokens.contains(where: { $0.contains(normalizedKeyword) }) {
                score += Weights.merchantMatch
                matches.append("merchant:\(keyword)")
                
                // Bonus for top-line merchant match
                if topLinesTokens.contains(where: { $0.contains(normalizedKeyword) }) {
                    score += Weights.topLineBonus
                    matches.append("topline_bonus:\(keyword)")
                }
            }
        }
        
        // 2. Product keyword matches (+4 or +6 in items zone)
        for keyword in category.productKeywords {
            let normalizedKeyword = TextNormalizer.normalize(keyword)
            
            // Check items zone first (higher weight)
            if itemsAreaTokens.contains(where: { $0.contains(normalizedKeyword) }) {
                score += Weights.productMatchInItemsZone
                matches.append("product_items:\(keyword)")
            } else if allTextTokens.contains(where: { $0.contains(normalizedKeyword) }) {
                score += Weights.productMatch
                matches.append("product:\(keyword)")
                
                // Bonus for top-line product match
                if topLinesTokens.contains(where: { $0.contains(normalizedKeyword) }) {
                    score += Weights.topLineBonus
                    matches.append("topline_bonus:\(keyword)")
                }
            }
        }
        
        // 3. General keyword matches (+2 each)
        for keyword in category.generalKeywords {
            let normalizedKeyword = TextNormalizer.normalize(keyword)
            if allTextTokens.contains(where: { $0.contains(normalizedKeyword) }) {
                score += Weights.generalMatch
                matches.append("general:\(keyword)")
            }
        }
        
        // 4. Negative keyword matches (-8 each)
        for keyword in category.negativeKeywords {
            let normalizedKeyword = TextNormalizer.normalize(keyword)
            if allTextTokens.contains(where: { $0.contains(normalizedKeyword) }) {
                score += Weights.negativeMatch
                matches.append("negative:\(keyword)")
            }
        }
        
        return (max(0, score), matches)
    }
    
    private func resolveConflicts(
        scores: [(id: String, score: Int, matches: [String])],
        rawText: String
    ) -> [(id: String, score: Int, matches: [String])] {
        
        var resolved = scores
        let normalizedText = TextNormalizer.normalize(rawText)
        
        // Priority rules for specific conflicts
        
        // Rule 1: If benzin/dizel/lt/pompa present -> Transport priority
        let fuelKeywords = ["benzin", "dizel", "motorin", "lpg", "pompa", "litre", " lt "]
        let hasFuelKeyword = fuelKeywords.contains { normalizedText.contains($0) }
        
        // Rule 2: If latte/espresso/cappuccino present -> Food priority
        let coffeeKeywords = ["latte", "espresso", "cappuccino", "americano", "mocha", "macchiato"]
        let hasCoffeeKeyword = coffeeKeywords.contains { normalizedText.contains($0) }
        
        // Apply priority adjustments
        if hasFuelKeyword && !hasCoffeeKeyword {
            // Boost transport, penalize food
            resolved = resolved.map { item in
                if item.id == "transport" {
                    return (item.id, item.score + 5, item.matches + ["priority:fuel"])
                } else if item.id == "food_drink" {
                    return (item.id, max(0, item.score - 5), item.matches + ["penalty:fuel_present"])
                }
                return item
            }
        }
        
        if hasCoffeeKeyword && !hasFuelKeyword {
            // Boost food, penalize transport
            resolved = resolved.map { item in
                if item.id == "food_drink" {
                    return (item.id, item.score + 5, item.matches + ["priority:coffee"])
                } else if item.id == "transport" {
                    return (item.id, max(0, item.score - 5), item.matches + ["penalty:coffee_present"])
                }
                return item
            }
        }
        
        // Re-sort after adjustments
        resolved.sort { $0.score > $1.score }
        
        return resolved
    }
    
    private func calculateConfidence(score: Int, matchCount: Int) -> Double {
        // Base confidence from score
        var confidence = min(1.0, Double(score) / 20.0)
        
        // Reduce confidence if only 1 match led to the score
        if matchCount == 1 {
            confidence = min(confidence, 0.5)
        } else if matchCount == 2 {
            confidence = min(confidence, 0.7)
        }
        
        // Cap at 0.95 (never 100% certain)
        return min(0.95, confidence)
    }
}
