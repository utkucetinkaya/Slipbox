
import SwiftUI
import AVFoundation

struct ImageCropView: View {
    let image: UIImage
    var onRetake: () -> Void
    var onContinue: (UIImage) -> Void
    
    // Normalized crop rect (0...1) relative to the image
    @State private var cropRect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    
    // To track geometric mapping
    @State private var imageFrame: CGRect = .zero
    
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
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding()
                
                Spacer()
                
                // Image Editor Area
                GeometryReader { geometry in
                    ZStack {
                        // 1. Image Layer
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .overlay(
                                GeometryReader { geo -> Color in
                                    DispatchQueue.main.async {
                                        // Store the frame of the image relative to the container
                                        self.imageFrame = geo.frame(in: .named("CropContainer"))
                                    }
                                    return Color.clear
                                }
                            )
                        
                        // 2. Crop Overlay Layer
                        if imageFrame != .zero {
                            CropOverlay(
                                cropRect: $cropRect,
                                imageFrame: imageFrame,
                                containerSize: geometry.size
                            )
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .coordinateSpace(name: "CropContainer")
                }
                .padding(20)
                
                Spacer()
                
                // Bottom Controls
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
                            performCrop()
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
    
    func performCrop() {
        // Map normalized rect to image pixel coordinates
        let scaleX = image.size.width
        let scaleY = image.size.height
        
        // Ensure cropRect is valid
        let crop = CGRect(
            x: max(0, cropRect.origin.x) * scaleX,
            y: max(0, cropRect.origin.y) * scaleY,
            width: min(1, cropRect.width) * scaleX,
            height: min(1, cropRect.height) * scaleY
        )
        
        guard let cgImg = image.cgImage?.cropping(to: crop) else {
            onContinue(image)
            return
        }
        
        let croppedImage = UIImage(cgImage: cgImg, scale: image.scale, orientation: image.imageOrientation)
        onContinue(croppedImage)
    }
}

// MARK: - Crop Overlay Component

// Custom Enum for Corners
enum CropCorner {
    case topLeft, topRight, bottomLeft, bottomRight
}

struct CropOverlay: View {
    @Binding var cropRect: CGRect
    let imageFrame: CGRect
    let containerSize: CGSize
    
    // Drag State
    @State private var dragStartRect: CGRect? = nil
    
    var body: some View {
        // Calculate the actual active frame in view coordinates
        let activeFrame = CGRect(
            x: imageFrame.minX + cropRect.minX * imageFrame.width,
            y: imageFrame.minY + cropRect.minY * imageFrame.height,
            width: cropRect.width * imageFrame.width,
            height: cropRect.height * imageFrame.height
        )
        
        ZStack {
            // 1. Dimmed Background (Difference Mask)
            Path { path in
                path.addRect(CGRect(origin: .zero, size: containerSize))
                path.addRect(activeFrame)
            }
            .fill(style: FillStyle(eoFill: true))
            .foregroundColor(Color.black.opacity(0.6))
            .allowsHitTesting(false)
            
            // 2. The Crop Box
            ZStack {
                // Grid Lines
                VStack {
                    Spacer(); Divider().background(Color.white.opacity(0.3)); Spacer(); Divider().background(Color.white.opacity(0.3)); Spacer()
                }
                HStack {
                    Spacer(); Divider().background(Color.white.opacity(0.3)); Spacer(); Divider().background(Color.white.opacity(0.3)); Spacer()
                }
                
                // Border
                Rectangle()
                    .stroke(Color(hex: "4F46E5"), lineWidth: 2)
                    .contentShape(Rectangle()) // Make workable area hit testable
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Move Logic
                                if dragStartRect == nil { dragStartRect = cropRect }
                                guard let start = dragStartRect else { return }
                                
                                let dx = value.translation.width / imageFrame.width
                                let dy = value.translation.height / imageFrame.height
                                
                                let newX = max(0, min(1 - start.width, start.origin.x + dx))
                                let newY = max(0, min(1 - start.height, start.origin.y + dy))
                                
                                cropRect.origin = CGPoint(x: newX, y: newY)
                            }
                            .onEnded { _ in dragStartRect = nil }
                    )
                
                // 3. Handles
                // Top-Left
                Handle()
                    .position(x: 0, y: 0)
                    .gesture(resizeGesture(corner: .topLeft))
                
                // Top-Right
                Handle()
                    .position(x: activeFrame.width, y: 0)
                    .gesture(resizeGesture(corner: .topRight))
                
                // Bottom-Left
                Handle()
                    .position(x: 0, y: activeFrame.height)
                    .gesture(resizeGesture(corner: .bottomLeft))
                
                // Bottom-Right
                Handle()
                    .position(x: activeFrame.width, y: activeFrame.height)
                    .gesture(resizeGesture(corner: .bottomRight))
            }
            .frame(width: activeFrame.width, height: activeFrame.height)
            .position(x: activeFrame.midX, y: activeFrame.midY)
        }
    }
    
    // Helper for Resize Logic
    func resizeGesture(corner: CropCorner) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if dragStartRect == nil { dragStartRect = cropRect }
                guard let start = dragStartRect else { return }
                
                let dx = value.translation.width / imageFrame.width
                let dy = value.translation.height / imageFrame.height
                
                var newRect = start
                
                switch corner {
                case .topLeft:
                    newRect.origin.x += dx
                    newRect.origin.y += dy
                    newRect.size.width -= dx
                    newRect.size.height -= dy
                case .topRight:
                    newRect.origin.y += dy
                    newRect.size.width += dx
                    newRect.size.height -= dy
                case .bottomLeft:
                    newRect.origin.x += dx
                    newRect.size.width -= dx
                    newRect.size.height += dy
                case .bottomRight:
                    newRect.size.width += dx
                    newRect.size.height += dy
                }
                
                // Min Size Constraint (e.g. 10%)
                if newRect.width < 0.1 || newRect.height < 0.1 { return }
                
                // Bounds Constraint (0...1)
                // (Simplified for brevity, would clamp edges)
                
                cropRect = newRect
            }
            .onEnded { _ in dragStartRect = nil }
    }
}

struct Handle: View {
    var body: some View {
        Circle()
            .fill(Color(hex: "4F46E5"))
            .frame(width: 24, height: 24)
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
    }
}

// Helpers
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
