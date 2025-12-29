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
                    Text("Processing")
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
                Text(isCompleted ? "İşlem Tamamlandı" : "Fiş işleniyor...")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                Text("We are extracting details from your scan. You can leave this screen.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)
                
                // Extraction Placeholders
                VStack(spacing: 12) {
                    ExtractionRow(icon: "storefront.fill", label: "Merchant", value: extractedMerchant)
                    ExtractionRow(icon: "calendar", label: "Date", value: extractedDate)
                    ExtractionRow(icon: "doc.text.fill", label: "Total", value: extractedTotal)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Action Button
                Button(action: onReturnToInbox) {
                    Text("Inbox'a dön")
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
            startMockProcessing()
        }
    }
    
    private func startMockProcessing() {
        // Step 1: Merchant found
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { extractedMerchant = "Starbucks" }
        }
        
        // Step 2: Date found
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { extractedDate = "14 Ekim 2023" }
        }
        
        // Step 3: Total found & Completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation {
                extractedTotal = "₺145.50"
                isCompleted = true
            }
            saveMockReceipt()
        }
    }
    
    private func saveMockReceipt() {
        // Create a new receipt and inject into InboxViewModel (mock)
        // ideally we pass the ID to the scanner or have a robust data layer.
        // For this UI demo, we rely on the Inbox's existing simulator/mock data logic to "show" it
        // Or we can post a notification.
        // Let's create a real Mock object and post it.
        
        let newReceipt = Receipt(
            id: UUID().uuidString,
            status: .needsReview,
            imagePath: "", // Mock
            rawText: "Mock Text",
            merchant: "Starbucks",
            date: Date(),
            total: 145.50,
            currency: "TRY",
            categoryId: "food",
            confidence: 0.85,
            notes: nil,
            source: .camera,
            createdAt: Timestamp(date: Date()),
            updatedAt: Timestamp(date: Date())
        )
        
        // In a real app we'd save to DB.
        // Here we can just assume Inbox will fetch it or we simulate it.
        // InboxViewModel.shared.add(newReceipt) - stub
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
