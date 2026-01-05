import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showEmailSignIn = false
    @State private var showError = false
    @State private var coordinator: AppleSignInCoordinator?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                // Header: Logo
                                HStack(spacing: 8) {
                                    Image("AppLogo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .shadow(color: DesignSystem.Colors.primary.opacity(0.5), radius: 10, x: 0, y: 0)
                                    
                                    Text("SlipBox")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                }
                                .padding(.top, 20)
                                .padding(.bottom, geometry.size.height * 0.05)
                                
                                // Hero Image
                                Group {
                                    if let uiImage = UIImage(named: "download-7") {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: min(geometry.size.height * 0.4, 350)) // Dynamic height
                                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 30, x: 0, y: 10)
                                    } else {
                                        // Fallback View
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 30)
                                                .fill(LinearGradient(colors: [DesignSystem.Colors.primary.opacity(0.4), DesignSystem.Colors.background], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(height: min(geometry.size.height * 0.4, 320))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 30)
                                                        .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
                                                )
                                            
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 80))
                                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                        }
                                        .padding(.horizontal, 40)
                                    }
                                }
                                .padding(.bottom, geometry.size.height * 0.05)
                                
                                // Headlines
                                VStack(spacing: 12) {
                                    DesignSystem.Typography.title1("Fişlerini saniyeler\niçinde düzene sok.")
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                        .lineSpacing(4)
                                        .minimumScaleFactor(0.8) // Allow scaling down
                                    
                                    DesignSystem.Typography.body("Tarayın. Kategorileyin. Raporlayın.")
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                            .frame(minHeight: geometry.size.height - 220) // Ensure spacing for footer
                        }
                        
                        // Buttons Footer
                        VStack(spacing: 16) {
                            // Custom Apple Sign In Button
                            Button(action: startAppleSignIn) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .padding(.trailing, 8)
                                    } else {
                                        Image(systemName: "apple.logo")
                                            .font(.system(size: 20))
                                    }
                                    Text("Apple ile Devam Et")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(DesignSystem.Colors.primary) // Premium Purple
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                            .disabled(authManager.isLoading)
                            
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
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                )
                            }
                            .disabled(authManager.isLoading)
                            
                            // Footer Links
                            HStack(spacing: 16) {
                                NavigationLink(destination: PrivacyPolicyView()) {
                                    Text("privacy".localized)
                                }
                                
                                Circle().frame(width: 2, height: 2).foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                NavigationLink(destination: TermsOfServiceView()) {
                                    Text("terms".localized)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 20)
                        .background(DesignSystem.Colors.background.opacity(0.95))
                    }
                }
                
                // Final Loading Overlay
                if authManager.isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
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
        }
    }
    
    private func startAppleSignIn() {
        let coordinator = AppleSignInCoordinator(
            onSuccess: { credential in
                Task {
                    do {
                        try await authManager.signInWithApple(credential: credential)
                    } catch {
                        authManager.errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            },
            onError: { error in
                authManager.errorMessage = error.localizedDescription
                showError = true
            }
        )
        
        self.coordinator = coordinator // Retain the coordinator
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        authManager.configureAppleRequest(request)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = coordinator
        controller.presentationContextProvider = coordinator
        controller.performRequests()
    }
}

// MARK: - Apple Sign In Coordinator
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    let onSuccess: (ASAuthorizationAppleIDCredential) -> Void
    let onError: (Error) -> Void
    
    init(onSuccess: @escaping (ASAuthorizationAppleIDCredential) -> Void, onError: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return UIWindow()
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            onSuccess(appleIDCredential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError
        if nsError.code != ASAuthorizationError.canceled.rawValue {
            onError(error)
        }
    }
}
