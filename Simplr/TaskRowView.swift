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
        var gestureStartTime: Date? = nil
        var isScrollGesture = false
        
        mutating func reset() {
            initialDirection = nil
            hasShownIcon = false
            lastTranslation = 0
            velocity = 0
            isActive = false
            gestureStartTime = nil
            isScrollGesture = false
        }
        
        mutating func markAsScrollGesture() {
            isScrollGesture = true
        }
    }
    
    // URGENT category pulsating animation states - optimized for performance
    @State private var urgentGlowIntensity: CGFloat = 0.0
    @State private var urgentTintOpacity: CGFloat = 0.0
    
    // Constants for gesture thresholds
    private let actionThreshold: CGFloat = -120 // Only left swipe triggers actions
    private let maxDragDistance: CGFloat = 150
    
    // Computed property to check if task has URGENT category (optimized)
    private var isUrgentTask: Bool {
        return isUrgentTaskMemoized
    }
    
    // Cached icon colors for performance optimization during animations
    private var cachedDeleteIconColor: Color {
        getIconColor(for: theme.error)
    }
    
    private var cachedEditIconColor: Color {
        getIconColor(for: isInCompletedView ? theme.warning : theme.primary)
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
                                .scaleEffect(showBothActionsConfirmation ? 1.0 : (showDeleteIcon ? 1.0 : 0.85))
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
                                        .foregroundColor(cachedDeleteIconColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Preview icon with consistent sizing and cached color for performance
                                Image(systemName: "trash")
                                    .font(.system(size: showDeleteIcon ? 18 : 14, weight: .bold))
                                    .foregroundColor(cachedDeleteIconColor)
                                    .scaleEffect(1.0)
                                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.8, blendDuration: 0), value: showDeleteIcon)
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
                                .scaleEffect(showBothActionsConfirmation ? 1.0 : (showEditIcon ? 1.0 : 0.85))
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
                                        .foregroundColor(cachedEditIconColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Preview icon with consistent sizing and cached color for performance
                                Image(systemName: isInCompletedView ? "arrow.uturn.backward" : "pencil")
                                    .font(.system(size: showEditIcon ? 18 : 14, weight: .bold))
                                    .foregroundColor(cachedEditIconColor)
                                    .scaleEffect(1.0)
                                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.8, blendDuration: 0), value: showEditIcon)
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
                        // Ultra-optimized completion icon with device-adaptive animation
                        Image(systemName: (task.isCompleted || showCheckmark) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor((task.isCompleted || showCheckmark) ? theme.success : theme.textTertiary)
                            .scaleEffect(completionScale)
                            .animation(
                                UIOptimizer.completionAnimation(),  // Device-optimized animation
                                value: completionScale  // Single animation trigger for maximum performance
                            )
                            .matchedGeometryEffect(id: "\(task.id)-completion", in: namespace)
                        
                        // Ultra-optimized particle effect with device-adaptive performance
                        if showCompletionParticles {
                            ForEach(0..<5, id: \.self) { index in  // Further reduced to 5 particles for optimal performance
                                Circle()
                                    .fill(theme.success)
                                    .frame(width: 2.5, height: 2.5)  // Even smaller particles for smoother animation
                                    .offset(
                                        x: cos(Double(index) * .pi / 2.5) * 20,  // Reduced radius for tighter effect
                                        y: sin(Double(index) * .pi / 2.5) * 20
                                    )
                                    .scaleEffect(showCompletionParticles ? 0 : 1)
                                    .opacity(showCompletionParticles ? 0 : 1)
                                    .animation(
                                        UIOptimizer.particleAnimation(delay: Double(index) * 0.02),  // Device-optimized with faster sequence
                                        value: showCompletionParticles
                                    )
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressed ? 0.97 : 1.0)  // Minimal scale for ultra-subtle effect
                .animation(
                    UIOptimizer.buttonResponseAnimation(),  // Device-optimized ultra-fast response
                    value: isPressed
                )
                
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
                                ChecklistProgressHeader(checklist: task.checklist)
                                    .animation(.easeInOut(duration: 0.3), value: task.checklist.map { $0.isCompleted })
                                
                                // Individual checklist items
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(task.checklist) { item in
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                // Immediate haptic feedback for responsiveness
                                                HapticManager.shared.buttonTap()
                                                toggleChecklistItem(item)
                                            }) {
                                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(item.isCompleted ? theme.success : theme.textTertiary)
                                                    .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .contentShape(Circle())
                                            .frame(width: 24, height: 24)
                                            .allowsHitTesting(true)
                                            .highPriorityGesture(
                                                TapGesture()
                                                    .onEnded { _ in
                                                        // Immediate haptic feedback for responsiveness
                                                        HapticManager.shared.buttonTap()
                                                        toggleChecklistItem(item)
                                                    }
                                            )
                                            
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
                            dueDatePill(dueDate: dueDate)
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
                        // Enhanced dark mode task card gradient with better distinction
                        (theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.08, blue: 0.08),  // Lighter top for better contrast
                                Color(red: 0.05, green: 0.05, blue: 0.05),  // Mid-tone
                                Color(red: 0.06, green: 0.06, blue: 0.06)   // Slightly lighter bottom
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : theme.surfaceGradient)
                    )
                    // Category-based glow effect removed
                    .shadow(
                        color: isUrgentTask && !task.isCompleted ? 
                            (theme.background == .black ? Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.25) : Color(red: 0.8, green: 0.1, blue: 0.1).opacity(0.35)) : 
                            // Enhanced shadow for better card distinction in dark mode
                            (theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? 
                                Color.black.opacity(0.9) :  // Stronger shadow for better separation
                                (themeManager.themeMode == .kawaii ? theme.shadow.opacity(0.4) : theme.shadow.opacity(0.6))),
                        radius: isUrgentTask && !task.isCompleted ? (theme.background == .black ? 8 : 12) : 
                            // Enhanced shadow radius for better card distinction
                            (theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? 18 :  // Larger radius for more depth
                                (themeManager.themeMode == .kawaii ? 1.0 : 1.0)),
                        x: 0,
                        y: isUrgentTask && !task.isCompleted ? (theme.background == .black ? 2 : 3) : 
                            // Enhanced shadow offset for better depth perception
                            (theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? 10 :  // Increased offset for more pronounced depth
                                (themeManager.themeMode == .kawaii ? 0.3 : 0.3))
                    )
            )
            .overlay(
                // Standard border for non-urgent tasks - using strokeBorder for clean corners
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        getBorderColor(for: theme),
                        lineWidth: getBorderWidth(for: theme)
                    )
                    .opacity(isUrgentTask && !task.isCompleted ? 0 : 1)
            )
            .overlay(
                // Optimized urgent red glow border - contained within card bounds
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.red.opacity(urgentGlowIntensity * 0.9),
                                Color.red.opacity(urgentGlowIntensity * 0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .opacity(isUrgentTask && !task.isCompleted ? 1.0 : 0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: urgentGlowIntensity)
            )
            .scaleEffect(isPressed ? 0.99 : 1.0)
            .opacity(completionOpacity)
            .overlay(
                // Red tint overlay for urgent tasks with inner glow
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.red.opacity(urgentTintOpacity * 0.12),
                                Color.red.opacity(urgentTintOpacity * 0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: urgentTintOpacity)
            )
            .animation(UIOptimizer.optimizedAnimation(duration: 0.15), value: isPressed)

            .offset(x: dragOffset)
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .animation(UIOptimizer.optimizedAnimation(duration: 0.3), value: isDragging)
            .optimizedRendering(shouldUpdate: isDragging || task.isCompleted)
            .zIndex(2) // Task card layer - above action buttons
        }
        .gesture(
            // Highly optimized drag gesture for seamless scrolling
            DragGesture(minimumDistance: 2, coordinateSpace: .local)
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
        .simultaneousGesture(
            // Add tap gesture that doesn't interfere with drag or scroll
            TapGesture()
                .onEnded { _ in
                    handleTapGesture()
                }
        )
        .contextMenu {
            contextMenuContent
        } preview: {
            taskDetailPreview
        }
        .onAppear {
            // Synchronize showCheckmark with actual task completion state on appear
            // This fixes the issue where undone tasks show the checkmark tick
            showCheckmark = task.isCompleted
            
            // Ultra-optimized initial animation when task appears
            withAnimation(UIOptimizer.optimizedAnimation().delay(0.08)) {
                completionOpacity = 1.0
            }
            
            // Start URGENT pulsating animation
            if isUrgentTask && !task.isCompleted {
                startUrgentPulsatingAnimation()
            }
        }

        .onChange(of: task.isCompleted) { _, newValue in
            // Synchronize showCheckmark when task completion state changes externally
            // This ensures visual consistency when tasks are updated from other views
            if !isDragging && !gestureCompleted {
                showCheckmark = newValue
            }
            
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
                withAnimation(UIOptimizer.buttonResponseAnimation()) {
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
    
    // MARK: - Preview Content
    
    private var taskDetailPreview: some View {
        TaskDetailPreviewView(task: task)
            .environmentObject(categoryManager)
            .environmentObject(themeManager)
            .environmentObject(taskManager)
            .onAppear {
                HapticManager.shared.previewAppears()
            }
            .onDisappear {
                HapticManager.shared.previewDismissed()
            }
    }
    
    // MARK: - Helper Methods
    
    /// Returns subtle, consistent border color for all themes with enhanced visibility for light themes
    private func getBorderColor(for theme: Theme) -> Color {
        // Enhanced border visibility for light and kawaii themes while maintaining subtlety
        if theme is KawaiiTheme {
            // Kawaii theme: soft pink-gray border that's visible but not prominent
            return Color(red: 0.75, green: 0.65, blue: 0.68).opacity(0.6)
        } else if theme.background == Color.white || 
                  theme.background == Color(red: 0.98, green: 0.98, blue: 0.98) ||
                  theme.background == Color(red: 0.98, green: 0.99, blue: 1.0) ||
                  theme.background == Color(red: 0.98, green: 1.0, blue: 0.99) {
            // Light themes: subtle gray border with better visibility
            return Color(red: 0.85, green: 0.85, blue: 0.85).opacity(0.7)
        } else {
            // Dark themes: use existing border with reduced opacity
            return theme.border.opacity(0.3)
        }
    }
    
    /// Returns consistent border width across all themes for uniform appearance
    private func getBorderWidth(for theme: Theme) -> CGFloat {
        // Consistent 0.8pt border width for all themes - subtle but visible
        return 0.8
    }
    

    
    /// Returns the appropriate icon color based on the background color for maximum contrast
    private func getIconColor(for baseColor: Color) -> Color {
        // Handle dark themes (DarkTheme, DarkBlueTheme, and DarkPurpleTheme) with optimized color selection
        if theme is DarkTheme {
            // Dark theme: primary is white, error is bright red - use black icons
            if baseColor == theme.primary {
                return Color.black // Black icon on white background
            } else {
                return Color.white // White icon on colored backgrounds (error, success)
            }
        } else if theme is DarkBlueTheme {
            // Dark Blue theme: optimized icon colors for blue-tinted backgrounds
            if baseColor == theme.primary {
                // Primary blue background - use dark icon for contrast
                return Color(red: 0.1, green: 0.15, blue: 0.25)
            } else if baseColor == theme.error {
                // Red error background - use white icon
                return Color.white
            } else if baseColor == theme.warning {
                // Orange warning background - use dark icon
                return Color(red: 0.1, green: 0.15, blue: 0.25)
            } else {
                // Other colored backgrounds - use white for contrast
                return Color.white
            }
        } else if theme is DarkPurpleTheme {
            // Dark Purple theme: optimized icon colors for purple-tinted backgrounds
            if baseColor == theme.primary {
                // Primary purple background - use dark icon for contrast
                return Color(red: 0.08, green: 0.05, blue: 0.15)
            } else if baseColor == theme.error {
                // Red error background - use white icon
                return Color.white
            } else if baseColor == theme.warning {
                // Orange warning background - use dark icon
                return Color(red: 0.08, green: 0.05, blue: 0.15)
            } else {
                // Other colored backgrounds - use white for contrast
                return Color.white
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
        let horizontalTranslation = abs(value.translation.width)
        let verticalTranslation = abs(value.translation.height)
        
        // Initialize gesture timing if this is the first movement
        if gestureState.gestureStartTime == nil {
            gestureState.gestureStartTime = Date()
        }
        
        // If this is marked as a scroll gesture, don't process further
        if gestureState.isScrollGesture {
            return
        }
        
        // Simplified scroll detection - only block if it's clearly a vertical scroll
        // Allow more horizontal movement to coexist with vertical scrolling
        let isDefinitelyScrollGesture = (
            // Strong vertical movement with very little horizontal component
            (verticalTranslation > 25 && horizontalTranslation < 10) ||
            // Very fast vertical velocity with minimal horizontal
            (abs(value.velocity.height) > 400 && abs(value.velocity.width) < 100)
        )
        
        if isDefinitelyScrollGesture {
            gestureState.markAsScrollGesture()
            if isDragging {
                resetToNeutralState()
            }
            return
        }
        
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
        
        // Require more deliberate horizontal movement before engaging swipe
        // This prevents accidental swipe activation during vertical scrolling
        guard horizontalTranslation > 15 else { return }
        
        // Additional check: ensure horizontal movement is more significant than vertical
        guard horizontalTranslation > verticalTranslation * 0.6 else { return }
        
        // Determine initial swipe direction on first significant movement
        if gestureState.initialDirection == nil && abs(translation) > 12 {
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
        // Immediately clear scroll gesture flag to allow scrolling
        gestureState.isScrollGesture = false
        gestureState.isActive = false
        
        // High-performance spring animation for 120fps
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
            dragOffset = 0
            isDragging = false
            dragProgress = 0
            showEditIcon = false
            showDeleteIcon = false
        }
        
        // Reset enhanced gesture state
        gestureState.reset()
        gestureCompleted = false
        hasTriggeredHaptic = false
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
        // Use interactive spring for real-time responsiveness with theme-specific optimizations
        let isDarkThemeOptimized = theme is DarkBlueTheme || theme is DarkPurpleTheme
        let animationResponse: Double = isDarkThemeOptimized ? 0.2 : 0.25
        let animationDamping: Double = isDarkThemeOptimized ? 0.95 : 0.9
        
        withAnimation(.interactiveSpring(response: animationResponse, dampingFraction: animationDamping, blendDuration: 0)) {
            dragOffset = translation
            isDragging = abs(translation) > 10
        }
    }
    
    private func updateVisualFeedback(translation: CGFloat) {
        // Calculate progress for visual feedback
        dragProgress = min(1.0, abs(translation) / abs(actionThreshold))
        
        // Theme-specific icon thresholds for optimal user experience
        let iconThreshold: CGFloat = {
            if theme is DarkPurpleTheme || theme is DarkBlueTheme {
                return 50 // Higher threshold for dark themes to prevent premature appearance
            } else {
                return 40 // Standard threshold for other themes
            }
        }()
        
        let shouldShowIcons = abs(translation) > iconThreshold
        
        // Batch state updates to reduce re-renders with improved state management
        let newShowDeleteIcon = shouldShowIcons
        let newShowEditIcon = shouldShowIcons
        
        if newShowDeleteIcon != showDeleteIcon || newShowEditIcon != showEditIcon {
            // Use optimized animation for icon state changes with theme-specific performance tuning
            let isDarkThemeOptimized = theme is DarkBlueTheme || theme is DarkPurpleTheme
            let animationResponse: Double = isDarkThemeOptimized ? 0.2 : 0.25
            let animationDamping: Double = isDarkThemeOptimized ? 0.9 : 0.8
            
            withAnimation(.interactiveSpring(response: animationResponse, dampingFraction: animationDamping, blendDuration: 0)) {
                showDeleteIcon = newShowDeleteIcon
                showEditIcon = newShowEditIcon
            }
            
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
        
        // If this was identified as a scroll gesture, reset state and allow scrolling
        if gestureState.isScrollGesture {
            resetToNeutralState()
            return
        }
        
        // Mark gesture as inactive and clear scroll gesture flag
        gestureState.isActive = false
        gestureState.isScrollGesture = false
        
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
        
        // Immediately clear scroll gesture flag to allow scrolling
        gestureState.isScrollGesture = false
        gestureState.isActive = false
        
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
        
        // Immediately clear scroll gesture flag to allow scrolling
        gestureState.isScrollGesture = false
        gestureState.isActive = false
        
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
        
        // Immediately clear scroll gesture flag to allow scrolling
        gestureState.isScrollGesture = false
        gestureState.isActive = false
        
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
        
        // Immediately clear scroll gesture flag to allow scrolling
        gestureState.isScrollGesture = false
        gestureState.isActive = false
        
        resetGestureState()
        // Notify parent that deletion was canceled
        onDeleteCanceled?()
    }
    
    private func performCompletionToggle() {
        // Prepare haptic feedback for better responsiveness
        HapticManager.shared.prepareForInteraction()
        
        // Device-optimized animation for maximum performance
        withAnimation(UIOptimizer.completionAnimation()) {
            if !task.isCompleted {
                // Animate completion - immediate visual feedback
                completionScale = 1.1  // Further reduced scale for ultra-smooth animation
                showCompletionParticles = true
                showCheckmark = true
                HapticManager.shared.taskCompleted()
            } else {
                // Animate un-completion - immediate visual feedback
                showCheckmark = false
                completionScale = 1.05  // Minimal scale for uncomplete
                HapticManager.shared.taskUncompleted()
            }
        }
        
        // Trigger the actual completion toggle with ultra-fast delay for immediate feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {  // Ultra-fast delay
            onToggleCompletion()
            
            // Optimized URGENT animation handling
            if isUrgentTask {
                if !task.isCompleted {
                    stopUrgentPulsatingAnimation()
                } else {
                    // Reduced delay for better responsiveness
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        startUrgentPulsatingAnimation()
                    }
                }
            }
        }
        
        // Ultra-optimized reset with device-adaptive animation and reduced timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {  // Further reduced for faster feedback
            withAnimation(UIOptimizer.completionAnimation()) {  // Device-optimized reset animation
                completionScale = 1.0
                showCompletionParticles = false
            }
            
            // Reset gestureCompleted flag to allow external state synchronization
            gestureCompleted = false
        }
    }
    
    private func resetGestureState() {
        // Ultra-high-performance reset animation with device optimization
        withAnimation(UIOptimizer.buttonResponseAnimation()) {
            dragOffset = 0
            isDragging = false
            dragProgress = 0
            showEditIcon = false
            showDeleteIcon = false
            showBothActionsConfirmation = false
            completionOpacity = 1.0
        }
        
        // Reset all gesture state efficiently with explicit cleanup
        hasTriggeredHaptic = false
        gestureCompleted = false
        
        // Explicitly reset gesture state to ensure clean slate
        gestureState.reset()
        
        // Ultra-fast delay to ensure state is fully cleared before allowing new gestures
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            // Additional cleanup to ensure no lingering state
            gestureState.isScrollGesture = false
            gestureState.isActive = false
        }
    }
    
    private func duplicateTask() {
        taskManager.duplicateTask(task)
    }
    
    /// Starts the optimized red glow pulsating animation for URGENT category tasks
    private func startUrgentPulsatingAnimation() {
        // Only animate if task is not completed and is URGENT
        guard isUrgentTask && !task.isCompleted else { return }
        
        // Single, optimized animation for both glow and tint
        // Using a longer duration for a more subtle, elegant pulse
        withAnimation(
            Animation.easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
        ) {
            urgentGlowIntensity = 0.7  // Moderate glow intensity for visibility without being overwhelming
            urgentTintOpacity = 0.6    // Subtle red tint on the card
        }
    }
    
    /// Stops the URGENT pulsating animation with device-optimized performance
    private func stopUrgentPulsatingAnimation() {
        withAnimation(UIOptimizer.optimizedAnimation()) {
            urgentGlowIntensity = 0.0
            urgentTintOpacity = 0.0
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
            task.isOverdue ? 
                (theme is KawaiiTheme ? Color.white : theme.error) : 
            task.isPending ? 
                (theme is KawaiiTheme ? Color(red: 0.2, green: 0.1, blue: 0.15) : theme.warning) : 
            // Enhanced visibility for kawaii theme with stronger contrast
            (isUrgentTask && (theme.background != .black)) ? Color.white : 
            (theme is KawaiiTheme ? Color(red: 0.15, green: 0.1, blue: 0.2) : theme.textSecondary)
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(
                    task.isOverdue ? 
                        (theme is KawaiiTheme ? 
                            Color(red: 0.9, green: 0.3, blue: 0.4) : // Strong kawaii error background
                            theme.error.opacity(0.15)) :
                    task.isPending ? 
                        (theme is KawaiiTheme ? 
                            Color(red: 0.95, green: 0.7, blue: 0.3) : // Kawaii warning background
                            theme.warning.opacity(0.1)) :
                    // Enhanced kawaii theme due date pill background for better visibility
                    (isUrgentTask && (theme.background != .black)) ? 
                        (theme is KawaiiTheme ? 
                            Color(red: 0.7, green: 0.5, blue: 0.8) : // Kawaii urgent background
                            Color.black.opacity(0.85)) : 
                    (theme is KawaiiTheme ? 
                        Color(red: 0.95, green: 0.9, blue: 0.95) : // Subtle kawaii normal background
                        theme.surfaceSecondary)
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    task.isOverdue ? 
                        (theme is KawaiiTheme ? 
                            Color(red: 0.7, green: 0.2, blue: 0.3) : // Strong kawaii error border
                            theme.error.opacity(0.3)) :
                    task.isPending ? 
                        (theme is KawaiiTheme ? 
                            Color(red: 0.8, green: 0.5, blue: 0.2) : // Kawaii warning border
                            theme.warning.opacity(0.2)) :
                    // Enhanced kawaii theme border for better visibility
                    (isUrgentTask && (theme.background != .black)) ? 
                        (theme is KawaiiTheme ? 
                            Color(red: 0.5, green: 0.3, blue: 0.6) : // Kawaii urgent border
                            Color.black.opacity(0.9)) : 
                    (theme is KawaiiTheme ? 
                        Color(red: 0.8, green: 0.7, blue: 0.85).opacity(0.4) : // Subtle kawaii normal border
                        Color.clear),
                    lineWidth: theme is KawaiiTheme ? 
                        (task.isOverdue || task.isPending || isUrgentTask ? 1.2 : 0.8) : 
                        ((isUrgentTask && (theme.background != .black)) ? 1.5 : 1)
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
            // Enhanced visibility for kawaii, serene, and coffee themes with stronger contrast
            theme is KawaiiTheme ? 
                (isUrgentTask ? Color.white : Color(red: 0.2, green: 0.1, blue: 0.15)) : // Dark text for kawaii, white for urgent
            theme is SereneTheme ?
                (isUrgentTask ? Color.white : Color(red: 0.15, green: 0.12, blue: 0.18)) : // Dark purple text for serene, white for urgent
            theme is CoffeeTheme ?
                (isUrgentTask ? Color.white : Color(red: 0.18, green: 0.12, blue: 0.08)) : // Dark coffee text for coffee theme, white for urgent
                ((isUrgentTask && (theme.background != .black)) ? 
                    Color.white : // White text for maximum contrast
                    theme.warning)
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(
                    // Enhanced kawaii, serene, and coffee theme reminder pill background for better visibility
                    theme is KawaiiTheme ? 
                        (isUrgentTask ? 
                            Color(red: 0.85, green: 0.45, blue: 0.55) : // Use kawaii accent color for urgent
                            Color(red: 0.85, green: 0.45, blue: 0.55).opacity(0.15)) : // Subtle kawaii accent background for normal
                    theme is SereneTheme ?
                        (isUrgentTask ?
                            Color(red: 0.68, green: 0.58, blue: 0.82) : // Use serene accent color for urgent
                            Color(red: 0.68, green: 0.58, blue: 0.82).opacity(0.15)) : // Subtle serene accent background for normal
                    theme is CoffeeTheme ?
                        (isUrgentTask ?
                            Color(red: 0.45, green: 0.32, blue: 0.22) : // Use coffee accent color for urgent
                            Color(red: 0.45, green: 0.32, blue: 0.22).opacity(0.15)) : // Subtle coffee accent background for normal
                        ((isUrgentTask && (theme.background != .black)) ? 
                            Color(red: 0.9, green: 0.5, blue: 0.0) : // Orange for other urgent themes
                            theme.warning.opacity(0.1))
                )
        )
        .overlay(
            // Enhanced border for kawaii, serene, and coffee theme visibility
            theme is KawaiiTheme ? 
                Capsule()
                    .stroke(
                        isUrgentTask ? 
                            Color(red: 0.7, green: 0.3, blue: 0.4) : // Darker kawaii border for urgent
                            Color(red: 0.85, green: 0.45, blue: 0.55).opacity(0.4), // Subtle kawaii border for normal
                        lineWidth: isUrgentTask ? 1.0 : 0.6
                    ) :
            theme is SereneTheme ?
                Capsule()
                    .stroke(
                        isUrgentTask ?
                            Color(red: 0.55, green: 0.45, blue: 0.68) : // Darker serene border for urgent
                            Color(red: 0.68, green: 0.58, blue: 0.82).opacity(0.4), // Subtle serene border for normal
                        lineWidth: isUrgentTask ? 1.0 : 0.6
                    ) :
            theme is CoffeeTheme ?
                Capsule()
                    .stroke(
                        isUrgentTask ?
                            Color(red: 0.18, green: 0.12, blue: 0.08) : // Same dark coffee color as text for urgent
                            Color(red: 0.18, green: 0.12, blue: 0.08).opacity(0.4), // Same dark coffee color as text for normal
                        lineWidth: isUrgentTask ? 1.0 : 0.6
                    ) :
                ((isUrgentTask && (theme.background != .black)) ?
                    Capsule()
                        .stroke(
                            Color(red: 0.7, green: 0.4, blue: 0.0),
                            lineWidth: 0.8
                        ) : nil)
        )
        .scaleEffect(task.isCompleted ? 0.95 : 1.0)
        .opacity(task.isCompleted ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.3).delay(0.2), value: task.isCompleted)
    }
    
    private func dueDatePill(dueDate: Date) -> some View {
        // Computed properties to break down complex expressions for better compilation performance
        let dueDateTextColor: Color = {
            if theme is KawaiiTheme {
                if task.isOverdue {
                    return Color.white
                } else if task.isPending {
                    return Color(red: 0.2, green: 0.1, blue: 0.15)
                } else if isUrgentTask {
                    return Color.white
                } else {
                    return Color(red: 0.15, green: 0.1, blue: 0.2)
                }
            } else if theme is SereneTheme {
                if task.isOverdue || task.isPending {
                    return Color.white
                } else {
                    return Color(red: 0.15, green: 0.12, blue: 0.18)
                }
            } else {
                if task.isOverdue {
                    return theme.error
                } else if task.isPending {
                    return theme.background == .black ? Color.white : theme.warning
                } else {
                    return theme.textSecondary
                }
            }
        }()
        
        let dueDateBackgroundColor: Color = {
            if theme is KawaiiTheme {
                if task.isOverdue {
                    return Color(red: 0.85, green: 0.45, blue: 0.55)
                } else if task.isPending {
                    return Color(red: 0.92, green: 0.78, blue: 0.45)
                } else if isUrgentTask {
                    return Color(red: 0.78, green: 0.65, blue: 0.85)
                } else {
                    return Color(red: 0.95, green: 0.9, blue: 0.95)
                }
            } else if theme is SereneTheme {
                if task.isOverdue {
                    return Color(red: 0.92, green: 0.68, blue: 0.72)
                } else if task.isPending {
                    return Color(red: 0.95, green: 0.82, blue: 0.68)
                } else {
                    return Color(red: 0.68, green: 0.58, blue: 0.82).opacity(0.15)
                }
            } else {
                if task.isOverdue {
                    return theme.error.opacity(0.15)
                } else if task.isPending {
                    return theme.warning.opacity(0.15)
                } else {
                    return theme.textSecondary.opacity(0.1)
                }
            }
        }()
        
        let dueDateBorderColor: Color = {
            if theme is KawaiiTheme {
                if task.isOverdue {
                    return Color(red: 0.75, green: 0.35, blue: 0.45)
                } else if task.isPending {
                    return Color(red: 0.85, green: 0.65, blue: 0.35)
                } else if isUrgentTask {
                    return Color(red: 0.65, green: 0.45, blue: 0.75)
                } else {
                    return Color(red: 0.8, green: 0.7, blue: 0.85).opacity(0.4)
                }
            } else if theme is SereneTheme {
                if task.isOverdue {
                    return Color(red: 0.85, green: 0.55, blue: 0.60)
                } else if task.isPending {
                    return Color(red: 0.88, green: 0.70, blue: 0.55)
                } else {
                    return Color(red: 0.68, green: 0.58, blue: 0.82).opacity(0.4)
                }
            } else {
                if task.isOverdue {
                    return theme.error.opacity(0.6)
                } else if task.isPending {
                    return theme.warning.opacity(0.6)
                } else {
                    return Color.clear
                }
            }
        }()
        
        let dueDateBorderWidth: CGFloat = {
            if theme is KawaiiTheme {
                return (task.isOverdue || task.isPending || isUrgentTask) ? 1.0 : 0.8
            } else if theme is SereneTheme {
                return (task.isOverdue || task.isPending) ? 1.0 : 0.6
            } else {
                return (task.isOverdue || task.isPending) ? 0.8 : 0
            }
        }()
        
        return HStack(spacing: 4) {
            Image(systemName: task.isOverdue ? "exclamationmark.triangle.fill" : 
                  task.isPending ? "clock" : "calendar")
                .font(.caption2)
                .shadow(
                    color: theme.background == .black ? Color.white.opacity(0.05) : Color.clear,
                    radius: 0.5,
                    x: 0,
                    y: 0.3
                )
            
            Text(formatDueDate(dueDate))
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(dueDateTextColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(dueDateBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(dueDateBorderColor, lineWidth: dueDateBorderWidth)
        )
        .opacity(task.isCompleted ? 0.6 : 1.0)
        .scaleEffect(task.isCompleted ? 0.99 : 1.0, anchor: .leading)
        .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        } else {
            // For other dates, show compact date only
            formatter.dateFormat = "MMM d"
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
        // Optimized checklist item toggle with performance considerations
        PerformanceMonitor.shared.measure("ChecklistItemToggle") {
            // Create a mutable copy of the task
            var updatedTask = task
            
            // Find and update the checklist item
            if let index = updatedTask.checklist.firstIndex(where: { $0.id == item.id }) {
                updatedTask.checklist[index].isCompleted.toggle()
                
                // Update the task through the task manager (uses batch updates for performance)
                taskManager.updateTask(updatedTask)
                
                // Haptic feedback is now provided immediately in the UI layer for better responsiveness
            }
        }
    }
}

// MARK: - Checklist Progress Header Component
struct ChecklistProgressHeader: View {
    let checklist: [ChecklistItem]
    @Environment(\.theme) var theme
    
    // Optimized computed properties with caching for better performance
    private var progressData: (completed: Int, total: Int, progress: Double) {
        let total = checklist.count
        guard total > 0 else { return (0, 0, 0) }
        
        let completed = checklist.lazy.filter { $0.isCompleted }.count
        let progress = Double(completed) / Double(total)
        
        return (completed, total, progress)
    }
    
    var body: some View {
        let data = progressData
        
        HStack(spacing: 8) {
            Text("Checklist")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.textSecondary)

            // Custom progress bar to avoid SwiftUI issues
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.textTertiary.opacity(0.2))
                    .frame(width: 50, height: 5)
                
                Capsule()
                    .fill(theme.progress)
                    .frame(width: 50 * data.progress, height: 5)
                    .animation(.easeInOut(duration: 0.25), value: data.progress)
            }

            Spacer()
            
            Text("\(data.completed)/\(data.total)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(theme.textSecondary)
                .animation(.easeInOut(duration: 0.2), value: data.completed)
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