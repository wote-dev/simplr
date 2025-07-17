# App Icon Badge Implementation

## Overview

This document outlines the comprehensive app icon badge implementation for the Simplr task management app, following Apple's latest iOS guidelines and best practices for performance optimization.

## Features Implemented

### 🎯 Core Badge Functionality

- **Smart Badge Counting**: Displays pending tasks that are overdue, due today, due tomorrow, or have no due date
- **User Control**: Toggle badge display on/off in Settings
- **Performance Optimized**: Throttled updates, caching, and efficient calculations
- **iOS Compatibility**: Uses modern iOS 16+ APIs with fallback to legacy methods
- **Persistent Settings**: Badge preference saved to UserDefaults

### 📱 iOS Guidelines Compliance

- **Badge Count Cap**: Limited to 99 following iOS conventions
- **Automatic Clearing**: Badge cleared when disabled or no pending tasks
- **Permission Handling**: Proper notification authorization for badge access
- **App Lifecycle Integration**: Updates on app activation and background transitions

## Technical Implementation

### BadgeManager Class

```swift
@MainActor
class BadgeManager: ObservableObject {
    static let shared = BadgeManager()
    @Published var isBadgeEnabled: Bool
    // ... implementation details
}
```

#### Key Features:

- **Singleton Pattern**: Centralized badge management
- **ObservableObject**: SwiftUI reactive updates
- **MainActor**: Thread-safe UI updates
- **Throttling**: Prevents excessive badge updates (1-second interval)
- **Logging**: Comprehensive logging for debugging

### Badge Calculation Logic

The badge count includes:

1. **Overdue tasks** (past due date, not completed)
2. **Tasks due today** (same day as current date)
3. **Tasks due tomorrow** (next day for better awareness)
4. **Tasks without due dates** (considered pending)

**Excluded from count:**

- Completed tasks
- Tasks due more than 1 day in the future

### Performance Optimizations

#### 1. Update Throttling

```swift
private let updateThrottleInterval: TimeInterval = 1.0
```

Prevents rapid successive badge updates that could impact performance.

#### 2. Change Detection

```swift
guard badgeCount != lastBadgeCount else { return }
```

Only updates badge when count actually changes.

#### 3. Async Task Management

```swift
private var pendingUpdate: Task<Void, Never>?
```

Cancels pending updates when new ones are requested.

#### 4. Modern API Usage

```swift
if #available(iOS 16.0, *) {
    UNUserNotificationCenter.current().setBadgeCount(number) { ... }
} else {
    UIApplication.shared.applicationIconBadgeNumber = number
}
```

Uses latest iOS 16+ badge APIs with legacy fallback.

## Integration Points

### 1. TaskManager Integration

```swift
class TaskManager {
    private let badgeManager = BadgeManager.shared

    func addTask(_ task: Task) {
        // ... add task logic
        badgeManager.updateBadge(with: tasks)
    }

    func deleteTask(_ task: Task) {
        // ... delete task logic
        badgeManager.updateBadge(with: tasks)
    }
}
```

### 2. Settings Integration

```swift
struct SettingsView: View {
    @EnvironmentObject var taskManager: TaskManager

    var body: some View {
        Toggle("Badge Count", isOn: $taskManager.badgeManagerInstance.isBadgeEnabled)
    }
}
```

### 3. App Lifecycle Integration

```swift
// SimplrApp.swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
    taskManager.performMaintenanceTasks() // Includes badge update
}
```

## Usage Examples

### Manual Badge Update

```swift
// Force immediate badge update
badgeManager.forceUpdateBadge(with: allTasks)

// Standard throttled update
badgeManager.updateBadge(with: allTasks)

// Clear badge
badgeManager.clearBadge()
```

### Settings Control

```swift
// Enable/disable badge
badgeManager.isBadgeEnabled = true

// Check current state
if badgeManager.isBadgeEnabled {
    // Badge is enabled
}
```

## Testing

The implementation includes comprehensive unit tests in `BadgeManagerTests.swift`:

- **Badge Count Calculation**: Verifies correct counting logic
- **Badge Disabling**: Tests clearing when disabled
- **Badge Cap**: Ensures 99-item limit
- **Edge Cases**: Various task scenarios

## Best Practices Followed

### 1. Performance

- ✅ Throttled updates to prevent excessive calls
- ✅ Change detection to avoid unnecessary updates
- ✅ Async task cancellation for pending updates
- ✅ Efficient task filtering algorithms

### 2. User Experience

- ✅ User-controllable badge display
- ✅ Persistent settings across app launches
- ✅ Immediate feedback when toggling settings
- ✅ Smart task prioritization (overdue, today, tomorrow)

### 3. iOS Guidelines

- ✅ Proper notification permission handling
- ✅ Modern API usage with legacy fallback
- ✅ Badge count capped at 99
- ✅ App lifecycle integration

### 4. Code Quality

- ✅ Comprehensive logging for debugging
- ✅ Thread-safe implementation with @MainActor
- ✅ Clean separation of concerns
- ✅ Extensive unit test coverage

## Troubleshooting

### Badge Not Updating

1. Check notification permissions in Settings > Notifications > Simplr
2. Verify `isBadgeEnabled` is true
3. Check console logs for BadgeManager messages
4. Ensure tasks have proper due dates

### Performance Issues

1. Badge updates are throttled to 1-second intervals
2. Large task lists are handled efficiently
3. Updates only occur when count changes

### Settings Not Persisting

1. Badge preference is saved to UserDefaults automatically
2. Default value is `true` for new installations
3. Settings sync across app launches

## Future Enhancements

### Potential Improvements

- **Custom Badge Rules**: User-defined criteria for badge counting
- **Category-Specific Badges**: Different badge logic per task category
- **Time-Based Updates**: Automatic updates at midnight for date changes
- **Widget Integration**: Sync badge count with home screen widgets

## Conclusion

This badge implementation provides a robust, performant, and user-friendly solution that follows Apple's latest guidelines while maintaining excellent performance characteristics. The modular design allows for easy maintenance and future enhancements.
