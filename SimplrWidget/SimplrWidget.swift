//
//  SimplrWidget.swift
//  SimplrWidget
//
//  Created by Daniel Zverev on 2/7/2025.
//

import WidgetKit
import SwiftUI

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [Task]
    let categories: [TaskCategory]
    let configuration: WidgetConfigurationIntent
}

struct TaskProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(
            date: Date(),
            tasks: [
                Task(title: "Sample Task 1", description: "This is a sample task", dueDate: Date()),
                Task(title: "Sample Task 2", description: "Another sample task"),
                Task(title: "Sample Task 3", description: "Third sample task")
            ],
            categories: [],
            configuration: WidgetConfigurationIntent()
        )
    }
    
    func snapshot(for configuration: WidgetConfigurationIntent, in context: Context) async -> TaskEntry {
        TaskEntry(
            date: Date(),
            tasks: loadTasks(for: configuration),
            categories: loadCategories(),
            configuration: configuration
        )
    }
    
    func timeline(for configuration: WidgetConfigurationIntent, in context: Context) async -> Timeline<TaskEntry> {
        let currentDate = Date()
        let tasks = loadTasks(for: configuration)
        let categories = loadCategories()
        
        let entry = TaskEntry(
            date: currentDate,
            tasks: tasks,
            categories: categories,
            configuration: configuration
        )
        
        // Update every 5 minutes for more responsive updates, especially after task completion
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadTasks(for configuration: WidgetConfigurationIntent) -> [Task] {
        guard let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr"),
              let data = userDefaults.data(forKey: "SavedTasks"),
              let allTasks = try? JSONDecoder().decode([Task].self, from: data) else {
            return []
        }
        
        // Start with all tasks, we'll handle completed tasks in the UI
        var filteredTasks = allTasks
        
        // Apply category filter if specified
        if let categoryFilter = configuration.categoryFilter, !categoryFilter.isEmpty {
            // Load categories to find the category ID
            if let categoryData = userDefaults.data(forKey: "SavedCategories"),
               let categories = try? JSONDecoder().decode([TaskCategory].self, from: categoryData) {
                if let category = categories.first(where: { $0.name == categoryFilter }) {
                    filteredTasks = filteredTasks.filter { $0.categoryId == category.id }
                }
            }
        }
        
        // Sort tasks: incomplete first (with URGENT priority), then completed (by completion date)
        filteredTasks.sort { (task1: Task, task2: Task) in
            // Prioritize incomplete tasks
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted && task2.isCompleted
            }
            
            // Both completed or both incomplete
            if task1.isCompleted && task2.isCompleted {
                // Sort completed tasks by completion date (most recent first)
                let date1 = task1.completedAt ?? task1.createdAt
                let date2 = task2.completedAt ?? task2.createdAt
                return date1 > date2
            } else {
                // For incomplete tasks, prioritize URGENT category first
                let task1IsUrgent = task1.categoryId == TaskCategory.urgent.id
                let task2IsUrgent = task2.categoryId == TaskCategory.urgent.id
                
                if task1IsUrgent != task2IsUrgent {
                    return task1IsUrgent && !task2IsUrgent
                }
                
                // Then sort by due date, then by creation date
                switch (task1.dueDate, task2.dueDate) {
                case (let date1?, let date2?):
                    return date1 < date2
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return task1.createdAt > task2.createdAt
                }
            }
        }
        
        // Return top 3 tasks (mix of incomplete and recently completed)
        return Array(filteredTasks.prefix(3))
    }
    
    private func loadCategories() -> [TaskCategory] {
        guard let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr"),
              let data = userDefaults.data(forKey: "SavedCategories"),
              let categories = try? JSONDecoder().decode([TaskCategory].self, from: data) else {
            return []
        }
        return categories
    }
}

