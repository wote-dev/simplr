//
//  CompletedView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct CompletedView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.theme) var theme
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?
    @State private var taskToEdit: Task?
    @State private var selectedSortOption: SortOption = .creationDateNewest
    @State private var showEmptyState = false
    @State private var emptyStateAnimationPhase = 0
    @State private var isAnimatingEmptyState = false
    @State private var emptyStateOpacity = 0.0
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
    
    private var completedTasks: [Task] {
        taskManager.tasks.filter { task in
            // Filter by current profile
            guard task.profileId == profileManager.currentProfile.rawValue else { return false }
            
            // Only show completed tasks
            guard task.isCompleted else { return false }
            
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
                
                // Second priority: Sort by completion date (most recent first)
                let date1 = task1.completedAt ?? task1.createdAt
                let date2 = task2.completedAt ?? task2.createdAt
                return date1 > date2
                
            case .dueDate:
                // Sort by original due date (earliest first), then by completion date
                if let date1 = task1.dueDate, let date2 = task2.dueDate {
                    return date1 < date2
                } else if task1.dueDate != nil {
                    return true // Tasks with due dates come first
                } else if task2.dueDate != nil {
                    return false
                } else {
                    // For tasks without due dates, sort by completion date
                    let compDate1 = task1.completedAt ?? task1.createdAt
                    let compDate2 = task2.completedAt ?? task2.createdAt
                    return compDate1 > compDate2
                }
                
            case .creationDateNewest:
                // Sort by completion date (most recent first), fallback to created date
                let date1 = task1.completedAt ?? task1.createdAt
                let date2 = task2.completedAt ?? task2.createdAt
                return date1 > date2
                
            case .creationDateOldest:
                // Sort by completion date (oldest first), fallback to created date
                let date1 = task1.completedAt ?? task1.createdAt
                let date2 = task2.completedAt ?? task2.createdAt
                return date1 < date2
                
            case .alphabetical:
                // Sort alphabetically by title
                return task1.title.localizedCaseInsensitiveCompare(task2.title) == .orderedAscending
            }
        }
    }
    
    private var groupedTasks: [(String, [Task])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: completedTasks) { task in
            let completionDate = task.completedAt ?? task.createdAt
            let today = Date()
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: today)!
            
            if calendar.isDate(completionDate, inSameDayAs: today) {
                return "Today"
            } else if calendar.isDate(completionDate, inSameDayAs: yesterday) {
                return "Yesterday"
            } else if completionDate > weekAgo {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                return formatter.string(from: completionDate)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d"
                return formatter.string(from: completionDate)
            }
        }
        
        return grouped.sorted { first, second in
            let key1 = first.0
            let key2 = second.0
            // Custom sorting logic for section headers
            let priority = ["Today": 0, "Yesterday": 1, "Monday": 2, "Tuesday": 3, "Wednesday": 4, "Thursday": 5, "Friday": 6, "Saturday": 7, "Sunday": 8]
            
            let p1 = priority[key1] ?? 999
            let p2 = priority[key2] ?? 999
            
            if p1 != 999 && p2 != 999 {
                return p1 < p2
            } else if p1 != 999 {
                return true
            } else if p2 != 999 {
                return false
            } else {
                return key1 > key2 // For dates, show more recent first
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
                    
                    // Optimized state transition with performance monitoring
                    Group {
                        if completedTasks.isEmpty {
                            emptyStateView
                        } else {
                            taskListView
                        }
                    }
                    .animation(UIOptimizer.optimizedStateTransitionAnimation(), value: completedTasks.isEmpty)
                }
            }
            .navigationBarHidden(true)
        }
        .searchable(text: $searchText, prompt: "Search completed tasks...")
        .sheet(item: $taskToEdit) { task in
            AddTaskView(taskManager: taskManager, taskToEdit: task)
        }
        .confirmationDialog("Delete Task", isPresented: $showingDeleteAlert, presenting: taskToDelete) { task in
            Button("Delete", role: .destructive) {
                // Optimized deletion with empty state awareness
                let willBeEmpty = completedTasks.count == 1
                
                if willBeEmpty {
                    // Special handling for last task deletion - smooth empty state transition
                    withAnimation(UIOptimizer.optimizedStateTransitionAnimation()) {
                        taskManager.deleteTask(task)
                    }
                    
                    // Ensure smooth empty state appearance
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(UIOptimizer.optimizedEmptyStateContainerAnimation()) {
                            // Trigger empty state animation refresh
                        }
                    }
                } else {
                    // Standard deletion animation for multiple tasks
                    withAnimation(UIOptimizer.optimizedUndoAnimation()) {
                        taskManager.deleteTask(task)
                    }
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
        .onChange(of: completedTasks.isEmpty) { _, isEmpty in
            handleEmptyStateTransition(isEmpty: isEmpty)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Ultra-smooth empty state animation trigger with coordinated timing
    private func triggerUltraSmoothEmptyStateAnimation() {
        guard !isAnimatingEmptyState else { return }
        
        isAnimatingEmptyState = true
        
        // Reset animation states
        withAnimation(.none) {
            emptyStateAnimationPhase = 0
            emptyStateOpacity = 0.0
        }
        
        // Fade in container first
        withAnimation(UIOptimizer.optimizedEmptyStateContainerAnimation()) {
            emptyStateOpacity = 1.0
        }
        
        // Coordinated staggered animation sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(UIOptimizer.optimizedEmptyStateIconAnimation()) {
                emptyStateAnimationPhase = 1
            }
            // Subtle haptic feedback for premium feel
            let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
            impactFeedback.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(UIOptimizer.optimizedEmptyStateTitleAnimation()) {
                emptyStateAnimationPhase = 2
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(UIOptimizer.optimizedEmptyStateSubtitleAnimation()) {
                emptyStateAnimationPhase = 3
            }
            isAnimatingEmptyState = false
        }
    }
    
    /// Handles the transition animation when empty state appears or disappears
    private func handleEmptyStateTransition(isEmpty: Bool) {
        if isEmpty {
            // Show empty state with ultra-smooth animation
            withAnimation(UIOptimizer.optimizedEmptyStateContainerAnimation()) {
                showEmptyState = true
            }
            
            // Trigger enhanced animation sequence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                triggerUltraSmoothEmptyStateAnimation()
            }
        } else {
            // Hide empty state with smooth fade out
            withAnimation(UIOptimizer.optimizedEmptyStateContainerAnimation().speed(1.5)) {
                showEmptyState = false
                emptyStateAnimationPhase = 0
                emptyStateOpacity = 0.0
            }
            isAnimatingEmptyState = false
        }
    }
    
    // MARK: - Spotlight Navigation
    
    private func handleSpotlightTaskSelection(_ taskId: UUID?) {
        guard let taskId = taskId,
              let task = taskManager.task(with: taskId) else {
            return
        }
        
        // Check if this task belongs in completed view
        let belongsInCompletedView = completedTasks.contains { $0.id == taskId }
        
        if belongsInCompletedView {
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
                    // Title with consistent typography
                    Text("Completed")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accentGradient)
                        .tracking(-0.5)
                    
                    // Subtitle with consistent hierarchy
                    Text(completedTasks.isEmpty ? "No completed tasks" : "\(completedTasks.count) tasks completed")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .opacity(0.8)
                        .animation(.adaptiveSmooth, value: completedTasks.isEmpty)
                }
                
                Spacer(minLength: 0)
                
                HStack(spacing: 12) {
                    // Sort Menu with consistent styling
                    Menu {
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
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.accent)
                            .frame(width: 44, height: 44)
                    }
                    .animatedButton()
                    
                    // Clear all button with consistent styling
                    if !completedTasks.isEmpty {
                        Button {
                            clearAllCompleted()
                            HapticManager.shared.buttonTap()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.error)
                                .frame(width: 44, height: 44)
                        }
                        .animatedButton()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 20)
            

        }
        // Remove background completely for seamless blending
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Icon with ultra-smooth fluid animation
            Image(systemName: "checkmark.seal")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(theme.accentGradient)
                .shadow(
                    color: theme.background == .black ? Color.white.opacity(0.15) : Color.black.opacity(0.1),
                    radius: 3,
                    x: 0,
                    y: 2
                )
                .scaleEffect(emptyStateAnimationPhase >= 1 ? 1.0 : 0.6)
                .opacity(emptyStateAnimationPhase >= 1 ? 1.0 : 0.0)
                .offset(y: emptyStateAnimationPhase >= 1 ? 0 : 12)
                .animation(UIOptimizer.optimizedEmptyStateIconAnimation(), value: emptyStateAnimationPhase)
                .floating(intensity: 1.5, duration: 5.0)
            
            VStack(spacing: 16) {
                Text("No Completed Tasks")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accentGradient)
                    .tracking(-0.3)
                    .scaleEffect(emptyStateAnimationPhase >= 2 ? 1.0 : 0.85)
                    .opacity(emptyStateAnimationPhase >= 2 ? 1.0 : 0.0)
                    .offset(y: emptyStateAnimationPhase >= 2 ? 0 : 8)
                    .animation(UIOptimizer.optimizedEmptyStateTitleAnimation(), value: emptyStateAnimationPhase)
                
                Text("Complete some tasks to see them here!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(theme.text.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .scaleEffect(emptyStateAnimationPhase >= 3 ? 1.0 : 0.9)
                    .opacity(emptyStateAnimationPhase >= 3 ? 1.0 : 0.0)
                    .offset(y: emptyStateAnimationPhase >= 3 ? 0 : 6)
                    .animation(UIOptimizer.optimizedEmptyStateSubtitleAnimation(), value: emptyStateAnimationPhase)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, -50)
        .opacity(emptyStateOpacity)
        .animation(.easeInOut(duration: 0.15), value: emptyStateOpacity)
        .transition(UIOptimizer.optimizedEmptyStateTransition())
        .onAppear {
            triggerUltraSmoothEmptyStateAnimation()
        }
    }
    
    private var taskListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20, pinnedViews: []) {
                ForEach(groupedTasks, id: \.0) { sectionTitle, tasks in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(sectionTitle)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            theme.text,
                                            theme.text.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .tracking(-0.2)
                            
                            Spacer()
                            
                            Text("\(tasks.count)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(theme.background)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    theme.accent,
                                                    theme.accent.opacity(0.8)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(tasks, id: \.id) { task in
                                completedTaskRow(task)
                                    .id("task-\(task.id.uuidString)")
                            }
                        }
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
        .transition(UIOptimizer.optimizedTaskListTransition())
        .animation(UIOptimizer.optimizedTaskListAnimation(), value: !completedTasks.isEmpty)
    }
    
    private func completedTaskRow(_ task: Task) -> some View {
        TaskRowView(
            task: task,
            namespace: taskNamespace,
            onToggleCompletion: {
                // Optimized animation for undo operation with state transition awareness
                let willBeEmpty = completedTasks.count == 1
                
                if willBeEmpty {
                    // Special handling when this will be the last task - smooth empty state transition
                    withAnimation(UIOptimizer.ultraButteryTaskCompletionAnimation()) {
                        taskManager.toggleTaskCompletion(task)
                    }
                    
                    // Ensure empty state appears smoothly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(UIOptimizer.optimizedEmptyStateContainerAnimation()) {
                            // Trigger empty state refresh
                        }
                    }
                } else {
                    // Standard undo animation for multiple tasks
                    withAnimation(UIOptimizer.ultraButteryTaskCompletionAnimation()) {
                        taskManager.toggleTaskCompletion(task)
                    }
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
            isInCompletedView: true
        )
        .environmentObject(taskManager)
        .padding(.horizontal, 20)
        .opacity(0.8) // Slightly dimmed to show it's completed
        .transition(.ultraButteryTaskCompletionTransition)
        .matchedGeometryEffect(id: task.id, in: taskNamespace)
    }
    
    /// Ultra-optimized transition for completed task removal with maximum responsiveness
    private func optimizedTaskTransition() -> AnyTransition {
        let insertion = AnyTransition.opacity.combined(with: .scale(scale: 0.96))
        let removal = AnyTransition.opacity.combined(with: .scale(scale: PerformanceConfig.Animation.undoTransitionScale))
            .animation(UIOptimizer.optimizedUndoAnimation())
        return .asymmetric(insertion: insertion, removal: removal)
    }
    
    private func clearAllCompleted() {
        let completedTasksToDelete = completedTasks
        
        // Use ultra-buttery smooth animation for seamless transition to empty state
        withAnimation(UIOptimizer.ultraButteryTaskRemovalAnimation()) {
            for task in completedTasksToDelete {
                taskManager.deleteTask(task)
            }
        }
        
        // Provide premium haptic feedback for user confirmation
        HapticManager.shared.successFeedback()
        
        // Ensure ultra-buttery smooth empty state appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            triggerUltraSmoothEmptyStateAnimation()
        }
    }
}