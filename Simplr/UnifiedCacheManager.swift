//
//  UnifiedCacheManager.swift
//  Simplr
//
//  Created by Performance Optimization
//

import Foundation
import UIKit
import os.log

/// Thread-safe unified cache manager with LRU eviction and memory pressure handling
class UnifiedCacheManager {
    static let shared = UnifiedCacheManager()
    
    // MARK: - Cache Entry Structure
    
    private struct CacheEntry<T> {
        let value: T
        let timestamp: Date
        var accessCount: Int
        var lastAccessed: Date
        
        init(value: T) {
            self.value = value
            self.timestamp = Date()
            self.accessCount = 1
            self.lastAccessed = Date()
        }
        
        mutating func markAccessed() {
            accessCount += 1
            lastAccessed = Date()
        }
    }
    
    // MARK: - Cache Storage
    
    private var taskFilterCache: [String: CacheEntry<[Task]>] = [:]
    private var computedTaskCache: [String: CacheEntry<[Task]>] = [:]
    private var categoryTaskCache: [String: CacheEntry<[Task]>] = [:]
    
    // MARK: - Configuration
    
    private let maxCacheSize: Int
    private let cacheValidityDuration: TimeInterval
    private let backgroundCacheSize: Int
    private let cleanupInterval: TimeInterval
    
    // MARK: - Thread Safety
    
    private let cacheQueue = DispatchQueue(label: "com.simplr.cache", qos: .userInitiated, attributes: .concurrent)
    private let backgroundQueue = DispatchQueue(label: "com.simplr.cache.background", qos: .utility)
    
    // MARK: - Memory Management
    
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    private var cleanupTimer: Timer?
    private var isMemoryPressureActive = false
    
    // MARK: - Performance Metrics
    
    private var cacheHits = 0
    private var cacheMisses = 0
    private var evictionCount = 0
    
    // MARK: - Initialization
    
    private init() {
        self.maxCacheSize = PerformanceConfig.Cache.maxFilteredTasksCacheSize
        self.cacheValidityDuration = PerformanceConfig.Cache.cacheValidityDuration
        self.backgroundCacheSize = PerformanceConfig.Cache.backgroundCacheSize
        self.cleanupInterval = PerformanceConfig.Memory.cleanupInterval
        
        setupMemoryPressureMonitoring()
        setupPeriodicCleanup()
        setupAppLifecycleObservers()
    }
    
    deinit {
        memoryPressureSource?.cancel()
        cleanupTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Cache Interface
    
    /// Get cached filtered tasks with thread-safe access
    func getCachedFilteredTasks(for key: String) -> [Task]? {
        return cacheQueue.sync {
            guard let entry = taskFilterCache[key],
                  isEntryValid(entry) else {
                cacheMisses += 1
                return nil
            }
            
            // Update access information
            taskFilterCache[key]?.markAccessed()
            cacheHits += 1
            return entry.value
        }
    }
    
    /// Cache filtered tasks with automatic size management
    func setCachedFilteredTasks(_ tasks: [Task], for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.taskFilterCache[key] = CacheEntry(value: tasks)
            self.enforceMemoryLimits()
        }
    }
    
    /// Get cached computed tasks (overdue, pending, etc.)
    func getCachedComputedTasks(for key: String) -> [Task]? {
        return cacheQueue.sync {
            guard let entry = computedTaskCache[key],
                  isEntryValid(entry) else {
                cacheMisses += 1
                return nil
            }
            
            computedTaskCache[key]?.markAccessed()
            cacheHits += 1
            return entry.value
        }
    }
    
