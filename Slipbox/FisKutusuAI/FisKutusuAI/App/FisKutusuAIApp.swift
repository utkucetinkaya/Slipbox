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
    @StateObject private var userPreferences = AppUserPreferences()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(userPreferences)
                .environmentObject(localizationManager)
                .environment(\.locale, userPreferences.locale)
        }
    }
}

// MARK: - Root View Router
struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var launchManager = LaunchManager.shared
    
    init() {
        // Global Appearance Configuration
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "050511")) // Dark background
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
        
        // Tab Bar Appearance is also configured here to ensure consistency
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color(hex: "1C1C1E")) // Slightly lighter for tab bar
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
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
