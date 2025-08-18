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
    
    /// Optimized toggle action with visual feedback and haptic response
    /// Restricts interaction to only chevron, category color, and category name
    private func performToggleAction() {
        // Provide immediate visual feedback
        withAnimation(.interpolatingSpring(stiffness: 500, damping: 30)) {
            isPressed = true
        }
        
        // Reset visual state after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(stiffness: 500, damping: 30)) {
                isPressed = false
            }
        }
        
        // PERFORMANCE: Use ultra-smooth animation for task card collapse/expand
        withAnimation(.ultraSmoothTaskCard(duration: 0.35)) {
            if let onToggleCollapse = onToggleCollapse {
                onToggleCollapse()
            } else {
                categoryManager.toggleCategoryCollapse(category)
            }
        }
        
        // Provide haptic feedback for successful interaction
        HapticManager.shared.selectionChange()
    }
    
    /// Optimized theme-adaptive chevron color with performance caching
    private var themeAdaptiveChevronColor: Color {
        // Enhanced theme-specific chevron colors for better visibility and consistency
        switch themeManager.themeMode {
        case .kawaii:
            // Softer, more playful color for kawaii theme
            return theme.textSecondary.opacity(0.8)
        case .serene:
            // Calmer, more subdued color for serene theme
            return theme.textSecondary.opacity(0.75)
        default:
            // Check for specific theme types for optimal contrast
            if theme is CoffeeTheme {
                // Warmer tone for coffee theme
                return theme.textSecondary.opacity(0.85)
            } else if theme is DarkBlueTheme {
                // Enhanced visibility for dark themes
                return theme.textSecondary.opacity(0.9)
            } else {
                // Standard visibility for light themes
                return theme.textSecondary
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Theme-adaptive Collapse/Expand chevron with optimized performance
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeAdaptiveChevronColor)
                .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                .animation(.adaptiveSmooth, value: isCollapsed)
                .frame(width: 12, height: 12)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .contentShape(Rectangle())
                .onTapGesture {
                    performToggleAction()
                }
            // Category icon/indicator
            Group {
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
                                            return 0.35 // Enhanced visibility for serene theme
                                        } else if theme is CoffeeTheme {
                                            return 0.4 // Enhanced visibility for coffee theme
                                        } else {
                                            return 0.3
                                        }
                                    }())
                            )
                            .shadow(
                                color: categoryColor.opacity({
                                    if themeManager.themeMode == .serene {
                                        return 0.25 // Enhanced shadow visibility for serene theme
                                    } else if theme is CoffeeTheme {
                                        return 0.22 // Enhanced shadow visibility for coffee theme
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
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .contentShape(Rectangle())
            .onTapGesture {
                performToggleAction()
            }
            
            // Category name
            Text(displayName.uppercased())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(
                    isSpecialCategory ? categoryColor : theme.textSecondary
                )
                .tracking(0.5)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .contentShape(Rectangle())
                .onTapGesture {
                    performToggleAction()
                }
            
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
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.clear)
        .animation(.adaptiveSnappy, value: isPressed)
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