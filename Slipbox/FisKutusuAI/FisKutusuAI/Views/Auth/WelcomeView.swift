import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showEmailSignIn = false
    @State private var showError = false
    @State private var appleSignInCoordinator = AppleSignInCoordinator()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Header: Logo
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 14)) // Matching app icon style essentially
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.5), radius: 10, x: 0, y: 0) // Glow effect
                        
                        Text("SlipBox")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Hero Image
                    // Using the generated 3D image.
                    if let uiImage = UIImage(named: "download-7") { // User renamed generated image to this
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 350)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 30, x: 0, y: 10)
                    } else {
                         // Fallback View
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(LinearGradient(colors: [DesignSystem.Colors.primary.opacity(0.4), DesignSystem.Colors.background], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 280, height: 320)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                        }
                        .frame(height: 350)
                    }
                    
                    Spacer()
                    
                    // Headlines
                    VStack(spacing: 12) {
                        DesignSystem.Typography.title1("Fişlerini saniyeler\niçinde düzene sok.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .lineSpacing(4)
                        
                        DesignSystem.Typography.body("Tarayın. Kategorileyin. Raporlayın.")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
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
                            .background(DesignSystem.Colors.primary) // Premium Purple
                            .foregroundColor(.white)
                            .cornerRadius(16)
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
                            .background(DesignSystem.Colors.inputBackground)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    
                    // Footer
                    HStack(spacing: 16) {
                        Link("Gizlilik", destination: URL(string: "https://yoursite.com/privacy")!)
                        Circle().frame(width: 2, height: 2).foregroundColor(DesignSystem.Colors.textSecondary)
                        Link("Kullanım Şartları", destination: URL(string: "https://yoursite.com/terms")!)
                    }
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.bottom, 24)
                }
            }
            .navigationDestination(isPresented: $showEmailSignIn) {
                EmailSignInView()
                    .toolbar(.hidden, for: .navigationBar)
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
        authManager.configureAppleRequest(request) // Use the manager to configure nonce
        
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
