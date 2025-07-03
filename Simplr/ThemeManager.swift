//
//  ThemeManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme
    @Published var themeMode: ThemeMode {
        didSet {
            saveThemeMode()
            updateTheme()
        }
    }
    
    @Published var isDarkMode: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let themeModeKey = "ThemeMode"
    
    init() {
        // Load saved theme mode or default to system
        let savedMode = userDefaults.string(forKey: themeModeKey) ?? ThemeMode.system.rawValue
        self.themeMode = ThemeMode(rawValue: savedMode) ?? .system
        
        // Initialize with light theme, will be updated in updateTheme()
        self.currentTheme = LightTheme()
        
        // Set initial dark mode state
        #if os(iOS)
        self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        #else
        self.isDarkMode = false
        #endif
        
        // Update theme based on current mode
        updateTheme()
    }
    
    // MARK: - Theme Management
    
    func setThemeMode(_ mode: ThemeMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            themeMode = mode
        }
    }
    
    func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch themeMode {
            case .light:
                themeMode = .dark
            case .dark:
                themeMode = .light
            case .system:
                // If in system mode, toggle to opposite of current appearance
                themeMode = isDarkMode ? .light : .dark
            }
        }
    }
    
    func updateTheme() {
        let shouldUseDarkTheme: Bool
        
        switch themeMode {
        case .light:
            shouldUseDarkTheme = false
        case .dark:
            shouldUseDarkTheme = true
        case .system:
            shouldUseDarkTheme = isDarkMode
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = shouldUseDarkTheme ? DarkTheme() : LightTheme()
        }
    }
    

    
    // MARK: - Persistence
    
    private func saveThemeMode() {
        userDefaults.set(themeMode.rawValue, forKey: themeModeKey)
    }
}

// MARK: - Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Theme = LightTheme()
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions
extension View {
    func themedEnvironment(_ themeManager: ThemeManager) -> some View {
        self.environment(\.theme, themeManager.currentTheme)
    }
}