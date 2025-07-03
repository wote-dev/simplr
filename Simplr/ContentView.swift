//
//  ContentView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

// MARK: - Themed Image Extension
extension Image {
    init(themedIcon name: String, themeManager: ThemeManager) {
        let isDarkMode: Bool
        switch themeManager.themeMode {
        case .dark:
            isDarkMode = true
        case .light:
            isDarkMode = false
        case .system:
            isDarkMode = themeManager.isDarkMode
        }
        
        self.init(isDarkMode ? "\(name)-dark" : "\(name)-light")
    }
}

struct ContentView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @State private var showingAddTask = false
    @State private var taskToEdit: Task?
    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?
    @State private var showingThemeSelector = false
    @State private var draggedTask: Task?
    @State private var dragOffset: CGSize = .zero
    @State private var isReordering = false
    @Namespace private var taskNamespace
    
    private var isDarkModeActive: Bool {
        switch themeManager.themeMode {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return themeManager.isDarkMode
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
        case overdue = "Overdue"
    }
    
    var filteredTasks: [Task] {
        return taskManager.filteredTasks(
            categoryId: categoryManager.selectedCategoryFilter,
            searchText: searchText,
            filterOption: filterOption
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(theme.surfaceGradient)
                    .frame(width: 120, height: 120)
                    .applyNeumorphicShadow(theme.neumorphicStyle)
                
                Image(systemName: "checklist")
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
            }
            
            VStack(spacing: 12) {
                Text("No Tasks Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.text)
                
                Text("Tap the + button to add your first task")
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
        VStack(spacing: 0) {
            // Category selector
            CategorySelectorView()
                .padding(.vertical, 8)
                .background(theme.background.opacity(0.95))
                .transition(.opacity.combined(with: .move(edge: .top)))
            
            // Task list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredTasks, id: \.id) { task in
                        taskRowWithEffects(task)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .searchable(text: $searchText, prompt: "Search tasks...")
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                removal: .opacity.combined(with: .scale(scale: 0.95))
            ))
        }
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
                    // Haptic feedback when starting to drag
                    HapticManager.shared.dragStart()
                }
                if draggedTask?.id == task.id {
                    dragOffset = value.translation
                }
            }
            .onEnded { value in
                if draggedTask?.id == task.id {
                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                        dragOffset = .zero
                        draggedTask = nil
                        isReordering = false
                    }
                    
                    // Handle reordering logic if needed
                    if abs(value.translation.height) > 60 {
                        reorderTask(task, translation: value.translation.height)
                        // Haptic feedback when task is reordered
                        HapticManager.shared.dragEnd()
                    } else {
                        // Light haptic when drag is cancelled
                        HapticManager.shared.selectionChange()
                    }
                }
            }
    }
    
    private var leadingToolbarItems: some View {
        HStack(spacing: 12) {
            Menu {
                Picker("Filter", selection: $filterOption) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Label(option.rawValue, systemImage: filterIcon(for: option))
                            .tag(option)
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(theme.surfaceGradient)
                        .frame(width: 36, height: 36)
                        .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                    
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(theme.primary)
                        .font(.system(size: 18, weight: .medium))
                        .shadow(
                            color: theme.background == .black ? Color.white.opacity(0.1) : Color.clear,
                            radius: 1,
                            x: 0,
                            y: 0.5
                        )
                        .scaleEffect(isReordering ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isReordering)
                }
            }
            
                    Button {
            HapticManager.shared.buttonTap()
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                showingThemeSelector = true
            }
        } label: {
                ZStack {
                    Circle()
                        .fill(theme.surfaceGradient)
                        .frame(width: 36, height: 36)
                        .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                    
                    Image(systemName: themeManager.themeMode.icon)
                        .foregroundColor(theme.primary)
                        .font(.system(size: 16, weight: .medium))
                        .shadow(
                            color: theme.background == .black ? Color.white.opacity(0.1) : Color.clear,
                            radius: 1,
                            x: 0,
                            y: 0.5
                        )
                }
            }
            .scaleEffect(showingThemeSelector ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: showingThemeSelector)
        }
    }
    
    private var trailingToolbarItem: some View {
        Button {
            HapticManager.shared.buttonTap()
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                showingAddTask = true
            }
        } label: {
            ZStack {
                Circle()
                    .fill(theme.accentGradient)
                    .frame(width: 44, height: 44)
                    .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                
                Image(systemName: "plus")
                    .foregroundColor(theme.background)
                    .font(.system(size: 20, weight: .semibold))
                    .shadow(
                        color: theme.background == .black ? Color.white.opacity(0.3) : Color.black.opacity(0.3),
                        radius: 2,
                        x: 0,
                        y: 1
                    )
                    .rotationEffect(.degrees(showingAddTask ? 45 : 0))
                    .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: showingAddTask)
            }
        }
        .scaleEffect(showingAddTask ? 1.1 : 1.0)
        .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: showingAddTask)
        .primaryActionButton()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                theme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if taskManager.tasks.isEmpty {
                        emptyStateView
                    } else {
                        taskListView
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(themedIcon: "simplr", themeManager: themeManager)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 32)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.3), value: isDarkModeActive)
                        
                        Text("Simplr")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.text)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    leadingToolbarItems
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingToolbarItem
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddEditTaskView(taskManager: taskManager)
                .themedEnvironment(themeManager)
                .environmentObject(themeManager)
                .environmentObject(categoryManager)
        }
        .sheet(item: $taskToEdit) { task in
            AddEditTaskView(taskManager: taskManager, taskToEdit: task)
                .themedEnvironment(themeManager)
                .environmentObject(themeManager)
                .environmentObject(categoryManager)
        }
        .sheet(isPresented: $showingThemeSelector) {
            ThemeSelectorView()
                .themedEnvironment(themeManager)
                .environmentObject(themeManager)
        }
        .onAppear {
            // Check for overdue tasks when view appears
            taskManager.checkForOverdueTasks()
        }
        .confirmationDialog("Delete Task", isPresented: $showingDeleteAlert, presenting: taskToDelete) { task in
            Button("Delete", role: .destructive) {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                    taskManager.deleteTask(task)
                }
            }
            Button("Cancel", role: .cancel) {
                HapticManager.shared.buttonTap()
            }
        } message: { task in
            Text("Are you sure you want to delete '\(task.title)'?")
        }
    }
    
    private func filterIcon(for option: FilterOption) -> String {
        switch option {
        case .all: return "list.bullet"
        case .pending: return "clock"
        case .completed: return "checkmark.circle"
        case .overdue: return "exclamationmark.triangle"
        }
    }
    
    private func reorderTask(_ task: Task, translation: CGFloat) {
        // Simple reordering logic - move task up or down in the list
        guard let currentIndex = taskManager.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let newIndex: Int
        if translation < 0 { // Moving up
            newIndex = max(0, currentIndex - 1)
        } else { // Moving down
            newIndex = min(taskManager.tasks.count - 1, currentIndex + 1)
        }
        
        if newIndex != currentIndex {
            taskManager.moveTask(from: currentIndex, to: newIndex)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environment(\.theme, LightTheme())
}
