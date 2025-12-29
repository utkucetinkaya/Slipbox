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

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    // Sign in with Apple nonce (RAW nonce is stored here, request gets SHA256(nonce))
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
                self.isLoading = false
            }
        }
    }

    // MARK: - Sign In with Apple (Request Config)
    /// Call this inside SignInWithAppleButton onRequest closure.
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce

        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce) // Apple wants hashed nonce
    }

    // MARK: - Sign In with Apple (Completion)
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let tokenData = credential.identityToken,
              let idTokenString = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.invalidCredentials
        }

        guard let rawNonce = currentNonce else {
            // You must call configureAppleRequest(_:) before this.
            throw AuthError.invalidCredentials
        }

        // Clear nonce immediately to prevent reuse
        currentNonce = nil

        // ✅ Correct Firebase Apple credential (fixes your compile error)
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: credential.fullName
        )

        do {
            let result = try await Auth.auth().signIn(with: firebaseCredential)

            if result.additionalUserInfo?.isNewUser == true {
                try await initializeNewUser(uid: result.user.uid, email: result.user.email)
            }
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    // MARK: - Email Sign In
    func signInWithEmail(email: String, password: String) async throws {
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    // MARK: - Email Sign Up
    func signUpWithEmail(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            try await initializeNewUser(uid: result.user.uid, email: email)
        } catch {
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }

    // MARK: - Initialize New User (Spark-first: client creates user doc)
    private func initializeNewUser(uid: String, email: String?) async throws {
        do {
            let userData: [String: Any] = [
                "uid": uid,
                "email": email ?? "",
                "currencyDefault": "TRY",
                "locale": "tr-TR",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            try await db.collection("users").document(uid).setData(userData, merge: true)

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

                try batch.setData(from: category, forDocument: ref, merge: true)
            }

            try await batch.commit()
        } catch {
            throw AuthError.initializationFailed(error.localizedDescription)
        }
    }

    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AuthError.signOutFailed(error.localizedDescription)
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
enum AuthError: LocalizedError {
    case invalidCredentials
    case signInFailed(String)
    case signUpFailed(String)
    case signOutFailed(String)
    case initializationFailed(String)

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
        }
    }
}
