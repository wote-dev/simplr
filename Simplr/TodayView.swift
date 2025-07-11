//
//  TodayView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct TodayView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @State private var showingAddTask = false
    @State private var taskToEdit: Task?
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?

    @State private var selectedFilter: TaskFilter = .all
    @State private var showingSettings = false
    @Namespace private var taskNamespace
    
    // Spotlight navigation
    @Binding var selectedTaskId: UUID?
    
    enum TaskFilter: CaseIterable {
        case all, pending, overdue
        
        var title: String {
            switch self {
            case .all: return "All"
            case .pending: return "Pending"
            case .overdue: return "Overdue"
            }
        }
    }
    
    private var todayTasks: [Task] {
        let calendar = Calendar.current
        let today = Date()
        
        let baseTasks = taskManager.tasks.filter { task in
            // Exclude completed tasks from today view - they should only appear in completed section
            guard !task.isCompleted else { return false }
            
            // Include tasks due today, overdue incomplete tasks, and tasks without due dates
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: today) || 
                       (dueDate < today && !task.isCompleted)
            }
            // Also include tasks without due dates that aren't completed
            return !task.isCompleted
        }
        .filter { task in
            // Search filter
            if !searchText.isEmpty {
                return task.title.localizedCaseInsensitiveContains(searchText) ||
                       task.description.localizedCaseInsensitiveContains(searchText)
            }
            return true
        }
        
        // Apply selected filter
        let filteredTasks = baseTasks.filter { task in
            switch selectedFilter {
            case .all:
                return true
            case .pending:
                return !task.isOverdue
            case .overdue:
                return task.isOverdue
            }
        }
        
        return filteredTasks.sorted { task1, task2 in
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
            
            // Third priority: Sort by due date
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            } else if task1.dueDate != nil {
                return true
            } else if task2.dueDate != nil {
                return false
            }
            
            // Final priority: Sort by creation date (newest first)
            return task1.createdAt > task2.createdAt
        }
    }
    
    // Get counts for all tasks (not just filtered ones) for the stat cards
    private var allTodayTasks: [Task] {
        let calendar = Calendar.current
        let today = Date()
        
        return taskManager.tasks.filter { task in
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: today) || 
                       (dueDate < today && !task.isCompleted)
            }
            return !task.isCompleted
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
                    
                    if todayTasks.isEmpty {
                        emptyStateView
                    } else {
                        taskListView
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .searchable(text: $searchText, prompt: "Search today's tasks...")
        .sheet(isPresented: $showingAddTask) {
            AddEditTaskView(taskManager: taskManager)
        }
        .sheet(item: $taskToEdit) { task in
            AddEditTaskView(taskManager: taskManager, taskToEdit: task)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(themeManager)
        }
        .confirmationDialog("Delete Task", isPresented: $showingDeleteAlert, presenting: taskToDelete) { task in
            Button("Delete", role: .destructive) {
                // Trigger the deletion animation and then delete the task
                withAnimation(.smoothSpring) {
                    taskManager.deleteTask(task)
                }
                // Clear the taskToDelete after deletion
                taskToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                // Clear the taskToDelete when canceling to prevent UI issues
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
        
        // Check if this task belongs in today's view
        let belongsInTodayView = todayTasks.contains { $0.id == taskId }
        
        if belongsInTodayView {
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("Today")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.accentGradient)
                        
                        if !allTodayTasks.isEmpty {
                             Text("\(allTodayTasks.count)")
                                 .font(.caption)
                                 .fontWeight(.medium)
                                 .foregroundColor(theme.textSecondary)
                                 .frame(width: 20, height: 20)
                                 .background(
                                     Circle()
                                         .fill(theme.textSecondary.opacity(0.15))
                                 )
                                 .transition(.scale.combined(with: .opacity))
                         }
                    }
                    
                    Text(todayDateString)
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        showingSettings = true
                        HapticManager.shared.buttonTap()
                    } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.accent)
                            .frame(width: 44, height: 44)
                    }
                    .animatedButton()
                    
                    Button {
                        showingAddTask = true
                        HapticManager.shared.buttonTap()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(theme.accentGradient)
                                .frame(width: 50, height: 50)
                                .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                            
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
                    }
                    .animatedButton()
                }
            }
            
            if !allTodayTasks.isEmpty {
                HStack(spacing: 16) {
                    TaskStatCard(
                        title: "Pending",
                        count: allTodayTasks.filter { !$0.isCompleted && !$0.isOverdue }.count,
                        color: theme.warning,
                        icon: "clock",
                        isSelected: selectedFilter == .pending,
                        onTap: {
                            withAnimation(.smoothSpring) {
                                selectedFilter = selectedFilter == .pending ? .all : .pending
                            }
                            HapticManager.shared.buttonTap()
                        }
                    )
                    
                    TaskStatCard(
                        title: "Overdue",
                        count: allTodayTasks.filter { $0.isOverdue }.count,
                        color: theme.error,
                        icon: "exclamationmark.triangle",
                        isSelected: selectedFilter == .overdue,
                        onTap: {
                            withAnimation(.smoothSpring) {
                                selectedFilter = selectedFilter == .overdue ? .all : .overdue
                            }
                            HapticManager.shared.buttonTap()
                        }
                    )
                    
                    TaskStatCard(
                        title: "Completed",
                        count: allTodayTasks.filter { $0.isCompleted }.count,
                        color: theme.success,
                        icon: "checkmark.circle",
                        isSelected: false,
                        onTap: {
                            // Completed tasks don't filter in today view - they're in completed section
                        }
                    )
                }
                .transition(.scaleAndSlide)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "house")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(theme.accentGradient)
                .shadow(
                    color: theme.background == .black ? Color.white.opacity(0.15) : Color.black.opacity(0.1),
                    radius: 3,
                    x: 0,
                    y: 2
                )
                .scaleEffect(showingAddTask ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: showingAddTask)
            
            VStack(spacing: 12) {
                Text("All Clear for Today!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.text)
                
                Text("No tasks due today. Enjoy your free time!")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(showingAddTask ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: showingAddTask)
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
            LazyVStack(spacing: 12) {
                ForEach(todayTasks, id: \.id) { task in
                    taskRowWithEffects(task)
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
            }
        )
        .environmentObject(taskManager)
        .padding(.horizontal, 20)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(x: 50)),
            removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(x: -50))
        ))
        .matchedGeometryEffect(id: task.id, in: taskNamespace)

    }
    

    
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

struct TaskStatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? theme.background : color)
                        .shadow(
                            color: theme.background == .black ? Color.white.opacity(0.1) : Color.clear,
                            radius: 1,
                            x: 0,
                            y: 0.5
                        )
                    
                    Text("\(count)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? theme.background : theme.text)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? theme.background.opacity(0.8) : theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : Color.clear)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.surfaceGradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                theme.accent.opacity(0.3),
                                                theme.accent.opacity(0.2)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 0
                                    )
                            )
                    )
                    .applyNeumorphicShadow(isSelected ? theme.neumorphicButtonStyle : theme.neumorphicStyle)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.smoothSpring, value: isSelected)
        }
        .animatedButton()
    }
}