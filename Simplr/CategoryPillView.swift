//
//  CategoryPillView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct CategoryPillView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    let category: TaskCategory?
    let isSelected: Bool
    let taskCount: Int?
    let action: () -> Void
    @State private var isPressed = false
    @State private var pulsateScale: CGFloat = 1.0
    @State private var pulsateOpacity: Double = 1.0
    
    private var displayName: String {
        category?.name ?? "All"
    }
    
    private var categoryColor: Color {
        guard let category = category else { return theme.textSecondary }
        
        switch themeManager.themeMode {
        case .kawaii:
            return category.color.kawaiiColor
        case .serene:
            return category.color.sereneColor
        default:
            return category.color.color
        }
    }
    
    private var isUrgentCategory: Bool {
        category?.name == "URGENT"
    }
    
    private var isImportantCategory: Bool {
        category?.name == "IMPORTANT"
    }
    
    private var isSpecialCategory: Bool {
        isUrgentCategory || isImportantCategory
    }
    
    private var backgroundColor: Color {
        if isSelected {
            guard let category = category else { return theme.surface }
            
            switch themeManager.themeMode {
            case .kawaii:
                return category.color.kawaiiLightColor
            case .serene:
                return category.color.sereneLightColor
            default:
                return category.color.lightColor
            }
        } else {
            return theme.surface
        }
    }
    
    private var textColor: Color {
        if isSelected {
            guard let category = category else { return theme.text }
            
            switch themeManager.themeMode {
            case .kawaii:
                return category.color.kawaiiDarkColor
            case .serene:
                return category.color.sereneDarkColor
            default:
                return category.color.darkColor
            }
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
                    if isUrgentCategory {
                        // Warning triangle for urgent category
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(categoryColor)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                            .scaleEffect(pulsateScale)
                            .opacity(pulsateOpacity)
                            .animation(.smoothSpring, value: isSelected)
                            .animation(
                                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: pulsateScale
                            )
                    } else if isImportantCategory {
                        // Exclamation point for important category
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(categoryColor)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                            .scaleEffect(pulsateScale)
                            .opacity(pulsateOpacity)
                            .animation(.smoothSpring, value: isSelected)
                            .animation(
                                Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                                value: pulsateScale
                            )
                    } else {
                        // Regular circle for other categories
                        Circle()
                            .fill({
                                switch themeManager.themeMode {
                                case .kawaii:
                                    return category.color.kawaiiGradient
                                case .serene:
                                    return category.color.sereneGradient
                                default:
                                    return category.color.gradient
                                }
                            }())
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(
                                        {
                                            switch themeManager.themeMode {
                                            case .kawaii:
                                                return category.color.kawaiiDarkColor
                                            case .serene:
                                                return category.color.sereneDarkColor
                                            default:
                                                return category.color.darkColor
                                            }
                                        }(),
                                        lineWidth: 0.8
                                    )
                                    .opacity(themeManager.themeMode == .serene ? 0.2 : 0.3)
                            )
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                            .animation(.smoothSpring, value: isSelected)
                    }
                } else {
                    // "All" category icon
                    Image(systemName: "list.bullet")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(textColor)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.smoothSpring, value: isSelected)
                }
                
                // Category name (hide for urgent category)
                if !isUrgentCategory {
                    Text(displayName)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(textColor)
                        .animation(.easeOut(duration: 0.2), value: isSelected)
                }
                
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
                    .fill(Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? categoryColor.opacity(0.3) : Color.clear,
                                lineWidth: 0.8
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .scaleEffect(isSpecialCategory ? pulsateScale : 1.0)
            .animation(.interpolatingSpring(stiffness: 600, damping: 30), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {
            // Long press action could be used for category editing
        }
        .onAppear {
            if isUrgentCategory {
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    pulsateScale = 1.05
                    pulsateOpacity = 0.8
                }
            } else if isImportantCategory {
                withAnimation(
                    Animation.easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: true)
                ) {
                    pulsateScale = 1.03
                    pulsateOpacity = 0.85
                }
            }
        }
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
                            .stroke(theme.textTertiary.opacity(0.3), style: StrokeStyle(lineWidth: 0.8, dash: [4, 4]))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .clipped()
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
                .onTapGesture {
                    // Dismiss keyboard when tapping header area
                    isNameFocused = false
                    hideKeyboard()
                }
                
                // Category name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category Name")
                        .font(.headline)
                        .foregroundColor(theme.text)
                    
                    TextField("Enter category name", text: $categoryName)
                        .focused($isNameFocused)
                        .font(.body)
                        .foregroundColor(theme.text)
                        .textFieldStyle(.plain)
                        .submitLabel(.done)
                        .autocorrectionDisabled(false)
                        .textInputAutocapitalization(.words)
                        .textSelection(.enabled)
                        .selectionDisabled(false)
                        .onSubmit {
                            if isValidName {
                                createCategory()
                            }
                        }
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
                                    lineWidth: 0.8
                                )
                                .animation(.easeOut(duration: 0.2), value: isValidName)
                        )
                        .contentShape(Rectangle())
                    
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
            .onTapGesture {
                // Dismiss keyboard when tapping background
                isNameFocused = false
                hideKeyboard()
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(theme.background == .black || theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? .dark : .light, for: .navigationBar)
            .toolbarBackground(theme.surface.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    CategorySelectorView()
        .environmentObject(CategoryManager())
        .environmentObject(TaskManager())
}