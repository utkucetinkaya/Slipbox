import SwiftUI

struct OnboardingContainerView: View {
    @State private var showPermissions = false
    
    var body: some View {
        ZStack {
            if showPermissions {
                PermissionView()
                    .transition(.move(edge: .trailing))
            } else {
                OnboardingView(showPermissions: $showPermissions)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.spring(), value: showPermissions)
    }
}
