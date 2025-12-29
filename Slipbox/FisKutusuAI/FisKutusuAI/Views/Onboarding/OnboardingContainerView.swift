import SwiftUI

struct OnboardingContainerView: View {
    @State private var showPermissions = false
    
    var body: some View {
        ZStack {
            if false { // Permission is now handled by LaunchManager router, not internally here
                PermissionView()
                    .transition(.move(edge: .trailing))
            } else {
                OnboardingView(showPermissions: Binding(
                    get: { false },
                    set: { _ in LaunchManager.shared.completeOnboarding() }
                ))
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.spring(), value: showPermissions)
    }
}
