import Foundation
import PDFKit
import SwiftUI

class ExportService {
    static let shared = ExportService()
    
    private init() {}
    
    /// Generate PDF Report locally
    func generatePDF(receipts: [Receipt], month: String) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "SlipBox App",
            kCGPDFContextAuthor: "User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 595.2 // A4 width
        let pageHeight = 841.8 // A4 height
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // Header
            let title = "Harcama Raporu - \(month)"
            let titleAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)]
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            var yPosition = 100.0
            
            // Table Header
            let headers = ["Tarih", "Mekan", "Kategori", "Tutar"]
            var xPosition = 50.0
            let columnWidths = [100.0, 150.0, 100.0, 100.0]
            
            for (index, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)])
                xPosition += columnWidths[index]
            }
            
            yPosition += 20
            
            // Rows
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            
            let currencyFormatter = NumberFormatter()
            currencyFormatter.numberStyle = .currency
            currencyFormatter.currencyCode = "TRY"
            
            for receipt in receipts {
                if yPosition > pageHeight - 50 {
                    context.beginPage()
                    yPosition = 50
                }
                
                xPosition = 50.0
                let dateStr = receipt.date != nil ? dateFormatter.string(from: receipt.date!) : "-"
                let merchantStr = receipt.merchant ?? "Bilinmiyor"
                let categoryStr = receipt.categoryId ?? "-"
                let totalStr = currencyFormatter.string(from: NSNumber(value: receipt.total ?? 0.0)) ?? "-"
                
                let rowData = [dateStr, merchantStr, categoryStr, totalStr]
                
                for (index, text) in rowData.enumerated() {
                    text.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)])
                    xPosition += columnWidths[index]
                }
                
                yPosition += 20
            }
            
            // Total
            yPosition += 20
            let totalSum = receipts.reduce(0) { $0 + ($1.total ?? 0) }
            let totalStr = "TOPLAM: " + (currencyFormatter.string(from: NSNumber(value: totalSum)) ?? "")
            totalStr.draw(at: CGPoint(x: 350, y: yPosition), withAttributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)])
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("Report_\(month).pdf")
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("PDF write error: \(error)")
            return nil
        }
    }
    
    /// Generate CSV Report locally
    func generateCSV(receipts: [Receipt], month: String) -> URL? {
        var csvString = "Tarih,Mekan,Kategori,Tutar,Para Birimi,Not\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        for receipt in receipts {
            let dateStr = receipt.date != nil ? dateFormatter.string(from: receipt.date!) : ""
            let merchant = (receipt.merchant ?? "").replacingOccurrences(of: ",", with: " ")
            let category = (receipt.categoryId ?? "").replacingOccurrences(of: ",", with: " ")
            let total = String(format: "%.2f", receipt.total ?? 0.0)
            let currency = receipt.currency ?? "TRY"
            let notes = (receipt.notes ?? "").replacingOccurrences(of: ",", with: " ")
            
            let line = "\(dateStr),\(merchant),\(category),\(total),\(currency),\(notes)\n"
            csvString.append(line)
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("Report_\(month).csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("CSV write error: \(error)")
            return nil
        }
    }
}
