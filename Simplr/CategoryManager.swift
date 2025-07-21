//
//  CategoryManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import Foundation
import SwiftUI
import os.log
import WidgetKit

class CategoryManager: ObservableObject {
    @Published var categories: [TaskCategory] = []
    @Published var selectedCategoryFilter: UUID? = nil // nil means "All"
    @Published var collapsedCategories: Set<String> = [] // Track collapsed categories by name
    
    private let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr") ?? UserDefaults.standard
    private let categoriesKey = "SavedCategories"
    private let selectedFilterKey = "SelectedCategoryFilter"
    private let collapsedCategoriesKey = "CollapsedCategories"
    
    // Performance optimization: Cache category lookups
    private var categoryLookupCache: [UUID: TaskCategory] = [:]
    private var lastCacheUpdate = Date.distantPast
    private let cacheValidityDuration: TimeInterval = 5.0 // 5 second cache for categories
    
    // Category hierarchy for importance-based ordering
    private let categoryHierarchy: [String] = [
        "URGENT",
        "IMPORTANT", 
        "Work",
        "Health",
        "Learning",
        "Shopping",
        "Travel",
        "Personal",
        "Uncategorized"
    ]
    
    init() {
        loadCategories()
        loadSelectedFilter()
        loadCollapsedCategories()
        rebuildCache()
        
        // Ensure all current predefined categories are available
        // This handles cases where new predefined categories are added
        refreshPredefinedCategories()
        
        // Performance optimization: Ensure categories are expanded by default
        // This provides better UX as users expect to see their tasks immediately
        ensureDefaultExpandedState()
    }
    
    // MARK: - Cache Management
    
    private func rebuildCache() {
        categoryLookupCache.removeAll()
        for category in categories {
            categoryLookupCache[category.id] = category
        }
        lastCacheUpdate = Date()
    }
    
    private func isCacheValid() -> Bool {
        return Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration
    }
    
    // MARK: - Category Management
    
    func addCategory(_ category: TaskCategory) {
        categories.append(category)
        categoryLookupCache[category.id] = category
        saveCategories()
        HapticManager.shared.selectionChange()
    }
    
    /// Force refresh categories to ensure all predefined categories are loaded
    /// This is useful when new predefined categories are added to the app
    func refreshPredefinedCategories() {
        // Preserve custom categories
        let customCategories = categories.filter { $0.isCustom }
        
        // Reload with all current predefined categories
        categories = TaskCategory.predefined
        categories.append(contentsOf: customCategories)
        
        // Save and rebuild cache
        saveCategories()
        rebuildCache()
    }
    
