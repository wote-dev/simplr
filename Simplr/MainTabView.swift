//
//  MainTabView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.theme) var theme
    @State private var selectedTab: Tab = .today
    @State private var animationPhase: CGFloat = 0
    @Namespace private var tabTransition
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var lastDragValue: CGFloat = 0
    @State private var dragVelocity: CGFloat = 0
    @State private var hasReachedBoundary = false
    @State private var lastBoundaryFeedback: Date = Date()
    @State private var gestureStartTime: Date = Date()
    @State private var dragHistory: [(offset: CGFloat, time: Date)] = []
    
    // Spotlight navigation
    @Binding var selectedTaskId: UUID?
    
    // Quick Actions
    @Binding var quickActionTriggered: SimplrApp.QuickAction?
    @State private var showingAddTask = false
    
    enum Tab: String, CaseIterable {
        case today = "today"
        case upcoming = "upcoming"
        case completed = "completed"
        
        var title: String {
            switch self {
            case .today: return "Today"
            case .upcoming: return "Upcoming"
            case .completed: return "Completed"
            }
        }
        
        var icon: String {
            switch self {
            case .today: return "sun.max"
            case .upcoming: return "calendar"
            case .completed: return "checkmark.circle"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .today: return "sun.max.fill"
            case .upcoming: return "calendar.circle.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
        
        var index: Int {
            switch self {
            case .today: return 0
            case .upcoming: return 1
            case .completed: return 2
            }
        }
        
        static func from(index: Int) -> Tab {
            switch index {
            case 0: return .today
            case 1: return .upcoming
            case 2: return .completed
            default: return .today
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Animated background
            backgroundView
            
            VStack(spacing: 0) {
                // Content area with swipe gesture
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(swipeGesture)
                
                // Custom tab bar
                customTabBar
            }
            
            // Celebration overlay
            CelebrationOverlayView(celebrationManager: CelebrationManager.shared)
        }
        .onAppear {
            startBackgroundAnimation()
        }
        .onChange(of: selectedTaskId) { _, newTaskId in
            handleSpotlightNavigation(newTaskId)
        }
        .onChange(of: quickActionTriggered) { _, action in
            handleQuickAction(action)
        }
        .sheet(isPresented: $showingAddTask) {
            AddEditTaskView(taskManager: taskManager)
        }
    }
    
    // MARK: - Spotlight Navigation
    
    private func handleSpotlightNavigation(_ taskId: UUID?) {
        guard let taskId = taskId,
              let task = taskManager.task(with: taskId) else { return }
        
        // Determine which tab should contain this task
        let targetTab: Tab
        
        if task.isCompleted {
            targetTab = .completed
        } else if task.isPending && task.isDueFuture {
            targetTab = .upcoming
        } else {
            // For today's tasks, overdue tasks, or tasks without due dates
            targetTab = .today
        }
        
        // Navigate to the appropriate tab if not already there
        if selectedTab != targetTab {
            withAnimation(.interpolatingSpring(stiffness: 420, damping: 26)) {
                selectedTab = targetTab
            }
            HapticManager.shared.selectionChanged()
        }
    }
    
    // MARK: - Quick Action Handling
    
    private func handleQuickAction(_ action: SimplrApp.QuickAction?) {
        guard let action = action else { return }
        
        switch action {
        case .addTask:
            // Show add task sheet
            showingAddTask = true
            
        case .viewToday:
            // Navigate to today tab if not already there
            if selectedTab != .today {
                withAnimation(.interpolatingSpring(stiffness: 420, damping: 26)) {
                    selectedTab = .today
                }
                HapticManager.shared.selectionChanged()
            }
        }
        
        // Clear the action to prevent repeated handling
        DispatchQueue.main.async {
            quickActionTriggered = nil
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            // Base background
            theme.backgroundGradient
                .ignoresSafeArea()
            
            // Animated particles for selected tab
            ForEach(0..<6, id: \.self) { index in
                animatedParticle(index: index)
            }
        }
    }
    
    private func animatedParticle(index: Int) -> some View {
        let delay = Double(index) * 0.5
        let duration = 3.0 + Double(index) * 0.3
        
        return Circle()
            .fill(
                RadialGradient(
                    colors: [
                        selectedTab == .today ? theme.warning.opacity(0.1) :
                        selectedTab == .upcoming ? theme.primary.opacity(0.1) :
                        theme.success.opacity(0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 50
                )
            )
            .frame(width: 100, height: 100)
            .offset(
                x: cos(animationPhase + delay) * 150,
                y: sin(animationPhase + delay) * 200
            )
            .opacity(0.6)
            .animation(
                .linear(duration: duration)
                .repeatForever(autoreverses: false),
                value: animationPhase
            )
    }
    
    private var contentView: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                TodayView(selectedTaskId: $selectedTaskId)
                    .frame(width: geometry.size.width)
                    .clipped()
                
                UpcomingView(selectedTaskId: $selectedTaskId)
                    .frame(width: geometry.size.width)
                    .clipped()
                
                CompletedView(selectedTaskId: $selectedTaskId)
                    .frame(width: geometry.size.width)
                    .clipped()
            }
            .scaleEffect(isDragging ? 0.99 : 1.0)
            .offset(x: calculateContentOffset(screenWidth: geometry.size.width))
            .animation(
                isDragging ? 
                    .interactiveSpring(response: 0.25, dampingFraction: 0.9, blendDuration: 0.0) : 
                    .interpolatingSpring(stiffness: 400, damping: 28),
                value: isDragging ? dragOffset : CGFloat(selectedTab.index)
            )
        }
        .clipped()
    }
    
    private func calculateContentOffset(screenWidth: CGFloat) -> CGFloat {
        let baseOffset = -CGFloat(selectedTab.index) * screenWidth
        
        if isDragging {
            // Apply smoother rubber band effect at boundaries
            let normalizedDrag = dragOffset / screenWidth
            let currentIndex = selectedTab.index
            
            // Check if we're trying to drag beyond bounds
            let wouldGoToIndex = currentIndex - Int(normalizedDrag.rounded())
            
            if wouldGoToIndex < 0 {
                // At first tab, trying to go left - apply refined rubber band
                let resistance = max(0, -normalizedDrag - CGFloat(currentIndex))
                let rubberBandOffset = resistance > 0 ? 
                    screenWidth * (resistance / (1 + resistance * 1.5)) : dragOffset
                
                // Provide haptic feedback when hitting boundary
                if resistance > 0.08 && !hasReachedBoundary {
                    provideBoundaryFeedback()
                }
                
                return baseOffset + rubberBandOffset
            } else if wouldGoToIndex >= Tab.allCases.count {
                // At last tab, trying to go right - apply refined rubber band
                let maxIndex = Tab.allCases.count - 1
                let resistance = max(0, -normalizedDrag + CGFloat(maxIndex - currentIndex))
                let rubberBandOffset = resistance > 0 ? 
                    -screenWidth * (resistance / (1 + resistance * 1.5)) : dragOffset
                
                // Provide haptic feedback when hitting boundary
                if resistance > 0.08 && !hasReachedBoundary {
                    provideBoundaryFeedback()
                }
                
                return baseOffset + rubberBandOffset
            } else {
                // Normal dragging within bounds - reset boundary state and apply slight damping
                hasReachedBoundary = false
                return baseOffset + dragOffset * 0.98
            }
        }
        
        return baseOffset
    }
    
    private func provideBoundaryFeedback() {
        let now = Date()
        // Throttle feedback to prevent too many haptics during continuous dragging
        if now.timeIntervalSince(lastBoundaryFeedback) > 0.3 {
            HapticManager.shared.gestureProgress()
            hasReachedBoundary = true
            lastBoundaryFeedback = now
        }
    }
    
    private var customTabBar: some View {
        ZStack {
            // Tab bar background with glassmorphism effect
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.surface.opacity(0.8),
                            theme.surfaceSecondary.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .applyNeumorphicShadow(theme.neumorphicStyle)
                .blur(radius: 0.5)
            
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 80)
        .padding(.horizontal, 20)
        .padding(.bottom, 34) // Account for safe area
    }
    
    private func tabButton(for tab: Tab) -> some View {
        Button {
            selectTab(tab)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Active background
                    if selectedTab == tab {
                        Circle()
                            .fill(theme.accentGradient)
                            .frame(width: 50, height: 50)
                            .matchedGeometryEffect(id: "activeTab", in: tabTransition)
                            .applyNeumorphicShadow(theme.neumorphicPressedStyle)
                    }
                    
                    Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(
                            selectedTab == tab ? theme.background : theme.textSecondary
                        )
                        .shadow(
                            color: selectedTab == tab ? (theme.background == .black ? Color.white.opacity(0.3) : Color.black.opacity(0.3)) : Color.clear,
                            radius: selectedTab == tab ? 2 : 0,
                            x: 0,
                            y: selectedTab == tab ? 1 : 0
                        )
                        .shadow(
                            color: selectedTab != tab ? (theme.background == .black ? Color.white.opacity(0.1) : Color.clear) : Color.clear,
                            radius: selectedTab != tab ? 1 : 0,
                            x: 0,
                            y: selectedTab != tab ? 0.5 : 0
                        )
                        .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                        .animation(.bounceSpring, value: selectedTab == tab)
                }
                .frame(width: 50, height: 50)
                
                Text(tab.title)
                    .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium))
                    .foregroundColor(
                        selectedTab == tab ? theme.text : theme.textSecondary
                    )
                    .shadow(
                        color: theme.background == .black ? Color.white.opacity(0.05) : Color.clear,
                        radius: 0.5,
                        x: 0,
                        y: 0.5
                    )
                    .scaleEffect(selectedTab == tab ? 1.0 : 0.9)
                    .animation(.smoothSpring, value: selectedTab == tab)
            }
        }
        .animatedButton(pressedScale: 0.9)
    }
    
    private func selectTab(_ tab: Tab) {
        guard selectedTab != tab else { return }
        
        HapticManager.shared.selectionChanged()
        
        withAnimation(.interpolatingSpring(stiffness: 420, damping: 26)) {
            selectedTab = tab
        }
    }
    
    private func startBackgroundAnimation() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let currentTime = Date()
                
                if !isDragging {
                    isDragging = true
                    lastDragValue = value.translation.width
                    hasReachedBoundary = false
                    gestureStartTime = currentTime
                    dragHistory = [(offset: value.translation.width, time: currentTime)]
                    HapticManager.shared.prepareForGestures()
                }
                
                // Calculate enhanced velocity using recent drag history
                let currentDrag = value.translation.width
                dragHistory.append((offset: currentDrag, time: currentTime))
                
                // Keep only recent history for more accurate velocity calculation
                dragHistory = dragHistory.filter { currentTime.timeIntervalSince($0.time) < 0.1 }
                
                if dragHistory.count > 1 {
                    let recent = dragHistory.suffix(3)
                    let timeSpan = recent.last!.time.timeIntervalSince(recent.first!.time)
                    let offsetSpan = recent.last!.offset - recent.first!.offset
                    dragVelocity = timeSpan > 0 ? offsetSpan / timeSpan : 0
                } else {
                    dragVelocity = currentDrag - lastDragValue
                }
                
                lastDragValue = currentDrag
                dragOffset = currentDrag
            }
            .onEnded { value in
                let screenWidth = UIScreen.main.bounds.width
                let dragDistance = value.translation.width
                let normalizedDrag = dragDistance / screenWidth
                
                // Enhanced velocity calculation using gesture predictor
                let gestureVelocity = abs(dragVelocity) > 100 ? dragVelocity : 
                    value.predictedEndTranslation.width - value.translation.width
                
                // More refined thresholds for better UX
                let distanceThreshold: CGFloat = 0.2  // 20% of screen width
                let velocityThreshold: CGFloat = 250  // Slightly lower for better responsiveness
                
                isDragging = false
                hasReachedBoundary = false
                dragHistory.removeAll()
                
                withAnimation(.interpolatingSpring(stiffness: 420, damping: 26)) {
                    // Enhanced decision logic considering both distance and velocity
                    let velocityBias = min(abs(gestureVelocity) / 1000, 0.3) // Cap velocity influence
                    let effectiveThreshold = distanceThreshold - velocityBias
                    
                    let shouldChangeTab = abs(normalizedDrag) > effectiveThreshold || 
                                         abs(gestureVelocity) > velocityThreshold
                    
                    if shouldChangeTab {
                        if (normalizedDrag > 0 || gestureVelocity > velocityThreshold) && selectedTab.index > 0 {
                            // Swipe right or high right velocity - go to previous tab
                            navigateToPreviousTab()
                        } else if (normalizedDrag < 0 || gestureVelocity < -velocityThreshold) && 
                                  selectedTab.index < Tab.allCases.count - 1 {
                            // Swipe left or high left velocity - go to next tab
                            navigateToNextTab()
                        } else {
                            // Gesture didn't meet threshold - provide cancel feedback
                            HapticManager.shared.gestureCancelled()
                        }
                    } else {
                        // Gesture didn't meet threshold - provide cancel feedback
                        HapticManager.shared.gestureCancelled()
                    }
                    
                    // Always reset drag offset
                    dragOffset = 0
                }
            }
    }
    
    private func navigateToPreviousTab() {
        let currentIndex = selectedTab.index
        if currentIndex > 0 {
            selectedTab = Tab.from(index: currentIndex - 1)
            HapticManager.shared.selectionChanged()
        }
    }
    
    private func navigateToNextTab() {
        let currentIndex = selectedTab.index
        if currentIndex < Tab.allCases.count - 1 {
            selectedTab = Tab.from(index: currentIndex + 1)
            HapticManager.shared.selectionChanged()
        }
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(selectedTaskId: .constant(nil), quickActionTriggered: .constant(nil))
            .themedEnvironment(ThemeManager())
            .environmentObject(ThemeManager())
            .environmentObject(TaskManager())
    }
} 