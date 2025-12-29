import SwiftUI
import Combine

enum LaunchState {
    case splash
    case auth
    case onboarding
    case permissions
    case main
}

class LaunchManager: ObservableObject {
    static let shared = LaunchManager()
    
    @Published var state: LaunchState = .splash
    
    // Dependencies
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Limits
    private let minSplashDuration: TimeInterval = 1.0
    
    private init() {
        // Observe Auth changes to trigger checks
        authManager.$user
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
        // 1. Auth Check
        guard authManager.user != nil else {
            withAnimation { state = .auth }
            return
        }
        
        // 2. Onboarding Check
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            withAnimation { state = .onboarding }
            return
        }
        
        // 3. Permissions Check
        if !UserDefaults.standard.bool(forKey: "hasSeenPermissions") {
            withAnimation { state = .permissions }
            return
        }
        
        // 4. Main App
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
