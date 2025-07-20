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
    let category: TaskCategory?
    let taskCount: Int
    
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
    
    var body: some View {
        HStack(spacing: 12) {
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
                                            return category.color.darkColor
                                        }
                                    }(),
                                    lineWidth: 0.8
                                )
                                .opacity(themeManager.themeMode == .serene ? 0.2 : 0.3)
                        )
                        .shadow(
                            color: categoryColor.opacity(themeManager.themeMode == .serene ? 0.15 : 0.2),
                            radius: themeManager.themeMode == .serene ? 0.5 : 1,
                            x: 0,
                            y: themeManager.themeMode == .serene ? 0.3 : 0.5
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
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
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