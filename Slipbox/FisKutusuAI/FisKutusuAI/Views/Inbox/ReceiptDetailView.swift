import SwiftUI

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
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
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
            .padding(AppSpacing.md)
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
            NavigationView {
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
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 300)
            
            if let uiImage = LocalImageManager.shared.getImage(filename: receipt.imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(AppCornerRadius.md)
            } else {
                VStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    Text("Görüntü bulunamadı")
                        .font(AppFonts.caption())
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
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                
                Text(statusMessage)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            if receipt.status == .needsReview {
                Button(action: approveReceipt) {
                    Text("Onayla")
                        .font(AppFonts.callout())
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.success)
                        .cornerRadius(AppCornerRadius.sm)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(statusBackgroundColor)
        .cornerRadius(AppCornerRadius.md)
    }
    
    private var statusIcon: some View {
        Group {
            switch receipt.status {
            case .processing:
                ProgressView()
            case .needsReview:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(AppColors.warning)
            case .approved:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.success)
            case .error:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.error)
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
        case .processing: return AppColors.statusProcessing.opacity(0.1)
        case .needsReview: return AppColors.warning.opacity(0.1)
        case .approved: return AppColors.success.opacity(0.1)
        case .error: return AppColors.error.opacity(0.1)
        }
    }
    
    // MARK: - Editable Fields
    private var editableFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Merchant
            VStack(alignment: .leading, spacing: 4) {
                Text("İşletme")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Örn: Migros", text: Binding(
                    get: { editedReceipt.merchant ?? "" },
                    set: { editedReceipt.merchant = $0.isEmpty ? nil : $0 }
                ))
                .font(AppFonts.body())
                .textFieldStyle(.roundedBorder)
            }
            
            // Date & Amount
            HStack(spacing: AppSpacing.md) {
                // Date
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tarih")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                    
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
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("0.00", value: Binding(
                        get: { editedReceipt.total ?? 0 },
                        set: { editedReceipt.total = $0 }
                    ), format: .number)
                    .font(AppFonts.body())
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Kategori")
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textSecondary)
            
            Button(action: { showingCategoryPicker = true }) {
                HStack {
                    if let categoryId = editedReceipt.categoryId,
                       let category = Category.defaults.first(where: { $0.id == categoryId }) {
                        Image(systemName: category.icon)
                        Text(category.name)
                            .font(AppFonts.body())
                    } else if let suggestedId = editedReceipt.categorySuggestedId,
                              let category = Category.defaults.first(where: { $0.id == suggestedId }) {
                        Image(systemName: category.icon)
                        Text("\(category.name) (Önerilen)")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.warning)
                    } else {
                        Text("Kategori Seç")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(AppCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notlar")
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textSecondary)
            
            TextEditor(text: Binding(
                get: { editedReceipt.notes ?? "" },
                set: { editedReceipt.notes = $0.isEmpty ? nil : $0 }
            ))
            .font(AppFonts.body())
            .frame(height: 100)
            .padding(8)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.sm)
        }
    }
    
    // MARK: - Actions
    private var actionsSection: some View {
        VStack(spacing: AppSpacing.sm) {
            if receipt.status != .approved {
                Button(action: approveReceipt) {
                    Text("Onayla ve Kaydet")
                        .primaryButton()
                }
            }
            
            Button(action: { showingDeleteConfirmation = true }) {
                Text("Fişi Sil")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.error)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.error.opacity(0.1))
                    .cornerRadius(AppCornerRadius.md)
            }
        }
        .padding(.top, AppSpacing.md)
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

// MARK: - Preview
#Preview {
    NavigationView {
        ReceiptDetailView(receipt: MockData.sampleReceipts[1])
    }
}