    func updateCategory(_ category: TaskCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            categoryLookupCache[category.id] = category
            saveCategories()
        }
    }
    
    func deleteCategory(_ category: TaskCategory) {
        guard category.isCustom else { return } // Can't delete predefined categories
        
        categories.removeAll { $0.id == category.id }
        categoryLookupCache.removeValue(forKey: category.id)
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
    
    // MARK: - Category Collapse/Expand Management
    
    func toggleCategoryCollapse(_ category: TaskCategory?) {
        let categoryName = category?.name ?? "Uncategorized"
        
        // Optimized toggle with single haptic feedback and immediate save for reliability
        let wasCollapsed = collapsedCategories.contains(categoryName)
        
        if wasCollapsed {
            collapsedCategories.remove(categoryName)
        } else {
            collapsedCategories.insert(categoryName)
        }
        
        // Single haptic feedback for better performance
        HapticManager.shared.selectionChange()
        
        // Immediate save for better state persistence reliability
        // This ensures user preferences are never lost
        saveCollapsedCategories()
    }
    
    func isCategoryCollapsed(_ category: TaskCategory?) -> Bool {
        let categoryName = category?.name ?? "Uncategorized"
        // Categories are expanded by default for better UX
        // Only return true if explicitly collapsed by user
        return collapsedCategories.contains(categoryName)
    }
    
    func expandAllCategories() {
        collapsedCategories.removeAll()
        saveCollapsedCategories()
        HapticManager.shared.selectionChange()
    }
    
    func collapseAllCategories(except excludedCategory: TaskCategory? = nil) {
        let excludedName = excludedCategory?.name ?? "Uncategorized"
        
        // Add all category names except the excluded one
        for category in categories {
            if category.name != excludedName {
                collapsedCategories.insert(category.name)
            }
        }
        
        // Also handle uncategorized if it's not the excluded category
        if excludedName != "Uncategorized" {
            collapsedCategories.insert("Uncategorized")
        }
        
        saveCollapsedCategories()
        HapticManager.shared.selectionChange()
    }
    
    /// Ensures categories are expanded by default on first app launch
    /// This provides better UX as users expect to see their tasks immediately
    private func ensureDefaultExpandedState() {
        // Check if this is the first time the app is launched with collapse state
        let hasLaunchedBefore = userDefaults.bool(forKey: "HasLaunchedWithCollapseState")
        
        if !hasLaunchedBefore {
            // First launch - ensure all categories start expanded
            collapsedCategories.removeAll()
            saveCollapsedCategories()
            
            // Mark that we've set the default state
            userDefaults.set(true, forKey: "HasLaunchedWithCollapseState")
        }
        
        // Performance optimization: If no collapsed categories are saved,
        // ensure the set is empty for optimal performance
        if collapsedCategories.isEmpty {
            saveCollapsedCategories()
        }
    }
    
    // MARK: - Category Lookup (Optimized with Caching)
    
    func category(for id: UUID?) -> TaskCategory? {
        guard let id = id else { return nil }
        
        return PerformanceMonitor.shared.measure(PerformanceMonitor.MeasurementPoint.categoryLookup) {
            // Use cache if valid
            if isCacheValid(), let cachedCategory = categoryLookupCache[id] {
                return cachedCategory
            }
            
            // Fallback to linear search and update cache
            let category = categories.first { $0.id == id }
            if let category = category {
                categoryLookupCache[id] = category
            }
            return category
        }
    }
    
    func category(for task: Task) -> TaskCategory? {
        return category(for: task.categoryId)
    }
    
    // MARK: - Smart Category Suggestions
    
    func suggestCategory(for taskTitle: String) -> TaskCategory? {
        let title = taskTitle.lowercased()
        
        // Urgent-related keywords (highest priority)
        if title.contains("urgent") || title.contains("asap") || title.contains("emergency") ||
           title.contains("critical") || title.contains("immediate") || title.contains("rush") ||
           title.contains("now") || title.contains("overdue") || title.contains("late") {
            return categories.first { $0.name == "URGENT" }
        }
        
        // Important-related keywords (high priority)
        if title.contains("important") || title.contains("priority") || title.contains("significant") ||
           title.contains("key") || title.contains("essential") || title.contains("vital") ||
           title.contains("crucial") || title.contains("major") {
            return categories.first { $0.name == "IMPORTANT" }
        }
        
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
    
    // MARK: - Category Hierarchy and Grouping
    
    /// Returns the priority order for a category (lower number = higher priority)
    func categoryPriority(for category: TaskCategory?) -> Int {
        guard let category = category else { return categoryHierarchy.count } // Uncategorized goes last
        return categoryHierarchy.firstIndex(of: category.name) ?? categoryHierarchy.count
    }
    
    /// Groups tasks by category and returns them in hierarchical order
    func groupTasksByCategory(_ tasks: [Task]) -> [(category: TaskCategory?, tasks: [Task])] {
        // Group tasks by category
        let grouped = Dictionary(grouping: tasks) { task in
            category(for: task.categoryId)
        }
        
        // Sort categories by hierarchy and return with their tasks
        return grouped.sorted { first, second in
            let firstPriority = categoryPriority(for: first.key)
            let secondPriority = categoryPriority(for: second.key)
            return firstPriority < secondPriority
        }.map { (category: $0.key, tasks: $0.value) }
    }
    
    /// Returns categories that have tasks, sorted by hierarchy
    func categoriesWithTasks(from tasks: [Task]) -> [TaskCategory?] {
        let categoriesWithTasks = Set(tasks.compactMap { category(for: $0.categoryId) })
        let hasUncategorized = tasks.contains { $0.categoryId == nil }
        
        var result: [TaskCategory?] = []
        
        // Add categories in hierarchy order if they have tasks
        for categoryName in categoryHierarchy {
            if let category = categories.first(where: { $0.name == categoryName && categoriesWithTasks.contains($0) }) {
                result.append(category)
            }
        }
        
        // Add uncategorized if there are tasks without categories
        if hasUncategorized {
            result.append(nil)
        }
        
        return result
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
            
            // Trigger immediate widget update since categories affect widget filtering
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func loadCategories() {
        // First try to load all categories from saved data
        if let data = userDefaults.data(forKey: categoriesKey),
           let savedCategories = try? JSONDecoder().decode([TaskCategory].self, from: data) {
            
            // Separate saved categories into predefined and custom
            var customCategories: [TaskCategory] = []
            var existingPredefinedCategories: [TaskCategory] = []
            
            for savedCategory in savedCategories {
                if savedCategory.isCustom {
                    customCategories.append(savedCategory)
                } else {
                    // Check if this is a predefined category with the correct UUID
                    if TaskCategory.predefined.contains(where: { $0.id == savedCategory.id }) {
                        existingPredefinedCategories.append(savedCategory)
                    }
                    // If it's a predefined category with wrong UUID, we'll replace it
                }
            }
            
            // Start with the correct predefined categories (with fixed UUIDs)
            categories = TaskCategory.predefined
            
            // Add custom categories
            categories.append(contentsOf: customCategories)
            
            // If we had predefined categories with wrong UUIDs, we need to migrate tasks
            let savedPredefinedWithWrongUUIDs = savedCategories.filter { savedCategory in
                !savedCategory.isCustom && 
                !TaskCategory.predefined.contains(where: { $0.id == savedCategory.id }) &&
                TaskCategory.predefined.contains(where: { $0.name == savedCategory.name })
            }
            
            // If there are categories to migrate, we need to update task references
            if !savedPredefinedWithWrongUUIDs.isEmpty {
                migratePredefinedCategoryUUIDs(savedPredefinedWithWrongUUIDs)
            }
        } else {
            // No saved data - use default predefined categories for first launch
            categories = TaskCategory.predefined
        }
        
        // Always save the current state to persist UUIDs
        saveCategories()
        
        // Rebuild cache after loading categories
        rebuildCache()
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
    
    private func saveCollapsedCategories() {
        let collapsedArray = Array(collapsedCategories)
        userDefaults.set(collapsedArray, forKey: collapsedCategoriesKey)
        
        // Performance optimization: Synchronize immediately for better reliability
        userDefaults.synchronize()
    }
    
    private func loadCollapsedCategories() {
        if let collapsedArray = userDefaults.array(forKey: collapsedCategoriesKey) as? [String] {
            collapsedCategories = Set(collapsedArray)
        } else {
            // Default to empty set (all categories expanded) for better UX
            collapsedCategories = Set<String>()
        }
    }
    
    /// Resets all categories to expanded state - useful for troubleshooting or user preference reset
    func resetToExpandedState() {
        collapsedCategories.removeAll()
        saveCollapsedCategories()
        HapticManager.shared.selectionChange()
    }
    
    // MARK: - Migration
    
    /// Migrates tasks from old predefined category UUIDs to new fixed UUIDs
    private func migratePredefinedCategoryUUIDs(_ oldCategories: [TaskCategory]) {
        // Create mapping from old UUID to new UUID
        var uuidMapping: [UUID: UUID] = [:]
        
        for oldCategory in oldCategories {
            if let newCategory = TaskCategory.predefined.first(where: { $0.name == oldCategory.name }) {
                uuidMapping[oldCategory.id] = newCategory.id
            }
        }
        
        // Update tasks in UserDefaults directly since we don't have access to TaskManager here
        if let tasksData = userDefaults.data(forKey: "SavedTasks"),
           var tasks = try? JSONDecoder().decode([Task].self, from: tasksData) {
            
            var tasksUpdated = false
            
            for i in 0..<tasks.count {
                if let oldCategoryId = tasks[i].categoryId,
                   let newCategoryId = uuidMapping[oldCategoryId] {
                    tasks[i].categoryId = newCategoryId
                    tasksUpdated = true
                }
            }
            
            // Save updated tasks if any changes were made
            if tasksUpdated {
                if let encodedTasks = try? JSONEncoder().encode(tasks) {
                    userDefaults.set(encodedTasks, forKey: "SavedTasks")
                    print("Migrated \(uuidMapping.count) predefined category UUIDs")
                }
            }
        }
        
        // Update selected filter if it references an old UUID
        if let selectedFilter = selectedCategoryFilter,
           let newFilterId = uuidMapping[selectedFilter] {
            selectedCategoryFilter = newFilterId
            saveSelectedFilter()
        }
    }
}