    /// Cache computed tasks
    func setCachedComputedTasks(_ tasks: [Task], for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.computedTaskCache[key] = CacheEntry(value: tasks)
            self.enforceMemoryLimits()
        }
    }
    
    /// Get cached category tasks
    func getCachedCategoryTasks(for key: String) -> [Task]? {
        return cacheQueue.sync {
            guard let entry = categoryTaskCache[key],
                  isEntryValid(entry) else {
                cacheMisses += 1
                return nil
            }
            
            categoryTaskCache[key]?.markAccessed()
            cacheHits += 1
            return entry.value
        }
    }
    
    /// Cache category tasks
    func setCachedCategoryTasks(_ tasks: [Task], for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.categoryTaskCache[key] = CacheEntry(value: tasks)
            self.enforceMemoryLimits()
        }
    }
    
    /// Invalidate all caches
    func invalidateAllCaches() {
        cacheQueue.async(flags: .barrier) {
            self.taskFilterCache.removeAll(keepingCapacity: !self.isMemoryPressureActive)
            self.computedTaskCache.removeAll(keepingCapacity: !self.isMemoryPressureActive)
            self.categoryTaskCache.removeAll(keepingCapacity: !self.isMemoryPressureActive)
        }
    }
    
    /// Invalidate specific cache type
    func invalidateCache(type: CacheType) {
        cacheQueue.async(flags: .barrier) {
            switch type {
            case .filteredTasks:
                self.taskFilterCache.removeAll(keepingCapacity: !self.isMemoryPressureActive)
            case .computedTasks:
                self.computedTaskCache.removeAll(keepingCapacity: !self.isMemoryPressureActive)
            case .categoryTasks:
                self.categoryTaskCache.removeAll(keepingCapacity: !self.isMemoryPressureActive)
            }
        }
    }
    
    // MARK: - Cache Types
    
    enum CacheType {
        case filteredTasks
        case computedTasks
        case categoryTasks
    }
    
    // MARK: - Private Methods
    
    private func isEntryValid<T>(_ entry: CacheEntry<T>) -> Bool {
        return Date().timeIntervalSince(entry.timestamp) < cacheValidityDuration
    }
    
    private func enforceMemoryLimits() {
        let currentLimit = isMemoryPressureActive ? backgroundCacheSize : maxCacheSize
        let totalEntries = taskFilterCache.count + computedTaskCache.count + categoryTaskCache.count
        
        guard totalEntries > currentLimit else { return }
        
        // Calculate how many entries to remove from each cache
        let entriesToRemove = totalEntries - currentLimit
        let removalPerCache = max(1, entriesToRemove / 3)
        
        // Remove LRU entries from each cache
        evictLRUEntries(from: &taskFilterCache, count: removalPerCache)
        evictLRUEntries(from: &computedTaskCache, count: removalPerCache)
        evictLRUEntries(from: &categoryTaskCache, count: removalPerCache)
        
        evictionCount += entriesToRemove
    }
    
    private func evictLRUEntries<T>(from cache: inout [String: CacheEntry<T>], count: Int) {
        guard cache.count > count else {
            cache.removeAll(keepingCapacity: !isMemoryPressureActive)
            return
        }
        
        // Sort by last accessed time and access count (LRU with frequency consideration)
        let sortedKeys = cache.keys.sorted { key1, key2 in
            let entry1 = cache[key1]!
            let entry2 = cache[key2]!
            
            // Primary sort: last accessed time
            if entry1.lastAccessed != entry2.lastAccessed {
                return entry1.lastAccessed < entry2.lastAccessed
            }
            
            // Secondary sort: access count (less frequently used first)
            return entry1.accessCount < entry2.accessCount
        }
        
        // Remove the least recently used entries
        for key in sortedKeys.prefix(count) {
            cache.removeValue(forKey: key)
        }
    }
    
    // MARK: - Memory Pressure Handling
    
    private func setupMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: backgroundQueue
        )
        
        memoryPressureSource?.setEventHandler { [weak self] in
            self?.handleMemoryPressure()
        }
        
        memoryPressureSource?.resume()
        
        // Also listen for UIKit memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func handleMemoryPressure() {
        isMemoryPressureActive = true
        
        cacheQueue.async(flags: .barrier) {
            // Aggressively reduce cache size during memory pressure
            let targetSize = self.backgroundCacheSize / 2
            
            // Keep only the most recently accessed entries
            self.reduceCache(&self.taskFilterCache, to: targetSize)
            self.reduceCache(&self.computedTaskCache, to: targetSize)
            self.reduceCache(&self.categoryTaskCache, to: targetSize)
            
            print("UnifiedCacheManager: Reduced cache size due to memory pressure")
        }
        
        // Reset memory pressure flag after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.isMemoryPressureActive = false
        }
    }
    
    private func handleMemoryWarning() {
        cacheQueue.async(flags: .barrier) {
            // Clear all caches during memory warning
            self.taskFilterCache.removeAll(keepingCapacity: false)
            self.computedTaskCache.removeAll(keepingCapacity: false)
            self.categoryTaskCache.removeAll(keepingCapacity: false)
            
            print("UnifiedCacheManager: Cleared all caches due to memory warning")
        }
    }
    
    private func reduceCache<T>(_ cache: inout [String: CacheEntry<T>], to targetSize: Int) {
        guard cache.count > targetSize else { return }
        
        let sortedKeys = cache.keys.sorted { key1, key2 in
            let entry1 = cache[key1]!
            let entry2 = cache[key2]!
            
            // Keep most recently accessed and frequently used entries
            if entry1.lastAccessed != entry2.lastAccessed {
                return entry1.lastAccessed > entry2.lastAccessed
            }
            
            return entry1.accessCount > entry2.accessCount
        }
        
        // Keep only the top entries
        let keysToKeep = Set(sortedKeys.prefix(targetSize))
        cache = cache.filter { keysToKeep.contains($0.key) }
    }
    
    // MARK: - Periodic Cleanup
    
    private func setupPeriodicCleanup() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            self?.performPeriodicCleanup()
        }
    }
    
    private func performPeriodicCleanup() {
        backgroundQueue.async {
            self.cacheQueue.async(flags: .barrier) {
                self.removeExpiredEntries()
                self.enforceMemoryLimits()
            }
        }
    }
    
    private func removeExpiredEntries() {
        let now = Date()
        
        taskFilterCache = taskFilterCache.filter { _, entry in
            now.timeIntervalSince(entry.timestamp) < cacheValidityDuration * 2
        }
        
        computedTaskCache = computedTaskCache.filter { _, entry in
            now.timeIntervalSince(entry.timestamp) < cacheValidityDuration * 2
        }
        
        categoryTaskCache = categoryTaskCache.filter { _, entry in
            now.timeIntervalSince(entry.timestamp) < cacheValidityDuration * 2
        }
    }
    
    // MARK: - App Lifecycle
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppForeground()
        }
    }
    
    private func handleAppBackground() {
        cacheQueue.async(flags: .barrier) {
            // Reduce cache size when app goes to background
            self.reduceCache(&self.taskFilterCache, to: self.backgroundCacheSize)
            self.reduceCache(&self.computedTaskCache, to: self.backgroundCacheSize)
            self.reduceCache(&self.categoryTaskCache, to: self.backgroundCacheSize)
        }
    }
    
    private func handleAppForeground() {
        // Reset memory pressure state when app becomes active
        isMemoryPressureActive = false
    }
    
    // MARK: - Performance Metrics
    
    func getCacheMetrics() -> CacheMetrics {
        return cacheQueue.sync {
            CacheMetrics(
                hitRate: cacheHits + cacheMisses > 0 ? Double(cacheHits) / Double(cacheHits + cacheMisses) : 0,
                totalEntries: taskFilterCache.count + computedTaskCache.count + categoryTaskCache.count,
                evictionCount: evictionCount,
                memoryPressureActive: isMemoryPressureActive
            )
        }
    }
}

// MARK: - Cache Metrics

struct CacheMetrics {
    let hitRate: Double
    let totalEntries: Int
    let evictionCount: Int
    let memoryPressureActive: Bool
}

// MARK: - Cache Key Generators

extension UnifiedCacheManager {
    
    /// Generate cache key for filtered tasks
    static func filteredTasksKey(categoryId: UUID?, searchText: String, filterOption: FilterOption) -> String {
        return "filtered_\(categoryId?.uuidString ?? "nil")_\(searchText)_\(filterOption.rawValue)"
    }
    
    /// Generate cache key for computed tasks
    static func computedTasksKey(type: String) -> String {
        return "computed_\(type)"
    }
    
    /// Generate cache key for category tasks
    static func categoryTasksKey(categoryId: UUID?) -> String {
        return "category_\(categoryId?.uuidString ?? "nil")"
    }
}