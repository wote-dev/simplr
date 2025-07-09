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
            withAnimation(.adaptiveSmooth) {
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
                withAnimation(.adaptiveSmooth) {
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
        // Simplified background for better performance
        theme.backgroundGradient
            .ignoresSafeArea()
    }
    
    private var contentView: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTaskId: $selectedTaskId)
                .tag(Tab.today)
            
            UpcomingView(selectedTaskId: $selectedTaskId)
                .tag(Tab.upcoming)
            
            CompletedView(selectedTaskId: $selectedTaskId)
                .tag(Tab.completed)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.adaptiveSmooth, value: selectedTab)
    }
    

    private var customTabBar: some View {
        ZStack {
            // Simplified tab bar background for better performance
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 10,
                    x: 0,
                    y: 5
                )
            
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 84)
        .padding(.horizontal, 16)
        .padding(.bottom, 34) // Account for safe area
    }
    
    private func tabButton(for tab: Tab) -> some View {
        Button {
            selectTab(tab)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Simplified active background
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.primary)
                            .frame(width: 56, height: 40)
                            .matchedGeometryEffect(id: "activeTab", in: tabTransition)
                    }
                    
                    Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .medium, design: .rounded))
                        .foregroundColor(selectedTab == tab ? .white : theme.textSecondary)
                        .scaleEffect(selectedTab == tab ? 1.0 : 0.9)
                        .animation(.adaptiveSmooth, value: selectedTab == tab)
                }
                .frame(width: 56, height: 40)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium, design: .rounded))
                    .foregroundColor(selectedTab == tab ? theme.text : theme.textSecondary)
                    .opacity(selectedTab == tab ? 1.0 : 0.8)
                    .scaleEffect(selectedTab == tab ? 1.0 : 0.95)
                    .animation(.adaptiveSmooth, value: selectedTab == tab)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(ModernTabButtonStyle())
    }
    
    private func selectTab(_ tab: Tab) {
        guard selectedTab != tab else { return }
        
        HapticManager.shared.selectionChanged()
        
        withAnimation(.adaptiveSmooth) {
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
            .animation(.adaptiveSnappy, value: configuration.isPressed)
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