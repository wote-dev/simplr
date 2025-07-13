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
    @Environment(\.theme) var theme
    @State private var showingAddTask = false
    @State private var taskToEdit: Task?
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?
    @State private var selectedSortOption: SortOption = .dueDate

    @Namespace private var taskNamespace
    
    // Spotlight navigation
    @Binding var selectedTaskId: UUID?
    
    enum SortOption: CaseIterable {
        case priority, dueDate, creationDate, alphabetical
        
        var title: String {
            switch self {
            case .priority: return "Priority"
            case .dueDate: return "Due Date"
            case .creationDate: return "Creation Date"
            case .alphabetical: return "Alphabetical"
            }
        }
        
        var icon: String {
            switch self {
            case .priority: return "exclamationmark.triangle"
            case .dueDate: return "calendar"
            case .creationDate: return "clock"
            case .alphabetical: return "textformat.abc"
            }
        }
    }
    
    private var upcomingTasks: [Task] {
        let calendar = Calendar.current
        let today = Date()
        
        return taskManager.tasks.filter { task in
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
                
            case .creationDate:
                // Sort by creation date (newest first)
                return task1.createdAt > task2.createdAt
                
            case .alphabetical:
                // Sort alphabetically by title
                return task1.title.localizedCaseInsensitiveCompare(task2.title) == .orderedAscending
            }
        }
    }
    
    private var groupedTasks: [(String, [Task])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: upcomingTasks) { task in
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
        .sheet(isPresented: $showingAddTask) {
            NavigationView {
                AddTaskView(taskManager: taskManager)
            }
        }
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
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("Upcoming")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.accentGradient)
                            .tracking(-0.5)
                        
                        // Animated task count badge
                        if upcomingTasks.count > 0 {
                            Text("\(upcomingTasks.count)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(theme.background)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(theme.accentGradient)
                                        .shadow(
                                            color: theme.shadow,
                                            radius: 4,
                                            x: 0,
                                            y: 2
                                        )
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                                .animation(.adaptiveBouncy, value: upcomingTasks.count)
                        }
                    }
                    
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
                    
                    // Enhanced add button
                    Button {
                        withAnimation(.adaptiveBouncy) {
                            showingAddTask = true
                        }
                        HapticManager.shared.buttonTap()
                    } label: {
                        ZStack {
                            // Background
                            Circle()
                                .fill(theme.accentGradient)
                                .frame(width: 50, height: 50)
                                .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                            
                            // Plus icon
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(theme.background)
                                .shadow(
                                    color: theme.background == .black ? Color.white.opacity(0.3) : Color.black.opacity(0.3),
                                    radius: 2,
                                    x: 0,
                                    y: 1
                                )
                        }
                        .scaleEffect(showingAddTask ? 0.95 : 1.0)
                        .animation(.adaptiveSnappy, value: showingAddTask)
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
        .background(
            // Subtle background enhancement
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.background,
                            theme.background.opacity(0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea(edges: .top)
        )
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
                    .scaleEffect(showingAddTask ? 0.95 : 1.0)
                    .animation(.adaptiveBouncy, value: showingAddTask)
            }
            
            // Enhanced text content
            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accentGradient)
                    .tracking(-0.3)
                
                VStack(spacing: 8) {
                    Text("No upcoming tasks scheduled.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(theme.text)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            }
            .opacity(showingAddTask ? 0.6 : 1.0)
            .animation(.adaptiveSmooth, value: showingAddTask)
            

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, -40)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: 20)),
            removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: -20))
        ))
    }
    
    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(groupedTasks, id: \.0) { sectionTitle, tasks in
                    VStack(alignment: .leading, spacing: 16) {
                        // Enhanced section header
                        HStack(alignment: .center, spacing: 12) {
                            // Section title with better typography
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
                                .tracking(-0.2)
                            
                            // Decorative line
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            theme.textSecondary.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)
                            
                            // Enhanced task count badge
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
                                        .shadow(
                                            color: theme.shadow,
                                            radius: 3,
                                            x: 0,
                                            y: 2
                                        )
                                )
                                .transition(.scale.combined(with: .opacity))
                                .animation(.adaptiveBouncy, value: tasks.count)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 4)
                        
                        // Task cards with enhanced spacing
                        LazyVStack(spacing: 10) {
                            ForEach(tasks, id: \.id) { task in
                                taskRowWithEffects(task)
                            }
                        }
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: 10)),
            removal: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: -10))
        ))
    }
    
    private func taskRowWithEffects(_ task: Task) -> some View {
        TaskRowView(
            task: task,
            namespace: taskNamespace,
            onToggleCompletion: {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
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
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(x: 50)),
            removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(x: -50))
        ))
        .matchedGeometryEffect(id: task.id, in: taskNamespace)
    }
}