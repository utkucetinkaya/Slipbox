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
        PhotoPickerView(selectedImage: $capturedImage)
    }
    .onChange(of: capturedImage) { newItem in
        if let image = newItem {
            // Trigger capture flow when image is selected
            onImageCaptured(image)
            // Reset for next time if needed, though view will likely disappear
            capturedImage = nil
        }
    }
}
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
