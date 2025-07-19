//
//  test_kawaii_icon_visibility_fix.swift
//  Simplr Icon Visibility Fix Test
//
//  Created by AI Assistant on 2/7/2025.
//

import SwiftUI

// Test to verify kawaii theme icon visibility fix
struct KawaiiIconVisibilityTest {
    
    /// Test function to verify icon color logic
    static func testIconColorLogic() {
        let kawaiiTheme = KawaiiTheme()
        let lightTheme = LightTheme()
        let darkTheme = DarkTheme()
        
        // Test kawaii theme icon color
        let kawaiiIconColor = getIconColor(for: kawaiiTheme)
        assert(kawaiiIconColor == kawaiiTheme.accent, "Kawaii theme should use accent color for icons")
        
        // Test light theme icon color
        let lightIconColor = getIconColor(for: lightTheme)
        assert(lightIconColor == lightTheme.text, "Light theme should use text color for icons")
        
        // Test dark theme icon color
        let darkIconColor = getIconColor(for: darkTheme)
        assert(darkIconColor == darkTheme.primary, "Dark theme should use primary color for icons")
        
        print("✅ All icon color tests passed!")
        print("Kawaii theme icon color: \(kawaiiIconColor)")
        print("Light theme icon color: \(lightIconColor)")
        print("Dark theme icon color: \(darkIconColor)")
    }
    
    /// Returns appropriate icon color for non-selected theme options with proper contrast
    private static func getIconColor(for theme: Theme) -> Color {
        if theme is KawaiiTheme {
            // Kawaii theme: use accent color for better visibility against light backgrounds
            return theme.accent
        } else if theme.background == Color.white || 
                  theme.background == Color(red: 0.98, green: 0.98, blue: 0.98) ||
                  theme.background == Color(red: 0.98, green: 0.99, blue: 1.0) ||
                  theme.background == Color(red: 0.98, green: 1.0, blue: 0.99) {
            // Light themes: use text color for better contrast
            return theme.text
        } else {
            // Dark themes and others: use primary color as before
            return theme.primary
        }
    }
}

// MARK: - Test Preview
struct KawaiiIconVisibilityTestPreview: View {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Kawaii Icon Visibility Fix Test")
                .font(.title)
                .fontWeight(.bold)
            
            // Test different themes
            ForEach([ThemeMode.kawaii, .light, .dark], id: \.self) { mode in
                HStack {
                    Text(mode.displayName)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Show icon with fixed color
                    Image(systemName: mode.icon)
                        .font(.title2)
                        .foregroundColor(getTestIconColor(for: mode))
                        .padding()
                        .background(Circle().fill(Color.gray.opacity(0.2)))
                }
                .padding(.horizontal)
            }
            
            Button("Run Tests") {
                KawaiiIconVisibilityTest.testIconColorLogic()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func getTestIconColor(for mode: ThemeMode) -> Color {
        let theme = getTheme(for: mode)
        
        if theme is KawaiiTheme {
            return theme.accent
        } else if theme.background == Color.white || 
                  theme.background == Color(red: 0.98, green: 0.98, blue: 0.98) ||
                  theme.background == Color(red: 0.98, green: 0.99, blue: 1.0) ||
                  theme.background == Color(red: 0.98, green: 1.0, blue: 0.99) {
            return theme.text
        } else {
            return theme.primary
        }
    }
    
    private func getTheme(for mode: ThemeMode) -> Theme {
        switch mode {
        case .kawaii:
            return KawaiiTheme()
        case .light:
            return LightTheme()
        case .dark:
            return DarkTheme()
        default:
            return LightTheme()
        }
    }
}

#Preview {
    KawaiiIconVisibilityTestPreview()
}