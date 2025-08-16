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
#if !WIDGET_TARGET
import WidgetKit
#endif

enum FilterOption: String, CaseIterable {
    case all = "All"
    case pending = "Pending"
    case completed = "Completed"
    case overdue = "Overdue"
}

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    
    private let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr") ?? UserDefaults.standard
    private let profileManager = ProfileManager.shared
    
    // Dynamic tasks key based on current profile
    private var tasksKey: String {
        return profileManager.getTasksKey()
    }
    
    // Reference to CategoryManager for Spotlight integration
    private var categoryManager: CategoryManager?
    
    // Badge management
    private let badgeManager = BadgeManager.shared
    
    // Unified cache manager for optimized memory usage
    private let cacheManager = UnifiedCacheManager.shared
    private var lastCacheUpdate = Date.distantPast
    private let cacheValidityDuration: TimeInterval = PerformanceConfig.Cache.cacheValidityDuration
    
    // Batch operation optimization
    private var batchUpdateTimer: Timer?
    private var pendingUpdates: Set<UUID> = []
    
    // Lazy computed properties for better performance
    private var _overdueTasks: [Task]?
    private var _pendingTasks: [Task]?
    private var _completedTasks: [Task]?
    private var _todayTasks: [Task]?
    private var _futureTasks: [Task]?
    private var _noDueDateTasks: [Task]?
    private var lastTasksUpdate = Date.distantPast
    
    init() {
        // Listen for profile changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ProfileDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleProfileChange()
        }
        
        loadTasks()
        requestNotificationPermission()
        setupNotificationHandling()
        setupMemoryManagement()
        
        // Initial badge update
        _Concurrency.Task { @MainActor in
            badgeManager.updateBadgeCount()
        }
    }
    
    private func setupMemoryManagement() {
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        
        // Listen for background events
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppBackground()
        }
    }
    
    private func handleMemoryWarning() {
        // Use unified cache manager for memory pressure handling
        cacheManager.invalidateAllCaches()
        lastCacheUpdate = Date.distantPast
        
        // Clear computed property caches
        _overdueTasks = nil
        _pendingTasks = nil
        _completedTasks = nil
        _todayTasks = nil
        _futureTasks = nil
        _noDueDateTasks = nil
        
        // Force memory cleanup
        autoreleasepool {
            // Additional cleanup for production
        }
        
        print("TaskManager: Cleared caches due to memory warning")
    }
    
    private func handleAppBackground() {
        // Enhanced background cleanup for App Store optimization
        performBackgroundCleanup()
    }
    
    /// Perform comprehensive background cleanup
    private func performBackgroundCleanup() {
        // Unified cache manager handles background cleanup automatically
        // Just need to clear computed property caches and batch operations
        
        // Cancel any pending batch operations
        batchUpdateTimer?.invalidate()
        batchUpdateTimer = nil
        pendingUpdates.removeAll(keepingCapacity: false)
        
        // Force memory cleanup
        autoreleasepool {
            // Additional cleanup for production
        }
    }
    
    // MARK: - Spotlight Integration Setup
    
    /// Set the category manager reference for Spotlight integration
    func setCategoryManager(_ categoryManager: CategoryManager) {
        self.categoryManager = categoryManager
        // Re-index all tasks with category information
        updateSpotlightIndex()
    }
    
    // MARK: - Badge Management
    
    /// Get the badge manager instance
    var badgeManagerInstance: BadgeManager {
        return badgeManager
    }
    
    /// Force update the app icon badge
    func updateBadge() {
        _Concurrency.Task { @MainActor in
            badgeManager.updateBadgeCountImmediately()
        }
    }
    
    /// Force immediate badge update with current task data (most reliable method)
    func updateBadgeImmediately() {
        _Concurrency.Task { @MainActor in
            await badgeManager.updateBadgeCountWithTasks(tasks)
        }
    }
    
    /// Post notification to request badge update with current tasks
    func requestBadgeUpdate() {
        NotificationCenter.default.post(
            name: .badgeUpdateRequested,
            object: nil,
            userInfo: ["tasks": tasks]
        )
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
    
    // MARK: - Enhanced Cache Management
    
    private func invalidateCache() {
        // Use unified cache manager for all cache invalidation
        cacheManager.invalidateAllCaches()
        
        // Invalidate computed property caches
        _overdueTasks = nil
        _pendingTasks = nil
        _completedTasks = nil
        _todayTasks = nil
        _futureTasks = nil
        _noDueDateTasks = nil
        lastTasksUpdate = Date()
        
        // CRITICAL FIX: Notify CategoryManager to refresh its state
        // This ensures category collapse/expand states remain consistent
        // when tasks change completion status
        categoryManager?.refreshCategoryState()
    }
    
    // Cache validity and cleanup now handled by UnifiedCacheManager
    
    // MARK: - Task Management
    
    func addTask(_ task: Task) {
        // Ensure task has the current profile ID
        var profiledTask = task
        profiledTask.profileId = profileManager.currentProfile.rawValue
        
        tasks.append(profiledTask)
        invalidateCache()
        saveTasksWithImmediateBadgeUpdate()
        
        // Index the new task in Spotlight
        let categories = categoryManager?.categories ?? []
        SpotlightManager.shared.indexTask(profiledTask, categories: categories)
        
        // Haptic feedback for adding a task
        HapticManager.shared.taskAdded()
        
        if profiledTask.hasReminder, let reminderDate = profiledTask.reminderDate {
            scheduleNotification(for: profiledTask, at: reminderDate)
        }
    }
    
    func addTask(
        title: String,
        description: String,
        dueDate: Date?,
        hasReminder: Bool,
        reminderDate: Date?,
        categoryId: UUID?
    ) {
        let newTask = Task(
            title: title,
            description: description,
            dueDate: dueDate,
            hasReminder: hasReminder,
            reminderDate: reminderDate,
            categoryId: categoryId,
            profileId: profileManager.currentProfile.rawValue
        )
        addTask(newTask)
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            let oldTask = tasks[index]

            // Note: Task completion is now independent of checklist completion
            // Users must explicitly mark the task as complete even if all checklist items are done

            // Handle side-effects of completion status change
            if oldTask.isCompleted != updatedTask.isCompleted {
                if updatedTask.isCompleted {
                    updatedTask.completedAt = Date()
                    HapticManager.shared.taskCompleted()
                } else {
                    updatedTask.completedAt = nil
                    HapticManager.shared.taskUncompleted()
                }
            }

            // Ensure profileId is preserved when updating tasks
            if updatedTask.profileId == nil {
                updatedTask.profileId = oldTask.profileId ?? profileManager.currentProfile.rawValue
            }

            // Always cancel the old notification to prevent duplicates
            cancelNotification(for: oldTask)

            // Schedule a new notification if the task is not complete and has a reminder
            if !updatedTask.isCompleted, updatedTask.hasReminder, let reminderDate = updatedTask.reminderDate {
                scheduleNotification(for: updatedTask, at: reminderDate)
            }

            // Save the updated task
            tasks[index] = updatedTask
            
            // Use batch updates for better performance
            scheduleBatchUpdate(for: updatedTask.id)
        }
    }
    
    /// Immediate task update for checklist items - bypasses batch delays for instant UI feedback
    func updateTaskImmediate(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let oldTask = tasks[index]
        var updatedTask = task
        
        // Handle completion status changes with immediate feedback
        if oldTask.isCompleted != updatedTask.isCompleted {
            if updatedTask.isCompleted {
                updatedTask.completedAt = Date()
            } else {
                updatedTask.completedAt = nil
            }
        }
        
        // Ensure profileId is preserved when updating tasks
        if updatedTask.profileId == nil {
            updatedTask.profileId = oldTask.profileId ?? profileManager.currentProfile.rawValue
        }
        
        // Update task immediately
        tasks[index] = updatedTask
        
        // Immediate cache invalidation for instant UI updates
        invalidateCache()
        
        // Immediate save with optimized badge update
        saveTasksWithOptimizedBadgeUpdate()
        
        // Background Spotlight update to avoid blocking UI
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let categories = self.categoryManager?.categories ?? []
            SpotlightManager.shared.indexTask(updatedTask, categories: categories)
        }
    }
    
    // MARK: - Batch Update Optimization
    
    private func scheduleBatchUpdate(for taskId: UUID) {
        pendingUpdates.insert(taskId)
        
        // Cancel existing timer
        batchUpdateTimer?.invalidate()
        
        // Schedule new batch update
        batchUpdateTimer = Timer.scheduledTimer(withTimeInterval: PerformanceConfig.UI.batchUpdateDelay, repeats: false) { [weak self] _ in
            self?.processBatchUpdates()
        }
    }
    
    private func processBatchUpdates() {
        guard !pendingUpdates.isEmpty else { return }
        
        // Clear pending updates
        let updatedTaskIds = pendingUpdates
        pendingUpdates.removeAll()
        
        // Perform batch operations
        invalidateCache()
        saveTasksWithImmediateBadgeUpdate()
        
        // Update Spotlight index for all updated tasks
        let categories = categoryManager?.categories ?? []
        let updatedTasks = tasks.filter { updatedTaskIds.contains($0.id) }
        for task in updatedTasks {
            SpotlightManager.shared.indexTask(task, categories: categories)
        }
        
        // Cache cleanup is now handled automatically by UnifiedCacheManager
    }
    
    func updateTask(
        _ task: Task,
        title: String,
        description: String,
        dueDate: Date?,
        hasReminder: Bool,
        reminderDate: Date?,
        categoryId: UUID?
    ) {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.description = description
        updatedTask.dueDate = dueDate
        updatedTask.hasReminder = hasReminder
        updatedTask.reminderDate = reminderDate
        updatedTask.categoryId = categoryId
        
        updateTask(updatedTask)
    }
    
    func deleteTask(_ task: Task) {
        cancelNotification(for: task)
        
        // Remove from Spotlight index
        SpotlightManager.shared.removeTask(task)
        
        tasks.removeAll { $0.id == task.id }
        invalidateCache()
        saveTasksWithImmediateBadgeUpdate()
        
        // Haptic feedback for deleting a task
        HapticManager.shared.taskDeleted()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        // Optimized completion toggle with minimal overhead
        let wasCompleted = tasks[index].isCompleted
        tasks[index].isCompleted.toggle()
        
        // Set or clear the completion date efficiently
        if tasks[index].isCompleted {
            tasks[index].completedAt = Date()
            HapticManager.shared.taskCompleted()
            cancelNotification(for: tasks[index])
        } else {
            tasks[index].completedAt = nil
            HapticManager.shared.taskUncompleted()
            // Only reschedule notification if task has reminder
            if tasks[index].hasReminder, let reminderDate = tasks[index].reminderDate {
                scheduleNotification(for: tasks[index], at: reminderDate)
            }
        }
        
        // Batch Spotlight and cache updates for better performance
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Update Spotlight index in background
            let categories = self.categoryManager?.categories ?? []
            SpotlightManager.shared.indexTask(self.tasks[index], categories: categories)
            
            // Update UI on main thread with optimized cache invalidation
            DispatchQueue.main.async {
                self.optimizedCacheInvalidation()
                self.saveTasksWithImmediateBadgeUpdate()
            }
        }
    }
    
    /// Optimized cache invalidation for undo operations
    private func optimizedCacheInvalidation() {
        // Use unified cache manager for efficient invalidation
        cacheManager.invalidateAllCaches()
        
        // Only invalidate specific computed property caches that are affected
        _overdueTasks = nil
        _pendingTasks = nil
        _completedTasks = nil
        _todayTasks = nil
        lastTasksUpdate = Date()
        
        // Lightweight category state refresh
        categoryManager?.refreshCategoryState()
    }
    

    
    func duplicateTask(_ task: Task) {
        // Create a new task with same properties but new ID and current timestamp
        let duplicatedTask = Task(
            title: "\(task.title) (Copy)",
            description: task.description,
            dueDate: task.dueDate,
            hasReminder: task.hasReminder,
            reminderDate: task.reminderDate,
            categoryId: task.categoryId,
            profileId: profileManager.currentProfile.rawValue
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
                
                // Force immediate synchronization to ensure data is persisted
                // This is critical for badge updates to work correctly
                userDefaults.synchronize()
                
                // Update badge after saving tasks
                requestBadgeUpdate()
                
                // Force immediate widget update for real-time synchronization
                WidgetCenter.shared.reloadAllTimelines()
                
                // Post notification for UI updates
                NotificationCenter.default.post(name: Notification.Name("tasksDidChange"), object: nil)
            }
        }
    }
    
    /// Enhanced save method that ensures immediate badge update synchronization
    private func saveTasksWithImmediateBadgeUpdate() {
        PerformanceMonitor.shared.measure(PerformanceMonitor.MeasurementPoint.taskSaving) {
            if let encoded = try? JSONEncoder().encode(tasks) {
                userDefaults.set(encoded, forKey: tasksKey)
                
                // Force immediate synchronization to ensure data is persisted
                userDefaults.synchronize()
                
                // Update badge immediately with current task data to avoid race conditions
                _Concurrency.Task { @MainActor in
                    await badgeManager.updateBadgeCountWithTasks(tasks)
                }
                
                // Trigger immediate widget update
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    /// Optimized save method specifically for checklist updates - minimal overhead
    private func saveTasksWithOptimizedBadgeUpdate() {
        PerformanceMonitor.shared.measure(PerformanceMonitor.MeasurementPoint.taskSaving) {
            if let encoded = try? JSONEncoder().encode(tasks) {
                userDefaults.set(encoded, forKey: tasksKey)
                
                // Immediate synchronization for data persistence
                userDefaults.synchronize()
                
                // Optimized badge update - check if enabled and update asynchronously
                _Concurrency.Task { @MainActor in
                    if await badgeManager.isBadgeEnabled {
                        await badgeManager.updateBadgeCountWithTasks(tasks)
                    }
                }
                
                // Skip widget update for checklist changes to improve performance
                // Widgets will update on next app activation or significant task changes
            }
        }
    }
    
    private func loadTasks() {
        PerformanceMonitor.shared.measure(PerformanceMonitor.MeasurementPoint.taskLoading) {
            if let data = userDefaults.data(forKey: tasksKey),
               let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
                
                // Migrate existing completed tasks that don't have completedAt date
                // Also ensure tasks have the correct profileId for the current profile
                let currentProfileId = profileManager.currentProfile.rawValue
                tasks = decodedTasks.compactMap { task in
                    var migratedTask = task
                    
                    // Migrate completedAt for completed tasks
                    if task.isCompleted && task.completedAt == nil {
                        migratedTask.completedAt = task.createdAt
                    }
                    
                    // Ensure tasks have the correct profileId for the current profile
                    // This handles cases where tasks might not have profileId set
                    if migratedTask.profileId == nil {
                        migratedTask.profileId = currentProfileId
                    }
                    
                    // Only include tasks that belong to the current profile
                    return migratedTask.profileId == currentProfileId ? migratedTask : nil
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
        let cacheKey = UnifiedCacheManager.computedTasksKey(type: "overdue")
        
        if let cached = cacheManager.getCachedComputedTasks(for: cacheKey) {
            return cached
        }
        
        let result = tasks.filter { $0.isOverdue }.sorted { task1, task2 in
            // URGENT category priority
            let task1IsUrgent = task1.categoryId == TaskCategory.urgent.id
            let task2IsUrgent = task2.categoryId == TaskCategory.urgent.id
            
            if task1IsUrgent != task2IsUrgent {
                return task1IsUrgent && !task2IsUrgent
            }
            
            // Then sort by due date
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            }
            
            // Finally by creation date
            return task1.createdAt > task2.createdAt
        }
        
        cacheManager.setCachedComputedTasks(result, for: cacheKey)
        return result
    }
    
    /// Returns all tasks that are pending (future due date and not completed)
    var pendingTasks: [Task] {
        let cacheKey = UnifiedCacheManager.computedTasksKey(type: "pending")
        
        if let cached = cacheManager.getCachedComputedTasks(for: cacheKey) {
            return cached
        }
        
        let result = tasks.filter { $0.isPending }.sorted { task1, task2 in
            // URGENT category priority
            let task1IsUrgent = task1.categoryId == TaskCategory.urgent.id
            let task2IsUrgent = task2.categoryId == TaskCategory.urgent.id
            
            if task1IsUrgent != task2IsUrgent {
                return task1IsUrgent && !task2IsUrgent
            }
            
            // Then sort by due date
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            }
            
            // Finally by creation date
            return task1.createdAt > task2.createdAt
        }
        
        cacheManager.setCachedComputedTasks(result, for: cacheKey)
        return result
    }
    
    /// Returns all tasks due today (including completed ones)
    var todayTasks: [Task] {
        let cacheKey = UnifiedCacheManager.computedTasksKey(type: "today")
        
        if let cached = cacheManager.getCachedComputedTasks(for: cacheKey) {
            return cached
        }
        
        let result = tasks.filter { $0.isDueToday }.sorted { task1, task2 in
            // Completion status first
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted && task2.isCompleted
            }
            
            // URGENT category priority for incomplete tasks
            if !task1.isCompleted && !task2.isCompleted {
                let task1IsUrgent = task1.categoryId == TaskCategory.urgent.id
                let task2IsUrgent = task2.categoryId == TaskCategory.urgent.id
                
                if task1IsUrgent != task2IsUrgent {
                    return task1IsUrgent && !task2IsUrgent
                }
            }
            
            // Finally by creation date
            return task1.createdAt > task2.createdAt
        }
        
        cacheManager.setCachedComputedTasks(result, for: cacheKey)
        return result
    }
    
    /// Returns all tasks due in the future (tomorrow or later, not completed)
    var futureTasks: [Task] {
        let cacheKey = UnifiedCacheManager.computedTasksKey(type: "future")
        
        if let cached = cacheManager.getCachedComputedTasks(for: cacheKey) {
            return cached
        }
        
        let result = tasks.filter { $0.isDueFuture && !$0.isCompleted }.sorted { task1, task2 in
            // URGENT category priority
            let task1IsUrgent = task1.categoryId == TaskCategory.urgent.id
            let task2IsUrgent = task2.categoryId == TaskCategory.urgent.id
            
            if task1IsUrgent != task2IsUrgent {
                return task1IsUrgent && !task2IsUrgent
            }
            
            // Then sort by due date
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            }
            
            // Finally by creation date
            return task1.createdAt > task2.createdAt
        }
        
        cacheManager.setCachedComputedTasks(result, for: cacheKey)
        return result
    }
    
    /// Returns all completed tasks
    var completedTasks: [Task] {
        let cacheKey = UnifiedCacheManager.computedTasksKey(type: "completed")
        
        if let cached = cacheManager.getCachedComputedTasks(for: cacheKey) {
            return cached
        }
        
        let result = tasks.filter { $0.isCompleted }
        cacheManager.setCachedComputedTasks(result, for: cacheKey)
        return result
    }
    
    /// Returns all tasks without a due date that are not completed
    var noDueDateTasks: [Task] {
        let cacheKey = UnifiedCacheManager.computedTasksKey(type: "noDueDate")
        
        if let cached = cacheManager.getCachedComputedTasks(for: cacheKey) {
            return cached
        }
        
        let result = tasks.filter { $0.dueDate == nil && !$0.isCompleted }.sorted { task1, task2 in
            // URGENT category priority
            let task1IsUrgent = task1.categoryId == TaskCategory.urgent.id
            let task2IsUrgent = task2.categoryId == TaskCategory.urgent.id
            
            if task1IsUrgent != task2IsUrgent {
                return task1IsUrgent && !task2IsUrgent
            }
            
            // Sort by creation date (newer first)
            return task1.createdAt > task2.createdAt
        }
        
        cacheManager.setCachedComputedTasks(result, for: cacheKey)
        return result
    }
    
    // MARK: - Category Filtering
    
    /// Returns tasks filtered by category
    func tasks(for categoryId: UUID?) -> [Task] {
        let cacheKey = UnifiedCacheManager.categoryTasksKey(categoryId: categoryId)
        
        if let cached = cacheManager.getCachedCategoryTasks(for: cacheKey) {
            return cached
        }
        
        let filtered: [Task]
        if let categoryId = categoryId {
            filtered = tasks.filter { $0.categoryId == categoryId }
        } else {
            filtered = tasks.filter { $0.categoryId == nil } // Uncategorized tasks
        }
        
        // Sort with URGENT category priority
        let result = filtered.sorted { task1, task2 in
            // Primary sort: completion status
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted && task2.isCompleted
            }
            
            // Secondary sort: URGENT category priority (URGENT tasks always come first)
            let task1IsUrgent = task1.categoryId == TaskCategory.urgent.id
            let task2IsUrgent = task2.categoryId == TaskCategory.urgent.id
            
            if task1IsUrgent != task2IsUrgent {
                return task1IsUrgent && !task2IsUrgent
            }
            
            // Tertiary sort: due date
            switch (task1.dueDate, task2.dueDate) {
            case let (date1?, date2?):
                return date1 < date2
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                // Quaternary sort: creation date (newer first)
                return task1.createdAt > task2.createdAt
            }
        }
        
        cacheManager.setCachedCategoryTasks(result, for: cacheKey)
        return result
    }
    
    /// Returns all tasks for a specific category (including subcategory filtering) - Optimized with caching
    func filteredTasks(categoryId: UUID? = nil, searchText: String = "", filterOption: FilterOption = .all) -> [Task] {
        return PerformanceMonitor.shared.measure(PerformanceMonitor.MeasurementPoint.taskFiltering) {
            // Create cache key
            let cacheKey = UnifiedCacheManager.filteredTasksKey(categoryId: categoryId, searchText: searchText, filterOption: filterOption)
            
            // Check cache
            if let cachedResult = cacheManager.getCachedFilteredTasks(for: cacheKey) {
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
        
        // Optimized sorting with URGENT category priority
        let result = filtered.sorted { task1, task2 in
            // Primary sort: completion status
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted && task2.isCompleted
            }
            
            // Secondary sort: URGENT category priority (URGENT tasks always come first)
            let task1IsUrgent = task1.categoryId == TaskCategory.urgent.id
            let task2IsUrgent = task2.categoryId == TaskCategory.urgent.id
            
            if task1IsUrgent != task2IsUrgent {
                return task1IsUrgent && !task2IsUrgent
            }
            
            // Tertiary sort: due date
            switch (task1.dueDate, task2.dueDate) {
            case let (date1?, date2?):
                return date1 < date2
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                // Quaternary sort: creation date (newer first)
                return task1.createdAt > task2.createdAt
            }
        }
        
        // Cache the result
             cacheManager.setCachedFilteredTasks(result, for: cacheKey)
             
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
            saveTasksWithImmediateBadgeUpdate()
            updateSpotlightIndex()
        }
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
    
    /// Clear all today's tasks (incomplete tasks due today, overdue, or without due dates)
    func clearTodayTasks() {
        let calendar = Calendar.current
        let today = Date()
        
        let todayTasksToDelete = tasks.filter { task in
            // Only delete incomplete tasks
            guard !task.isCompleted else { return false }
            
            // Include tasks due today, overdue incomplete tasks, and tasks without due dates
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: today) || 
                       (dueDate < today && !task.isCompleted)
            }
            // Also include tasks without due dates that aren't completed
            return !task.isCompleted
        }
        
        if !todayTasksToDelete.isEmpty {
            print("Clearing \(todayTasksToDelete.count) today's tasks")
            
            for task in todayTasksToDelete {
                cancelNotification(for: task)
                // Remove from Spotlight index
                SpotlightManager.shared.removeTask(task)
            }
            
            tasks.removeAll { task in
                todayTasksToDelete.contains { $0.id == task.id }
            }
            
            invalidateCache()
            saveTasksWithImmediateBadgeUpdate()
            
            // Haptic feedback for clearing tasks
            HapticManager.shared.successFeedback()
        }
    }
    
    /// Handle profile changes by reloading tasks for the new profile
    private func handleProfileChange() {
        // Clear current tasks and cache
        tasks.removeAll()
        invalidateCache()
        
        // Load tasks for the new profile
        loadTasks()
        
        // Update badge and Spotlight index
        updateBadgeImmediately()
        updateSpotlightIndex()
    }
    
    /// Call this method when the app becomes active to clean up old tasks
    func performMaintenanceTasks() {
        // Reload tasks from UserDefaults to sync with widget changes
        loadTasks()
        cleanupOldCompletedTasks()
        checkForOverdueTasks()
        // Refresh Spotlight index to ensure it's up to date
        updateSpotlightIndex()
        
        // Update app icon badge after maintenance with immediate update
        _Concurrency.Task { @MainActor in
            await badgeManager.updateBadgeCountWithTasks(tasks)
        }
    }
    
    // MARK: - Cache Performance Monitoring
    
    /// Get cache performance metrics for debugging and optimization
    func getCachePerformanceMetrics() -> CacheMetrics {
        return cacheManager.getCacheMetrics()
    }
    
    /// Log cache performance metrics (debug builds only)
    func logCachePerformance() {
        #if DEBUG
        let metrics = getCachePerformanceMetrics()
        print("Cache Performance:")
        print("  Hit Rate: \(String(format: "%.2f", metrics.hitRate * 100))%")
        print("  Total Entries: \(metrics.totalEntries)")
        print("  Evictions: \(metrics.evictionCount)")
        print("  Memory Pressure: \(metrics.memoryPressureActive ? "Active" : "Normal")")
        #endif
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