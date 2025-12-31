import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var uiState: AppUIState
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    InboxView()
                case 1:
                    ReportsView()
                case 2:
                    SettingsView()
                default:
                    InboxView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
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
                        .fill(Color(hex: "1C1C1E"))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 20) // Floating adjustment
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
            .foregroundColor(selectedTab == index ? Color(hex: "4F46E5") : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(selectedTab == index ? Color(hex: "4F46E5").opacity(0.1) : Color.clear)
            )
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

