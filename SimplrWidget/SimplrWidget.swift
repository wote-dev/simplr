//
//  SimplrWidget.swift
//  SimplrWidget
//
//  Created by Daniel Zverev on 2/7/2025.
//

import WidgetKit
import SwiftUI
import Foundation

#if canImport(AppIntents)
import AppIntents
#endif

struct TaskEntry: TimelineEntry {
    let date: Date
    let nextTask: Task?
    let todayTasks: [Task]
    let weekTasks: [Task]
    let categories: [TaskCategory]
}

// MARK: - Timeline Providers

@available(iOS 16.0, *)
struct IntentTaskProvider: IntentTimelineProvider {
    typealias Entry = TaskEntry
    typealias Intent = WidgetConfigurationIntent
    
    func placeholder(in context: Context) -> TaskEntry {
        let sampleTasks = getSampleTasks()
        let sampleCategories = getSampleCategories()
        return TaskEntry(
            date: Date(),
            nextTask: sampleTasks.first,
            todayTasks: Array(sampleTasks.prefix(3)),
            weekTasks: sampleTasks,
            categories: sampleCategories
        )
    }
    
    func getSnapshot(for configuration: WidgetConfigurationIntent, in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let (allTasks, categories) = getTasksAndCategories()
        let entry = createEntry(from: allTasks, categories: categories)
        completion(entry)
    }
    
    func getTimeline(for configuration: WidgetConfigurationIntent, in context: Context, completion: @escaping (Timeline<TaskEntry>) -> ()) {
        let currentDate = Date()
        let (allTasks, categories) = getTasksAndCategories()
        let entry = createEntry(from: allTasks, categories: categories)
        
        // Create multiple entries for better timeline management
        var entries: [TaskEntry] = [entry]
        
        // Add entries for the next few hours to handle task due date changes
        for hourOffset in 1...6 {
            if let futureDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate) {
                let futureEntry = TaskEntry(
                    date: futureDate,
                    nextTask: entry.nextTask,
                    todayTasks: entry.todayTasks,
                    weekTasks: entry.weekTasks,
                    categories: entry.categories
                )
                entries.append(futureEntry)
            }
        }
        
        // Update every hour, but allow for more frequent updates if needed
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createEntry(from allTasks: [Task], categories: [TaskCategory]) -> TaskEntry {
        let calendar = Calendar.current
        let now = Date()
        
        // Get next task (highest priority incomplete task)
        let nextTask = allTasks.first
        
        // Get today's tasks
        let todayTasks = allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDateInToday(dueDate)
        }
        
        // Get this week's tasks
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
        
        let weekTasks = allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= startOfWeek && dueDate <= endOfWeek
        }
        
        return TaskEntry(
            date: now,
            nextTask: nextTask,
            todayTasks: Array(todayTasks.prefix(5)),
            weekTasks: Array(weekTasks.prefix(10)),
            categories: categories
        )
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
            tasks = sortedTasks
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
            Task(title: "Update documentation", description: "Add new API endpoints to docs", categoryId: personalCategory.id),
            Task(title: "Buy groceries", description: "Milk, bread, eggs", dueDate: Date(), categoryId: personalCategory.id),
            Task(title: "Call dentist", description: "Schedule cleaning appointment", dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()), categoryId: personalCategory.id)
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

struct TaskProvider: TimelineProvider {
    typealias Entry = TaskEntry
    
    func placeholder(in context: Context) -> TaskEntry {
        let sampleTasks = getSampleTasks()
        let sampleCategories = getSampleCategories()
        return TaskEntry(
            date: Date(),
            nextTask: sampleTasks.first,
            todayTasks: Array(sampleTasks.prefix(3)),
            weekTasks: sampleTasks,
            categories: sampleCategories
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let (allTasks, categories) = getTasksAndCategories()
        let entry = createEntry(from: allTasks, categories: categories)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> ()) {
        let currentDate = Date()
        let (allTasks, categories) = getTasksAndCategories()
        let entry = createEntry(from: allTasks, categories: categories)
        
        // Create multiple entries for better timeline management
        var entries: [TaskEntry] = [entry]
        
        // Add entries for the next few hours to handle task due date changes
        for hourOffset in 1...6 {
            if let futureDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate) {
                let futureEntry = TaskEntry(
                    date: futureDate,
                    nextTask: entry.nextTask,
                    todayTasks: entry.todayTasks,
                    weekTasks: entry.weekTasks,
                    categories: entry.categories
                )
                entries.append(futureEntry)
            }
        }
        
        // Update every hour, but allow for more frequent updates if needed
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createEntry(from allTasks: [Task], categories: [TaskCategory]) -> TaskEntry {
        let calendar = Calendar.current
        let now = Date()
        
        // Get next task (highest priority incomplete task)
        let nextTask = allTasks.first
        
        // Get today's tasks
        let todayTasks = allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDateInToday(dueDate)
        }
        
        // Get this week's tasks
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
        
        let weekTasks = allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= startOfWeek && dueDate <= endOfWeek
        }
        
