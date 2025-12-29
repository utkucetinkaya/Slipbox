import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var fullName = "Kerem Yılmaz"
    @State private var email = "kerem.yilmaz@slipbox.app"
    @State private var phone = "+90 555 123 45 67"
    
    var body: some View {
        ZStack {
            Color(hex: "050511")
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Avatar Edit
                VStack(spacing: 16) {
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color(hex: "FFCC00").opacity(0.2)) // Placeholder avatar color
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill") // Placeholder image
                                    .font(.system(size: 60))
                                    .foregroundColor(Color(hex: "FFCC00"))
                            )
                        
                        Circle()
                            .fill(Color(hex: "4F46E5"))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "050511"), lineWidth: 4)
                            )
                    }
                    
                    Button("Fotoğrafı Değiştir") {
                        // Stub for photo picker
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "4F46E5"))
                }
                .padding(.top, 20)
                
                // Form Fields
                VStack(spacing: 20) {
                    ProfileField(label: "Ad Soyad", text: $fullName)
                    
                    ProfileField(label: "E-posta", text: $email, isLocked: true)
                    
                    ProfileField(label: "Telefon", text: $phone)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    print("💾 Profile saved: \(fullName), \(phone)")
                    dismiss()
                }) {
                    Text("Kaydet")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "4F46E5"))
                        .cornerRadius(28)
                        .shadow(color: Color(hex: "4F46E5").opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Profili Düzenle")
    }
}

struct ProfileField: View {
    let label: String
    @Binding var text: String
    var isLocked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            HStack {
                TextField("", text: $text)
                    .foregroundColor(isLocked ? .white.opacity(0.5) : .white)
                    .disabled(isLocked)
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding()
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
    }
}
