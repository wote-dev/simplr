//
//  CategoryPillView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct CategoryPillView: View {
    @Environment(\.theme) var theme
    let category: TaskCategory?
    let isSelected: Bool
    let taskCount: Int?
    let action: () -> Void
    @State private var isPressed = false
    
    private var displayName: String {
        category?.name ?? "All"
    }
    
    private var categoryColor: Color {
        category?.color.color ?? theme.textSecondary
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return category?.color.lightColor ?? theme.surface
        } else {
            return theme.surface
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return category?.color.darkColor ?? theme.text
        } else {
            return theme.textSecondary
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.smoothSpring) {
                HapticManager.shared.selectionChange()
                action()
            }
        }) {
            HStack(spacing: 8) {
                // Category color indicator
                if let category = category {
                    Circle()
                        .fill(category.color.gradient)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(category.color.darkColor, lineWidth: 1)
                                .opacity(0.3)
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.smoothSpring, value: isSelected)
                } else {
                    // "All" category icon
                    Image(systemName: "list.bullet")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(textColor)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.smoothSpring, value: isSelected)
                }
                
                // Category name
                Text(displayName)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(textColor)
                    .animation(.easeOut(duration: 0.2), value: isSelected)
                
                // Task count badge
                if let taskCount = taskCount, taskCount > 0 {
                    Text("\(taskCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? theme.surface : theme.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? categoryColor : theme.surfaceSecondary)
                        )
                        .scaleEffect(isSelected ? 1.0 : 0.9)
                        .animation(.smoothSpring, value: isSelected)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(backgroundColor)
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? categoryColor.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.interpolatingSpring(stiffness: 600, damping: 30), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .personalityButton(style: .gentle)
    }
}

// MARK: - Category Selector View
struct CategorySelectorView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingCreateCategory = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" category pill
                CategoryPillView(
                    category: nil,
                    isSelected: categoryManager.selectedCategoryFilter == nil,
                    taskCount: taskManager.tasks.filter { $0.categoryId == nil }.count,
                    action: {
                        categoryManager.clearFilter()
                    }
                )
                
                // Category pills
                ForEach(categoryManager.categories) { category in
                    CategoryPillView(
                        category: category,
                        isSelected: categoryManager.selectedCategoryFilter == category.id,
                        taskCount: categoryManager.taskCount(for: category.id, in: taskManager.tasks),
                        action: {
                            if categoryManager.selectedCategoryFilter == category.id {
                                categoryManager.clearFilter()
                            } else {
                                categoryManager.setSelectedFilter(category.id)
                            }
                        }
                    )
                }
                
                // Add category button
                Button(action: {
                    showingCreateCategory = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                        Text("Add")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(theme.textTertiary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .background(
                                Capsule()
                                    .fill(theme.surface.opacity(0.5))
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showingCreateCategory) {
            CreateCategoryView()
        }
    }
}

// MARK: - Create Category View
struct CreateCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    @EnvironmentObject var categoryManager: CategoryManager
    
    @State private var categoryName = ""
    @State private var selectedColor: CategoryColor = .blue
    @FocusState private var isNameFocused: Bool
    
    var isValidName: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !categoryManager.categories.contains { $0.name.lowercased() == categoryName.lowercased() }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Category")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.text)
                    
                    Text("Organize your tasks with custom categories")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Category name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category Name")
                        .font(.headline)
                        .foregroundColor(theme.text)
                    
                    TextField("Enter category name", text: $categoryName)
                        .focused($isNameFocused)
                        .font(.body)
                        .foregroundColor(theme.text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isValidName ? selectedColor.color.opacity(0.5) : 
                                    (categoryName.isEmpty ? Color.clear : theme.error.opacity(0.5)),
                                    lineWidth: 2
                                )
                                .animation(.easeOut(duration: 0.2), value: isValidName)
                        )
                    
                    if !categoryName.isEmpty && !isValidName {
                        Text("Category name already exists or is invalid")
                            .font(.caption)
                            .foregroundColor(theme.error)
                    }
                }
                
                // Color selector
                VStack(alignment: .leading, spacing: 16) {
                    Text("Category Color")
                        .font(.headline)
                        .foregroundColor(theme.text)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(CategoryColor.allCases, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                                HapticManager.shared.selectionChange()
                            }) {
                                Circle()
                                    .fill(color.gradient)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(theme.text, lineWidth: selectedColor == color ? 3 : 0)
                                            .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                                    )
                                    .scaleEffect(selectedColor == color ? 1.0 : 0.9)
                                    .animation(.smoothSpring, value: selectedColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .themedBackground(theme)
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createCategory()
                    }
                    .foregroundColor(selectedColor.color)
                    .fontWeight(.semibold)
                    .disabled(!isValidName)
                    .opacity(isValidName ? 1.0 : 0.5)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }
    
    private func createCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newCategory = categoryManager.createCustomCategory(name: trimmedName, color: selectedColor)
        categoryManager.setSelectedFilter(newCategory.id)
        dismiss()
    }
}

#Preview {
    CategorySelectorView()
        .environmentObject(CategoryManager())
        .environmentObject(TaskManager())
} 