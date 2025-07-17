//
//  WidgetIntents.swift
//  SimplrWidget
//
//  Created by Daniel Zverev on 2/7/2025.
//

import AppIntents
import Foundation
import WidgetKit

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
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Task ID")
    var taskId: String
    
    init(taskId: String) {
        self.taskId = taskId
    }

    init() {
        self.taskId = ""
    }
    
    func perform() async throws -> some IntentResult {
        print("[Widget] ToggleTaskIntent called for task ID: \(taskId)")
        
        // Access shared UserDefaults
        guard let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr") else {
            print("[Widget] Error: Unable to access shared UserDefaults")
            throw WidgetError.unableToAccessSharedData
        }
        
        // Load tasks
        guard let data = userDefaults.data(forKey: "SavedTasks"),
              var tasks = try? JSONDecoder().decode([Task].self, from: data) else {
            print("[Widget] Error: Unable to load tasks from UserDefaults")
            throw WidgetError.unableToLoadTasks
        }
        
        print("[Widget] Loaded \(tasks.count) tasks from UserDefaults")
        
        // Find and toggle the task
        guard let taskIndex = tasks.firstIndex(where: { $0.id.uuidString == taskId }) else {
            print("[Widget] Error: Task not found with ID: \(taskId)")
            throw WidgetError.taskNotFound
        }
        
        let wasCompleted = tasks[taskIndex].isCompleted
        let taskTitle = tasks[taskIndex].title
        
        print("[Widget] Found task: '\(taskTitle)', currently completed: \(wasCompleted)")
        
        tasks[taskIndex].isCompleted.toggle()
        
        if tasks[taskIndex].isCompleted {
            tasks[taskIndex].completedAt = Date()
        } else {
            tasks[taskIndex].completedAt = nil
        }
        
        print("[Widget] Task toggled to completed: \(tasks[taskIndex].isCompleted)")
        
        // Save updated tasks
        guard let encodedData = try? JSONEncoder().encode(tasks) else {
            print("[Widget] Error: Unable to encode tasks")
            throw WidgetError.unableToLoadTasks
        }
        
        userDefaults.set(encodedData, forKey: "SavedTasks")
        userDefaults.synchronize() // Force immediate sync
        print("[Widget] Tasks saved to UserDefaults")
        
        // Force immediate widget refresh
        WidgetCenter.shared.reloadAllTimelines()
        print("[Widget] Widget timelines reloaded immediately")
        
        // Also schedule a delayed refresh to ensure the update is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            WidgetCenter.shared.reloadAllTimelines()
            print("[Widget] Secondary widget refresh completed")
        }
        
        // Provide user feedback with better messaging
        let message = tasks[taskIndex].isCompleted ? 
            "✓ Task completed!" : 
            "↻ Task reopened"
        
        print("[Widget] Task toggle completed successfully")
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