//
//  PerformanceMonitor.swift
//  Simplr
//
//  Performance monitoring utility for tracking app performance
//

import Foundation
import os.log

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.danielzverev.simplr", category: "Performance")
    private var timers: [String: CFAbsoluteTime] = [:]
    
    private init() {}
    
    /// Start timing an operation
    func startTimer(_ identifier: String) {
        timers[identifier] = CFAbsoluteTimeGetCurrent()
    }
    
    /// End timing and log the duration
    func endTimer(_ identifier: String) {
        guard let startTime = timers[identifier] else {
            logger.warning("Timer '\(identifier)' was not started")
            return
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        timers.removeValue(forKey: identifier)
        
        #if DEBUG
        logger.info("⏱️ \(identifier): \(String(format: "%.3f", duration * 1000))ms")
        #endif
    }
    
    /// Measure the execution time of a closure
    func measure<T>(_ identifier: String, operation: () throws -> T) rethrows -> T {
        startTimer(identifier)
        defer { endTimer(identifier) }
        return try operation()
    }
    
    /// Measure async operations
    func measureAsync<T>(_ identifier: String, operation: () async throws -> T) async rethrows -> T {
        startTimer(identifier)
        defer { endTimer(identifier) }
        return try await operation()
    }
    
    /// Get current memory usage as a formatted string
    func getCurrentMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageInMB = Double(info.resident_size) / 1024.0 / 1024.0
            return String(format: "%.2f MB", memoryUsageInMB)
        } else {
            return "Unable to get memory info"
        }
    }
}

// MARK: - Convenience Extensions

extension PerformanceMonitor {
    /// Common performance measurement points
    enum MeasurementPoint {
        static let taskFiltering = "TaskFiltering"
        static let categoryLookup = "CategoryLookup"
        static let taskSaving = "TaskSaving"
        static let taskLoading = "TaskLoading"
        static let uiUpdate = "UIUpdate"
        static let searchOperation = "SearchOperation"
    }
}