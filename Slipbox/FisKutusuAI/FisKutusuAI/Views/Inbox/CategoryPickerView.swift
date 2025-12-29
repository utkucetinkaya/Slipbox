import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategoryId: String?
    @State private var searchText = ""
    
    private var filteredCategories: [Category] {
        if searchText.isEmpty {
            return Category.defaults
        }
        return Category.defaults.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $searchText)
                .padding(16) // AppSpacing.md
            
            // Categories Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) { // AppSpacing.md
                    ForEach(filteredCategories) { category in
                        CategoryCell(
                            category: category,
                            isSelected: selectedCategoryId == category.id
                        )
                        .onTapGesture {
                            selectedCategoryId = category.id
                        }
                    }
                }
                .padding(16) // AppSpacing.md
            }
        }
    }
}

// MARK: - Category Cell
private struct CategoryCell: View {
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) { // AppSpacing.sm
            Image(systemName: category.icon)
                .font(.system(size: 32))
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.primary)
            
            Text(category.name)
                .font(.callout) // AppFonts.callout()
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.cardBackground)
        .cornerRadius(12) // AppCornerRadius.md
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Search Bar
private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextField("Kategori Ara", text: $text)
                .font(.body) // AppFonts.body()
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(8) // AppSpacing.sm
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(8) // AppCornerRadius.sm
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        CategoryPickerView(selectedCategoryId: .constant("food_drink"))
            .navigationTitle("Kategori Seç")
    }
}
