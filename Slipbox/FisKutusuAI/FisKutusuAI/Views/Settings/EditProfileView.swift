import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var uiState: AppUIState
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Photo Picker
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Avatar Edit
                VStack(spacing: 16) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else if let urlString = authManager.profile?.profileImageUrl, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 120, height: 120)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    case .failure:
                                        defaultAvatar
                                    @unknown default:
                                        defaultAvatar
                                    }
                                }
                            } else {
                                defaultAvatar
                            }
                            
                            editBadge
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImage = image
                            }
                        }
                    }
                    
                    Button("Fotoğrafı Değiştir") {
                        // Triggers the PhotosPicker if needed, but the picker itself is a button
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                }
                .padding(.top, 20)
                
                // Form Fields
                VStack(spacing: 20) {
                    ProfileField(label: "Ad Soyad", text: $fullName)
                    
                    ProfileField(label: "E-posta", text: $email, isLocked: true)
                    
                    ProfileField(label: "Telefon", text: $phone)
                }
                .padding(.horizontal, 20)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Save Button
                Button(action: saveProfile) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Kaydet")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(28)
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(20)
                .disabled(isLoading)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Profili Düzenle")
        .onAppear {
            uiState.isTabBarHidden = true
            // Load current profile data
            if let profile = authManager.profile {
                fullName = profile.displayName ?? ""
                email = authManager.user?.email ?? ""
                phone = profile.phoneNumber ?? ""
            }
        }
        .onDisappear {
            uiState.isTabBarHidden = false
        }
    }
    
    private func saveProfile() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                var imageUrl: String? = nil
                if let image = selectedImage {
                    imageUrl = try await authManager.uploadProfileImage(image)
                }
                
                try await authManager.updateProfile(
                    displayName: fullName,
                    phoneNumber: phone,
                    profileImageUrl: imageUrl
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(DesignSystem.Colors.primary.opacity(0.1))
            .frame(width: 120, height: 120)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignSystem.Colors.primary)
            )
    }
    
    private var editBadge: some View {
        Circle()
            .fill(DesignSystem.Colors.primary)
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "pencil")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            )
            .overlay(
                Circle()
                    .stroke(DesignSystem.Colors.background, lineWidth: 4)
            )
    }
}

struct ProfileField: View {
    let label: String
    @Binding var text: String
    var isLocked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack {
                TextField("", text: $text)
                    .foregroundColor(isLocked ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                    .disabled(isLocked)
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
                }
            }
            .padding()
            .background(DesignSystem.Colors.inputBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
    }
}
