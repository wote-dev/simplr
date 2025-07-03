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
    @State private var draggedTask: Task?
    @State private var dragOffset: CGSize = .zero
    @State private var isReordering = false
    @Namespace private var taskNamespace
    
    private var upcomingTasks: [Task] {
        return taskManager.tasks.filter { task in
            // Include only truly pending tasks (future due dates, not completed)
            return task.isPending && task.isDueFuture
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
            // Sort by due date
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            }
            return task1.createdAt > task2.createdAt
        }
    }
    
    private var groupedTasks: [(String, [Task])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: upcomingTasks) { task in
            guard let dueDate = task.dueDate else { return "No Date" }
            
            let today = Date()
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: today)!
            
            if calendar.isDate(dueDate, inSameDayAs: tomorrow) {
                return "Tomorrow"
            } else if dueDate < nextWeek {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                return formatter.string(from: dueDate)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d"
                return formatter.string(from: dueDate)
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
            AddEditTaskView(taskManager: taskManager)
        }
        .sheet(item: $taskToEdit) { task in
            AddEditTaskView(taskManager: taskManager, taskToEdit: task)
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert, presenting: taskToDelete) { task in
            Button("Delete", role: .destructive) {
                withAnimation(.smoothSpring) {
                    taskManager.deleteTask(task)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { task in
            Text("Are you sure you want to delete '\(task.title)'?")
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upcoming")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(theme.text)
                    
                    Text("\(upcomingTasks.count) pending tasks")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
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
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar")
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
                Text("No Upcoming Tasks")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.text)
                
                Text("All caught up! Add new tasks to plan ahead.")
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
            LazyVStack(spacing: 20) {
                ForEach(groupedTasks, id: \.0) { sectionTitle, tasks in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(sectionTitle)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.text)
                            
                            Spacer()
                            
                            Text("\(tasks.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(theme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(theme.surfaceSecondary)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(tasks, id: \.id) { task in
                                taskRowWithEffects(task)
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
            }
        )
        .environmentObject(taskManager)
        .padding(.horizontal, 16)
        .zIndex(draggedTask?.id == task.id ? 1 : 0)
        .scaleEffect(draggedTask?.id == task.id ? 1.05 : 1.0)
        .shadow(
            color: draggedTask?.id == task.id ? .black.opacity(0.3) : .clear,
            radius: draggedTask?.id == task.id ? 10 : 0,
            x: 0,
            y: draggedTask?.id == task.id ? 5 : 0
        )
        .offset(draggedTask?.id == task.id ? dragOffset : .zero)
        .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: draggedTask?.id == task.id)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(x: 50)),
            removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(x: -50))
        ))
        .matchedGeometryEffect(id: task.id, in: taskNamespace)
        .gesture(taskDragGesture(for: task))
    }
    
    private func taskDragGesture(for task: Task) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if draggedTask == nil {
                    draggedTask = task
                    isReordering = true
                    HapticManager.shared.dragStart()
                }
                dragOffset = value.translation
            }
            .onEnded { value in
                withAnimation(.smoothSpring) {
                    draggedTask = nil
                    dragOffset = .zero
                    isReordering = false
                }
                HapticManager.shared.dragEnd()
            }
    }
} 