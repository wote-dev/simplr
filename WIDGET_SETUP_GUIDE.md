# Simplr Widget Setup Guide

I've created all the necessary files for your Simplr widget that shows the top 3 upcoming tasks. Follow these steps to add the widget extension to your Xcode project:

## Files Created

- `SimplrWidget/SimplrWidget.swift` - Main widget implementation
- `SimplrWidget/SimplrWidgetBundle.swift` - Widget bundle registration
- `SimplrWidget/Task+Widget.swift` - Shared Task model for widget
- `SimplrWidget/Info.plist` - Widget extension Info.plist
- `SimplrWidget/SimplrWidget.entitlements` - Widget entitlements for App Groups
- `Simplr/Simplr.entitlements` - Main app entitlements for App Groups
- `Simplr/TaskManager.swift` - Updated to use App Groups for data sharing

## Setup Instructions

### Step 1: Add Widget Extension Target

1. Open `Simplr.xcodeproj` in Xcode
2. Select your project in the navigator
3. Click the "+" button at the bottom of the targets list
4. Choose "Widget Extension" from the template list
5. Configure the extension:
   - Product Name: `SimplrWidget`
   - Bundle Identifier: `blackcubesolutions.Simplr.SimplrWidget`
   - Language: Swift
   - Use Core Data: No
   - Include Configuration Intent: No
6. Click "Finish"
7. When prompted about activating the scheme, click "Activate"

### Step 2: Replace Generated Files

1. Delete the auto-generated widget files in the `SimplrWidget` folder
2. Add the files I created in the `SimplrWidget` folder to your widget target:
   - Right-click on `SimplrWidget` folder in Xcode
   - Choose "Add Files to 'Simplr'"
   - Select all files from the `SimplrWidget` folder
   - Make sure "SimplrWidget" target is checked
   - Click "Add"

### Step 3: Configure App Groups

1. Select your main app target (`Simplr`)
2. Go to "Signing & Capabilities" tab
3. Click "+" and add "App Groups" capability
4. Add group: `group.com.danielzverev.simplr`
5. Select your widget target (`SimplrWidget`)
6. Go to "Signing & Capabilities" tab
7. Click "+" and add "App Groups" capability
8. Add the same group: `group.com.danielzverev.simplr`

### Step 4: Add Entitlements Files

1. Add `Simplr.entitlements` to your main app target
2. Add `SimplrWidget.entitlements` to your widget target
3. In target settings, set the "Code Signing Entitlements" build setting to point to the respective entitlements files

### Step 5: Update Build Settings

For the widget target, ensure these settings:
- iOS Deployment Target: 14.0 or later
- Swift Language Version: Swift 5
- Product Bundle Identifier: `blackcubesolutions.Simplr.SimplrWidget`

### Step 6: Test the Widget

1. Build and run your app
2. Add some tasks with due dates
3. On your device/simulator, long-press on the home screen
4. Tap the "+" button to add widgets
5. Search for "Simplr" and add the widget

## Widget Features

✅ **Clean, Modern Design**: Rounded corners and elegant typography
✅ **Dark/Light Mode Support**: Automatically adapts to system appearance
✅ **Top 3 Tasks**: Shows your most important upcoming tasks
✅ **Smart Sorting**: Tasks with due dates are prioritized
✅ **Due Date Display**: Shows "Today", "Tomorrow", or specific dates
✅ **Overdue Indicators**: Red indicators for overdue tasks
✅ **Empty State**: Beautiful "All caught up!" message when no tasks
✅ **Data Sharing**: Uses App Groups to share data between app and widget

## Troubleshooting

- **Widget not updating**: Make sure App Groups are configured correctly
- **Data not showing**: Verify the App Group identifier matches in both targets
- **Build errors**: Ensure all files are added to the correct targets
- **Widget not appearing**: Check that the widget extension is properly configured

The widget will automatically update every hour and whenever you modify tasks in the main app.