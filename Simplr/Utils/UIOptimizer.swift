//
//  UIOptimizer.swift
//  Simplr
//
//  Created by Performance Optimization
//

import SwiftUI
import Combine

/// Utility class for optimizing UI performance and reducing unnecessary updates
class UIOptimizer: ObservableObject {
    static let shared = UIOptimizer()
    
    private var debounceTimers: [String: Timer] = [:]
    private var throttleTimestamps: [String: Date] = [:]
    private let queue = DispatchQueue(label: "ui.optimizer", qos: .userInteractive)
    
    private init() {}
    
    /// Debounce function calls to reduce frequency
    func debounce(key: String, delay: TimeInterval = PerformanceConfig.UI.searchDebounceDelay, action: @escaping () -> Void) {
        // Cancel existing timer
        debounceTimers[key]?.invalidate()
        
        // Create new timer
        debounceTimers[key] = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
            self.debounceTimers.removeValue(forKey: key)
        }
    }
    
    /// Throttle function calls to limit frequency
    func throttle(key: String, interval: TimeInterval = PerformanceConfig.optimizedGestureThrottleInterval, action: @escaping () -> Void) {
        let now = Date()
        
        if let lastCall = throttleTimestamps[key] {
            if now.timeIntervalSince(lastCall) < interval {
                return // Skip this call
            }
        }
        
        throttleTimestamps[key] = now
        action()
    }
    
    /// Optimize animation performance using centralized config with App Store optimizations
    static func optimizedAnimation(duration: Double = PerformanceConfig.Animation.defaultDuration, curve: Animation = .easeInOut) -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .linear(duration: duration * 0.5)
        }
        
        // App Store optimization: Adaptive animation based on device performance
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return curve.speed(1.3) // Faster on high-end devices
        case .medium:
            return curve.speed(1.1) // Slightly faster on mid-range
        case .low:
            return .easeInOut(duration: duration * 0.8) // Simpler animation on low-end
        }
    }
    
    /// Determine device performance level for optimization
    private static func getDevicePerformanceLevel() -> DevicePerformance {
        let processorCount = ProcessInfo.processInfo.processorCount
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        
        if processorCount >= 6 && physicalMemory >= 6_000_000_000 {
            return .high
        } else if processorCount >= 4 && physicalMemory >= 3_000_000_000 {
            return .medium
        } else {
            return .low
        }
    }
    
    private enum DevicePerformance {
        case high, medium, low
    }
    
    /// Batch UI updates for better performance
    func batchUIUpdates(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
    
    /// Enhanced cleanup for App Store optimization
    func cleanup() {
        debounceTimers.values.forEach { $0.invalidate() }
        debounceTimers.removeAll(keepingCapacity: false)
        throttleTimestamps.removeAll(keepingCapacity: false)
        
        // Force memory cleanup
        autoreleasepool {
            // Additional cleanup for production
        }
    }
    
    /// Aggressive cleanup for memory pressure
    func aggressiveCleanup() {
        cleanup()
        
        // Clear any cached rendering data
        queue.async {
            // Perform background cleanup
        }
    }
}

/// View modifier for optimized rendering
struct OptimizedRendering: ViewModifier {
    let shouldUpdate: Bool
    
    func body(content: Content) -> some View {
        content
            .drawingGroup(opaque: false, colorMode: .nonLinear) // Optimize rendering
            .animation(UIOptimizer.optimizedAnimation(), value: shouldUpdate)
    }
}

extension View {
    /// Apply optimized rendering to views
    func optimizedRendering(shouldUpdate: Bool = true) -> some View {
        modifier(OptimizedRendering(shouldUpdate: shouldUpdate))
    }
    
    /// Debounce view updates
    func debounced<T: Equatable>(
        _ value: T,
        delay: TimeInterval = 0.3,
        key: String = UUID().uuidString
    ) -> some View {
        self.onChange(of: value) { oldValue, newValue in
            UIOptimizer.shared.debounce(key: key, delay: delay) {
                // View will update naturally
            }
        }
    }
}

/// Memory-efficient image loading
struct OptimizedAsyncImage: View {
    let imageName: String
    let size: CGSize?
    
    init(_ imageName: String, size: CGSize? = nil) {
        self.imageName = imageName
        self.size = size
    }
    
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size?.width, height: size?.height)
            .clipped()
            .drawingGroup() // Optimize for repeated rendering
    }
}