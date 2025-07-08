# Simplr Widget Setup Guide - Updated for iOS 17+

## Problem
The widget files exist but the **SimplrWidget target is missing** from your Xcode project configuration. This is why widgets don't appear in the widget gallery on your device.

## Solution: Add Widget Extension Target

### Step 1: Add Widget Extension Target in Xcode

1. **Open Simplr.xcodeproj in Xcode**
2. **Select your project** in the navigator (top-level "Simplr")
3. **Click the "+" button** at the bottom of the targets list
4. **Choose "Widget Extension"** from the template list
5. **Configure the widget extension:**
   - Product Name: `SimplrWidget`
   - Bundle Identifier: `blackcubesolutions.Simplr.SimplrWidget`
   - Language: Swift
   - Use Core Data: No
   - Include Configuration Intent: Yes
   - **IMPORTANT:** Uncheck "Include Live Activity"
6. **Click "Finish"**
7. **Choose "Activate"** when prompted about the scheme

### Step 2: Replace Auto-Generated Files

1. **Delete** the auto-generated widget files Xcode created in the SimplrWidget folder
2. **Add the existing widget files** to the SimplrWidget target:
   - Right-click SimplrWidget folder in Xcode
   - Choose "Add Files to 'Simplr'"
   - Select ALL files from your existing SimplrWidget folder:
     - `SimplrWidget.swift`
     - `SimplrWidgetBundle.swift`
     - `Task+Widget.swift`
     - `WidgetIntents.swift`
     - `Info.plist`
     - `SimplrWidget.entitlements`
   - **Important:** Make sure "SimplrWidget" target is checked
   - Click "Add"

### Step 3: Configure Target Settings

1. **Select SimplrWidget target** in project settings
2. **General tab:**
   - iOS Deployment Target: `16.0` or later
   - Bundle Identifier: `blackcubesolutions.Simplr.SimplrWidget`
   - Version: `1.0`
   - Build: `1`

3. **Build Settings tab:**
   - Product Bundle Identifier: `blackcubesolutions.Simplr.SimplrWidget`
   - Code Signing Entitlements: `SimplrWidget/SimplrWidget.entitlements`
   - Swift Language Version: `Swift 5`
   - iOS Deployment Target: `16.0`

4. **Signing & Capabilities tab:**
   - **Add App Groups capability**
   - Add group: `group.com.danielzverev.simplr`

### Step 4: Configure Main App Target

1. **Select Simplr target** in project settings
2. **Signing & Capabilities tab:**
   - **Add App Groups capability** (if not already present)
   - Add group: `group.com.danielzverev.simplr`
   - Set Code Signing Entitlements: `Simplr/Simplr.entitlements`

### Step 5: Verify File Targets

Ensure these files are added to the correct targets:

**SimplrWidget target should include:**
- SimplrWidget.swift
- SimplrWidgetBundle.swift
- Task+Widget.swift
- WidgetIntents.swift
- Info.plist
- SimplrWidget.entitlements

**Simplr target should include:**
- All main app files
- Simplr.entitlements

### Step 6: Build and Test

1. **Clean build folder** (Cmd+Shift+K)
2. **Build the project** (Cmd+B)
3. **Run on device** (not simulator for best results)
4. **Test widget:**
   - Long-press on home screen
   - Tap "+" button
   - Search for "Simplr"
   - Add the widget in desired size

## Widget Features (iOS 17+ Compatible)

✅ **Small Widget:** Shows next upcoming task with interactive completion button
✅ **Medium Widget:** Shows today's tasks (up to 3) with category indicators
✅ **Large Widget:** Shows week overview with daily task counts
✅ **Lock Screen Widgets:** Circular, rectangular, and inline accessories
✅ **Interactive Elements:** Tap to complete tasks (iOS 17+)
✅ **App Intents:** Modern configuration and interaction system
✅ **Dark/Light Mode:** Automatic adaptation
✅ **Category Colors:** Proper color theming
✅ **Smart Refresh:** Updates every hour and when app data changes

## Troubleshooting

### Widget Not Appearing in Gallery
- Ensure SimplrWidget target builds successfully
- Verify bundle identifier is correct: `blackcubesolutions.Simplr.SimplrWidget`
- Check iOS deployment target is 16.0+
- Make sure App Groups are configured in both targets

### Build Errors
- Clean build folder (Cmd+Shift+K)
- Ensure all files are added to correct targets
- Verify entitlements files are properly set
- Check that App Groups match exactly: `group.com.danielzverev.simplr`

### Widget Not Updating
- Verify App Groups configuration
- Check that TaskManager and CategoryManager use the same App Group
- Ensure widget timeline is properly configured

### Data Not Showing
- Confirm App Group identifier matches in both main app and widget
- Verify UserDefaults suite name: `group.com.danielzverev.simplr`
- Check that tasks are being saved to shared UserDefaults

## Latest iOS Guidelines Compliance

This widget implementation follows the latest iOS guidelines:

- **iOS 17+ AppIntentConfiguration** for modern widget configuration
- **iOS 16+ IntentConfiguration** fallback for older devices
- **Interactive Elements** using App Intents framework
- **Proper Container Backgrounds** with `.containerBackground()` modifier
- **Accessibility Support** with proper labels and hints
- **Performance Optimized** with efficient timeline management
- **Privacy Compliant** with App Groups for secure data sharing

The widget will automatically update every hour and whenever you modify tasks in the main app.