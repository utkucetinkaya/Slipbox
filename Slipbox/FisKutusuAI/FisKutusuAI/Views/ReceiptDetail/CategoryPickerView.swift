import SwiftUI

struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategoryId: String?
    
    @State private var searchText = ""
    
    // Grid layout column definition
    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 20)
    ]
    
    private var filteredCategories: [Category] {
        if searchText.isEmpty {
            return Category.defaults.sorted(by: { $0.order < $1.order })
        } else {
            return Category.defaults.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) 
            }.sorted(by: { $0.order < $1.order })
        }
    }
    
    // Mock recent categories (could be real logic later)
    private var recentCategories: [Category] {
        Array(Category.defaults.prefix(3))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "050511")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                        TextField("Search categories...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color(hex: "1C1C1E"))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            
                            // Recent Section
                            if searchText.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("RECENT")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
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
                                Text("ALL CATEGORIES")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
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
                                                .foregroundColor(.white.opacity(0.3))
                                                .frame(width: 64, height: 64)
                                            
                                            Image(systemName: "plus")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("Create")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .onTapGesture {
                                        // Stub action
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
                        // Stub action
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Create Custom Category")
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
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4F46E5"))
                }
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
                        .fill(isSelected ? Color(hex: "4F46E5") : Color(hex: "1C1C1E"))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: category.icon)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color(hex: "4F46E5"))) // Mask background
                            .offset(x: 4, y: -4)
                    }
                }
                
                Text(category.name)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? Color(hex: "4F46E5") : .white.opacity(0.8))
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
                        .fill(isSelected ? Color(hex: "4F46E5").opacity(0.2) : Color(hex: "1C1C1E"))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color(hex: "4F46E5") : Color.clear, lineWidth: 2)
                        )
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                }
                
                Text(category.name)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    CategoryPickerView(selectedCategoryId: .constant("food_drink"))
}