struct SimplrWidgetEntryView: View {
    var entry: TaskProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 10) {
            // Header
            HStack {
                Text("Reminders")
                    .font(family == .systemSmall ? .subheadline : .headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if entry.tasks.isEmpty {
                // Empty state
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(family == .systemSmall ? .title3 : .title2)
                        .foregroundColor(.green)
                    Text("All caught up!")
                        .font(family == .systemSmall ? .caption : .subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text("No pending tasks")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Task list
                VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 10) {
                    ForEach(entry.tasks) { task in
                        TaskRowWidget(task: task, categories: entry.categories, family: family)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(family == .systemSmall ? 12 : 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct TaskRowWidget: View {
    let task: Task
    let categories: [TaskCategory]
    let family: WidgetFamily
    
    private var taskCategory: TaskCategory? {
        guard let categoryId = task.categoryId else { return nil }
        return categories.first { $0.id == categoryId }
    }
    
    private var dotColor: Color {
        if task.isOverdue {
            return Color.red
        } else if let category = taskCategory {
            return category.color.color
        } else {
            return Color.gray // Default color for uncategorized tasks
        }
    }
    
    private var isUrgentTask: Bool {
        guard let category = taskCategory else { return false }
        return category.name.uppercased() == "URGENT"
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Task completion button
            Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: family == .systemSmall ? 20 : 24, height: family == .systemSmall ? 20 : 24)
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(family == .systemSmall ? .system(size: 16, weight: .medium) : .system(size: 18, weight: .medium))
                            .foregroundColor(.green)
                            .contentTransition(.symbolEffect(.replace.offUp))
                            .symbolEffect(.bounce, value: task.isCompleted)
                    } else if isUrgentTask {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(family == .systemSmall ? .system(size: 16, weight: .medium) : .system(size: 18, weight: .medium))
                            .foregroundColor(.red)
                            .contentTransition(.symbolEffect(.replace.offUp))
                    } else {
                        Image(systemName: "circle")
                            .font(family == .systemSmall ? .system(size: 16, weight: .medium) : .system(size: 18, weight: .medium))
                            .foregroundColor(dotColor)
                            .contentTransition(.symbolEffect(.replace.offUp))
                    }
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: task.isCompleted)
            .accessibilityLabel(task.isCompleted ? "Mark as incomplete" : "Mark as complete")
            .accessibilityHint("Double tap to toggle task completion")
            
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(family == .systemSmall ? .caption : .footnote)
                    .fontWeight(.medium)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .lineLimit(family == .systemSmall ? 2 : 3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .strikethrough(task.isCompleted, color: .secondary)
                
                if task.isCompleted {
                    Text("Completed")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                } else if let dueDate = task.dueDate {
                    Text(dueDateText(for: dueDate))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                }
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private func dueDateText(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if date < now {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            return "\(days)d overdue"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

struct SimplrWidget: Widget {
    let kind: String = "SimplrWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WidgetConfigurationIntent.self, provider: TaskProvider()) { entry in
            SimplrWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Simplr Tasks")
        .description("View your upcoming tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct SimplrWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SimplrWidgetEntryView(entry: TaskEntry(
                date: Date(),
                tasks: [
                    Task(title: "Review project proposal", description: "Check the latest updates", dueDate: Date()),
                    Task(title: "Call dentist", description: "Schedule appointment", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())),
                    Task(title: "Buy groceries", description: "Milk, bread, eggs")
                ],
                categories: [
                    TaskCategory(name: "Work", color: .blue),
                    TaskCategory(name: "Personal", color: .green),
                    TaskCategory(name: "Shopping", color: .orange)
                ],
                configuration: WidgetConfigurationIntent()
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small Widget - Interactive")
            
            SimplrWidgetEntryView(entry: TaskEntry(
                date: Date(),
                tasks: [
                    Task(title: "Review project proposal and check updates", description: "Check the latest updates", dueDate: Date()),
                    Task(title: "Call dentist for appointment", description: "Schedule appointment", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())),
                    Task(title: "Buy groceries for the week", description: "Milk, bread, eggs")
                ],
                categories: [
                    TaskCategory(name: "Work", color: .blue),
                    TaskCategory(name: "Personal", color: .green),
                    TaskCategory(name: "Shopping", color: .orange)
                ],
                configuration: WidgetConfigurationIntent()
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium Widget - Interactive")
        }
    }
}
