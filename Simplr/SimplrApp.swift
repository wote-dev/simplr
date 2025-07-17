//
//  SimplrApp.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import UserNotifications
import CoreSpotlight
import UIKit

@main
struct SimplrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var taskManager = TaskManager()
    @StateObject private var categoryManager = CategoryManager()
    @StateObject private var premiumManager = PremiumManager()
    // Celebration manager removed
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "HasCompletedOnboarding")
    @State private var showThemeSelection = false
    @State private var selectedTaskId: UUID? = nil
    @State private var quickActionTriggered: QuickAction? = nil
    
    // Quick Action types
    enum QuickAction: String {
        case addTask = "AddTask"
        case viewToday = "ViewToday"
    }
    
    init() {
        // Request notification permissions on app launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permissions granted: \(granted)")
                // Badge will be initialized when TaskManager loads tasks
            }
        }
        
        // Set up Home screen quick actions
        setupQuickActions()
    }
    
    var body: some Scene {
        WindowGroup {
            SystemAwareWrapper {
                ZStack {
                    if showOnboarding {
                        OnboardingView(showOnboarding: $showOnboarding, showThemeSelection: $showThemeSelection)
                            .themedEnvironment(themeManager)
                            .transition(.asymmetric(
                                insertion: .identity,
                                removal: .opacity.combined(with: .scale(scale: 0.95))
                            ))
                    } else if showThemeSelection {
                        ThemeSelectionOnboardingView(showThemeSelection: $showThemeSelection)
                            .themedEnvironment(themeManager)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 1.05)),
                                removal: .opacity.combined(with: .scale(scale: 0.95))
                            ))
                    } else {
                        MainTabView(
                            selectedTaskId: $selectedTaskId,
                            quickActionTriggered: $quickActionTriggered
                        )
                            .themedEnvironment(themeManager)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 1.05)),
                                removal: .identity
                            ))
                    }
                }
                .preferredColorScheme(colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Perform maintenance tasks when app becomes active
                    taskManager.performMaintenanceTasks()
                    
                    // App became active
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // App going to background
                }
                .onReceive(NotificationCenter.default.publisher(for: .quickActionTriggered)) { notification in
                    // Handle quick action triggered from AppDelegate
                    if let shortcutItem = notification.object as? UIApplicationShortcutItem {
                        handleQuickAction(shortcutItem)
                    }
                }
                .onAppear {
                    // Set up Spotlight integration
                    taskManager.setCategoryManager(categoryManager)
                    // Connect premium manager with theme manager
                    themeManager.setPremiumManager(premiumManager)
                    // Perform initial cleanup when app starts
                    taskManager.performMaintenanceTasks()
                    
                    // Handle quick action if app was launched via quick action
                    handleLaunchQuickAction()
                }
                .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                    handleSpotlightSearchResult(userActivity)
                }
            }
            .environmentObject(themeManager)
            .environmentObject(taskManager)
            .environmentObject(categoryManager)
            .environmentObject(premiumManager)
            // Celebration manager environment object removed
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch themeManager.themeMode {
        case .light:
            return .light
        case .lightBlue:
            return .light // Light Blue theme uses light color scheme
        case .dark:
            return .dark
        case .system:
            return nil
        case .kawaii:
            return .light // Kawaii theme uses light color scheme
        }
    }
    
    // MARK: - Quick Actions Setup
    
    private func setupQuickActions() {
        let application = UIApplication.shared
        
        let addTaskAction = UIApplicationShortcutItem(
            type: QuickAction.addTask.rawValue,
            localizedTitle: "Add Task",
            localizedSubtitle: "Create a new task",
            icon: UIApplicationShortcutIcon(systemImageName: "plus.circle.fill"),
            userInfo: nil
        )
        
        let viewTodayAction = UIApplicationShortcutItem(
            type: QuickAction.viewToday.rawValue,
            localizedTitle: "View Today",
            localizedSubtitle: "See today's tasks",
            icon: UIApplicationShortcutIcon(systemImageName: "sun.max.fill"),
            userInfo: nil
        )
        
        application.shortcutItems = [addTaskAction, viewTodayAction]
    }
    
    // MARK: - Quick Action Handling
    
    private func handleLaunchQuickAction() {
        // Check if app was launched via quick action
        if let shortcutItem = appDelegate.launchShortcutItem {
            handleQuickAction(shortcutItem)
            // Clear the launch shortcut item to prevent repeated handling
            appDelegate.launchShortcutItem = nil
        }
    }
    
    private func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) {
        guard let action = QuickAction(rawValue: shortcutItem.type) else { return }
        
        // Dismiss onboarding and theme selection if showing
        if showOnboarding {
            showOnboarding = false
            // Complete onboarding when quick action is triggered
            UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
        }
        if showThemeSelection {
            showThemeSelection = false
        }
        
        // Add haptic feedback
        HapticManager.shared.buttonTap()
        
        // Set the triggered action
        quickActionTriggered = action
        
        print("Quick action triggered: \(action.rawValue)")
    }
    

    
    // MARK: - Spotlight Search Result Handling
    
    private func handleSpotlightSearchResult(_ userActivity: NSUserActivity) {
        // Dismiss onboarding and theme selection if showing
        if showOnboarding {
            showOnboarding = false
            // Complete onboarding when spotlight search is triggered
            UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
        }
        if showThemeSelection {
            showThemeSelection = false
        }
        
        guard let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              let taskId = SpotlightManager.taskId(from: uniqueIdentifier) else {
            print("Unable to extract task ID from Spotlight search result")
            return
        }
        
        // Check if the task still exists
        guard taskManager.task(with: taskId) != nil else {
            print("Task with ID \(taskId) no longer exists")
            // Optionally show an alert to the user
            return
        }
        
        // Store the selected task ID for navigation
        selectedTaskId = taskId
        
        // Add haptic feedback for spotlight navigation
        HapticManager.shared.buttonTap()
        
        print("Opening task from Spotlight: \(taskId)")
    }
}

// MARK: - System Aware Wrapper
struct SystemAwareWrapper<Content: View>: View {
    @Environment(\.colorScheme) var systemColorScheme
    @EnvironmentObject var themeManager: ThemeManager
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .onChange(of: systemColorScheme) { oldColorScheme, newColorScheme in
                // Update theme manager when system appearance changes
                let newIsDarkMode = newColorScheme == .dark
                if themeManager.isDarkMode != newIsDarkMode {
                    themeManager.isDarkMode = newIsDarkMode
                    if themeManager.themeMode == .system {
                        themeManager.updateTheme()
                    }
                }
            }
            .onAppear {
                // Set initial system appearance
                let newIsDarkMode = systemColorScheme == .dark
                themeManager.isDarkMode = newIsDarkMode
                if themeManager.themeMode == .system {
                    themeManager.updateTheme()
                }
            }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    var launchShortcutItem: UIApplicationShortcutItem?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Check if app was launched via shortcut
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchShortcutItem = shortcutItem
        }
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        // Handle quick action when app is already running
        handleQuickActionFromDelegate(shortcutItem)
        completionHandler(true)
    }
    
    private func handleQuickActionFromDelegate(_ shortcutItem: UIApplicationShortcutItem) {
        // Post notification to be handled by the main app
        NotificationCenter.default.post(
            name: .quickActionTriggered,
            object: shortcutItem
        )
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let quickActionTriggered = Notification.Name("quickActionTriggered")
}
