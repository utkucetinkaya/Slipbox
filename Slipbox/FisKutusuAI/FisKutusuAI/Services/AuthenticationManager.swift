import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseAppCheck
import AuthenticationServices
import Combine
import CryptoKit
import Security

@MainActor
final class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var user: User?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var isOnboardingCompleted = false
    @Published var isProfileLoaded = false
    @Published var profile: UserProfile?

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    // Sign in with Apple nonce
    private var currentNonce: String?

    private init() {
        registerAuthStateHandler()
    }

    // MARK: - Auth State Observer
    private func registerAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                self.user = user
                if let user = user {
                    // Fetch user doc to check onboarding status
                    await self.fetchUserStatus(uid: user.uid)
                } else {
                    self.isOnboardingCompleted = false
                    self.isProfileLoaded = false
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Fetch User Status
    func fetchUserStatus(uid: String) async {
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let profile = try? snapshot.data(as: UserProfile.self) {
                self.profile = profile
                self.isOnboardingCompleted = profile.onboardingCompleted
                self.isProfileLoaded = true
                print("✅ User Profile Loaded: \(uid)")
            } else {
                self.isProfileLoaded = false
                print("⚠️ User Profile Missing in Firestore: \(uid)")
            }
        } catch {
            print("❌ Error fetching user status: \(error.localizedDescription)")
            self.isProfileLoaded = false 
        }
        self.isLoading = false
    }
    
    // MARK: - Update Onboarding Status
    func completeOnboarding() async throws {
        guard let uid = user?.uid else { return }
        try await db.collection("users").document(uid).updateData([
            "onboardingCompleted": true,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        self.isOnboardingCompleted = true
        self.profile?.onboardingCompleted = true
    }
    
    // MARK: - Update Profile
    func updateProfile(displayName: String, phoneNumber: String, profileImageUrl: String? = nil) async throws {
        guard let uid = user?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        var updateData: [String: Any] = [
            "displayName": displayName,
            "phoneNumber": phoneNumber,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let imageUrl = profileImageUrl {
            updateData["profileImageUrl"] = imageUrl
        }
        
        do {
            try await db.collection("users").document(uid).updateData(updateData)
            
            self.profile?.displayName = displayName
            self.profile?.phoneNumber = phoneNumber
            if let imageUrl = profileImageUrl {
                self.profile?.profileImageUrl = imageUrl
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Profile Image Processing
    func processProfileImage(_ image: UIImage) async throws -> String {
        // Limit image size for Firestore (Base64 string limit)
        let resizedImage = image.preparingThumbnail(of: CGSize(width: 200, height: 200)) ?? image
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Görsel verisi oluşturulamadı"])
        }
        
        return imageData.base64EncodedString()
    }
    
    // MARK: - Reset Onboarding (Debug)
    func resetOnboarding() async throws {
        guard let uid = user?.uid else { return }
        try await db.collection("users").document(uid).updateData([
            "onboardingCompleted": false
        ])
        self.isOnboardingCompleted = false
    }

    // MARK: - Sign In with Apple (Request Config)
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce

        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    // MARK: - Sign In with Apple (Completion)
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let tokenData = credential.identityToken,
              let idTokenString = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.invalidCredentials
        }

        guard let rawNonce = currentNonce else {
            throw AuthError.invalidCredentials
        }

        currentNonce = nil

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: credential.fullName
        )

        do {
            isLoading = true
            errorMessage = nil
            
            let result = try await Auth.auth().signIn(with: firebaseCredential)
            
            if result.additionalUserInfo?.isNewUser == true {
                try await initializeNewUser(uid: result.user.uid, email: result.user.email)
            }
            isLoading = false
            // Status will be fetched by the auth listener
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    // MARK: - Email Sign In
    func signInWithEmail(email: String, password: String) async throws {
        do {
            isLoading = true
            errorMessage = nil
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    // MARK: - Email Sign Up
    func signUpWithEmail(email: String, password: String) async throws {
        do {
            isLoading = true
            errorMessage = nil
            
            print("🚀 Starting Sign-Up for: \(email)")
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ Auth User Created: \(result.user.uid)")
            
            try await initializeNewUser(uid: result.user.uid, email: email)
            print("✅ User Profile Initialized")
            
            self.isProfileLoaded = true
            isLoading = false
        } catch {
            print("❌ Sign-Up Error: \(error.localizedDescription)")
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }

    // MARK: - Initialize New User
    private func initializeNewUser(uid: String, email: String?) async throws {
        do {
            let userData: [String: Any] = [
                "uid": uid,
                "email": email ?? "",
                "displayName": "",
                "phoneNumber": "",
                "profileImageUrl": NSNull(),
                "currencyDefault": "TRY",
                "locale": "tr-TR",
                "onboardingCompleted": false,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            try await db.collection("users").document(uid).setData(userData, merge: true)
            print("📦 User doc set in Firestore")
            
            // Populate local profile
            self.profile = try? await db.collection("users").document(uid).getDocument().data(as: UserProfile.self)

            // Seed default categories
            let defaultCategories = Category.defaults
            let batch = db.batch()

            for category in defaultCategories {
                guard let categoryId = category.id else { continue }
                let ref = db
                    .collection("users")
                    .document(uid)
                    .collection("categories")
                    .document(categoryId)

                try batch.setData(from: category, forDocument: ref)
            }

            try await batch.commit()
            print("📦 Default categories batch committed")
        } catch {
            print("❌ Firestore Initialization Failed: \(error.localizedDescription)")
            throw AuthError.initializationFailed(error.localizedDescription)
        }
    }

    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.isOnboardingCompleted = false
        } catch {
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let uid = user?.uid else { return }
        
        do {
            // 1. Delete Receipts
            let receipts = try await db.collection("users").document(uid).collection("receipts").getDocuments()
            let batch = db.batch()
            for doc in receipts.documents {
                batch.deleteDocument(doc.reference)
            }
            
            // 2. Delete Categories
            let categories = try await db.collection("users").document(uid).collection("categories").getDocuments()
            for doc in categories.documents {
                batch.deleteDocument(doc.reference)
            }
            
            // 3. Delete Profiles
            batch.deleteDocument(db.collection("users").document(uid))
            batch.deleteDocument(db.collection("entitlements").document(uid))
            
            try await batch.commit()
            
            // 5. Delete Firebase Auth User
            guard let authUser = Auth.auth().currentUser else {
                throw AuthError.notAuthenticated
            }
            
            do {
                try await authUser.delete()
            } catch let error as NSError {
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    throw AuthError.requiresRecentLogin
                }
                throw AuthError.deleteFailed
            }
            
            self.user = nil
            self.isOnboardingCompleted = false
            self.isProfileLoaded = false
        } catch let error as AuthError {
            throw error
        } catch {
            print("❌ Delete account error: \(error)")
            throw AuthError.deleteFailed
        }
    }

    // MARK: - App Check Token (optional helper)
    func getAppCheckToken() async throws -> String {
        let token = try await AppCheck.appCheck().token(forcingRefresh: false)
        return token.token
    }

    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

// MARK: - Nonce helpers (Firebase recommended)
private extension AuthenticationManager {
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if status != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
        }

        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Auth Errors
enum AuthError: Error, LocalizedError, Equatable {
    case invalidCredentials
    case signInFailed(String)
    case signUpFailed(String)
    case signOutFailed(String)
    case initializationFailed(String)
    case notAuthenticated
    case deleteFailed
    case requiresRecentLogin

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Geçersiz kimlik bilgileri"
        case .signInFailed(let message):
            return "Giriş başarısız: \(message)"
        case .signUpFailed(let message):
            return "Kayıt başarısız: \(message)"
        case .signOutFailed(let message):
            return "Çıkış başarısız: \(message)"
        case .initializationFailed(let message):
            return "Kullanıcı başlatma başarısız: \(message)"
        case .notAuthenticated:
            return "Kullanıcı oturumu bulunamadı"
        case .deleteFailed:
            return "Hesap silme işlemi sırasında bir hata oluştu"
        case .requiresRecentLogin:
            return "Güvenlik gereği, bu işlem için yakın zamanda giriş yapmış olmanız gerekiyor. Lütfen çıkış yapıp tekrar girin."
        }
    }
    
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials),
             (.notAuthenticated, .notAuthenticated),
             (.deleteFailed, .deleteFailed),
             (.requiresRecentLogin, .requiresRecentLogin):
            return true
        case (.signInFailed(let l), .signInFailed(let r)),
             (.signUpFailed(let l), .signUpFailed(let r)),
             (.signOutFailed(let l), .signOutFailed(let r)),
             (.initializationFailed(let l), .initializationFailed(let r)):
            return l == r
        default:
            return false
        }
    }
}
