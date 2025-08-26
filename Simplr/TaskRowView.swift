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

    
    // Ultra-optimized gesture states for 120fps performance with reduced CPU usage
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var dragProgress: CGFloat = 0
    @State private var showEditIcon = false
    @State private var showDeleteIcon = false
    @State private var hasTriggeredHaptic = false
    @State private var gestureCompleted = false
    @State private var completionOpacity: CGFloat = 0.8
    @State private var showBothActionsConfirmation = false
    
    // Performance optimization: Cache animation values
    @State private var cachedAnimationValues = AnimationCache()
    
    // Reduce state updates for better performance
    @State private var lastGestureUpdate: Date = .distantPast
    private let gestureUpdateInterval: TimeInterval = 0.008 // 120fps max update rate
    
    // Performance optimization: Combine related states with memory efficiency
    @State private var gestureState = GestureState()
    
    // Animation performance cache
    private struct AnimationCache {
        let deleteIconColor: Color
        let editIconColor: Color
        let actionButtonScale: CGFloat
        let iconTransitionDuration: Double
        
        init() {
            self.deleteIconColor = Color.red
            self.editIconColor = Color.blue
            self.actionButtonScale = 1.0
            self.iconTransitionDuration = 0.22
        }
    }
    
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
    
    // Optimized gesture state container with performance tracking
    private struct GestureState {
        var initialDirection: SwipeDirection? = nil
        var hasShownIcon = false
        var lastTranslation: CGFloat = 0
        var velocity: CGFloat = 0
        var isActive = false
        var gestureStartTime: Date? = nil
        var isScrollGesture = false
        var initialTouchLocation: CGPoint? = nil
        
        mutating func reset() {
            initialDirection = nil
            hasShownIcon = false
            lastTranslation = 0
            velocity = 0
            isActive = false
            gestureStartTime = nil
            isScrollGesture = false
            initialTouchLocation = nil
        }
        
        mutating func markAsScrollGesture() {
            isScrollGesture = true
        }
    }
    
    // URGENT category indication states - ultra-optimized for maximum performance
    @State private var urgentGlowIntensity: CGFloat = 0.0
    @State private var urgentTintOpacity: CGFloat = 0.0
    
    // iPad-specific width adaptation caching
    @State private var cachedTaskTitleWidth: CGFloat?
    @State private var lastCalculatedTitle: String = ""
    @State private var lastCalculatedTheme: String = ""
    
    // Optimized constants for gesture thresholds
    private let actionThreshold: CGFloat = -110 // Reduced for easier activation
    private let maxDragDistance: CGFloat = 140 // Slightly reduced for smoother feel
    private let hapticTriggerDistance: CGFloat = -40 // Earlier haptic feedback
    private let iconRevealDistance: CGFloat = -60 // Earlier icon visibility
    
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
    
    /// Optimized task title width for iPad content adaptation
    private var optimizedTaskTitleWidth: CGFloat? {
        // Use dynamic width based on title length for iPadOS, full width for iPhone
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return .infinity
        }
        
        // Performance optimization: cache calculated width
        let currentThemeId = getThemeId()
        if cachedTaskTitleWidth != nil && 
           lastCalculatedTitle == task.title && 
           lastCalculatedTheme == currentThemeId {
            return cachedTaskTitleWidth
        }
        
        // Calculate and cache new width
        let calculatedWidth = calculateTaskTitleWidth()
        cachedTaskTitleWidth = calculatedWidth
        lastCalculatedTitle = task.title
        lastCalculatedTheme = currentThemeId
        
        return calculatedWidth
    }
    
    /// Calculate optimal width for task title on iPad
    private func calculateTaskTitleWidth() -> CGFloat {
        let baseFont = UIFont.preferredFont(forTextStyle: .headline)
        let fontWeight: UIFont.Weight = isUrgentTask && !task.isCompleted ? 
            (theme.background == .black ? .bold : .medium) : .semibold
        
        let font = UIFont.systemFont(ofSize: baseFont.pointSize, weight: fontWeight)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        
        let textSize = (task.title as NSString).size(withAttributes: attributes)
        
        // Add padding for icons, spacing, and comfortable reading
        let basePadding: CGFloat = 60 // For completion button and spacing
        let urgentIconPadding: CGFloat = isUrgentTask && !task.isCompleted ? 24 : 0
        let comfortablePadding: CGFloat = 40 // Extra space for better UX
        
        let calculatedWidth = textSize.width + basePadding + urgentIconPadding + comfortablePadding
        
        // Constrain to reasonable bounds for iPad
        let minWidth: CGFloat = 300
        let maxWidth: CGFloat = 600
        
        return max(minWidth, min(maxWidth, calculatedWidth))
    }
    
    /// Get theme identifier for caching
    private func getThemeId() -> String {
        switch theme {
        case is MinimalTheme: return "minimal"
        case is PlainLightTheme: return "plainLight"
        case is LightGreenTheme: return "lightGreen"
        case is LightTheme: return "lightBlue"
        case is DarkTheme: return "dark"
        case is DarkBlueTheme: return "darkBlue"
        case is KawaiiTheme: return "kawaii"
        case is SereneTheme: return "serene"
        case is CoffeeTheme: return "coffee"
        default: return "unknown"
        }
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
                                .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0), value: showDeleteIcon)
                                .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0), value: showBothActionsConfirmation)
                            
                            if showBothActionsConfirmation {
                                // Confirmation button - reset gesture state first, then show dialog
                                Button(action: {
                                    // Reset the gesture state first to restore card position
                                    dismissConfirmationsSmooth()
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
                                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0), value: showDeleteIcon)
                            }
                        }
                        .opacity(showBothActionsConfirmation ? 1.0 : abs(dragProgress))
                        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0), value: dragProgress)
                        
                        // Second action (Edit or Mark as Incomplete based on context)
                        ZStack {
                            Circle()
                                .fill(showBothActionsConfirmation ? 
                                    (isInCompletedView ? theme.warning : theme.primary) : 
                                    (isInCompletedView ? theme.warning.opacity(0.3) : theme.primary.opacity(0.3)))
                                .frame(width: showBothActionsConfirmation ? 50 : 40, height: showBothActionsConfirmation ? 50 : 40)
                                .scaleEffect(showBothActionsConfirmation ? 1.0 : (showEditIcon ? 1.0 : 0.85))
                                .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0), value: showEditIcon)
                                .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0), value: showBothActionsConfirmation)
                            
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
                                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0), value: showEditIcon)
                            }
                        }
                        .opacity(showBothActionsConfirmation ? 1.0 : abs(dragProgress))
                        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0), value: dragProgress)
                    }
                    .padding(.trailing, 20)
                }
                .zIndex(1) // Background actions layer - behind the task card
            }
            
            // Main task content
            HStack(spacing: 12) {
                // Ultra-smooth completion toggle optimized for 120fps
                Button(action: {
                    performCompletionToggle()
                }) {
                    ZStack {
                        // Simplified completion icon with minimal state changes
                        Image(systemName: (task.isCompleted || showCheckmark) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor((task.isCompleted || showCheckmark) ? theme.success : theme.textTertiary)
                            .scaleEffect(completionScale)
                            .animation(
                                .spring(response: 0.25, dampingFraction: 0.85),
                                value: completionScale
                            )
                            .matchedGeometryEffect(id: "\(task.id)-completion", in: namespace)
                        
                        // Optimized particle effect with minimal overhead
                        if showCompletionParticles {
                            ForEach(0..<2, id: \.self) { index in  // Ultra-minimal particles
                                Circle()
                                    .fill(theme.success.opacity(0.8))
                                    .frame(width: 2.5, height: 2.5)
                                    .offset(
                                        x: cos(Double(index) * .pi) * 12,
                                        y: sin(Double(index) * .pi) * 12
                                    )
                                    .scaleEffect(showCompletionParticles ? 1 : 0)
                                    .opacity(showCompletionParticles ? 0.7 : 0)
                                    .animation(
                                        UIOptimizer.particleAnimation(),
                                        value: showCompletionParticles
                                    )
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressed ? 0.98 : 1.0, anchor: .center)
                .animation(.spring(response: 0.1), value: isPressed)
                
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
                                .animation(.none, value: task.isCompleted)  // Eliminates wobble
                                .matchedGeometryEffect(id: "\(task.id)-title", in: namespace)
                                .frame(maxWidth: optimizedTaskTitleWidth, alignment: .leading)
                        }

                        // Task description with fade animation
                        if !task.description.isEmpty {
                            Text(task.description)
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                                .lineLimit(2)
                                .opacity(task.isCompleted ? 0.5 : 0.8)
                                .scaleEffect(task.isCompleted ? 0.99 : 1.0, anchor: .leading)
                                .animation(.none, value: task.isCompleted)  // Eliminates wobble
                                .matchedGeometryEffect(id: "\(task.id)-description", in: namespace)

                        }
                        
                        // Detailed checklist view
                        if !task.checklist.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                // Checklist header with integrated progress pill
                                ChecklistProgressHeader(checklist: task.checklist)
                                    .animation(.none, value: task.checklist.map { $0.isCompleted })  // Eliminates wobble
                                
                                // Individual checklist items
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(task.checklist) { item in
                                        HStack(spacing: 8) {
                                            // Ultra-stable checklist toggle - no wobble
                                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(item.isCompleted ? theme.success : theme.textTertiary)
                                                .contentShape(Circle())
                                                .frame(width: 24, height: 24)
                                                .animation(.none, value: item.isCompleted)  // Eliminates wobble
                                                .onTapGesture {
                                                    // Immediate haptic feedback and optimized toggle
                                                    HapticManager.shared.buttonTap()
                                                    optimizedToggleChecklistItem(item)
                                                }
                                            
                                            Text(item.title)
                                                .font(.caption)
                                                .foregroundColor(item.isCompleted ? theme.textSecondary : theme.text)
                                                .strikethrough(item.isCompleted)
                                                .opacity(item.isCompleted ? 0.7 : 1.0)
                                                .animation(.none, value: item.isCompleted)  // Eliminates wobble
                                            
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
            .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 8 : 16)
            .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 0 : 16)
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
                // Ultra-optimized urgent red border - static for maximum performance
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
            )
            .scaleEffect(isPressed ? 0.99 : 1.0)
            .opacity(completionOpacity)
            .overlay(
                // Red tint overlay for urgent tasks - static for maximum performance
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
            )
            .animation(UIOptimizer.optimizedAnimation(duration: 0.15), value: isPressed)

            .offset(x: max(dragOffset, -maxDragDistance)) // Prevent left clipping by limiting negative offset
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0), value: dragOffset)
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0), value: isDragging)
            .optimizedRendering(shouldUpdate: isDragging || task.isCompleted)
            .zIndex(2) // Task card layer - above action buttons
        }
        .clipShape(RoundedRectangle(cornerRadius: 24)) // Ensure clean clipping with rounded corners
        .simultaneousGesture(
                                // Ultra-smooth 120fps gesture handling with minimal CPU overhead
                                DragGesture(minimumDistance: 8, coordinateSpace: .global)
                                    .onChanged { value in
                                        // Throttle gesture updates for 120fps performance
                                        let now = Date()
                                        guard now.timeIntervalSince(lastGestureUpdate) >= gestureUpdateInterval else { return }
                                        lastGestureUpdate = now
                                        
                                        // Enhanced diagonal swipe detection with strict thresholds
                                        let verticalDistance = abs(value.translation.height)
                                        let horizontalDistance = abs(value.translation.width)
                                        let verticalVelocity = abs(value.velocity.height)
                                        let horizontalVelocity = abs(value.velocity.width)
                                        
                                        // Calculate angle in degrees for precise detection
                                        let angleInDegrees = atan2(verticalDistance, horizontalDistance) * 180 / .pi
                                        
                                        // Strict scroll gesture detection - only trigger for clear vertical movement
                                        let isStrictScrollGesture = (
                                            // Angle-based detection: > 35 degrees from horizontal (45 on iPad for better touch tolerance)
                                            angleInDegrees > (UIDevice.current.userInterfaceIdiom == .pad ? 45 : 35) ||
                                            // Distance-based: vertical movement significantly exceeds horizontal (relaxed on iPad)
                                            (verticalDistance > (UIDevice.current.userInterfaceIdiom == .pad ? 40 : 25) && verticalDistance > horizontalDistance * (UIDevice.current.userInterfaceIdiom == .pad ? 1.5 : 1.8)) ||
                                            // Velocity-based: strong vertical velocity with minimal horizontal (relaxed on iPad)
                                            (verticalVelocity > (UIDevice.current.userInterfaceIdiom == .pad ? 600 : 800) && verticalVelocity > horizontalVelocity * (UIDevice.current.userInterfaceIdiom == .pad ? 2.0 : 2.5))
                                        )
                                        
                                        // Enhanced horizontal swipe detection - allow moderate diagonal movement
                                        let isValidHorizontalSwipe = (
                                            // Must have meaningful horizontal movement (increased to 12 on iPad for larger touch areas)
                                            horizontalDistance > (UIDevice.current.userInterfaceIdiom == .pad ? 12 : 8) &&
                                            // Angle must be within 30 degrees of horizontal (40 on iPad for better diagonal tolerance)
                                            angleInDegrees <= (UIDevice.current.userInterfaceIdiom == .pad ? 40 : 30) &&
                                            // Horizontal movement should dominate (relaxed on iPad)
                                            horizontalDistance > verticalDistance * (UIDevice.current.userInterfaceIdiom == .pad ? 0.6 : 0.8) &&
                                            // Not already marked as scroll gesture
                                            !gestureState.isScrollGesture
                                        )
                                        
                                        if isStrictScrollGesture {
                                            gestureState.markAsScrollGesture()
                                            resetToNeutralState()
                                            return
                                        }
                                        
                                        if isValidHorizontalSwipe {
                                            handleDragChanged(value)
                                        }
                                    }
                .onEnded { value in
                    // Enhanced completion detection with strict diagonal filtering
                    let verticalDistance = abs(value.translation.height)
                    let horizontalDistance = abs(value.translation.width)
                    let horizontalVelocity = abs(value.velocity.width)
                    let verticalVelocity = abs(value.velocity.height)
                    
                    // Calculate angle in degrees from horizontal
                    let angleInDegrees = atan2(verticalDistance, horizontalDistance) * 180 / .pi
                    
                    // Strict completion criteria - prevent diagonal swipe completion
                    let isValidSwipeCompletion = (
                        // Must have sufficient horizontal movement (increased on iPad)
                        horizontalDistance > (UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12) &&
                        // Angle must be within 25 degrees of horizontal (35 on iPad)
                        angleInDegrees <= (UIDevice.current.userInterfaceIdiom == .pad ? 35 : 25) &&
                        // Horizontal movement must clearly dominate (relaxed on iPad)
                        horizontalDistance > verticalDistance * (UIDevice.current.userInterfaceIdiom == .pad ? 1.0 : 1.2) &&
                        // Either sufficient distance or velocity (adjusted for iPad)
                        (horizontalDistance > (UIDevice.current.userInterfaceIdiom == .pad ? 60 : 40) || horizontalVelocity > (UIDevice.current.userInterfaceIdiom == .pad ? 500 : 600)) &&
                        // Not marked as scroll gesture
                        !gestureState.isScrollGesture
                    )
                    
                    if isValidSwipeCompletion {
                        handleDragEnded(value)
                    } else {
                        resetToNeutralState()
                    }
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
        .onDisappear {
            // Clean up cached values for memory optimization
            cachedTaskTitleWidth = nil
            lastCalculatedTitle = ""
            lastCalculatedTheme = ""
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
            .environment(\.theme, themeManager.currentTheme)
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
        // Handle dark themes (DarkTheme and DarkBlueTheme) with optimized color selection
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
        
        // Initialize gesture timing and location if this is the first movement
        if gestureState.gestureStartTime == nil {
            gestureState.gestureStartTime = Date()
            gestureState.initialTouchLocation = value.startLocation
        }
        
        // If this is marked as a scroll gesture, don't process further
        if gestureState.isScrollGesture {
            return
        }
        
        // Ultra-fast scroll detection for 120fps performance
        let isScrollGesture = abs(verticalTranslation) > abs(horizontalTranslation) * 0.7
        
        if isScrollGesture {
            gestureState.markAsScrollGesture()
            resetToNeutralState()
            return
        }
        
        // Ultra-responsive swipe detection with minimal calculations
        let isSmoothSwipe = abs(horizontalTranslation) > 6 && !isScrollGesture
        
        if !isSmoothSwipe {
            return
        }
        
        // Update gesture state for performance tracking
        gestureState.velocity = velocity
        gestureState.isActive = true
        
        // If confirmations are showing, handle dismissal gesture
        if showBothActionsConfirmation {
            let dismissThreshold: CGFloat = 20
            if translation > dismissThreshold {
                dismissConfirmationsSmooth()
                return
            }
            return
        }
        
        // Only respond to left swipes (negative translation)
        guard translation < 0 else {
            resetToNeutralState()
            return
        }
        
        // Ultra-fast update filtering for 120fps
        guard abs(translation - gestureState.lastTranslation) > 0.5 else { return }
        
        // Determine initial swipe direction on first movement
        if gestureState.initialDirection == nil && abs(translation) > 8 {
            gestureState.initialDirection = .left
        }
        
        // Trigger gesture start haptic on movement
        if !isDragging && abs(translation) > 8 {
            HapticManager.shared.gestureStart()
            HapticManager.shared.prepareForGestures()
        }
        
        // Optimized icon state management
        if gestureState.hasShownIcon {
            handleIconShownStateSmooth(translation: translation)
            return
        }
        
        // Ultra-smooth 120fps gesture processing with optimized throttling
        UIOptimizer.shared.throttle(key: "leftSwipeUpdate", interval: 0.008) {
            let limitedTranslation = max(-maxDragDistance, translation)
            updateDragStateSmooth(translation: limitedTranslation)
            updateVisualFeedbackSmooth(translation: limitedTranslation)
            handleHapticFeedbackSmooth(translation: limitedTranslation)
        }
        
        // Store last translation for velocity calculations
        gestureState.lastTranslation = translation
    }
    
    // MARK: - Scroll-Aware Gesture Handling System
    
    /// Ultra-optimized gesture reset that immediately defers to parent ScrollView
    /// This method is critical for fixing the scrolling issue where expanded task cards
    /// would prevent vertical scrolling in the parent ScrollView
    
    private func resetToNeutralState() {
        // Ultra-fast reset for 120fps performance
        gestureState.isScrollGesture = false
        gestureState.isActive = false
        
        // Optimized reset animation with minimal duration
        withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
            dragOffset = 0
            isDragging = false
            dragProgress = 0
            showEditIcon = false
            showDeleteIcon = false
            showBothActionsConfirmation = false
            completionOpacity = 1.0
        }
        
        gestureState.reset()
        gestureCompleted = false
        hasTriggeredHaptic = false
    }
    
    private func handleIconShownStateSmooth(translation: CGFloat) {
        let distanceFromNeutral = abs(translation)
        
        // Optimized movement detection with performance-first approach
        if distanceFromNeutral > abs(dragOffset) * 1.05 { // Reduced tolerance for better performance
            // Single unified animation to prevent conflicts
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0)) {
                dragProgress = 0
                showEditIcon = false
                showDeleteIcon = false
            }
            return
        }
        
        // Optimized movement toward neutral with unified timing
        if translation > dragOffset * 0.98 { // Tighter tolerance for smoother interaction
            return
        }
        
        // Single animation block to prevent jitter and improve performance
        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.95, blendDuration: 0)) {
            dragOffset = translation
            isDragging = abs(translation) > 8 // Optimized threshold for better performance
            dragProgress = 0
            showEditIcon = false
            showDeleteIcon = false
        }
    }
    
    private func updateDragStateSmooth(translation: CGFloat) {
        // Ultra-fast state updates for 120fps
        let newIsDragging = abs(translation) > 4
        
        // Batch state updates to reduce re-renders
        if dragOffset != translation || isDragging != newIsDragging {
            dragOffset = translation
            isDragging = newIsDragging
        }
    }
    
    private func updateVisualFeedbackSmooth(translation: CGFloat) {
        // Ultra-fast progress calculation for 120fps
        let newDragProgress = min(1.0, abs(translation) / abs(actionThreshold))
        
        // Minimal threshold for progress updates
        if abs(newDragProgress - dragProgress) > 0.01 {
            dragProgress = newDragProgress
        }
        
        // Fast icon threshold for responsive interaction
        let shouldShowIcons = abs(translation) > 20
        
        // Immediate icon updates with optimized animation
        if shouldShowIcons != showDeleteIcon {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.9)) {
                showDeleteIcon = shouldShowIcons
                showEditIcon = shouldShowIcons
            }
            
            gestureState.hasShownIcon = shouldShowIcons
        }
    }
    
    private func handleHapticFeedbackSmooth(translation: CGFloat) {
        // Ultra-fast haptic feedback for 120fps performance
        if !hasTriggeredHaptic && translation < actionThreshold {
            HapticManager.shared.gestureThreshold()
            hasTriggeredHaptic = true
        }
        
        // Fast reset for continuous interaction
        if abs(translation) < abs(actionThreshold * 0.8) {
            hasTriggeredHaptic = false
        }
    }
    
    private func handleTapGesture() {
        // Dismiss confirmations if tapped elsewhere
        if showBothActionsConfirmation {
            dismissConfirmationsSmooth()
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
        
        // If confirmations are already showing, handle dismissal with ultra-smooth responsiveness
        if showBothActionsConfirmation {
            let dismissThreshold: CGFloat = 15 // Ultra-responsive dismissal
            
            if translation > dismissThreshold {
                dismissConfirmationsSmooth()
            } else {
                // Snap back to confirmation position with ultra-smooth animation
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9, blendDuration: 0)) {
                    dragOffset = -140
                }
            }
            return
        }
        
        // Only respond to left swipes
        guard translation < 0 else {
            HapticManager.shared.gestureCancelled()
            dismissConfirmationsSmooth()
            return
        }
        
        // If user was swiping right after showing icons, always reset with smooth animation
        if gestureState.hasShownIcon && translation > 0 {
            HapticManager.shared.gestureCancelled()
            dismissConfirmationsSmooth()
            return
        }
        
        // Ultra-smooth gesture recognition with responsive thresholds
        let shouldShowBothActionsConfirmation = shouldTriggerConfirmationSmooth(translation: translation, velocity: velocity)
        
        if shouldShowBothActionsConfirmation {
            // Show both actions confirmation with ultra-smooth animation
            HapticManager.shared.gestureThreshold()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9, blendDuration: 0)) {
                showBothActionsConfirmation = true
                dragOffset = -140
            }
        } else {
            // Snap back to original position with cancel haptic and smooth animation
            HapticManager.shared.gestureCancelled()
            dismissConfirmationsSmooth()
        }
    }
    
    private func shouldTriggerConfirmationSmooth(translation: CGFloat, velocity: CGFloat) -> Bool {
        // Ultra-responsive gesture recognition with balanced thresholds
        let distanceThreshold = translation < actionThreshold
        let velocityThreshold = translation < -40 && velocity < -500 // Responsive velocity threshold
        let combinedThreshold = translation < -35 && velocity < -300 // Balanced combined threshold
        
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
        // Execute the mark as incomplete action with optimized performance
        gestureCompleted = true
        HapticManager.shared.buttonTap()
        
        // Immediately clear scroll gesture flags for responsive UI
        gestureState.isScrollGesture = false
        gestureState.isActive = false
        
        // Optimized visual feedback for undo operation
        withAnimation(UIOptimizer.optimizedUndoAnimation()) {
            showCheckmark = false
            completionScale = 1.0
            completionOpacity = 1.0
        }
        
        // Reset gesture state with minimal delay
        resetGestureStateOptimized()
        
        // Immediate completion toggle for responsive undo
        onToggleCompletion()
    }
    
    /// Optimized gesture state reset for undo operations
    private func resetGestureStateOptimized() {
        // Ultra-fast reset animation optimized for undo operations
        withAnimation(UIOptimizer.buttonResponseAnimation()) {
            dragOffset = 0
            isDragging = false
            dragProgress = 0
            showEditIcon = false
            showDeleteIcon = false
            showBothActionsConfirmation = false
            completionOpacity = 1.0
        }
        
        // Immediate state cleanup without delays
        hasTriggeredHaptic = false
        gestureCompleted = false
        gestureState.reset()
        
        // Minimal delay for state synchronization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            gestureState.isScrollGesture = false
            gestureState.isActive = false
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
    
    private func dismissConfirmationsSmooth() {
        HapticManager.shared.gestureCancelled()
        
        // Immediately clear scroll gesture flag to allow scrolling
        gestureState.isScrollGesture = false
        gestureState.isActive = false
        
        // Ultra-smooth dismissal animation with optimized performance
        withAnimation(.spring(response: 0.2, dampingFraction: 0.98, blendDuration: 0)) {
            dragOffset = 0
            isDragging = false
            dragProgress = 0
            showEditIcon = false
            showDeleteIcon = false
            showBothActionsConfirmation = false
            completionOpacity = 1.0
        }
        
        // Reset state with optimized cleanup
        gestureState.reset()
        gestureCompleted = false
        hasTriggeredHaptic = false
        
        // Notify parent that deletion was canceled
        onDeleteCanceled?()
    }
    
    private func performCompletionToggle() {
        // Ultra-buttery smooth completion toggle optimized for 120fps consistency
        let isCompleting = !task.isCompleted
        
        // Immediate haptic feedback for responsive feel
        if isCompleting {
            HapticManager.shared.taskCompleted()
        } else {
            HapticManager.shared.taskUncompleted()
        }
        
        // Ultra-buttery smooth completion animation
        withAnimation(UIOptimizer.ultraButteryTaskCompletionAnimation()) {
            if isCompleting {
                completionScale = 1.08
                showCheckmark = true
            } else {
                completionScale = 0.92
                showCheckmark = false
            }
        }
        
        // Particle effect with ultra-buttery smooth timing
        if isCompleting {
            showCompletionParticles = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                showCompletionParticles = false
            }
        } else {
            showCompletionParticles = false
        }
        
        // Immediate task toggle with perfectly coordinated timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            onToggleCompletion()
            
            // URGENT animation handling with ultra-buttery smooth transitions
            if isUrgentTask {
                if isCompleting {
                    stopUrgentPulsatingAnimation()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        startUrgentPulsatingAnimation()
                    }
                }
            }
        }
        
        // Ultra-buttery smooth reset animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(UIOptimizer.ultraButteryTaskRemovalAnimation()) {
                completionScale = 1.0
            }
            gestureCompleted = false
        }
    }
    
    private func resetGestureState() {
        // Ultra-smooth reset animation with unified timing to prevent jitter
        withAnimation(.spring(response: 0.2, dampingFraction: 0.98, blendDuration: 0)) {
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
        gestureState.isScrollGesture = false
        gestureState.isActive = false
    }
    
    private func duplicateTask() {
        taskManager.duplicateTask(task)
    }
    
    /// Starts the ultra-optimized urgent indication with minimal performance impact
    private func startUrgentPulsatingAnimation() {
        // Only animate if task is not completed and is URGENT
        guard isUrgentTask && !task.isCompleted else { return }
        
        // Ultra-lightweight static indication instead of continuous animation
        // This eliminates performance overhead during swipe gestures
        urgentGlowIntensity = 0.8  // Static high visibility
        urgentTintOpacity = 0.3    // Subtle static tint
    }
    
    /// Stops the URGENT indication with instant performance
    private func stopUrgentPulsatingAnimation() {
        // Instant removal without animation to maximize responsiveness
        urgentGlowIntensity = 0.0
        urgentTintOpacity = 0.0
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
        .animation(.none, value: task.isCompleted)  // Eliminates wobble
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
        .animation(.none, value: task.isCompleted)  // Eliminates wobble
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
        // Legacy method - kept for compatibility
        optimizedToggleChecklistItem(item)
    }
    
    private func optimizedToggleChecklistItem(_ item: ChecklistItem) {
        // Ultra-optimized checklist toggle with immediate UI feedback
        PerformanceMonitor.shared.measure("OptimizedChecklistToggle") {
            // Find the checklist item index first for efficiency
            guard let checklistIndex = task.checklist.firstIndex(where: { $0.id == item.id }) else { return }
            
            // Create optimized task copy with minimal overhead
            var updatedTask = task
            updatedTask.checklist[checklistIndex].isCompleted.toggle()
            
            // Immediate UI update through direct task manager call
            taskManager.updateTaskImmediate(updatedTask)
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
            Text("checklist")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Custom progress bar to avoid SwiftUI issues
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.textTertiary.opacity(0.2))
                    .frame(width: 50, height: 5)
                
                Capsule()
                    .fill(theme.progress)
                    .frame(width: 50 * data.progress, height: 5)
                    .animation(.none, value: data.progress)  // Eliminates wobble
            }

            Spacer()
            
            Text("\(data.completed)/\(data.total)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(theme.textSecondary)
                .animation(.none, value: data.completed)  // Eliminates wobble
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