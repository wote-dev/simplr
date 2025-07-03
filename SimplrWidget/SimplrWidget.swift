//
//  SimplrWidget.swift
//  SimplrWidget
//
//  Created by Daniel Zverev on 2/7/2025.
//

import WidgetKit
import SwiftUI
import Foundation

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [Task]
    let categories: [TaskCategory]
}

struct TaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: getSampleTasks(), categories: getSampleCategories())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let (tasks, categories) = getTasksAndCategories()
        let entry = TaskEntry(date: Date(), tasks: tasks, categories: categories)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> ()) {
        let currentDate = Date()
        let (tasks, categories) = getTasksAndCategories()
        let entry = TaskEntry(date: currentDate, tasks: tasks, categories: categories)
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getTasksAndCategories() -> ([Task], [TaskCategory]) {
        let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr")
        
        // Load tasks
        let tasks: [Task]
        if let data = userDefaults?.data(forKey: "SavedTasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            let incompleteTasks = decodedTasks.filter { !$0.isCompleted }
            let sortedTasks = incompleteTasks.sorted { task1, task2 in
                // Sort by due date, with tasks without due dates at the end
                switch (task1.dueDate, task2.dueDate) {
                case (let date1?, let date2?):
                    return date1 < date2
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                case (nil, nil):
                    return task1.createdAt < task2.createdAt
                }
            }
            tasks = Array(sortedTasks.prefix(3))
        } else {
            tasks = getSampleTasks()
        }
        
        // Load categories
        let categories: [TaskCategory]
        if let data = userDefaults?.data(forKey: "SavedCategories"),
           let decodedCategories = try? JSONDecoder().decode([TaskCategory].self, from: data) {
            categories = decodedCategories
        } else {
            categories = getSampleCategories()
        }
        
        return (tasks, categories)
    }
    
    private func getSampleTasks() -> [Task] {
        let workCategory = TaskCategory(name: "Work", color: .blue)
        let personalCategory = TaskCategory(name: "Personal", color: .green)
        
        return [
            Task(title: "Review project proposal", description: "Check the new client requirements", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: workCategory.id),
            Task(title: "Team meeting", description: "Weekly sync with the development team", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()), categoryId: workCategory.id),
            Task(title: "Update documentation", description: "Add new API endpoints to docs", categoryId: personalCategory.id)
        ]
    }
    
    private func getSampleCategories() -> [TaskCategory] {
        [
            TaskCategory(name: "Work", color: .blue),
            TaskCategory(name: "Personal", color: .green),
            TaskCategory(name: "Shopping", color: .orange),
            TaskCategory(name: "Health", color: .red),
            TaskCategory(name: "Learning", color: .purple),
            TaskCategory(name: "Travel", color: .indigo)
        ]
    }
}

struct SimplrWidgetEntryView: View {
    var entry: TaskProvider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Upcoming Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Tasks
            if entry.tasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("All caught up!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.tasks.prefix(3), id: \.id) { task in
                        TaskRowWidget(task: task, categories: entry.categories)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct TaskRowWidget: View {
    let task: Task
    let categories: [TaskCategory]
    @Environment(\.colorScheme) var colorScheme
    
    private var taskCategory: TaskCategory? {
        guard let categoryId = task.categoryId else { return nil }
        return categories.first { $0.id == categoryId }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Category indicator or default circle
            Circle()
                .fill(categoryIndicatorColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .lineLimit(1)
                    
                    // Category badge for widget
                    if let category = taskCategory {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(category.color.color)
                                .frame(width: 4, height: 4)
                            Text(category.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(category.color.color)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(category.color.lightColor)
                        )
                    }
                    
                    Spacer()
                }
                
                if let dueDate = task.dueDate {
                    Text(formatDueDate(dueDate))
                        .font(.caption)
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                } else {
                    Text("No due date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    private var categoryIndicatorColor: Color {
        if let category = taskCategory {
            return category.color.color
        } else if task.dueDate != nil && task.dueDate! < Date() {
            return Color.red
        } else {
            return Color.blue
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct SimplrWidget: Widget {
    let kind: String = "SimplrWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
            SimplrWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Simplr Tasks")
        .description("View your top 3 upcoming tasks at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    SimplrWidget()
} timeline: {
    let workCategory = TaskCategory(name: "Work", color: .blue)
    let personalCategory = TaskCategory(name: "Personal", color: .green)
    
    TaskEntry(date: .now, tasks: [
        Task(title: "Review project proposal", description: "Check the new client requirements", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: workCategory.id),
        Task(title: "Team meeting", description: "Weekly sync with the development team", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()), categoryId: workCategory.id),
        Task(title: "Update documentation", description: "Add new API endpoints to docs", categoryId: personalCategory.id)
    ], categories: [workCategory, personalCategory])
}