import SwiftUI
import VisionKit
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingDocumentCamera = false
    @State private var showingPhotoPicker = false
    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = capturedImage {
                    // Show captured image
                    capturedImageView(image)
                } else {
                    // Show instructions
                    instructionsView
                }
            }
            .navigationTitle("Fiş Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingDocumentCamera) {
                #if targetEnvironment(simulator)
                // Simulator: Document camera not supported. Use gallery picker instead.
                PhotoPickerView(selectedImage: $capturedImage)
                #else
                // Real device: Use VNDocumentCameraViewController
                DocumentCameraView(image: $capturedImage, isShowing: $showingDocumentCamera)
                #endif
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(selectedImage: $capturedImage)
            }
            .onAppear {
                #if targetEnvironment(simulator)
                showingPhotoPicker = true
                #else
                showingDocumentCamera = true
                #endif
            }
        }
        .overlay(alignment: .bottom) {
            errorAlert
        }
    }
    
    // MARK: - Instructions View
    private var instructionsView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Fişi Tara")
                .font(AppFonts.title())
                .foregroundColor(.white)
            
            Text(simulatorInstructions)
                .font(AppFonts.body())
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            
            Button(action: {
                #if targetEnvironment(simulator)
                showingPhotoPicker = true
                #else
                showingDocumentCamera = true
                #endif
            }) {
                Text("Fotoğraf Seç")
                    .primaryButton()
            }
            .padding(.horizontal, AppSpacing.xl)
            
            Spacer()
        }
    }
    
    private var simulatorInstructions: String {
        #if targetEnvironment(simulator)
        return "Simulator'da galeriden fotoğraf seçebilirsiniz"
        #else
        return "Fişi kamera çerçevesine yerleştirin"
        #endif
    }
    
    // MARK: - Captured Image View
    private func capturedImageView(_ image: UIImage) -> some View {
        VStack(spacing: 0) {
            // Image preview
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Actions
            HStack(spacing: AppSpacing.md) {
                Button(action: { capturedImage = nil }) {
                    Text("Tekrar Çek")
                        .secondaryButton()
                }
                
                Button(action: processReceipt) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Kullan")
                            .primaryButton()
                    }
                }
                .disabled(isProcessing)
            }
            .padding(AppSpacing.md)
            .background(Color.black.opacity(0.8))
        }
    }
    
    // MARK: - Process Receipt (On-Device / Spark-First)
    private func processReceipt() {
        guard let image = capturedImage,
              let uid = Auth.auth().currentUser?.uid else { return }
        
        isProcessing = true
        
        Task {
            do {
                // 1. Check Free tier limit (Local check or removed for v1)
                // For v1, we skip strict server-side enforcement. 
                // We can add local check here if needed later.
                
                // 2. Extract text using OCR (On-Device)
                let rawText = try await OCRService.shared.recognizeText(from: image)
                
                // 3. Parse Data (On-Device)
                let parsedData = OCRService.shared.parseReceiptData(from: rawText)
                
                // 4. Suggest Category (On-Device)
                let suggestedCategory = CategoryService.shared.suggestCategory(
                    merchant: parsedData.merchant, 
                    rawText: rawText
                )
                
                // 5. Create receipt ID
                let receiptId = UUID().uuidString
                
                // 6. Save Image Locally
                let localFilename = try LocalImageManager.shared.saveImage(image: image, id: receiptId)
                
                // 7. Create Receipt Object
                // Note: We use confidence 1.0 since user manually took the photo, but 
                // if parsing is weak we might set it lower. For now assume user review needed if fields missing.
                let status: ReceiptStatus = (parsedData.total != nil && parsedData.merchant != nil) ? .approved : .needsReview
                
                let receipt = Receipt(
                    id: receiptId,
                    status: status,
                    imagePath: localFilename, // Changed semantics: now local filename
                    rawText: rawText.count > 4000 ? String(rawText.prefix(4000)) : rawText, // Limit size
                    merchant: parsedData.merchant,
                    date: parsedData.date ?? Date(),
                    total: parsedData.total,
                    currency: parsedData.currency,
                    categoryId: suggestedCategory, // Pre-fill category
                    categorySuggestedId: suggestedCategory,
                    confidence: 0.9,
                    notes: nil,
                    source: .camera,
                    createdAt: Timestamp(date: Date()),
                    updatedAt: Timestamp(date: Date()),
                    error: nil
                )
                
                // 8. Save Metadata to Firestore
                try await FirestoreReceiptRepository.shared.saveReceipt(receipt)
                
                // Done!
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error processing receipt: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
    
    // MARK: - Error Handling
    @State private var errorMessage: String?
    
    private var errorAlert: some View {
        Group {
            if let message = errorMessage {
                Text(message)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.error)
                    .padding(AppSpacing.sm)
                    .background(AppColors.error.opacity(0.1))
                    .cornerRadius(AppCornerRadius.sm)
                    .padding(.horizontal, AppSpacing.md)
            }
        }
    }
}

// MARK: - Document Camera View (Real Device Only)
#if !targetEnvironment(simulator)
struct DocumentCameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isShowing: Bool
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentCameraView
        
        init(_ parent: DocumentCameraView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            if scan.pageCount > 0 {
                parent.image = scan.imageOfPage(at: 0)
            }
            parent.isShowing = false
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isShowing = false
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document camera error: \(error)")
            parent.isShowing = false
        }
    }
}
#endif

// MARK: - Photo Picker View (Simulator)
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CameraCaptureView()
}
