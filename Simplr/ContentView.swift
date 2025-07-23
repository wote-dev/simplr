//
//  ContentView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Themed Image Extension
extension Image {
    init(themedIcon name: String, themeManager: ThemeManager) {
        switch themeManager.themeMode {
        case .kawaii:
            // Use kawaii-specific icon if available, otherwise fall back to light theme
            if name == "simplr" {
                self.init("kawaii-icon")
            } else {
                self.init("\(name)-light")
            }
        case .dark:
            self.init("\(name)-dark")
        case .light:
            self.init("\(name)-light")
        case .lightBlue:
            self.init("\(name)-light") // Use same light icons for light blue theme
        case .lightGreen:
            self.init("\(name)-light") // Use same light icons for light green theme
        case .minimal:
            self.init("\(name)-light") // Use same light icons for minimal theme
        case .serene:
            self.init("\(name)-light") // Use same light icons for serene theme
        case .coffee:
            self.init("\(name)-light") // Use same light icons for coffee theme
        case .system:
            let isDarkMode = themeManager.isDarkMode
            self.init(isDarkMode ? "\(name)-dark" : "\(name)-light")
        }
    }
    
    init(themedBCSLogo themeManager: ThemeManager) {
        switch themeManager.themeMode {
        case .kawaii:
            self.init("bcs-kawaii")
        case .dark:
            self.init("bcs-dark")
        case .light:
            self.init("bcs-light")
        case .lightBlue:
            self.init("bcs-light") // Use same light logo for light blue theme
        case .lightGreen:
            self.init("bcs-light") // Use same light logo for light green theme
        case .minimal:
            self.init("bcs-light") // Use same light logo for minimal theme
        case .serene:
            self.init("bcs-light") // Use same light logo for serene theme
        case .coffee:
            self.init("bcs-light") // Use same light logo for coffee theme
        case .system:
            let isDarkMode = themeManager.isDarkMode
            self.init(isDarkMode ? "bcs-dark" : "bcs-light")
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var premiumManager: PremiumManager
    @Environment(\.theme) var theme
    @State private var showingAddTask = false
    @State private var taskToEdit: Task?
    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?
    @State private var showingThemeSelector = false

    @Namespace private var taskNamespace
    
    // Optimized filtered tasks with memoization and debouncing
    private var filteredTasks: [Task] {
        // Use debounced search for better performance
        let searchQuery = searchText.count < 2 ? "" : searchText
        return taskManager.filteredTasks(
            categoryId: categoryManager.selectedCategoryFilter,
            searchText: searchQuery,
            filterOption: filterOption
        )
    }
    
    /// Returns appropriate icon color for non-selected theme options with proper contrast
    private func getIconColor(for theme: Theme) -> Color {
        if theme is KawaiiTheme {
            // Kawaii theme: use accent color for better visibility against light backgrounds
            return theme.accent
        } else if theme is CoffeeTheme {
            // Coffee theme: use accent color for better contrast against warm background
            return theme.accent
        } else if theme.background == Color.white || 
                  theme.background == Color(red: 0.98, green: 0.98, blue: 0.98) ||
                  theme.background == Color(red: 0.98, green: 0.99, blue: 1.0) ||
                  theme.background == Color(red: 0.98, green: 1.0, blue: 0.99) ||
                  theme.background == Color(red: 0.96, green: 0.94, blue: 0.90) {
            // Light themes (including coffee): use text color for better contrast
            return theme.text
        } else {
            // Dark themes and others: use primary color as before
            return theme.primary
        }
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
                .animation(.easeInOut(duration: 0.2), value: filteredTasks.count) // Optimize list animations
            }
            .searchable(text: $searchText, prompt: "Search tasks...")
            .debounced(searchText, delay: 0.2, key: "search-debounce")
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
                        .foregroundColor(getIconColor(for: theme))
                        .font(.system(size: 18, weight: .medium))
                        .shadow(
                            color: theme.background == .black ? Color.white.opacity(0.1) : Color.clear,
                            radius: 1,
                            x: 0,
                            y: 0.5
                        )

                }
            }
            
                    ZStack {
                Circle()
                    .fill(theme.surfaceGradient)
                    .frame(width: 36, height: 36)
                    .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                
                Image(systemName: themeManager.themeMode.icon)
                    .foregroundColor(getIconColor(for: theme))
                    .font(.system(size: 16, weight: .medium))
                    .shadow(
                        color: theme.background == .black ? Color.white.opacity(0.1) : Color.clear,
                        radius: 1,
                        x: 0,
                        y: 0.5
                    )
            }
            .scaleEffect(showingThemeSelector ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: showingThemeSelector)
            .contentShape(Circle())
            .highPriorityGesture(
                TapGesture()
                    .onEnded { _ in
                        HapticManager.shared.buttonTap()
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                            showingThemeSelector = true
                        }
                    }
            )
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
                // Background with image support
                Color.clear
                    .themedBackground(theme)
                
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
                            .animation(.easeInOut(duration: 0.3), value: themeManager.themeMode)
                        
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
            NavigationView {
                AddTaskView(taskManager: taskManager)
                    .themedEnvironment(themeManager)
                    .environmentObject(themeManager)
                    .environmentObject(categoryManager)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $taskToEdit) { task in
            NavigationView {
                AddTaskView(taskManager: taskManager, taskToEdit: task)
                    .themedEnvironment(themeManager)
                    .environmentObject(themeManager)
                    .environmentObject(categoryManager)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingThemeSelector) {
            ThemeSelectorView()
                .themedEnvironment(themeManager)
                .environmentObject(themeManager)
                .environmentObject(premiumManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .memoryAware {
            // Clear search text and reset filters on memory warning
            searchText = ""
            categoryManager.clearFilter()
        }
        .onAppear {
            // Check for overdue tasks when view appears
            taskManager.checkForOverdueTasks()
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
    }
    
    private func filterIcon(for option: FilterOption) -> String {
        switch option {
        case .all: return "list.bullet"
        case .pending: return "clock"
        case .completed: return "checkmark.circle"
        case .overdue: return "exclamationmark.triangle"
        }
    }
    

}



#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environment(\.theme, LightTheme())
}
