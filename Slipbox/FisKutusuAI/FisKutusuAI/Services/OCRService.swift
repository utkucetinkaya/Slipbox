import Foundation
import Vision
import UIKit

struct OCRResult {
    var rawText: String
    var merchantName: String?
    var total: Double?
    var date: Date?
    var confidence: Double
    var isUTTS: Bool = false
    var vatRate: Double?
    var vatAmount: Double?
    var baseAmount: Double?
    
    // Enhanced fields for categorization
    var lines: [String] = []
    var topLinesTokens: [String] = []
    var itemsAreaTokens: [String] = []
    var merchantNormalized: String?
}

class OCRService {
    static let shared = OCRService()
    
    func recognizeText(in image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                let result = self.parseText(fullText)
                continuation.resume(returning: result)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["tr-TR", "en-US"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func parseText(_ text: String) -> OCRResult {
        let lines = text.components(separatedBy: "\n")
        var result = OCRResult(rawText: text, confidence: 0.5)
        
        // 1. Merchant Name Heuristic
        // 1. Merchant Name Heuristic
        let genericBlocklist = [
            "E-ARŞİV", "E-ARSIV", "FATURA", "MÜŞTERİ", "MUSTERI", "NÜSHASI", "NUSHASI",
            "SATIŞ", "SATIS", "İŞYERİ", "ISYERI", "TERMINAL", "FİS", "FISI", "BELGE",
            "Mersis", "Tarih:", "Saat:", "ETTN", "TCKN", "VKN", "TUTAR", "TOPLAM", "KDV",
            // TEŞEKKÜRLER variations - OCR often misreads Turkish characters
            "TEŞEKKÜRLER", "TESEKKURLER", "TEŞEKKÜR", "TESEKKUR", "TES EKKUR", 
            "TESEKKORLER", "TESEKKOR", "TESEKKÖRLER", "TESEKKOLER", "TEŞEKKORLER",
            "TESSEKKURLER", "TESEKK", "TEŞEKK", "TESEKURLER", "TESSEKK",
            // Other thank-you/greeting phrases
            "İYİ GÜNLER", "IYI GUNLER", "IYIGUNLER", "BİZİ TERCİH", "BIZI TERCIH", 
            "YİNE BEKLERİZ", "YINE BEKLERIZ", "SAĞOLUN", "SAGOLUN", "HOSGELDINIZ", "HOŞGELDİNİZ",
            "TEKRAR BEKLERIZ", "TEKRAR BEKLERİZ", "GORÜŞMEK ÜZERE", "GORUSMEK UZERE",
            // Order/Table/Service terms
            "ORDER", "SİPARİŞ", "SIPARIS", "MASA", "TABLE", "SERVİS", "SERVIS", 
            "KASİYER", "KASIYER", "INDEX", "SAYFA", "NO:", "TARİH", "SAAT",
            // Website patterns
            "WWW.", ".COM", ".NET", ".ORG", ".TR"
        ]
        
        let knownBrands = ["A101", "BİM", "BIM", "ŞOK", "SOK", "MİGROS", "MIGROS", "CARREFOUR", "KÖFTECİ YUSUF"]
        
        // Search first 10 lines for known brands first
        for line in lines.prefix(10) {
            let clean = line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            for brand in knownBrands {
                if clean.contains(brand) {
                    result.merchantName = clean
                    break
                }
            }
            if result.merchantName != nil { break }
        }
        
        // 2. Strict Top-Line Heuristic (If brand not found)
        if result.merchantName == nil {
            // Check the first 5 lines. The merchant is almost always at the very top.
            for line in lines.prefix(5) {
                let clean = line.trimmingCharacters(in: .whitespacesAndNewlines)
                var upperClean = clean.uppercased()
                
                if clean.isEmpty { continue }
                if clean.count < 3 { continue }
                
                // Skip common noise
                if upperClean.contains("TARİH") || upperClean.contains("SAAT") || upperClean.contains("NO:") { continue }
                
                // Skip if purely numeric or looks like date/phone/total
                if clean.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil { continue }
                if upperClean.contains("TOPLAM") || upperClean.contains("TUTAR") || upperClean.contains("KDV") { continue }
                
                // Check generic blocklist - normalize for Turkish character variations
                let normalizedLine = TextNormalizer.normalize(upperClean)
                let isGeneric = genericBlocklist.contains { term in 
                    let normalizedTerm = TextNormalizer.normalize(term)
                    return normalizedLine.contains(normalizedTerm) || upperClean.contains(term.uppercased())
                }
                if isGeneric { continue }
                
                // Skip websites (starts with WWW or ends with .COM, .NET, .TR)
                if upperClean.hasPrefix("WWW.") || upperClean.contains(".COM") || upperClean.contains(".NET") || upperClean.contains(".ORG") { continue }
                
                // If we survive the filters, this is the merchant. Stop immediately.
                result.merchantName = clean
                break
            }
        }
        
        // 3. Fallback: Search deeper if still nil
        if result.merchantName == nil {
             for line in lines.prefix(8) {
                let clean = line.trimmingCharacters(in: .whitespacesAndNewlines)
                let upperClean = clean.uppercased()
                 
                let isGeneric = genericBlocklist.contains { term in upperClean.contains(term.uppercased()) }
                if isGeneric { continue }
                 
                if upperClean.contains("A.Ş") || upperClean.contains("LTD") || upperClean.contains("TİC") {
                    result.merchantName = clean
                    break
                }
             }
        }
        
        // 2. Total Amount
        // Regex: Matches numbers like 123,45 or 123.45. Group 1 captures the digits.
        // We look for patterns like "* 163.78", "TOPLAM 163,78", etc.
        let amountPattern = #"(\d+[\.,]\d{2})"#
        let amountRegex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive)
        let matches = amountRegex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        
        var amounts: [Double] = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: text) {
                let cleanStr = text[range].replacingOccurrences(of: ",", with: ".")
                if let val = Double(cleanStr) {
                    // Filter out numbers that look like dates (e.g. 20.20 from 20.2023)
                    // Simple heuristic: Total usually doesn't have 4 digits immediately following it
                    amounts.append(val)
                }
            }
        }
        // Take the largest one as it's usually the total
        result.total = amounts.max()
        
