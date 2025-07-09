//
//  TaskRowView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct TaskRowView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var taskManager: TaskManager
    let task: Task
    let namespace: Namespace.ID
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isPressed = false
    @State private var showCompletionParticles = false
    @State private var completionScale: CGFloat = 1.0
    @State private var checkmarkScale: CGFloat = 0.1
    @State private var showCheckmark = false
    @State private var showingQuickListDetail = false
    
    // Optimized gesture states - reduced state variables
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var dragProgress: CGFloat = 0
    @State private var showCompletionIcon = false
    @State private var showDeleteIcon = false
    @State private var hasTriggeredHaptic = false
    @State private var initialSwipeDirection: SwipeDirection? = nil
    @State private var hasShownIcon = false // Track if any icon has been shown
    
    // Enum to track initial swipe direction
    private enum SwipeDirection {
        case left, right
    }
    
    // Simplified confirmation states
    @State private var showCompletionConfirmation = false
    @State private var showDeleteConfirmation = false
    
    // Additional state variables
    @State private var gestureCompleted = false
    @State private var completionOpacity: CGFloat = 0.8
    @State private var confirmationProgress: CGFloat = 0
    
    // Constants for gesture thresholds
    private let completionThreshold: CGFloat = 120
    private let deletionThreshold: CGFloat = -120
    private let maxDragDistance: CGFloat = 150
    
    var body: some View {
        ZStack {
            // Background action indicators
            HStack {
                // Completion background (left side)
                if dragOffset > 0 {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(showCompletionConfirmation ? theme.success : theme.success.opacity(0.3))
                                .frame(width: showCompletionConfirmation ? 50 : 40, height: showCompletionConfirmation ? 50 : 40)
                                .scaleEffect(showCompletionIcon ? 1.1 : 0.9)
                .animation(.interpolatingSpring(stiffness: 300, damping: 35), value: showCompletionIcon)
                .animation(.interpolatingSpring(stiffness: 250, damping: 30), value: showCompletionConfirmation)
                            
                            if showCompletionConfirmation {
                                // Confirmation button
                                Button(action: {
                                    confirmCompletionAction()
                                }) {
                                    Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(getIconColor(for: theme.success))
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Preview icon
                                Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(getIconColor(for: theme.success))
                                    .scaleEffect(showCompletionIcon ? 1.0 : 0.5)
                                .animation(Animation.adaptiveSnappy, value: showCompletionIcon)
                            }
                        }
                        .opacity(showCompletionConfirmation ? 1.0 : dragProgress)
                        .animation(.easeOut(duration: 0.2), value: dragProgress)
                        
                        Spacer()
                    }
                    .padding(.leading, 20)
                }
                
                Spacer()
                
                // Deletion background (right side)
                if dragOffset < 0 {
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(showDeleteConfirmation ? theme.error : theme.error.opacity(0.3))
                                .frame(width: showDeleteConfirmation ? 50 : 40, height: showDeleteConfirmation ? 50 : 40)
                                .scaleEffect(showDeleteIcon ? 1.1 : 0.9)
                .animation(.interpolatingSpring(stiffness: 300, damping: 35), value: showDeleteIcon)
                .animation(.interpolatingSpring(stiffness: 250, damping: 30), value: showDeleteConfirmation)
                            
                            if showDeleteConfirmation {
                                // Confirmation button
                                Button(action: {
                                    confirmDeleteAction()
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(getIconColor(for: theme.error))
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Preview icon
                                Image(systemName: "trash")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(getIconColor(for: theme.error))
                                    .scaleEffect(showDeleteIcon ? 1.0 : 0.5)
                                    .animation(Animation.adaptiveSnappy, value: showDeleteIcon)
                            }
                        }
                        .opacity(showDeleteConfirmation ? 1.0 : abs(dragProgress))
                        .animation(.easeOut(duration: 0.2), value: dragProgress)
                    }
                    .padding(.trailing, 20)
                }
            }
            
            // Main task content
            HStack(spacing: 16) {
                // Completion toggle with enhanced animations
                Button(action: {
                    performCompletionToggle()
                }) {
                    ZStack {
                        // Base circle
                        Circle()
                            .fill(task.isCompleted ? theme.success : theme.surface)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(task.isCompleted ? theme.success : theme.textTertiary, lineWidth: 2)
                            )
                            .applyNeumorphicShadow(task.isCompleted ? theme.neumorphicPressedStyle : theme.neumorphicButtonStyle)
                            .scaleEffect(completionScale)
                            .animation(Animation.adaptiveElastic, value: completionScale)
                        
                        // Checkmark with smooth animation
                        if task.isCompleted || showCheckmark {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(getIconColor(for: theme.success))
                                .scaleEffect(task.isCompleted ? 1.0 : checkmarkScale)
                                .opacity(task.isCompleted ? 1.0 : 0.8)
                                .animation(.interpolatingSpring(stiffness: 600, damping: 20), value: task.isCompleted)
                                .matchedGeometryEffect(id: "\(task.id)-checkmark", in: namespace)
                        }
                        
                        // Particle effect for completion
                        if showCompletionParticles {
                            ForEach(0..<8, id: \.self) { index in
                                Circle()
                                    .fill(theme.success)
                                    .frame(width: 4, height: 4)
                                    .offset(
                                        x: cos(Double(index) * .pi / 4) * 30,
                                        y: sin(Double(index) * .pi / 4) * 30
                                    )
                                    .scaleEffect(showCompletionParticles ? 0 : 1)
                                    .opacity(showCompletionParticles ? 0 : 1)
                                    .animation(
                                        Animation.adaptiveSmooth.delay(Double(index) * 0.05),
                                        value: showCompletionParticles
                                    )
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.interpolatingSpring(stiffness: 600, damping: 30), value: isPressed)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Task title 
                    HStack(spacing: 8) {
                        Text(task.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? theme.textSecondary : theme.text)
                            .opacity(task.isCompleted ? 0.7 : 1.0)
                            .scaleEffect(task.isCompleted ? 0.99 : 1.0, anchor: .leading)
                            .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                            .matchedGeometryEffect(id: "\(task.id)-title", in: namespace)
                        
                        Spacer()
                    }
                    
                    // Category indicator - now on its own row for better spacing
                    if let category = categoryManager.category(for: task) {
                        HStack {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(category.color.gradient)
                                    .frame(width: 8, height: 8)
                                    .overlay(
                                        Circle()
                                            .stroke(category.color.darkColor, lineWidth: 0.5)
                                            .opacity(0.3)
                                    )
                                
                                Text(category.name)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(category.color.darkColor)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(category.color.lightColor)
                                    .overlay(
                                        Capsule()
                                            .stroke(category.color.color.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                            .scaleEffect(task.isCompleted ? 0.98 : 1.0)
                            .opacity(task.isCompleted ? 0.6 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                            
                            Spacer()
                        }
                    }
                    
                    // Task description with fade animation
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                            .opacity(task.isCompleted ? 0.5 : 0.8)
                            .scaleEffect(task.isCompleted ? 0.99 : 1.0, anchor: .leading)
                            .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                            .matchedGeometryEffect(id: "\(task.id)-description", in: namespace)
                    }
                    
                    // Quick List indicator
                    if task.hasQuickList {
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.primary)
                                
                                Text("\(task.completedQuickListItemsCount)/\(task.totalQuickListItemsCount)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.textSecondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(theme.surface)
                                    .overlay(
                                        Capsule()
                                            .stroke(theme.primary.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track with border
                                    Capsule()
                                        .fill(theme.surface)
                                        .overlay(
                                            Capsule()
                                                .stroke(theme.textTertiary.opacity(0.3), lineWidth: 0.5)
                                        )
                                        .frame(height: 5)
                                    
                                    // Progress fill with clear end indicator
                                    if task.quickListCompletionPercentage > 0 {
                                        Capsule()
                                            .fill(task.allQuickListItemsCompleted ? Color.green.gradient : theme.primary.gradient)
                                            .frame(width: max(5, geometry.size.width * task.quickListCompletionPercentage), height: 5)
                                            .overlay(
                                                // End cap indicator
                                                Capsule()
                                                    .stroke(task.allQuickListItemsCompleted ? Color.green : theme.primary, lineWidth: 1)
                                                    .frame(width: max(5, geometry.size.width * task.quickListCompletionPercentage), height: 5)
                                            )
                                            .animation(.easeInOut(duration: 0.3), value: task.quickListCompletionPercentage)
                                    }
                                }
                            }
                            .frame(height: 5)
                            .frame(maxWidth: 60)
                            
                            Spacer()
                        }
                        .opacity(task.isCompleted ? 0.6 : 1.0)
                        .scaleEffect(task.isCompleted ? 0.99 : 1.0, anchor: .leading)
                        .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                    }
                    
                    // Due date and reminder info with improved spacing - vertical layout when both present
                    if task.dueDate != nil || (task.hasReminder && !task.isCompleted) {
                        let hasBothDateAndReminder = task.dueDate != nil && task.hasReminder && !task.isCompleted
                        
                        if hasBothDateAndReminder {
                            // Vertical layout when both are present for better spacing
                            VStack(alignment: .leading, spacing: 6) {
                                if let dueDate = task.dueDate {
                                    dueDatePill(dueDate)
                                }
                                
                                if task.hasReminder && !task.isCompleted {
                                    reminderPill()
                                }
                            }
                        } else {
                            // Horizontal layout when only one is present
                            HStack(spacing: 8) {
                                if let dueDate = task.dueDate {
                                    dueDatePill(dueDate)
                                }
                                
                                if task.hasReminder && !task.isCompleted {
                                    reminderPill()
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons with enhanced interactions (hidden during drag)
                if !isDragging && !showCompletionConfirmation && !showDeleteConfirmation {
                    HStack(spacing: 12) {
                        Button(action: {
                            HapticManager.shared.buttonTap()
                            onEdit()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(theme.surfaceGradient)
                                    .frame(width: 36, height: 36)
                                    .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                                
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(theme.primary)
                                    .shadow(
                                        color: theme.background == .black ? Color.white.opacity(0.1) : Color.clear,
                                        radius: 1,
                                        x: 0,
                                        y: 0.5
                                    )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(task.isCompleted ? 0.9 : 1.0)
                        .opacity(task.isCompleted ? 0.6 : 1.0)
                        .animation(.easeInOut(duration: 0.3).delay(0.1), value: task.isCompleted)
                    }
                    .opacity(isDragging ? 0 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isDragging)
                }
            }
            .padding(20)
            .neumorphicCard(theme, cornerRadius: 16)
            .scaleEffect(isPressed ? 0.99 : 1.0)
            .opacity(completionOpacity)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .offset(x: dragOffset)
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
        .onTapGesture {
            // Dismiss confirmations if tapped elsewhere
            if showCompletionConfirmation || showDeleteConfirmation {
                dismissConfirmations()
            } else if task.hasQuickList {
                // Open quick list detail view for tasks with quick lists
                HapticManager.shared.buttonTap()
                showingQuickListDetail = true
            } else {
                // Subtle tap feedback for tasks without quick lists
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                    isPressed = false
                }
            }
        }
        .contextMenu {
            contextMenuContent
        }
        .onAppear {
            // Initial animation when task appears
            withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                completionOpacity = 1.0
            }
        }
        .sheet(isPresented: $showingQuickListDetail) {
            QuickListDetailView(taskId: task.id)
                .environmentObject(taskManager)
                .environmentObject(categoryManager)
                .environment(\.theme, theme)
        }
    }
    
    // MARK: - Context Menu
    
    private var contextMenuContent: some View {
        VStack {
            // Toggle completion action
            Button(action: {
                HapticManager.shared.contextMenuAction()
                withAnimation(.easeInOut(duration: 0.2)) {
                    onToggleCompletion()
                }
            }) {
                Label(
                    task.isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                    systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                )
            }
            
            // Edit action
            Button(action: {
                HapticManager.shared.contextMenuAction()
                onEdit()
            }) {
                Label("Edit Task", systemImage: "pencil")
            }
            
            // Duplicate action
            Button(action: {
                HapticManager.shared.contextMenuAction()
                duplicateTask()
            }) {
                Label("Duplicate Task", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            // Delete action
            Button(role: .destructive, action: {
                HapticManager.shared.contextMenuAction()
                onDelete()
            }) {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns the appropriate icon color based on the theme background
    private func getIconColor(for baseColor: Color) -> Color {
        // In dark theme, use contrasting color for better visibility
        if theme.background == .black {
            return Color.black // Black icons on colored backgrounds in dark mode
        } else {
            return Color.white // White icons on colored backgrounds in light mode
        }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        guard !gestureCompleted else { return }
        
        let translation = value.translation.width
        
        // If confirmations are showing, handle dismissal gesture
        if showCompletionConfirmation || showDeleteConfirmation {
            // Allow dismissal by swiping in opposite direction or back to center
            let dismissThreshold: CGFloat = 30
            
            if showCompletionConfirmation && translation < -dismissThreshold {
                // Swiping left while completion confirmation is showing - dismiss
                HapticManager.shared.gestureCancelled()
                resetGestureState()
                return
            } else if showDeleteConfirmation && translation > dismissThreshold {
                // Swiping right while delete confirmation is showing - dismiss
                HapticManager.shared.gestureCancelled()
                resetGestureState()
                return
            }
            
            // If swiping in same direction as confirmation, don't do anything
            return
        }
        
        // Determine initial swipe direction on first significant movement
        if initialSwipeDirection == nil && abs(translation) > 15 {
            initialSwipeDirection = translation > 0 ? .right : .left
        }
        
        // Trigger gesture start haptic on first movement
        if !isDragging && abs(translation) > 8 {
            HapticManager.shared.gestureStart()
            HapticManager.shared.prepareForGestures()
        }
        
        // ULTIMATE FIX: Once ANY icon is shown, ONLY allow return to neutral
        if hasShownIcon {
            // Calculate how close we are to neutral (0)
            let distanceFromNeutral = abs(translation)
            
            // If we're moving away from neutral after showing an icon, BLOCK IT
            if distanceFromNeutral > abs(dragOffset) {
                // User is trying to swipe further after showing an icon - BLOCK
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 40)) {
                    dragOffset = dragOffset // Keep current position, don't allow further movement
                    isDragging = true
                }
                
                // Reset all visual indicators
                dragProgress = 0
                showCompletionIcon = false
                showDeleteIcon = false
                
                // STOP ALL FURTHER PROCESSING
                return
            } else {
                // User is returning toward neutral - allow this movement only
                let constrainedTranslation = translation
                if let initialDirection = initialSwipeDirection {
                    // Only allow movement back toward neutral
                    if initialDirection == .right {
                        // Original swipe was right, only allow movement back to 0 or less
                        if translation > dragOffset {
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 40)) {
                                dragOffset = dragOffset // Don't allow further right movement
                            }
                            return
                        }
                    } else {
                        // Original swipe was left, only allow movement back to 0 or more
                        if translation < dragOffset {
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 40)) {
                                dragOffset = dragOffset // Don't allow further left movement
                            }
                            return
                        }
                    }
                }
                
                // Allow movement toward neutral
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 40)) {
                    dragOffset = constrainedTranslation
                    isDragging = abs(constrainedTranslation) > 10
                }
                
                // Reset visual indicators when returning to neutral
                dragProgress = 0
                showCompletionIcon = false
                showDeleteIcon = false
                
                // STOP ALL FURTHER PROCESSING
                return
            }
        }
        
        // Normal gesture processing (only reached if not in opposite direction mode)
        let limitedTranslation = max(-maxDragDistance, min(maxDragDistance, translation))
        
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 40)) {
            dragOffset = limitedTranslation
            isDragging = abs(limitedTranslation) > 10
        }
        
        // Calculate progress for visual feedback
        if limitedTranslation > 0 {
            dragProgress = min(1.0, limitedTranslation / completionThreshold)
            let shouldShowIcon = limitedTranslation > 40
            showCompletionIcon = shouldShowIcon
            showDeleteIcon = false
            if shouldShowIcon {
                hasShownIcon = true
            }
        } else {
            dragProgress = min(1.0, abs(limitedTranslation) / abs(deletionThreshold))
            let shouldShowIcon = abs(limitedTranslation) > 40
            showDeleteIcon = shouldShowIcon
            showCompletionIcon = false
            if shouldShowIcon {
                hasShownIcon = true
            }
        }
        
        // Trigger haptic feedback at threshold
        if !hasTriggeredHaptic {
            if limitedTranslation > completionThreshold {
                HapticManager.shared.gestureThreshold()
                hasTriggeredHaptic = true
            } else if limitedTranslation < deletionThreshold {
                HapticManager.shared.gestureThreshold()
                hasTriggeredHaptic = true
            }
        }
        
        // Reset haptic flag if user pulls back
        if abs(limitedTranslation) < abs(completionThreshold * 0.8) && abs(limitedTranslation) < abs(deletionThreshold * 0.8) {
            hasTriggeredHaptic = false
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let translation = value.translation.width
        let velocity = value.velocity.width
        
        // If confirmations are already showing, handle dismissal
        if showCompletionConfirmation || showDeleteConfirmation {
            let dismissThreshold: CGFloat = 30
            
            if showCompletionConfirmation && translation < -dismissThreshold {
                // Dismiss completion confirmation by swiping left
                HapticManager.shared.gestureCancelled()
                resetGestureState()
            } else if showDeleteConfirmation && translation > dismissThreshold {
                // Dismiss delete confirmation by swiping right
                HapticManager.shared.gestureCancelled()
                resetGestureState()
            } else {
                // Not enough movement to dismiss, snap back to confirmation position
                withAnimation(.interpolatingSpring(stiffness: 250, damping: 35)) {
                    if showCompletionConfirmation {
                        dragOffset = 80
                    } else if showDeleteConfirmation {
                        dragOffset = -80
                    }
                }
            }
            return
        }
        
        // If user was swiping in opposite direction after showing an icon, always reset
        if let initialDirection = initialSwipeDirection, hasShownIcon {
            let isSwipingOpposite = (initialDirection == .right && translation < 0) || 
                                   (initialDirection == .left && translation > 0)
            
            if isSwipingOpposite {
                // User swiped in opposite direction after showing an icon, always reset
                HapticManager.shared.gestureCancelled()
                resetGestureState()
                return
            }
        }
        
        // Check if gesture should trigger confirmation (only in the original direction)
        let shouldShowCompletionConfirmation = translation > completionThreshold || (translation > 70 && velocity > 800)
        let shouldShowDeleteConfirmation = translation < deletionThreshold || (translation < -70 && velocity < -800)
        
        if shouldShowCompletionConfirmation {
            // Show completion confirmation
            HapticManager.shared.gestureThreshold()
            withAnimation(.interpolatingSpring(stiffness: 250, damping: 35)) {
                showCompletionConfirmation = true
                dragOffset = 80 // Keep some offset to show the confirmation button
            }
        } else if shouldShowDeleteConfirmation {
            // Show deletion confirmation
            HapticManager.shared.gestureThreshold()
            withAnimation(.interpolatingSpring(stiffness: 250, damping: 35)) {
                showDeleteConfirmation = true
                dragOffset = -80 // Keep some offset to show the confirmation button
            }
        } else {
            // Snap back to original position with cancel haptic
            HapticManager.shared.gestureCancelled()
            resetGestureState()
        }
    }
    
    private func confirmCompletionAction() {
        // Execute the completion action
        gestureCompleted = true
        HapticManager.shared.swipeToComplete()
        
        withAnimation(.interpolatingSpring(stiffness: 250, damping: 35)) {
            dragOffset = UIScreen.main.bounds.width
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            performCompletionToggle()
            resetGestureState()
        }
    }
    
    private func confirmDeleteAction() {
        // Execute the deletion action
        gestureCompleted = true
        HapticManager.shared.swipeToDelete()
        
        withAnimation(.interpolatingSpring(stiffness: 250, damping: 35)) {
            dragOffset = -UIScreen.main.bounds.width
            completionOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDelete()
        }
    }
    
    private func dismissConfirmations() {
        HapticManager.shared.gestureCancelled()
        resetGestureState()
    }
    
    private func performCompletionToggle() {
        // Prepare haptic feedback for better responsiveness
        HapticManager.shared.prepareForInteraction()
        
        withAnimation(.interpolatingSpring(stiffness: 400, damping: 25)) {
            if !task.isCompleted {
                // Animate completion
                completionScale = 1.3
                showCompletionParticles = true
                showCheckmark = true
                checkmarkScale = 1.0
                HapticManager.shared.taskCompleted()
            } else {
                // Animate un-completion
                showCheckmark = false
                checkmarkScale = 0.1
                HapticManager.shared.taskUncompleted()
            }
        }
        
        // Trigger the actual completion toggle after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onToggleCompletion()
        }
        
        // Reset animation states
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                completionScale = 1.0
                showCompletionParticles = false
            }
        }
    }
    
    private func resetGestureState() {
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 45)) {
            dragOffset = 0
            isDragging = false
            dragProgress = 0
            showCompletionIcon = false
            showDeleteIcon = false
            showCompletionConfirmation = false
            showDeleteConfirmation = false
        }
        
        hasTriggeredHaptic = false
        gestureCompleted = false
        confirmationProgress = 0
        initialSwipeDirection = nil
        hasShownIcon = false
    }
    
    private func duplicateTask() {
        taskManager.duplicateTask(task)
    }
    
    private func dueDatePill(_ date: Date) -> some View {
        HStack(spacing: 3) {
            Image(systemName: task.isOverdue ? "exclamationmark.triangle.fill" : 
                  task.isPending ? "clock" : "calendar")
                .font(.caption2)
                .shadow(
                    color: theme.background == .black ? Color.white.opacity(0.05) : Color.clear,
                    radius: 0.5,
                    x: 0,
                    y: 0.3
                )
            
            Text(formatDueDate(date))
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(
            task.isOverdue ? theme.error : 
            task.isPending ? theme.warning : 
            theme.textSecondary
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(
                    task.isOverdue ? theme.error.opacity(0.15) :
                    task.isPending ? theme.warning.opacity(0.1) :
                    theme.surfaceSecondary
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    task.isOverdue ? theme.error.opacity(0.3) :
                    task.isPending ? theme.warning.opacity(0.2) :
                    Color.clear,
                    lineWidth: 1
                )
        )
        .scaleEffect(task.isCompleted ? 0.95 : 1.0)
        .opacity(task.isCompleted ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.3).delay(0.15), value: task.isCompleted)
    }
    
    private func reminderPill() -> some View {
        HStack(spacing: 3) {
            Image(systemName: "bell.fill")
                .font(.caption2)
                .shadow(
                    color: theme.background == .black ? Color.white.opacity(0.05) : Color.clear,
                    radius: 0.5,
                    x: 0,
                    y: 0.3
                )
            
            if let reminderDate = task.reminderDate {
                Text(formatReminderTime(reminderDate))
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(theme.warning)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(theme.warning.opacity(0.1))
        )
        .scaleEffect(task.isCompleted ? 0.95 : 1.0)
        .opacity(task.isCompleted ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.3).delay(0.2), value: task.isCompleted)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            formatter.timeStyle = .short
            return "Tomorrow \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.timeStyle = .short
            return "Yesterday \(formatter.string(from: date))"
        } else {
            // For other dates, show compact date and time
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    private func formatReminderTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            formatter.timeStyle = .short
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            // For other dates, show compact format
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
    

}

#Preview {
    VStack(spacing: 16) {
        TaskRowView(
            task: Task(title: "Sample Task", description: "This is a sample task description", dueDate: Date(), hasReminder: true),
            namespace: Namespace().wrappedValue,
            onToggleCompletion: {},
            onEdit: {},
            onDelete: {}
        )
        
        TaskRowView(
            task: {
                var task = Task(title: "Completed Task", description: "This task is completed")
                task.isCompleted = true
                return task
            }(),
            namespace: Namespace().wrappedValue,
            onToggleCompletion: {},
            onEdit: {},
            onDelete: {}
        )
        
        TaskRowView(
            task: {
                var task = Task(title: "Overdue Task", description: "This task is overdue", dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
                return task
            }(),
            namespace: Namespace().wrappedValue,
            onToggleCompletion: {},
            onEdit: {},
            onDelete: {}
        )
    }
    .padding()
    .background(LightTheme().backgroundGradient)
    .environment(\.theme, LightTheme())
    .environmentObject(TaskManager())
    .environmentObject(CategoryManager())
}