import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) var dismiss
    @State private var deleteConfirmationText = ""
    @State private var showingFinalAlert = false
    
    var isDeleteEnabled: Bool {
        deleteConfirmationText == "DELETE"
    }
    
    var body: some View {
        ZStack {
            Color(hex: "050511")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Warning Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "FF3B30").opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .stroke(Color(hex: "FF3B30").opacity(0.3), lineWidth: 1)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "FF3B30"))
                }
                .padding(.top, 40)
                
                // Warning Text
                VStack(spacing: 12) {
                    Text("Hesabını silmek üzeresin")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Bu işlem geri alınamaz. Tüm makbuzların ve verilerin kalıcı olarak silinecektir.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        // Simple highlighting workaround without AttributedString complexity for now
                        .overlay(
                            Text("kalıcı olarak")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "FF3B30"))
                                .offset(x: 24, y: 9) // Approximate position, keeping it simple for SwiftUI string interpolation limitations in older versions. 
                                // Actually, let's just use standard text for safety as AttributedString is iOS 15+.
                                // Better approach: split text or simply bold the whole thing in different color if needed.
                                // For this prompt, I will stick to single color for simplicity or AttributedString if iOS 17 target.
                                .opacity(0) // Hiding this overlay hack, using standard text below.
                        )
                }
                
                // Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Onaylamak için 'DELETE' yazın")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white.opacity(0.3))
                        
                        TextField("", text: $deleteConfirmationText)
                            .foregroundColor(.white)
                            .textInputAutocapitalization(.characters)
                            .accentColor(Color(hex: "FF3B30"))
                            .overlay(
                                Text("DELETE")
                                    .foregroundColor(.white.opacity(0.2))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .opacity(deleteConfirmationText.isEmpty ? 1 : 0)
                                , alignment: .leading
                            )
                    }
                    .padding()
                    .background(Color(hex: "1C1C1E"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "FF3B30").opacity(deleteConfirmationText == "DELETE" ? 1 : 0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: {
                        showingFinalAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Sil")
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isDeleteEnabled ? Color(hex: "FF3B30") : Color(hex: "2C2C2E"))
                        .cornerRadius(28)
                    }
                    .disabled(!isDeleteEnabled)
                    .opacity(isDeleteEnabled ? 1 : 0.5)
                    
                    Button("İptal") {
                        dismiss()
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Hesabı Sil")
        .alert("Hesabını silmek istediğine emin misin?", isPresented: $showingFinalAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                print("🔥 Account deleted!")
                // Logic to navigate to onboarding would go here
            }
        } message: {
            Text("Son kez soruyoruz. Bu işlem geri alınamaz.")
        }
    }
}

#Preview {
    NavigationStack {
        DeleteAccountView()
    }
}
