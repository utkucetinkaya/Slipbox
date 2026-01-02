import SwiftUI

struct CreateCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var categoryName: String = ""
    @State private var selectedIcon: String = "cart.fill"
    @State private var selectedColor: Color = Color(hex: "4F46E5")
    
    private let icons = [
        "cart.fill", "car.fill", "fork.knife", "desktopcomputer", "wrench.fill",
        "bag.fill", "house.fill", "tshirt.fill", "heart.fill", "film.fill",
        "book.fill", "airplane", "creditcard.fill", "gift.fill", "doc.text.fill"
    ]
    
    private let colors = [
        Color(hex: "4F46E5"), Color(hex: "A855F7"), Color(hex: "FF2D55"),
        Color(hex: "FF9500"), Color(hex: "FFCC00"), Color(hex: "34C759"),
        Color(hex: "007AFF"), Color(hex: "FF3B30"), Color.gray
    ]
    
    private let columns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
        GridItem(.flexible()), GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Preview Card
                        VStack(spacing: 16) {
                            Circle()
                                .fill(selectedColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: selectedIcon)
                                        .font(.system(size: 32))
                                        .foregroundColor(selectedColor)
                                )
                                .shadow(color: selectedColor.opacity(0.3), radius: 10)
                            
                            Text(categoryName.isEmpty ? "category_name_placeholder".localized : categoryName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(categoryName.isEmpty ? DesignSystem.Colors.textSecondary.opacity(0.3) : DesignSystem.Colors.textPrimary)
                        }
                        .padding(.top, 20)
                        
                        // Form Fields
                        VStack(alignment: .leading, spacing: 24) {
                            // Name Input
                            VStack(alignment: .leading, spacing: 12) {
                                Text("category_name_label".localized)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                TextField("category_name_placeholder".localized, text: $categoryName)
                                    .padding()
                                    .background(DesignSystem.Colors.surface)
                                    .cornerRadius(12)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                            
                            // Color Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("select_color".localized)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                HStack(spacing: 12) {
                                    ForEach(colors, id: \.self) { color in
                                        Circle()
                                            .fill(color)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                            )
                                            .onTapGesture {
                                                withAnimation(.spring()) {
                                                    selectedColor = color
                                                }
                                            }
                                    }
                                }
                            }
                            
                            // Icon Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("select_icon".localized)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(icons, id: \.self) { icon in
                                        ZStack {
                                            Circle()
                                                .fill(selectedIcon == icon ? DesignSystem.Colors.surface : Color.clear)
                                                .frame(width: 48, height: 48)
                                                .overlay(
                                                    Circle()
                                                        .stroke(selectedIcon == icon ? selectedColor : Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                            
                                            Image(systemName: icon)
                                                .font(.system(size: 20))
                                                .foregroundColor(selectedIcon == icon ? selectedColor : DesignSystem.Colors.textSecondary)
                                        }
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                selectedIcon = icon
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("create_category_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save".localized) {
                        let newCategory = Category(
                            id: UUID().uuidString,
                            name: categoryName,
                            icon: selectedIcon,
                            order: 100, // Custom categories at the end
                            isDefault: false
                        )
                        CategoryService.shared.addCustomCategory(newCategory)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(categoryName.isEmpty ? .white.opacity(0.3) : Color(hex: "4F46E5"))
                    .disabled(categoryName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    CreateCategoryView()
        .environmentObject(LocalizationManager.shared)
}
