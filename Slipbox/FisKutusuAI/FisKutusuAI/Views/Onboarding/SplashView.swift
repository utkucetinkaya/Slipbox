import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        ZStack {
            Color(hex: "050511").ignoresSafeArea()
            
            VStack {
                VStack(spacing: 20) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250, height: 250) // Adjust size for splash
                        .cornerRadius(48) // Rounded corners for icon look
                        .shadow(color: DesignSystem.Colors.primary.opacity(0.6), radius: 20, x: 0, y: 0) // Glow effect
                    
                    Text("SlipBox")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
        }
        .onAppear {
            // Wait for 1.5 seconds then notify LaunchManager
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                LaunchManager.shared.completeSplash()
            }
        }
    }
}

#Preview {
    SplashView()
}
