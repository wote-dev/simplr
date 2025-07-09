//
//  TaskManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import Foundation
import UserNotifications
import UIKit
import os.log
import WidgetKit

enum FilterOption: String, CaseIterable {
    case all = "All"
    case pending = "Pending"
    case completed = "Completed"
    case overdue = "Overdue"
}

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    
    private let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr") ?? UserDefaults.standard
    private let tasksKey = "SavedTasks"
    
    // Reference to CategoryManager for Spotlight integration
    private var categoryManager: CategoryManager?
    
    // Performance optimization: Cache filtered results
    private var filteredTasksCache: [String: [Task]] = [:]
    private var lastCacheUpdate = Date.distantPast
    private let cacheValidityDuration: TimeInterval = 1.0 // 1 second cache
    
    // Lazy computed properties for better performance
    private var _overdueTasks: [Task]?
    private var _pendingTasks: [Task]?
    private var _completedTasks: [Task]?
    private var _todayTasks: [Task]?
    private var _futureTasks: [Task]?
    private var _noDueDateTasks: [Task]?
    private var lastTasksUpdate = Date.distantPast
    
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
    
    // MARK: - Cache Management
    
    private func invalidateCache() {
        filteredTasksCache.removeAll()
        _overdueTasks = nil
        _pendingTasks = nil
        _completedTasks = nil
        _todayTasks = nil
        _futureTasks = nil
        _noDueDateTasks = nil
        lastTasksUpdate = Date()
    }
    
    private func isCacheValid() -> Bool {
        return Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration
    }
    
    // MARK: - Task Management
    
    func addTask(_ task: Task) {
        tasks.append(task)
        invalidateCache()
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
            invalidateCache()
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
        invalidateCache()
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
            
            invalidateCache()
            saveTasks()
        }
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
        PerformanceMonitor.shared.measure(PerformanceMonitor.MeasurementPoint.taskSaving) {
            if let encoded = try? JSONEncoder().encode(tasks) {
                userDefaults.set(encoded, forKey: tasksKey)
                
                // Trigger immediate widget update
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    private func loadTasks() {
        PerformanceMonitor.shared.measure(PerformanceMonitor.MeasurementPoint.taskLoading) {
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
    
    // MARK: - Task Filtering Computed Properties (Optimized with Caching)
    
    /// Returns all tasks that are overdue (past due date and not completed)
    var overdueTasks: [Task] {
        if let cached = _overdueTasks, Date().timeIntervalSince(lastTasksUpdate) < cacheValidityDuration {
            return cached
        }
        let result = tasks.filter { $0.isOverdue }
        _overdueTasks = result
        return result
    }
    
    /// Returns all tasks that are pending (future due date and not completed)
    var pendingTasks: [Task] {
        if let cached = _pendingTasks, Date().timeIntervalSince(lastTasksUpdate) < cacheValidityDuration {
            return cached
        }
        let result = tasks.filter { $0.isPending }
        _pendingTasks = result
        return result
    }
    
    /// Returns all tasks due today (including completed ones)
    var todayTasks: [Task] {
        if let cached = _todayTasks, Date().timeIntervalSince(lastTasksUpdate) < cacheValidityDuration {
            return cached
        }
        let result = tasks.filter { $0.isDueToday }
        _todayTasks = result
        return result
    }
    
    /// Returns all tasks due in the future (tomorrow or later, not completed)
    var futureTasks: [Task] {
        if let cached = _futureTasks, Date().timeIntervalSince(lastTasksUpdate) < cacheValidityDuration {
            return cached
        }
        let result = tasks.filter { $0.isDueFuture && !$0.isCompleted }
        _futureTasks = result
        return result
    }
    
    /// Returns all completed tasks
    var completedTasks: [Task] {
        if let cached = _completedTasks, Date().timeIntervalSince(lastTasksUpdate) < cacheValidityDuration {
            return cached
        }
        let result = tasks.filter { $0.isCompleted }
        _completedTasks = result
        return result
    }
    
    /// Returns all tasks without a due date that are not completed
    var noDueDateTasks: [Task] {
        if let cached = _noDueDateTasks, Date().timeIntervalSince(lastTasksUpdate) < cacheValidityDuration {
            return cached
        }
        let result = tasks.filter { $0.dueDate == nil && !$0.isCompleted }
        _noDueDateTasks = result
        return result
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
    
    /// Returns all tasks for a specific category (including subcategory filtering) - Optimized with caching
    func filteredTasks(categoryId: UUID? = nil, searchText: String = "", filterOption: FilterOption = .all) -> [Task] {
        return PerformanceMonitor.shared.measure(PerformanceMonitor.MeasurementPoint.taskFiltering) {
            // Create cache key
            let cacheKey = "\(categoryId?.uuidString ?? "nil")_\(searchText)_\(filterOption.rawValue)"
            
            // Check cache validity
            if isCacheValid(), let cachedResult = filteredTasksCache[cacheKey] {
                return cachedResult
            }
            
            // Perform filtering
            var filtered = tasks
        
        // Category filter - optimize by using pre-filtered arrays when possible
        if let categoryId = categoryId {
            filtered = filtered.filter { $0.categoryId == categoryId }
        }
        
        // Search filter - case-insensitive search optimization
        if !searchText.isEmpty {
            let lowercaseSearchText = searchText.lowercased()
            filtered = filtered.filter { task in
                task.title.lowercased().contains(lowercaseSearchText) ||
                task.description.lowercased().contains(lowercaseSearchText)
            }
        }
        
        // Status filter - use cached computed properties when possible
        switch filterOption {
        case .all:
            break // No additional filtering
        case .pending:
            filtered = filtered.filter { !$0.isCompleted && !$0.isOverdue }
        case .completed:
            if searchText.isEmpty && categoryId == nil {
                // Use cached completed tasks if no other filters
                filtered = completedTasks
            } else {
                filtered = filtered.filter { $0.isCompleted }
            }
        case .overdue:
            if searchText.isEmpty && categoryId == nil {
                // Use cached overdue tasks if no other filters
                filtered = overdueTasks
            } else {
                filtered = filtered.filter { $0.isOverdue }
            }
        }
        
        // Optimized sorting - reduce comparison operations
        let result = filtered.sorted { task1, task2 in
            // Primary sort: completion status
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted && task2.isCompleted
            }
            
            // Secondary sort: due date
            switch (task1.dueDate, task2.dueDate) {
            case let (date1?, date2?):
                return date1 < date2
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                // Tertiary sort: creation date (newer first)
                return task1.createdAt > task2.createdAt
            }
        }
        
        // Cache the result
             filteredTasksCache[cacheKey] = result
             lastCacheUpdate = Date()
             
             return result
         }
    }
    
    // MARK: - Bulk Category Operations (Optimized)
    
    /// Assign category to multiple tasks - optimized for bulk operations
    func assignCategory(_ categoryId: UUID?, to taskIds: [UUID]) {
        let taskIdSet = Set(taskIds) // Convert to Set for O(1) lookup
        var hasChanges = false
        
        for index in tasks.indices {
            if taskIdSet.contains(tasks[index].id) {
                tasks[index].categoryId = categoryId
                hasChanges = true
            }
        }
        
        if hasChanges {
            invalidateCache()
            saveTasks()
            
            // Update Spotlight index for affected tasks
            updateSpotlightIndex()
            
            HapticManager.shared.selectionChange()
        }
    }
    
    // MARK: - Performance Optimization Methods
    
    /// Batch update multiple tasks to reduce save operations
    func batchUpdateTasks(_ updates: [(UUID, (inout Task) -> Void)]) {
        var hasChanges = false
        let updateDict = Dictionary(uniqueKeysWithValues: updates)
        
        for index in tasks.indices {
            if let updateFunction = updateDict[tasks[index].id] {
                let originalTask = tasks[index]
                
                // Cancel existing notification before updating
                cancelNotification(for: originalTask)
                
                updateFunction(&tasks[index])
                hasChanges = true
                
                // Schedule new notification if task has reminder and is not completed
                if tasks[index].hasReminder, 
                   let reminderDate = tasks[index].reminderDate,
                   !tasks[index].isCompleted {
                    scheduleNotification(for: tasks[index], at: reminderDate)
                }
            }
        }
        
        if hasChanges {
            invalidateCache()
            saveTasks()
            updateSpotlightIndex()
        }
    }
    
    // MARK: - Quick List Management
    
    /// Add a new quick list item to a task
    func addQuickListItem(to taskId: UUID, text: String) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        let newItem = QuickListItem(text: text)
        tasks[index].quickListItems.append(newItem)
        
        invalidateCache()
        saveTasks()
        updateSpotlightIndex()
        
        HapticManager.shared.selectionChange()
    }
    
    /// Toggle completion status of a quick list item
    func toggleQuickListItem(taskId: UUID, itemId: UUID) {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == taskId }),
              let itemIndex = tasks[taskIndex].quickListItems.firstIndex(where: { $0.id == itemId }) else { return }
        
        tasks[taskIndex].quickListItems[itemIndex].isCompleted.toggle()
        tasks[taskIndex].quickListItems[itemIndex].completedAt = tasks[taskIndex].quickListItems[itemIndex].isCompleted ? Date() : nil
        
        invalidateCache()
        saveTasks()
        updateSpotlightIndex()
        
        HapticManager.shared.selectionChange()
    }
    
    /// Update the text of a quick list item
    func updateQuickListItem(taskId: UUID, itemId: UUID, newText: String) {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == taskId }),
              let itemIndex = tasks[taskIndex].quickListItems.firstIndex(where: { $0.id == itemId }) else { return }
        
        tasks[taskIndex].quickListItems[itemIndex].text = newText
        
        invalidateCache()
        saveTasks()
        updateSpotlightIndex()
        
        HapticManager.shared.selectionChange()
    }
    
    /// Delete a quick list item from a task
    func deleteQuickListItem(taskId: UUID, itemId: UUID) {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        tasks[taskIndex].quickListItems.removeAll { $0.id == itemId }
        
        invalidateCache()
        saveTasks()
        updateSpotlightIndex()
        
        HapticManager.shared.selectionChange()
    }
    
    /// Reorder quick list items within a task
    func reorderQuickListItems(taskId: UUID, from source: IndexSet, to destination: Int) {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        tasks[taskIndex].quickListItems.move(fromOffsets: source, toOffset: destination)
        
        invalidateCache()
        saveTasks()
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
        // Reload tasks from UserDefaults to sync with widget changes
        loadTasks()
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