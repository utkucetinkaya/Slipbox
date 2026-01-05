import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedbackText: String = ""
    @State private var isSending = false
    @State private var showSentAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("feedback_intro".localized) // "Geri bildiriminiz bizim için değerli..."
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    ZStack(alignment: .topLeading) {
                        if feedbackText.isEmpty {
                            Text("feedback_placeholder".localized) // "Düşüncelerinizi buraya yazın..."
                                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
                                .padding(12)
                        }
                        
                        TextEditor(text: $feedbackText)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(8)
                    }
                    .background(DesignSystem.Colors.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                    .frame(height: 200)
                    .padding(.horizontal)
                    
                    Button(action: sendFeedback) {
                        HStack {
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("send".localized) // "Gönder"
                                    .fontWeight(.semibold)
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(feedbackText.isEmpty ? Color.gray : DesignSystem.Colors.primary)
                        .cornerRadius(12)
                    }
                    .disabled(feedbackText.isEmpty || isSending)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("send_feedback".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) {
                        dismiss()
                    }
                }
            }
            .alert("thank_you".localized, isPresented: $showSentAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("feedback_sent_message".localized)
            }
        }
    }
    
    private func sendFeedback() {
        isSending = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSending = false
            showSentAlert = true
            print("Feedback sent: \(feedbackText)")
        }
    }
}
