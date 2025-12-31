import SwiftUI
import AVFoundation
import PhotosUI
import UIKit

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
                Text("camera_instruction".localized)
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
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18))
                        }
                        Text("select_from_gallery".localized)
                            .font(.system(size: 10, weight: .medium))
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
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 76, height: 76)
                        
                        Circle()
                            .fill(Color(hex: "4F46E5"))
                            .frame(width: 64, height: 64)
                            .shadow(color: Color(hex: "4F46E5").opacity(0.5), radius: 10)
                    }
                }
                
                Spacer()
                
                // Close Button
                Button(action: onDismiss) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Image(systemName: "xmark")
                                .font(.system(size: 18))
                        }
                        Text("cancel".localized)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.white)
                }
                .padding(.trailing, 32)
            }
            .padding(.top, 20)
            .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 30)
            .background(
                Color.black.opacity(0.8)
                    .background(VisualEffectView(effect: UIBlurEffect(style: .dark)))
                    .ignoresSafeArea()
            )
        }
    }
    .sheet(isPresented: $showingPhotoPicker) {
        PhotoPickerView(selectedImage: $capturedImage)
            .ignoresSafeArea()
    }
    .onChange(of: capturedImage) { oldValue, newValue in
        if let image = newValue {
            // CRITICAL: We need a delay to allow the sheet to fully dismiss 
            // before ScannerCoordinator swaps out CameraCaptureView.
            // Without this, SwiftUI unmounts the view while its sheet is still "closing",
            // leading to the entire flow being dismissed.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onImageCaptured(image)
                capturedImage = nil
            }
        }
    }
}
}

// MARK: - Visual Effect View
struct VisualEffectView: UIViewRepresentable {
var effect: UIVisualEffect?
func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView() }
func updateUIView(_ uiView: UIVisualEffectView, context: Context) { uiView.effect = effect }
}

// MARK: - Components

struct CornerMarker: View {
    let color: Color
    var topLeft: Bool = false
    var topRight: Bool = false
    var bottomLeft: Bool = false
    var bottomRight: Bool = false
    
    var body: some View {
        CornerPath(
            topLeft: topLeft,
            topRight: topRight,
            bottomLeft: bottomLeft,
            bottomRight: bottomRight
        )
        .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        .frame(width: 40, height: 40)
    }
}

struct CornerPath: Shape {
    var topLeft: Bool
    var topRight: Bool
    var bottomLeft: Bool
    var bottomRight: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Length of the arm
        let l: CGFloat = 40 
        // Radius of the corner
        let r: CGFloat = 12 
        
        // We act based on which corner is active.
        // We assume the view frame is exactly the corner size (e.g. 40x40 or visual area).
        // Actually, let's draw relative to the specific corner of the frame.
        
        if topLeft {
            path.move(to: CGPoint(x: 0, y: l))
            path.addLine(to: CGPoint(x: 0, y: r))
            path.addQuadCurve(to: CGPoint(x: r, y: 0), control: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: l, y: 0))
        } else if topRight {
            path.move(to: CGPoint(x: w - l, y: 0))
            path.addLine(to: CGPoint(x: w - r, y: 0))
            path.addQuadCurve(to: CGPoint(x: w, y: r), control: CGPoint(x: w, y: 0))
            path.addLine(to: CGPoint(x: w, y: l))
        } else if bottomLeft {
            path.move(to: CGPoint(x: 0, y: h - l))
            path.addLine(to: CGPoint(x: 0, y: h - r))
            path.addQuadCurve(to: CGPoint(x: r, y: h), control: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: l, y: h))
        } else if bottomRight {
            path.move(to: CGPoint(x: w - l, y: h))
            path.addLine(to: CGPoint(x: w - r, y: h))
            path.addQuadCurve(to: CGPoint(x: w, y: h - r), control: CGPoint(x: w, y: h))
            path.addLine(to: CGPoint(x: w, y: h - l))
        }
        
        return path
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
        // Just dismiss, we will load async
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider else { return }
        
        // Load image
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self.parent.selectedImage = uiImage
                    }
                }
            }
        }
    }
}
}
