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
                .padding(AppSpacing.md)
            
            // Categories Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppSpacing.md) {
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
                .padding(AppSpacing.md)
            }
        }
    }
}

// MARK: - Category Cell
private struct CategoryCell: View {
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: category.icon)
                .font(.system(size: 32))
                .foregroundColor(isSelected ? .white : AppColors.primary)
            
            Text(category.name)
                .font(AppFonts.callout())
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(isSelected ? AppColors.primary : AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Search Bar
private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField("Kategori Ara", text: $text)
                .font(AppFonts.body())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.sm)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        CategoryPickerView(selectedCategoryId: .constant("food_drink"))
            .navigationTitle("Kategori Seç")
    }
}
