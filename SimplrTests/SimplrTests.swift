//
//  SimplrTests.swift
//  SimplrTests
//
//  Created by Daniel Zverev on 2/7/2025.
//

import Testing
import Foundation
@testable import Simplr

struct SimplrTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testTaskCompletionDateTracking() async throws {
        let taskManager = TaskManager()
        let task = Task(title: "Test Task")
        
        // Add task
        taskManager.addTask(task)
        #expect(task.completedAt == nil)
        #expect(task.isCompleted == false)
        
        // Complete task
        taskManager.toggleTaskCompletion(task)
        
        // Find the updated task
        let updatedTask = taskManager.tasks.first { $0.id == task.id }
        #expect(updatedTask != nil)
        #expect(updatedTask?.isCompleted == true)
        #expect(updatedTask?.completedAt != nil)
        
        // Uncomplete task
        taskManager.toggleTaskCompletion(task)
        
        // Find the updated task again
        let uncompletedTask = taskManager.tasks.first { $0.id == task.id }
        #expect(uncompletedTask?.isCompleted == false)
        #expect(uncompletedTask?.completedAt == nil)
    }
    
    @Test func testAutoDeleteOldCompletedTasks() async throws {
        let taskManager = TaskManager()
        
        // Create a task and mark it as completed 8 days ago
        var oldTask = Task(title: "Old Completed Task")
        oldTask.isCompleted = true
        oldTask.completedAt = Calendar.current.date(byAdding: .day, value: -8, to: Date())
        
        // Create a task completed 3 days ago (should not be deleted)
        var recentTask = Task(title: "Recent Completed Task")
        recentTask.isCompleted = true
        recentTask.completedAt = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        
        // Create an active task (should not be deleted)
        let activeTask = Task(title: "Active Task")
        
        taskManager.tasks = [oldTask, recentTask, activeTask]
        
        // Run cleanup
        taskManager.cleanupOldCompletedTasks()
        
        // Check that only the old task was deleted
        #expect(taskManager.tasks.count == 2)
        #expect(taskManager.tasks.contains { $0.id == recentTask.id })
        #expect(taskManager.tasks.contains { $0.id == activeTask.id })
        #expect(!taskManager.tasks.contains { $0.id == oldTask.id })
    }
    
    @Test func testShouldBeAutoDeletedProperty() async throws {
        // Task completed 8 days ago - should be deleted
        var oldCompletedTask = Task(title: "Old Task")
        oldCompletedTask.isCompleted = true
        oldCompletedTask.completedAt = Calendar.current.date(byAdding: .day, value: -8, to: Date())
        #expect(oldCompletedTask.shouldBeAutoDeleted == true)
        
        // Task completed 3 days ago - should not be deleted
        var recentCompletedTask = Task(title: "Recent Task")
        recentCompletedTask.isCompleted = true
        recentCompletedTask.completedAt = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        #expect(recentCompletedTask.shouldBeAutoDeleted == false)
        
        // Active task - should not be deleted
        let activeTask = Task(title: "Active Task")
        #expect(activeTask.shouldBeAutoDeleted == false)
        
        // Completed task without date - should not be deleted
        var taskWithoutDate = Task(title: "Task without date")
        taskWithoutDate.isCompleted = true
        #expect(taskWithoutDate.shouldBeAutoDeleted == false)
    }
}
