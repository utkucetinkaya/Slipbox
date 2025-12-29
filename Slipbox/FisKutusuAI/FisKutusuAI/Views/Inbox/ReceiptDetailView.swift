import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ReceiptDetailView: View {
    let receipt: Receipt
    @State private var editedReceipt: Receipt
    @State private var showingCategoryPicker = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    init(receipt: Receipt) {
        self.receipt = receipt
        _editedReceipt = State(initialValue: receipt)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) { // AppSpacing.lg
                // Receipt Image
                receiptImage
                
                // Status Card
                statusCard
                
                // Editable Fields
                editableFields
                
                // Category Selection
                categorySection
                
                // Notes
                notesSection
                
                // Actions
                actionsSection
            }
            .padding(16) // AppSpacing.md
        }
        .navigationTitle("Fiş Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Kaydet") {
                    saveReceipt()
                }
                .disabled(!hasChanges)
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            NavigationStack {
                CategoryPickerView(selectedCategoryId: $editedReceipt.categoryId)
                    .navigationTitle("Kategori Seç")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Bitti") {
                                showingCategoryPicker = false
                            }
                        }
                    }
            }
        }
        .alert("Fişi Sil", isPresented: $showingDeleteConfirmation) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                deleteReceipt()
            }
        } message: {
            Text("Bu fişi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.")
        }
    }
    
    // MARK: - Receipt Image
    private var receiptImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12) // AppCornerRadius.md
                .fill(Color.gray.opacity(0.2))
                .frame(height: 300)
            
            if let uiImage = LocalImageManager.shared.getImage(filename: receipt.imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12) // AppCornerRadius.md
            } else {
                VStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    Text("Görüntü bulunamadı")
                        .font(.caption) // AppFonts.caption
                        .foregroundColor(.gray)
                }
            }
            
            // Pinch-to-zoom placeholder (removed for simplicity in v1)
        }
    }
    
    // MARK: - Status Card
    private var statusCard: some View {
        HStack {
            statusIcon
            
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.headline) // AppFonts.headline
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(statusMessage)
                    .font(.caption) // AppFonts.caption
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            if receipt.status == .needsReview {
                Button(action: approveReceipt) {
                    Text("Onayla")
                        .font(.callout) // AppFonts.callout
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16) // AppSpacing.md
                        .padding(.vertical, 4) // AppSpacing.xs
                        .background(DesignSystem.Colors.success)
                        .cornerRadius(8) // AppCornerRadius.sm
                }
            }
        }
        .padding(16) // AppSpacing.md
        .background(statusBackgroundColor)
        .cornerRadius(12) // AppCornerRadius.md
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
    
    private var statusIcon: some View {
        Group {
            switch receipt.status {
            case .processing:
                ProgressView()
            case .needsReview:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.warning)
            case .approved:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.success)
            case .error:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.error)
            }
        }
        .font(.title2)
    }
    
    private var statusTitle: String {
        switch receipt.status {
        case .processing: return "İşleniyor"
        case .needsReview: return "Onay Bekliyor"
        case .approved: return "Onaylandı"
        case .error: return "Hata"
        }
    }
    
    private var statusMessage: String {
        switch receipt.status {
        case .processing: return "Fiş otomatik olarak işleniyor..."
        case .needsReview:
            if let confidence = receipt.confidence {
                return "Emin değilim (\(Int(confidence * 100))%). Lütfen kontrol edin."
            }
            return "Lütfen bilgileri kontrol edin"
        case .approved: return "Bu fiş onaylandı ve kullanıma hazır"
        case .error: return receipt.error ?? "İşlenirken bir hata oluştu"
        }
    }
    
    private var statusBackgroundColor: Color {
        switch receipt.status {
        case .processing: return Color.blue.opacity(0.1) // AppColors.statusProcessing fallback
        case .needsReview: return DesignSystem.Colors.warning.opacity(0.1)
        case .approved: return DesignSystem.Colors.success.opacity(0.1)
        case .error: return DesignSystem.Colors.error.opacity(0.1)
        }
    }
    
    // MARK: - Editable Fields
    private var editableFields: some View {
        VStack(alignment: .leading, spacing: 16) { // AppSpacing.md
            // Merchant
            VStack(alignment: .leading, spacing: 4) {
                Text("İşletme")
                    .font(.caption) // AppFonts.caption
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                TextField("Örn: Migros", text: Binding(
                    get: { editedReceipt.merchant ?? "" },
                    set: { editedReceipt.merchant = $0.isEmpty ? nil : $0 }
                ))
                .font(.body) // AppFonts.body
                .textFieldStyle(.roundedBorder)
            }
            
            // Date & Amount
            HStack(spacing: 16) { // AppSpacing.md
                // Date
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tarih")
                        .font(.caption) // AppFonts.caption
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    DatePicker("", selection: Binding(
                        get: { editedReceipt.date ?? Date() },
                        set: { editedReceipt.date = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
                
                // Amount
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tutar")
                        .font(.caption) // AppFonts.caption
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    TextField("0.00", value: Binding(
                        get: { editedReceipt.total ?? 0 },
                        set: { editedReceipt.total = $0 }
                    ), format: .number)
                    .font(.body) // AppFonts.body
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) { // AppSpacing.sm
            Text("Kategori")
                .font(.caption) // AppFonts.caption
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Button(action: { showingCategoryPicker = true }) {
                HStack {
                    if let categoryId = editedReceipt.categoryId,
                       let category = Category.defaults.first(where: { $0.id == categoryId }) {
                        Image(systemName: category.icon)
                        Text(category.name)
                            .font(.body) // AppFonts.body
                    } else if let suggestedId = editedReceipt.categorySuggestedId,
                              let category = Category.defaults.first(where: { $0.id == suggestedId }) {
                        Image(systemName: category.icon)
                        Text("\(category.name) (Önerilen)")
                            .font(.body) // AppFonts.body
                            .foregroundColor(DesignSystem.Colors.warning)
                    } else {
                        Text("Kategori Seç")
                            .font(.body) // AppFonts.body
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding()
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(8) // AppCornerRadius.sm
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notlar")
                .font(.caption) // AppFonts.caption
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextEditor(text: Binding(
                get: { editedReceipt.notes ?? "" },
                set: { editedReceipt.notes = $0.isEmpty ? nil : $0 }
            ))
            .font(.body) // AppFonts.body
            .frame(height: 100)
            .padding(8)
            .scrollContentBackground(.hidden) // Fix for TextEditor background
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(8) // AppCornerRadius.sm
             .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Actions
    private var actionsSection: some View {
        VStack(spacing: 8) { // AppSpacing.sm
            if receipt.status != .approved {
                Button(action: approveReceipt) {
                    Text("Onayla ve Kaydet")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(DesignSystem.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12) // AppCornerRadius.md
                }
            }
            
            Button(action: { showingDeleteConfirmation = true }) {
                Text("Fişi Sil")
                    .font(.headline) // AppFonts.headline
                    .foregroundColor(DesignSystem.Colors.error)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.error.opacity(0.1))
                    .cornerRadius(12) // AppCornerRadius.md
            }
        }
        .padding(.top, 16) // AppSpacing.md
    }
    
    // MARK: - Computed
    private var hasChanges: Bool {
        editedReceipt.merchant != receipt.merchant ||
        editedReceipt.date != receipt.date ||
        editedReceipt.total != receipt.total ||
        editedReceipt.categoryId != receipt.categoryId ||
        editedReceipt.notes != receipt.notes
    }
    
    // MARK: - Actions
    private func saveReceipt() {
        Task {
            do {
                try await FirestoreReceiptRepository.shared.saveReceipt(editedReceipt)
                dismiss()
            } catch {
                print("Error saving receipt: \(error)")
            }
        }
    }
    
    private func approveReceipt() {
        var approved = editedReceipt
        approved.status = .approved
        
        Task {
            do {
                try await FirestoreReceiptRepository.shared.saveReceipt(approved)
                dismiss()
            } catch {
                print("Error approving receipt: \(error)")
            }
        }
    }
    
    private func deleteReceipt() {
        Task {
            do {
                // Delete local image
                LocalImageManager.shared.deleteImage(filename: receipt.imagePath)
                
                // Delete metadata from Firestore
                try await FirestoreReceiptRepository.shared.deleteReceipt(id: receipt.id ?? "")
                dismiss()
            } catch {
                print("Error deleting receipt: \(error)")
            }
        }
    }
}
