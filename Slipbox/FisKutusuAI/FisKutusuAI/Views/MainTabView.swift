import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var uiState: AppUIState
    @Environment(\.colorScheme) var colorScheme
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                InboxView()
                    .tag(0)
                    .toolbarBackground(.hidden, for: .tabBar)
                
                ReportsView()
                    .tag(1)
                    .toolbarBackground(.hidden, for: .tabBar)
                
                SettingsView()
                    .tag(2)
                    .toolbarBackground(.hidden, for: .tabBar)
            }
            
            if !uiState.isTabBarHidden {
                // Custom Pill TabBar
                HStack(spacing: 0) {
                    tabButton(index: 0, icon: "tray.fill", label: "inbox".localized)
                    tabButton(index: 1, icon: "chart.bar.fill", label: "reports".localized)
                    tabButton(index: 2, icon: "gearshape.fill", label: "settings".localized)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.surface)
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 20, x: 0, y: 10)
                )
                .overlay(
                    Capsule()
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 20) // Floating adjustment
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1) // Ensure it stays on top
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private func tabButton(index: Int, icon: String, label: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: selectedTab == index ? .bold : .medium))
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedTab == index ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(selectedTab == index ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
            )
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

