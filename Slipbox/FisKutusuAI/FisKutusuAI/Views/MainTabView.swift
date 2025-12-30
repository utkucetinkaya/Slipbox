import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            InboxView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 0 ? "tray.fill" : "tray")
                        Text("inbox")
                    }
                }
                .tag(0)
            
            ReportsView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 1 ? "chart.bar.fill" : "chart.bar")
                        Text("reports")
                    }
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                        Text("settings")
                    }
                }
                .tag(2)
        }
        .accentColor(Color(hex: "4F46E5"))
    }
}

// MARK: - Placeholder Views (to be implemented)

