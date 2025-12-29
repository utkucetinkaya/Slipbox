import SwiftUI

struct ReceiptDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: InboxViewModel
    
    @State private var receipt: Receipt
    @State private var showingApproveSheet = false
    @State private var showingImagePreview = false
    @State private var showingCategoryPicker = false
    
    init(receipt: Receipt, viewModel: InboxViewModel) {
        self._receipt = State(initialValue: receipt)
        self.viewModel = viewModel
    }
    
    var isEditable: Bool {
        // Editable if Needs Review OR Approved (user can still fix data after approval)
        // Processing is strictly read-only
        receipt.status == .needsReview || receipt.status == .approved
    }
    
    var body: some View {
        ZStack {
            // ... background ...
            Color(hex: "050511").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // ... content ...
                    imagePreview
                    
                    if receipt.status == .processing {
                        statusBanner(text: "Fiş işleniyor, lütfen bekleyin...", icon: "clock.fill", color: .blue)
                    } else if receipt.status == .approved {
                        // Optional: Don't show banner if we want a clean look, or keep it to indicate checking status.
                        // User request: "Eğer status = approved ise 'Kaydet' (edit) olabilir ama onay butonları olmaz."
                        // So approved is "editable" for corrections, but already confident.
                    }
                    
                    formFields
                        .disabled(!isEditable)
                        .opacity(isEditable ? 1 : 0.8)
                    
                    noteSection
                        .disabled(!isEditable)
                        .opacity(isEditable ? 1 : 0.8)
                    
                    autoCategorizeToggle
                        .disabled(!isEditable)
                        .opacity(isEditable ? 1 : 0.8)
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .scrollContentBackground(.hidden)
            
            // Bottom Buttons - ONLY for Needs Review (Approve/Reject)
            if receipt.status == .needsReview {
                VStack {
                    Spacer()
                    bottomButtons
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Fiş İnceleme")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditable {
                    Button(action: saveAndDismiss) {
                        Text("Kaydet")
                            .foregroundColor(Color(hex: "4F46E5"))
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar) // Hide Tab Bar
        .sheet(isPresented: $showingApproveSheet) {
            ApproveReceiptSheetView(
                receipt: receipt,
                onApprove: {
                    // Update local state first to ensure consistency
                    receipt.status = .approved
                    receipt.confidence = 1.0
                    
                    // Update ViewModel
                    viewModel.updateReceipt(receipt)
                    
                    // Dismiss view
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(selectedCategoryId: $receipt.categoryId)
        }
        .fullScreenCover(isPresented: $showingImagePreview) {
            ImagePreviewView(dismiss: $showingImagePreview)
        }
        .onDisappear {
            // Auto-save changes when leaving the screen
            if isEditable {
                viewModel.updateReceipt(receipt)
            }
        }
    }
    
    // MARK: - Status Banner
    private func statusBanner(text: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
            Text(text)
                .font(.system(size: 14, weight: .medium))
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Image Preview
    private var imagePreview: some View {
        Button(action: { showingImagePreview = true }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1C1C1E"))
                    .frame(height: 200)
                
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12))
                        Text("YAKINLAŞTIRMAK İÇİN DOKUN")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: 16) {
            // Merchant
            FormField(
                label: "İşletme",
                icon: "storefront",
                value: $receipt.merchant,
                placeholder: "İşletme adı"
            )
            
            // Date & Amount Row
            HStack(spacing: 12) {
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tarih")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(formatDate(receipt.displayDate))
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(12)
                }
                
                // Amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tutar")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack {
                        Text("₺")
                            .foregroundColor(.white)
                        TextField("0,00", value: $receipt.total, format: .number)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                    }
                    .font(.system(size: 16))
                    .padding()
                    .background(Color(hex: "1C1C1E"))
                    .cornerRadius(12)
                }
            }
            
            // Category
            categoryPicker
        }
    }
    
    private var categoryPicker: some View {
        Button(action: {
            if isEditable {
                showingCategoryPicker = true
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Kategori")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if receipt.status == .needsReview {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Kontrol Et")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "FFCC00"))
                    }
                }
                
                HStack {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(receipt.displayCategoryColor)
                    
                    // Use the new displayCategoryName property for translated name
                    Text(receipt.displayCategoryName ?? "Market & Alışveriş")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isEditable {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()
                .background(Color(hex: "1C1C1E"))
                .cornerRadius(12)
            }
        }
        .disabled(!isEditable)
    }
    
    // MARK: - Note Section
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Not (Opsiyonel)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            ZStack(alignment: .topLeading) {
                if receipt.notes?.isEmpty ?? true {
                    Text("Fiş hakkında not ekle...")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                
                TextEditor(text: Binding(
                    get: { receipt.notes ?? "" },
                    set: { receipt.notes = $0 }
                ))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.clear) // Ensure transparency
                .frame(minHeight: 100)
            }
            .padding(12)
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Auto Categorize Toggle
    private var autoCategorizeToggle: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Otomatik Kategori")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Bu işletmeyi her zaman \(receipt.displayCategoryName ?? "Market & Alışveriş") kategorisine ata")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Toggle("", isOn: Binding(
                get: { receipt.autoCategorizeMerchant ?? false },
                set: { receipt.autoCategorizeMerchant = $0 }
            ))
                .labelsHidden()
        }
        .padding(16)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(16)
    }
    
    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        HStack(spacing: 12) {
            // Processing: No buttons
            if receipt.status == .processing {
                EmptyView()
            }
            // Needs Review: Reject and Approve
            else if receipt.status == .needsReview {
                Button(action: {
                    viewModel.rejectReceipt(id: receipt.id ?? "")
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Reddet")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "FF3B30").opacity(0.2))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "FF3B30"), lineWidth: 1)
                    )
                }
                
                Button(action: { showingApproveSheet = true }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Onayla")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "4F46E5"))
                    .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal, 20)
        // Add bottom padding to lift buttons off the very bottom/home indicator
        .padding(.bottom, 10) 
        .background(
            // Gradient background
            VStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "050511").opacity(0), location: 0),
                        .init(color: Color(hex: "050511"), location: 0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                Color(hex: "050511")
            }
            .ignoresSafeArea()
        )
    }
    
    // MARK: - Helpers
    private func saveAndDismiss() {
        viewModel.updateReceipt(receipt)
        dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "tr-TR")
        return formatter.string(from: date)
    }
}

// MARK: - Form Field Component
struct FormField: View {
    let label: String
    let icon: String
    @Binding var value: String?
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            HStack {
                TextField(placeholder, text: Binding(
                    get: { value ?? "" },
                    set: { value = $0 }
                ))
                .font(.system(size: 16))
                .foregroundColor(.white)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding()
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(12)
        }
    }
}

// MARK: - Image Preview
struct ImagePreviewView: View {
    @Binding var dismiss: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                
                Spacer()
                
                Image(systemName: "doc.text.image")
                    .font(.system(size: 120))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Önizleme")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReceiptDetailView(
            receipt: MockData.inboxReceipts[0],
            viewModel: InboxViewModel()
        )
    }
}
