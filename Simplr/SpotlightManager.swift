//
//  SpotlightManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
import UIKit

class SpotlightManager {
    static let shared = SpotlightManager()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Index all tasks in Spotlight
    func indexAllTasks(_ tasks: [Task], categories: [TaskCategory] = []) {
        let searchableItems = tasks.compactMap { task in
            createSearchableItem(for: task, categories: categories)
        }
        
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                print("Error indexing tasks in Spotlight: \(error.localizedDescription)")
            } else {
                print("Successfully indexed \(searchableItems.count) tasks in Spotlight")
            }
        }
    }
    
    /// Index a single task in Spotlight
    func indexTask(_ task: Task, categories: [TaskCategory] = []) {
        guard let searchableItem = createSearchableItem(for: task, categories: categories) else {
            return
        }
        
        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { error in
            if let error = error {
                print("Error indexing task '\(task.title)' in Spotlight: \(error.localizedDescription)")
            }
        }
    }
    
    /// Remove a task from Spotlight index
    func removeTask(_ task: Task) {
        let identifier = spotlightIdentifier(for: task)
        
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier]) { error in
            if let error = error {
                print("Error removing task '\(task.title)' from Spotlight: \(error.localizedDescription)")
            }
        }
    }
    
    /// Remove all tasks from Spotlight index
    func removeAllTasks() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["com.danielzverev.simplr.tasks"]) { error in
            if let error = error {
                print("Error removing all tasks from Spotlight: \(error.localizedDescription)")
            } else {
                print("Successfully removed all tasks from Spotlight")
            }
        }
    }
    
    /// Update Spotlight index when tasks change
    func updateTasksIndex(_ tasks: [Task], categories: [TaskCategory] = []) {
        // Remove all existing items first, then add updated ones
        removeAllTasks()
        
        // Add a small delay to ensure removal completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.indexAllTasks(tasks, categories: categories)
        }
    }
    
    // MARK: - Private Methods
    
    private func createSearchableItem(for task: Task, categories: [TaskCategory]) -> CSSearchableItem? {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
        
        // Basic information
        attributeSet.title = task.title
        attributeSet.contentDescription = task.description.isEmpty ? "No description" : task.description
        
        // Create detailed description with status and dates
        var detailParts: [String] = []
        
        if task.isCompleted {
            detailParts.append("✅ Completed")
            if let completedDate = task.completedAt {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                detailParts.append("Completed: \(formatter.string(from: completedDate))")
            }
        } else if task.isOverdue {
            detailParts.append("⚠️ Overdue")
        } else if task.isDueToday {
            detailParts.append("📅 Due Today")
        } else if task.isPending {
            detailParts.append("⏳ Pending")
        }
        
        if let dueDate = task.dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            detailParts.append("Due: \(formatter.string(from: dueDate))")
        }
        
        // Add category information
        if let categoryId = task.categoryId,
           let category = categories.first(where: { $0.id == categoryId }) {
            detailParts.append("Category: \(category.name)")
        }
        
        if !detailParts.isEmpty {
            attributeSet.contentDescription = detailParts.joined(separator: " • ")
        }
        
        // Keywords for better searchability
        var keywords: [String] = [task.title]
        
        if !task.description.isEmpty {
            keywords.append(task.description)
        }
        
        // Add status keywords
        if task.isCompleted {
            keywords.append(contentsOf: ["completed", "done", "finished"])
        } else if task.isOverdue {
            keywords.append(contentsOf: ["overdue", "late", "urgent"])
        } else if task.isPending {
            keywords.append(contentsOf: ["pending", "todo", "upcoming"])
        }
        
        // Add category keywords
        if let categoryId = task.categoryId,
           let category = categories.first(where: { $0.id == categoryId }) {
            keywords.append(category.name.lowercased())
        }
        
        attributeSet.keywords = keywords
        
        // Dates
        attributeSet.contentCreationDate = task.createdAt
        attributeSet.contentModificationDate = task.completedAt ?? task.createdAt
        
        if let dueDate = task.dueDate {
            attributeSet.dueDate = dueDate
        }
        
        // Set relevance ranking
        if task.isOverdue {
            attributeSet.rankingHint = 1.0 // Highest priority
        } else if task.isDueToday {
            attributeSet.rankingHint = 0.9
        } else if task.isPending {
            attributeSet.rankingHint = 0.7
        } else if task.isCompleted {
            attributeSet.rankingHint = 0.3 // Lower priority for completed tasks
        } else {
            attributeSet.rankingHint = 0.5
        }
        
        // App-specific metadata
        attributeSet.relatedUniqueIdentifier = task.id.uuidString
        
        // Create the searchable item
        let identifier = spotlightIdentifier(for: task)
        let searchableItem = CSSearchableItem(
            uniqueIdentifier: identifier,
            domainIdentifier: "com.danielzverev.simplr.tasks",
            attributeSet: attributeSet
        )
        
        // Set expiration date for completed tasks (auto-remove after 30 days)
        if task.isCompleted {
            let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date())
            searchableItem.expirationDate = thirtyDaysFromNow
        }
        
        return searchableItem
    }
    
    private func spotlightIdentifier(for task: Task) -> String {
        return "task_\(task.id.uuidString)"
    }
    
    // MARK: - Task ID Extraction
    
    /// Extract task ID from Spotlight search result identifier
    static func taskId(from spotlightIdentifier: String) -> UUID? {
        guard spotlightIdentifier.hasPrefix("task_") else { return nil }
        let uuidString = String(spotlightIdentifier.dropFirst(5)) // Remove "task_" prefix
        return UUID(uuidString: uuidString)
    }
} 