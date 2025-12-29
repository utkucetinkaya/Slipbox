import Foundation
import SwiftUI
import Combine

class InboxViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var selectedFilter: ReceiptStatus? = .processing {
        didSet {
            print("🔍 Filter changed to: \(selectedFilter?.displayText ?? "All")")
            debugPrintCounts()
        }
    }
    
    var filteredReceipts: [Receipt] {
        let filtered: [Receipt]
        if let status = selectedFilter {
            filtered = receipts.filter { $0.status == status }
        } else {
            filtered = receipts
        }
        return filtered.sorted(by: { $0.displayDate > $1.displayDate })
    }
    
    init() {
        self.receipts = MockData.inboxReceipts
        print("🚀 InboxViewModel initialized with \(receipts.count) receipts")
        debugPrintCounts()
        simulateProcessing()
    }
    
    func simulateProcessing() {
        let processingReceipts = receipts.filter { $0.status == .processing }
        
        for receipt in processingReceipts {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int.random(in: 3...5))) { [weak self] in
                guard let self = self else { return }
                
                // Find current index (in case it changed)
                if let index = self.receipts.firstIndex(where: { $0.id == receipt.id }) {
                    var updated = self.receipts[index]
                    
                    // Randomly decide outcome: 60% needs review, 40% approved
                    let isApproved = Double.random(in: 0...1) > 0.6
                    
                    if isApproved {
                        updated.status = .approved
                        updated.confidence = 0.95
                        print("✨ Receipt auto-processed -> APPROVED: \(updated.merchant ?? "")")
                    } else {
                        updated.status = .needsReview
                        updated.confidence = 0.65
                        print("⚠️ Receipt auto-processed -> NEEDS REVIEW: \(updated.merchant ?? "")")
                    }
                    
                    self.receipts[index] = updated
                    self.objectWillChange.send()
                    self.debugPrintCounts()
                }
            }
        }
    }
    
    func deleteReceipt(_ receipt: Receipt) {
        print("🗑️ Deleting receipt: \(receipt.id ?? "unknown")")
        receipts.removeAll { $0.id == receipt.id }
        print("✅ Receipt deleted. Remaining count: \(receipts.count)")
        objectWillChange.send() 
    }
    
    func updateReceipt(_ updatedReceipt: Receipt) {
        if let index = receipts.firstIndex(where: { $0.id == updatedReceipt.id }) {
            print("✏️ Updating receipt: \(updatedReceipt.merchant ?? "unknown")")
            receipts[index] = updatedReceipt
            objectWillChange.send()
        }
    }
    
    func approveReceipt(id: String) {
        print("👍 Approving receipt: \(id)")
        if let index = receipts.firstIndex(where: { $0.id == id }) {
            var updated = receipts[index]
            updated.status = .approved
            updated.confidence = 1.0
            receipts[index] = updated
            
            print("✅ Receipt approved. New status: \(updated.status.rawValue)")
            objectWillChange.send()
            
            // Force UI refresh if needed by slight delay or direct check
            debugPrintCounts()
        } else {
            print("❌ Receipt not found for approval: \(id)")
        }
    }
    
    func rejectReceipt(id: String) {
        print("👎 Rejecting receipt: \(id)")
        receipts.removeAll { $0.id == id }
        print("✅ Receipt rejected/removed. Remaining count: \(receipts.count)")
        objectWillChange.send()
    }
    
    func setFilter(_ status: ReceiptStatus?) {
        selectedFilter = status
    }
    
    private func debugPrintCounts() {
        let processing = receipts.filter { $0.status == .processing }.count
        let needsReview = receipts.filter { $0.status == .needsReview }.count
        let approved = receipts.filter { $0.status == .approved }.count
        print("📊 Stats - Yeni: \(processing), Bekleyen: \(needsReview), Tamam: \(approved)")
    }
}
