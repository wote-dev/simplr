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
        
        // Update every 15 minutes for more responsive updates
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadTasks(for configuration: WidgetConfigurationIntent) -> [Task] {
        guard let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr"),
              let data = userDefaults.data(forKey: "SavedTasks"),
              let allTasks = try? JSONDecoder().decode([Task].self, from: data) else {
            return []
        }
        
        // Filter incomplete tasks
        var filteredTasks = allTasks.filter { !$0.isCompleted }
        
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
        
        // Sort tasks: due date tasks first, then by creation date
        filteredTasks.sort { task1, task2 in
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
        
        // Return top 3 tasks
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
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Task status indicator
            Circle()
                .fill(dotColor)
                .frame(width: family == .systemSmall ? 7 : 8, height: family == .systemSmall ? 7 : 8)
                .padding(.top, family == .systemSmall ? 4 : 5)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(family == .systemSmall ? .caption : .footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(family == .systemSmall ? 2 : 3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let dueDate = task.dueDate {
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
                    Task(title: "Review project proposal and check the latest updates from the team", description: "Check the latest updates", dueDate: Date()),
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
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small Widget")
            
            SimplrWidgetEntryView(entry: TaskEntry(
                date: Date(),
                tasks: [
                    Task(title: "Review project proposal and check the latest updates from the team", description: "Check the latest updates", dueDate: Date()),
                    Task(title: "Call dentist for appointment scheduling", description: "Schedule appointment", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())),
                    Task(title: "Buy groceries for the week including fresh produce", description: "Milk, bread, eggs")
                ],
                categories: [
                    TaskCategory(name: "Work", color: .blue),
                    TaskCategory(name: "Personal", color: .green),
                    TaskCategory(name: "Shopping", color: .orange)
                ],
                configuration: WidgetConfigurationIntent()
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium Widget")
        }
    }
}
