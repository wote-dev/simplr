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
    case kawaii = "kawaii"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        case .kawaii: return "Kawaii"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        case .kawaii: return "heart.fill"
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .light, .dark, .system:
            return false
        case .kawaii:
            return true
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
    
    // Premium manager reference
    var premiumManager: PremiumManager?
    
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
    
    // Removed duplicate setThemeMode method - using the one with checkPremium parameter below
    
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
            case .kawaii:
                // Toggle from Kawaii to light theme
                themeMode = .light
            }
        }
    }
    
    func updateTheme() {
        let newTheme: Theme
        
        switch themeMode {
        case .light:
            newTheme = LightTheme()
        case .dark:
            newTheme = DarkTheme()
        case .system:
            newTheme = isDarkMode ? DarkTheme() : LightTheme()
        case .kawaii:
            // Check if user has access to Kawaii theme
            if let premiumManager = premiumManager,
               premiumManager.hasAccess(to: .kawaiiTheme) {
                newTheme = KawaiiTheme()
            } else {
                // Fallback to light theme if no access
                newTheme = LightTheme()
                // Reset theme mode to light
                DispatchQueue.main.async {
                    self.themeMode = .light
                }
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = newTheme
        }
    }
    
    // MARK: - Premium Theme Management
    
    func setPremiumManager(_ manager: PremiumManager) {
        self.premiumManager = manager
    }
    
    func setThemeMode(_ mode: ThemeMode, checkPremium: Bool = true) {
        // Check if theme requires premium access
        if checkPremium && mode.isPremium {
            guard let premiumManager = premiumManager,
                  premiumManager.hasAccess(to: .kawaiiTheme) else {
                // Show paywall for premium theme
                premiumManager?.showPaywall(for: .kawaiiTheme)
                return
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            themeMode = mode
        }
    }
    
    func canAccessTheme(_ mode: ThemeMode) -> Bool {
        if !mode.isPremium {
            return true
        }
        
        guard let premiumManager = premiumManager else {
            return false
        }
        
        switch mode {
        case .kawaii:
            return premiumManager.hasAccess(to: .kawaiiTheme)
        default:
            return true
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