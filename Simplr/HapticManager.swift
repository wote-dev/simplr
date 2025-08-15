//
//  HapticManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import UIKit

/// Manager for providing refined haptic feedback throughout the app
class HapticManager {
    static let shared = HapticManager()
    
    private init() {
        setupPreparationTimer()
    }
    
    // MARK: - Pre-allocated Haptic Generators
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    // MARK: - Performance Optimization
    private var lastHapticTime: Date = .distantPast
    private let hapticDebounceInterval: TimeInterval = 0.05 // 50ms debounce
    private var preparationTimer: Timer?
    private let preparationInterval: TimeInterval = 2.0
    
    // MARK: - Haptic Feedback Methods
    
    /// Light haptic feedback for task completion
    func taskCompleted() {
        guard shouldTriggerHaptic() else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Subtle haptic feedback for task uncomplete
    func taskUncompleted() {
        guard shouldTriggerHaptic() else { return }
        softImpactGenerator.impactOccurred()
    }
    
    /// Success haptic feedback for adding a new task
    func taskAdded() {
        guard shouldTriggerHaptic() else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Warning haptic feedback for task deletion
    func taskDeleted() {
        guard shouldTriggerHaptic() else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Light haptic feedback for button taps and UI interactions
    func buttonTap() {
        guard shouldTriggerHaptic() else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Gentle haptic feedback for theme changes - optimized for rapid theme switching
    func themeChange() {
        // Use shorter debounce for theme changes to feel more responsive
        let now = Date()
        if now.timeIntervalSince(lastHapticTime) >= 0.02 { // 20ms for theme changes
            lastHapticTime = now
            softImpactGenerator.impactOccurred(intensity: 0.9)
        }
    }
    
    /// Subtle haptic feedback for selection changes
    func selectionChange() {
        guard shouldTriggerHaptic() else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// Subtle haptic feedback for tab selection changes
    func selectionChanged() {
        guard shouldTriggerHaptic() else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// Success haptic feedback for general operations
    func successFeedback() {
        guard shouldTriggerHaptic() else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Success haptic for reminder notifications
    func reminderReceived() {
        guard shouldTriggerHaptic() else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Warning haptic for overdue tasks
    func taskOverdue() {
        guard shouldTriggerHaptic() else { return }
        softImpactGenerator.impactOccurred(intensity: 0.4)
    }
    
    /// Error haptic for validation failures
    func validationError() {
        guard shouldTriggerHaptic() else { return }
        softImpactGenerator.impactOccurred(intensity: 0.5)
    }
    

    
    // MARK: - Gesture-Specific Haptics
    
    /// Subtle haptic feedback when swipe gesture begins
    func gestureStart() {
        guard shouldTriggerHaptic() else { return }
        softImpactGenerator.impactOccurred()
    }
    
    /// Progressive haptic feedback during gesture movement
    func gestureProgress() {
        guard shouldTriggerHaptic() else { return }
        softImpactGenerator.impactOccurred(intensity: 0.5)
    }
    
    /// Strong haptic feedback when gesture reaches threshold
    func gestureThreshold() {
        guard shouldTriggerHaptic() else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Completion haptic for successful swipe gesture
    func gestureCompleted() {
        guard shouldTriggerHaptic() else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Cancel haptic when gesture is released before threshold
    func gestureCancelled() {
        guard shouldTriggerHaptic() else { return }
        softImpactGenerator.impactOccurred(intensity: 0.3)
    }
    
    /// Strong haptic for swipe to complete gesture
    func swipeToComplete() {
        guard shouldTriggerHaptic() else { return }
        mediumImpactGenerator.impactOccurred()
        
        // Add a slight delay for a satisfying double-tap effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    /// Strong haptic for swipe to delete gesture
    func swipeToDelete() {
        guard shouldTriggerHaptic() else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    // MARK: - Context Menu and Preview Haptics
    
    /// Haptic feedback when context menu preview appears
    func previewAppears() {
        guard shouldTriggerHaptic() else { return }
        softImpactGenerator.impactOccurred()
    }
    
    /// Subtle haptic when context menu preview is dismissed
    func previewDismissed() {
        guard shouldTriggerHaptic() else { return }
        softImpactGenerator.impactOccurred(intensity: 0.5)
    }
    
    /// Haptic feedback for context menu action selection
    func contextMenuAction() {
        guard shouldTriggerHaptic() else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Prepare Methods (for better performance)
    
    /// Prepare haptic generators for better responsiveness
    func prepareForInteraction() {
        lightImpactGenerator.prepare()
        softImpactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    /// Prepare haptic generators specifically for gesture interactions
    func prepareForGestures() {
        softImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        lightImpactGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    /// Continuous preparation for optimal responsiveness
    func continuousPreparation() {
        lightImpactGenerator.prepare()
        softImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Performance Optimization Methods
    
    /// Debounce haptic triggers to prevent performance issues during rapid interactions
    private func shouldTriggerHaptic() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastHapticTime) >= hapticDebounceInterval {
            lastHapticTime = now
            return true
        }
        return false
    }
    
    /// Setup timer for continuous preparation to maintain responsiveness
    private func setupPreparationTimer() {
        preparationTimer?.invalidate()
        preparationTimer = Timer.scheduledTimer(
            withTimeInterval: preparationInterval,
            repeats: true
        ) { [weak self] _ in
            self?.continuousPreparation()
        }
        preparationTimer?.tolerance = 0.5
    }
    
    /// Cleanup resources when no longer needed
    deinit {
        preparationTimer?.invalidate()
        preparationTimer = nil
    }
}