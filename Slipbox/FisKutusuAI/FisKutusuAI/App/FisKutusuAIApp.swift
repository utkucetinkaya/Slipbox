import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseAppCheck

@main
struct FisKutusuAIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - Root View Router
struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var launchManager = LaunchManager.shared
    
    var body: some View {
        Group {
            switch launchManager.state {
            case .splash:
                SplashView()
            case .auth:
                WelcomeView()
            case .onboarding:
                OnboardingContainerView()
            case .permissions:
                PermissionView()
            case .main:
                MainTabView()
            }
        }
        .animation(.default, value: launchManager.state)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }
}