        // 3. Date (Regex for DD.MM.YYYY, DD/MM/YYYY, etc.)
        // 3. Date Parsing (Enhanced)
        // Regex: Matches DD.MM.YYYY, DD/MM/YYYY, DD-MM-YYYY with optional spaces (horizontal only)
        // We use [ \t] instead of \s to prevent matching across lines (e.g. "1/2" on one line and "18" on next)
        let datePattern = #"(\d{1,2})[ \t]*[\./-][ \t]*(\d{1,2})[ \t]*[\./-][ \t]*(\d{2,4})"#
        let dateRegex = try? NSRegularExpression(pattern: datePattern)
        let dateMatches = dateRegex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        
        var validDates: [(date: Date, yearDigits: Int)] = []
        
        for match in dateMatches {
            // We expect 3 captures: Day, Month, Year
            if match.numberOfRanges == 4,
               let dayRange = Range(match.range(at: 1), in: text),
               let monthRange = Range(match.range(at: 2), in: text),
               let yearRange = Range(match.range(at: 3), in: text) {
                
                let day = String(text[dayRange])
                let month = String(text[monthRange])
                let year = String(text[yearRange])
                let yearDigits = year.count
                
                // Construct a normalized date string "dd.MM.yyyy"
                // If year is 2 digits, let formatter handle 20xx interpretation, but we track it.
                let cleanDateStr = "\(day).\(month).\(year)"
                
                let formats = ["dd.MM.yyyy", "d.M.yyyy", "dd.MM.yy"]
                
                for format in formats {
                    formatter.dateFormat = format
                    if let datePos = formatter.date(from: cleanDateStr) {
                        let calendar = Calendar.current
                        let yearInt = calendar.component(.year, from: datePos)
                        
                        // Sanity check: 2000 - 2030
                        if yearInt >= 2000 && yearInt < 2030 {
                            validDates.append((date: datePos, yearDigits: yearDigits))
                            break
                        }
                    }
                }
            }
        }
        
