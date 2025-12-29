import SwiftUI
import AVFoundation
import PhotosUI

struct CameraCaptureView: View {
    var onImageCaptured: (UIImage) -> Void
    var onDismiss: () -> Void
    
    @State private var showingPhotoPicker = false
    @State private var cameraService = CameraService() // Custom simple camera service wrapper
    @State private var capturedImage: UIImage?
    
    var body: some View {
        ZStack {
            // Camera Layer
            CameraPreview(session: cameraService.session)
                .ignoresSafeArea()
                .onAppear {
                    cameraService.checkPermissions()
                    cameraService.start()
                }
                .onDisappear {
                    cameraService.stop()
                }
            
            // Overlay Layer
            VStack {
                // Top Custom Bar
                HStack {
                    Spacer()
                    Text("Fişi kadraja hizala")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    Spacer()
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Crop Guide Overlay (Visual only)
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                    
                    // Corner Markers
                    VStack {
                        HStack {
                            CornerMarker(color: Color(hex: "4F46E5"), topLeft: true)
                            Spacer()
                            CornerMarker(color: Color(hex: "4F46E5"), topRight: true)
                        }
                        Spacer()
                        HStack {
                            CornerMarker(color: Color(hex: "4F46E5"), bottomLeft: true)
                            Spacer()
                            CornerMarker(color: Color(hex: "4F46E5"), bottomRight: true)
                        }
                    }
                    .padding(40)
                    
                    // Scanning line visual
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "4F46E5").opacity(0), Color(hex: "4F46E5"), Color(hex: "4F46E5").opacity(0)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 2)
                        .shadow(color: Color(hex: "4F46E5"), radius: 4)
                        .opacity(0.5)
                }
                
                Spacer()
                
                // Bottom Controls
                HStack {
                    // Gallery Button
                    Button(action: { showingPhotoPicker = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 24))
                            Text("Galeriden Seç")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.white)
                    }
                    .padding(.leading, 32)
                    
                    Spacer()
                    
                    // Capture Button
                    Button(action: {
                        cameraService.capturePhoto { image in
                            if let image = image {
                                onImageCaptured(image)
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .fill(Color(hex: "4F46E5"))
                                .frame(width: 70, height: 70)
                        }
                    }
                    
                    Spacer()
                    
                    // Close Button
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.trailing, 32)
                }
                .padding(.bottom, 50)
                .background(
                    LinearGradient(colors: [.black.opacity(0), .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                )
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
             #if targetEnvironment(simulator)
             PhotoPickerView(selectedImage: .init(get: { nil }, set: { img in
                 if let img = img {
                     onImageCaptured(img)
                 }
             }))
             #else
             PhotoPickerView(selectedImage: .init(get: { nil }, set: { img in
                 if let img = img {
                     onImageCaptured(img)
                 }
             }))
             #endif
        }
    }
}

// MARK: - Components

struct CornerMarker: View {
    let color: Color
    var topLeft: Bool = false
    var topRight: Bool = false
    var bottomLeft: Bool = false
    var bottomRight: Bool = false
    
    var body: some View {
        Path { path in
            let w: CGFloat = 40
            let h: CGFloat = 40
            let r: CGFloat = 10
            
            if topLeft {
                path.move(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: 0, y: r))
                path.addQuadCurve(to: CGPoint(x: r, y: 0), control: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: w, y: 0))
            } else if topRight {
                path.move(to: CGPoint(x: -w, y: 0)) // Relative to frame... tricky in Path
                // Simpler approach: Just strokes
            }
        }
        .stroke(color, lineWidth: 4)
        .frame(width: 40, height: 40)
        // Actually simpler to use clear frame with overlay logic or just Images if assets existed.
        // Let's use simple shapes for now.
        .overlay(
            Group {
                if topLeft {
                    CameraCorner(rotation: 0, color: color)
                } else if topRight {
                    CameraCorner(rotation: 90, color: color)
                } else if bottomRight {
                    CameraCorner(rotation: 180, color: color)
                } else if bottomLeft {
                    CameraCorner(rotation: 270, color: color)
                }
            }
        )
    }
}

struct CameraCorner: View {
    let rotation: Double
    let color: Color
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .trim(from: 0, to: 0.25)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: 40, height: 40) // Clip frame
    }
}

// MARK: - Camera Service & Preview

class CameraService: NSObject {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        setupSession()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        case .denied, .restricted:
            // Handle error state
            break
        default: break
        }
    }
    
    func setupSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("❌ Camera Error: Could not create input device")
            return
        }
        
        session.beginConfiguration()
        // Ensure atomic commit
        defer { session.commitConfiguration() }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
    }
    
    func start() {
        // Run on background thread to prevent UI freezing
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let self = self, !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let self = self, self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.captureCompletion = completion
        
        // Check for active video connection
        guard let connection = output.connection(with: .video), connection.isActive, connection.isEnabled else {
            #if targetEnvironment(simulator)
            print("📱 Simulator detected: Generating mock receipt image.")
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 720, height: 1280))
            let image = renderer.image { ctx in
                UIColor.black.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 720, height: 1280))
                
                // Draw a simple receipt shape
                UIColor.white.setFill()
                ctx.fill(CGRect(x: 100, y: 200, width: 520, height: 800))
                
                // Draw dummy text
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 40, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                "MOCK RECEIPT".draw(at: CGPoint(x: 200, y: 300), withAttributes: attrs)
            }
            completion(image)
            #else
            print("❌ Camera Error: No active video connection.")
            completion(nil)
            #endif
            return
        }
        
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            captureCompletion?(nil)
            return
        }
        captureCompletion?(image)
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Photo Picker View
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}
