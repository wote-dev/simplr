//
//  PerformanceConfig.swift
//  Simplr
//
//  Created by Performance Optimization
//

import Foundation
import SwiftUI

/// Centralized performance configuration for the app
struct PerformanceConfig {
    
    // MARK: - Cache Settings
    struct Cache {
        static let maxFilteredTasksCacheSize = 20
        static let cacheValidityDuration: TimeInterval = 0.5
        static let backgroundCacheSize = 5
        static let memoryWarningCacheSize = 0
    }
    
    // MARK: - Animation Settings
    struct Animation {
        static let defaultDuration: Double = 0.3
        static let fastDuration: Double = 0.15
        static let slowDuration: Double = 0.6
        static let springResponse: Double = 0.4
        static let springDamping: Double = 0.8
        
        // Optimized animations for better performance
        static let optimizedFast = SwiftUI.Animation.easeInOut(duration: fastDuration).speed(1.2)
        static let optimizedDefault = SwiftUI.Animation.easeInOut(duration: defaultDuration).speed(1.2)
        static let optimizedSlow = SwiftUI.Animation.easeInOut(duration: slowDuration).speed(1.1)
        static let optimizedSpring = SwiftUI.Animation.spring(response: springResponse, dampingFraction: springDamping).speed(1.1)
    }
    
    // MARK: - UI Settings
    struct UI {
        static let searchDebounceDelay: TimeInterval = 0.2
        static let batchUpdateDelay: TimeInterval = 0.1
        static let gestureThrottleInterval: TimeInterval = 0.016 // ~60fps
        static let highPerformanceThrottleInterval: TimeInterval = 0.008 // ~120fps
        static let minimumSearchLength = 2
        static let maxVisibleTasks = 100 // Limit for very large task lists
    }
    
    // MARK: - Memory Settings
    struct Memory {
        static let memoryWarningThreshold: Double = 100.0 // MB
        static let criticalMemoryThreshold: Double = 150.0 // MB
        static let backgroundMemoryReduction: Double = 0.5 // Reduce cache by 50%
        static let cleanupInterval: TimeInterval = 300.0 // 5 minutes
    }
    
    // MARK: - Performance Monitoring
    struct Monitoring {
        static let enablePerformanceLogging = false // Set to true for debugging
        static let slowOperationThreshold: TimeInterval = 0.1 // 100ms
        static let memoryCheckInterval: TimeInterval = 30.0 // 30 seconds
    }
    
    // MARK: - Haptic Settings
    struct Haptics {
        static let enableHaptics = true
        static let prepareHapticsInAdvance = true
        static let hapticIntensity: Float = 1.0
    }
    
    // MARK: - Network Settings
    struct Network {
        static let requestTimeout: TimeInterval = 10.0
        static let maxConcurrentRequests = 3
        static let cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad
    }
    
    // MARK: - Device-Specific Optimizations
    static var isHighPerformanceDevice: Bool {
        // Check if device supports high refresh rate
        if #available(iOS 15.0, *) {
            return UIScreen.main.maximumFramesPerSecond > 60
        }
        return false
    }
    
    static var shouldUseReducedAnimations: Bool {
        return UIAccessibility.isReduceMotionEnabled
    }
    
    static var optimizedGestureThrottleInterval: TimeInterval {
        return isHighPerformanceDevice ? UI.highPerformanceThrottleInterval : UI.gestureThrottleInterval
    }
    
    // MARK: - Dynamic Performance Adjustment
    static func adjustForMemoryPressure(_ level: MemoryManager.MemoryPressureLevel) -> PerformanceSettings {
        switch level {
        case .normal:
            return PerformanceSettings(
                cacheSize: Cache.maxFilteredTasksCacheSize,
                animationDuration: Animation.defaultDuration,
                enableComplexAnimations: true,
                maxVisibleItems: UI.maxVisibleTasks
            )
        case .warning:
            return PerformanceSettings(
                cacheSize: Cache.backgroundCacheSize,
                animationDuration: Animation.fastDuration,
                enableComplexAnimations: false,
                maxVisibleItems: UI.maxVisibleTasks / 2
            )
        case .critical:
            return PerformanceSettings(
                cacheSize: Cache.memoryWarningCacheSize,
                animationDuration: Animation.fastDuration,
                enableComplexAnimations: false,
                maxVisibleItems: UI.maxVisibleTasks / 4
            )
        }
    }
}

/// Dynamic performance settings that can be adjusted based on device state
struct PerformanceSettings {
    let cacheSize: Int
    let animationDuration: Double
    let enableComplexAnimations: Bool
    let maxVisibleItems: Int
}

/// Performance monitoring utilities
class PerformanceTracker {
    static let shared = PerformanceTracker()
    
    private var operationTimes: [String: TimeInterval] = [:]
    private let queue = DispatchQueue(label: "performance.tracker", qos: .utility)
    
    private init() {}
    
    func trackOperation<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        guard PerformanceConfig.Monitoring.enablePerformanceLogging else {
            return try operation()
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        queue.async {
            self.operationTimes[name] = timeElapsed
            
            if timeElapsed > PerformanceConfig.Monitoring.slowOperationThreshold {
                print("⚠️ Slow operation detected: \(name) took \(String(format: "%.3f", timeElapsed))s")
            }
        }
        
        return result
    }
    
    func getAverageTime(for operation: String) -> TimeInterval? {
        return operationTimes[operation]
    }
    
    func reset() {
        queue.async {
            self.operationTimes.removeAll()
        }
    }
}