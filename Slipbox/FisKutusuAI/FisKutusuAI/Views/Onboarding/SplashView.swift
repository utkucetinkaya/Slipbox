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
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "4F46E5"))
                    
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
