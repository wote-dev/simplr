//
//  SimplrApp.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import UserNotifications

@main
struct SimplrApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var taskManager = TaskManager()
    @StateObject private var categoryManager = CategoryManager()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "HasCompletedOnboarding")
    
    init() {
        // Request notification permissions on app launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SystemAwareWrapper {
                ZStack {
                    if showOnboarding {
                        OnboardingView(showOnboarding: $showOnboarding)
                            .themedEnvironment(themeManager)
                            .transition(.asymmetric(
                                insertion: .identity,
                                removal: .opacity.combined(with: .scale(scale: 0.95))
                            ))
                    } else {
                        MainTabView()
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
                }
                .onAppear {
                    // Perform initial cleanup when app starts
                    taskManager.performMaintenanceTasks()
                }
            }
            .environmentObject(themeManager)
            .environmentObject(taskManager)
            .environmentObject(categoryManager)
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch themeManager.themeMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
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
            .onChange(of: systemColorScheme) { _, newColorScheme in
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
