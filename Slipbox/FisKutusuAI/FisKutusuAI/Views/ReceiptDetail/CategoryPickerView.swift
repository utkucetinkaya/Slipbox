import SwiftUI

struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var selectedCategoryId: String?
    
    @State private var searchText = ""
    @State private var showingCreateCategory = false
    
    @ObservedObject var categoryService = CategoryService.shared
    
    // Grid layout column definition
    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 20)
    ]
    
    private var filteredCategories: [Category] {
        let all = categoryService.allCategories
        if searchText.isEmpty {
            return all.sorted(by: { $0.order < $1.order })
        } else {
            return all.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) 
            }.sorted(by: { $0.order < $1.order })
        }
    }
    
    // Mock recent categories (could be real logic later)
    private var recentCategories: [Category] {
        Array(categoryService.allCategories.prefix(3))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        TextField("search_categories".localized, text: $searchText)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    .padding()
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            
                            // Recent Section
                            if searchText.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("recent".localized)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                        .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(recentCategories) { category in
                                                CategoryCircleItem(
                                                    category: category,
                                                    isSelected: selectedCategoryId == category.id,
                                                    action: {
                                                        selectCategory(category)
                                                    }
                                                )
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                            
                            // All Categories Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("all_categories_title".localized)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .padding(.horizontal, 20)
                                
                                LazyVGrid(columns: columns, spacing: 24) {
                                    ForEach(filteredCategories) { category in
                                        CategoryGridItem(
                                            category: category,
                                            isSelected: selectedCategoryId == category.id,
                                            action: {
                                                selectCategory(category)
                                            }
                                        )
                                    }
                                    
                                    // Create Custom Stub
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.3))
                                                .frame(width: 64, height: 64)
                                            
                                            Image(systemName: "plus")
                                                .font(.system(size: 24))
                                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                        }
                                        
                                        Text("create".localized)
                                            .font(.system(size: 13))
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    }
                                    .onTapGesture {
                                        showingCreateCategory = true
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
                
                // Create Custom Category Button (Floating)
                VStack {
                    Spacer()
                    Button(action: {
                        showingCreateCategory = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("create_custom_category".localized)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "4F46E5"))
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "4F46E5").opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("select_category".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4F46E5"))
                }
            }
            .sheet(isPresented: $showingCreateCategory) {
                CreateCategoryView()
            }
        }
    }
    
    private func selectCategory(_ category: Category) {
        selectedCategoryId = category.id
        dismiss()
    }
}

// MARK: - Components

struct CategoryCircleItem: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(isSelected ? Color(hex: "4F46E5") : DesignSystem.Colors.surface)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: category.icon)
                                .font(.system(size: 24))
                                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color(hex: "4F46E5"))) // Mask background
                            .offset(x: 4, y: -4)
                    }
                }
                
                Text(category.name.localized)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? Color(hex: "4F46E5") : DesignSystem.Colors.textPrimary.opacity(0.8))
            }
        }
    }
}

struct CategoryGridItem: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "4F46E5").opacity(0.2) : DesignSystem.Colors.surface)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color(hex: "4F46E5") : Color.clear, lineWidth: 2)
                        )
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary)
                }
                
                Text(category.name.localized)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    CategoryPickerView(selectedCategoryId: .constant("food_drink"))
}
