//
//  CategorySectionHeaderView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct CategorySectionHeaderView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var categoryManager: CategoryManager
    let category: TaskCategory?
    let taskCount: Int
    let onToggleCollapse: (() -> Void)?
    
    @State private var isPressed = false
    
    init(category: TaskCategory?, taskCount: Int, onToggleCollapse: (() -> Void)? = nil) {
        self.category = category
        self.taskCount = taskCount
        self.onToggleCollapse = onToggleCollapse
    }
    
    private var displayName: String {
        category?.name ?? "Uncategorized"
    }
    
    private var categoryColor: Color {
        guard let category = category else { return theme.textSecondary }
        
        // Use theme-specific colors
        switch themeManager.themeMode {
        case .kawaii:
            return category.color.kawaiiColor
        case .serene:
            return category.color.sereneColor
        default:
            // Check if current theme is coffee theme for subdued colors
            if theme is CoffeeTheme {
                return category.color.coffeeColor
            }
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
    
    private var isCollapsed: Bool {
        categoryManager.isCategoryCollapsed(category)
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                if let onToggleCollapse = onToggleCollapse {
                    onToggleCollapse()
                } else {
                    categoryManager.toggleCategoryCollapse(category)
                }
            }
            HapticManager.shared.buttonTap()
        }) {
            HStack(spacing: 12) {
                // Simple Collapse/Expand chevron with clean rotation
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                    .animation(.easeInOut(duration: 0.25), value: isCollapsed)
                    .frame(width: 12, height: 12)
            // Category icon/indicator
            if let category = category {
                if isUrgentCategory {
                    // Warning triangle for urgent category
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(categoryColor)
                        .shadow(
                            color: categoryColor.opacity(0.3),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                } else if isImportantCategory {
                    // Exclamation point for important category
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(categoryColor)
                        .shadow(
                            color: categoryColor.opacity(0.3),
                            radius: 2,
                            x: 0,
                            y: 1
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
                                // Check if current theme is coffee theme for subdued colors
                                if theme is CoffeeTheme {
                                    return category.color.coffeeGradient
                                }
                                return category.color.gradient
                            }
                        }())
                        .frame(width: 16, height: 16)
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
                                            // Check if current theme is coffee theme for subdued colors
                                            if theme is CoffeeTheme {
                                                return category.color.coffeeDarkColor
                                            }
                                            return category.color.darkColor
                                        }
                                    }(),
                                    lineWidth: 0.8
                                )
                                .opacity({
                                    if themeManager.themeMode == .serene {
                                        return 0.2
                                    } else if theme is CoffeeTheme {
                                        return 0.25 // Slightly more subdued for coffee theme
                                    } else {
                                        return 0.3
                                    }
                                }())
                        )
                        .shadow(
                            color: categoryColor.opacity({
                                if themeManager.themeMode == .serene {
                                    return 0.15
                                } else if theme is CoffeeTheme {
                                    return 0.12 // More subdued shadow for coffee theme
                                } else {
                                    return 0.2
                                }
                            }()),
                            radius: {
                                if themeManager.themeMode == .serene {
                                    return 0.5
                                } else if theme is CoffeeTheme {
                                    return 0.8 // Slightly softer shadow for coffee theme
                                } else {
                                    return 1.0
                                }
                            }(),
                            x: 0,
                            y: {
                                if themeManager.themeMode == .serene {
                                    return 0.3
                                } else if theme is CoffeeTheme {
                                    return 0.4 // Subtle shadow offset for coffee theme
                                } else {
                                    return 0.5
                                }
                            }()
                        )
                }
            } else {
                // "Uncategorized" icon
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
            
            // Category name
            Text(displayName.uppercased())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(
                    isSpecialCategory ? categoryColor : theme.textSecondary
                )
                .tracking(0.5)
            
            // Task count
            Text("\(taskCount)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(theme.surfaceSecondary)
                )
            
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.clear)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.interpolatingSpring(stiffness: 500, damping: 30), value: isPressed)
        .contentShape(Rectangle()) // Make entire area tappable
        .allowsHitTesting(true)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.interpolatingSpring(stiffness: 500, damping: 30)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.interpolatingSpring(stiffness: 500, damping: 30)) {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        CategorySectionHeaderView(
            category: TaskCategory.urgent,
            taskCount: 3
        )
        
        CategorySectionHeaderView(
            category: TaskCategory.work,
            taskCount: 5
        )
        
        CategorySectionHeaderView(
            category: nil,
            taskCount: 2
        )
    }
    .environmentObject(ThemeManager())
    .environment(\.theme, LightTheme())
}