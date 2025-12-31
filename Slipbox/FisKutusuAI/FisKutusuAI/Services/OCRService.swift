import Foundation
import Vision
import UIKit

struct OCRResult {
    var rawText: String
    var merchantName: String?
    var total: Double?
    var date: Date?
    var confidence: Double
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
        
        // 1. Merchant Name Heuristic: Usually the first line with enough characters that isn't just date/time
        for line in lines.prefix(3) {
            let clean = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.count > 3 && !clean.contains(":") && !clean.contains(".") {
                result.merchantName = clean
                break
            }
        }
        if result.merchantName == nil {
             result.merchantName = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 2. Total Amount (Looking for the largest number near currency keywords or generally the largest in the bottom half)
        // Regex: Matches numbers like 123,45 123.45 and optional ₺, TL, TRY
        let amountPattern = #"(\d+[\.,]\d{2})(?:\s*(?:TL|TRY|₺))?"#
        let amountRegex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive)
        let matches = amountRegex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        
        var amounts: [Double] = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: text) {
                let cleanStr = text[range].replacingOccurrences(of: ",", with: ".")
                if let val = Double(cleanStr) {
                    amounts.append(val)
                }
            }
        }
        // Take the largest one as it's usually the total
        result.total = amounts.max()
        
        // 3. Date (Regex for DD.MM.YYYY, DD/MM/YYYY, etc.)
        let datePattern = #"(\d{1,2}[\./-]\d{1,2}[\./-]\d{2,4})"#
        let dateRegex = try? NSRegularExpression(pattern: datePattern)
        if let match = dateRegex?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let range = Range(match.range(at: 1), in: text) {
                let dateStr = String(text[range])
                let formats = ["dd.MM.yyyy", "dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yy", "dd/MM/yy"]
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "tr_TR")
                for format in formats {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateStr) {
                        result.date = date
                        break
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
        
        return result
    }
    
    enum OCRError: Error {
        case invalidImage
        case noTextFound
    }
}
