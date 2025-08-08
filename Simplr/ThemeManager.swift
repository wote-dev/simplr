//
//  ThemeManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import Combine
import WidgetKit

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case light = "light"
    case lightBlue = "lightBlue"
    case lightGreen = "lightGreen"
    case minimal = "minimal"
    case dark = "dark"
    case darkBlue = "darkBlue"
    case darkPurple = "darkPurple"
    case system = "system"
    case kawaii = "kawaii"
    case serene = "serene"
    case coffee = "coffee"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .lightBlue: return "Light Blue"
        case .lightGreen: return "Light Green"
        case .minimal: return "Minimal"
        case .dark: return "Dark"
        case .darkBlue: return "Dark Blue"
        case .darkPurple: return "Dark Purple"
        case .system: return "System"
        case .kawaii: return "Kawaii"
        case .serene: return "Serene"
        case .coffee: return "Coffee"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .lightBlue: return "sun.max.circle.fill"
        case .lightGreen: return "leaf.fill"
        case .minimal: return "circle.fill"
        case .dark: return "moon.fill"
        case .darkBlue: return "moon.circle.fill"
        case .darkPurple: return "moon.stars.fill"
        case .system: return "circle.lefthalf.filled"
        case .kawaii: return "heart.fill"
        case .serene: return "cloud.fill"
        case .coffee: return "cup.and.saucer.fill"
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .light, .lightBlue, .minimal, .dark, .system:
            return false
        case .lightGreen, .darkBlue, .darkPurple, .kawaii, .serene, .coffee:
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
    var premiumManager: PremiumManager? {
        didSet {
            // Set up observation of premium status changes
            setupPremiumObservation()
        }
    }
    private var premiumObservationCancellable: AnyCancellable?
    
    init() {
        // Load saved theme mode or default to system
        let savedMode = userDefaults.string(forKey: themeModeKey) ?? ThemeMode.system.rawValue
        self.themeMode = ThemeMode(rawValue: savedMode) ?? .system
        
        // Initialize with plain light theme, will be updated in updateTheme()
        self.currentTheme = PlainLightTheme()
        
        // Set initial dark mode state
        #if os(iOS)
        self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        #else
        self.isDarkMode = false
        #endif
        
        // Update theme based on current mode
        updateTheme()
    }
    
    deinit {
        premiumObservationCancellable?.cancel()
    }
    
    // MARK: - Theme Management
    
    // Removed duplicate setThemeMode method - using the one with checkPremium parameter below
    
    func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch themeMode {
            case .light:
                themeMode = .lightBlue
            case .lightBlue:
                themeMode = .lightGreen
            case .lightGreen:
                themeMode = .serene
            case .serene:
                themeMode = .coffee
            case .coffee:
                themeMode = .minimal
            case .minimal:
                themeMode = .dark
            case .dark:
                themeMode = .darkBlue
            case .darkBlue:
                themeMode = .darkPurple
            case .darkPurple:
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
            newTheme = PlainLightTheme()
        case .lightBlue:
            newTheme = LightTheme()
        case .lightGreen:
            // Check if user has access to Light Green theme
            if let premiumManager = premiumManager,
               premiumManager.hasAccess(to: .premiumAccess) {
                newTheme = LightGreenTheme()
            } else {
                // Fallback to light theme if no access, but preserve the theme selection
                newTheme = PlainLightTheme()
            }
        case .serene:
            // Check if user has access to Serene theme
            if let premiumManager = premiumManager,
               premiumManager.hasAccess(to: .premiumAccess) {
                newTheme = SereneTheme()
            } else {
                // Fallback to light theme if no access, but preserve the theme selection
                newTheme = PlainLightTheme()
            }
        case .minimal:
            newTheme = MinimalTheme()
        case .dark:
            newTheme = DarkTheme()
        case .darkBlue:
            // Check if user has access to Dark Blue theme
            if let premiumManager = premiumManager,
               premiumManager.hasAccess(to: .premiumAccess) {
                newTheme = DarkBlueTheme()
            } else {
                // Fallback to dark theme if no access, but preserve the theme selection
                newTheme = DarkTheme()
            }
        case .darkPurple:
            // Check if user has access to Dark Purple theme
            if let premiumManager = premiumManager,
               premiumManager.hasAccess(to: .premiumAccess) {
                newTheme = DarkPurpleTheme()
            } else {
                // Fallback to dark theme if no access, but preserve the theme selection
                newTheme = DarkTheme()
            }
        case .system:
            newTheme = isDarkMode ? DarkTheme() : PlainLightTheme()
        case .kawaii:
            // Check if user has access to Kawaii theme
            if let premiumManager = premiumManager,
               premiumManager.hasAccess(to: .premiumAccess) {
                newTheme = KawaiiTheme()
            } else {
                // Fallback to light theme if no access, but preserve the kawaii theme selection
                // This allows the theme choice to persist when the user gains premium access
                newTheme = PlainLightTheme()
                // Don't reset the theme mode - keep it as kawaii so it persists
            }
        case .coffee:
            // Check if user has access to Coffee theme
            if let premiumManager = premiumManager,
               premiumManager.hasAccess(to: .premiumAccess) {
                newTheme = CoffeeTheme()
            } else {
                // Fallback to light theme if no access, but preserve the coffee theme selection
                // This allows the theme choice to persist when the user gains premium access
                newTheme = PlainLightTheme()
                // Don't reset the theme mode - keep it as coffee so it persists
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = newTheme
        }
    }
    
    // MARK: - Premium Theme Management
    
    func setPremiumManager(_ manager: PremiumManager) {
        self.premiumManager = manager
        // Refresh theme after premium manager is set to ensure proper access checking
        updateTheme()
    }
    
    private func setupPremiumObservation() {
        // Cancel any existing observation
        premiumObservationCancellable?.cancel()
        
        guard let premiumManager = premiumManager else { return }
        
        // Observe changes to premium status
        premiumObservationCancellable = premiumManager.$isPremium
            .sink { [weak self] _ in
                // When premium status changes, update the theme
                // This ensures premium themes are applied immediately when purchased
                DispatchQueue.main.async {
                    self?.updateTheme()
                }
            }
    }
    
    func setThemeMode(_ mode: ThemeMode, checkPremium: Bool = true) {
        // Check if theme requires premium access
        if checkPremium && mode.isPremium {
            guard let premiumManager = premiumManager else {
                return
            }
            
            let requiredFeature: PremiumFeature = .premiumAccess
            
            guard premiumManager.hasAccess(to: requiredFeature) else {
                // Show paywall for premium theme
                premiumManager.showPaywall()
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
        case .kawaii, .lightGreen, .darkBlue, .darkPurple, .serene, .coffee:
            return premiumManager.hasAccess(to: .premiumAccess)
        default:
            return true
        }
    }
    

    
    // MARK: - Persistence
    
    private func saveThemeMode() {
        userDefaults.set(themeMode.rawValue, forKey: themeModeKey)
        
        // Sync with widget via shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr") {
            sharedDefaults.set(themeMode.rawValue, forKey: "ThemeMode")
            
            // Also sync system dark mode state
            #if os(iOS)
            let isDark = UITraitCollection.current.userInterfaceStyle == .dark
            sharedDefaults.set(isDark, forKey: "SystemDarkMode")
            #endif
            
            // Force widget reload to pick up new theme
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

// MARK: - Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Theme = PlainLightTheme()
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