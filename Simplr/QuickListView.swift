//
//  QuickListView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct QuickListView: View {
    @Binding var quickListItems: [QuickListItem]
    @Environment(\.theme) private var theme
    @EnvironmentObject private var taskManager: TaskManager
    @State private var newItemText = ""
    @State private var editingItem: QuickListItem?
    @State private var editText = ""
    @FocusState private var isAddingFocused: Bool
    @FocusState private var isEditingFocused: Bool
    
    let taskId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress indicator
            if !quickListItems.isEmpty {
                QuickListProgressView(items: quickListItems)
                    .padding(.bottom, 4)
            }
            
            // List items
            ForEach(quickListItems) { item in
                if editingItem?.id == item.id {
                    // Edit mode
                    HStack(spacing: 12) {
                        Button(action: { toggleItem(item) }) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(item.isCompleted ? .green : theme.textSecondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        TextField("Item text", text: $editText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.subheadline)
                            .focused($isEditingFocused)
                            .onSubmit {
                                saveEdit()
                            }
                        
                        Button(action: saveEdit) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: cancelEdit) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(theme.primary, lineWidth: 1)
                            )
                    )
                } else {
                    QuickListItemRow(
                        item: item,
                        onToggle: { toggleItem(item) },
                        onEdit: { startEditing(item) },
                        onDelete: { deleteItem(item) }
                    )
                }
            }
            
            // Add new item field
            if isAddingFocused || newItemText.isEmpty {
                HStack(spacing: 12) {
                    TextField(quickListItems.isEmpty ? "Add quick list item" : "Add item", text: $newItemText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.subheadline)
                        .focused($isAddingFocused)
                        .onSubmit {
                            addNewItem()
                        }
                    
                    if !newItemText.isEmpty {
                        Button(action: addNewItem) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isAddingFocused ? theme.primary : theme.textTertiary, lineWidth: 1)
                        )
                )
            } else {
                // Add button when not focused
                Button(action: { isAddingFocused = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.primary)
                        
                        Text(quickListItems.isEmpty ? "Add quick list item" : "Add item")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .animation(.easeInOut(duration: 0.3), value: quickListItems.count)
    }
    
    // MARK: - Actions
    
    private func toggleItem(_ item: QuickListItem) {
        guard let taskId = taskId else {
            // Fallback for local state management
            if let index = quickListItems.firstIndex(where: { $0.id == item.id }) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    quickListItems[index].isCompleted.toggle()
                    quickListItems[index].completedAt = quickListItems[index].isCompleted ? Date() : nil
                }
            }
            return
        }
        
        // Immediate visual feedback - update local state first
        if let index = quickListItems.firstIndex(where: { $0.id == item.id }) {
            let newCompletionState = !quickListItems[index].isCompleted
            
            withAnimation(.easeInOut(duration: 0.2)) {
                quickListItems[index].isCompleted = newCompletionState
                quickListItems[index].completedAt = newCompletionState ? Date() : nil
            }
            
            // Haptic feedback
            HapticManager.shared.selectionChange()
            
            // Additional haptic feedback based on completion state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if newCompletionState {
                    HapticManager.shared.taskCompleted()
                } else {
                    HapticManager.shared.taskUncompleted()
                }
            }
        }
        
        // Then persist the change
        taskManager.toggleQuickListItem(taskId: taskId, itemId: item.id)
    }
    
    private func startEditing(_ item: QuickListItem) {
        editingItem = item
        editText = item.text
        isEditingFocused = true
    }
    
    private func saveEdit() {
        guard let editingItem = editingItem,
              !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            cancelEdit()
            return
        }
        
        let trimmedText = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let taskId = taskId {
            taskManager.updateQuickListItem(taskId: taskId, itemId: editingItem.id, newText: trimmedText)
        } else {
            // Fallback for local state management
            if let index = quickListItems.firstIndex(where: { $0.id == editingItem.id }) {
                quickListItems[index].text = trimmedText
            }
        }
        
        cancelEdit()
    }
    
    private func cancelEdit() {
        editingItem = nil
        editText = ""
        isEditingFocused = false
    }
    
    private func deleteItem(_ item: QuickListItem) {
        guard let taskId = taskId else {
            // Fallback for local state management
            withAnimation(.easeInOut(duration: 0.2)) {
                quickListItems.removeAll { $0.id == item.id }
            }
            return
        }
        
        // Immediate visual feedback - remove from local state first
        withAnimation(.easeInOut(duration: 0.2)) {
            quickListItems.removeAll { $0.id == item.id }
        }
        
        // Then persist the change
        taskManager.deleteQuickListItem(taskId: taskId, itemId: item.id)
    }
    
    private func addNewItem() {
        let trimmedText = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        if let taskId = taskId {
            // Create new item for immediate visual feedback
            let newItem = QuickListItem(text: trimmedText)
            
            // Immediate visual feedback - add to local state first
            withAnimation(.easeInOut(duration: 0.2)) {
                quickListItems.append(newItem)
            }
            
            // Clear the text field immediately
            newItemText = ""
            
            // Then persist the change
            taskManager.addQuickListItem(to: taskId, text: trimmedText)
        } else {
            // Fallback for local state management
            let newItem = QuickListItem(text: trimmedText)
            withAnimation(.easeInOut(duration: 0.2)) {
                quickListItems.append(newItem)
            }
            newItemText = ""
        }
        
        // Keep keyboard focused for next input
        isAddingFocused = true
    }
}

// MARK: - Quick List Item Row

struct QuickListItemRow: View {
    let item: QuickListItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion toggle
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.isCompleted ? .green : theme.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Item text
            Text(item.text)
                .font(.subheadline)
                .foregroundColor(item.isCompleted ? theme.textSecondary : theme.text)
                .strikethrough(item.isCompleted)
                .opacity(item.isCompleted ? 0.6 : 1.0)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                                    .stroke(theme.textTertiary, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Quick List Progress View

struct QuickListProgressView: View {
    let items: [QuickListItem]
    @Environment(\.theme) private var theme
    
    private var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    private var totalCount: Int {
        items.count
    }
    
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completedCount) of \(totalCount) completed")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track with border
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(theme.textTertiary.opacity(0.3), lineWidth: 1)
                        )
                        .frame(height: 8)
                    
                    // Progress fill with clear end indicator
                    if progress > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progress == 1.0 ? Color.green.gradient : theme.primary.gradient)
                            .frame(width: max(8, geometry.size.width * progress), height: 8)
                            .overlay(
                                // End cap indicator
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(progress == 1.0 ? Color.green : theme.primary, lineWidth: 1.5)
                                    .frame(width: max(8, geometry.size.width * progress), height: 8)
                            )
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    QuickListView(
        quickListItems: .constant([
            QuickListItem(text: "Buy milk"),
            QuickListItem(text: "Buy bread")
        ]),
        taskId: nil
    )
    .environmentObject(TaskManager())
    .environment(\.theme, ThemeManager().currentTheme)
}