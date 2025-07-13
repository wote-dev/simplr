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
    @Namespace private var tabTransition
    
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
            // Animated background
            backgroundView
            
            VStack(spacing: 0) {
                // Content area
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom tab bar
                customTabBar
            }
            
            // Celebration overlay removed
        }


        .onChange(of: selectedTaskId) { _, newTaskId in
            handleSpotlightNavigation(newTaskId)
        }
        .onChange(of: quickActionTriggered) { _, action in
            handleQuickAction(action)
        }
        .sheet(isPresented: $showingAddTask) {
            NavigationView {
                AddTaskView(taskManager: taskManager)
            }
        }
        .confirmationDialog("Clear All Today's Tasks", isPresented: $showingClearTodayAlert) {
            Button("Clear All Tasks", role: .destructive) {
                withAnimation(.smoothSpring) {
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
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
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
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
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
        // Use themedBackground to support background images
        Color.clear
            .themedBackground(theme)
    }
    
    // MARK: - Tab Content Display (Swipe removed)
    
    private var contentView: some View {
        // Display only the selected tab content without swipe gestures
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
        .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: selectedTab)
    }
    

    private var customTabBar: some View {
        // Tab bar content with frosted glass background
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(
            // Solid background colors for each theme
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
    
    private func tabButton(for tab: Tab) -> some View {
        Button {
            selectTab(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .medium, design: .default))
                    .foregroundColor(
                        selectedTab == tab ? 
                        theme.accent : 
                        (themeManager.themeMode == .kawaii ? theme.textSecondary :
                         (themeManager.isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.5)))
                    )
                    .scaleEffect(selectedTab == tab ? 1.0 : 0.9)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab == tab)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: selectedTab == tab ? .medium : .regular, design: .default))
                    .foregroundColor(
                        selectedTab == tab ? 
                        theme.accent : 
                        (themeManager.themeMode == .kawaii ? theme.textSecondary :
                         (themeManager.isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.5)))
                    )
                    .opacity(selectedTab == tab ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab == tab)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(ModernTabButtonStyle())
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
    
    private func selectTab(_ tab: Tab) {
        guard selectedTab != tab else { return }
        
        HapticManager.shared.selectionChanged()
        
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
            selectedTab = tab
        }
    }
    

    

}

// MARK: - Modern Tab Button Style
struct ModernTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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