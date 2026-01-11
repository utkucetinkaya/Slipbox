import SwiftUI

struct PremiumGateModifier: ViewModifier {
    @ObservedObject var entitlementManager = EntitlementManager.shared
    var isLocked: Bool
    var onLockedTap: () -> Void = {}
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLocked && !entitlementManager.isPro)
            
            if isLocked && !entitlementManager.isPro {
                Color.black.opacity(0.001) // Invisible tap target
                    .onTapGesture {
                        onLockedTap()
                    }
                
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                    Spacer()
                }
            }
        }
    }
}

extension View {
    func premiumGate(isLocked: Bool, onLockedTap: @escaping () -> Void) -> some View {
        self.modifier(PremiumGateModifier(isLocked: isLocked, onLockedTap: onLockedTap))
    }
}

struct PremiumLockedView<Content: View>: View {
    @ObservedObject var entitlementManager = EntitlementManager.shared
    let content: Content
    let onLockedTap: () -> Void
    
    init(onLockedTap: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onLockedTap = onLockedTap
    }
    
    var body: some View {
        if entitlementManager.isPro {
            content
        } else {
            content
                .overlay(
                    Color.black.opacity(0.4)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                        )
                        .cornerRadius(12)
                )
                .onTapGesture {
                    onLockedTap()
                }
        }
    }
}
