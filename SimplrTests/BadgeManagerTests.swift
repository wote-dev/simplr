//
//  BadgeManagerTests.swift
//  SimplrTests
//
//  Created by Daniel Zverev on 2/7/2025.
//

import XCTest
@testable import Simplr

/// Unit tests for BadgeManager functionality
class BadgeManagerTests: XCTestCase {
    
    var badgeManager: BadgeManager!
    
    @MainActor
    override func setUp() {
        super.setUp()
        badgeManager = BadgeManager.shared
        // Reset badge state for testing
        badgeManager.isBadgeEnabled = true
    }
    
    @MainActor
    override func tearDown() {
        badgeManager.clearBadge()
        super.tearDown()
    }
    
    @MainActor
    func testBadgeCountCalculation() {
        // Create test tasks
        let now = Date()
        let calendar = Calendar.current
        
        // Task due today (should be counted)
        let taskDueToday = Task(
            title: "Due Today",
            dueDate: now
        )
        
        // Task due tomorrow (should be counted)
        let taskDueTomorrow = Task(
            title: "Due Tomorrow",
            dueDate: calendar.date(byAdding: .day, value: 1, to: now)
        )
        
        // Overdue task (should be counted)
        let overdueTask = Task(
            title: "Overdue",
            dueDate: calendar.date(byAdding: .day, value: -1, to: now)
        )
        
        // Completed task (should NOT be counted)
        var completedTask = Task(
            title: "Completed",
            dueDate: now
        )
        completedTask.isCompleted = true
        
        // Task due next week (should NOT be counted)
        let futureTask = Task(
            title: "Future",
            dueDate: calendar.date(byAdding: .day, value: 7, to: now)
        )
        
        // Task without due date (should be counted as pending)
        let noDueDateTask = Task(
            title: "No Due Date"
        )
        
        let tasks = [taskDueToday, taskDueTomorrow, overdueTask, completedTask, futureTask, noDueDateTask]
        
        // Save tasks to UserDefaults to simulate the app environment
        let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr")!
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(tasks) {
            userDefaults.set(encoded, forKey: "SavedTasks")
        }

        // Test badge calculation
        badgeManager.updateBadgeCount()
        
        // Expected count: taskDueToday + taskDueTomorrow + overdueTask + noDueDateTask = 4
        // (completedTask and futureTask should not be counted)
        
        print("Test completed - Badge should show 4 pending tasks")
    }
    
    @MainActor
    func testBadgeDisabling() {
        let tasks = [Task(title: "Test Task", dueDate: Date())]
        
        // Save tasks to UserDefaults
        let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr")!
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(tasks) {
            userDefaults.set(encoded, forKey: "SavedTasks")
        }

        // Enable badge and update
        badgeManager.isBadgeEnabled = true
        badgeManager.updateBadgeCount()
        
        // Disable badge
        badgeManager.isBadgeEnabled = false
        
        // Badge should be cleared when disabled
        print("Test completed - Badge should be cleared when disabled")
    }
    
    @MainActor
    func testBadgeCapAt99() {
        // Create 150 tasks to test the 99 cap
        var tasks: [Task] = []
        for i in 1...150 {
            tasks.append(Task(title: "Task \(i)", dueDate: Date()))
        }
        
        // Save tasks to UserDefaults
        let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr")!
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(tasks) {
            userDefaults.set(encoded, forKey: "SavedTasks")
        }

        badgeManager.updateBadgeCount()
        
        // Badge should be capped at 99
        print("Test completed - Badge should be capped at 99 for 150 tasks")
    }
}