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
    @StateObject private var userPreferences = AppUserPreferences.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var entitlementManager = EntitlementManager.shared
    @StateObject private var storeKitManager = StoreKitManager.shared
    @StateObject private var uiState = AppUIState.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(userPreferences)
                .environmentObject(localizationManager)
                .environmentObject(entitlementManager)
                .environmentObject(storeKitManager)
                .environmentObject(uiState)
                .environment(\.locale, userPreferences.locale)
                .preferredColorScheme(userPreferences.appTheme.colorScheme)
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
        appearance.backgroundColor = UIColor(DesignSystem.Colors.background) // Dark background
        appearance.titleTextAttributes = [.foregroundColor: UIColor(DesignSystem.Colors.textPrimary)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(DesignSystem.Colors.textPrimary)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(DesignSystem.Colors.primary)
        
        // Hide Native Tab Bar Globally
        // We use a custom floating tab bar, so the native one should never be visible or interactive.
        UITabBar.appearance().isHidden = true
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
            case .entitlementsLoading:
                EntitlementsLoadingView()
            case .main:
                MainTabView()
            }
        }
        .animation(.default, value: launchManager.state)
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}

struct EntitlementsLoadingView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.surface)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(hex: "4F46E5").opacity(0.3), radius: 20, x: 0, y: 0)
                    
                    Image("AppLogo") // Proper app logo as requested
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .cornerRadius(14)
                }
                
                VStack(spacing: 8) {
                    Text("slipbox_app_name".localized)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("processing".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
    }
}
