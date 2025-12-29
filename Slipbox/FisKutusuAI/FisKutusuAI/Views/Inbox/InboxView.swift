import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

struct InboxView: View {
    @StateObject private var viewModel = InboxViewModel()
    @State private var selectedTab: ReceiptTab = .needsReview
    @State private var showingCamera = false
    
    enum ReceiptTab: String, CaseIterable {
        case processing = "Yeni"
        case needsReview = "Onay Bekleyen"
        case approved = "Tamam"
        
        var status: ReceiptStatus {
            switch self {
            case .processing: return .processing
            case .needsReview: return .needsReview
            case .approved: return .approved
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tabs
                tabBar
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.receipts.isEmpty {
                    emptyStateView
                } else {
                    receiptsList
                }
            }
            .navigationTitle("Gelen Kutusu")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCamera = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                Text("Camera Capture View")
                    // CameraCaptureView() // Will implement next
            }
        }
        .task {
            // Start real-time listener instead of one-time fetch
            viewModel.startListening(status: selectedTab.status)
        }
        .onDisappear {
            // Clean up listener when view disappears
            viewModel.stopListening()
        }
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ReceiptTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                    // Switch listener to new status
                    viewModel.startListening(status: tab.status)
                }) {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(AppFonts.callout())
                            .foregroundColor(selectedTab == tab ? AppColors.primary : AppColors.textSecondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? AppColors.primary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .background(AppColors.background)
    }
    
    // MARK: - Receipts List
    private var receiptsList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.receipts) { receipt in
                    NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                        ReceiptCardView(receipt: receipt)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(AppSpacing.md)
        }
        .refreshable {
            await viewModel.loadReceipts(status: selectedTab.status)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Yükleniyor...")
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, AppSpacing.md)
            Spacer()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            
            Image(systemName: emptyStateIcon)
                .font(.system(size: 64))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            
            Text(emptyStateTitle)
                .font(AppFonts.title2())
                .foregroundColor(AppColors.textPrimary)
            
            Text(emptyStateMessage)
                .font(AppFonts.body())
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            
            if selectedTab == .needsReview || selectedTab == .processing {
                Button(action: { showingCamera = true }) {
                    Text("Fiş Ekle")
                        .primaryButton()
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.md)
            }
            
            Spacer()
        }
    }
    
    private var emptyStateIcon: String {
        switch selectedTab {
        case .processing: return "clock.arrow.circlepath"
        case .needsReview: return "exclamationmark.circle"
        case .approved: return "checkmark.circle"
        }
    }
    
    private var emptyStateTitle: String {
        switch selectedTab {
        case .processing: return "İşleniyor..."
        case .needsReview: return "Onay Bekleyen Fiş Yok"
        case .approved: return "Onaylanmış Fiş Yok"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedTab {
        case .processing: return "Yüklenen fişler otomatik olarak işleniyor"
        case .needsReview: return "Onaylanması gereken fiş bulunmuyor"
        case .approved: return "Henüz onaylanmış fiş yok. Fiş ekleyerek başlayın!"
        }
    }
}

// MARK: - ViewModel
@MainActor
class InboxViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Use Firestore repository (Phase 3)
    private let repository: ReceiptRepository = FirestoreReceiptRepository.shared
    private var listener: ListenerRegistration?
    
    func loadReceipts(status: ReceiptStatus) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            receipts = try await repository.fetchReceipts(status: status)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Real-time listener for automatic updates
    func startListening(status: ReceiptStatus) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Remove previous listener
        listener?.remove()
        
        // Create new listener with correct path + orderBy
        listener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("receipts")
            .whereField("status", isEqualTo: status.rawValue)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self.receipts = documents.compactMap { try? $0.data(as: Receipt.self) }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func deleteReceipt(id: String) async {
        do {
            try await repository.deleteReceipt(id: id)
            receipts.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    deinit {
        listener?.remove()
    }
}

// MARK: - Preview
#Preview {
    InboxView()
}
