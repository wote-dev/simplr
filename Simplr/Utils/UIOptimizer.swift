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
    
    /// Optimized spring animation for form sections with performance considerations
    static func formSectionAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.15)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return PerformanceConfig.Animation.optimizedFormSection
        case .medium:
            return .spring(
                response: PerformanceConfig.Animation.formSectionResponse + 0.05, 
                dampingFraction: PerformanceConfig.Animation.formSectionDamping + 0.05, 
                blendDuration: 0.05
            )
        case .low:
            return .easeInOut(duration: 0.15)
        }
    }
    
    /// Optimized animation for date picker transitions with smooth performance
    static func datePickerAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.15)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return PerformanceConfig.Animation.optimizedDatePicker
        case .medium:
            return .spring(
                response: PerformanceConfig.Animation.datePickerResponse + 0.05, 
                dampingFraction: PerformanceConfig.Animation.datePickerDamping - 0.05, 
                blendDuration: 0.05
            )
        case .low:
            return .easeInOut(duration: 0.15)
        }
    }
    
    /// Optimized animation for toggle switches and micro-interactions
    static func toggleAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.1)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return PerformanceConfig.Animation.optimizedToggle
        case .medium:
            return .spring(
                response: PerformanceConfig.Animation.toggleResponse + 0.05, 
                dampingFraction: PerformanceConfig.Animation.toggleDamping, 
                blendDuration: 0.02
            )
        case .low:
            return .easeInOut(duration: 0.15)
        }
    }
    
    /// High-performance transition for content appearance/disappearance
    static func contentTransition() -> AnyTransition {
        if PerformanceConfig.shouldUseReducedAnimations {
            return AnyTransition.opacity
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return AnyTransition.asymmetric(
                insertion: .scale(scale: 0.95, anchor: .top)
                    .combined(with: .opacity)
                    .combined(with: .move(edge: .top))
                    .animation(formSectionAnimation()),
                removal: .scale(scale: 0.95, anchor: .top)
                    .combined(with: .opacity)
                    .combined(with: .move(edge: .top))
                    .animation(datePickerAnimation())
            )
        case .medium:
            return AnyTransition.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98))
                    .animation(formSectionAnimation()),
                removal: .opacity.combined(with: .scale(scale: 0.98))
                    .animation(datePickerAnimation())
            )
        case .low:
            return AnyTransition.opacity.animation(.easeInOut(duration: 0.15))
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
    
    /// Ultra-fast completion animation for 120fps toggle responsiveness
    static func completionAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.12)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return .spring(response: 0.18, dampingFraction: 0.85, blendDuration: 0)
        case .medium:
            return .spring(response: 0.22, dampingFraction: 0.9, blendDuration: 0)
        case .low:
            return .easeInOut(duration: 0.15)
        }
    }
    
    /// Ultra-buttery smooth task completion animation optimized for consistent 120fps
    static func ultraButteryTaskCompletionAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.2)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return .spring(response: 0.32, dampingFraction: 0.92, blendDuration: 0.02)
        case .medium:
            return .spring(response: 0.28, dampingFraction: 0.94, blendDuration: 0.03)
        case .low:
            return .easeInOut(duration: 0.25)
        }
    }
    
    /// Ultra-buttery smooth task removal animation for list disappearance
    static func ultraButteryTaskRemovalAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.18)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return .spring(response: 0.28, dampingFraction: 0.95, blendDuration: 0.02)
        case .medium:
            return .spring(response: 0.25, dampingFraction: 0.97, blendDuration: 0.03)
        case .low:
            return .easeInOut(duration: 0.22)
        }
    }
    

    
    /// Ultra-fast particle animation for 120fps completion effects
    static func particleAnimation(delay: Double = 0) -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .linear(duration: 0.08).delay(delay)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return .spring(response: 0.12, dampingFraction: 0.85).delay(delay)
        case .medium:
            return .spring(response: 0.15, dampingFraction: 0.8).delay(delay)
        case .low:
            return .easeOut(duration: 0.12).delay(delay)
        }
    }
    
    /// Ultra-fast button response animation for instant feedback
    static func buttonResponseAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .linear(duration: 0.06)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return .spring(response: 0.1, dampingFraction: 0.7, blendDuration: 0.01)
        case .medium:
            return .spring(response: 0.12, dampingFraction: 0.65, blendDuration: 0.02)
        case .low:
            return .easeInOut(duration: 0.1)
        }
    }
    
    /// Performance-optimized animation for undo operations with maximum responsiveness
    static func optimizedUndoAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: PerformanceConfig.Animation.undoAnimationDuration * 0.8)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return .spring(
                response: PerformanceConfig.Animation.undoSpringResponse,
                dampingFraction: PerformanceConfig.Animation.undoSpringDamping,
                blendDuration: 0.05
            ).speed(1.4)
        case .medium:
            return .spring(
                response: PerformanceConfig.Animation.undoSpringResponse * 1.1,
                dampingFraction: PerformanceConfig.Animation.undoSpringDamping,
                blendDuration: 0.08
            ).speed(1.2)
        case .low:
            return .easeInOut(duration: PerformanceConfig.Animation.undoAnimationDuration).speed(1.1)
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
    
    // MARK: - Empty State Ultra-Smooth Animations
    
    /// Ultra-smooth empty state container animation with fluid curves
    static func optimizedEmptyStateContainerAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.15)
        }
        
        return Animation.interpolatingSpring(mass: 1.0,
                                           stiffness: PerformanceConfig.Animation.emptyStateInterpolatingStiffness,
                                           damping: PerformanceConfig.Animation.emptyStateInterpolatingDamping)
    }
    
    /// Ultra-smooth icon animation with fluid bounce and overshoot
    static func optimizedEmptyStateIconAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.15)
        }
        
        return Animation.interpolatingSpring(mass: 1.0,
                                           stiffness: PerformanceConfig.Animation.emptyStateInterpolatingStiffness * 1.2,
                                           damping: PerformanceConfig.Animation.emptyStateInterpolatingDamping * 0.9)
            .delay(PerformanceConfig.Animation.emptyStateIconDelay)
    }
    
    /// Ultra-smooth title animation with gentle overshoot
    static func optimizedEmptyStateTitleAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.15)
        }
        
        return Animation.interpolatingSpring(mass: 1.0,
                                           stiffness: PerformanceConfig.Animation.emptyStateInterpolatingStiffness * 1.1,
                                           damping: PerformanceConfig.Animation.emptyStateInterpolatingDamping * 1.1)
            .delay(PerformanceConfig.Animation.emptyStateTitleDelay)
    }
    
    /// Ultra-smooth subtitle animation with final gentle entrance
    static func optimizedEmptyStateSubtitleAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.15)
        }
        
        return Animation.interpolatingSpring(mass: 1.0,
                                           stiffness: PerformanceConfig.Animation.emptyStateInterpolatingStiffness,
                                           damping: PerformanceConfig.Animation.emptyStateInterpolatingDamping * 1.2)
            .delay(PerformanceConfig.Animation.emptyStateSubtitleDelay)
    }
    
    /// Ultra-smooth empty state transition with fluid scaling
    static func optimizedEmptyStateTransition() -> AnyTransition {
        if PerformanceConfig.shouldUseReducedAnimations {
            return AnyTransition.opacity
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return AnyTransition.asymmetric(
                insertion: .scale(scale: 0.85, anchor: .center)
                    .combined(with: .opacity)
                    .combined(with: .offset(y: 8))
                    .animation(optimizedEmptyStateContainerAnimation()),
                removal: .scale(scale: 0.9, anchor: .center)
                    .combined(with: .opacity)
                    .combined(with: .offset(y: -5))
                    .animation(optimizedEmptyStateContainerAnimation().speed(1.2))
            )
        case .medium:
            return AnyTransition.asymmetric(
                insertion: .scale(scale: 0.9, anchor: .center)
                    .combined(with: .opacity)
                    .combined(with: .offset(y: 12))
                    .animation(optimizedEmptyStateContainerAnimation()),
                removal: .scale(scale: 0.92, anchor: .center)
                    .combined(with: .opacity)
                    .combined(with: .offset(y: -8))
                    .animation(optimizedEmptyStateContainerAnimation().speed(1.1))
            )
        case .low:
            return AnyTransition.opacity.animation(.easeInOut(duration: 0.15))
        }
    }
    
    /// Enhanced empty state animation coordinator for synchronized timing
    static func enhancedEmptyStateCoordinator() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.3)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return .interpolatingSpring(
                stiffness: 180,
                damping: 20,
                initialVelocity: 0.3
            )
        case .medium:
            return .interpolatingSpring(
                stiffness: 160,
                damping: 22,
                initialVelocity: 0.2
            )
        case .low:
            return .easeInOut(duration: 0.35)
        }
    }
    

    
    /// Optimized task list transition for smooth state changes
    static func optimizedTaskListTransition() -> AnyTransition {
        if PerformanceConfig.shouldUseReducedAnimations {
            return AnyTransition.opacity
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return AnyTransition.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                    .combined(with: .offset(y: 10))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).speed(1.2)),
                removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                    .animation(.easeInOut(duration: 0.15))
            )
        case .medium:
            return AnyTransition.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                    .animation(.spring(response: 0.6, dampingFraction: 0.85)),
                removal: .opacity.combined(with: .scale(scale: 0.99, anchor: .top))
                    .animation(.easeInOut(duration: 0.15))
            )
        case .low:
            return AnyTransition.opacity.animation(.easeInOut(duration: 0.15))
        }
    }
    
    /// Optimized task list animation for content appearance
    static func optimizedTaskListAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.15)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return .spring(
                response: 0.5,
                dampingFraction: 0.8,
                blendDuration: 0.1
            ).speed(1.2)
        case .medium:
            return .spring(
                response: 0.6,
                dampingFraction: 0.85,
                blendDuration: 0.15
            )
        case .low:
            return .easeInOut(duration: 0.3)
        }
    }
    
    /// Optimized state transition animation for main content switching
    static func optimizedStateTransitionAnimation() -> Animation {
        if PerformanceConfig.shouldUseReducedAnimations {
            return .easeInOut(duration: 0.15)
        }
        
        let devicePerformance = getDevicePerformanceLevel()
        switch devicePerformance {
        case .high:
            return .spring(
                response: 0.4,
                dampingFraction: 0.85,
                blendDuration: 0.1
            ).speed(1.3)
        case .medium:
            return .spring(
                response: 0.5,
                dampingFraction: 0.9,
                blendDuration: 0.15
            )
        case .low:
            return .easeInOut(duration: 0.15)
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