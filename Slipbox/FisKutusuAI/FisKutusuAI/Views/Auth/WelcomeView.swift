import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showEmailSignIn = false
    @State private var showError = false
    @State private var appleSignInCoordinator = AppleSignInCoordinator()
    
    // Custom Colors
    private let darkBackground = Color(red: 5/255, green: 5/255, blue: 17/255) // #050511
    private let primaryPurple = Color(red: 79/255, green: 70/255, blue: 229/255) // #4F46E5
    private let cardBackground = Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.1)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                darkBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Header: Logo
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass") // Fallback icon
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(primaryPurple)
                            .clipShape(Circle())
                        
                        Text("SlipBox")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Hero Image
                    // Using the generated 3D image. Assuming the user adds it to Assets as "WelcomeHero".
                    // Fallback to a placeholder system image if not found.
                    if let uiImage = UIImage(named: "WelcomeHero") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 350)
                            .shadow(color: primaryPurple.opacity(0.3), radius: 30, x: 0, y: 10)
                    } else {
                        // Fallback View if image isn't added yet
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(LinearGradient(colors: [primaryPurple.opacity(0.4), darkBackground], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 280, height: 320)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            VStack(spacing: 20) {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 30, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 120, height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 100, height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 140, height: 8)
                            }
                        }
                        .frame(height: 350)
                    }
                    
                    Spacer()
                    
                    // Headlines
                    VStack(spacing: 12) {
                        Text("Fişlerini saniyeler\niçinde düzene sok.")
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .lineSpacing(4)
                        
                        Text("Tarayın. Kategorileyin. Raporlayın.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    
                    // Buttons
                    VStack(spacing: 16) {
                        // Custom Apple Sign In Button
                        Button(action: startAppleSignIn) {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 20))
                                Text("Apple ile Devam Et")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(primaryPurple)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                        }
                        
                        // Email Sign In Button
                        Button(action: { showEmailSignIn = true }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 18))
                                Text("E-posta ile Devam Et")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(darkBackground) // Transparent/Dark
                            .foregroundColor(.white)
                            .cornerRadius(30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    
                    // Footer
                    HStack(spacing: 16) {
                        Link("Gizlilik", destination: URL(string: "https://yoursite.com/privacy")!)
                        Circle().frame(width: 2, height: 2).foregroundColor(.gray)
                        Link("Kullanım Şartları", destination: URL(string: "https://yoursite.com/terms")!)
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 24)
                }
            }
            .sheet(isPresented: $showEmailSignIn) {
                EmailSignInView()
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                if let error = authManager.errorMessage {
                    Text(error)
                }
            }
            .onAppear {
                appleSignInCoordinator.onSuccess = { credential in
                    Task {
                        do {
                            try await authManager.signInWithApple(credential: credential)
                        } catch {
                            authManager.errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                
                appleSignInCoordinator.onError = { error in
                    authManager.errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func startAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = appleSignInCoordinator
        controller.presentationContextProvider = appleSignInCoordinator
        controller.performRequests()
    }
}

// MARK: - Apple Sign In Coordinator
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    var onSuccess: ((ASAuthorizationAppleIDCredential) -> Void)?
    var onError: ((Error) -> Void)?
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .flatMap { $0 }?
            .windows
            .first { $0.isKeyWindow } ?? UIWindow()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            onSuccess?(appleIDCredential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Ignore user cancellation
        let nsError = error as NSError
        if nsError.code != ASAuthorizationError.canceled.rawValue {
            onError?(error)
        }
    }
}

// MARK: - Email Sign In Sheet (Reused & Styled)
struct EmailSignInView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let darkBackground = Color(red: 20/255, green: 20/255, blue: 35/255)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 5/255, green: 5/255, blue: 17/255).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    Text(isSignUp ? "Hesap Oluştur" : "Giriş Yap")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    VStack(spacing: 16) {
                        TextField("E-posta", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        SecureField("Şifre", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: handleSubmit) {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isSignUp ? "Kayıt Ol" : "Giriş Yap")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 79/255, green: 70/255, blue: 229/255))
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Zaten hesabınız var mı? Giriş yapın" : "Hesabınız yok mu? Kayıt olun")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func handleSubmit() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isSignUp {
                    try await authManager.signUpWithEmail(email: email, password: password)
                } else {
                    try await authManager.signInWithEmail(email: email, password: password)
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