        // Pick the best date
        // Priority: 4-digit year > 2-digit year.
        // If same digits, pick the one that appears later? Or earlier? 
        // Usually receipts have date at top or bottom. 
        // Let's sort by yearDigits desc (4 > 2).
        if let best = validDates.sorted(by: { $0.yearDigits > $1.yearDigits }).first {
            result.date = best.date
        }
        
        // 4. UTTS & Fuel Detection
        // Keywords: UTTS, TTS, Taşıt Tanıma, Plaka, Filo, Yakıt Otomasyon
        let uttsKeywords = ["UTTS", "TTS", "TAŞIT TANIMA", "TASIT TANIMA", "PLAKA", "FİLO", "FILO", "YAKIT OTOMASYON", "OPET TAŞIT", "SHELL TTS", "BP TAŞIT", "KURŞUNSUZ", "MOTORIN", "DIZEL"]
        let upperText = text.uppercased()
        
        for keyword in uttsKeywords {
            if upperText.contains(keyword) {
                result.isUTTS = true
                break
            }
        }
        
        // Additional Heuristic: Fuel Volume (e.g., "3,82 LT")
        if !result.isUTTS {
            // Look for "LT" or "LITRE" preceded by a number
            // Regex: (\d+[.,]\d+)\s*(LT|LİTRE|LITRE)
            let fuelPattern = #"(\d+[\.,]\d+)\s*(LT|LİTRE|LITRE)"#
            if let fuelRegex = try? NSRegularExpression(pattern: fuelPattern, options: .caseInsensitive),
               fuelRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                result.isUTTS = true // It's likely a fuel receipt, treat as similar category
            }
        }
        
        // 5. VAT (KDV) Parsing
        // Regex: KDV[%]?\s*(\d{1,2})\s*[:=]?\s*([0-9.,]+)
        // Looks for "KDV %8 : 12,50" or "KDV 18 20.00"
        let kdvPattern = #"KDV[%]?\s*(\d{1,2})\s*[:=]?\s*(\d+[\.,]\d{2})"#
        if let kdvRegex = try? NSRegularExpression(pattern: kdvPattern, options: .caseInsensitive) {
            let kdvMatches = kdvRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            // We take the last match typically, or iterate to find plausible ones (often at bottom)
            for match in kdvMatches {
                if let rateRange = Range(match.range(at: 1), in: text),
                   let amountRange = Range(match.range(at: 2), in: text) {
                    
                    if let rate = Double(String(text[rateRange])),
                       let amountStr = String(text[amountRange]).replacingOccurrences(of: ",", with: ".") as String?,
                       let amount = Double(amountStr) {
                        
                        // Heuristic: VAT amount must be less than Total
                        if let total = result.total, amount < total {
                            result.vatRate = rate
                            result.vatAmount = amount
                            result.baseAmount = total - amount
                            // Found a valid KDV line
                        }
                    }
                }
            }
        }
        
        // Confidence Heuristic
        if result.total != nil {
            result.confidence = result.merchantName != nil ? 0.9 : 0.7
        } else {
            result.confidence = 0.4
        }
        
        // Populate enhanced categorization fields
        result.lines = lines
        result.topLinesTokens = TextNormalizer.extractTopLineTokens(from: lines, count: 5)
        result.itemsAreaTokens = TextNormalizer.extractItemsZoneTokens(from: lines)
        if let merchant = result.merchantName {
            result.merchantNormalized = TextNormalizer.normalizeMerchant(merchant)
        }
        
        return result
    }
    
    enum OCRError: Error {
        case invalidImage
        case noTextFound
    }
}
