//
//  QuickListDetailView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct QuickListDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var categoryManager: CategoryManager
    
    let taskId: UUID
    // Use computed property to always get fresh data from TaskManager
    private var quickListItems: [QuickListItem] {
        currentTask?.quickListItems ?? []
    }
    @State private var newItemText = ""
    @State private var isTaskCompleted: Bool = false
    
    // Visual feedback states
    @State private var taskCompletionScale: CGFloat = 1.0
    @State private var isTaskPressed = false
    @State private var itemPressStates: [UUID: Bool] = [:]
    
    // Computed property to get the current task state from TaskManager
    private var currentTask: Task? {
        taskManager.tasks.first { $0.id == taskId }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Header with task info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentTask?.title ?? "Task")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(theme.text)
                            
                            if let description = currentTask?.description, !description.isEmpty {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        // Task completion toggle
                        Button(action: {
                            // Immediate haptic feedback
                            HapticManager.shared.buttonTap()
                            
                            // Visual press animation
                            withAnimation(.interpolatingSpring(stiffness: 600, damping: 30)) {
                                taskCompletionScale = 0.95
                            }
                            
                            // Reset scale after brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.interpolatingSpring(stiffness: 600, damping: 30)) {
                                    taskCompletionScale = 1.0
                                }
                            }
                            
                            // Persist the change first
                            if let task = currentTask {
                                taskManager.toggleTaskCompletion(task)
                                
                                // Immediate visual feedback with the new state
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isTaskCompleted = !isTaskCompleted
                                }
                                
                                // Additional haptic feedback based on completion state
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    if isTaskCompleted {
                                        HapticManager.shared.taskCompleted()
                                    } else {
                                        HapticManager.shared.taskUncompleted()
                                    }
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isTaskCompleted ? theme.success : theme.surface)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(isTaskCompleted ? theme.success : theme.textTertiary, lineWidth: 2)
                                    )
                                    .scaleEffect(taskCompletionScale)
                                
                                if isTaskCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(isTaskPressed ? 0.95 : 1.0)
                        .animation(.interpolatingSpring(stiffness: 600, damping: 30), value: isTaskPressed)
                    }
                    
                    // Progress indicator
                    if !quickListItems.isEmpty {
                        QuickListProgressView(items: quickListItems)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.surfaceGradient)
                )
                .padding(.horizontal, 16)
                
                // Quick list items
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(quickListItems.enumerated()), id: \.element.id) { index, item in
                            HStack(spacing: 16) {
                                // Completion toggle
                                Button(action: {
                                    // Immediate haptic feedback
                                    HapticManager.shared.selectionChange()
                                    
                                    // Visual press feedback
                                    withAnimation(.interpolatingSpring(stiffness: 600, damping: 30)) {
                                        itemPressStates[item.id] = true
                                    }
                                    
                                    // Reset press state
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.interpolatingSpring(stiffness: 600, damping: 30)) {
                                            itemPressStates[item.id] = false
                                        }
                                    }
                                    
                                    // Store the new completion state for haptic feedback
                                    let newCompletionState = !quickListItems[index].isCompleted
                                    
                                    // Toggle the item completion in TaskManager
                                    // This will automatically update the UI since we're using computed property
                                    taskManager.toggleQuickListItem(taskId: taskId, itemId: item.id)
                                    
                                    // Additional haptic feedback based on NEW completion state
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        if newCompletionState {
                                            HapticManager.shared.taskCompleted()
                                        } else {
                                            HapticManager.shared.taskUncompleted()
                                        }
                                    }
                                }) {
                                    Image(systemName: quickListItems[index].isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(quickListItems[index].isCompleted ? theme.success : theme.textSecondary)
                                        .scaleEffect((itemPressStates[item.id] ?? false) ? 0.85 : 1.0)
                                        .animation(.interpolatingSpring(stiffness: 600, damping: 30), value: itemPressStates[item.id])
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Item text
                                Text(quickListItems[index].text)
                                    .font(.body)
                                    .foregroundColor(quickListItems[index].isCompleted ? theme.textSecondary : theme.text)
                                    .strikethrough(quickListItems[index].isCompleted)
                                    .opacity(quickListItems[index].isCompleted ? 0.6 : 1.0)
                                
                                Spacer()
                                
                                // Delete button
                                Button(action: {
                                    deleteItem(item)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.surfaceGradient)
                            )
                        }
                        
                        // Add new item section
                        HStack(spacing: 16) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(theme.primary)
                            
                            TextField(quickListItems.isEmpty ? "Add your first item" : "Add new item", text: $newItemText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.body)
                                .onSubmit {
                                    addNewItem()
                                }
                            
                            if !newItemText.isEmpty {
                                Button(action: addNewItem) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(theme.primary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(theme.textTertiary, lineWidth: 1)
                                )
                        )
                        
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(theme.backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primary)
                }
            }
        }
        .onAppear {
            // Initialize local state with current task completion status
            isTaskCompleted = currentTask?.isCompleted ?? false
        }
        .onChange(of: currentTask?.isCompleted) { _, newValue in
            // Sync local state when TaskManager updates the task
            if let completed = newValue, completed != isTaskCompleted {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTaskCompleted = completed
                }
            }
        }
        // Removed onChange for quickListItems to prevent overwriting immediate visual feedback
        // Local state is now the single source of truth for UI updates

    }
    
    // MARK: - Actions
    
    private func deleteItem(_ item: QuickListItem) {
        // Delete the item from TaskManager - UI will update automatically
        taskManager.deleteQuickListItem(taskId: taskId, itemId: item.id)
        
        // Haptic feedback
        HapticManager.shared.selectionChange()
    }
    
    private func addNewItem() {
        let trimmedText = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Clear the text field immediately
        newItemText = ""
        
        // Add the item to TaskManager - UI will update automatically
        taskManager.addQuickListItem(to: taskId, text: trimmedText)
        
        // Haptic feedback
        HapticManager.shared.selectionChange()
    }
}

#Preview {
    let taskManager = TaskManager()
    let sampleTask = {
        var task = Task(title: "Sample Task", description: "This is a sample task with quick list items")
        task.quickListItems = [
            QuickListItem(text: "First item"),
            QuickListItem(text: "Second item"),
            QuickListItem(text: "Third item")
        ]
        return task
    }()
    
    // Add the sample task to the task manager
    taskManager.addTask(sampleTask)
    
    return QuickListDetailView(taskId: sampleTask.id)
        .environmentObject(taskManager)
        .environmentObject(CategoryManager())
        .environment(\.theme, LightTheme())
}