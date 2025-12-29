import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            InboxView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 0 ? "tray.fill" : "tray")
                        Text("Inbox")
                    }
                }
                .tag(0)
            
            ReportsView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 1 ? "chart.bar.fill" : "chart.bar")
                        Text("Raporlar")
                    }
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                        Text("Ayarlar")
                    }
                }
                .tag(2)
        }
        .accentColor(Color(hex: "4F46E5"))
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "0A0A14"))
            
            // Normal state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.white.opacity(0.5))
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Color.white.opacity(0.5))
            ]
            
            // Selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "4F46E5"))
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color(hex: "4F46E5"))
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

