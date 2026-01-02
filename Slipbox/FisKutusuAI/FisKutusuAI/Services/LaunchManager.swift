import SwiftUI
import Combine
import FirebaseAuth

enum LaunchState {
    case splash
    case auth
    case onboarding
    case permissions
    case entitlementsLoading
    case main
}

class LaunchManager: ObservableObject {
    static let shared = LaunchManager()
    
    @Published var state: LaunchState = .splash
    
    // Dependencies
    private let authManager = AuthenticationManager.shared
    private let entitlementManager = EntitlementManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Limits
    private let minSplashDuration: TimeInterval = 3.0
    
    private init() {
        // Observe Auth changes to trigger checks
        authManager.$user
            .combineLatest(authManager.$isProfileLoaded)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkState()
            }
            .store(in: &cancellables)
        
        entitlementManager.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkState()
            }
            .store(in: &cancellables)
    }
    
    func checkState() {
        // Ensure minimum splash time
        // Just triggered manually or by view appearing usually.
        // real logic:
        
        // 1. Splash is initial. We usually want to wait a bit.
        // Implementation: SplashView calls .checkState() on Appear.
        
        determineNextState()
    }
    
    private func determineNextState() {
        // 1. Onboarding Check (Priority: High - Always first for fresh installs)
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
             withAnimation { state = .onboarding }
             return
        }

        // 2. Auth Check
        if authManager.isLoading {
            // Still loading auth state (Firebase init), stay in splash
            return
        }
        
        guard let user = authManager.user else {
            withAnimation { state = .auth }
            return
        }
        
        // 3. Profile Loaded Check
        guard authManager.isProfileLoaded else {
            // Wait for profile to load (Splash or LoadingView will be shown)
            // If already in .auth and we just signed in, we stay there until it loads.
            return
        }
        
        // 4. Entitlements Listener Start (if not already)
        entitlementManager.startListening(uid: user.uid)
        
        // 5. Start Receipt Repository Listener
        FirestoreReceiptRepository.shared.startListening()
        
        // 6. Permissions Check
        if !UserDefaults.standard.bool(forKey: "hasSeenPermissions") {
            withAnimation { state = .permissions }
            return
        }
        
        // 7. Entitlements Check (Wait for first load)
        if entitlementManager.isLoading {
            withAnimation { state = .entitlementsLoading }
            return
        }
        
        // 8. Main App
        withAnimation { state = .main }
    }
    
    // MARK: - State Transitions for Views
    
    func completeSplash() {
        // Called by SplashView after delay
        determineNextState()
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        checkState()
    }
    
    func completePermissions() {
        UserDefaults.standard.set(true, forKey: "hasSeenPermissions")
        checkState()
    }
    
    // MARK: - Debug Tools
    
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        checkState()
    }
    
    func resetPermissions() {
        UserDefaults.standard.set(false, forKey: "hasSeenPermissions")
        checkState()
    }
    
    func resetAll() {
        resetOnboarding()
        resetPermissions()
        try? authManager.signOut()
    }
}
