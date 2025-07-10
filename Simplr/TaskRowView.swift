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
    @State private var isPressed = false
    @State private var showCompletionParticles = false
    @State private var completionScale: CGFloat = 1.0
    @State private var checkmarkScale: CGFloat = 0.1
    @State private var showCheckmark = false
    @State private var showingQuickListDetail = false
    
    // Optimized gesture states for 120fps performance
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var dragProgress: CGFloat = 0
    @State private var showCompletionIcon = false
    @State private var showDeleteIcon = false
    @State private var hasTriggeredHaptic = false
    @State private var gestureCompleted = false
    @State private var completionOpacity: CGFloat = 0.8
    @State private var showBothActionsConfirmation = false
    
    // Performance optimization: Combine related states
    @State private var gestureState = GestureState()
    
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
    @State private var urgentPulseScale: CGFloat = 1.0
    @State private var urgentPulseOpacity: CGFloat = 1.0
    @State private var urgentGlowOpacity: CGFloat = 0.0
    
    // Constants for gesture thresholds
    private let actionThreshold: CGFloat = -120 // Only left swipe triggers actions
    private let maxDragDistance: CGFloat = 150
    
    // Computed property to check if task has URGENT category
    private var isUrgentTask: Bool {
        guard let category = categoryManager.category(for: task) else { return false }
        return category.name == "URGENT"
    }
    
    var body: some View {
        ZStack {
            // Background action indicators - positioned absolutely behind the task card
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
                        
                        // Complete action (on the right)
                        ZStack {
                            Circle()
                                .fill(showBothActionsConfirmation ? theme.success : theme.success.opacity(0.3))
                                .frame(width: showBothActionsConfirmation ? 50 : 40, height: showBothActionsConfirmation ? 50 : 40)
                                .scaleEffect(showCompletionIcon ? 1.1 : 0.9)
                                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: showCompletionIcon)
                                .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: showBothActionsConfirmation)
                            
                            if showBothActionsConfirmation {
                                // Confirmation button - execute completion immediately
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
                        .opacity(showBothActionsConfirmation ? 1.0 : abs(dragProgress))
                        .animation(.easeOut(duration: 0.2), value: dragProgress)
                    }
                    .padding(.trailing, 20)
                }
                .zIndex(1) // Background actions layer - behind the task card
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
                    // Enhanced Task title with URGENT styling
                    HStack(spacing: 8) {
                        Text(task.title)
                            .font(isUrgentTask && !task.isCompleted ? .title3 : .headline)
                            .fontWeight(isUrgentTask && !task.isCompleted ? .bold : .semibold)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(
                                task.isCompleted ? theme.textSecondary :
                                (isUrgentTask && !task.isCompleted ? Color.red.opacity(0.9) : 
                                 (theme is KawaiiTheme ? theme.accent : theme.text))
                            )
                            .opacity(task.isCompleted ? 0.7 : 1.0)
                            .scaleEffect(task.isCompleted ? 0.99 : 1.0, anchor: .leading)
                            .shadow(
                                color: isUrgentTask && !task.isCompleted ?
                                Color.red.opacity(0.2) : Color.clear,
                                radius: 1,
                                x: 0,
                                y: 0.5
                            )
                            .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                            .matchedGeometryEffect(id: "\(task.id)-title", in: namespace)
                        

                        
                        Spacer()
                    }
                    
                    // Enhanced Category indicator with special URGENT styling
                    if let category = categoryManager.category(for: task) {
                        HStack {
                            HStack(spacing: 4) {
                                if isUrgentTask && !task.isCompleted {
                                    // Warning triangle for urgent category
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color.red)
                                        .shadow(
                                            color: Color.red.opacity(0.4),
                                            radius: 3,
                                            x: 0,
                                            y: 1
                                        )
                                } else {
                                    // Regular circle for other categories
                                    Circle()
                                        .fill(themeManager.themeMode == .kawaii ? category.color.kawaiiGradient : category.color.gradient)
                                        .frame(width: 8, height: 8)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    themeManager.themeMode == .kawaii ? category.color.kawaiiDarkColor : category.color.darkColor,
                                                    lineWidth: 0.5
                                                )
                                                .opacity(0.3)
                                        )
                                }
                                
                                Text(category.name)
                                    .font(isUrgentTask && !task.isCompleted ? .caption : .caption2)
                                    .fontWeight(isUrgentTask && !task.isCompleted ? .bold : .medium)
                                    .foregroundColor(
                                        isUrgentTask && !task.isCompleted ?
                                        Color.red :
                                        (themeManager.themeMode == .kawaii ? category.color.kawaiiDarkColor : category.color.darkColor)
                                    )
                                    .shadow(
                                        color: isUrgentTask && !task.isCompleted ?
                                        Color.red.opacity(0.3) : Color.clear,
                                        radius: 1,
                                        x: 0,
                                        y: 0.5
                                    )
                            }
                            .padding(.horizontal, isUrgentTask && !task.isCompleted ? 8 : 6)
                            .padding(.vertical, isUrgentTask && !task.isCompleted ? 4 : 2)
                            .background(
                                Capsule()
                                    .fill(
                                        isUrgentTask && !task.isCompleted ?
                                        LinearGradient(
                                            colors: [
                                                Color.red.opacity(0.2),
                                                Color.red.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [themeManager.themeMode == .kawaii ? category.color.kawaiiLightColor : category.color.lightColor],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                isUrgentTask && !task.isCompleted ?
                                                Color.red.opacity(0.4) :
                                                (themeManager.themeMode == .kawaii ? category.color.kawaiiColor.opacity(0.2) : category.color.color.opacity(0.2)),
                                                lineWidth: isUrgentTask && !task.isCompleted ? 1 : 0.5
                                            )
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
                if !isDragging && !showBothActionsConfirmation {
                    HStack(spacing: 12) {
                        Button(action: {
                            HapticManager.shared.buttonTap()
                            onEdit()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        themeManager.themeMode == .kawaii ? 
                                        LinearGradient(
                                            colors: [
                                                theme.accent.opacity(0.8),
                                                theme.accent.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        theme.surfaceGradient
                                    )
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                themeManager.themeMode == .kawaii ? 
                                                theme.accent.opacity(0.4) : Color.clear,
                                                lineWidth: themeManager.themeMode == .kawaii ? 1.5 : 0
                                            )
                                    )
                                    .applyNeumorphicShadow(
                                        themeManager.themeMode == .kawaii ? 
                                        NeumorphicShadowStyle(
                                            lightShadow: ShadowStyle(
                                                color: Color.white.opacity(0.8),
                                                radius: 6,
                                                x: -3,
                                                y: -3
                                            ),
                                            darkShadow: ShadowStyle(
                                                color: theme.accent.opacity(0.3),
                                                radius: 6,
                                                x: 3,
                                                y: 3
                                            )
                                        ) :
                                        theme.neumorphicButtonStyle
                                    )
                                
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(
                                        themeManager.themeMode == .kawaii ? 
                                        Color.white : theme.primary
                                    )
                                    .shadow(
                                        color: themeManager.themeMode == .kawaii ? 
                                        theme.accent.opacity(0.5) : 
                                        (theme.background == .black ? Color.white.opacity(0.1) : Color.clear),
                                        radius: themeManager.themeMode == .kawaii ? 2 : 1,
                                        x: 0,
                                        y: themeManager.themeMode == .kawaii ? 1 : 0.5
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
            .background(
                // Enhanced URGENT background styling with modern rounded corners
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        isUrgentTask && !task.isCompleted ?
                        LinearGradient(
                            colors: [
                                Color.red.opacity(0.15),
                                Color.red.opacity(0.08),
                                Color.red.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        theme.surfaceGradient
                    )
                    .overlay(
                        // Modern border styling for seamless blending
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                isUrgentTask && !task.isCompleted ?
                                LinearGradient(
                                    colors: [
                                        Color.red.opacity(0.6),
                                        Color.red.opacity(0.3),
                                        Color.red.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                // Nearly invisible border for seamless integration
                                (themeManager.themeMode == .kawaii ?
                                LinearGradient(
                                    colors: [
                                        theme.accent.opacity(0.08),
                                        theme.accent.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ) : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)),
                                lineWidth: isUrgentTask && !task.isCompleted ? 2 : (themeManager.themeMode == .kawaii ? 0.5 : 0)
                            )
                    )
                    .shadow(
                        color: isUrgentTask && !task.isCompleted ? 
                            Color.red.opacity(0.3) : 
                            (themeManager.themeMode == .kawaii ? theme.shadow.opacity(0.4) : theme.shadow.opacity(0.6)),
                        radius: isUrgentTask && !task.isCompleted ? 12 : 
                            (themeManager.themeMode == .kawaii ? 1.0 : 1.0),
                        x: 0,
                        y: isUrgentTask && !task.isCompleted ? 4 : 
                            (themeManager.themeMode == .kawaii ? 0.3 : 0.3)
                    )
            )
            .scaleEffect(isPressed ? 0.99 : (isUrgentTask ? urgentPulseScale : 1.0))
            .opacity(completionOpacity * (isUrgentTask ? urgentPulseOpacity : 1.0))
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .overlay(
                // Enhanced URGENT glow effect with modern rounded corners
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.red.opacity(urgentGlowOpacity * 0.8),
                                Color.red.opacity(urgentGlowOpacity * 0.4),
                                Color.red.opacity(urgentGlowOpacity * 0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .blur(radius: 6)
                    .opacity(isUrgentTask && !task.isCompleted ? urgentGlowOpacity : 0)
            )
            .offset(x: dragOffset)
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: isDragging)
            .zIndex(2) // Task card layer - above action buttons
            .drawingGroup() // Optimize rendering performance for complex animations
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
        .clipped() // Optimize rendering by clipping overflow content
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
        .sheet(isPresented: $showingQuickListDetail) {
            QuickListDetailView(taskId: task.id)
                .environmentObject(taskManager)
                .environmentObject(categoryManager)
                .environment(\.theme, theme)
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
            showCompletionIcon = false
            showDeleteIcon = false
        }
    }
    
    private func handleIconShownState(translation: CGFloat) {
        let distanceFromNeutral = abs(translation)
        
        // Block further movement away from neutral
        if distanceFromNeutral > abs(dragOffset) {
            // Keep current position with minimal animation overhead
            dragProgress = 0
            showCompletionIcon = false
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
        showCompletionIcon = false
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
        let newShowCompletionIcon = shouldShowIcons
        
        if newShowDeleteIcon != showDeleteIcon || newShowCompletionIcon != showCompletionIcon {
            showDeleteIcon = newShowDeleteIcon
            showCompletionIcon = newShowCompletionIcon
            
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
        } else if task.hasQuickList {
            // Open quick list detail view for tasks with quick lists
            HapticManager.shared.buttonTap()
            showingQuickListDetail = true
        } else {
            // Subtle tap feedback for tasks without quick lists
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
    
    private func confirmCompletionAction() {
        // Execute the completion action
        gestureCompleted = true
        HapticManager.shared.swipeToComplete()
        
        // High-performance completion animation
        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
            dragOffset = UIScreen.main.bounds.width
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            performCompletionToggle()
            resetGestureState()
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
            showCompletionIcon = false
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
        
        // Create a more prominent pulsating effect
        withAnimation(
            Animation.easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
        ) {
            urgentPulseScale = 1.03
            urgentPulseOpacity = 0.8
        }
        
        // Add a stronger glow effect with different timing
        withAnimation(
            Animation.easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
                .delay(0.2)
        ) {
            urgentGlowOpacity = 0.7
        }
    }
    
    /// Stops the URGENT pulsating animation
    private func stopUrgentPulsatingAnimation() {
        withAnimation(.easeOut(duration: 0.5)) {
            urgentPulseScale = 1.0
            urgentPulseOpacity = 1.0
            urgentGlowOpacity = 0.0
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
            onDelete: {},
            onDeleteCanceled: nil
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
            onDeleteCanceled: nil
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
            onDeleteCanceled: nil
        )
    }
    .padding()
    .background(LightTheme().backgroundGradient)
    .environment(\.theme, LightTheme())
    .environmentObject(TaskManager())
    .environmentObject(CategoryManager())
}