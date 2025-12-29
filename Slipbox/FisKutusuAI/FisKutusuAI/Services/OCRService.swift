import Vision
import UIKit

class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    /// Recognize text from an image using Vision framework
    func recognizeText(from image: UIImage) async throws -> String {
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
                
                if fullText.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: fullText)
                }
            }
            
            // Configure OCR request
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["tr-TR", "en-US"]
            request.usesLanguageCorrection = true
            
            // Perform OCR
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Parse structured data from raw OCR text (placeholder)
    func parseReceiptData(from text: String) -> ParsedReceipt {
        return ParsedReceipt(
            merchant: parseMerchant(from: text),
            date: parseDate(from: text),
            total: parseTotal(from: text),
            currency: "TRY"
        )
    }
    
    // MARK: - Private Parsing Helpers
    
    private func parseMerchant(from text: String) -> String? {
        // Simple heuristic: First non-empty line
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return lines.first
    }
    
    private func parseDate(from text: String) -> Date? {
        // Look for date patterns: DD.MM.YYYY, DD/MM/YYYY, YYYY-MM-DD
        let patterns = [
            #"(\d{2})[./](\d{2})[./](\d{4})"#,
            #"(\d{4})-(\d{2})-(\d{2})"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let dateString = String(text[range])
                
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                formatter.dateFormat = "dd/MM/yyyy"
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    private func parseTotal(from text: String) -> Double? {
        // Look for currency amounts: 123.45, 123,45, 1.234,56
        let patterns = [
            #"(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})"#,  // 1.234,56 or 1,234.56
            #"(\d+[.,]\d{2})"#                      // 123.45 or 123,45
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                var amountString = String(text[range])
                
                // Normalize to Double format (remove thousand separators, replace , with .)
                amountString = amountString.replacingOccurrences(of: ".", with: "")
                amountString = amountString.replacingOccurrences(of: ",", with: ".")
                
                if let amount = Double(amountString) {
                    return amount
                }
            }
        }
        
        return nil
    }
}

// MARK: - Models

struct ParsedReceipt {
    let merchant: String?
    let date: Date?
    let total: Double?
    let currency: String
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noTextFound:
            return "No text found in image"
        }
    }
}
