import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingDeleteConfirmation = false
    @State private var showingSignOutConfirmation = false
    @State private var showingPaywall = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription Section
                subscriptionSection
                
                // App Settings
                appSettingsSection
                
                // About
                aboutSection
                
                // Debug (Only visible for dev/testing, but useful here)
                debugSection
                
                // Danger Zone
                dangerZoneSection
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .alert("Hesabı Sil", isPresented: $showingDeleteConfirmation) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Hesabınız ve tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz.")
            }
            .alert("Çıkış Yap", isPresented: $showingSignOutConfirmation) {
                Button("İptal", role: .cancel) { }
                Button("Çıkış Yap", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?")
            }
            .alert("Hata", isPresented: $showingError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            await viewModel.loadSettings()
        }
        .onReceive(viewModel.$errorMessage) { msg in
            if let msg = msg {
                self.errorMessage = msg
                self.showingError = true
            }
        }
    }
    
    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.isPro ? "SlipBox Pro" : "SlipBox Free")
                        .font(.headline) // AppFonts.headline
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if viewModel.isPro, let expiresAt = viewModel.expiresAt {
                        Text("Bitiş: \(formatDate(expiresAt))")
                            .font(.caption) // AppFonts.caption
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    } else {
                        Text("Sınırlı özellikler")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if viewModel.isPro {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                } else {
                    Button("Yükselt") {
                        showingPaywall = true
                    }
                    .font(.callout) // AppFonts.callout
                    .foregroundColor(.white)
                    .padding(.horizontal, 16) // AppSpacing.md
                    .padding(.vertical, 4) // AppSpacing.xs
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(8) // AppCornerRadius.sm
                }
            }
            .padding(.vertical, 4) // AppSpacing.xs
            
            if !viewModel.isPro {
                HStack {
                    Text("Bu ay kullanılan fiş:")
                    Spacer()
                    Text("\(viewModel.receiptCount) / 20")
                        .foregroundColor(viewModel.receiptCount >= 20 ? DesignSystem.Colors.error : DesignSystem.Colors.textSecondary)
                }
                .font(.body) // AppFonts.body
            }
        } header: {
            Text("Abonelik")
        }
    }
    
    // MARK: - App Settings
    private var appSettingsSection: some View {
        Section {
            // Currency Picker
            Picker("Para Birimi", selection: $viewModel.selectedCurrency) {
                Text("TRY (₺)").tag("TRY")
                Text("USD ($)").tag("USD")
                Text("EUR (€)").tag("EUR")
            }
            .onChange(of: viewModel.selectedCurrency) { newCurrency in
                Task {
                    await viewModel.updateCurrency(newCurrency)
                }
            }
            
            // Language (Display only for now)
            HStack {
                Text("Dil")
                Spacer()
                Text("Türkçe")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        } header: {
            Text("Uygulama")
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        Section {
            Link(destination: URL(string: "https://slipbox.web.app/privacy")!) {
                HStack {
                    Text("Gizlilik Politikası")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Link(destination: URL(string: "https://slipbox.web.app/terms")!) {
                HStack {
                    Text("Kullanım Koşulları")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            HStack {
                Text("Sürüm")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        } header: {
            Text("Hakkında")
        }
    }
    
    // MARK: - Debug Section
    private var debugSection: some View {
        Section {
            Button(action: {
                Task {
                    await viewModel.resetOnboarding()
                }
            }) {
                Text("Onboarding'i Sıfırla")
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        } header: {
            Text("Geliştirici (Debug)")
        } footer: {
            Text("Onboarding ekranlarını tekrar görmek için kullanın.")
        }
    }
    
    // MARK: - Danger Zone
    private var dangerZoneSection: some View {
        Section {
            Button(action: { showingSignOutConfirmation = true }) {
                Text("Çıkış Yap")
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Button(action: { showingDeleteConfirmation = true }) {
                Text("Hesabı Sil")
                    .foregroundColor(DesignSystem.Colors.error)
            }
        } header: {
            Text("Hesap")
        } footer: {
            Text("Hesabınızı sildiğinizde tüm fişleriniz, raporlarınız ve ayarlarınız kalıcı olarak silinir.")
        }
    }
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr-TR")
        return formatter.string(from: date)
    }
    
    private func signOut() {
        Task {
            // Call ViewModel sign out
            await viewModel.signOut()
        }
    }
    
    private func deleteAccount() {
        Task {
            await viewModel.deleteAccount()
        }
    }
}

// MARK: - ViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var isPro = false
    @Published var expiresAt: Date?
    @Published var receiptCount = 0
    @Published var selectedCurrency = "TRY"
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func loadSettings() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Fetch entitlements
            let entDoc = try await db.collection("entitlements").document(uid).getDocument()
            if let ent = try? entDoc.data(as: Entitlements.self) {
                isPro = ent.isPro
                expiresAt = ent.expiresAt?.dateValue()
                receiptCount = ent.receiptCount
            }
            
            // Fetch user profile
            let userDoc = try await db.collection("users").document(uid).getDocument()
            if let user = try? userDoc.data(as: UserProfile.self) {
                selectedCurrency = user.currencyDefault
            }
        } catch {
            print("Error loading settings: \(error)")
        }
    }
    
    func updateCurrency(_ currency: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await db.collection("users").document(uid).updateData([
                "currencyDefault": currency
            ])
        } catch {
            print("Error updating currency: \(error)")
        }
    }
    
    func resetOnboarding() async {
        do {
            try await AuthenticationManager.shared.resetOnboarding()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func signOut() async {
        do {
            try AuthenticationManager.shared.signOut()
        } catch {
            self.errorMessage = "Çıkış başarısız: \(error.localizedDescription)"
        }
    }
    
    func deleteAccount() async {
        do {
            // v1: Spark-first implementation
            // Skip Cloud Function call. Just delete the Auth user.
            // Note: This leaves orphan documents in Firestore, but for v1 MVP it's acceptable.
            // Ideally we would delete them client-side or use a scheduled function later.
            
            // Delete auth user
            try await Auth.auth().currentUser?.delete()
            
            // Sign out
            try Auth.auth().signOut()
        } catch {
            self.errorMessage = "Hesap silinemedi. Lütfen önce çıkış yapıp tekrar giriş yapın, ardından tekrar deneyin. (Hata: \(error.localizedDescription))"
        }
    }
}

// MARK: - Preview
#Preview("Free") {
    SettingsView()
}
