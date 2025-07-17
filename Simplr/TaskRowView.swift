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
    @EnvironmentObject var themeManager: ThemeManager
    let task: Task
    let namespace: Namespace.ID
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDeleteCanceled: (() -> Void)? // New callback for when deletion is canceled
    let isInCompletedView: Bool // New parameter to determine if we're in the completed view
    @State private var isPressed = false
    @State private var showCompletionParticles = false
    @State private var completionScale: CGFloat = 1.0
    @State private var checkmarkScale: CGFloat = 0.1
    @State private var showCheckmark = false

    
    // Optimized gesture states for 120fps performance
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var dragProgress: CGFloat = 0
    @State private var showEditIcon = false
    @State private var showDeleteIcon = false
    @State private var hasTriggeredHaptic = false
    @State private var gestureCompleted = false
    @State private var completionOpacity: CGFloat = 0.8
    @State private var showBothActionsConfirmation = false
    
    // Performance optimization: Combine related states
    @State private var gestureState = GestureState()
    
    // Memoized computed properties for better performance
    private var taskCategory: TaskCategory? {
        categoryManager.category(for: task)
    }
    
    private var isUrgentTaskMemoized: Bool {
        taskCategory?.name == "URGENT"
    }
    
    // Enum to track initial swipe direction
    private enum SwipeDirection {
        case left, right
    }
    
    // Optimized gesture state container
    private struct GestureState {
        var initialDirection: SwipeDirection? = nil
        var hasShownIcon = false
        var lastTranslation: CGFloat = 0
        var velocity: CGFloat = 0
        var isActive = false
    }
    
    // URGENT category pulsating animation states
    @State private var urgentPulseScale: CGFloat = 0.998  // Start at minimum scale for breathing motion
    @State private var urgentPulseOpacity: CGFloat = 0.95  // Start at minimum opacity for breathing motion
    @State private var urgentBorderOpacity: CGFloat = 0.0
    @State private var urgentBorderScale: CGFloat = 1.0
    
    // Constants for gesture thresholds
    private let actionThreshold: CGFloat = -120 // Only left swipe triggers actions
    private let maxDragDistance: CGFloat = 150
    
    // Computed property to check if task has URGENT category (optimized)
    private var isUrgentTask: Bool {
        return isUrgentTaskMemoized
    }
    
    // Category-based glow effect properties removed
    
    var body: some View {
        ZStack {
            // Background action indicators - positioned absolutely behind the task card
            // Left swipe shows: Delete (left) and Edit (right)
            if dragOffset < 0 {
                HStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Delete action (on the left)
                        ZStack {
                            Circle()
                                .fill(showBothActionsConfirmation ? theme.error : theme.error.opacity(0.3))
                                .frame(width: showBothActionsConfirmation ? 50 : 40, height: showBothActionsConfirmation ? 50 : 40)
                                .scaleEffect(showDeleteIcon ? 1.1 : 0.9)
                                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: showDeleteIcon)
                                .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: showBothActionsConfirmation)
                            
                            if showBothActionsConfirmation {
                                // Confirmation button - reset gesture state first, then show dialog
                                Button(action: {
                                    // Reset the gesture state first to restore card position
                                    dismissConfirmations()
                                    // Then show the confirmation dialog after a brief delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        onDelete()
                                    }
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
                        .opacity(showBothActionsConfirmation ? 1.0 : abs(dragProgress))
                        .animation(.easeOut(duration: 0.2), value: dragProgress)
                        
                        // Second action (Edit or Mark as Incomplete based on context)
                        ZStack {
                            Circle()
                                .fill(showBothActionsConfirmation ? 
                                    (isInCompletedView ? theme.warning : theme.primary) : 
                                    (isInCompletedView ? theme.warning.opacity(0.3) : theme.primary.opacity(0.3)))
                                .frame(width: showBothActionsConfirmation ? 50 : 40, height: showBothActionsConfirmation ? 50 : 40)
                                .scaleEffect(showEditIcon ? 1.1 : 0.9)
                                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: showEditIcon)
                                .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: showBothActionsConfirmation)
                            
                            if showBothActionsConfirmation {
                                // Confirmation button - execute appropriate action
                                Button(action: {
                                    if isInCompletedView {
                                        confirmMarkIncompleteAction()
                                    } else {
                                        confirmEditAction()
                                    }
                                }) {
                                    Image(systemName: isInCompletedView ? "arrow.uturn.backward" : "pencil")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(getIconColor(for: isInCompletedView ? theme.warning : theme.primary))
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Preview icon
                                Image(systemName: isInCompletedView ? "arrow.uturn.backward" : "pencil")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(getIconColor(for: isInCompletedView ? theme.warning : theme.primary))
                                    .scaleEffect(showEditIcon ? 1.0 : 0.5)
                                    .animation(Animation.adaptiveSnappy, value: showEditIcon)
                            }
                        }
                        .opacity(showBothActionsConfirmation ? 1.0 : abs(dragProgress))
                        .animation(.easeOut(duration: 0.2), value: dragProgress)
                    }
                    .padding(.trailing, 20)
                }
                .zIndex(1) // Background actions layer - behind the task card
            }
            
            // Main task content
            HStack(spacing: 12) {
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
                
                // Main content area with text on left and pills on right
                HStack(alignment: .top, spacing: 12) {
                    // Left side: Text content
                    VStack(alignment: .leading, spacing: 8) {
                        // Enhanced Task title with URGENT styling
                        HStack(alignment: .top, spacing: 8) {
                            // Urgent category icon as bullet point - positioned to the left
                            if let category = categoryManager.category(for: task), isUrgentTask && !task.isCompleted {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(theme.background == .black ? Color(red: 1.0, green: 0.4, blue: 0.4) : Color(red: 0.8, green: 0.1, blue: 0.1))
                                    .shadow(
                                        color: (theme.background == .black ? Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.5) : Color(red: 0.8, green: 0.1, blue: 0.1).opacity(0.6)),
                                        radius: theme.background == .black ? 2 : 3,
                                        x: 0,
                                        y: 1
                                    )
                                    .padding(.top, 1) // Align with first line of text
                                    .frame(width: 16) // Fixed width for consistent alignment
                            }
                            
                            Text(task.title)
                                .font(isUrgentTask && !task.isCompleted ? .headline : .headline)
                                .fontWeight(isUrgentTask && !task.isCompleted ? 
                                    (theme.background == .black ? .bold : .medium) : .semibold)
                                .lineLimit(isUrgentTask && !task.isCompleted ? 4 : 2)
                                .multilineTextAlignment(.leading)
                                .strikethrough(task.isCompleted)
                                .foregroundColor(
                                    task.isCompleted ? theme.textSecondary :
                                    (isUrgentTask && !task.isCompleted ? 
                                        (theme.background == .black ? Color(red: 1.0, green: 0.4, blue: 0.4) : Color(red: 0.8, green: 0.1, blue: 0.1)) : 
                                     (theme is KawaiiTheme ? theme.accent : theme.text))
                                )
                                .opacity(task.isCompleted ? 0.7 : 1.0)
                                .scaleEffect(task.isCompleted ? 0.99 : 1.0, anchor: .leading)
                                .shadow(
                                    color: isUrgentTask && !task.isCompleted ?
                                    (theme.background == .black ? Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.3) : Color(red: 0.8, green: 0.1, blue: 0.1).opacity(0.4)) : Color.clear,
                                    radius: theme.background == .black ? 1 : 2,
                                    x: 0,
                                    y: 0.5
                                )
                                .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                                .matchedGeometryEffect(id: "\(task.id)-title", in: namespace)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                        
                        // Detailed checklist view
                        if !task.checklist.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                // Checklist header with integrated progress pill
                                let completedCount = task.checklist.filter { $0.isCompleted }.count
                                let totalCount = task.checklist.count
                                let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0

                                HStack(spacing: 8) {
                                    Text("Checklist")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(theme.textSecondary)

                                    ProgressView(value: progress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: theme.accent))
                                        .frame(width: 50, height: 5) // A small pill for progress
                                        .clipShape(Capsule())

                                    Spacer()
                                    
                                    Text("\(completedCount)/\(totalCount)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(theme.textSecondary)
                                }
                                
                                // Individual checklist items
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(task.checklist) { item in
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                toggleChecklistItem(item)
                                            }) {
                                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(item.isCompleted ? theme.success : theme.textTertiary)
                                                    .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Text(item.title)
                                                .font(.caption)
                                                .foregroundColor(item.isCompleted ? theme.textSecondary : theme.text)
                                                .strikethrough(item.isCompleted)
                                                .opacity(item.isCompleted ? 0.7 : 1.0)
                                                .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
                                            
                                            Spacer()
                                        }
                                    }
                                }
                                .padding(.top, 2)
                            }
                            .padding(.top, 6)
                        }
                        
                        // Due date display under task text
                        if let dueDate = task.dueDate {
                            HStack(spacing: 6) {
                                Image(systemName: task.isOverdue ? "exclamationmark.triangle.fill" : 
                                      task.isPending ? "clock" : "calendar")
                                    .font(.caption2)
                                    .foregroundColor(
                                        task.isOverdue ? theme.error : 
                                        task.isPending ? theme.warning : 
                                        theme.textSecondary
                                    )
                                
                                Text(formatDueDate(dueDate))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(
                                        task.isOverdue ? theme.error : 
                                        task.isPending ? theme.warning : 
                                        theme.textSecondary
                                    )
                                
                                Spacer()
                            }
                            .opacity(task.isCompleted ? 0.6 : 1.0)
                            .scaleEffect(task.isCompleted ? 0.99 : 1.0, anchor: .leading)
                            .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                        }
                        

                    }
                    
                    // Right side: Pills (reminder only)
                    VStack(alignment: .trailing, spacing: 6) {
                        // Reminder pill
                        if task.hasReminder && !task.isCompleted {
                            reminderPill()
                        }
                    }
                }
                
                // Action buttons removed - edit functionality moved to swipe gesture
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(
                // Clean background without confining borders
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        isUrgentTask && !task.isCompleted ?
                        LinearGradient(
                            colors: theme.background == .black ? [
                                Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.15),
                                Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.08),
                                Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.12)
                            ] : [
                                Color(red: 0.8, green: 0.1, blue: 0.1).opacity(0.18),
                                Color(red: 0.8, green: 0.1, blue: 0.1).opacity(0.10),
                                Color(red: 0.8, green: 0.1, blue: 0.1).opacity(0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        // Enhanced dark mode task card gradient for sleeker look
                        (theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.04, green: 0.04, blue: 0.04),
                                Color(red: 0.02, green: 0.02, blue: 0.02),
                                Color(red: 0.03, green: 0.03, blue: 0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : theme.surfaceGradient)
                    )
                    // Category-based glow effect removed
                    .shadow(
                        color: isUrgentTask && !task.isCompleted ? 
                            (theme.background == .black ? Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.25) : Color(red: 0.8, green: 0.1, blue: 0.1).opacity(0.35)) : 
                            // Enhanced shadow for dark mode sleek cards
                            (theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? 
                                Color.black.opacity(0.8) :
                                (themeManager.themeMode == .kawaii ? theme.shadow.opacity(0.4) : theme.shadow.opacity(0.6))),
                        radius: isUrgentTask && !task.isCompleted ? (theme.background == .black ? 8 : 12) : 
                            // Larger shadow radius for dark mode sleek look
                            (theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? 15 :
                                (themeManager.themeMode == .kawaii ? 1.0 : 1.0)),
                        x: 0,
                        y: isUrgentTask && !task.isCompleted ? (theme.background == .black ? 2 : 3) : 
                            // Enhanced shadow offset for dark mode depth
                            (theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? 8 :
                                (themeManager.themeMode == .kawaii ? 0.3 : 0.3))
                    )
            )
            .overlay(
                // Subtle border for definition
                RoundedRectangle(cornerRadius: 24)
                    .stroke(theme.border, lineWidth: 0.5)
                    .opacity(isUrgentTask && !task.isCompleted ? 0 : 1)
            )
            .overlay(
                // Urgent border pulsation effect coordinated with glow
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: theme.background == .black ? [
                                Color(red: 1.0, green: 0.4, blue: 0.4).opacity(urgentBorderOpacity * 0.9),
                                Color(red: 1.0, green: 0.4, blue: 0.4).opacity(urgentBorderOpacity * 0.7),
                                Color(red: 1.0, green: 0.4, blue: 0.4).opacity(urgentBorderOpacity * 0.5)
                            ] : [
                                Color(red: 0.7, green: 0.05, blue: 0.05).opacity(urgentBorderOpacity * 1.0), // Darker red for light mode
                                Color(red: 0.8, green: 0.1, blue: 0.1).opacity(urgentBorderOpacity * 0.8),
                                Color(red: 0.7, green: 0.05, blue: 0.05).opacity(urgentBorderOpacity * 0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: theme.background == .black ? 1.5 : 2.0
                    )
                    .scaleEffect(isUrgentTask && !task.isCompleted ? urgentBorderScale : 1.0)
                    .opacity(isUrgentTask && !task.isCompleted ? urgentBorderOpacity : 0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: urgentBorderOpacity)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: urgentBorderScale)
            )
            .scaleEffect(isPressed ? 0.99 : (isUrgentTask ? urgentPulseScale : 1.0))
            .opacity(completionOpacity * (isUrgentTask ? urgentPulseOpacity : 1.0))
            .animation(UIOptimizer.optimizedAnimation(duration: 0.15), value: isPressed)

            .offset(x: dragOffset)
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .animation(UIOptimizer.optimizedAnimation(duration: 0.3), value: isDragging)
            .optimizedRendering(shouldUpdate: isDragging || task.isCompleted)
            .zIndex(2) // Task card layer - above action buttons
        }
        .gesture(
            // High-performance drag gesture optimized for 120fps
            DragGesture(minimumDistance: 5, coordinateSpace: .local)
                .onChanged { value in
                    // Advanced throttling for optimal performance
                    let translationDelta = abs(value.translation.width - gestureState.lastTranslation)
                    let velocityThreshold = abs(value.velocity.width) > 500 ? 1.0 : 2.0
                    
                    if translationDelta > velocityThreshold {
                        handleDragChanged(value)
                    }
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
        .simultaneousGesture(
            // Add tap gesture that doesn't interfere with drag
            TapGesture()
                .onEnded { _ in
                    handleTapGesture()
                }
        )
        .contextMenu {
            contextMenuContent
        }
        .onAppear {
            // Initial animation when task appears
            withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                completionOpacity = 1.0
            }
            
            // Start URGENT pulsating animation
            if isUrgentTask && !task.isCompleted {
                startUrgentPulsatingAnimation()
            }
        }

        .onChange(of: task.isCompleted) { _, newValue in
            // Handle URGENT animation based on completion state
            if isUrgentTask {
                if newValue {
                    // Task completed - stop animation
                    stopUrgentPulsatingAnimation()
                } else {
                    // Task uncompleted - start animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        startUrgentPulsatingAnimation()
                    }
                }
            }
        }
        .onChange(of: task.categoryId) { _, _ in
            // Handle URGENT animation when category changes
            if isUrgentTask && !task.isCompleted {
                // Task became URGENT - start animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    startUrgentPulsatingAnimation()
                }
            } else {
                // Task is no longer URGENT - stop animation
                stopUrgentPulsatingAnimation()
            }
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
    
    /// Returns the appropriate icon color based on the background color for maximum contrast
    private func getIconColor(for baseColor: Color) -> Color {
        // In dark theme, primary is white, so we need black icons for contrast
        // In light theme, primary is black, so we need white icons for contrast
        if theme is DarkTheme {
            // Dark theme: primary is white, error is bright red - use black icons
            if baseColor == theme.primary {
                return Color.black // Black icon on white background
            } else {
                return Color.white // White icon on colored backgrounds (error, success)
            }
        } else {
            // Light theme and Kawaii: primary is dark, use white icons
            return Color.white
        }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        guard !gestureCompleted else { return }
        
        let translation = value.translation.width
        let velocity = value.velocity.width
        
        // Update gesture state for performance tracking
        gestureState.velocity = velocity
        gestureState.isActive = true
        
        // If confirmations are showing, handle dismissal gesture
        if showBothActionsConfirmation {
            let dismissThreshold: CGFloat = 30
            if translation > dismissThreshold {
                dismissConfirmations()
                return
            }
            return
        }
        
        // Only respond to left swipes (negative translation)
        guard translation < 0 else {
            // Right swipes reset to neutral with optimized animation
            if dragOffset != 0 {
                resetToNeutralState()
            }
            return
        }
        
        // Determine initial swipe direction on first significant movement
        if gestureState.initialDirection == nil && abs(translation) > 15 {
            gestureState.initialDirection = .left
        }
        
        // Trigger gesture start haptic on first movement
        if !isDragging && abs(translation) > 8 {
            HapticManager.shared.gestureStart()
            HapticManager.shared.prepareForGestures()
        }
        
        // Optimized icon state management
        if gestureState.hasShownIcon {
            handleIconShownState(translation: translation)
            return
        }
        
        // Normal gesture processing with performance optimizations
        let limitedTranslation = max(-maxDragDistance, translation)
        
        // Use high-performance animation for 120fps
        updateDragState(translation: limitedTranslation)
        
        // Calculate progress and update visual feedback
        updateVisualFeedback(translation: limitedTranslation)
        
        // Handle haptic feedback efficiently
        handleHapticFeedback(translation: limitedTranslation)
        
        // Store last translation for velocity calculations
        gestureState.lastTranslation = translation
    }
    
    // MARK: - Optimized Helper Methods for Gesture Handling
    
    private func resetToNeutralState() {
        // High-performance spring animation for 120fps
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
            dragOffset = 0
            isDragging = false
            dragProgress = 0
            showEditIcon = false
            showDeleteIcon = false
        }
    }
    
    private func handleIconShownState(translation: CGFloat) {
        let distanceFromNeutral = abs(translation)
        
        // Block further movement away from neutral
        if distanceFromNeutral > abs(dragOffset) {
            // Keep current position with minimal animation overhead
            dragProgress = 0
            showEditIcon = false
            showDeleteIcon = false
            return
        }
        
        // Allow movement toward neutral only
        if translation > dragOffset {
            return
        }
        
        // Update position with optimized animation
        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.9, blendDuration: 0)) {
            dragOffset = translation
            isDragging = abs(translation) > 10
        }
        
        // Reset visual indicators
        dragProgress = 0
        showEditIcon = false
        showDeleteIcon = false
    }
    
    private func updateDragState(translation: CGFloat) {
        // Use interactive spring for real-time responsiveness
        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.9, blendDuration: 0)) {
            dragOffset = translation
            isDragging = abs(translation) > 10
        }
    }
    
    private func updateVisualFeedback(translation: CGFloat) {
        // Calculate progress for visual feedback
        dragProgress = min(1.0, abs(translation) / abs(actionThreshold))
        let shouldShowIcons = abs(translation) > 40
        
        // Batch state updates to reduce re-renders
        let newShowDeleteIcon = shouldShowIcons
        let newShowEditIcon = shouldShowIcons
        
        if newShowDeleteIcon != showDeleteIcon || newShowEditIcon != showEditIcon {
            showDeleteIcon = newShowDeleteIcon
            showEditIcon = newShowEditIcon
            
            if shouldShowIcons {
                gestureState.hasShownIcon = true
            }
        }
    }
    
    private func handleHapticFeedback(translation: CGFloat) {
        // Trigger haptic feedback at threshold
        if !hasTriggeredHaptic && translation < actionThreshold {
            HapticManager.shared.gestureThreshold()
            hasTriggeredHaptic = true
        }
        
        // Reset haptic flag if user pulls back
        if abs(translation) < abs(actionThreshold * 0.8) {
            hasTriggeredHaptic = false
        }
    }
    
    private func handleTapGesture() {
        // Dismiss confirmations if tapped elsewhere
        if showBothActionsConfirmation {
            dismissConfirmations()
        } else {
            // Provide subtle tap feedback for all tasks
            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8, blendDuration: 0)) {
                isPressed = true
            }
            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8, blendDuration: 0).delay(0.1)) {
                isPressed = false
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let translation = value.translation.width
        let velocity = value.velocity.width
        
        // Mark gesture as inactive
        gestureState.isActive = false
        
        // If confirmations are already showing, handle dismissal
        if showBothActionsConfirmation {
            let dismissThreshold: CGFloat = 30
            
            if translation > dismissThreshold {
                dismissConfirmations()
            } else {
                // Snap back to confirmation position with optimized animation
                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                    dragOffset = -140
                }
            }
            return
        }
        
        // Only respond to left swipes
        guard translation < 0 else {
            HapticManager.shared.gestureCancelled()
            dismissConfirmations()
            return
        }
        
        // If user was swiping right after showing icons, always reset
        if gestureState.hasShownIcon && translation > 0 {
            HapticManager.shared.gestureCancelled()
            dismissConfirmations()
            return
        }
        
        // Enhanced gesture recognition with velocity consideration
        let shouldShowBothActionsConfirmation = shouldTriggerConfirmation(translation: translation, velocity: velocity)
        
        if shouldShowBothActionsConfirmation {
            // Show both actions confirmation with optimized animation
            HapticManager.shared.gestureThreshold()
            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                showBothActionsConfirmation = true
                dragOffset = -140
            }
        } else {
            // Snap back to original position with cancel haptic
            HapticManager.shared.gestureCancelled()
            dismissConfirmations()
        }
    }
    
    private func shouldTriggerConfirmation(translation: CGFloat, velocity: CGFloat) -> Bool {
        // Enhanced gesture recognition logic
        let distanceThreshold = translation < actionThreshold
        let velocityThreshold = translation < -70 && velocity < -800
        let combinedThreshold = translation < -60 && velocity < -500
        
        return distanceThreshold || velocityThreshold || combinedThreshold
    }
    
    private func confirmEditAction() {
        // Execute the edit action
        gestureCompleted = true
        HapticManager.shared.buttonTap()
        
        // Reset gesture state and trigger edit
        resetGestureState()
        
        // Trigger edit action
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onEdit()
        }
    }
    
    private func confirmMarkIncompleteAction() {
        // Execute the mark as incomplete action
        gestureCompleted = true
        HapticManager.shared.buttonTap()
        
        // Reset gesture state and trigger completion toggle
        resetGestureState()
        
        // Trigger completion toggle to mark as incomplete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onToggleCompletion()
        }
    }
    
    private func confirmDeleteAction() {
        // Execute the deletion action with animation
        gestureCompleted = true
        HapticManager.shared.swipeToDelete()
        
        // High-performance delete animation
        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
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
        // Notify parent that deletion was canceled
        onDeleteCanceled?()
    }
    
    private func performCompletionToggle() {
        // Prepare haptic feedback for better responsiveness
        HapticManager.shared.prepareForInteraction()
        
        // High-performance completion animation
        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
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
            
            // Stop URGENT pulsating animation if task is being completed
            if isUrgentTask && !task.isCompleted {
                stopUrgentPulsatingAnimation()
            }
            // Restart URGENT pulsating animation if task is being uncompleted
            else if isUrgentTask && task.isCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startUrgentPulsatingAnimation()
                }
            }
        }
        
        // Reset animation states with high-performance animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                completionScale = 1.0
                showCompletionParticles = false
            }
        }
    }
    
    private func resetGestureState() {
        // High-performance reset animation for 120fps
        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
            dragOffset = 0
            isDragging = false
            dragProgress = 0
            showEditIcon = false
            showDeleteIcon = false
            showBothActionsConfirmation = false
            completionOpacity = 1.0
        }
        
        // Reset all gesture state efficiently
        hasTriggeredHaptic = false
        gestureCompleted = false
        gestureState = GestureState() // Reset entire gesture state at once
    }
    
    private func duplicateTask() {
        taskManager.duplicateTask(task)
    }
    
    /// Starts the enhanced pulsating animation for URGENT category tasks
    private func startUrgentPulsatingAnimation() {
        // Only animate if task is not completed and is URGENT
        guard isUrgentTask && !task.isCompleted else { return }
        
        // Create border pulse animation with improved timing
        // Using ease-in-out curves for smooth, polished breathing motion
        withAnimation(
            Animation.easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
        ) {
            urgentPulseOpacity = theme.background == .black ? 0.95 : 0.92
            urgentBorderOpacity = theme.background == .black ? 0.6 : 0.8 // More prominent border in light mode
        }
        
        // Add more noticeable card scale for breathing motion
        withAnimation(
            Animation.easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
                .delay(0.1)
        ) {
            urgentPulseScale = theme.background == .black ? 1.002 : 1.004  // More prominent scale in light mode
        }
        
        // Reset border scale for clean appearance
        urgentBorderScale = 1.0
    }
    
    /// Stops the URGENT pulsating animation
    private func stopUrgentPulsatingAnimation() {
        withAnimation(.easeOut(duration: 0.5)) {
            urgentPulseScale = theme.background == .black ? 0.998 : 0.996  // Reset to minimum scale
            urgentPulseOpacity = theme.background == .black ? 0.95 : 0.92  // Reset to minimum opacity
            urgentBorderOpacity = 0.0
            urgentBorderScale = 1.0
        }
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
            // Maximum contrast for urgent tasks in light and kawaii themes
            (isUrgentTask && (theme.background != .black)) ? Color.white : theme.textSecondary
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(
                    task.isOverdue ? theme.error.opacity(0.15) :
                    task.isPending ? theme.warning.opacity(0.1) :
                    // Maximum contrast background for urgent tasks in light and kawaii themes
                    (isUrgentTask && (theme.background != .black)) ? 
                        (theme is KawaiiTheme ? Color(red: 0.05, green: 0.05, blue: 0.05) : Color.black.opacity(0.85)) : 
                        theme.surfaceSecondary
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    task.isOverdue ? theme.error.opacity(0.3) :
                    task.isPending ? theme.warning.opacity(0.2) :
                    // Maximum contrast border for urgent tasks in light and kawaii themes
                    (isUrgentTask && (theme.background != .black)) ? 
                        (theme is KawaiiTheme ? Color.black : Color.black.opacity(0.9)) : Color.clear,
                    lineWidth: (isUrgentTask && (theme.background != .black)) ? 
                        (theme is KawaiiTheme ? 2.0 : 1.5) : 1
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
        .foregroundColor(
            // Maximum contrast for urgent tasks in light and kawaii themes
            (isUrgentTask && (theme.background != .black)) ? 
                Color.white : // White text for maximum contrast
                theme.warning
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(
                    // Maximum contrast background for urgent tasks in light and kawaii themes
                    (isUrgentTask && (theme.background != .black)) ? 
                        (theme is KawaiiTheme ? Color(red: 0.7, green: 0.3, blue: 0.0) : Color(red: 0.9, green: 0.5, blue: 0.0)) : // Darker orange for kawaii
                        theme.warning.opacity(0.1)
                )
        )
        .overlay(
            // Maximum contrast border for urgent tasks in light and kawaii themes
            (isUrgentTask && (theme.background != .black)) ?
                Capsule()
                    .stroke(
                        (theme is KawaiiTheme ? Color(red: 0.5, green: 0.2, blue: 0.0) : Color(red: 0.7, green: 0.4, blue: 0.0)),
                        lineWidth: (theme is KawaiiTheme ? 2.0 : 1.5)
                    ) : nil
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
    
    private func toggleChecklistItem(_ item: ChecklistItem) {
        // Create a mutable copy of the task
        var updatedTask = task
        
        // Find and update the checklist item
        if let index = updatedTask.checklist.firstIndex(where: { $0.id == item.id }) {
            updatedTask.checklist[index].isCompleted.toggle()
            
            // Update the task through the task manager
            taskManager.updateTask(updatedTask)
            
            // Provide haptic feedback
            HapticManager.shared.buttonTap()
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
            onDelete: {},
            onDeleteCanceled: nil,
            isInCompletedView: false
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
            onDelete: {},
            onDeleteCanceled: nil,
            isInCompletedView: true
        )
        
        TaskRowView(
            task: {
                var task = Task(title: "Overdue Task", description: "This task is overdue", dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
                return task
            }(),
            namespace: Namespace().wrappedValue,
            onToggleCompletion: {},
            onEdit: {},
            onDelete: {},
            onDeleteCanceled: nil,
            isInCompletedView: false
        )
    }
    .padding()
    .background(LightTheme().backgroundGradient)
    .environment(\.theme, LightTheme())
    .environmentObject(TaskManager())
    .environmentObject(CategoryManager())
}