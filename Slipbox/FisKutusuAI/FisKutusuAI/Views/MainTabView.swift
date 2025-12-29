import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            InboxView()
                .tabItem {
                    Label("Gelen Kutusu", systemImage: "tray.fill")
                }
                .tag(0)
            
            ReportsView()
                .tabItem {
                    Label("Raporlar", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

