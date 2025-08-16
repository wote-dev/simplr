//
//  AppPerformanceAnalytics.swift
//  Simplr
//
//  Created by Performance Analytics for App Store optimization
//

import Foundation
import SwiftUI
import os.log
import MetricKit
import UIKit

extension Notification.Name {
    static let performanceMemoryWarning = Notification.Name("performanceMemoryWarning")
}

/// Performance analytics and monitoring for App Store optimization
class AppPerformanceAnalytics {
    static let shared = AppPerformanceAnalytics()
    
    private let logger = Logger(subsystem: "com.danielzverev.simplr", category: "PerformanceAnalytics")
    private var performanceSnapshots: [PerformanceSnapshot] = []
    
    private init() {}
    
    // MARK: - Performance Snapshot
    struct PerformanceSnapshot: Codable {
        let timestamp: Date
        let appLaunchTime: TimeInterval
        let memoryUsage: Double
        let frameRate: Double
        let cacheHitRatio: Double
        
        init(timestamp: Date = Date(), appLaunchTime: TimeInterval = 0, memoryUsage: Double = 0, frameRate: Double = 60, cacheHitRatio: Double = 0) {
            self.timestamp = timestamp
            self.appLaunchTime = appLaunchTime
            self.memoryUsage = memoryUsage
            self.frameRate = frameRate
            self.cacheHitRatio = cacheHitRatio
        }
    }
    
    // MARK: - Memory Management
    func recordMemoryWarning() {
        logger.warning("Memory warning recorded")
        NotificationCenter.default.post(name: .performanceMemoryWarning, object: nil)
    }
    
    // MARK: - Performance Tracking
    func recordPerformanceSnapshot(_ snapshot: PerformanceSnapshot) {
        performanceSnapshots.append(snapshot)
        
        // Keep only last 100 snapshots
        if performanceSnapshots.count > 100 {
            performanceSnapshots.removeFirst()
        }
    }
    
    // MARK: - Analytics Methods
    func getRecentSnapshots(limit: Int = 10) -> [PerformanceSnapshot] {
        return Array(performanceSnapshots.suffix(limit))
    }
    
    func calculateAverageLaunchTime() -> TimeInterval {
        guard !performanceSnapshots.isEmpty else { return 0 }
        return performanceSnapshots.reduce(0) { $0 + $1.appLaunchTime } / Double(performanceSnapshots.count)
    }
    
    func getPerformanceSummary() -> [String: Any] {
        return [
            "totalSnapshots": performanceSnapshots.count,
            "averageLaunchTime": calculateAverageLaunchTime(),
            "latestMemoryUsage": performanceSnapshots.last?.memoryUsage ?? 0,
            "averageFrameRate": performanceSnapshots.last?.frameRate ?? 60
        ]
    }
    
    // MARK: - Memory Optimization
    func clearOldSnapshots() {
        let cutoffDate = Date().addingTimeInterval(-3600) // 1 hour ago
        performanceSnapshots.removeAll { $0.timestamp < cutoffDate }
    }
    
    // MARK: - App Launch Metrics
    func recordAppLaunchTime(_ launchTime: TimeInterval) {
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            appLaunchTime: launchTime,
            memoryUsage: getCurrentMemoryUsage(),
            frameRate: 60,
            cacheHitRatio: 0.8
        )
        recordPerformanceSnapshot(snapshot)
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        
        return 0
    }
}