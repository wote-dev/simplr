//
//  WidgetThemeManager.swift
//  SimplrWidget
//
//  Created by AI Assistant on 2025-02-07.
//

import SwiftUI

// MARK: - Widget Theme Manager
class WidgetThemeManager {
    static let shared = WidgetThemeManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr")
    private let themeModeKey = "ThemeMode"
    
    private var cachedTheme: WidgetTheme?
    private var lastThemeCheck: Date = .distantPast
    private let cacheTimeout: TimeInterval = 2.0 // 2 second cache for system theme responsiveness while maintaining performance
    
    private init() {}
    
    func currentTheme() -> WidgetTheme {
        let now = Date()
        
        // Return cached theme if still valid
        if let cached = cachedTheme, now.timeIntervalSince(lastThemeCheck) < cacheTimeout {
            return cached
        }
        
        // Determine current theme mode
        let savedMode = userDefaults?.string(forKey: themeModeKey) ?? "system"
        let themeMode = WidgetThemeMode(rawValue: savedMode) ?? .system
        
        // Check system dark mode
        let isDarkMode = isSystemDarkMode()
        
        // Create appropriate theme
        let theme: WidgetTheme
        switch themeMode {
        case .light:
            theme = WidgetLightTheme()
        case .lightBlue:
            theme = WidgetLightBlueTheme()
        case .lightGreen:
            theme = WidgetLightGreenTheme()
        case .minimal:
            theme = WidgetMinimalTheme()
        case .dark:
            theme = WidgetDarkTheme()
        case .darkBlue:
            theme = WidgetDarkBlueTheme()
        case .system:
            theme = isDarkMode ? WidgetDarkTheme() : WidgetLightTheme()
        case .kawaii:
            theme = WidgetKawaiiTheme()
        case .serene:
            theme = WidgetSereneTheme()
        case .coffee:
            theme = WidgetCoffeeTheme()
        }
        
        cachedTheme = theme
        lastThemeCheck = now
        
        return theme
    }
    
    private func isSystemDarkMode() -> Bool {
        // Widgets can't directly access system appearance, so we'll use a shared preference
        // The main app should set this value when theme changes
        return userDefaults?.bool(forKey: "SystemDarkMode") ?? false
    }
    
    func invalidateCache() {
        cachedTheme = nil
    }
}

// MARK: - Widget Theme Mode
enum WidgetThemeMode: String, CaseIterable {
    case light = "light"
    case lightBlue = "lightBlue"
    case lightGreen = "lightGreen"
    case minimal = "minimal"
    case dark = "dark"
    case darkBlue = "darkBlue"

    case system = "system"
    case kawaii = "kawaii"
    case serene = "serene"
    case coffee = "coffee"
}

// MARK: - Widget Theme Protocol
protocol WidgetTheme {
    var backgroundColor: Color { get }
    var surfaceColor: Color { get }
    var primaryTextColor: Color { get }
    var secondaryTextColor: Color { get }
    var accentColor: Color { get }
    var successColor: Color { get }
    var warningColor: Color { get }
    var errorColor: Color { get }
    var borderColor: Color { get }
    var shadowColor: Color { get }
    
    var backgroundGradient: LinearGradient { get }
    var surfaceGradient: LinearGradient { get }
    
    var cornerRadius: CGFloat { get }
    var shadowRadius: CGFloat { get }
    var shadowOpacity: Double { get }
}

// MARK: - Base Widget Theme Implementation
struct WidgetBaseTheme {
    static let cornerRadius: CGFloat = 12
    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: Double = 0.1
}

// MARK: - Widget Theme Implementations

// MARK: - Widget Light Theme
struct WidgetLightTheme: WidgetTheme {
    let backgroundColor = Color(red: 0.98, green: 0.98, blue: 0.98)
    let surfaceColor = Color(red: 0.92, green: 0.92, blue: 0.92)
    let primaryTextColor = Color.black
    let secondaryTextColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    let accentColor = Color(red: 0.2, green: 0.6, blue: 0.85)
    let successColor = Color(red: 0.2, green: 0.8, blue: 0.2)
    let warningColor = Color(red: 1.0, green: 0.7, blue: 0.0)
    let errorColor = Color(red: 0.9, green: 0.2, blue: 0.2)
    let borderColor = Color(red: 0.75, green: 0.75, blue: 0.75).opacity(0.6)
    let shadowColor = Color.black.opacity(0.15)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundColor, Color(red: 0.96, green: 0.96, blue: 0.96)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.93, green: 0.93, blue: 0.93), Color(red: 0.91, green: 0.91, blue: 0.91)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cornerRadius: CGFloat { WidgetBaseTheme.cornerRadius }
    var shadowRadius: CGFloat { WidgetBaseTheme.shadowRadius }
    var shadowOpacity: Double { WidgetBaseTheme.shadowOpacity }
}

