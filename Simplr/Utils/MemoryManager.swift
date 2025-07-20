//
//  MemoryManager.swift
//  Simplr
//
//  Created by Performance Optimization
//

import Foundation
import UIKit
import SwiftUI

/// Utility class for managing memory usage and preventing memory leaks
class MemoryManager: ObservableObject {
    static let shared = MemoryManager()
    
    private var memoryWarningObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?
    
    @Published var memoryPressure: MemoryPressureLevel = .normal
    
    enum MemoryPressureLevel {
        case normal
        case warning
        case critical
    }
    
    private init() {
        setupMemoryMonitoring()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupMemoryMonitoring() {
        // Monitor memory warnings
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        
        // Monitor app lifecycle for memory optimization
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppBackground()
        }
        
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppForeground()
        }
    }
    
    private func handleMemoryWarning() {
        memoryPressure = .critical
        
        // Notify managers to clear caches
        NotificationCenter.default.post(name: .memoryWarning, object: nil)
        
        // Aggressive cleanup for App Store quality
        performAggressiveCleanup()
        
        // Reset memory pressure after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.memoryPressure = .normal
        }
    }
    
    /// Perform aggressive cleanup for App Store optimization
    private func performAggressiveCleanup() {
        DispatchQueue.global(qos: .utility).async {
            autoreleasepool {
                // Clear URL cache completely
                URLCache.shared.removeAllCachedResponses()
                
                // Clear image cache
                self.clearImageCaches()
                
                // Force UI optimizer cleanup
                DispatchQueue.main.async {
                    UIOptimizer.shared.aggressiveCleanup()
                }
                
                // Trigger garbage collection
                self.forceGarbageCollection()
            }
        }
    }
    
    private func clearImageCaches() {
        // Clear any cached images
        let cache = NSCache<NSString, UIImage>()
        cache.removeAllObjects()
    }
    
    private func forceGarbageCollection() {
        // Multiple autoreleasepool calls to ensure cleanup
        for _ in 0..<3 {
            autoreleasepool {
                // Force cleanup
            }
        }
    }
    
    private func handleAppBackground() {
        // Clear caches when app goes to background
        UIOptimizer.shared.cleanup()
        
        // Notify managers to reduce memory usage
        NotificationCenter.default.post(name: .appDidEnterBackground, object: nil)
    }
    
    private func handleAppForeground() {
        // Reset memory pressure when returning to foreground
        memoryPressure = .normal
    }
    
    /// Get current memory usage in MB
    func getCurrentMemoryUsage() -> Double {
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
            return Double(info.resident_size) / 1024.0 / 1024.0
        }
        
        return 0.0
    }
    
    /// Check if memory usage is high with App Store thresholds
    func isMemoryUsageHigh() -> Bool {
        let currentUsage = getCurrentMemoryUsage()
        return currentUsage > PerformanceConfig.Memory.memoryWarningThreshold
    }
    
    /// Check if memory usage is critical
    func isMemoryUsageCritical() -> Bool {
        let currentUsage = getCurrentMemoryUsage()
        return currentUsage > PerformanceConfig.Monitoring.criticalMemoryThreshold
    }
    
    /// Get memory usage percentage (0.0 to 1.0)
    func getMemoryUsagePercentage() -> Double {
        let currentUsage = getCurrentMemoryUsage()
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0
        return min(currentUsage / totalMemory, 1.0)
    }
    
    /// Force memory cleanup
    func forceCleanup() {
        autoreleasepool {
            // Clear URL cache
            URLCache.shared.removeAllCachedResponses()
            
            // Clear UI optimizer caches
            UIOptimizer.shared.cleanup()
            
            // Notify all managers to clear their caches
            NotificationCenter.default.post(name: .forceMemoryCleanup, object: nil)
        }
    }
    
    private func cleanup() {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let memoryWarning = Notification.Name("memoryWarning")
    static let forceMemoryCleanup = Notification.Name("forceMemoryCleanup")
    static let appDidEnterBackground = Notification.Name("appDidEnterBackground")
}

// MARK: - Memory-Aware View Modifier
struct MemoryAware: ViewModifier {
    @StateObject private var memoryManager = MemoryManager.shared
    let onMemoryWarning: (() -> Void)?
    
    init(onMemoryWarning: (() -> Void)? = nil) {
        self.onMemoryWarning = onMemoryWarning
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: memoryManager.memoryPressure) { oldValue, newValue in
                if newValue == .critical {
                    onMemoryWarning?()
                }
            }
    }
}

extension View {
    /// Make view memory-aware and respond to memory warnings
    func memoryAware(onMemoryWarning: (() -> Void)? = nil) -> some View {
        modifier(MemoryAware(onMemoryWarning: onMemoryWarning))
    }
}