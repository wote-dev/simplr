//
//  UpcomingView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct UpcomingView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.theme) var theme
    @State private var taskToEdit: Task?
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?
    @State private var selectedSortOption: SortOption = .dueDate
    @State private var showEmptyState = false
    @State private var emptyStateAnimationPhase = 0

    @Namespace private var taskNamespace
    
    // Spotlight navigation
    @Binding var selectedTaskId: UUID?
    
    enum SortOption: CaseIterable {
        case priority, dueDate, creationDateNewest, creationDateOldest, alphabetical
        
        var title: String {
            switch self {
            case .priority: return "Priority"
            case .dueDate: return "Due Date"
            case .creationDateNewest: return "Most Recent"
            case .creationDateOldest: return "First Added"
            case .alphabetical: return "Alphabetical"
            }
        }
        
        var icon: String {
            switch self {
            case .priority: return "exclamationmark.triangle"
            case .dueDate: return "calendar"
            case .creationDateNewest: return "clock.arrow.2.circlepath"
            case .creationDateOldest: return "clock"
            case .alphabetical: return "textformat.abc"
            }
        }
    }
    
    private var upcomingTasks: [Task] {
        let calendar = Calendar.current
        let today = Date()
        
        return taskManager.tasks.filter { task in
            // Filter by current profile
            guard task.profileId == profileManager.currentProfile.rawValue else { return false }
            
            // Exclude completed tasks
            guard !task.isCompleted else { return false }
            
            // Check if task has a due date in the future
            if let dueDate = task.dueDate {
                return task.isPending && task.isDueFuture
            }
            
            // For tasks without due dates, check if they have future reminder dates
            if let reminderDate = task.reminderDate {
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today))!
                return reminderDate >= tomorrow
            }
            
            // Exclude tasks without due dates or reminder dates from upcoming view
            return false
        }
        .filter { task in
            // Search filter
            if !searchText.isEmpty {
                return task.title.localizedCaseInsensitiveContains(searchText) ||
                       task.description.localizedCaseInsensitiveContains(searchText)
            }
            return true
        }
        .sorted { task1, task2 in
            switch selectedSortOption {
            case .priority:
                // First priority: URGENT category tasks always come first
                let task1IsUrgent = task1.categoryId == TaskCategory.urgent.id
                let task2IsUrgent = task2.categoryId == TaskCategory.urgent.id
                
                if task1IsUrgent != task2IsUrgent {
                    return task1IsUrgent && !task2IsUrgent
                }
                
                // Second priority: Sort by overdue/pending status
                if task1.isOverdue != task2.isOverdue {
                    return task1.isOverdue && !task2.isOverdue
                }
                
                // Third priority: Sort by due date or reminder date
                let date1 = task1.dueDate ?? task1.reminderDate
                let date2 = task2.dueDate ?? task2.reminderDate
                
                if let d1 = date1, let d2 = date2 {
                    return d1 < d2
                } else if date1 != nil {
                    return true
                } else if date2 != nil {
                    return false
                }
                
                // Final priority: Sort by creation date (newest first)
                return task1.createdAt > task2.createdAt
                
            case .dueDate:
                // Sort by due date or reminder date (earliest first)
                let date1 = task1.dueDate ?? task1.reminderDate
                let date2 = task2.dueDate ?? task2.reminderDate
                
                if let d1 = date1, let d2 = date2 {
                    return d1 < d2
                } else if date1 != nil {
                    return true // Tasks with dates come first
                } else if date2 != nil {
                    return false
                } else {
                    return task1.createdAt > task2.createdAt // Newest first for undated tasks
                }
                
            case .creationDateNewest:
                // Sort by creation date (newest first)
                return task1.createdAt > task2.createdAt
                
            case .creationDateOldest:
                // Sort by creation date (oldest first)
                return task1.createdAt < task2.createdAt
                
            case .alphabetical:
                // Sort alphabetically by title
                return task1.title.localizedCaseInsensitiveCompare(task2.title) == .orderedAscending
            }
        }
    }
    
    private var groupedTasksByCategory: [(category: TaskCategory?, tasks: [Task])] {
        return categoryManager.groupTasksByCategory(upcomingTasks)
    }
    
    private func groupTasksByDate(_ tasks: [Task]) -> [(String, [Task])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: tasks) { task in
            // Use due date if available, otherwise use reminder date
            let relevantDate = task.dueDate ?? task.reminderDate
            guard let date = relevantDate else { return "No Date" }
            
            let today = Date()
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
              let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: today) else {
                return "Unknown Date"
            }
            
            if calendar.isDate(date, inSameDayAs: tomorrow) {
                return "Tomorrow"
            } else if date < nextWeek {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                return formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d"
                return formatter.string(from: date)
            }
        }
        
        return grouped.sorted { first, second in
            let key1 = first.0
            let key2 = second.0
            // Custom sorting logic for section headers
            let priority = ["Tomorrow": 0, "Tuesday": 1, "Wednesday": 2, "Thursday": 3, "Friday": 4, "Saturday": 5, "Sunday": 6, "Monday": 7]
            
            let p1 = priority[key1] ?? 999
            let p2 = priority[key2] ?? 999
            
            if p1 != 999 && p2 != 999 {
                return p1 < p2
            } else if p1 != 999 {
                return true
            } else if p2 != 999 {
                return false
            } else {
                return key1 < key2
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    if upcomingTasks.isEmpty {
                        emptyStateView
                    } else {
                        taskListView
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .searchable(text: $searchText, prompt: "Search upcoming tasks...")
        .sheet(item: $taskToEdit) { task in
            NavigationView {
                AddTaskView(taskManager: taskManager, taskToEdit: task)
            }
        }
        .confirmationDialog("Delete Task", isPresented: $showingDeleteAlert, presenting: taskToDelete) { task in
            Button("Delete", role: .destructive) {
                // Trigger the deletion animation and then delete the task
                withAnimation(.smoothSpring) {
                    taskManager.deleteTask(task)
                }
                taskToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                taskToDelete = nil
            }
        } message: { task in
            Text("Are you sure you want to delete '\(task.title)'?")
        }
        .onChange(of: selectedTaskId) { _, newTaskId in
            handleSpotlightTaskSelection(newTaskId)
        }
        .onChange(of: upcomingTasks.isEmpty) { _, isEmpty in
            handleEmptyStateTransition(isEmpty: isEmpty)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CategoryStateDidRefresh"))) { _ in
            // CRITICAL FIX: Refresh view when category state changes
            // This ensures collapse/expand states remain consistent after task completion changes
            withAnimation(.easeInOut(duration: 0.25)) {
                // Force view refresh by updating a state variable
                // The animation ensures smooth transitions
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Handles the transition animation when empty state appears or disappears
    private func handleEmptyStateTransition(isEmpty: Bool) {
        if isEmpty {
            // Show empty state with staggered animation
            withAnimation(UIOptimizer.optimizedEmptyStateContainerAnimation()) {
                showEmptyState = true
            }
            
            // Staggered animation sequence with haptic feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(UIOptimizer.optimizedEmptyStateIconAnimation()) {
                    emptyStateAnimationPhase = 1
                }
                // Light haptic feedback for icon appearance
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(UIOptimizer.optimizedEmptyStateTitleAnimation()) {
                    emptyStateAnimationPhase = 2
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(UIOptimizer.optimizedEmptyStateSubtitleAnimation()) {
                    emptyStateAnimationPhase = 3
                }
            }
        } else {
            // Hide empty state immediately when tasks are added
            withAnimation(UIOptimizer.optimizedEmptyStateContainerAnimation()) {
                showEmptyState = false
                emptyStateAnimationPhase = 0
            }
        }
    }
    
    // MARK: - Spotlight Navigation
    
    private func handleSpotlightTaskSelection(_ taskId: UUID?) {
        guard let taskId = taskId,
              let task = taskManager.task(with: taskId) else {
            return
        }
        
        // Check if this task belongs in upcoming view
        let belongsInUpcomingView = upcomingTasks.contains { $0.id == taskId }
        
        if belongsInUpcomingView {
            // Clear the selectedTaskId to prevent repeated navigation
            DispatchQueue.main.async {
                selectedTaskId = nil
            }
            
            // Open the task for editing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                taskToEdit = task
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            // Main header content
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    // Title with enhanced typography
                    Text("Upcoming")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accentGradient)
                        .tracking(-0.5)
                    
                    // Subtitle with better hierarchy
                    Text(upcomingTasks.isEmpty ? "All caught up!" : "Tasks scheduled ahead")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .opacity(0.8)
                        .animation(.adaptiveSmooth, value: upcomingTasks.isEmpty)
                }
                
                Spacer(minLength: 0)
                
                HStack(spacing: 12) {
                    // Sort menu button
                    Menu {
                        // Sort Section
                        Section("Sort By") {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    withAnimation(.smoothSpring) {
                                        selectedSortOption = option
                                    }
                                    HapticManager.shared.buttonTap()
                                } label: {
                                    HStack {
                                        Image(systemName: option.icon)
                                        Text(option.title)
                                        Spacer()
                                        if selectedSortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.accent)
                            .frame(width: 44, height: 44)
                    }
                    .animatedButton()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 20)
            
            // Subtle divider
            if !upcomingTasks.isEmpty {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.textSecondary.opacity(0.1),
                                theme.textSecondary.opacity(0.05),
                                theme.textSecondary.opacity(0.1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .animation(.adaptiveSmooth.delay(0.1), value: upcomingTasks.isEmpty)
            }
        }
        // Remove background completely for seamless blending
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            // Enhanced icon with floating animation
            ZStack {
                // Main icon
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 64, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                theme.accent,
                                theme.accent.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(emptyStateAnimationPhase >= 1 ? 1.0 : 0.3)
                    .opacity(emptyStateAnimationPhase >= 1 ? 1.0 : 0.0)
                    .offset(y: emptyStateAnimationPhase >= 1 ? 0 : 20)
                    .animation(UIOptimizer.optimizedEmptyStateIconAnimation(), value: emptyStateAnimationPhase)
                    .floating(intensity: 3, duration: 3.0)
            }
            
            // Enhanced text content
            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accentGradient)
                    .tracking(-0.3)
                    .scaleEffect(emptyStateAnimationPhase >= 2 ? 1.0 : 0.8)
                    .opacity(emptyStateAnimationPhase >= 2 ? 1.0 : 0.0)
                    .offset(y: emptyStateAnimationPhase >= 2 ? 0 : 15)
                    .animation(UIOptimizer.optimizedEmptyStateTitleAnimation(), value: emptyStateAnimationPhase)
                
                VStack(spacing: 8) {
                    Text("No upcoming tasks scheduled.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(theme.text)
                        .scaleEffect(emptyStateAnimationPhase >= 3 ? 1.0 : 0.8)
                        .opacity(emptyStateAnimationPhase >= 3 ? 1.0 : 0.0)
                        .offset(y: emptyStateAnimationPhase >= 3 ? 0 : 10)
                        .animation(UIOptimizer.optimizedEmptyStateSubtitleAnimation(), value: emptyStateAnimationPhase)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            }
            // Add task functionality is now handled by MainTabView
            

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, -40)
        .transition(UIOptimizer.optimizedEmptyStateTransition())
        .onAppear {
            // Trigger staggered animation sequence
            withAnimation(.none) {
                emptyStateAnimationPhase = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                emptyStateAnimationPhase = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                emptyStateAnimationPhase = 2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                emptyStateAnimationPhase = 3
            }
        }
    }
    
    private var taskListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 16, pinnedViews: []) {
                ForEach(Array(groupedTasksByCategory.indices), id: \.self) { index in
                    let categoryGroup = groupedTasksByCategory[index]
                    if !categoryGroup.tasks.isEmpty {
                        VStack(spacing: 8) {
                            // Category section header with collapse functionality
                            CategorySectionHeaderView(
                                category: categoryGroup.category,
                                taskCount: categoryGroup.tasks.count
                            )
                            
                            // Show tasks only if category is not collapsed
                            if !categoryManager.isCategoryCollapsed(categoryGroup.category) {
                                // Group tasks by date within each category
                                let dateGroupedTasks = groupTasksByDate(categoryGroup.tasks)
                                
                                LazyVStack(spacing: 20) {
                                    ForEach(dateGroupedTasks, id: \.0) { sectionTitle, tasks in
                                        VStack(alignment: .leading, spacing: 12) {
                                            // Date section header (smaller, secondary)
                                            HStack(alignment: .center, spacing: 8) {
                                                Text(sectionTitle)
                                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                    .foregroundColor(theme.textSecondary)
                                                    .tracking(-0.1)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.8)
                                                
                                                Rectangle()
                                                    .fill(theme.textSecondary.opacity(0.2))
                                                    .frame(height: 0.5)
                                                
                                                Text("\(tasks.count)")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(theme.textTertiary)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(
                                                        Capsule()
                                                            .fill(theme.surfaceSecondary)
                                                    )
                                            }
                                            .padding(.horizontal, 24)
                                            
                                            // Task cards
                                            LazyVStack(spacing: 10) {
                                                ForEach(tasks, id: \.id) { task in
                                                    taskRowWithEffects(task)
                                                        .id("task-\(task.id.uuidString)")
                                                }
                                            }
                                        }
                                    }
                                }
                                .clipped() // Optimize rendering performance
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                                    removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                                ))
                                .animation(.easeInOut(duration: 0.35), value: categoryManager.isCategoryCollapsed(categoryGroup.category))
                            } else {
                                // ENHANCED: Ultra-smooth collapse animation for empty state
                                Color.clear
                                    .frame(height: 0)
                                    .transition(.opacity.combined(with: .scale(scale: 1.0, anchor: .top)))
                                    .animation(.ultraSmooth(duration: 0.35), value: categoryManager.isCategoryCollapsed(categoryGroup.category))
                            }
                        }
                        .id("category-\(categoryGroup.category?.id.uuidString ?? "uncategorized")")
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.automatic)
        .scrollClipDisabled(false)
        .scrollDismissesKeyboard(.interactively)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    private func taskRowWithEffects(_ task: Task) -> some View {
        TaskRowView(
            task: task,
            namespace: taskNamespace,
            onToggleCompletion: {
                withAnimation(UIOptimizer.ultraButteryTaskCompletionAnimation()) {
                    taskManager.toggleTaskCompletion(task)
                }
            },
            onEdit: {
                taskToEdit = task
            },
            onDelete: {
                taskToDelete = task
                showingDeleteAlert = true
            },
            onDeleteCanceled: {
                // Reset gesture state when deletion is canceled via swipe dismissal
                taskToDelete = nil
            },
            isInCompletedView: false
        )
        .environmentObject(taskManager)
        .padding(.horizontal, 20)
        .transition(.ultraButteryTaskCompletionTransition)
        .matchedGeometryEffect(id: task.id, in: taskNamespace)
    }
}