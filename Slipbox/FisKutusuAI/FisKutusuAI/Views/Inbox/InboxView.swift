import SwiftUI

struct InboxView: View {
    @StateObject private var viewModel = InboxViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var entitlementManager: EntitlementManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var showingScanner = false
    @State private var showingPaywall = false
    @State private var isSearching = false
    @FocusState private var isSearchFieldFocused: Bool
    
    private let scanLimit = 15
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                Color(hex: "0A0A14")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header or Search Bar
                    if isSearching {
                        searchBar
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                        .padding(.top, 16)
                    
                    // Segmented Control
                    segmentedControl
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Receipt List
                    if viewModel.filteredReceipts.isEmpty {
                        emptyState
                    } else {
                        receiptsList
                    }
                }
            }
            .fullScreenCover(isPresented: $showingScanner) {
                ScannerCoordinator()
            }
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func tryScanning() {
        if entitlementManager.isPro {
            showingScanner = true
        } else {
            // Check limit
            if viewModel.receipts.count >= scanLimit {
                showingPaywall = true
            } else {
                showingScanner = true
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Text("inbox".localized)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                tryScanning()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 16)
            
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isSearching = true
                    isSearchFieldFocused = true
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.4))
                
                TextField("ara".localized, text: $viewModel.searchText)
                    .foregroundColor(.white)
                    .focused($isSearchFieldFocused)
                    .submitLabel(.search)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            
            Button("vazgec".localized) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isSearching = false
                    viewModel.searchText = ""
                    isSearchFieldFocused = false
                }
            }
            .foregroundColor(Color(hex: "4F46E5"))
            .font(.system(size: 16, weight: .medium))
        }
    }
    
    // MARK: - Segmented Control
    private var segmentedControl: some View {
        HStack(spacing: 8) {
            segmentButton(label: "status_new".localized, status: .new)
            segmentButton(label: "status_needs_review".localized, status: .pendingReview)
            segmentButton(label: "status_approved".localized, status: .approved)
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
    
    private func segmentButton(label: String, status: ReceiptStatus) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.setFilter(viewModel.selectedFilter == status ? nil : status)
            }
        }) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(viewModel.selectedFilter == status ? .white : .white.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(viewModel.selectedFilter == status ? Color(hex: "4F46E5") : Color.clear)
                )
        }
    }
    
    // MARK: - Receipts List
    private var receiptsList: some View {
        List {
            ForEach(viewModel.filteredReceipts) { receipt in
                ZStack {
                    // Hidden Navigation Link for Tap
                    NavigationLink(destination: ReceiptDetailView(receipt: receipt, viewModel: viewModel)) {
                        EmptyView()
                    }
                    .opacity(0)
                    
                    // Visible Card
                    ReceiptCardView(receipt: receipt)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteReceipt(receipt)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 22))
                    }
                    .tint(.red)
                    
                    NavigationLink(destination: ReceiptDetailView(receipt: receipt, viewModel: viewModel)) {
                        Image(systemName: "pencil")
                            .font(.system(size: 22))
                    }
                    .tint(Color(hex: "4F46E5"))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(hex: "0A0A14").ignoresSafeArea()) // Fix overscroll
        .padding(.bottom, 100)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1C1C1E"))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-6))
                
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "2C2C2E"))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(6))
                
                Image(systemName: "doc.text")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "4F46E5"))
            }
            .padding(.bottom, 16)
            
            Text("inbox_empty".localized)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("inbox_subtitle".localized)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                tryScanning()
            }) {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                    Text("scan_receipt".localized)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 200, height: 56)
                .background(Color(hex: "4F46E5"))
                .cornerRadius(16)
                .shadow(color: Color(hex: "4F46E5").opacity(0.4), radius: 20, x: 0, y: 10)
            }
            .padding(.top, 16)
            
            Spacer()
        }
    }
}

// MARK: - Add Receipt Placeholder
struct AddReceiptPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "050511")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: "4F46E5"))
                
                Text("fis_ekleme".localized)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Kamera akışı burada görünecek")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("kapat".localized) {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4F46E5"))
                }
            }
        }
    }
}

#Preview {
    InboxView()
}
