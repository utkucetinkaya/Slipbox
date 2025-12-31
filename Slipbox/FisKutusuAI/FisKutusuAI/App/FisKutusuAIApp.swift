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
            Color(hex: "050511")
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
            Color(hex: "050511")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "1C1C1E"))
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(hex: "4F46E5").opacity(0.3), radius: 20, x: 0, y: 0)
                    
                    Image("AppLogo") // Proper app logo as requested
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
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
