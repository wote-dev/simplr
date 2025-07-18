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

    
    let taskToEdit: Task?
    
    init(taskManager: TaskManager, taskToEdit: Task? = nil) {
        self.taskManager = taskManager
        self.taskToEdit = taskToEdit
    }
    
    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when tapping background
                    isTitleFocused = false
                    hideKeyboard()
                }
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    taskFormSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in
                        // Dismiss keyboard when scrolling
                        isTitleFocused = false
                        hideKeyboard()
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
        VStack(spacing: 20) {
            // Title and Description
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.text)
                    
                    CustomTextField(text: $title, placeholder: "Enter task title", isFirstResponder: true)
                        .frame(height: 48)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.text)
                    
                    CustomTextField(text: $description, placeholder: "Add more details...", isMultiline: true)
                        .frame(minHeight: 80)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.shadow, radius: 8, x: 0, y: 4)
            )
            
            // Category Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Category")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.text)
                
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
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.shadow, radius: 8, x: 0, y: 4)
            )
            
            // Checklist Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Checklist")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.text)

                ForEach($checklistItems) { $item in
                    HStack {
                        CustomTextField(
                            text: $item.title, 
                            placeholder: "Checklist item"
                        )
                        .frame(height: 48)
                        Button(action: {
                            if let index = checklistItems.firstIndex(where: { $0.id == item.id }) {
                                checklistItems.remove(at: index)
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }

                HStack {
                    CustomTextField(
                        text: $newChecklistItemTitle, 
                        placeholder: "Add new item",
                        onCommit: addChecklistItem
                    )
                    .frame(height: 48)
                    
                    Button(action: addChecklistItem) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(theme.accent)
                    }
                    .disabled(newChecklistItemTitle.isEmpty)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.shadow, radius: 8, x: 0, y: 4)
            )

            // Due Date
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Due Date")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.text)
                        
                        Text("Set a deadline for this task")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $hasDueDate)
                        .toggleStyle(SwitchToggleStyle(tint: theme.accent))
                }
                
                if hasDueDate {
                    DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .foregroundColor(theme.text)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.shadow, radius: 8, x: 0, y: 4)
            )
            
            // Reminder
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reminder")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.text)
                        
                        Text("Get notified about this task")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $hasReminder)
                        .toggleStyle(SwitchToggleStyle(tint: theme.accent))
                }
                
                if hasReminder {
                    DatePicker("Reminder time", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .foregroundColor(theme.text)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.shadow, radius: 8, x: 0, y: 4)
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