// MARK: - Widget Dark Theme
struct WidgetDarkTheme: WidgetTheme {
    let backgroundColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    let surfaceColor = Color(red: 0.18, green: 0.18, blue: 0.18)
    let primaryTextColor = Color.white
    let secondaryTextColor = Color(red: 0.7, green: 0.7, blue: 0.7)
    let accentColor = Color(red: 0.4, green: 0.6, blue: 0.9)
    let successColor = Color(red: 0.3, green: 0.8, blue: 0.3)
    let warningColor = Color(red: 1.0, green: 0.7, blue: 0.3)
    let errorColor = Color(red: 1.0, green: 0.4, blue: 0.4)
    let borderColor = Color(red: 0.3, green: 0.3, blue: 0.3)
    let shadowColor = Color.black.opacity(0.3)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundColor, Color(red: 0.1, green: 0.1, blue: 0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [surfaceColor, Color(red: 0.16, green: 0.16, blue: 0.16)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cornerRadius: CGFloat { WidgetBaseTheme.cornerRadius }
    var shadowRadius: CGFloat { WidgetBaseTheme.shadowRadius }
    var shadowOpacity: Double { WidgetBaseTheme.shadowOpacity }
}

// MARK: - Widget Minimal Theme
struct WidgetMinimalTheme: WidgetTheme {
    let backgroundColor = Color.white
    let surfaceColor = Color.white
    let primaryTextColor = Color.black
    let secondaryTextColor = Color.gray.opacity(0.7)
    let accentColor = Color.black
    let successColor = Color.green
    let warningColor = Color.orange
    let errorColor = Color.red
    let borderColor = Color.gray.opacity(0.2)
    let shadowColor = Color.clear
    
    var backgroundGradient: LinearGradient {
        LinearGradient(colors: [backgroundColor, backgroundColor], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(colors: [surfaceColor, surfaceColor], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var cornerRadius: CGFloat { 8 }
    var shadowRadius: CGFloat { 0 }
    var shadowOpacity: Double { 0 }
}

// MARK: - Widget Kawaii Theme
struct WidgetKawaiiTheme: WidgetTheme {
    let backgroundColor = Color(red: 0.97, green: 0.94, blue: 0.92)
    let surfaceColor = Color(red: 0.92, green: 0.88, blue: 0.86)
    let primaryTextColor = Color(red: 0.15, green: 0.05, blue: 0.1)
    let secondaryTextColor = Color(red: 0.35, green: 0.25, blue: 0.3)
    let accentColor = Color(red: 0.85, green: 0.45, blue: 0.55)
    let successColor = Color(red: 0.85, green: 0.45, blue: 0.55)
    let warningColor = Color(red: 1.0, green: 0.85, blue: 0.6)
    let errorColor = Color(red: 1.0, green: 0.71, blue: 0.76)
    let borderColor = Color(red: 0.85, green: 0.75, blue: 0.78).opacity(0.8)
    let shadowColor = Color(red: 0.98, green: 0.85, blue: 0.88).opacity(0.2)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundColor, Color(red: 0.95, green: 0.92, blue: 0.90)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.93, green: 0.89, blue: 0.87), Color(red: 0.91, green: 0.87, blue: 0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cornerRadius: CGFloat { 16 }
    var shadowRadius: CGFloat { 10 }
    var shadowOpacity: Double { 0.15 }
}

// MARK: - Additional Widget Themes
struct WidgetLightBlueTheme: WidgetTheme {
    let backgroundColor = Color(red: 0.95, green: 0.97, blue: 1.0)
    let surfaceColor = Color(red: 0.9, green: 0.93, blue: 0.97)
    let primaryTextColor = Color(red: 0.1, green: 0.2, blue: 0.4)
    let secondaryTextColor = Color(red: 0.3, green: 0.4, blue: 0.6)
    let accentColor = Color(red: 0.2, green: 0.5, blue: 0.9)
    let successColor = Color(red: 0.2, green: 0.8, blue: 0.4)
    let warningColor = Color(red: 1.0, green: 0.7, blue: 0.2)
    let errorColor = Color(red: 0.9, green: 0.3, blue: 0.3)
    let borderColor = Color.blue.opacity(0.2)
    let shadowColor = Color.blue.opacity(0.1)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundColor, Color(red: 0.92, green: 0.95, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [surfaceColor, Color(red: 0.87, green: 0.91, blue: 0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cornerRadius: CGFloat { WidgetBaseTheme.cornerRadius }
    var shadowRadius: CGFloat { WidgetBaseTheme.shadowRadius }
    var shadowOpacity: Double { WidgetBaseTheme.shadowOpacity }
}

struct WidgetLightGreenTheme: WidgetTheme {
    let backgroundColor = Color(red: 0.98, green: 1.0, blue: 0.99)
    let surfaceColor = Color(red: 0.93, green: 0.97, blue: 0.95)
    let primaryTextColor = Color(red: 0.05, green: 0.15, blue: 0.1)
    let secondaryTextColor = Color(red: 0.25, green: 0.45, blue: 0.35)
    let accentColor = Color(red: 0.2, green: 0.7, blue: 0.6)
    let successColor = Color(red: 0.2, green: 0.8, blue: 0.4)
    let warningColor = Color(red: 1.0, green: 0.6, blue: 0.0)
    let errorColor = Color(red: 0.9, green: 0.3, blue: 0.3)
    let borderColor = Color(red: 0.7, green: 0.9, blue: 0.8).opacity(0.7)
    let shadowColor = Color(red: 0.2, green: 0.7, blue: 0.6).opacity(0.12)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundColor, Color(red: 0.95, green: 1.0, blue: 0.97)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [surfaceColor, Color(red: 0.91, green: 0.95, blue: 0.93)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cornerRadius: CGFloat { WidgetBaseTheme.cornerRadius }
    var shadowRadius: CGFloat { WidgetBaseTheme.shadowRadius }
    var shadowOpacity: Double { WidgetBaseTheme.shadowOpacity }
}

struct WidgetDarkBlueTheme: WidgetTheme {
    let backgroundColor = Color(red: 0.08, green: 0.1, blue: 0.15)
    let surfaceColor = Color(red: 0.12, green: 0.15, blue: 0.22)
    let primaryTextColor = Color(red: 0.9, green: 0.92, blue: 0.95)
    let secondaryTextColor = Color(red: 0.7, green: 0.75, blue: 0.8)
    let accentColor = Color(red: 0.4, green: 0.6, blue: 0.9)
    let successColor = Color(red: 0.3, green: 0.8, blue: 0.3)
    let warningColor = Color(red: 1.0, green: 0.7, blue: 0.3)
    let errorColor = Color(red: 1.0, green: 0.4, blue: 0.4)
    let borderColor = Color.blue.opacity(0.3)
    let shadowColor = Color.black.opacity(0.4)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundColor, Color(red: 0.06, green: 0.08, blue: 0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [surfaceColor, Color(red: 0.1, green: 0.13, blue: 0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cornerRadius: CGFloat { WidgetBaseTheme.cornerRadius }
    var shadowRadius: CGFloat { WidgetBaseTheme.shadowRadius }
    var shadowOpacity: Double { WidgetBaseTheme.shadowOpacity }
}



struct WidgetSereneTheme: WidgetTheme {
    let backgroundColor = Color(red: 0.95, green: 0.96, blue: 0.98)
    let surfaceColor = Color(red: 0.9, green: 0.92, blue: 0.95)
    let primaryTextColor = Color(red: 0.2, green: 0.25, blue: 0.35)
    let secondaryTextColor = Color(red: 0.4, green: 0.45, blue: 0.55)
    let accentColor = Color(red: 0.5, green: 0.6, blue: 0.7)
    let successColor = Color(red: 0.4, green: 0.7, blue: 0.5)
    let warningColor = Color(red: 0.9, green: 0.7, blue: 0.4)
    let errorColor = Color(red: 0.8, green: 0.4, blue: 0.4)
    let borderColor = Color(red: 0.8, green: 0.82, blue: 0.85)
    let shadowColor = Color.gray.opacity(0.1)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundColor, Color(red: 0.92, green: 0.94, blue: 0.96)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [surfaceColor, Color(red: 0.87, green: 0.9, blue: 0.93)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cornerRadius: CGFloat { 14 }
    var shadowRadius: CGFloat { 6 }
    var shadowOpacity: Double { 0.08 }
}

struct WidgetCoffeeTheme: WidgetTheme {
    let backgroundColor = Color(red: 0.94, green: 0.91, blue: 0.87)
    let surfaceColor = Color(red: 0.89, green: 0.85, blue: 0.8)
    let primaryTextColor = Color(red: 0.25, green: 0.2, blue: 0.15)
    let secondaryTextColor = Color(red: 0.45, green: 0.4, blue: 0.35)
    let accentColor = Color(red: 0.6, green: 0.4, blue: 0.2)
    let successColor = Color(red: 0.5, green: 0.7, blue: 0.4)
    let warningColor = Color(red: 0.9, green: 0.7, blue: 0.3)
    let errorColor = Color(red: 0.8, green: 0.4, blue: 0.3)
    let borderColor = Color(red: 0.7, green: 0.65, blue: 0.6)
    let shadowColor = Color.brown.opacity(0.15)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundColor, Color(red: 0.91, green: 0.88, blue: 0.84)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [surfaceColor, Color(red: 0.86, green: 0.82, blue: 0.77)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cornerRadius: CGFloat { 12 }
    var shadowRadius: CGFloat { 8 }
    var shadowOpacity: Double { 0.12 }
}