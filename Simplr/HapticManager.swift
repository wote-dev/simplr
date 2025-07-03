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
    
    private init() {}
    
    // MARK: - Haptic Feedback Methods
    
    /// Light haptic feedback for task completion
    func taskCompleted() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Subtle haptic feedback for task uncomplete
    func taskUncompleted() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred()
    }
    
    /// Success haptic feedback for adding a new task
    func taskAdded() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    /// Warning haptic feedback for task deletion
    func taskDeleted() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    /// Light haptic feedback for button taps and UI interactions
    func buttonTap() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Subtle haptic feedback for selection changes
    func selectionChange() {
        let selection = UISelectionFeedbackGenerator()
        selection.selectionChanged()
    }
    
    /// Subtle haptic feedback for tab selection changes
    func selectionChanged() {
        let selection = UISelectionFeedbackGenerator()
        selection.selectionChanged()
    }
    
    /// Success haptic feedback for general operations
    func successFeedback() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    /// Success haptic for reminder notifications
    func reminderReceived() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    /// Warning haptic for overdue tasks
    func taskOverdue() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.4)
    }
    
    /// Error haptic for validation failures
    func validationError() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.5)
    }
    
    /// Subtle haptic for drag and reorder operations
    func dragStart() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Confirmation haptic for successful reordering
    func dragEnd() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred()
    }
    
    // MARK: - Gesture-Specific Haptics
    
    /// Subtle haptic feedback when swipe gesture begins
    func gestureStart() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred()
    }
    
    /// Progressive haptic feedback during gesture movement
    func gestureProgress() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.5)
    }
    
    /// Strong haptic feedback when gesture reaches threshold
    func gestureThreshold() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    /// Completion haptic for successful swipe gesture
    func gestureCompleted() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    /// Cancel haptic when gesture is released before threshold
    func gestureCancelled() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.3)
    }
    
    /// Strong haptic for swipe to complete gesture
    func swipeToComplete() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Add a slight delay for a satisfying double-tap effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let secondImpact = UIImpactFeedbackGenerator(style: .light)
            secondImpact.impactOccurred()
        }
    }
    
    /// Strong haptic for swipe to delete gesture
    func swipeToDelete() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    // MARK: - Context Menu and Preview Haptics
    
    /// Haptic feedback when context menu preview appears
    func previewAppears() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred()
    }
    
    /// Subtle haptic when context menu preview is dismissed
    func previewDismissed() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.5)
    }
    
    /// Haptic feedback for context menu action selection
    func contextMenuAction() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    // MARK: - Prepare Methods (for better performance)
    
    /// Prepare haptic generators for better responsiveness
    func prepareForInteraction() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        
        let selection = UISelectionFeedbackGenerator()
        selection.prepare()
    }
    
    /// Prepare haptic generators specifically for gesture interactions
    func prepareForGestures() {
        let softImpact = UIImpactFeedbackGenerator(style: .soft)
        softImpact.prepare()
        
        let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
        mediumImpact.prepare()
        
        let lightImpact = UIImpactFeedbackGenerator(style: .light)
        lightImpact.prepare()
        
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
    }
} 