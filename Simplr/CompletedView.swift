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
    @Environment(\.theme) var theme
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?
    @State private var taskToEdit: Task?
    @State private var selectedSortOption: SortOption = .creationDate
    @Namespace private var taskNamespace
    
    // Spotlight navigation
    @Binding var selectedTaskId: UUID?
    
    enum SortOption: CaseIterable {
        case priority, dueDate, creationDate, alphabetical
        
        var title: String {
            switch self {
            case .priority: return "Priority"
            case .dueDate: return "Due Date"
            case .creationDate: return "Completion Date"
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
    
    private var completedTasks: [Task] {
        taskManager.tasks.filter { task in
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
                
            case .creationDate:
                // Sort by completion date (most recent first), fallback to created date
                let date1 = task1.completedAt ?? task1.createdAt
                let date2 = task2.completedAt ?? task2.createdAt
                return date1 > date2
                
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
                    
                    if completedTasks.isEmpty {
                        emptyStateView
                    } else {
                        taskListView
                    }
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
            
            // Stats view section
            if !completedTasks.isEmpty {
                VStack(spacing: 0) {
                    CompletionStatsView(completedCount: completedTasks.count, taskManager: taskManager)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    
                    // Subtle divider for consistency
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
                        .animation(.adaptiveSmooth.delay(0.1), value: completedTasks.isEmpty)
                }
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
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(theme.accentGradient)
                .shadow(
                    color: theme.background == .black ? Color.white.opacity(0.15) : Color.black.opacity(0.1),
                    radius: 3,
                    x: 0,
                    y: 2
                )
                .animation(.easeInOut(duration: 0.3), value: completedTasks.isEmpty)
            
            VStack(spacing: 16) {
                Text("No Completed Tasks")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accentGradient)
                    .tracking(-0.3)
                
                Text("Complete some tasks to see them here!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, -50)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
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
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 0.95))
        ))
    }
    
    private func completedTaskRow(_ task: Task) -> some View {
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
            isInCompletedView: true
        )
        .environmentObject(taskManager)
        .padding(.horizontal, 20)
        .opacity(0.8) // Slightly dimmed to show it's completed
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(x: 50)),
            removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(x: -50))
        ))
        .matchedGeometryEffect(id: task.id, in: taskNamespace)
    }
    
    private func clearAllCompleted() {
        let completedTasksToDelete = completedTasks
        
        withAnimation(.smoothSpring) {
            for task in completedTasksToDelete {
                taskManager.deleteTask(task)
            }
        }
        
        HapticManager.shared.successFeedback()
    }
}

struct CompletionStatsView: View {
    let completedCount: Int
    let taskManager: TaskManager
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 16) {
            StatItem(
                title: "Today",
                count: todayCompletedCount,
                icon: "calendar.circle",
                color: theme.success
            )
            
            StatItem(
                title: "This Week",
                count: weekCompletedCount,
                icon: "calendar.badge.clock",
                color: theme.primary
            )
            
            StatItem(
                title: "Total",
                count: completedCount,
                icon: "trophy",
                color: theme.accent
            )
        }
    }
    
    private var todayCompletedCount: Int {
        let calendar = Calendar.current
        let today = Date()
        
        return taskManager.completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: today)
        }.count
    }
    
    private var weekCompletedCount: Int {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: today) ?? today
        
        return taskManager.completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= weekAgo
        }.count
    }
}

struct StatItem: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                    .shadow(
                        color: theme.background == .black ? Color.white.opacity(0.1) : Color.clear,
                        radius: 1,
                        x: 0,
                        y: 0.5
                    )
                
                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.text)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surfaceGradient)
                .applyNeumorphicShadow(theme.neumorphicStyle)
        )
    }
}