//
//  AddTaskView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct AddTaskView: View {
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
    @State private var selectedCategory: TaskCategory? = nil
    @State private var checklistItems: [ChecklistItem] = []
    @State private var newChecklistItemTitle = ""
    @FocusState private var isTitleFocused: Bool
    @State private var showingSuccess = false
    @State private var isTextFieldActive = false
    @State private var lastTapLocation: CGPoint = .zero

    
    let taskToEdit: Task?
    
    init(taskManager: TaskManager, taskToEdit: Task? = nil) {
        self.taskManager = taskManager
        self.taskToEdit = taskToEdit
    }
    
    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { location in
                    lastTapLocation = location
                    // Only dismiss keyboard if tapping outside text fields
                    if !isTextFieldActive {
                        isTitleFocused = false
                        hideKeyboard()
                    }
                }
            
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    
                    taskFormSection
                        .animation(.easeInOut(duration: 0.3), value: hasDueDate)
                        .animation(.easeInOut(duration: 0.3), value: hasReminder)
                        .animation(.easeInOut(duration: 0.3), value: checklistItems.count)
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .global)
                    .onChanged { value in
                        // Only dismiss keyboard for significant scroll gestures
                        // and not when text selection might be happening
                        let velocity = sqrt(pow(value.velocity.width, 2) + pow(value.velocity.height, 2))
                        if velocity > 300 && !isTextFieldActive {
                            isTitleFocused = false
                            hideKeyboard()
                        }
                    }
            )
        }
        .navigationTitle(taskToEdit == nil ? "Add Task" : "Edit Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(theme.background == .black || theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? .dark : .light, for: .navigationBar)
        .toolbarBackground(theme.surface.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(theme.textSecondary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveTask()
                }
                .foregroundColor(themeManager.themeMode == .kawaii ? theme.text : theme.primary)
                .fontWeight(.semibold)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            setupInitialValues()
            isTitleFocused = taskToEdit == nil
        }
        .overlay(successOverlay)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(taskToEdit == nil ? "Add New Task" : "Edit Task")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.text)
            
            Text(taskToEdit == nil ? "Create a new task to stay organized" : "Update your task details")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var taskFormSection: some View {
        VStack(spacing: 32) {
            // MARK: - Basic Information Section
            VStack(spacing: 0) {
                // Section Header with enhanced styling
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Basic Information")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(theme.text)
                        
                        Text("Task title and description")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Visual indicator
                    Image(systemName: "doc.text")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.accent)
                        .opacity(0.7)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Subtle divider
                Rectangle()
                    .fill(theme.border.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                
                // Content
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.text)
                        
                        CustomTextField(
                            text: $title, 
                            placeholder: "Enter task title", 
                            isFirstResponder: true,
                            allowsTextSelection: true
                        )
                        .frame(height: 48)
                        .onTapGesture {
                            isTextFieldActive = true
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { _ in
                            isTextFieldActive = true
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidEndEditingNotification)) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isTextFieldActive = false
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.text)
                        
                        CustomTextField(
                            text: $description, 
                            placeholder: "Add more details...", 
                            isMultiline: true,
                            allowsTextSelection: true
                        )
                        .frame(minHeight: 80)
                        .onTapGesture {
                            isTextFieldActive = true
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UITextView.textDidBeginEditingNotification)) { _ in
                            isTextFieldActive = true
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UITextView.textDidEndEditingNotification)) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isTextFieldActive = false
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(theme.surface)
                    .shadow(color: theme.shadow.opacity(0.15), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(theme.border.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // MARK: - Category Selection Section
            VStack(spacing: 0) {
                // Section Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Category")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(theme.text)
                        
                        Text("Organize your task")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Visual indicator
                    Image(systemName: "folder")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.accent)
                        .opacity(0.7)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Subtle divider
                Rectangle()
                    .fill(theme.border.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // No category option
                            CategoryPill(
                                title: "None",
                                color: .gray,
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }
                            
                            // Category options
                            ForEach(categoryManager.categories) { category in
                                CategoryPill(
                                    title: category.name,
                                    color: category.color.color,
                                    isSelected: selectedCategory?.id == category.id
                                ) {
                                    selectedCategory = selectedCategory?.id == category.id ? nil : category
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                    .clipped()
                }
                .padding(.bottom, 20)
                .padding(.top, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(theme.surface)
                    .shadow(color: theme.shadow.opacity(0.15), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(theme.border.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // MARK: - Checklist Section
            VStack(spacing: 0) {
                // Section Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Checklist")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(theme.text)
                        
                        Text("Break down your task")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Visual indicator with item count
                    HStack(spacing: 6) {
                        if !checklistItems.isEmpty {
                            Text("\(checklistItems.count)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(theme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(theme.accent.opacity(0.15))
                                )
                        }
                        
                        Image(systemName: "checklist")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.accent)
                            .opacity(0.7)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Subtle divider
                Rectangle()
                    .fill(theme.border.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    ForEach($checklistItems) { $item in
                        HStack {
                            CustomTextField(
                                text: $item.title, 
                                placeholder: "Checklist item",
                                allowsTextSelection: true
                            )
                            .frame(height: 48)
                            .onTapGesture {
                                isTextFieldActive = true
                            }
                            Button(action: {
                                if let index = checklistItems.firstIndex(where: { $0.id == item.id }) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        checklistItems.remove(at: index)
                                    }
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(.red.opacity(0.1))
                                    )
                            }
                        }
                    }

                    HStack {
                        CustomTextField(
                            text: $newChecklistItemTitle, 
                            placeholder: "Add new item",
                            onCommit: addChecklistItem,
                            allowsTextSelection: true
                        )
                        .frame(height: 48)
                        .onTapGesture {
                            isTextFieldActive = true
                        }
                        
                        Button(action: addChecklistItem) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(theme.accent)
                        }
                        .disabled(newChecklistItemTitle.isEmpty)
                        .opacity(newChecklistItemTitle.isEmpty ? 0.5 : 1.0)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(theme.surface)
                    .shadow(color: theme.shadow.opacity(0.15), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(theme.border.opacity(0.1), lineWidth: 1)
                    )
            )

            // MARK: - Due Date Section
            VStack(spacing: 0) {
                // Section Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Due Date")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(theme.text)
                        
                        Text("Set a deadline for this task")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Visual indicator and toggle
                    HStack(spacing: 12) {
                        if hasDueDate {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.accent)
                                .opacity(0.7)
                        } else {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                                .opacity(0.5)
                        }
                        
                        Toggle("", isOn: $hasDueDate)
                            .toggleStyle(SwitchToggleStyle(tint: theme.accent))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Subtle divider
                Rectangle()
                    .fill(theme.border.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                
                // Content
                VStack(spacing: 16) {
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .foregroundColor(theme.text)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, hasDueDate ? 20 : 8)
                .padding(.top, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(theme.surface)
                    .shadow(color: theme.shadow.opacity(0.15), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(theme.border.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // MARK: - Reminder Section
            VStack(spacing: 0) {
                // Section Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reminder")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(theme.text)
                        
                        Text("Get notified about this task")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Visual indicator and toggle
                    HStack(spacing: 12) {
                        if hasReminder {
                            Image(systemName: "bell.badge")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.accent)
                                .opacity(0.7)
                        } else {
                            Image(systemName: "bell")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                                .opacity(0.5)
                        }
                        
                        Toggle("", isOn: $hasReminder)
                            .toggleStyle(SwitchToggleStyle(tint: theme.accent))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Subtle divider
                Rectangle()
                    .fill(theme.border.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                
                // Content
                VStack(spacing: 16) {
                    if hasReminder {
                        DatePicker("Reminder time", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .foregroundColor(theme.text)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, hasReminder ? 20 : 8)
                .padding(.top, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(theme.surface)
                    .shadow(color: theme.shadow.opacity(0.15), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(theme.border.opacity(0.1), lineWidth: 1)
                    )
            )
            

        }
    }
    
    private var successOverlay: some View {
        ZStack {
            if showingSuccess {
                // Full screen celebration overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 20) {
                    // Large animated checkmark
                    ZStack {
                        Circle()
                            .fill(.green.gradient)
                            .frame(width: 80, height: 80)
                            .scaleEffect(showingSuccess ? 1.0 : 0.1)
                            .animation(.bouncy(duration: 0.6, extraBounce: 0.3), value: showingSuccess)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(showingSuccess ? 1.0 : 0.1)
                            .animation(.bouncy(duration: 0.6, extraBounce: 0.3).delay(0.1), value: showingSuccess)
                    }
                    
                    // Success text
                    VStack(spacing: 8) {
                        Text(taskToEdit == nil ? "Task Created!" : "Task Updated!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .scaleEffect(showingSuccess ? 1.0 : 0.8)
                            .opacity(showingSuccess ? 1.0 : 0.0)
                            .animation(.bouncy(duration: 0.5, extraBounce: 0.2).delay(0.2), value: showingSuccess)
                        
                        Text(taskToEdit == nil ? "Your task has been added successfully" : "Your changes have been saved")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .scaleEffect(showingSuccess ? 1.0 : 0.8)
                            .opacity(showingSuccess ? 1.0 : 0.0)
                            .animation(.bouncy(duration: 0.5, extraBounce: 0.2).delay(0.3), value: showingSuccess)
                    }
                }
                .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
    }
    
    private func setupInitialValues() {
        guard let task = taskToEdit else { return }
        
        title = task.title
        description = task.description
        dueDate = task.dueDate ?? Date()
        hasDueDate = task.dueDate != nil
        hasReminder = task.hasReminder
        reminderDate = task.reminderDate ?? Date()
        selectedCategory = categoryManager.categories.first { $0.id == task.categoryId }
        checklistItems = task.checklist

    }
    
    private func addChecklistItem() {
        guard !newChecklistItemTitle.isEmpty else { return }
        checklistItems.append(ChecklistItem(title: newChecklistItemTitle))
        newChecklistItemTitle = ""
    }
    
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            HapticManager.shared.validationError()
            return
        }
        
        if var taskToUpdate = taskToEdit {
            taskToUpdate.title = trimmedTitle
            taskToUpdate.description = description
            taskToUpdate.dueDate = hasDueDate ? dueDate : nil
            taskToUpdate.hasReminder = hasReminder
            taskToUpdate.reminderDate = hasReminder ? reminderDate : nil
            taskToUpdate.categoryId = selectedCategory?.id
            taskToUpdate.checklist = checklistItems

            taskManager.updateTask(taskToUpdate)
        } else {
            let newTask = Task(
                title: trimmedTitle,
                description: description,
                dueDate: hasDueDate ? dueDate : nil,
                hasReminder: hasReminder,
                reminderDate: hasReminder ? reminderDate : nil,
                categoryId: selectedCategory?.id,
                checklist: checklistItems
            )
            taskManager.addTask(newTask)
        }
        
        HapticManager.shared.taskAdded()
        
        withAnimation(.adaptiveSnappy) {
            showingSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            dismiss()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Supporting Views

struct CategoryPill: View {
    @Environment(\.theme) var theme
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? theme.text : theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? theme.accent.opacity(0.2) : theme.surfaceSecondary)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? theme.accent : theme.border, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}



#Preview {
    AddTaskView(taskManager: TaskManager())
        .environmentObject(ThemeManager())
        .environmentObject(CategoryManager())
        .environment(\.theme, LightTheme())
}