        return TaskEntry(
            date: now,
            nextTask: nextTask,
            todayTasks: Array(todayTasks.prefix(5)),
            weekTasks: Array(weekTasks.prefix(10)),
            categories: categories
        )
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
            tasks = sortedTasks
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
            Task(title: "Update documentation", description: "Add new API endpoints to docs", categoryId: personalCategory.id),
            Task(title: "Buy groceries", description: "Milk, bread, eggs", dueDate: Date(), categoryId: personalCategory.id),
            Task(title: "Call dentist", description: "Schedule cleaning appointment", dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()), categoryId: personalCategory.id)
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
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            case .accessoryCircular:
                AccessoryCircularView(entry: entry)
            case .accessoryRectangular:
                AccessoryRectangularView(entry: entry)
            case .accessoryInline:
                AccessoryInlineView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
    }
}

// MARK: - Small Widget (Next Task)
struct SmallWidgetView: View {
    let entry: TaskEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Next")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                Spacer()
            }
            
            Spacer()
            
            // Next task or empty state
            if let nextTask = entry.nextTask {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(nextTask.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            if let dueDate = nextTask.dueDate {
                                Text(formatDueDate(dueDate))
                                    .font(.caption)
                                    .foregroundColor(dueDate < Date() ? .red : .secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Interactive completion button for iOS 16+
                        if #available(iOS 16.0, *) {
                            Button(intent: ToggleTaskIntent(taskId: nextTask.id.uuidString)) {
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Category indicator
                    if let categoryId = nextTask.categoryId,
                       let category = entry.categories.first(where: { $0.id == categoryId }) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(category.color.color)
                                .frame(width: 6, height: 6)
                            Text(category.name)
                                .font(.caption2)
                                .foregroundColor(category.color.color)
                        }
                    }
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("All done!")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(12)
    }
}

// MARK: - Medium Widget (Today's Tasks)
struct MediumWidgetView: View {
    let entry: TaskEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Today")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                Spacer()
                
                // Add quick task button for iOS 16+
                if #available(iOS 16.0, *) {
                    Button(intent: AddQuickTaskIntent(title: "New Task")) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                
                Text("\(entry.todayTasks.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                    )
            }
            .padding(.bottom, 4)
            
            // Today's tasks
            if entry.todayTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sun.max")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("No tasks today!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.todayTasks.prefix(3), id: \.id) { task in
                        TaskRowWidget(task: task, categories: entry.categories, isCompact: true)
                    }
                    
                    if entry.todayTasks.count > 3 {
                        Text("+ \(entry.todayTasks.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
    }
}

// MARK: - Large Widget (Week Overview)
struct LargeWidgetView: View {
    let entry: TaskEntry
    @Environment(\.colorScheme) var colorScheme
    
    private var weekDays: [(String, [Task])] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start ?? entry.date
        
        var days: [(String, [Task])] = []
        
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                let dayName = calendar.isDateInToday(day) ? "Today" : 
                             calendar.isDateInTomorrow(day) ? "Tomorrow" :
                             DateFormatter().weekdaySymbols[calendar.component(.weekday, from: day) - 1].prefix(3).capitalized
                
                let tasksForDay = entry.weekTasks.filter { task in
                    guard let dueDate = task.dueDate else { return false }
                    return calendar.isDate(dueDate, inSameDayAs: day)
                }
                
                days.append((String(dayName), tasksForDay))
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "calendar.week")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("This Week")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                Spacer()
                
                Text("\(entry.weekTasks.count) tasks")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                    )
            }
            .padding(.bottom, 4)
            
            // Week grid
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, dayData in
                    let (dayName, tasks) = dayData
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(dayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(dayName == "Today" ? .blue : .secondary)
                            
                            Spacer()
                            
                            if !tasks.isEmpty {
                                Text("\(tasks.count)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(
                                        Circle()
                                            .fill(Color.secondary.opacity(0.2))
                                    )
                            }
                        }
                        
                        if tasks.isEmpty {
                            HStack {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 4, height: 4)
                                Text("No tasks")
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.7))
                                Spacer()
                            }
                        } else {
                            ForEach(tasks.prefix(2), id: \.id) { task in
                                HStack(spacing: 6) {
                                    // Category indicator
                                    Circle()
                                        .fill(getCategoryColor(for: task))
                                        .frame(width: 4, height: 4)
                                    
                                    Text(task.title)
                                        .font(.caption2)
                                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                }
                            }
                            
                            if tasks.count > 2 {
                                HStack {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 4, height: 4)
                                    Text("+ \(tasks.count - 2) more")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    
                    if index < weekDays.count - 1 {
                        Divider()
                            .opacity(0.3)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
    }
    
    private func getCategoryColor(for task: Task) -> Color {
        guard let categoryId = task.categoryId,
              let category = entry.categories.first(where: { $0.id == categoryId }) else {
            return task.isOverdue ? .red : .blue
        }
        return category.color.color
    }
}

// MARK: - Accessory Widgets (Lock Screen)

struct AccessoryCircularView: View {
    let entry: TaskEntry
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.blue.gradient)
            
            VStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("\(entry.todayTasks.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .widgetAccentable()
    }
}

