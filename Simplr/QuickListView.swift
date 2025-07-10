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
    
    // Binding to expose focus state to parent view
    @Binding var isQuickListFocused: Bool
    
    // Expose focus states to parent view
    var isAnyFieldFocused: Bool {
        isAddingFocused || isEditingFocused
    }
    
    init(quickListItems: Binding<[QuickListItem]>, taskId: UUID?, isQuickListFocused: Binding<Bool> = .constant(false)) {
        self._quickListItems = quickListItems
        self.taskId = taskId
        self._isQuickListFocused = isQuickListFocused
    }
    
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
                    // Edit mode with modern design
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edit Item")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primary)
                        
                        HStack(spacing: 12) {
                            Button(action: { toggleItem(item) }) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(item.isCompleted ? theme.success : theme.textSecondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            TextField("Edit item text", text: $editText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.body)
                                .foregroundColor(theme.text)
                                .focused($isEditingFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    let trimmedText = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmedText.isEmpty {
                                        // Dismiss keyboard if text is empty
                                        isEditingFocused = false
                                    } else {
                                        saveEdit()
                                    }
                                }
                            
                            HStack(spacing: 8) {
                                Button(action: saveEdit) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(theme.success)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: cancelEdit) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(theme.error)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Ensure tapping anywhere in the edit field area focuses the text field
                            if !isEditingFocused {
                                isEditingFocused = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.accentGradient, lineWidth: 0)
                    )
                    .shadow(
                        color: theme.primary.opacity(0.15),
                        radius: 8,
                        x: 0,
                        y: 2
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
            
            // Add new item field with modern design
            VStack(alignment: .leading, spacing: 8) {
                if isAddingFocused || !newItemText.isEmpty {
                    Text("New Item")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isAddingFocused ? theme.primary : theme.textSecondary)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
                
                HStack(spacing: 12) {
                    // Plus icon indicator
                    Image(systemName: isAddingFocused ? "plus.circle.fill" : "plus.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isAddingFocused ? theme.primary : theme.textSecondary)
                        .scaleEffect(isAddingFocused ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isAddingFocused)
                    
                    TextField(quickListItems.isEmpty ? "Add your first quick list item" : "Add another item", text: $newItemText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .foregroundColor(theme.text)
                        .focused($isAddingFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            let trimmedText = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmedText.isEmpty {
                                // Dismiss keyboard if text is empty
                                isAddingFocused = false
                            } else {
                                addNewItem()
                                // Keep keyboard open by maintaining focus after adding item
                                DispatchQueue.main.async {
                                    isAddingFocused = true
                                }
                            }
                        }
                        .onChange(of: isAddingFocused) { _, newValue in
                            // Prevent unwanted focus loss
                            if !newValue && !newItemText.isEmpty {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                    isAddingFocused = true
                                }
                            }
                        }
                    
                    if !newItemText.isEmpty {
                        Button(action: {
                            // Ensure focus is maintained when using button
                            let wasFocused = isAddingFocused
                            addNewItem()
                            if wasFocused {
                                DispatchQueue.main.async {
                                    isAddingFocused = true
                                }
                            }
                        }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // Ensure tapping anywhere in the text field area focuses the text field
                    if !isAddingFocused {
                        isAddingFocused = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface)
                )
                .scaleEffect(isAddingFocused ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isAddingFocused)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isAddingFocused ? theme.accentGradient : LinearGradient(colors: [theme.textTertiary.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 0
                        )
                        .animation(.easeInOut(duration: 0.2), value: isAddingFocused)
                )
                .shadow(
                    color: isAddingFocused ? theme.primary.opacity(0.1) : Color.clear,
                    radius: isAddingFocused ? 8 : 0,
                    x: 0,
                    y: isAddingFocused ? 2 : 0
                )
                .animation(.easeInOut(duration: 0.2), value: isAddingFocused)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: quickListItems.count)
        .onChange(of: isAnyFieldFocused) { _, newValue in
            // Sync with parent binding
            isQuickListFocused = newValue
        }
        .onChange(of: isQuickListFocused) { _, newValue in
            // Handle focus dismissal from parent
            if !newValue && isAnyFieldFocused {
                withAnimation(.easeOut(duration: 0.2)) {
                    isAddingFocused = false
                    isEditingFocused = false
                }
            }
        }
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
        
        // Clear editing state but maintain keyboard focus by transitioning to add field
        self.editingItem = nil
        self.editText = ""
        
        // Transition focus to the add new item field to keep keyboard visible
        DispatchQueue.main.async {
            self.isEditingFocused = false
            self.isAddingFocused = true
        }
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
        
        // Store focus state before any changes
        let wasFocused = isAddingFocused
        
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
        
        // Maintain focus to prevent keyboard dismissal if it was focused
        if wasFocused {
            // Immediately re-assert focus to prevent any loss
            isAddingFocused = true
            
            // Use multiple async dispatches with increasing delays for robustness
            DispatchQueue.main.async {
                self.isAddingFocused = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.isAddingFocused = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.isAddingFocused = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isAddingFocused = true
            }
            
            // Final assertion after view updates complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.isAddingFocused = true
            }
        }
    }
}

// MARK: - Quick List Item Row

struct QuickListItemRow: View {
    let item: QuickListItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.theme) private var theme
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion toggle with enhanced visual feedback
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(item.isCompleted ? theme.success : theme.textSecondary)
                    .scaleEffect(item.isCompleted ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Item text with improved typography
            Text(item.text)
                .font(.body)
                .foregroundColor(item.isCompleted ? theme.textSecondary : theme.text)
                .strikethrough(item.isCompleted)
                .opacity(item.isCompleted ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
            
            Spacer()
            
            // Action buttons with better spacing and visual hierarchy
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(
                            theme is KawaiiTheme ? 
                            Color.white : theme.textSecondary
                        )
                        .padding(6)
                        .background(
                            Circle()
                                .fill(
                                    theme is KawaiiTheme ? 
                                    theme.accent.opacity(0.8) : theme.surfaceSecondary
                                )
                                .opacity(isHovered ? 1.0 : (theme is KawaiiTheme ? 0.9 : 0.0))
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    theme is KawaiiTheme ? 
                                    theme.accent.opacity(0.4) : Color.clear,
                                    lineWidth: theme is KawaiiTheme ? 1 : 0
                                )
                                .opacity(theme is KawaiiTheme ? 1.0 : 0.0)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.error)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(theme.error.opacity(0.1))
                                .opacity(isHovered ? 1.0 : 0.0)
                        )
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
                        .stroke(theme.textTertiary.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
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
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.textTertiary.opacity(0.3), lineWidth: 1)
                        )
                        .frame(height: 8)
                    
                    // Progress fill with clear end indicator
                    if progress > 0 {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(progress == 1.0 ? Color.green.gradient : theme.primary.gradient)
                            .frame(width: max(8, geometry.size.width * progress), height: 8)
                            .overlay(
                                // End cap indicator
                                RoundedRectangle(cornerRadius: 8)
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
        taskId: nil,
        isQuickListFocused: .constant(false)
    )
    .environmentObject(TaskManager())
    .environment(\.theme, ThemeManager().currentTheme)
}