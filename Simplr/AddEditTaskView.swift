//
//  AddEditTaskView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import Combine

struct AddEditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var categoryManager: CategoryManager
    @ObservedObject var taskManager: TaskManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var hasReminder = false
    @State private var reminderDate = Date()
    @State private var showReminderScheduler = false
    @State private var selectedCategory: TaskCategory? = nil
    @State private var suggestedCategory: TaskCategory? = nil
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    @State private var showSuccessAnimation = false
    @State private var formScale: CGFloat = 1.0
    @State private var selectedReminderOption: String? = nil
    @State private var formOpacity: Double = 1.0
    @State private var savingTask = false
    @State private var quickListItems: [QuickListItem] = []
    @Namespace private var formNamespace
    @State private var isKeyboardVisible = false
    @State private var quickListFocused = false
    
    let taskToEdit: Task?
    
    init(taskManager: TaskManager, taskToEdit: Task? = nil) {
        self.taskManager = taskManager
        self.taskToEdit = taskToEdit
        
        if let task = taskToEdit {
            _title = State(initialValue: task.title)
            _description = State(initialValue: task.description)
            _hasDueDate = State(initialValue: task.dueDate != nil)
            _dueDate = State(initialValue: task.dueDate ?? Date())
            _hasReminder = State(initialValue: task.hasReminder)
            _reminderDate = State(initialValue: task.reminderDate ?? Date())
        }
    }
    
    var body: some View {
        mainView
            .onAppear {
                if let task = taskToEdit {
                    title = task.title
                    description = task.description
                    dueDate = task.dueDate ?? Date()
                    hasDueDate = task.dueDate != nil
                    hasReminder = task.hasReminder
                    reminderDate = task.reminderDate ?? Date()
                    selectedCategory = categoryManager.categories.first { $0.id == task.categoryId }
                    quickListItems = task.quickListItems
                    
                    // Set initial selected reminder option for existing tasks
                    if task.hasReminder {
                        selectedReminderOption = determineReminderOption(reminderDate: task.reminderDate ?? Date(), dueDate: task.dueDate)
                    }
                }
                
                withAnimation(.smoothSpring.delay(0.1)) {
                    formOpacity = 1.0
                }
                
                // Auto-focus title field for new tasks
                if taskToEdit == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTitleFocused = true
                    }
                }
                
                // Setup keyboard observers
                setupKeyboardObservers()
            }
            .onDisappear {
                removeKeyboardObservers()
            }
            .onChange(of: title) { _, newTitle in
                // Update category suggestion based on title
                if selectedCategory == nil && !newTitle.isEmpty {
                    suggestedCategory = categoryManager.suggestCategory(for: newTitle)
                } else if newTitle.isEmpty {
                    suggestedCategory = nil
                }
            }
            .onReceive(taskManager.$tasks) { _ in
                // Sync local quickListItems with updated task from TaskManager
                if let taskId = taskToEdit?.id,
                   let updatedTask = taskManager.tasks.first(where: { $0.id == taskId }) {
                    quickListItems = updatedTask.quickListItems
                }
            }
    }
    
    private var mainView: some View {
        NavigationView {
            contentView
                .navigationTitle("")
                .navigationBarHidden(true)
                .toolbar {
                    if !isKeyboardVisible {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                withAnimation(.smoothSpring) {
                                    dismiss()
                                }
                            }
                            .foregroundColor(theme.textSecondary)
                            .animatedButton()
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                saveTask()
                            }
                            .foregroundColor(theme.primary)
                            .fontWeight(.semibold)
                            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                            .scaleEffect(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.0)
                            .animation(.smoothEase, value: title.isEmpty)
                            .animatedButton()
                        }
                    }
                }
                .overlay(isKeyboardVisible ? nil : floatingButtons)
        }
        .onChange(of: hasDueDate) { _, newValue in
            withAnimation(.smoothSpring) {
                if !newValue {
                    hasReminder = false
                }
            }
        }
        .overlay(
            // Success animation overlay
            successAnimationOverlay
        )
        .overlay(
            // Reminder scheduler modal
            ReminderSchedulerView(
                isPresented: $showReminderScheduler,
                reminderDate: $reminderDate,
                hasReminder: $hasReminder,
                dueDate: hasDueDate ? dueDate : nil
            )
        )
    }
    
    private var contentView: some View {
        ZStack {
            // Background gradient
            theme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    formSections
                    Spacer(minLength: 100)
                }
                .scaleEffect(formScale)
                .opacity(formOpacity)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in
                        // Dismiss keyboard when user starts scrolling, but only for non-QuickList fields
                        // QuickListView handles its own focus management
                        if isTitleFocused || isDescriptionFocused {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isTitleFocused = false
                                isDescriptionFocused = false
                            }
                        }
                    }
            )
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(taskToEdit == nil ? "Add New Task" : "Edit Task")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.text)
                .matchedGeometryEffect(id: "header-title", in: formNamespace)
            
            Text(taskToEdit == nil ? "Create a new task to stay organized" : "Update your task details")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .matchedGeometryEffect(id: "header-subtitle", in: formNamespace)
        }
        .padding(.top, 20)
        .transition(.scaleAndSlide)
    }
    
    private var quickListSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Quick List", icon: "list.bullet")
                .matchedGeometryEffect(id: "quicklist-header", in: formNamespace)
            
            QuickListView(
                quickListItems: $quickListItems, 
                taskId: taskToEdit?.id,
                isQuickListFocused: $quickListFocused
            )
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surfaceGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.textTertiary.opacity(0.1), lineWidth: 1)
                    )
                    .applyNeumorphicShadow(theme.neumorphicStyle)
            )
        }
        .transition(.scaleAndSlide)
    }
    
    private var formSections: some View {
        VStack(spacing: 20) {
            taskDetailsSection
            categorySection
            quickListSection
            dueDateSection
            reminderSection
        }
        .padding(.horizontal, 20)
    }
    
    private var taskDetailsSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Task Details", icon: "doc.text")
                .matchedGeometryEffect(id: "details-header", in: formNamespace)
            
            VStack(spacing: 16) {
                // Title field with enhanced focus animations
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.text)
                    
                    TextField("Enter task title", text: $title)
                        .focused($isTitleFocused)
                        .font(.body)
                        .foregroundColor(theme.text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .submitLabel(.next)
                        .onSubmit {
                            // Move focus to description field instead of dismissing keyboard
                            isDescriptionFocused = true
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            isTitleFocused ? theme.accent : theme.textTertiary.opacity(0.2),
                                            lineWidth: isTitleFocused ? 2 : 1
                                        )
                                )
                        )
                        .scaleEffect(isTitleFocused ? 1.01 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: isTitleFocused)
                }
                .transition(.slideInFromTrailing)
                
                // Description field with enhanced focus animations
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.text)
                    
                    TextField("Add details (optional)", text: $description, axis: .vertical)
                        .focused($isDescriptionFocused)
                        .font(.body)
                        .foregroundColor(theme.text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .submitLabel(.done)
                        .onSubmit {
                            // Keep keyboard open by maintaining focus or dismiss if user wants to finish
                            // For multi-line text, return should add new line, so we'll keep focus
                            isDescriptionFocused = true
                        }
                        .lineLimit(3...6)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            isDescriptionFocused ? theme.accent : theme.textTertiary.opacity(0.2),
                                            lineWidth: isDescriptionFocused ? 2 : 1
                                        )
                                )
                        )
                        .scaleEffect(isDescriptionFocused ? 1.01 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: isDescriptionFocused)
                }
                .transition(.slideInFromTrailing)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surfaceGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.textTertiary.opacity(0.1), lineWidth: 1)
                    )
                    .applyNeumorphicShadow(theme.neumorphicStyle)
            )
        }
        .transition(.scaleAndSlide)
    }
    
    private var categorySection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Category", icon: "tag")
                .matchedGeometryEffect(id: "category-header", in: formNamespace)
            
            VStack(spacing: 16) {
                // Category suggestion
                if let suggestedCategory = suggestedCategory, selectedCategory == nil {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Suggested Category")
                                .font(.headline)
                                .foregroundColor(theme.text)
                            
                            Text("Based on your task title")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = suggestedCategory
                                HapticManager.shared.selectionChange()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(themeManager.themeMode == .kawaii ? suggestedCategory.color.kawaiiGradient : suggestedCategory.color.gradient)
                                    .frame(width: 12, height: 12)
                                
                                Text(suggestedCategory.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(theme.text)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .stroke(
                                        (themeManager.themeMode == .kawaii ? suggestedCategory.color.kawaiiColor.opacity(0.3) : suggestedCategory.color.color.opacity(0.3)),
                                        lineWidth: 0
                                    )
                                    .background(
                                        Capsule()
                                            .fill(themeManager.themeMode == .kawaii ? suggestedCategory.color.kawaiiLightColor : suggestedCategory.color.lightColor)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
                }
                
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // No category option
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = nil
                                HapticManager.shared.selectionChange()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(selectedCategory == nil ? theme.text : theme.textSecondary)
                                
                                Text("None")
                                    .font(.system(size: 14, weight: selectedCategory == nil ? .semibold : .medium))
                                    .foregroundColor(selectedCategory == nil ? theme.text : theme.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == nil ? theme.surface : theme.surfaceSecondary)
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedCategory == nil ? theme.textSecondary.opacity(0.3) : theme.textTertiary.opacity(0.2),
                                                lineWidth: selectedCategory == nil ? 2 : 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Category options
                        ForEach(categoryManager.categories) { category in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = selectedCategory?.id == category.id ? nil : category
                                    HapticManager.shared.selectionChange()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(themeManager.themeMode == .kawaii ? category.color.kawaiiGradient : category.color.gradient)
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    themeManager.themeMode == .kawaii ? category.color.kawaiiDarkColor : category.color.darkColor,
                                                    lineWidth: 0
                                                )
                                                .opacity(0.3)
                                        )
                                        .scaleEffect(selectedCategory?.id == category.id ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.15), value: selectedCategory?.id == category.id)
                                    
                                    Text(category.name)
                                        .font(.system(size: 14, weight: selectedCategory?.id == category.id ? .semibold : .medium))
                                        .foregroundColor(selectedCategory?.id == category.id ? (themeManager.themeMode == .kawaii ? category.color.kawaiiDarkColor : category.color.darkColor) : theme.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory?.id == category.id ? (themeManager.themeMode == .kawaii ? category.color.kawaiiLightColor : category.color.lightColor) : theme.surface)
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    selectedCategory?.id == category.id ? (themeManager.themeMode == .kawaii ? category.color.kawaiiColor.opacity(0.5) : category.color.color.opacity(0.5)) : theme.textTertiary.opacity(0.2),
                                                    lineWidth: selectedCategory?.id == category.id ? 2 : 1
                                                )
                                        )
                                )
                                .scaleEffect(selectedCategory?.id == category.id ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: selectedCategory?.id == category.id)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
                }
                .scrollContentBackground(.hidden)
                .clipped()
            }
            .padding(20)
            .neumorphicCard(theme, cornerRadius: 16)
        }
        .transition(.scaleAndSlide)
    }
    
    private var dueDateSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Due Date", icon: "calendar")
                .matchedGeometryEffect(id: "date-header", in: formNamespace)
            
            VStack(spacing: 16) {
                // Due date toggle with enhanced animations
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set due date")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.text)
                        
                        Text("Add a deadline for this task")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $hasDueDate)
                        .toggleStyle(CustomToggleStyle())
                        .scaleEffect(hasDueDate ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: hasDueDate)
                }
                
                if hasDueDate {
                    DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .foregroundColor(theme.text)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.textTertiary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity).combined(with: .offset(y: -10)),
                            removal: .scale.combined(with: .opacity).combined(with: .offset(y: 10))
                        ))
                        .matchedGeometryEffect(id: "date-picker", in: formNamespace)
                }
            }
            .padding(20)
            .neumorphicCard(theme, cornerRadius: 16)
        }
        .transition(.scaleAndSlide)
    }
    
    private var reminderSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Reminder", icon: "bell")
                .matchedGeometryEffect(id: "reminder-header", in: formNamespace)
            
            VStack(spacing: 12) {
                // Toggle for reminder
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set reminder")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.text)
                        
                        if hasReminder {
                            Text("Reminder set for \(formatReminderDate(reminderDate))")
                                .font(.caption)
                                .foregroundColor(theme.success)
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            Text("Get notified about this task")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $hasReminder)
                        .toggleStyle(CustomToggleStyle())
                        .scaleEffect(hasReminder ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: hasReminder)
                }
                
                // Quick reminder options - shown inline when reminder is enabled
                if hasReminder {
                    VStack(spacing: 12) {
                        if hasDueDate {
                            // Show relative options for tasks with due dates
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                quickReminderOption("15 min before", icon: "clock.fill", isSelected: selectedReminderOption == "15 min before") {
                                    reminderDate = Calendar.current.date(byAdding: .minute, value: -15, to: dueDate) ?? dueDate
                                }
                                
                                quickReminderOption("1 hour before", icon: "clock.arrow.circlepath", isSelected: selectedReminderOption == "1 hour before") {
                                    reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: dueDate) ?? dueDate
                                }
                                
                                quickReminderOption("1 day before", icon: "calendar.day.timeline.leading", isSelected: selectedReminderOption == "1 day before") {
                                    reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
                                }
                                
                                quickReminderOption("Custom time", icon: "gear", isSelected: selectedReminderOption == "Custom time") {
                                    showReminderScheduler = true
                                }
                            }
                        } else {
                            // Show time-based options for tasks without due dates
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                quickReminderOption("In 1 hour", icon: "clock.fill", isSelected: selectedReminderOption == "In 1 hour") {
                                    reminderDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                                }
                                
                                quickReminderOption("Tomorrow 9 AM", icon: "sun.max.fill", isSelected: selectedReminderOption == "Tomorrow 9 AM") {
                                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date().addingTimeInterval(86400))
                                    components.hour = 9
                                    components.minute = 0
                                    reminderDate = Calendar.current.date(from: components) ?? Date()
                                }
                                
                                quickReminderOption("This evening", icon: "moon.fill", isSelected: selectedReminderOption == "This evening") {
                                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                                    components.hour = 18
                                    components.minute = 0
                                    reminderDate = Calendar.current.date(from: components) ?? Date()
                                }
                                
                                quickReminderOption("Custom time", icon: "gear", isSelected: selectedReminderOption == "Custom time") {
                                    showReminderScheduler = true
                                }
                            }
                        }
                        
                        // Show selected time with option to adjust
                        HStack {
                            Text("Reminder: \(formatReminderDate(reminderDate))")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            
                            Spacer()
                            
                            Button("Adjust") {
                                showReminderScheduler = true
                            }
                            .font(.caption)
                            .foregroundColor(theme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.surfaceSecondary)
                            )
                            .animatedButton(pressedScale: 0.95)
                        }
                        .padding(.top, 4)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).combined(with: .offset(y: -10)),
                        removal: .scale.combined(with: .opacity).combined(with: .offset(y: 10))
                    ))
                }
            }
            .padding(20)
            .neumorphicCard(theme, cornerRadius: 16)
        }
        .transition(.scaleAndSlide)
        .onChange(of: hasReminder) { _, newValue in
            if newValue {
                if reminderDate < Date() {
                    // Set a default reminder time if none is set or it's in the past
                    if hasDueDate {
                        reminderDate = Calendar.current.date(byAdding: .minute, value: -15, to: dueDate) ?? dueDate
                        selectedReminderOption = "15 min before"
                    } else {
                        reminderDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                        selectedReminderOption = "In 1 hour"
                    }
                }
            } else {
                selectedReminderOption = nil
            }
        }
        .onChange(of: showReminderScheduler) { _, newValue in
            if !newValue && hasReminder {
                // User returned from custom scheduler
                selectedReminderOption = "Custom time"
            }
        }
    }
    
    // Helper function for quick reminder options
    private func quickReminderOption(_ title: String, icon: String, isSelected: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            selectedReminderOption = title
            HapticManager.shared.selectionChanged()
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? theme.background : theme.primary)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? theme.background : theme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? theme.accentGradient : LinearGradient(colors: [theme.surface], startPoint: .leading, endPoint: .trailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? theme.accent : theme.textTertiary.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .applyNeumorphicShadow(isSelected ? theme.neumorphicPressedStyle : theme.neumorphicButtonStyle)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .animatedButton(pressedScale: 0.95)
        .hapticFeedback(.light)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var floatingButtons: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                // Cancel button with enhanced animations
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        dismiss()
                    }
                }
                .font(.headline)
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .neumorphicButton(theme, cornerRadius: 16)
                .animatedButton(pressedScale: 0.97)
                .hapticFeedback(.light)
                
                // Save button with loading state
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
            .transition(.slideInFromTrailing)
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            saveTask()
        }) {
            HStack {
                if savingTask {
                    BouncingDots(dotCount: 3, dotSize: 6, color: .white)
                        .transition(.scale)
                } else {
                    Text("Save Task")
                        .transition(.scale)
                }
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(theme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                      LinearGradient(colors: [theme.textTertiary], startPoint: .leading, endPoint: .trailing) : theme.accentGradient)
                .applyNeumorphicShadow(theme.neumorphicButtonStyle)
        )
        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || savingTask)
        .scaleEffect(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: title.isEmpty)
        .animatedButton(pressedScale: 0.97)
        .hapticFeedback(.medium)
    }
    
    private var successAnimationOverlay: some View {
        VStack {
            if showSuccessAnimation {
                // Modern iOS-style toast notification
                HStack(spacing: 12) {
                    // Success icon with modern styling
                    ZStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Success text with proper typography
                    Text(taskToEdit == nil ? "Task Created" : "Task Updated")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    // Modern material background with proper blur
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 20)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.9), value: showSuccessAnimation)
            }
            
            Spacer()
        }
        .padding(.top, 60) // Position below navigation area
    }
    
    private func formatReminderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func determineReminderOption(reminderDate: Date, dueDate: Date?) -> String {
        if let dueDate = dueDate {
            let timeDifference = dueDate.timeIntervalSince(reminderDate)
            if abs(timeDifference - 15 * 60) < 60 { // 15 minutes with 1 minute tolerance
                return "15 min before"
            } else if abs(timeDifference - 60 * 60) < 60 { // 1 hour with 1 minute tolerance
                return "1 hour before"
            } else if abs(timeDifference - 24 * 60 * 60) < 60 { // 1 day with 1 minute tolerance
                return "1 day before"
            }
        } else {
            let now = Date()
            let timeDifference = reminderDate.timeIntervalSince(now)
            if abs(timeDifference - 60 * 60) < 60 { // 1 hour with 1 minute tolerance
                return "In 1 hour"
            }
            
            // Check if it's tomorrow at 9 AM
            let calendar = Calendar.current
            let reminderComponents = calendar.dateComponents([.hour, .minute], from: reminderDate)
            let tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: now.addingTimeInterval(86400))
            if reminderComponents.hour == 9 && reminderComponents.minute == 0 {
                var expectedTomorrow = tomorrowComponents
                expectedTomorrow.hour = 9
                expectedTomorrow.minute = 0
                if let expectedDate = calendar.date(from: expectedTomorrow),
                   abs(reminderDate.timeIntervalSince(expectedDate)) < 60 {
                    return "Tomorrow 9 AM"
                }
            }
            
            // Check if it's this evening (6 PM)
            let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            if reminderComponents.hour == 18 && reminderComponents.minute == 0 {
                var expectedEvening = todayComponents
                expectedEvening.hour = 18
                expectedEvening.minute = 0
                if let expectedDate = calendar.date(from: expectedEvening),
                   abs(reminderDate.timeIntervalSince(expectedDate)) < 60 {
                    return "This evening"
                }
            }
        }
        return "Custom time"
    }
    
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { 
            // Haptic feedback for validation error
            HapticManager.shared.validationError()
            return 
        }
        
        // Start saving animation
        withAnimation(.easeInOut(duration: 0.2)) {
            savingTask = true
        }
        
        // Simulate brief saving delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let taskToEdit = taskToEdit {
                // Edit existing task
                var updatedTask = taskToEdit
                updatedTask.title = trimmedTitle
                updatedTask.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
                updatedTask.dueDate = hasDueDate ? dueDate : nil
                updatedTask.hasReminder = hasReminder
                updatedTask.reminderDate = hasReminder ? reminderDate : nil
                updatedTask.categoryId = selectedCategory?.id
                updatedTask.quickListItems = quickListItems
                
                taskManager.updateTask(updatedTask)
            } else {
                // Add new task
                let newTask = Task(
                    title: trimmedTitle,
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                    dueDate: hasDueDate ? dueDate : nil,
                    hasReminder: hasReminder,
                    reminderDate: hasReminder ? reminderDate : nil,
                    categoryId: selectedCategory?.id,
                    quickListItems: quickListItems
                )
                
                taskManager.addTask(newTask)
            }
            
            // Show success animation
            withAnimation(.easeInOut(duration: 0.3)) {
                savingTask = false
                showSuccessAnimation = true
            }
            
            // Haptic feedback for successful save
            HapticManager.shared.taskAdded()
            
            // Quick success feedback with faster timing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                    showSuccessAnimation = false
                }
            }
            
            // Dismiss view quickly after toast disappears
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Keyboard Observers
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = false
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
}

