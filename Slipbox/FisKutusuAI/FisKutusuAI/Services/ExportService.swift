import Foundation
import PDFKit
import SwiftUI

class ExportService {
    static let shared = ExportService()
    
    private init() {}
    
    /// Generate PDF Report locally
    func generatePDF(receipts: [Receipt], month: String, totalExpense: Double, totalVat: Double, currencyCode: String) -> URL? {
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
            
            // Force Light Mode: Fill background with white
            UIColor.white.setFill()
            UIRectFill(pageRect)
            
            // 1. Logo
            if let logoImg = UIImage(named: "AppLogo") {
                let logoRect = CGRect(x: 50, y: 35, width: 40, height: 40)
                logoImg.draw(in: logoRect)
            }
            
            // Header
            let monthTitle = month.uppercased()
            let title = "Harcama Raporu"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1.0) // Gray 800
            ]
            let monthAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor(red: 79/255, green: 70/255, blue: 229/255, alpha: 1.0) // Indigo 600
            ]
            
            title.draw(at: CGPoint(x: 100, y: 40), withAttributes: titleAttributes)
            monthTitle.draw(at: CGPoint(x: 100, y: 65), withAttributes: monthAttributes)
            
            // Draw a separator line
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 50, y: 95))
            path.addLine(to: CGPoint(x: pageWidth - 50, y: 95))
            UIColor(white: 0.9, alpha: 1.0).setStroke()
            path.lineWidth = 1
            path.stroke()
            
            // Summary Section
            let summaryY = 105.0
            let boxWidth = (pageWidth - 120) / 3
            
            drawSummaryBox(context: context.cgContext, rect: CGRect(x: 50, y: summaryY, width: boxWidth, height: 60), title: "Toplam Gider", value: formatCurrency(totalExpense, currencyCode: currencyCode))
            drawSummaryBox(context: context.cgContext, rect: CGRect(x: 50 + boxWidth + 10, y: summaryY, width: boxWidth, height: 60), title: "Toplam KDV", value: formatCurrency(totalVat, currencyCode: currencyCode))
            drawSummaryBox(context: context.cgContext, rect: CGRect(x: 50 + (boxWidth + 10) * 2, y: summaryY, width: boxWidth, height: 60), title: "Fiş Sayısı", value: "\(receipts.count)")
            
            var yPosition = 190.0
            
            // Table Header
            let headers = ["Tarih/Saat", "İşletme", "VKN", "Fiş No", "Kategori", "Tutar"]
            var xPosition = 40.0
            let columnWidths = [85.0, 125.0, 85.0, 80.0, 80.0, 60.0]
            
            // Header Background
            let headerRect = CGRect(x: 50, y: yPosition - 5, width: pageWidth - 100, height: 25)
            UIColor(red: 243/255, green: 244/255, blue: 246/255, alpha: 1.0).setFill() // Gray 100
            UIRectFill(headerRect)
            
            for (index, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: xPosition + 5, y: yPosition), withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: UIColor(red: 75/255, green: 85/255, blue: 99/255, alpha: 1.0) // Gray 600
                ])
                xPosition += columnWidths[index]
            }
            
            yPosition += 30
            
            // Rows
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            
            for (index, receipt) in receipts.enumerated() {
                if yPosition > pageHeight - 60 {
                    context.beginPage()
                    yPosition = 50
                }
                
                // Zebra stripe
                if index % 2 != 0 {
                    let rowRect = CGRect(x: 50, y: yPosition - 5, width: pageWidth - 100, height: 22)
                    UIColor(white: 0.98, alpha: 1.0).setFill()
                    UIRectFill(rowRect)
                }
                
                xPosition = 40.0
                let dateStr = receipt.date != nil ? dateFormatter.string(from: receipt.date!) : "-"
                let timeStr = receipt.receiptTime ?? ""
                let dateTimeStr = timeStr.isEmpty ? dateStr : "\(dateStr)\n\(timeStr)"
                
                let merchantStr = receipt.merchantName ?? "Bilinmiyor"
                let vknStr = receipt.taxOfficeIdNumber ?? "-"
                let fisNoStr = receipt.receiptNumber ?? "-"
                let categoryStr = receipt.categoryName ?? "-"
                let totalStr = formatCurrency(receipt.total ?? 0.0, currencyCode: currencyCode)
                
                let rowData = [dateTimeStr, merchantStr, vknStr, fisNoStr, categoryStr, totalStr]
                
                for (index, text) in rowData.enumerated() {
                    let rect = CGRect(x: xPosition + 5, y: yPosition, width: columnWidths[index], height: 20)
                    text.draw(in: rect, withAttributes: [
                        .font: UIFont.systemFont(ofSize: 9),
                        .foregroundColor: UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1.0) // Gray 800
                    ])
                    xPosition += columnWidths[index]
                }
                
                yPosition += 22
            }
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("SlipBox_Rapor_\(month.replacingOccurrences(of: " ", with: "_")).pdf")
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("PDF write error: \(error)")
            return nil
        }
    }
    
    private func drawSummaryBox(context: CGContext, rect: CGRect, title: String, value: String) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 12)
        UIColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1.0).setFill() // Slate 50
        path.fill()
        
        // Border
        UIColor(red: 226/255, green: 232/255, blue: 240/255, alpha: 1.0).setStroke() // Slate 200
        path.lineWidth = 1
        path.stroke()
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: UIColor(red: 100/255, green: 116/255, blue: 139/255, alpha: 1.0) // Slate 500
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .bold),
            .foregroundColor: UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1.0) // Slate 900
        ]
        
        title.draw(at: CGPoint(x: rect.minX + 15, y: rect.minY + 12), withAttributes: titleAttrs)
        value.draw(at: CGPoint(x: rect.minX + 15, y: rect.minY + 28), withAttributes: valueAttrs)
    }
    
    private func formatCurrency(_ amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        // Try to match locale to currency for better formatting (e.g. ₺ vs TL)
        if currencyCode == "TRY" {
            formatter.locale = Locale(identifier: "tr_TR")
        } else if currencyCode == "USD" {
            formatter.locale = Locale(identifier: "en_US")
        } else {
            formatter.locale = Locale.current
        }
        return formatter.string(from: NSNumber(value: amount)) ?? "-"
    }
    
    /// Generate CSV Report locally
    func generateCSV(receipts: [Receipt], month: String) -> URL? {
        // Turkish CSV often uses Semicolon as separator due to comma in decimals
        var csvString = "Tarih;Saat;İşletme;Kategori;Tutar;KDV;VKN/TCKN;Fiş No;İşyeri No;Terminal No;Para Birimi;Not\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        for receipt in receipts {
            let dateStr = receipt.date != nil ? dateFormatter.string(from: receipt.date!) : ""
            let timeStr = receipt.receiptTime ?? ""
            let merchant = (receipt.merchantName ?? "").replacingOccurrences(of: ";", with: " ")
            let category = (receipt.categoryName ?? "").replacingOccurrences(of: ";", with: " ")
            
            // Format number with Turkish locale (comma for decimal)
            let total = String(format: "%.2f", receipt.total ?? 0.0).replacingOccurrences(of: ".", with: ",")
            let vatTotal = String(format: "%.2f", receipt.vatTotal ?? 0.0).replacingOccurrences(of: ".", with: ",")
            
            let vkn = receipt.taxOfficeIdNumber ?? ""
            let fisNo = receipt.receiptNumber ?? ""
            let isyeriNo = receipt.workplaceNumber ?? ""
            let terminalNo = receipt.terminalNumber ?? ""
            
            let currency = receipt.currency ?? "TRY"
            let notes = (receipt.note ?? "").replacingOccurrences(of: ";", with: " ").replacingOccurrences(of: "\n", with: " ")
            
            let line = "\(dateStr);\(timeStr);\(merchant);\(category);\(total);\(vatTotal);\(vkn);\(fisNo);\(isyeriNo);\(terminalNo);\(currency);\(notes)\n"
            csvString.append(line)
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("SlipBox_Rapor_\(month.replacingOccurrences(of: " ", with: "_")).csv")
        
        do {
            // Include UTF-8 BOM for Excel compatibility with Turkish characters
            let bom = "\u{FEFF}"
            let finalCsv = bom + csvString
            try finalCsv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("CSV write error: \(error)")
            return nil
        }
    }
}

