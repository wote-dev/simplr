//
//  TaskManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import Foundation
import UserNotifications
import UIKit

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    
    private let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr") ?? UserDefaults.standard
    private let tasksKey = "SavedTasks"
    
    // Reference to CategoryManager for Spotlight integration
    private var categoryManager: CategoryManager?
    
    init() {
        loadTasks()
        requestNotificationPermission()
        setupNotificationHandling()
    }
    
    // MARK: - Spotlight Integration Setup
    
    /// Set the category manager reference for Spotlight integration
    func setCategoryManager(_ categoryManager: CategoryManager) {
        self.categoryManager = categoryManager
        // Re-index all tasks with category information
        updateSpotlightIndex()
    }
    
    /// Update the entire Spotlight index with current tasks
    func updateSpotlightIndex() {
        let categories = categoryManager?.categories ?? []
        SpotlightManager.shared.updateTasksIndex(tasks, categories: categories)
    }
    
    /// Find a task by its ID (useful for Spotlight result handling)
    func task(with id: UUID) -> Task? {
        return tasks.first { $0.id == id }
    }
    
    // MARK: - Task Management
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
        
        // Index the new task in Spotlight
        let categories = categoryManager?.categories ?? []
        SpotlightManager.shared.indexTask(task, categories: categories)
        
        // Haptic feedback for adding a task
        HapticManager.shared.taskAdded()
        
        if task.hasReminder, let reminderDate = task.reminderDate {
            scheduleNotification(for: task, at: reminderDate)
        }
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            // Cancel existing notification
            cancelNotification(for: tasks[index])
            
            tasks[index] = task
            saveTasks()
            
            // Update the task in Spotlight
            let categories = categoryManager?.categories ?? []
            SpotlightManager.shared.indexTask(task, categories: categories)
            
            // Schedule new notification if needed
            if task.hasReminder, let reminderDate = task.reminderDate {
                scheduleNotification(for: task, at: reminderDate)
            }
        }
    }
    
    func deleteTask(_ task: Task) {
        cancelNotification(for: task)
        
        // Remove from Spotlight index
        SpotlightManager.shared.removeTask(task)
        
        tasks.removeAll { $0.id == task.id }
        saveTasks()
        
        // Haptic feedback for deleting a task
        HapticManager.shared.taskDeleted()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            // Set or clear the completion date
            if tasks[index].isCompleted {
                tasks[index].completedAt = Date()
                HapticManager.shared.taskCompleted()
                cancelNotification(for: tasks[index])
                
                // Check for milestone celebrations after completing a task
                CelebrationManager.shared.checkMilestones(taskManager: self)
            } else {
                tasks[index].completedAt = nil
                HapticManager.shared.taskUncompleted()
                if tasks[index].hasReminder, let reminderDate = tasks[index].reminderDate {
                    scheduleNotification(for: tasks[index], at: reminderDate)
                }
            }
            
            // Update the task in Spotlight with new completion status
            let categories = categoryManager?.categories ?? []
            SpotlightManager.shared.indexTask(tasks[index], categories: categories)
            
            saveTasks()
        }
    }
    
    func moveTask(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < tasks.count,
              destinationIndex >= 0, destinationIndex < tasks.count else {
            return
        }
        
        let movedTask = tasks.remove(at: sourceIndex)
        tasks.insert(movedTask, at: destinationIndex)
        saveTasks()
    }
    
    func duplicateTask(_ task: Task) {
        // Create a new task with same properties but new ID and current timestamp
        let duplicatedTask = Task(
            title: "\(task.title) (Copy)",
            description: task.description,
            dueDate: task.dueDate,
            hasReminder: task.hasReminder,
            reminderDate: task.reminderDate,
            categoryId: task.categoryId
        )
        
        addTask(duplicatedTask)
        
        // Haptic feedback for duplicating task
        HapticManager.shared.taskAdded()
    }
    
    // MARK: - Persistence
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        if let data = userDefaults.data(forKey: tasksKey),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            
            // Migrate existing completed tasks that don't have completedAt date
            tasks = decodedTasks.map { task in
                var migratedTask = task
                if task.isCompleted && task.completedAt == nil {
                    // For existing completed tasks, set completedAt to createdAt as a reasonable fallback
                    migratedTask.completedAt = task.createdAt
                }
                return migratedTask
            }
            
            // Save the migrated data back
            saveTasks()
        }
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleNotification(for task: Task, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                // Light haptic feedback when reminder is set
                DispatchQueue.main.async {
                    HapticManager.shared.selectionChange()
                }
            }
        }
    }
    
    private func cancelNotification(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationHandling() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    // MARK: - Overdue Task Detection
    
    func checkForOverdueTasks() {
        let overdueTasks = tasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return dueDate < Date()
        }
        
        if !overdueTasks.isEmpty {
            DispatchQueue.main.async {
                HapticManager.shared.taskOverdue()
            }
        }
    }
    
    // MARK: - Task Filtering Computed Properties
    
    /// Returns all tasks that are overdue (past due date and not completed)
    var overdueTasks: [Task] {
        return tasks.filter { $0.isOverdue }
    }
    
    /// Returns all tasks that are pending (future due date and not completed)
    var pendingTasks: [Task] {
        return tasks.filter { $0.isPending }
    }
    
    /// Returns all tasks due today (including completed ones)
    var todayTasks: [Task] {
        return tasks.filter { $0.isDueToday }
    }
    
    /// Returns all tasks due in the future (tomorrow or later, not completed)
    var futureTasks: [Task] {
        return tasks.filter { $0.isDueFuture && !$0.isCompleted }
    }
    
    /// Returns all completed tasks
    var completedTasks: [Task] {
        return tasks.filter { $0.isCompleted }
    }
    
    /// Returns all tasks without a due date that are not completed
    var noDueDateTasks: [Task] {
        return tasks.filter { $0.dueDate == nil && !$0.isCompleted }
    }
    
    // MARK: - Category Filtering
    
    /// Returns tasks filtered by category
    func tasks(for categoryId: UUID?) -> [Task] {
        if let categoryId = categoryId {
            return tasks.filter { $0.categoryId == categoryId }
        } else {
            return tasks.filter { $0.categoryId == nil } // Uncategorized tasks
        }
    }
    
    /// Returns all tasks for a specific category (including subcategory filtering)
    func filteredTasks(categoryId: UUID? = nil, searchText: String = "", filterOption: ContentView.FilterOption = .all) -> [Task] {
        var filtered = tasks
        
        // Category filter
        if let categoryId = categoryId {
            filtered = filtered.filter { $0.categoryId == categoryId }
        }
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Status filter
        switch filterOption {
        case .all:
            break // No additional filtering
        case .pending:
            filtered = filtered.filter { !$0.isCompleted && !$0.isOverdue }
        case .completed:
            filtered = filtered.filter { $0.isCompleted }
        case .overdue:
            filtered = filtered.filter { $0.isOverdue }
        }
        
        // Sort by completion status, then by due date, then by creation date
        return filtered.sorted { task1, task2 in
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted && task2.isCompleted
            }
            
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            } else if task1.dueDate != nil {
                return true
            } else if task2.dueDate != nil {
                return false
            }
            
            return task1.createdAt > task2.createdAt
        }
    }
    
    // MARK: - Bulk Category Operations
    
    /// Assign category to multiple tasks
    func assignCategory(_ categoryId: UUID?, to taskIds: [UUID]) {
        for taskId in taskIds {
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks[index].categoryId = categoryId
            }
        }
        saveTasks()
        
        // Update Spotlight index for affected tasks
        updateSpotlightIndex()
        
        HapticManager.shared.selectionChange()
    }
    
    // MARK: - Automatic Cleanup
    
    /// Removes completed tasks that are older than 7 days
    func cleanupOldCompletedTasks() {
        let tasksToDelete = tasks.filter { $0.shouldBeAutoDeleted }
        
        if !tasksToDelete.isEmpty {
            print("Auto-deleting \(tasksToDelete.count) completed tasks older than 7 days")
            
            for task in tasksToDelete {
                cancelNotification(for: task)
                // Remove from Spotlight index
                SpotlightManager.shared.removeTask(task)
            }
            
            tasks.removeAll { $0.shouldBeAutoDeleted }
            saveTasks()
        }
    }
    
    /// Call this method when the app becomes active to clean up old tasks
    func performMaintenanceTasks() {
        cleanupOldCompletedTasks()
        checkForOverdueTasks()
        // Refresh Spotlight index to ensure it's up to date
        updateSpotlightIndex()
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {}
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Haptic feedback when reminder notification is received
        HapticManager.shared.reminderReceived()
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Haptic feedback when user interacts with notification
        HapticManager.shared.buttonTap()
        
        completionHandler()
    }
}