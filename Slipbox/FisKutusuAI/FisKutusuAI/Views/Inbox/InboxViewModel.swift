import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

class InboxViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var selectedFilter: ReceiptStatus? = .pendingReview
    @Published var searchText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let repository = FirestoreReceiptRepository.shared
    
    var filteredReceipts: [Receipt] {
        var filtered: [Receipt] = receipts
        
        // Status filter
        if let status = selectedFilter {
            if status == .new {
                // 'Yeni' tab: Only show .new receipts from the last 15 minutes
                let fifteenMinsAgo = Date().addingTimeInterval(-15 * 60)
                filtered = filtered.filter { receipt in
                    receipt.status == .new && (receipt.createdAt?.dateValue() ?? Date()) > fifteenMinsAgo
                }
            } else if status == .pendingReview {
                // 'Onay Bekleyen' tab: Show BOTH .new and .pendingReview
                // This acts as a catch-all for items requiring approval
                filtered = filtered.filter { $0.status == .new || $0.status == .pendingReview }
            } else {
                filtered = filtered.filter { $0.status == status }
            }
        }
        
        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter { receipt in
                let merchantMatch = receipt.merchantName?.lowercased().contains(query) ?? false
                let noteMatch = receipt.note?.lowercased().contains(query) ?? false
                return merchantMatch || noteMatch
            }
        }
        
        return filtered.sorted(by: { $0.displayDate > $1.displayDate })
    }
    
    init() {
        setupSubscription()
    }
    
    private func setupSubscription() {
        repository.$receipts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] receipts in
                self?.receipts = receipts
            }
            .store(in: &cancellables)
    }
    
    func deleteReceipt(_ receipt: Receipt) {
        Task {
            do {
                try await repository.deleteReceipt(receipt)
                await MainActor.run {
                    if let index = self.receipts.firstIndex(where: { $0.id == receipt.id }) {
                        self.receipts.remove(at: index)
                    }
                }
                print("✅ Receipt deleted: \(receipt.id ?? "")")
            } catch {
                print("❌ Delete failed: \(error.localizedDescription)")
            }
        }
    }
    
    func approveReceipt(id: String) {
        guard let receipt = receipts.first(where: { $0.id == id }) else { return }
        var updated = receipt
        updated.status = .approved
        
        Task {
            do {
                try await repository.updateReceipt(updated)
                print("✅ Receipt approved: \(id)")
            } catch {
                print("❌ Approval failed: \(error.localizedDescription)")
            }
        }
    }
    
    func rejectReceipt(id: String) {
        guard let receipt = receipts.first(where: { $0.id == id }) else { return }
        deleteReceipt(receipt)
    }
    
    func setFilter(_ status: ReceiptStatus?) {
        selectedFilter = status
    }
}
