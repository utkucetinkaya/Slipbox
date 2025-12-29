import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    var onRetake: () -> Void
    var onContinue: (UIImage) -> Void
    
    @State private var currentRotation: Double = 0
    // In a real app, these would be draggable points. For this iteration UI, we mock the visual grid.
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: onRetake) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Fişi Kırp")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty visual balancer
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding()
                
                Spacer()
                
                // Image Area
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .rotationEffect(.degrees(currentRotation))
                        .padding(20)
                    
                    // Crop Overlay
                    ZStack {
                        // Grid Lines
                        GridShape()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        
                        // Border
                        Rectangle()
                            .stroke(Color(hex: "4F46E5"), lineWidth: 2)
                        
                        // Corner Handles
                        VStack {
                            HStack { Handle(); Spacer(); Handle() }
                            Spacer()
                            HStack { Handle(); Spacer(); Handle() }
                        }
                    }
                    .padding(20) // Matching image padding (in reality would be dynamic)
                    .aspectRatio(image.size.width/image.size.height, contentMode: .fit)
                    // Visual approximation for mock purposes
                }
                .frame(maxHeight: .infinity)
                
                // Rotation Control
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            currentRotation -= 90
                        }
                    }) {
                        Circle()
                            .fill(Color(hex: "1C1C1E"))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "rotate.right")
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(.trailing, 32)
                }
                
                // Bottom Bar
                VStack(spacing: 20) {
                    Text("Köşeleri sürükleyerek alanı belirleyin")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 16) {
                        Button(action: onRetake) {
                            Text("Tekrar Çek")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(hex: "1C1C1E"))
                                .cornerRadius(28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            // In reality, perform crop
                            onContinue(image)
                        }) {
                            HStack {
                                Text("Devam Et")
                                Image(systemName: "checkmark")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "4F46E5"))
                            .cornerRadius(28)
                        }
                    }
                }
                .padding(24)
                .background(Color(hex: "050511"))
                .cornerRadius(32, corners: [.topLeft, .topRight])
            }
        }
    }
}

// MARK: - Components

struct GridShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Verticals
        path.move(to: CGPoint(x: rect.width/3, y: 0)); path.addLine(to: CGPoint(x: rect.width/3, y: rect.height))
        path.move(to: CGPoint(x: 2*rect.width/3, y: 0)); path.addLine(to: CGPoint(x: 2*rect.width/3, y: rect.height))
        // Horizontals
        path.move(to: CGPoint(x: 0, y: rect.height/3)); path.addLine(to: CGPoint(x: rect.width, y: rect.height/3))
        path.move(to: CGPoint(x: 0, y: 2*rect.height/3)); path.addLine(to: CGPoint(x: rect.width, y: 2*rect.height/3))
        return path
    }
}

struct Handle: View {
    var body: some View {
        Circle()
            .fill(Color(hex: "4F46E5"))
            .frame(width: 24, height: 24)
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            // Offset logic would be here for drag
             .offset(x: -12, y: -12) // Alignment tweak
             .padding(0)
    }
}

// Helper for corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    ImageCropView(image: UIImage(), onRetake: {}, onContinue: { _ in })
}
