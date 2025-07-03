# Pending vs Overdue Task Implementation

## Overview

This document describes the implementation of clear differentiation between 'pending' and 'overdue' tasks in the Simplr iOS app.

## Problem Statement

Previously, the app grouped both future tasks and overdue tasks under the "pending" category, making it difficult for users to distinguish between:

- **Pending tasks**: Tasks with future due dates that haven't been completed yet
- **Overdue tasks**: Tasks with past due dates that haven't been completed yet

## Solution Implementation

### 1. Enhanced Task Model (`Task.swift`)

Added computed properties to the `Task` struct for better task status classification:

```swift
/// Returns true if the task is overdue (past due date and not completed)
var isOverdue: Bool {
    guard let dueDate = dueDate, !isCompleted else { return false }
    return dueDate < Date()
}

/// Returns true if the task is pending (has a future due date and not completed)
var isPending: Bool {
    guard let dueDate = dueDate, !isCompleted else { return false }
    return dueDate >= Date()
}

/// Returns true if the task is due today
var isDueToday: Bool {
    guard let dueDate = dueDate else { return false }
    return Calendar.current.isDateInToday(dueDate)
}

/// Returns true if the task is due in the future (tomorrow or later)
var isDueFuture: Bool {
    guard let dueDate = dueDate else { return false }
    let today = Date()
    let calendar = Calendar.current
    return dueDate > calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: today)!)
}

/// Returns the number of days until due date (negative if overdue)
var daysUntilDue: Int? {
    guard let dueDate = dueDate else { return nil }
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let due = calendar.startOfDay(for: dueDate)
    return calendar.dateComponents([.day], from: today, to: due).day
}
```

### 2. Enhanced TaskManager (`TaskManager.swift`)

Added computed properties for easy access to filtered task lists:

```swift
/// Returns all tasks that are overdue (past due date and not completed)
var overdueTasks: [Task] {
    return tasks.filter { $0.isOverdue }
}

/// Returns all tasks that are pending (future due date and not completed)
var pendingTasks: [Task] {
    return tasks.filter { $0.isPending }
}

/// Returns all tasks due today (including completed ones)
var todayTasks: [Task] {
    return tasks.filter { $0.isDueToday }
}

/// Returns all tasks due in the future (tomorrow or later, not completed)
var futureTasks: [Task] {
    return tasks.filter { $0.isDueFuture && !$0.isCompleted }
}

/// Returns all completed tasks
var completedTasks: [Task] {
    return tasks.filter { $0.isCompleted }
}

/// Returns all tasks without a due date that are not completed
var noDueDateTasks: [Task] {
    return tasks.filter { $0.dueDate == nil && !$0.isCompleted }
}
```

### 3. Updated TodayView (`TodayView.swift`)

**Statistics Cards:**

- Now shows three separate stats: "Pending", "Overdue", and "Completed"
- Pending count only includes non-completed, non-overdue tasks
- Overdue count shows tasks past their due date

**Task Sorting:**

- Prioritizes overdue tasks above pending tasks
- Maintains completion status as primary sorting criteria

### 4. Updated UpcomingView (`UpcomingView.swift`)

**Task Filtering:**

- Now explicitly shows only truly pending tasks (future due dates)
- Uses the new `isPending` and `isDueFuture` computed properties
- Updated header text to clarify "pending tasks" instead of "tasks scheduled"

### 5. Updated ContentView (`ContentView.swift`)

**Filter Options:**

- "Pending" filter now excludes overdue tasks: `return !task.isCompleted && !task.isOverdue`
- "Overdue" filter uses the new computed property: `return task.isOverdue`

### 6. Enhanced TaskRowView (`TaskRowView.swift`)

**Visual Indicators:**

- Different icons for overdue vs pending tasks:
  - Overdue: `exclamationmark.triangle.fill` (red error color)
  - Pending: `clock` (yellow warning color)
  - Regular: `calendar` (secondary text color)

**Status Labels:**

- Overdue tasks show "OVERDUE" badge in bold red
- Pending tasks (non-today) show "PENDING" badge in yellow
- Enhanced background colors and borders for better visual distinction

**Color Coding:**

- Overdue tasks: Red error color with stronger background and border
- Pending tasks: Yellow warning color with subtle background
- Regular tasks: Standard secondary colors

## Key Improvements

1. **Clear Semantic Distinction**: Tasks are now properly categorized based on their due date relationship to the current date.

2. **Visual Differentiation**: Users can immediately identify overdue vs pending tasks through:

   - Different icons
   - Color coding (red for overdue, yellow for pending)
   - Text labels ("OVERDUE" vs "PENDING")

3. **Better Information Architecture**:

   - Today view shows accurate counts for each category
   - Upcoming view focuses only on future tasks
   - Filter system properly separates concerns

4. **Improved Task Prioritization**: Overdue tasks are visually emphasized and sorted higher than pending tasks.

## User Benefits

- **Quick Visual Scanning**: Users can immediately identify which tasks need urgent attention (overdue) vs future planning (pending)
- **Better Task Management**: Clear separation helps users prioritize their workflow
- **Reduced Cognitive Load**: No need to mentally calculate if a task is overdue or pending
- **Enhanced Productivity**: Visual urgency indicators help focus on what needs immediate attention

## Technical Benefits

- **Maintainable Code**: Computed properties centralize the logic for task status determination
- **Consistent Logic**: All views use the same underlying classification system
- **Extensible**: Easy to add new task status categories in the future
- **Performance**: Computed properties are efficient and calculated on-demand
