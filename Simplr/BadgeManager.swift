//
//  BadgeManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import Foundation
import UIKit
import UserNotifications
import os.log

/// Manages app icon badge count with performance optimization and iOS best practices
@MainActor
class BadgeManager: ObservableObject {
    static let shared = BadgeManager()
    
    // MARK: - Properties
    
    @Published private(set) var currentBadgeCount: Int = 0
    
    private let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr") ?? UserDefaults.standard
    private let badgeEnabledKey = "badgeCountEnabled"
    private let logger = Logger(subsystem: "com.danielzverev.simplr", category: "BadgeManager")
    
    // Performance optimization: Debounce badge updates
    private var updateTimer: Timer?
    private let updateDelay: TimeInterval = 0.5
    
    // Cache for badge count calculation
    private var lastCalculatedCount: Int = 0
    private var lastCalculationTime = Date.distantPast
    private let cacheValidityDuration: TimeInterval = 30 // 30 seconds
    
    // MARK: - Initialization
    
    private init() {
        // Load initial badge state
        updateBadgeCount()
        
        // Listen for app lifecycle events
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        updateTimer?.invalidate()
    }
    
    // MARK: - Public Interface
    
    /// Whether badge count is enabled in settings
    var isBadgeEnabled: Bool {
        get {
            userDefaults.bool(forKey: badgeEnabledKey)
        }
        set {
            userDefaults.set(newValue, forKey: badgeEnabledKey)
            
            if newValue {
                updateBadgeCount()
            } else {
                clearBadge()
            }
            
            logger.info("Badge count \(newValue ? "enabled" : "disabled")")
        }
    }
    
    /// Update badge count based on current tasks
    func updateBadgeCount() {
        guard isBadgeEnabled else {
            clearBadge()
            return
        }
        
        // Debounce updates to prevent excessive badge changes
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateDelay, repeats: false) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                await self?.performBadgeUpdate()
            }
        }
    }
    
    /// Force immediate badge update (use sparingly)
    func updateBadgeCountImmediately() {
        guard isBadgeEnabled else {
            clearBadge()
            return
        }
        
        updateTimer?.invalidate()
        _Concurrency.Task { @MainActor in
            await performBadgeUpdate()
        }
    }
    
    /// Update badge count with provided task data to avoid UserDefaults race conditions
    /// This method is optimized for immediate updates when tasks are modified
    func updateBadgeCountWithTasks(_ tasks: [Simplr.Task]) async {
        guard isBadgeEnabled else {
            clearBadge()
            return
        }
        
        updateTimer?.invalidate()
        
        let badgeCount = calculateBadgeCount(from: tasks)
        setBadgeCount(badgeCount)
        
        // Update cache with the calculated count
        lastCalculatedCount = badgeCount
        lastCalculationTime = Date()
        
        logger.debug("Updated badge count with provided tasks: \(badgeCount)")
    }
    
    /// Clear the app icon badge
    func clearBadge() {
        setBadgeCount(0)
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        // Update badge when app becomes active with immediate update
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateBadgeCountImmediately()
        }
        
        // Clear cache when app goes to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.invalidateCache()
        }
        
        // Handle memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.invalidateCache()
        }
        
        // Listen for task updates to ensure immediate badge updates
        NotificationCenter.default.addObserver(
            forName: .badgeUpdateRequested,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let tasks = notification.userInfo?["tasks"] as? [Simplr.Task] {
                _Concurrency.Task { @MainActor in
                    await self?.updateBadgeCountWithTasks(tasks)
                }
            } else {
                self?.updateBadgeCountImmediately()
            }
        }
    }
    
    private func performBadgeUpdate() async {
        let badgeCount = await calculateBadgeCount()
        setBadgeCount(badgeCount)
    }
    
    private func calculateBadgeCount() async -> Int {
        // Use cached value if still valid
        let now = Date()
        if now.timeIntervalSince(lastCalculationTime) < cacheValidityDuration {
            return lastCalculatedCount
        }
        
        // Load tasks from UserDefaults (same source as TaskManager)
        guard let data = userDefaults.data(forKey: "SavedTasks"),
              let tasks = try? JSONDecoder().decode([Simplr.Task].self, from: data) else {
            logger.warning("Failed to load tasks for badge count calculation")
            return 0
        }
        
        let pendingCount = calculateBadgeCount(from: tasks)
        
        // Cache the result
        lastCalculatedCount = pendingCount
        lastCalculationTime = now
        
        logger.debug("Calculated badge count from UserDefaults: \(pendingCount)")
        return pendingCount
    }
    
    /// Calculate badge count from provided task array (optimized for immediate updates)
    private func calculateBadgeCount(from tasks: [Simplr.Task]) -> Int {
        // Calculate pending tasks count (incomplete tasks that are due today, overdue, or have no due date)
        let calendar = Calendar.current
        let today = Date()
        
        let pendingCount = tasks.filter { task in
            // Only count incomplete tasks
            guard !task.isCompleted else { return false }
            
            // Include tasks that are:
            // 1. Due today
            // 2. Overdue
            // 3. Have no due date (always visible)
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: today) || dueDate < today
            } else {
                return true // Tasks without due date are always counted
            }
        }.count
        
        return pendingCount
    }
    
    private func setBadgeCount(_ count: Int) {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.setBadgeCount(count)
            }
            return
        }
        
        // Only update if the count has changed
        guard count != currentBadgeCount else { 
            logger.debug("Badge count unchanged: \(count)")
            return 
        }
        
        // Update the app icon badge with enhanced error handling
        UNUserNotificationCenter.current().setBadgeCount(count) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Error setting badge count: \(error.localizedDescription)")
                    // Retry once after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UNUserNotificationCenter.current().setBadgeCount(count) { retryError in
                            if let retryError = retryError {
                                self?.logger.error("Retry failed for badge count: \(retryError.localizedDescription)")
                            } else {
                                self?.logger.info("Badge count set successfully on retry: \(count)")
                                self?.currentBadgeCount = count
                                // Post notification for successful retry
                                NotificationCenter.default.post(
                                    name: .badgeCountDidUpdate,
                                    object: nil,
                                    userInfo: ["badgeCount": count]
                                )
                            }
                        }
                    }
                } else {
                    self?.logger.info("Badge count set successfully: \(count)")
                    self?.currentBadgeCount = count
                    // Post notification for successful badge update
                    NotificationCenter.default.post(
                        name: .badgeCountDidUpdate,
                        object: nil,
                        userInfo: ["badgeCount": count]
                    )
                }
            }
        }
        
        logger.info("Updated app icon badge to: \(count)")
    }
    
    private func invalidateCache() {
        lastCalculationTime = Date.distantPast
        lastCalculatedCount = 0
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let badgeUpdateRequested = Notification.Name("badgeUpdateRequested")
}

// MARK: - Badge Count Extensions

extension BadgeManager {
    /// Get badge count for specific task categories (for future use)
    func badgeCount(for categoryId: UUID?) async -> Int {
        guard let data = userDefaults.data(forKey: "SavedTasks"),
              let tasks = try? JSONDecoder().decode([Simplr.Task].self, from: data) else {
            return 0
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        return tasks.filter { task in
            // Filter by category
            guard task.categoryId == categoryId else { return false }
            
            // Only count incomplete tasks
            guard !task.isCompleted else { return false }
            
            // Include tasks that are due today, overdue, or have no due date
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: today) || dueDate < today
            } else {
                return true
            }
        }.count
    }
    
    /// Get total pending tasks count (for widgets and other components)
    func totalPendingTasksCount() async -> Int {
        return await calculateBadgeCount()
    }
}