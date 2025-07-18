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
    @State private var shouldUseReducedMotion = UIAccessibility.isReduceMotionEnabled
    
    // Spotlight navigation
    @Binding var selectedTaskId: UUID?
    
    // Quick Actions
    @Binding var quickActionTriggered: SimplrApp.QuickAction?
    @State private var showingAddTask = false
    @State private var showingClearTodayAlert = false
    
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
            case .today: return "house"
            case .upcoming: return "clock"
            case .completed: return "checkmark.seal"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .today: return "house.fill"
            case .upcoming: return "clock.fill"
            case .completed: return "checkmark.seal.fill"
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
            // Static background - no animation for better performance
            backgroundView
            
            VStack(spacing: 0) {
                // Content area with optimized transitions
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom tab bar
                customTabBar
            }
        }
        .onChange(of: selectedTaskId) { _, newTaskId in
            handleSpotlightNavigation(newTaskId)
        }
        .onChange(of: quickActionTriggered) { _, action in
            handleQuickAction(action)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)) { _ in
            shouldUseReducedMotion = UIAccessibility.isReduceMotionEnabled
        }
        .sheet(isPresented: $showingAddTask) {
            NavigationView {
                AddTaskView(taskManager: taskManager)
            }
        }
        .confirmationDialog("Clear All Today's Tasks", isPresented: $showingClearTodayAlert) {
            Button("Clear All Tasks", role: .destructive) {
                withAnimation(optimizedAnimation) {
                    taskManager.clearTodayTasks()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all incomplete tasks for today, including overdue tasks and tasks without due dates. This action cannot be undone.")
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
            selectTab(targetTab)
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
                selectTab(.today)
            }
        }
        
        // Clear the action to prevent repeated handling
        DispatchQueue.main.async {
            quickActionTriggered = nil
        }
    }
    
    private var backgroundView: some View {
        // Use themedBackground to support background images
        Color.clear
            .themedBackground(theme)
    }
    
    // MARK: - Optimized Tab Content Display
    
    private var contentView: some View {
        Group {
            switch selectedTab {
            case .today:
                TodayView(selectedTaskId: $selectedTaskId)
            case .upcoming:
                UpcomingView(selectedTaskId: $selectedTaskId)
            case .completed:
                CompletedView(selectedTaskId: $selectedTaskId)
            }
        }
        .transition(optimizedTransition)
        .animation(optimizedAnimation, value: selectedTab)
    }
    

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                optimizedTabButton(for: tab)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(
                    themeManager.themeMode == .kawaii ?
                    Color(red: 243/255, green: 236/255, blue: 230/255) :
                    (themeManager.isDarkMode ?
                     Color.black :
                     (themeManager.themeMode == .lightBlue ? Color(red: 245/255, green: 249/255, blue: 255/255) :
                      Color(red: 250/255, green: 250/255, blue: 250/255)))
                )
                .ignoresSafeArea(.container, edges: .bottom)
        )
    }
    

    
    private func selectTab(_ tab: Tab) {
        guard selectedTab != tab else { return }
        
        // Minimal haptic feedback
        HapticManager.shared.selectionChanged()
        
        // Direct tab switch with optimized animation
        withAnimation(optimizedAnimation) {
            selectedTab = tab
        }
    }
    
    // MARK: - Performance Optimization Helpers
    
    /// Ultra-optimized animation for maximum performance
    private var optimizedAnimation: Animation {
        if shouldUseReducedMotion {
            return .linear(duration: 0.1)
        }
        
        // Use the fastest, most efficient animation
        return .easeOut(duration: 0.2)
    }
    
    /// Minimal transition for best performance
    private var optimizedTransition: AnyTransition {
        if shouldUseReducedMotion {
            return .identity
        }
        
        // Simple opacity transition - fastest and most efficient
        return .opacity
    }
    
    /// Ultra-optimized tab button for maximum performance
    private func optimizedTabButton(for tab: Tab) -> some View {
        Button {
            selectTab(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .medium))
                    .foregroundColor(
                        selectedTab == tab ? 
                        theme.accent : 
                        (themeManager.themeMode == .kawaii ? theme.textSecondary :
                         (themeManager.isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.5)))
                    )
                
                Text(tab.title)
                    .font(.system(size: 10, weight: selectedTab == tab ? .medium : .regular))
                    .foregroundColor(
                        selectedTab == tab ? 
                        theme.accent : 
                        (themeManager.themeMode == .kawaii ? theme.textSecondary :
                         (themeManager.isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.5)))
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(OptimizedTabButtonStyle(isSelected: selectedTab == tab))
        .if(tab == .today) { view in
            view.contextMenu {
                Button {
                    showingClearTodayAlert = true
                    HapticManager.shared.buttonTap()
                } label: {
                    Label("Clear All Tasks", systemImage: "trash")
                }
            }
        }
    }

}

// MARK: - Optimized Tab Button Style for Maximum Performance
struct OptimizedTabButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}



// MARK: - View Extension for Conditional Modifiers
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
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