struct AccessoryRectangularView: View {
    let entry: TaskEntry
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "target")
                .font(.title3)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                if let nextTask = entry.nextTask {
                    Text(nextTask.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let dueDate = nextTask.dueDate {
                        Text(formatDueDate(dueDate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("All done!")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
        }
        .widgetAccentable()
    }
}

struct AccessoryInlineView: View {
    let entry: TaskEntry
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "target")
            
            if let nextTask = entry.nextTask {
                Text(nextTask.title)
                    .lineLimit(1)
            } else {
                Text("All tasks completed")
            }
        }
        .widgetAccentable()
    }
}

struct TaskRowWidget: View {
    let task: Task
    let categories: [TaskCategory]
    let isCompact: Bool
    @Environment(\.colorScheme) var colorScheme
    
    init(task: Task, categories: [TaskCategory], isCompact: Bool = false) {
        self.task = task
        self.categories = categories
        self.isCompact = isCompact
    }
    
    private var taskCategory: TaskCategory? {
        guard let categoryId = task.categoryId else { return nil }
        return categories.first { $0.id == categoryId }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Category indicator or default circle
            Circle()
                .fill(categoryIndicatorColor)
                .frame(width: isCompact ? 6 : 8, height: isCompact ? 6 : 8)
                .padding(.top, isCompact ? 4 : 6)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(isCompact ? .caption : .subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Category badge for widget (only if not compact)
                    if !isCompact, let category = taskCategory {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(category.color.color)
                                .frame(width: 3, height: 3)
                            Text(category.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(category.color.color)
                        }
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(category.color.lightColor)
                        )
                    }
                }
                
                if let dueDate = task.dueDate {
                    Text(formatDueDate(dueDate))
                        .font(.caption2)
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                } else if !isCompact {
                    Text("No due date")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, isCompact ? 1 : 2)
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
}

// MARK: - Date Formatting Helper
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

struct SimplrWidget: Widget {
    let kind: String = "SimplrWidget"
    
    var body: some WidgetConfiguration {
        if #available(iOS 16.0, *) {
            return IntentConfiguration(kind: kind, intent: WidgetConfigurationIntent.self, provider: IntentTaskProvider()) { entry in
                SimplrWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            }
            .configurationDisplayName("Simplr Tasks")
            .description("View and manage your tasks at a glance.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
            .contentMarginsDisabled()
        } else {
            return StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
                SimplrWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            }
            .configurationDisplayName("Simplr Tasks")
            .description("View your tasks at a glance.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
            .contentMarginsDisabled()
        }
    }
}

