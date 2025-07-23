//
//  TaskDetailPreviewView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct TaskDetailPreviewView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var taskManager: TaskManager
    @State var task: Task
    
    private var taskCategory: TaskCategory? {
        guard let categoryId = task.categoryId else { return nil }
        return categoryManager.category(for: categoryId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and status
            headerSection
            
            // Description if available
            if !task.description.isEmpty {
                descriptionSection
            }
            
            // Checklist Section
            if !task.checklist.isEmpty {
                checklistSection
            }
            
            // Category if assigned
            if let category = taskCategory {
                categorySection(category)
            }
            
            // Date and reminder information
            dateInfoSection
            
            // Task metadata
            metadataSection
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surfaceGradient)
                .shadow(
                    color: .black.opacity(0.1),
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.primary.opacity(0.1), lineWidth: 0)
        )
        .frame(maxWidth: 320)
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                Text("Checklist")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textSecondary)
                    .textCase(.uppercase)
            }

            ForEach(task.checklist) { item in
                HStack(spacing: 8) {
                    Button(action: {
                        // Immediate haptic feedback for responsiveness
                        HapticManager.shared.buttonTap()
                        toggleChecklistItem(item)
                    }) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(item.isCompleted ? theme.success : theme.textTertiary)
                            .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Circle())
                    .frame(width: 24, height: 24)
                    .allowsHitTesting(true)
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded { _ in
                                // Immediate haptic feedback for responsiveness
                                HapticManager.shared.buttonTap()
                                toggleChecklistItem(item)
                            }
                    )
                    
                    Text(item.title)
                        .font(.caption)
                        .foregroundColor(item.isCompleted ? theme.textSecondary : theme.text)
                        .strikethrough(item.isCompleted)
                        .opacity(item.isCompleted ? 0.7 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Completion status indicator
                ZStack {
                    Circle()
                        .fill(task.isCompleted ? theme.success : theme.surface)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(task.isCompleted ? theme.success : theme.textTertiary, lineWidth: 0)
                        )
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(task.isCompleted ? theme.textSecondary : theme.text)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)
                    
                    // Status indicator
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.caption2)
                            .foregroundColor(statusColor)
                        
                        Text(statusText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "text.alignleft")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                
                Text("Description")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textSecondary)
                    .textCase(.uppercase)
            }
            
            Text(task.description)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func categorySection(_ category: TaskCategory) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                
                Text("Category")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textSecondary)
                    .textCase(.uppercase)
            }
            
            HStack(spacing: 8) {
                if category.name.uppercased() == "URGENT" {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                } else {
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
                                    lineWidth: 0
                                )
                                .opacity(themeManager.themeMode == .serene ? 0.2 : 0.3)
                        )
                }
                
                Text(category.name)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor({
                        switch themeManager.themeMode {
                        case .kawaii:
                            return category.color.kawaiiDarkColor
                        case .serene:
                            return category.color.sereneDarkColor
                        default:
                            return category.color.darkColor
                        }
                    }())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill({
                                switch themeManager.themeMode {
                                case .kawaii:
                                    return category.color.kawaiiLightColor
                                case .serene:
                                    return category.color.sereneLightColor
                                default:
                                    // Check if current theme is coffee theme for subdued colors
                                    if theme is CoffeeTheme {
                                        return category.color.coffeeLightColor
                                    }
                                    return category.color.lightColor
                                }
                            }())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        {
                                            switch themeManager.themeMode {
                                            case .kawaii:
                                                return category.color.kawaiiColor.opacity(0.2)
                                            case .serene:
                                                return category.color.sereneColor.opacity(0.15)
                                            default:
                                                // Check if current theme is coffee theme for subdued colors
                                                if theme is CoffeeTheme {
                                                    return category.color.coffeeColor.opacity(0.15)
                                                }
                                                return category.color.color.opacity(0.2)
                                            }
                                        }(),
                                        lineWidth: 0
                                    )
                            )
                    )
            }
        }
    }
    
    private var dateInfoSection: some View {
        VStack(spacing: 8) {
            // Due date information
            if let dueDate = task.dueDate {
                dateInfoRow(
                    icon: task.isOverdue ? "exclamationmark.triangle.fill" : 
                          task.isPending ? "clock" : "calendar",
                    label: "Due Date",
                    value: formatDueDate(dueDate),
                    color: task.isOverdue ? theme.error : 
                           task.isPending ? theme.warning : theme.textSecondary
                )
            }
            
            // Reminder information
            if task.hasReminder, let reminderDate = task.reminderDate, !task.isCompleted {
                dateInfoRow(
                    icon: "bell.fill",
                    label: "Reminder",
                    value: formatReminderTime(reminderDate),
                    color: theme.warning
                )
            }
        }
    }
    
    private func dateInfoRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 12)
            
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textSecondary)
                .textCase(.uppercase)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 0)
                )
        )
    }
    
    private var metadataSection: some View {
        VStack(spacing: 6) {
            Divider()
                .background(theme.textTertiary.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Created")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textTertiary)
                        .textCase(.uppercase)
                    
                    Text(formatDate(task.createdAt))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                if task.isCompleted, let completedAt = task.completedAt {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Completed")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(theme.textTertiary)
                            .textCase(.uppercase)
                        
                        Text(formatDate(completedAt))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(theme.success)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleChecklistItem(_ item: ChecklistItem) {
        // Optimized checklist item toggle with performance considerations
        PerformanceMonitor.shared.measure("ChecklistItemToggle") {
            // Create a mutable copy of the task
            var updatedTask = task
            
            // Find and update the checklist item
            if let index = updatedTask.checklist.firstIndex(where: { $0.id == item.id }) {
                updatedTask.checklist[index].isCompleted.toggle()
                
                // Update the task through the task manager (uses batch updates for performance)
                taskManager.updateTask(updatedTask)
                
                // Haptic feedback is provided immediately in the UI layer for better responsiveness
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        if task.isCompleted {
            return "checkmark.circle.fill"
        } else if task.isOverdue {
            return "exclamationmark.triangle.fill"
        } else if task.isPending {
            return "clock.fill"
        } else {
            return "circle"
        }
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return theme.success
        } else if task.isOverdue {
            return theme.error
        } else if task.isPending {
            return theme.warning
        } else {
            return theme.textSecondary
        }
    }
    
    private var statusText: String {
        if task.isCompleted {
            return "Completed"
        } else if task.isOverdue {
            return "Overdue"
        } else if task.isPending {
            return "Pending"
        } else {
            return "No due date"
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            formatter.timeStyle = .short
            return "Tomorrow \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.timeStyle = .short
            return "Yesterday \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    private func formatReminderTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            formatter.timeStyle = .short
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 20) {
        TaskDetailPreviewView(
            task: Task(
                title: "Complete Project Proposal",
                description: "Finish the quarterly project proposal with budget analysis and timeline",
                dueDate: Date(),
                hasReminder: true
            )
        )
        
        TaskDetailPreviewView(
            task: {
                var task = Task(
                    title: "Buy Groceries",
                    description: "Get milk, bread, eggs, and vegetables for the week"
                )
                task.isCompleted = true
                task.completedAt = Date()
                return task
            }()
        )
    }
    .padding()
    .background(LightTheme().backgroundGradient)
    .environment(\.theme, LightTheme())
}