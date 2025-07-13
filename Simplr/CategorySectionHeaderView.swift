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
        
        // Use kawaii colors when in kawaii theme mode
        if themeManager.themeMode == .kawaii {
            return category.color.kawaiiColor
        } else {
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
                        .foregroundColor(
                            themeManager.themeMode == .kawaii ? category.color.kawaiiColor : category.color.color
                        )
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
                        .foregroundColor(
                            themeManager.themeMode == .kawaii ? category.color.kawaiiColor : category.color.color
                        )
                        .shadow(
                            color: categoryColor.opacity(0.3),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                } else {
                    // Regular circle for other categories
                    Circle()
                        .fill(themeManager.themeMode == .kawaii ? category.color.kawaiiGradient : category.color.gradient)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(
                                    themeManager.themeMode == .kawaii ? category.color.kawaiiDarkColor : category.color.darkColor,
                                    lineWidth: 1
                                )
                                .opacity(0.3)
                        )
                        .shadow(
                            color: categoryColor.opacity(0.2),
                            radius: 1,
                            x: 0,
                            y: 0.5
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