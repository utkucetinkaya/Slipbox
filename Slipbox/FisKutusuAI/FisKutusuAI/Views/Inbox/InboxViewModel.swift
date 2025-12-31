import Foundation
import SwiftUI
import Combine

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
            filtered = filtered.filter { $0.status == status }
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
