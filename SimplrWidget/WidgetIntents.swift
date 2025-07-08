//
//  WidgetIntents.swift
//  SimplrWidget
//
//  Created by Daniel Zverev on 2/7/2025.
//

import AppIntents
import Foundation

enum WidgetError: Error, LocalizedError {
    case unableToAccessSharedData
    case unableToLoadTasks
    case taskNotFound
    
    var errorDescription: String? {
        switch self {
        case .unableToAccessSharedData:
            return "Unable to access shared data"
        case .unableToLoadTasks:
            return "Unable to load tasks"
        case .taskNotFound:
            return "Task not found"
        }
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task Completion"
    static var description = IntentDescription("Mark a task as completed or incomplete")
    
    @Parameter(title: "Task ID")
    var taskId: String
    
    func perform() async throws -> some IntentResult {
        // Access shared UserDefaults
        guard let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr") else {
            throw WidgetError.unableToAccessSharedData
        }
        
        // Load tasks
        guard let data = userDefaults.data(forKey: "SavedTasks"),
              var tasks = try? JSONDecoder().decode([Task].self, from: data) else {
            throw WidgetError.unableToLoadTasks
        }
        
        // Find and toggle the task
        guard let taskIndex = tasks.firstIndex(where: { $0.id.uuidString == taskId }) else {
            throw WidgetError.taskNotFound
        }
        
        tasks[taskIndex].isCompleted.toggle()
        if tasks[taskIndex].isCompleted {
            tasks[taskIndex].completedAt = Date()
        } else {
            tasks[taskIndex].completedAt = nil
        }
        
        // Save updated tasks
        if let encodedData = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encodedData, forKey: "SavedTasks")
        }
        
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct AddQuickTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Quick Task"
    static var description = IntentDescription("Add a new task quickly")
    
    @Parameter(title: "Task Title")
    var title: String
    
    func perform() async throws -> some IntentResult {
        // Access shared UserDefaults
        guard let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr") else {
            throw WidgetError.unableToAccessSharedData
        }
        
        // Load existing tasks
        var tasks: [Task] = []
        if let data = userDefaults.data(forKey: "SavedTasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decodedTasks
        }
        
        // Create new task
        let newTask = Task(title: title, description: "", dueDate: nil)
        tasks.append(newTask)
        
        // Save updated tasks
        if let encodedData = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encodedData, forKey: "SavedTasks")
        }
        
        return .result()
    }
}

// MARK: - Widget Configuration Intent
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct WidgetConfigurationIntent: AppIntents.WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    static var description = IntentDescription("Configure your Simplr widget")
    
    @Parameter(title: "Show Category", default: nil)
    var categoryFilter: String?
    
    @Parameter(title: "Widget Type", default: .today)
    var widgetType: WidgetTypeOption
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$widgetType) tasks") {
            \.$categoryFilter
        }
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum WidgetTypeOption: String, AppEnum {
    case today = "today"
    case upcoming = "upcoming"
    case nextTask = "next"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Widget Type")
    static var caseDisplayRepresentations: [WidgetTypeOption: DisplayRepresentation] = [
        .today: "Today's Tasks",
        .upcoming: "Upcoming Tasks",
        .nextTask: "Next Task"
    ]
}