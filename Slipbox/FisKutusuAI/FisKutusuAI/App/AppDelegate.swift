import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure App Check for abuse prevention
        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        #else
        let providerFactory = DeviceCheckProviderFactory()
        #endif
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Configure appearance
        configureAppearance()
        
        return true
    }
    
    private func configureAppearance() {
        // Navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
