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
            Color.black.ignoresSafeArea()
            
            switch currentStep {
            case .camera:
                CameraCaptureView(onImageCaptured: { image in
                    currentStep = .crop(image)
                }, onDismiss: {
                    dismiss()
                })
                .transition(.opacity)
                
            case .crop(let image):
                ImageCropView(image: image, onRetake: {
                    currentStep = .camera
                }, onContinue: { croppedImage in
                    currentStep = .processing(croppedImage)
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .processing(let image):
                ProcessingView(image: image, onReturnToInbox: {
                    dismiss()
                })
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: currentStep)
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
