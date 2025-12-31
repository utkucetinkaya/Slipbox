import SwiftUI
import FirebaseFirestore

struct ProcessingView: View {
    let image: UIImage
    var onReturnToInbox: () -> Void
    
    @State private var scanOffset: CGFloat = -150
    @State private var isCompleted = false
    @State private var extractedMerchant: String?
    @State private var extractedDate: String?
    @State private var extractedTotal: String?
    
    // Auto-save logic
    @EnvironmentObject var inboxViewModel: InboxViewModel
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A14").ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Text("processing_title".localized)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onReturnToInbox) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                Spacer()
                
                // Scanner Animation Container
                ZStack {
                    // Image Preview with blur
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 220, height: 320)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .overlay(Color.black.opacity(0.2))
                    
                    // Scanning line
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "4F46E5").opacity(0), Color(hex: "4F46E5"), Color(hex: "4F46E5").opacity(0)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: 260, height: 4)
                        .shadow(color: Color(hex: "4F46E5"), radius: 10)
                        .offset(y: scanOffset)
                        .onAppear {
                            withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: true)) {
                                scanOffset = 150
                            }
                        }
                }
                .padding(.bottom, 40)
                
                // Status Text
                Text(isCompleted ? "processing_completed".localized : "processing_in_progress".localized)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                Text("processing_description".localized)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)
                
                // Extraction Placeholders
                VStack(spacing: 12) {
                    ExtractionRow(icon: "storefront.fill", label: "merchant".localized, value: extractedMerchant)
                    ExtractionRow(icon: "calendar", label: "date".localized, value: extractedDate)
                    ExtractionRow(icon: "doc.text.fill", label: "amount".localized, value: extractedTotal)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Action Button
                Button(action: onReturnToInbox) {
                    Text("return_to_inbox".localized)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "4F46E5"))
                        .cornerRadius(28)
                }
                .padding(24)
            }
        }
        .onAppear {
            startProcessing()
        }
    }
    
    private func startProcessing() {
        Task {
            do {
                // 1. Save Image Locally
                let fileName = UUID().uuidString
                let localPath = try ImageStorageService.shared.saveImage(image, fileName: fileName)
                
                // 2. Run OCR
                let ocrResult = try await OCRService.shared.recognizeText(in: image)
                
                await MainActor.run {
                    withAnimation {
                        extractedMerchant = ocrResult.merchantName
                        extractedDate = ocrResult.date?.formatted(date: .abbreviated, time: .omitted)
                        extractedTotal = ocrResult.total != nil ? "\(ocrResult.total!)" : nil
                    }
                }
                
                // 3. Categorization (Keyword based)
                let catResult = CategorizationService.shared.categorize(merchantName: ocrResult.merchantName, rawText: ocrResult.rawText)
                
                // 4. Determine Status
                // All receipts now land in 'new' initially for easy access in the 'Recent' tab
                let initialStatus: ReceiptStatus = .new
                
                // Fetch category name if found
                var categoryName: String? = nil
                if catResult.categoryId != "other" {
                    categoryName = Category.defaults.first(where: { $0.id == catResult.categoryId })?.name 
                        ?? Category.additional.first(where: { $0.id == catResult.categoryId })?.name
                }
                
                let receipt = Receipt(
                    id: nil,
                    status: initialStatus,
                    imageLocalPath: localPath,
                    rawText: ocrResult.rawText,
                    merchantName: ocrResult.merchantName,
                    date: ocrResult.date,
                    total: ocrResult.total,
                    currency: AppUserPreferences.shared.currencyCode,
                    categoryId: catResult.categoryId,
                    categoryName: categoryName,
                    confidence: catResult.confidence,
                    note: nil,
                    source: .camera,
                    createdAt: nil,
                    updatedAt: nil,
                    error: nil
                )
                
                // 4. Save to Firestore
                try await FirestoreReceiptRepository.shared.addReceipt(receipt)
                
                await MainActor.run {
                    withAnimation {
                        isCompleted = true
                    }
                }
            } catch {
                print("❌ Processing failed: \(error.localizedDescription)")
            }
        }
    }
}

struct ExtractionRow: View {
    let icon: String
    let label: String
    let value: String?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "4F46E5"))
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .transition(.opacity)
            } else {
                // Skeleton Loader
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 12)
            }
        }
        .padding()
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(16)
    }
}

#Preview {
    ProcessingView(image: UIImage(), onReturnToInbox: {})
}
