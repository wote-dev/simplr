//
//  CategoryManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import Foundation
import SwiftUI

class CategoryManager: ObservableObject {
    @Published var categories: [TaskCategory] = []
    @Published var selectedCategoryFilter: UUID? = nil // nil means "All"
    
    private let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr") ?? UserDefaults.standard
    private let categoriesKey = "SavedCategories"
    private let selectedFilterKey = "SelectedCategoryFilter"
    
    init() {
        loadCategories()
        loadSelectedFilter()
    }
    
    // MARK: - Category Management
    
    func addCategory(_ category: TaskCategory) {
        categories.append(category)
        saveCategories()
        HapticManager.shared.selectionChange()
    }
    
    func updateCategory(_ category: TaskCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }
    
    func deleteCategory(_ category: TaskCategory) {
        guard category.isCustom else { return } // Can't delete predefined categories
        
        categories.removeAll { $0.id == category.id }
        saveCategories()
        
        // Clear filter if the deleted category was selected
        if selectedCategoryFilter == category.id {
            selectedCategoryFilter = nil
            saveSelectedFilter()
        }
        
        HapticManager.shared.taskDeleted()
    }
    
    func createCustomCategory(name: String, color: CategoryColor) -> TaskCategory {
        let category = TaskCategory(name: name, color: color, isCustom: true)
        addCategory(category)
        return category
    }
    
    // MARK: - Category Filtering
    
    func setSelectedFilter(_ categoryId: UUID?) {
        selectedCategoryFilter = categoryId
        saveSelectedFilter()
        HapticManager.shared.selectionChange()
    }
    
    func clearFilter() {
        selectedCategoryFilter = nil
        saveSelectedFilter()
        HapticManager.shared.selectionChange()
    }
    
    // MARK: - Category Lookup
    
    func category(for id: UUID?) -> TaskCategory? {
        guard let id = id else { return nil }
        return categories.first { $0.id == id }
    }
    
    func category(for task: Task) -> TaskCategory? {
        guard let categoryId = task.categoryId else { return nil }
        return category(for: categoryId)
    }
    
    // MARK: - Smart Category Suggestions
    
    func suggestCategory(for taskTitle: String) -> TaskCategory? {
        let title = taskTitle.lowercased()
        
        // Work-related keywords
        if title.contains("meeting") || title.contains("project") || title.contains("work") || 
           title.contains("client") || title.contains("deadline") || title.contains("email") ||
           title.contains("presentation") || title.contains("conference") {
            return categories.first { $0.name == "Work" }
        }
        
        // Shopping-related keywords
        if title.contains("buy") || title.contains("shop") || title.contains("grocery") ||
           title.contains("store") || title.contains("purchase") || title.contains("market") {
            return categories.first { $0.name == "Shopping" }
        }
        
        // Health-related keywords
        if title.contains("doctor") || title.contains("gym") || title.contains("exercise") ||
           title.contains("workout") || title.contains("health") || title.contains("medical") ||
           title.contains("appointment") || title.contains("dentist") {
            return categories.first { $0.name == "Health" }
        }
        
        // Learning-related keywords
        if title.contains("study") || title.contains("learn") || title.contains("course") ||
           title.contains("read") || title.contains("book") || title.contains("tutorial") ||
           title.contains("practice") || title.contains("skill") {
            return categories.first { $0.name == "Learning" }
        }
        
        // Travel-related keywords
        if title.contains("trip") || title.contains("travel") || title.contains("flight") ||
           title.contains("hotel") || title.contains("vacation") || title.contains("pack") ||
           title.contains("passport") || title.contains("booking") {
            return categories.first { $0.name == "Travel" }
        }
        
        return nil
    }
    
    // MARK: - Category Statistics
    
    func taskCount(for categoryId: UUID?, in tasks: [Task]) -> Int {
        if let categoryId = categoryId {
            return tasks.filter { $0.categoryId == categoryId }.count
        } else {
            // Return count of uncategorized tasks for "All" filter
            return tasks.filter { $0.categoryId == nil }.count
        }
    }
    
    func completedTaskCount(for categoryId: UUID?, in tasks: [Task]) -> Int {
        if let categoryId = categoryId {
            return tasks.filter { $0.categoryId == categoryId && $0.isCompleted }.count
        } else {
            return tasks.filter { $0.categoryId == nil && $0.isCompleted }.count
        }
    }
    
    // MARK: - Persistence
    
    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            userDefaults.set(encoded, forKey: categoriesKey)
        }
    }
    
    private func loadCategories() {
        // Always start with predefined categories
        var loadedCategories = TaskCategory.predefined
        
        // Load custom categories if they exist
        if let data = userDefaults.data(forKey: categoriesKey),
           let savedCategories = try? JSONDecoder().decode([TaskCategory].self, from: data) {
            
            // Add only custom categories (predefined ones are already included)
            let customCategories = savedCategories.filter { $0.isCustom }
            loadedCategories.append(contentsOf: customCategories)
        }
        
        categories = loadedCategories
        saveCategories() // Save the merged list
    }
    
    private func saveSelectedFilter() {
        if let selectedCategoryFilter = selectedCategoryFilter {
            userDefaults.set(selectedCategoryFilter.uuidString, forKey: selectedFilterKey)
        } else {
            userDefaults.removeObject(forKey: selectedFilterKey)
        }
    }
    
    private func loadSelectedFilter() {
        if let filterString = userDefaults.string(forKey: selectedFilterKey),
           let filterId = UUID(uuidString: filterString) {
            selectedCategoryFilter = filterId
        }
    }
} 