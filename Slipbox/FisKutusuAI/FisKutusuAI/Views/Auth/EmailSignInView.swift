import SwiftUI

struct EmailSignInView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isPasswordVisible = false
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Text(isSignUp ? "Hesap Oluştur" : "Tekrar Hoş Geldiniz")
                            .font(.system(size: 28, weight: .bold)) // Title1 equivalent
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(isSignUp ? "SlipBox ile fişlerini yönetmeye başla." : "SlipBox hesabınıza giriş yaparak\nfişlerinizi yönetmeye devam edin.")
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 24) {
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("E-posta Adresi")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                TextField("kullanici@slipbox.app", text: $email)
                                    .textContentType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                if !email.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(isValidEmail(email) ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                                }
                            }
                            .padding()
                            .background(DesignSystem.Colors.inputBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Şifre")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                if isPasswordVisible {
                                    TextField("••••••", text: $password)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                } else {
                                    SecureField("••••••", text: $password)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                }
                                
                                Button(action: { isPasswordVisible.toggle() }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                            .padding()
                            .background(DesignSystem.Colors.inputBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                            
                            if isSignUp && !password.isEmpty && password.count < 6 {
                                Text("Şifre en az 6 karakter olmalı.")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.error)
                            }
                        }
                    }
                    
                    // Error Message
                    if let error = authManager.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundColor(DesignSystem.Colors.error)
                    }
                    
                    // Submit Button
                    if authManager.isLoading {
                        ProgressView()
                            .tint(DesignSystem.Colors.primary)
                    } else {
                        DesignSystem.Buttons.primary(
                            title: isSignUp ? "Kayıt Ol" : "Giriş Yap",
                            icon: isSignUp ? "person.badge.plus" : "arrow.right"
                        ) {
                            handleSubmit()
                        }
                        .disabled(email.isEmpty || password.count < 6)
                        .opacity((email.isEmpty || password.count < 6) ? 0.6 : 1.0)
                    }
                    
                    // Switch & Forgot Password
                    VStack(spacing: 16) {
                        if !isSignUp {
                            // Forgot Password removed as per request
                        }
                        
                        HStack {
                            Rectangle()
                                .fill(DesignSystem.Colors.border)
                                .frame(height: 1)
                            Text("VEYA")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Rectangle()
                                .fill(DesignSystem.Colors.border)
                                .frame(height: 1)
                        }
                        
                        Button(action: {
                            withAnimation {
                                isSignUp.toggle()
                                authManager.errorMessage = nil
                            }
                        }) {
                            Text(isSignUp ? "Zaten hesabın var mı? Giriş Yap" : "Hesabın yok mu? Kayıt Ol")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(DesignSystem.Colors.inputBackground)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(24)
            }
            
            // Custom Back Button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(DesignSystem.Colors.surface)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                    }
                    .padding(.leading, 20)
                    .padding(.top, 10) // Safe area padding
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func handleSubmit() {
        Task {
            if isSignUp {
                _ = try? await authManager.signUpWithEmail(email: email, password: password)
                LaunchManager.shared.checkState()
            } else {
                _ = try? await authManager.signInWithEmail(email: email, password: password)
                LaunchManager.shared.checkState()
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // Basic validation
        email.contains("@") && email.contains(".")
    }
}
