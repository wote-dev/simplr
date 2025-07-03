//
//  AddEditTaskView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

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
    @State private var formScale: CGFloat = 0.95
    @State private var formOpacity: Double = 0
    @State private var savingTask = false
    @Namespace private var formNamespace
    
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
                withAnimation(.smoothSpring.delay(0.1)) {
                    formScale = 1.0
                    formOpacity = 1.0
                }
                
                // Initialize category selection
                if let task = taskToEdit, let categoryId = task.categoryId {
                    selectedCategory = categoryManager.category(for: categoryId)
                }
                
                // Auto-focus title field for new tasks
                if taskToEdit == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTitleFocused = true
                    }
                }
            }
            .onChange(of: title) { _, newTitle in
                // Update category suggestion based on title
                if selectedCategory == nil && !newTitle.isEmpty {
                    suggestedCategory = categoryManager.suggestCategory(for: newTitle)
                } else if newTitle.isEmpty {
                    suggestedCategory = nil
                }
            }
    }
    
    private var mainView: some View {
        NavigationView {
            contentView
                .navigationTitle("")
                .navigationBarHidden(true)
                .toolbar {
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
                .overlay(floatingButtons)
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
    
    private var formSections: some View {
        VStack(spacing: 20) {
            taskDetailsSection
            categorySection
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
                        .foregroundColor(theme.text)
                    
                    TextField("Enter task title", text: $title)
                        .focused($isTitleFocused)
                        .font(.body)
                        .foregroundColor(theme.text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.surface)
                        )
                        .scaleEffect(isTitleFocused ? 1.02 : 1.0)
                        .animation(.bounceSpring, value: isTitleFocused)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isTitleFocused ? theme.accentGradient : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                                .animation(.smoothEase, value: isTitleFocused)
                        )
                }
                .transition(.slideInFromTrailing)
                
                // Description field with enhanced focus animations
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(theme.text)
                    
                    TextField("Add details (optional)", text: $description, axis: .vertical)
                        .focused($isDescriptionFocused)
                        .font(.body)
                        .foregroundColor(theme.text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(3...6)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.surface)
                        )
                        .scaleEffect(isDescriptionFocused ? 1.02 : 1.0)
                        .animation(.bounceSpring, value: isDescriptionFocused)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isDescriptionFocused ? theme.accentGradient : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                                .animation(.smoothEase, value: isDescriptionFocused)
                        )
                }
                .transition(.slideInFromTrailing)
            }
            .padding(20)
            .neumorphicCard(theme, cornerRadius: 16)
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
                            withAnimation(.smoothSpring) {
                                selectedCategory = suggestedCategory
                                HapticManager.shared.selectionChange()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(suggestedCategory.color.gradient)
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
                                    .stroke(suggestedCategory.color.color.opacity(0.3), lineWidth: 1)
                                    .background(
                                        Capsule()
                                            .fill(suggestedCategory.color.lightColor)
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
                            withAnimation(.smoothSpring) {
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
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == nil ? theme.surface : theme.surfaceSecondary)
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedCategory == nil ? theme.textSecondary.opacity(0.3) : Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Category options
                        ForEach(categoryManager.categories) { category in
                            Button(action: {
                                withAnimation(.smoothSpring) {
                                    selectedCategory = selectedCategory?.id == category.id ? nil : category
                                    HapticManager.shared.selectionChange()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(category.color.gradient)
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .stroke(category.color.darkColor, lineWidth: 1)
                                                .opacity(0.3)
                                        )
                                        .scaleEffect(selectedCategory?.id == category.id ? 1.1 : 1.0)
                                        .animation(.smoothSpring, value: selectedCategory?.id == category.id)
                                    
                                    Text(category.name)
                                        .font(.system(size: 14, weight: selectedCategory?.id == category.id ? .semibold : .medium))
                                        .foregroundColor(selectedCategory?.id == category.id ? category.color.darkColor : theme.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory?.id == category.id ? category.color.lightColor : theme.surface)
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    selectedCategory?.id == category.id ? category.color.color.opacity(0.3) : Color.clear,
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                .scaleEffect(selectedCategory?.id == category.id ? 1.05 : 1.0)
                                .animation(.smoothSpring, value: selectedCategory?.id == category.id)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollContentBackground(.hidden)
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
                            .foregroundColor(theme.text)
                        
                        Text("Add a deadline for this task")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $hasDueDate)
                        .toggleStyle(CustomToggleStyle())
                        .scaleEffect(hasDueDate ? 1.05 : 1.0)
                        .animation(.bounceSpring, value: hasDueDate)
                }
                
                if hasDueDate {
                    DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .foregroundColor(theme.text)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.surface)
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
                        .animation(.bounceSpring, value: hasReminder)
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
                                quickReminderOption("15 min before", icon: "clock.fill") {
                                    reminderDate = Calendar.current.date(byAdding: .minute, value: -15, to: dueDate) ?? dueDate
                                }
                                
                                quickReminderOption("1 hour before", icon: "clock.arrow.circlepath") {
                                    reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: dueDate) ?? dueDate
                                }
                                
                                quickReminderOption("1 day before", icon: "calendar.day.timeline.leading") {
                                    reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
                                }
                                
                                quickReminderOption("Custom time", icon: "gear") {
                                    showReminderScheduler = true
                                }
                            }
                        } else {
                            // Show time-based options for tasks without due dates
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                quickReminderOption("In 1 hour", icon: "clock.fill") {
                                    reminderDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                                }
                                
                                quickReminderOption("Tomorrow 9 AM", icon: "sun.max.fill") {
                                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date().addingTimeInterval(86400))
                                    components.hour = 9
                                    components.minute = 0
                                    reminderDate = Calendar.current.date(from: components) ?? Date()
                                }
                                
                                quickReminderOption("This evening", icon: "moon.fill") {
                                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                                    components.hour = 18
                                    components.minute = 0
                                    reminderDate = Calendar.current.date(from: components) ?? Date()
                                }
                                
                                quickReminderOption("Custom time", icon: "gear") {
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
                                RoundedRectangle(cornerRadius: 6)
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
            if newValue && reminderDate < Date() {
                // Set a default reminder time if none is set or it's in the past
                if hasDueDate {
                    reminderDate = Calendar.current.date(byAdding: .minute, value: -15, to: dueDate) ?? dueDate
                } else {
                    reminderDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                }
            }
        }
    }
    
    // Helper function for quick reminder options
    private func quickReminderOption(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primary)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surfaceSecondary)
                    .applyNeumorphicShadow(theme.neumorphicButtonStyle)
            )
        }
        .animatedButton(pressedScale: 0.95)
        .hapticFeedback(.light)
    }
    
    private var floatingButtons: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                // Cancel button with enhanced animations
                Button("Cancel") {
                    withAnimation(.smoothSpring) {
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
        .animation(.bounceSpring, value: title.isEmpty)
        .animatedButton(pressedScale: 0.97)
        .hapticFeedback(.medium)
    }
    
    private var successAnimationOverlay: some View {
        ZStack {
            if showSuccessAnimation {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(theme.success)
                            .frame(width: 80, height: 80)
                            .scaleEffect(showSuccessAnimation ? 1.0 : 0.1)
                            .animation(.bounceSpring.delay(0.1), value: showSuccessAnimation)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(theme.background)
                            .shadow(
                                color: theme.background == .black ? Color.white.opacity(0.3) : Color.black.opacity(0.3),
                                radius: 2,
                                x: 0,
                                y: 1
                            )
                            .scaleEffect(showSuccessAnimation ? 1.0 : 0.1)
                            .animation(.bounceSpring.delay(0.2), value: showSuccessAnimation)
                    }
                    
                    Text(taskToEdit == nil ? "Task Created!" : "Task Updated!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .scaleEffect(showSuccessAnimation ? 1.0 : 0.1)
                        .animation(.bounceSpring.delay(0.3), value: showSuccessAnimation)
                    
                    // Particle celebration
                    ParticleSystem(
                        particleCount: 15,
                        colors: [theme.success, .white, theme.primary],
                        size: 8,
                        animationDuration: 1.5
                    )
                    .opacity(showSuccessAnimation ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.3).delay(0.4), value: showSuccessAnimation)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func formatReminderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { 
            // Haptic feedback for validation error
            HapticManager.shared.validationError()
            return 
        }
        
        // Start saving animation
        withAnimation(.smoothSpring) {
            savingTask = true
        }
        
        // Simulate brief saving delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let taskToEdit = taskToEdit {
                // Edit existing task
                var updatedTask = taskToEdit
                updatedTask.title = trimmedTitle
                updatedTask.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
                updatedTask.dueDate = hasDueDate ? dueDate : nil
                updatedTask.hasReminder = hasReminder
                updatedTask.reminderDate = hasReminder ? reminderDate : nil
                updatedTask.categoryId = selectedCategory?.id
                
                taskManager.updateTask(updatedTask)
            } else {
                // Add new task
                let newTask = Task(
                    title: trimmedTitle,
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                    dueDate: hasDueDate ? dueDate : nil,
                    hasReminder: hasReminder,
                    reminderDate: hasReminder ? reminderDate : nil,
                    categoryId: selectedCategory?.id
                )
                
                taskManager.addTask(newTask)
            }
            
            // Show success animation
            withAnimation(.bounceSpring) {
                savingTask = false
                showSuccessAnimation = true
            }
            
            // Haptic feedback for successful save
            HapticManager.shared.taskAdded()
            
            // Dismiss after success animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.smoothSpring) {
                    dismiss()
                }
            }
        }
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