//
//  TodayView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

struct TodayView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.theme) var theme
    // showingAddTask state is now handled by MainTabView
    @State private var taskToEdit: Task?
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?

    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedSortOption: SortOption = .priority
    @State private var showingSettings = false
    @State private var showEmptyState = false
    @State private var emptyStateAnimationPhase = 0
    @State private var isAnimatingEmptyState = false
    @State private var refreshTrigger = false
    
    // Shared UserDefaults for widget synchronization
    private let sharedUserDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr")
    private let todaySortOptionKey = "TodaySortOption"
    @Namespace private var taskNamespace
    
    // Spotlight navigation
    @Binding var selectedTaskId: UUID?
    
    // Add task state from MainTabView
    @Binding var showingAddTask: Bool
    
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
    
    enum SortOption: String, CaseIterable {
        case priority = "priority"
        case dueDate = "dueDate"
        case creationDateNewest = "creationDateNewest"
        case creationDateOldest = "creationDateOldest"
        case alphabetical = "alphabetical"
        
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
    
    private var todayTasks: [Task] {
        let calendar = Calendar.current
        let today = Date()
        
        let baseTasks = taskManager.tasks.filter { task in
            // Filter by current profile
            guard task.profileId == profileManager.currentProfile.rawValue else { return false }
            
            // Exclude completed tasks from today view - they should only appear in completed section
            guard !task.isCompleted else { return false }
            
            // Check if task has a due date
            if let dueDate = task.dueDate {
                // Include tasks due today or overdue incomplete tasks
                return calendar.isDate(dueDate, inSameDayAs: today) || 
                       (dueDate < today && !task.isCompleted)
            }
            
            // For tasks without due dates, check if they have reminder dates
            if let reminderDate = task.reminderDate {
                // Only include if reminder is today or in the past
                return calendar.isDate(reminderDate, inSameDayAs: today) || reminderDate < today
            }
            
            // Include tasks without due dates or reminder dates (truly undated tasks)
            return true
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
                
            case .dueDate:
                // Sort by due date (earliest first), then by creation date
                if let date1 = task1.dueDate, let date2 = task2.dueDate {
                    return date1 < date2
                } else if task1.dueDate != nil {
                    return true // Tasks with due dates come first
                } else if task2.dueDate != nil {
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
    
    // Get counts for all tasks (not just filtered ones) for the stat cards
    private var allTodayTasks: [Task] {
        let calendar = Calendar.current
        let today = Date()
        
        return taskManager.tasks.filter { task in
            // Filter by current profile
            guard task.profileId == profileManager.currentProfile.rawValue else { return false }
            
            // Exclude completed tasks
            guard !task.isCompleted else { return false }
            
            // Check if task has a due date
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: today) || 
                       (dueDate < today && !task.isCompleted)
            }
            
            // For tasks without due dates, check if they have reminder dates
            if let reminderDate = task.reminderDate {
                // Only include if reminder is today or in the past
                return calendar.isDate(reminderDate, inSameDayAs: today) || reminderDate < today
            }
            
            // Include tasks without due dates or reminder dates (truly undated tasks)
            return true
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
                    
                    if showEmptyState {
                        emptyStateView
                    } else {
                        taskListView
                    }
                }
                .onChange(of: todayTasks.isEmpty) { _, isEmpty in
                    handleEmptyStateTransition(isEmpty: isEmpty)
                }
                
                // Floating action button now handled by MainTabView
            }
            .navigationBarHidden(true)
        }
        .searchable(text: $searchText, prompt: "Search today's tasks...")
        // Add task sheet is now handled by MainTabView
        .sheet(item: $taskToEdit) { task in
            NavigationView {
                AddTaskView(taskManager: taskManager, taskToEdit: task)
            }
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
        .confirmationDialog("Switch Profile", isPresented: $showingProfileSwitcher) {
            ForEach(UserProfile.allCases, id: \.self) { profile in
                Button(role: profile == profileManager.currentProfile ? .cancel : nil) {
                    if profile != profileManager.currentProfile {
                        withAnimation(.smoothSpring) {
                            profileManager.switchToProfile(profile)
                        }
                    }
                } label: {
                    Label(profile.displayName, systemImage: profile.icon)
                }
            }
        } message: {
            Text("Switch between your Personal and Work profiles")
        }
        .onChange(of: selectedTaskId) { _, newTaskId in
            handleSpotlightTaskSelection(newTaskId)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CategoryStateDidRefresh"))) { _ in
            // CRITICAL FIX: Refresh view when category state changes
            // This ensures collapse/expand states remain consistent after task completion changes
            withAnimation(.easeInOut(duration: 0.25)) {
                // Force view refresh by toggling a state variable
                // The animation ensures smooth transitions
                refreshTrigger.toggle()
            }
        }
        .onAppear {
            loadSortOption()
            // Initialize empty state if needed
            if todayTasks.isEmpty {
                handleEmptyStateTransition(isEmpty: true)
            }
        }
        .onChange(of: selectedSortOption) { _, newValue in
            saveSortOption(newValue)
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
    
    @State private var showingProfileSwitcher = false
    
    private var headerView: some View {
        VStack(spacing: 0) {
            // Main header content
            HStack(alignment: .firstTextBaseline, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accentGradient)
                        .tracking(-0.5)
                    
                    // Date subtitle positioned below the Today heading
                    Text(todayDateString)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .opacity(0.8)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .truncationMode(.tail)
                }
                .accessibilityLabel("Today's tasks")
                
                Spacer(minLength: 0)
                
                HStack(spacing: 8) {
                    // Profile selector (if available)
                    if profileManager.shouldShowProfileSwitcher() {
                        Button(action: {
                            showingProfileSwitcher = true
                            HapticManager.shared.selectionChange()
                        }) {
                            Image(systemName: profileManager.currentProfile.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.accent)
                                .frame(width: 44, height: 44)
                        }
                        .animatedButton()
                        .accessibilityLabel("Current profile: \(profileManager.currentProfile.displayName)")
                        .accessibilityHint("Tap to switch between Personal and Work profiles")
                    }
                    
                    // Sort and Filter menu button
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
                        
                        Divider()
                        
                        // Filter Section
                        Section("Filter") {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                Button {
                                    withAnimation(.smoothSpring) {
                                        selectedFilter = filter
                                    }
                                    HapticManager.shared.buttonTap()
                                } label: {
                                    HStack {
                                        Text(filter.title)
                                        Spacer()
                                        if selectedFilter == filter {
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
                    
                    // Settings button with circular background
                    Button {
                        showingSettings = true
                        HapticManager.shared.buttonTap()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(theme.accentGradient)
                                .frame(width: 48, height: 48)
                                .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                            
                            Image(systemName: "gear")
                                .font(.system(size: 22, weight: .medium))
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
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 20)
            
            // Subtle divider for consistency
            if !todayTasks.isEmpty {
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
                    .animation(.adaptiveSmooth.delay(0.1), value: todayTasks.isEmpty)
            }
        }
        // Remove background completely for seamless blending
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // House icon with ultra-smooth animation
            Image(systemName: "house")
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
                .offset(y: emptyStateAnimationPhase >= 1 ? 0 : 25)
                .animation(.ultraSmooth(duration: 0.42), value: emptyStateAnimationPhase)
                .floating(intensity: 1, duration: 4.0) // Ultra-smooth subtle floating
            
            // Text content with ultra-smooth staggered animations
            VStack(spacing: 16) {
                Text("All Clear for Today!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accentGradient)
                    .tracking(-0.3)
                    .scaleEffect(emptyStateAnimationPhase >= 2 ? 1.0 : 0.85)
                    .opacity(emptyStateAnimationPhase >= 2 ? 1.0 : 0.0)
                    .offset(y: emptyStateAnimationPhase >= 2 ? 0 : 15)
                    .animation(.ultraSmooth(duration: 0.38).delay(0.12), value: emptyStateAnimationPhase)
                
                Text("Add your first task to get started")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .scaleEffect(emptyStateAnimationPhase >= 3 ? 1.0 : 0.9)
                    .opacity(emptyStateAnimationPhase >= 3 ? 1.0 : 0.0)
                    .offset(y: emptyStateAnimationPhase >= 3 ? 0 : 10)
                    .animation(.ultraSmooth(duration: 0.35).delay(0.24), value: emptyStateAnimationPhase)
            }
            
            // Add task button with ultra-smooth animation
            Button {
                withAnimation(.smoothSpring) {
                    showingAddTask = true
                }
                HapticManager.shared.buttonTap()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Add Your First Task")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(theme.background)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.accentGradient)
                )
                .scaleEffect(emptyStateAnimationPhase >= 3 ? 1.0 : 0.9)
                .opacity(emptyStateAnimationPhase >= 3 ? 1.0 : 0.0)
                .offset(y: emptyStateAnimationPhase >= 3 ? 0 : 10)
                .animation(.ultraSmooth(duration: 0.35).delay(0.36), value: emptyStateAnimationPhase)
            }
            .animatedButton()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, -50)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.85).combined(with: .opacity).combined(with: .offset(y: 15)),
            removal: .scale(scale: 0.9).combined(with: .opacity).combined(with: .offset(y: -8))
        ))
    }
    
    private var taskListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 16, pinnedViews: []) {
                let groupedTasks = categoryManager.groupTasksByCategory(todayTasks)
                
                ForEach(Array(groupedTasks.indices), id: \.self) { index in
                    let categoryGroup = groupedTasks[index]
                    if !categoryGroup.tasks.isEmpty {
                        VStack(spacing: 8) {
                            // Category section header
                            CategorySectionHeaderView(
                                category: categoryGroup.category,
                                taskCount: categoryGroup.tasks.count
                            )
                            
                            // ENHANCED: Ultra-smooth task card collapse/expand animations
                            let isCollapsed = categoryManager.isCategoryCollapsed(categoryGroup.category)
                            
                            if !isCollapsed {
                                LazyVStack(spacing: 8) {
                                    ForEach(Array(categoryGroup.tasks.enumerated()), id: \.element.id) { index, task in
                                        taskRowWithEffects(task)
                                            .id("task-\(task.id.uuidString)")
                                            .transition(.asymmetric(
                                                insertion: .opacity
                                                    .combined(with: .scale(scale: 0.92, anchor: .top))
                                                    .combined(with: .offset(y: 12)),
                                                removal: .opacity
                                                    .combined(with: .scale(scale: 0.88, anchor: .top))
                                                    .combined(with: .offset(y: -8))
                                            ))
                                    }
                                }
                                .padding(.top, 4)
                                .padding(.bottom, 8)
                                .padding(.horizontal, 8)
                                .clipped() // Optimize rendering performance
                                .animation(.ultraSmooth(duration: 0.35), value: isCollapsed)
                            } else {
                                // PERFORMANCE OPTIMIZATION: Enhanced empty state with smooth collapse
                                Color.clear
                                    .frame(height: 0)
                                    .transition(.opacity.combined(with: .scale(scale: 1.0, anchor: .top)))
                                    .animation(.ultraSmooth(duration: 0.32), value: isCollapsed)
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
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 0.95))
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
    
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    

    
    // Floating action button functionality is now handled by MainTabView
    
    // MARK: - Sort Option Persistence
    
    private func saveSortOption(_ sortOption: SortOption) {
        sharedUserDefaults?.set(sortOption.rawValue, forKey: todaySortOptionKey)
        sharedUserDefaults?.synchronize()
        
        // Trigger widget update to reflect new sort order
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func loadSortOption() {
        guard let sharedUserDefaults = sharedUserDefaults else { return }
        
        if let savedSortOption = sharedUserDefaults.string(forKey: todaySortOptionKey),
           let sortOption = SortOption(rawValue: savedSortOption) {
            selectedSortOption = sortOption
        }
    }
    
    // MARK: - Empty State Animation Management
    
    private func handleEmptyStateTransition(isEmpty: Bool) {
        if isEmpty {
            // Prevent animation overlap
            guard !isAnimatingEmptyState else { return }
            isAnimatingEmptyState = true
            
            // Show empty state container with ultra-smooth fade
            withAnimation(UIOptimizer.optimizedEmptyStateContainerAnimation()) {
                showEmptyState = true
            }
            
            // Reset animation states for clean start
            withAnimation(.none) {
                emptyStateAnimationPhase = 0
            }
            
            // Ultra-smooth staggered animation sequence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(UIOptimizer.optimizedEmptyStateIconAnimation()) {
                    emptyStateAnimationPhase = 1 // House icon
                }
                // Subtle haptic feedback for premium feel
                let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
                impactFeedback.impactOccurred()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                withAnimation(UIOptimizer.optimizedEmptyStateTitleAnimation()) {
                    emptyStateAnimationPhase = 2 // Title text
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(UIOptimizer.optimizedEmptyStateSubtitleAnimation()) {
                    emptyStateAnimationPhase = 3 // Subtitle + button
                }
                isAnimatingEmptyState = false
            }
            
            // Coordinated haptic feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                HapticManager.shared.successFeedback()
            }
        } else {
            // Hide empty state immediately with ultra-smooth transition
            withAnimation(UIOptimizer.optimizedStateTransitionAnimation()) {
                showEmptyState = false
                emptyStateAnimationPhase = 0
            }
            isAnimatingEmptyState = false
        }
    }
}
