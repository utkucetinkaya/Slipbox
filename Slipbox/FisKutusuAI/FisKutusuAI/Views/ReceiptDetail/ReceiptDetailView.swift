import SwiftUI

struct ReceiptDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: InboxViewModel
    @EnvironmentObject var userPreferences: AppUserPreferences
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var uiState: AppUIState
    
    @State private var receipt: Receipt
    @State private var showingApproveSheet = false
    @State private var showingImagePreview = false
    @State private var showingCategoryPicker = false
    @State private var wasDeleted = false
    
    init(receipt: Receipt, viewModel: InboxViewModel) {
        self._receipt = State(initialValue: receipt)
        self.viewModel = viewModel
    }
    
    var isEditable: Bool {
        // Editable if New, Pending Review OR Approved (user can still fix data after approval)
        receipt.status == .new || receipt.status == .pendingReview || receipt.status == .approved
    }
    
    var body: some View {
        ZStack {
            // ... background ...
            DesignSystem.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // ... content ...
                    imagePreview
                    
                    if receipt.status == .processing {
                        statusBanner(text: "processing_banner".localized, icon: "clock.fill", color: .blue)
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
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .scrollContentBackground(.hidden)
            
            // Bottom Buttons - New or Pending Review (Approve/Reject)
            if receipt.status == .new || receipt.status == .pendingReview {
                VStack {
                    Spacer()
                    bottomButtons
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("receipt_review".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditable {
                    Button(action: saveAndDismiss) {
                        Text("save".localized)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
        // .toolbar(.hidden, for: .tabBar) // REMOVED: Redundant and causes layout glitches since we hide globally
        .sheet(isPresented: $showingApproveSheet) {
            ApproveReceiptSheetView(
                receipt: receipt,
                onApprove: {
                    // Approval logic
                    var updated = receipt
                    updated.status = .approved
                    updated.confidence = 1.0
                    
                    // IMPORTANT: Update local state to avoid onDisappear overwriting
                    self.receipt = updated
                    
                    Task {
                        try? await FirestoreReceiptRepository.shared.updateReceipt(updated)
                        dismiss()
                    }
                }
            )
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(selectedCategoryId: $receipt.categoryId)
        }
        .onChange(of: receipt.categoryId) { newId in
            if let newId = newId {
                // Sync categoryName so display updates immediately
                if let cat = Category.defaults.first(where: { $0.id == newId }) ?? Category.additional.first(where: { $0.id == newId }) {
                    receipt.categoryName = cat.name
                    // Also define display color/icon if we tracked them, but name is key
                }
            }
        }
        .fullScreenCover(isPresented: $showingImagePreview) {
            ImagePreviewView(dismiss: $showingImagePreview, imagePath: receipt.imageLocalPath)
        }
        .onAppear {
            uiState.isTabBarHidden = true
            updateCurrencyDisplay()
        }
        .onDisappear {
            uiState.isTabBarHidden = false
            
            // Auto-save changes when leaving the screen
            if isEditable && !wasDeleted {
                Task {
                    try? await FirestoreReceiptRepository.shared.updateReceipt(receipt)
                }
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
                    .fill(DesignSystem.Colors.surface)
                    .frame(height: 200)
                
                if let uiImage = ImageStorageService.shared.loadImage(from: receipt.imageLocalPath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .cornerRadius(16)
                        .clipped()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("image_not_found".localized)
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.7))
                    }
                }
                
                // Zoom overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: 16) {
            // UTTS Warning
            if receipt.isUTTS ?? false {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "fuelpump.fill")
                            .foregroundColor(.orange)
                        Text("utts_warning_title".localized)
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    Text("utts_warning_message".localized)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Merchant
            FormField(
                label: "merchant".localized,
                icon: "storefront",
                value: $receipt.merchantName,
                placeholder: "merchant_placeholder".localized
            )
            
            // Date & Amount Row
            HStack(spacing: 12) {
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("date".localized)
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(formatDate(receipt.displayDate))
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                }
                
                // Month Mismatch Warning
                if isDifferentMonth {
                    HStack {
                        Image(systemName: "info.circle.fill")
                        Text("different_month_warning".localized)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.top, 4)
                }
                
                // Amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("amount".localized)
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    HStack {
                        Text(userPreferences.currencySymbol)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        TextField("0,00", value: $receipt.total, format: .number)
                            .keyboardType(.decimalPad)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    .font(.system(size: 16))
                    .padding()
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                }
            }
            
            // Tax Details (VAT & Base)
            if let kdvAmount = receipt.vatAmount, kdvAmount > 0 {
                HStack(spacing: 12) {
                    // VAT Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("vat_amount_label".localized)
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack {
                            Text(userPreferences.currencySymbol)
                            Text(String(format: "%.2f", kdvAmount))
                            if let rate = receipt.vatRate {
                                Text("(%\(Int(rate)))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                    }
                    
                    // Base Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("base_amount_label".localized)
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                         
                        HStack {
                            Text(userPreferences.currencySymbol)
                            Text(String(format: "%.2f", receipt.baseAmount ?? ((receipt.total ?? 0) - kdvAmount)))
                        }
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                    }
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
                    Text("category".localized)
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    if receipt.status == .pendingReview {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("check".localized)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.warning)
                    }
                }
                
                HStack {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(receipt.displayCategoryColor)
                    
                    // Use the new displayCategoryName property for translated name
                    Text(receipt.displayCategoryName?.localized ?? "category_food".localized)
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    if isEditable {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding()
                .background(DesignSystem.Colors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
            }
        }
        .disabled(!isEditable)
    }
    
    // MARK: - Note Section
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("note_optional".localized)
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            ZStack(alignment: .topLeading) {
                if receipt.note?.isEmpty ?? true {
                    Text("note_placeholder".localized)
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                
                TextEditor(text: Binding(
                    get: { receipt.note ?? "" },
                    set: { receipt.note = $0 }
                ))
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear) // Ensure transparency
                .frame(minHeight: 100)
            }
            .padding(12)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
    
    
    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        HStack(spacing: 12) {
            // Processing: No buttons
            if receipt.status == .processing {
                EmptyView()
            }
            // New or Pending Review: Reject and Approve
            else if receipt.status == .new || receipt.status == .pendingReview {
                Button(action: {
                    Task {
                        do {
                            wasDeleted = true
                            try await FirestoreReceiptRepository.shared.deleteReceipt(receipt)
                            await MainActor.run {
                                dismiss()
                            }
                        } catch {
                            wasDeleted = false
                            print("❌ Deletion failed: \(error.localizedDescription)")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("reject".localized)
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
                        Text("approve".localized)
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
                        .init(color: DesignSystem.Colors.background.opacity(0), location: 0),
                        .init(color: DesignSystem.Colors.background, location: 0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                DesignSystem.Colors.background
            }
            .ignoresSafeArea()
        )
    }
    
    // MARK: - Helpers
    // MARK: - Helpers
    private func saveAndDismiss() {
        Task {
            do {
                // If the user saves, we commit to the CURRENT currency settings.
                // This means the receipt's currency becomes the user's selected reference currency.
                var editingReceipt = self.receipt
                editingReceipt.currency = userPreferences.currencyCode
                try await FirestoreReceiptRepository.shared.updateReceipt(editingReceipt)
                
                dismiss()
            } catch {
                print("❌ Update failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = userPreferences.locale
        return formatter.string(from: date)
    }
    
    private var isDifferentMonth: Bool {
        let calendar = Calendar.current
        let today = Date()
        let rDate = receipt.displayDate
        
        let rMonth = calendar.component(.month, from: rDate)
        let rYear = calendar.component(.year, from: rDate)
        let cMonth = calendar.component(.month, from: today)
        let cYear = calendar.component(.year, from: today)
        
        return rMonth != cMonth || rYear != cYear
    }
    
    // Logic to convert initial value
    private func updateCurrencyDisplay() {
        // If receipt currency is different from user preference, convert it for display/edit
        // But only if we haven't edited it yet (or just opened).
        let targetCurrency = userPreferences.currencyCode
        let originalCurrency = receipt.currency ?? "TRY"
        
        // If they match, no conversion needed
        if targetCurrency == originalCurrency { return }
        
        // Otherwise, convert the receipts total to the targets
        if let total = receipt.total {
             let converted = CurrencyService.shared.convert(total, from: originalCurrency, to: targetCurrency)
             // We update the local state 'receipt' to reflect this converted value
             // So the TextField shows the converted value.
             // When saved, it saves this new value + new currency code.
             receipt.total = Double(truncating: NSNumber(value: converted))
             receipt.currency = targetCurrency // Temporarily update local state
        }
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
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack {
                TextField(placeholder, text: Binding(
                    get: { value ?? "" },
                    set: { value = $0 }
                ))
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Image Preview
struct ImagePreviewView: View {
    @Binding var dismiss: Bool
    let imagePath: String
    
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
                
                if let uiImage = ImageStorageService.shared.loadImage(from: imagePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 120))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("image_not_found".localized)
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReceiptDetailView(
            receipt: Receipt(
                id: "preview_detail",
                status: .new,
                imageLocalPath: "",
                merchantName: "Detail Store",
                date: Date(),
                total: 89.50,
                currency: "USD",
                categoryName: "category_food",
                source: .camera
            ),
            viewModel: InboxViewModel()
        )
    }
    .environmentObject(AppUserPreferences.shared)
    .environmentObject(LocalizationManager.shared)
}