#Preview(as: .systemSmall) {
    SimplrWidget()
} timeline: {
    let workCategory = TaskCategory(name: "Work", color: .blue)
    let personalCategory = TaskCategory(name: "Personal", color: .green)
    
    TaskEntry(
        date: .now,
        nextTask: Task(title: "Review project proposal", description: "Check the new client requirements", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: workCategory.id),
        todayTasks: [
            Task(title: "Buy groceries", description: "Milk, bread, eggs", dueDate: Date(), categoryId: personalCategory.id)
        ],
        weekTasks: [
            Task(title: "Review project proposal", description: "Check the new client requirements", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: workCategory.id),
            Task(title: "Team meeting", description: "Weekly sync with the development team", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()), categoryId: workCategory.id)
        ],
        categories: [workCategory, personalCategory]
    )
}

#Preview(as: .systemMedium) {
    SimplrWidget()
} timeline: {
    let workCategory = TaskCategory(name: "Work", color: .blue)
    let personalCategory = TaskCategory(name: "Personal", color: .green)
    
    TaskEntry(
        date: .now,
        nextTask: Task(title: "Review project proposal", description: "Check the new client requirements", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: workCategory.id),
        todayTasks: [
            Task(title: "Buy groceries", description: "Milk, bread, eggs", dueDate: Date(), categoryId: personalCategory.id),
            Task(title: "Call dentist", description: "Schedule cleaning", dueDate: Date(), categoryId: personalCategory.id)
        ],
        weekTasks: [
            Task(title: "Review project proposal", description: "Check the new client requirements", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: workCategory.id),
            Task(title: "Team meeting", description: "Weekly sync with the development team", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()), categoryId: workCategory.id)
        ],
        categories: [workCategory, personalCategory]
    )
}

#Preview(as: .systemLarge) {
    SimplrWidget()
} timeline: {
    let workCategory = TaskCategory(name: "Work", color: .blue)
    let personalCategory = TaskCategory(name: "Personal", color: .green)
    
    TaskEntry(
        date: .now,
        nextTask: Task(title: "Review project proposal", description: "Check the new client requirements", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: workCategory.id),
        todayTasks: [
            Task(title: "Buy groceries", description: "Milk, bread, eggs", dueDate: Date(), categoryId: personalCategory.id)
        ],
        weekTasks: [
            Task(title: "Review project proposal", description: "Check the new client requirements", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: workCategory.id),
            Task(title: "Team meeting", description: "Weekly sync with the development team", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()), categoryId: workCategory.id),
            Task(title: "Update documentation", description: "Add new API endpoints to docs", dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()), categoryId: personalCategory.id),
            Task(title: "Buy groceries", description: "Milk, bread, eggs", dueDate: Date(), categoryId: personalCategory.id),
            Task(title: "Call dentist", description: "Schedule cleaning appointment", dueDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()), categoryId: personalCategory.id)
        ],
        categories: [workCategory, personalCategory]
    )
}

#Preview(as: .accessoryCircular) {
    SimplrWidget()
} timeline: {
    let workCategory = TaskCategory(name: "Work", color: .blue)
    let personalCategory = TaskCategory(name: "Personal", color: .green)
    
    TaskEntry(
        date: .now,
        nextTask: Task(title: "Review project proposal", description: "Check the new client requirements", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: workCategory.id),
        todayTasks: [
            Task(title: "Buy groceries", description: "Milk, bread, eggs", dueDate: Date(), categoryId: personalCategory.id),
            Task(title: "Call dentist", description: "Schedule cleaning", dueDate: Date(), categoryId: personalCategory.id)
        ],
        weekTasks: [],
        categories: [workCategory, personalCategory]
    )
}

#Preview(as: .accessoryRectangular) {
    SimplrWidget()
} timeline: {
    let workCategory = TaskCategory(name: "Work", color: .blue)
    let personalCategory = TaskCategory(name: "Personal", color: .green)
    
    TaskEntry(
        date: .now,
        nextTask: Task(title: "Review project proposal", description: "Check the new client requirements", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: workCategory.id),
        todayTasks: [
            Task(title: "Buy groceries", description: "Milk, bread, eggs", dueDate: Date(), categoryId: personalCategory.id)
        ],
        weekTasks: [],
        categories: [workCategory, personalCategory]
    )
}

#Preview(as: .accessoryInline) {
    SimplrWidget()
} timeline: {
    let workCategory = TaskCategory(name: "Work", color: .blue)
    let personalCategory = TaskCategory(name: "Personal", color: .green)
    
    TaskEntry(
        date: .now,
        nextTask: Task(title: "Review project proposal", description: "Check the new client requirements", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: workCategory.id),
        todayTasks: [],
        weekTasks: [],
        categories: [workCategory, personalCategory]
    )
}