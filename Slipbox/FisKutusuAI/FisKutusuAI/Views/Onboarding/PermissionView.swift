import SwiftUI
import AVFoundation
import Photos

struct PermissionView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var cameraStatus: AVAuthorizationStatus = .notDetermined
    @State private var photoStatus: PHAuthorizationStatus = .notDetermined
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 0) {
                Spacer()
                
                // Hero Image
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "4F46E5").opacity(0.8),
                                Color(hex: "06B6D4").opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(Color(hex: "1C1C1E"))
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "4F46E5"), lineWidth: 2)
                        )
                    
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                    
                    // Checkmark Badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .offset(x: -10, y: -10)
                        }
                    }
                    .frame(width: 160, height: 160)
                }
                .padding(.bottom, 40)
                
                // Title & Description
                VStack(spacing: 16) {
                    Text("unlock_camera".localized)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("camera_permission_description".localized)
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 40)
                
                // Permission Cards
                VStack(spacing: 16) {
                    // Camera
                    PermissionCard(
                        icon: "camera.fill",
                        title: "onboarding_scan_title".localized,
                        description: "onboarding_scan_description".localized,
                        isAuthorized: cameraStatus == .authorized,
                        color: Color(hex: "4F46E5")
                    )
                    
                    // Gallery
                    PermissionCard(
                        icon: "photo.on.rectangle",
                        title: "select_from_gallery".localized,
                        description: "gallery_permission_description".localized,
                        isAuthorized: photoStatus == .authorized || photoStatus == .limited,
                        color: Color(hex: "4F46E5")
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button(action: requestAllPermissions) {
                        Text("enable_permissions".localized)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(DesignSystem.Colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(28)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    Button(action: skipOnboarding) {
                        Text("maybe_later".localized)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            checkPermissions()
        }
    }
    
    // MARK: - Logic
    private func checkPermissions() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoStatus = PHPhotoLibrary.authorizationStatus()
    }
    
    private func requestAllPermissions() {
        // Request Camera
        if cameraStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                DispatchQueue.main.async {
                    checkPermissions()
                    requestPhotoPermission()
                }
            }
        } else if cameraStatus == .denied {
            openSettings()
        } else {
            requestPhotoPermission()
        }
    }
    
    private func requestPhotoPermission() {
        if photoStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization { _ in
                DispatchQueue.main.async {
                    checkPermissions()
                    finishIfAuthorized()
                }
            }
        } else if photoStatus == .denied {
            openSettings()
        } else {
            finishIfAuthorized()
        }
    }
    
    private func finishIfAuthorized() {
        if cameraStatus == .authorized || photoStatus == .authorized {
            skipOnboarding()
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func skipOnboarding() {
        LaunchManager.shared.completePermissions()
    }
}

// MARK: - Subviews
struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isAuthorized: Bool
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                if isAuthorized {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.success)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
            }
            .padding(.top, 4)
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1C1C1E")) // Surface color
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isAuthorized ? DesignSystem.Colors.success.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    PermissionView()
        .environmentObject(AuthenticationManager.shared)
}