struct SectionHeader: View {
    @Environment(\.theme) var theme
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.accentGradient)
                    .frame(width: 32, height: 32)
                    .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.background)
                    .shadow(
                        color: theme.background == .black ? Color.white.opacity(0.3) : Color.black.opacity(0.3),
                        radius: 2,
                        x: 0,
                        y: 1
                    )
            }
            .pulsing(minScale: 0.98, maxScale: 1.02, duration: 3.0)
            
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(theme.text)
            
            Spacer()
        }
    }
}

struct CustomToggleStyle: ToggleStyle {
    @Environment(\.theme) var theme
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? theme.accentGradient : LinearGradient(colors: [theme.surfaceSecondary], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 50, height: 30)
                    .applyNeumorphicShadow(configuration.isOn ? theme.neumorphicPressedStyle : theme.neumorphicButtonStyle)
                
                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .scaleEffect(configuration.isOn ? 1.1 : 1.0)
                    .animation(.bounceSpring, value: configuration.isOn)
            }
            .onTapGesture {
                withAnimation(.bounceSpring) {
                    configuration.isOn.toggle()
                }
                HapticManager.shared.selectionChange()
            }
            .animatedButton(pressedScale: 0.98)
        }
    }
}

#Preview {
    AddEditTaskView(taskManager: TaskManager())
        .environmentObject(ThemeManager())
        .environment(\.theme, LightTheme())
}