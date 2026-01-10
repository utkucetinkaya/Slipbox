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
    var vatTotal: Double?
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
        // 1. Normalize Text (TR Locale awareness)
        let normalizedText = text.replacingOccurrences(of: "i", with: "İ")
            .replacingOccurrences(of: "ı", with: "I")
            .uppercased()
        
        let lines = normalizedText.components(separatedBy: "\n")
        var result = OCRResult(rawText: text, confidence: 0.5)
        
        // --- 1. Merchant Name Heuristic ---
        let genericBlocklist = [
            "E-ARŞİV", "E-ARSIV", "FATURA", "MÜŞTERİ", "MUSTERI", "NÜSHASI", "NUSHASI",
            "SATIŞ", "SATIS", "İŞYERİ", "ISYERI", "TERMINAL", "FİS", "FISI", "BELGE",
            "MERSIS", "TARIH:", "SAAT:", "ETTN", "TCKN", "VKN", "TUTAR", "TOPLAM", "KDV",
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
        
        for line in lines.prefix(10) {
            let clean = line.trimmingCharacters(in: .whitespacesAndNewlines)
            for brand in knownBrands {
                if clean.contains(brand) {
                    result.merchantName = clean
                    break
                }
            }
            if result.merchantName != nil { break }
        }
        
        if result.merchantName == nil {
            for line in lines.prefix(5) {
                let clean = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if clean.isEmpty || clean.count < 3 { continue }
                if clean.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil { continue }
                
                // Check generic blocklist - normalize for Turkish character variations
                let normalizedLine = TextNormalizer.normalize(clean)
                let isGeneric = genericBlocklist.contains { term in 
                    let normalizedTerm = TextNormalizer.normalize(term)
                    return normalizedLine.contains(normalizedTerm) || clean.contains(term.uppercased())
                }
                if isGeneric { continue }
                if clean.hasPrefix("WWW.") || clean.contains(".COM") { continue }
                
                result.merchantName = clean
                break
            }
        }
        
        // --- 2. Total Amount ---
        let amountPattern = #"(\d+[\.,]\d{2})"#
        let amountRegex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive)
        let matches = amountRegex?.matches(in: normalizedText, range: NSRange(normalizedText.startIndex..., in: normalizedText)) ?? []
        
        var amounts: [Double] = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: normalizedText) {
                let cleanStr = String(normalizedText[range]).replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
                if let val = Double(cleanStr) {
                    amounts.append(val)
                }
            }
        }
        result.total = amounts.max()
        
        // --- 3. Date ---
        let datePattern = #"(\d{1,2})[ \t]*[\./-][ \t]*(\d{1,2})[ \t]*[\./-][ \t]*(\d{2,4})"#
        let dateRegex = try? NSRegularExpression(pattern: datePattern)
        let dateMatches = dateRegex?.matches(in: normalizedText, range: NSRange(normalizedText.startIndex..., in: normalizedText)) ?? []
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        var validDates: [(date: Date, yearDigits: Int)] = []
        
        for match in dateMatches {
            if match.numberOfRanges == 4,
               let dayRange = Range(match.range(at: 1), in: normalizedText),
               let monthRange = Range(match.range(at: 2), in: normalizedText),
               let yearRange = Range(match.range(at: 3), in: normalizedText) {
                
                let day = String(normalizedText[dayRange])
                let month = String(normalizedText[monthRange])
                let year = String(normalizedText[yearRange])
                let cleanDateStr = "\(day).\(month).\(year)"
                
                let formats = ["dd.MM.yyyy", "d.M.yyyy", "dd.MM.yy"]
                for format in formats {
                    formatter.dateFormat = format
                    if let datePos = formatter.date(from: cleanDateStr) {
                        let calendar = Calendar.current
                        let yearInt = calendar.component(.year, from: datePos)
                        if yearInt >= 2000 && yearInt < 2030 {
                            validDates.append((date: datePos, yearDigits: year.count))
                            break
                        }
                    }
                }
            }
        }
        result.date = validDates.sorted(by: { $0.yearDigits > $1.yearDigits }).first?.date
        
        // --- 4. UTTS & Fuel ---
        let uttsKeywords = ["UTTS", "TTS", "TAŞIT TANIMA", "TASIT TANIMA", "PLAKA", "FİLO", "FILO", "YAKIT OTOMASYON", "OPET TAŞIT", "SHELL TTS", "BP TAŞIT", "KURŞUNSUZ", "MOTORIN", "DIZEL"]
        for keyword in uttsKeywords {
            if normalizedText.contains(keyword) {
                result.isUTTS = true
                break
            }
        }
        
        // --- 5. VAT (KDV) Extraction (Enhanced) ---
        var detectedVats: [Double] = []
        
        // Regular Expression Candidates
        // Pattern 1: TOPLAM KDV : 1.234,56 or TOPKDV *20,45
        let vatPatterns = [
            #"(?:TOPLAM\s*KDV|KDV\s*TOPLAM|KDV\s*TUTARI|TOPKDV|TOP\.KDV|KDV)\s*[:\-\=\*]*\s*(?:₺|TL|TR)?\s*(\d{1,3}(?:[\.\s]\d{3})*(?:,\d{2})|\d+(?:,\d{2})|\d+(?:\.\d{2}))"#,
            #"(?:KDV|K\.D\.V)\s*%?\s*\d{1,2}\s*[:\-\=\*]*\s*(?:₺|TL|TR)?\s*(\d{1,3}(?:[\.\s]\d{3})*(?:,\d{2})|\d+(?:,\d{2})|\d+(?:\.\d{2}))"#
        ]
        
        for pattern in vatPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: normalizedText, range: NSRange(normalizedText.startIndex..., in: normalizedText))
                for match in matches {
                    if let amountRange = Range(match.range(at: 1), in: normalizedText) {
                        var amountStr = String(normalizedText[amountRange])
                            .replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: ".", with: "")
                            .replacingOccurrences(of: ",", with: ".")
                        
                        if let amount = Double(amountStr) {
                            if let total = result.total, amount < total {
                                detectedVats.append(amount)
                            }
                        }
                    }
                }
            }
        }
        
        // If multiple matches, sum them if they are small (aggregation logic)
        // If we found a "TOPLAM KDV" specifically, we might prefer that.
        // For now, let's take the largest if it's below total, OR sum if they look like line items.
        // Actually, many receipts list KDV %1, KDV %10, KDV %20 and then a TOTAL KDV.
        // If we sum them all, we might double count.
        // Heuristic: If we have multiple and one is close to the sum of others, take the largest.
        if !detectedVats.isEmpty {
            let totalVat = detectedVats.max() ?? 0.0
            result.vatTotal = totalVat
        }
        
        // Fallback Compute: vatTotal = total - net (if keywords found)
        if result.vatTotal == nil, let total = result.total {
            let netKeywords = ["ARA TOPLAM", "TOPLAM MATRAH", "NET TOPLAM", "KDV HARIÇ", "KDV HARIC"]
            for keyword in netKeywords {
                if normalizedText.contains(keyword) {
                    // Try to find the amount after this keyword
                    let pattern = NSRegularExpression.escapedPattern(for: keyword) + #"\s*[:\-\=]?\s*(?:₺|TL|TR)?\s*(\d{1,3}(?:[\.\s]\d{3})*(?:,\d{2})|\d+(?:,\d{2})|\d+(?:\.\d{2}))"#
                    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                       let match = regex.firstMatch(in: normalizedText, range: NSRange(normalizedText.startIndex..., in: normalizedText)),
                       let range = Range(match.range(at: 1), in: normalizedText) {
                        
                        let netStr = String(normalizedText[range])
                            .replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: ".", with: "")
                            .replacingOccurrences(of: ",", with: ".")
                        
                        if let net = Double(netStr) {
                            let diff = total - net
                            if diff > 0 && diff < (total * 0.5) { // Guards: positive and max 50%
                                result.vatTotal = diff
                                break
                            }
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
