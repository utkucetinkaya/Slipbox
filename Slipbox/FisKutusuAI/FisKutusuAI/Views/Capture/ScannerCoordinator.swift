import SwiftUI

struct ScannerCoordinator: View {
    @Environment(\.dismiss) var dismiss
    
    enum Step {
        case camera
        case crop(UIImage)
        case processing(UIImage)
    }
    
    @State private var currentStep: Step = .camera
    @StateObject private var viewModel = InboxViewModel() // Shared view model for saving receipt
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A14").ignoresSafeArea()
            
            Group {
                switch currentStep {
                case .camera:
                    CameraCaptureView(onImageCaptured: { image in
                        currentStep = .crop(image)
                    }, onDismiss: {
                        dismiss()
                    })
                    .id("camera")
                    
                case .crop(let image):
                    ImageCropView(image: image, onRetake: {
                        currentStep = .camera
                    }, onContinue: { croppedImage in
                        currentStep = .processing(croppedImage)
                    })
                    .id("crop")
                    
                case .processing(let image):
                    ProcessingView(image: image, onReturnToInbox: {
                        dismiss()
                    })
                    .id("processing")
                }
            }
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.4), value: currentStep)
        .environmentObject(viewModel)
    }
}

extension ScannerCoordinator.Step: Equatable {
    static func == (lhs: ScannerCoordinator.Step, rhs: ScannerCoordinator.Step) -> Bool {
        switch (lhs, rhs) {
        case (.camera, .camera): return true
        case (.crop, .crop): return true
        case (.processing, .processing): return true
        default: return false
        }
    }
}

#Preview {
    ScannerCoordinator()
}
