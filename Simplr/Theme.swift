//
//  Theme.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

// MARK: - Theme Protocol
protocol Theme {
    var primary: Color { get }
    var secondary: Color { get }
    var accent: Color { get }
    var background: Color { get }
    var surface: Color { get }
    var surfaceSecondary: Color { get }
    var text: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var shadow: Color { get }
    var border: Color { get }
    var borderSecondary: Color { get }
    var toggle: Color { get }
    var progress: Color { get }
    
    var backgroundGradient: LinearGradient { get }
    var surfaceGradient: LinearGradient { get }
    var accentGradient: LinearGradient { get }
    var backgroundImage: String? { get }
    
    var shadowStyle: ShadowStyle { get }
    var cardShadowStyle: ShadowStyle { get }
    var neumorphicStyle: NeumorphicShadowStyle { get }
    var neumorphicButtonStyle: NeumorphicShadowStyle { get }
    var neumorphicPressedStyle: NeumorphicShadowStyle { get }
}

// MARK: - Shadow Style
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    let opacity: Double
    
    init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0, opacity: Double = 1.0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
        self.opacity = opacity
    }
}

// MARK: - Neumorphic Shadow Style
struct NeumorphicShadowStyle {
    let lightShadow: ShadowStyle
    let darkShadow: ShadowStyle
    
    init(lightShadow: ShadowStyle, darkShadow: ShadowStyle) {
        self.lightShadow = lightShadow
        self.darkShadow = darkShadow
    }
}

// MARK: - Minimal Theme (Ultra-Clean White)
struct MinimalTheme: Theme {
    let primary = Color.black
    let secondary = Color.gray.opacity(0.6)
    let accent = Color.black
    let background = Color.white // Pure white background
    let surface = Color.white // Pure white surfaces
    let surfaceSecondary = Color.white // Keep secondary surfaces white too
    let text = Color.black
    let textSecondary = Color.gray.opacity(0.7) // Subtle gray for secondary text
    let textTertiary = Color.gray.opacity(0.5) // Lighter gray for tertiary text
    let success = Color.green // Simple green for success
    let warning = Color.orange // Simple orange for warnings
    let error = Color.red // Simple red for errors
    let shadow = Color.clear // No shadows for ultra-minimal look
    let border = Color.gray.opacity(0.2) // Very subtle borders
    let borderSecondary = Color.gray.opacity(0.1) // Even more subtle secondary borders
    let toggle = Color.black
    let progress = Color.black
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white, Color.white], // Pure white gradient
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white, Color.white], // Pure white gradient
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color.black, Color.black], // Solid black for accent
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundImage: String? {
        nil
    }
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.clear, // No shadow
            radius: 0,
            y: 0
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.clear, // No shadow
            radius: 0,
            y: 0
        )
    }
    
    var neumorphicStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.clear, // No neumorphic effects
                radius: 0,
                x: 0,
                y: 0
            ),
            darkShadow: ShadowStyle(
                color: Color.clear, // No neumorphic effects
                radius: 0,
                x: 0,
                y: 0
            )
        )
    }
    
    var neumorphicButtonStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.clear, // No neumorphic effects
                radius: 0,
                x: 0,
                y: 0
            ),
            darkShadow: ShadowStyle(
                color: Color.clear, // No neumorphic effects
                radius: 0,
                x: 0,
                y: 0
            )
        )
    }
    
    var neumorphicPressedStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.clear, // No neumorphic effects
                radius: 0,
                x: 0,
                y: 0
            ),
            darkShadow: ShadowStyle(
                color: Color.clear, // No neumorphic effects
                radius: 0,
                x: 0,
                y: 0
            )
        )
    }
}

// MARK: - Plain Light Theme (Monochromatic)
struct PlainLightTheme: Theme {
    let primary = Color.black
    let secondary = Color.gray
    let accent = Color.black
    let background = Color(red: 0.98, green: 0.98, blue: 0.98) // Slightly off-white for better contrast
    let surface = Color(red: 0.92, green: 0.92, blue: 0.92) // More distinct gray surface with better contrast
    let surfaceSecondary = Color(red: 0.90, green: 0.90, blue: 0.90) // Darker gray secondary surface for clear distinction
    let text = Color.black
    let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.4) // Darker for better readability
    let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.6)
    let success = Color(red: 0.2, green: 0.8, blue: 0.2) // Green for success actions
    let warning = Color(red: 1.0, green: 0.7, blue: 0.0) // Orange for warnings
    let error = Color(red: 0.9, green: 0.2, blue: 0.2) // Red for error actions
    let shadow = Color.black.opacity(0.15) // Stronger shadow for better definition
    let border = Color(red: 0.75, green: 0.75, blue: 0.75).opacity(0.6) // Enhanced visibility border
    let borderSecondary = Color(red: 0.7, green: 0.7, blue: 0.7).opacity(0.8) // More visible secondary border
    let toggle = Color.accentColor
    let progress = Color(red: 0.2, green: 0.6, blue: 0.85) // A consistent, pleasant blue
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.98, blue: 0.98),
                Color(red: 0.96, green: 0.96, blue: 0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.93, blue: 0.93), // More distinct lighter gray
                Color(red: 0.91, green: 0.91, blue: 0.91)  // More distinct darker gray for better contrast
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.2, green: 0.2, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundImage: String? {
        nil
    }
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.black.opacity(0.02),
            radius: 2,
            y: 0.5
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.black.opacity(0.03),
            radius: 3,
            y: 1
        )
    }
    
    var neumorphicStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.8),
                radius: 4,
                x: -2,
                y: -2
            ),
            darkShadow: ShadowStyle(
                color: Color.black.opacity(0.08),
                radius: 4,
                x: 2,
                y: 2
            )
        )
    }
    
    var neumorphicButtonStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.9),
                radius: 3,
                x: -1.5,
                y: -1.5
            ),
            darkShadow: ShadowStyle(
                color: Color.black.opacity(0.06),
                radius: 3,
                x: 1.5,
                y: 1.5
            )
        )
    }
    
    var neumorphicPressedStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.black.opacity(0.08),
                radius: 4,
                x: 2,
                y: 2
            ),
            darkShadow: ShadowStyle(
                color: Color.white.opacity(0.6),
                radius: 4,
                x: -2,
                y: -2
            )
        )
    }
}

// MARK: - Light Green Theme (Sophisticated Teal Green Accent)
struct LightGreenTheme: Theme {
    let primary = Color(red: 0.2, green: 0.7, blue: 0.6) // Sophisticated teal green primary
    let secondary = Color(red: 0.4, green: 0.8, blue: 0.7) // Lighter teal green secondary
    let accent = Color(red: 0.1, green: 0.6, blue: 0.5) // Deep teal green accent
    let background = Color(red: 0.98, green: 1.0, blue: 0.99) // Subtle green-tinted background
    let surface = Color(red: 0.93, green: 0.97, blue: 0.95) // More distinct green surface with better contrast
    let surfaceSecondary = Color(red: 0.91, green: 0.95, blue: 0.93) // Darker green-tinted secondary surface for clear distinction
    let text = Color(red: 0.05, green: 0.15, blue: 0.1) // Dark green-tinted text
    let textSecondary = Color(red: 0.25, green: 0.45, blue: 0.35) // Green-gray secondary text
    let textTertiary = Color(red: 0.45, green: 0.65, blue: 0.55) // Lighter green-gray tertiary
    let success = Color(red: 0.2, green: 0.8, blue: 0.4) // Fresh green for success
    let warning = Color(red: 1.0, green: 0.6, blue: 0.0) // Warm orange for warnings
    let error = Color(red: 0.9, green: 0.3, blue: 0.3) // Soft red for errors
    let shadow = Color(red: 0.2, green: 0.7, blue: 0.6).opacity(0.12) // Green-tinted shadow
    let border = Color(red: 0.7, green: 0.9, blue: 0.8).opacity(0.7) // Enhanced visibility green border
    let borderSecondary = Color(red: 0.6, green: 0.85, blue: 0.75).opacity(0.8) // More visible green secondary border
    let toggle = Color(red: 0.2, green: 0.7, blue: 0.6)
    let progress = Color(red: 0.2, green: 0.8, blue: 0.6)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 1.0, blue: 0.99),
                Color(red: 0.95, green: 1.0, blue: 0.97)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.94, green: 0.98, blue: 0.96), // More distinct lighter green
                Color(red: 0.92, green: 0.96, blue: 0.94)  // More distinct darker green for better contrast
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.7, blue: 0.6),
                Color(red: 0.1, green: 0.6, blue: 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundImage: String? {
        nil
    }
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color(red: 0.2, green: 0.7, blue: 0.6).opacity(0.08),
            radius: 4,
            y: 2
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color(red: 0.2, green: 0.7, blue: 0.6).opacity(0.12),
            radius: 8,
            y: 4
        )
    }
    
    var neumorphicStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.9),
                radius: 6,
                x: -3,
                y: -3
            ),
            darkShadow: ShadowStyle(
                color: Color(red: 0.2, green: 0.7, blue: 0.6).opacity(0.15),
                radius: 6,
                x: 3,
                y: 3
            )
        )
    }
    
    var neumorphicButtonStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.95),
                radius: 4,
                x: -2,
                y: -2
            ),
            darkShadow: ShadowStyle(
                color: Color(red: 0.2, green: 0.7, blue: 0.6).opacity(0.12),
                radius: 4,
                x: 2,
                y: 2
            )
        )
    }
    
    var neumorphicPressedStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color(red: 0.2, green: 0.7, blue: 0.6).opacity(0.12),
                radius: 4,
                x: 2,
                y: 2
            ),
            darkShadow: ShadowStyle(
                color: Color.white.opacity(0.7),
                radius: 4,
                x: -2,
                y: -2
            )
        )
    }
}

// MARK: - Light Blue Theme (Sophisticated Blue Accent)
struct LightTheme: Theme {
    let primary = Color(red: 0.2, green: 0.4, blue: 0.8) // Sophisticated blue primary
    let secondary = Color(red: 0.4, green: 0.6, blue: 0.9) // Lighter blue secondary
    let accent = Color(red: 0.1, green: 0.3, blue: 0.7) // Deep blue accent
    let background = Color(red: 0.98, green: 0.99, blue: 1.0) // Subtle blue-tinted background
    let surface = Color(red: 0.93, green: 0.95, blue: 0.98) // More distinct blue surface with better contrast
    let surfaceSecondary = Color(red: 0.91, green: 0.93, blue: 0.96) // Darker blue-tinted secondary surface for clear distinction
    let text = Color(red: 0.1, green: 0.1, blue: 0.2) // Dark blue-tinted text
    let textSecondary = Color(red: 0.3, green: 0.4, blue: 0.5) // Blue-gray secondary text
    let textTertiary = Color(red: 0.5, green: 0.6, blue: 0.7) // Lighter blue-gray tertiary
    let success = Color(red: 0.2, green: 0.7, blue: 0.4) // Fresh green for success
    let warning = Color(red: 1.0, green: 0.6, blue: 0.0) // Warm orange for warnings
    let error = Color(red: 0.9, green: 0.3, blue: 0.3) // Soft red for errors
    let shadow = Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.12) // Blue-tinted shadow
    let border = Color(red: 0.7, green: 0.8, blue: 0.9).opacity(0.7) // Enhanced visibility blue border
    let borderSecondary = Color(red: 0.6, green: 0.75, blue: 0.85).opacity(0.8) // More visible blue secondary border
    let toggle = Color(red: 0.2, green: 0.4, blue: 0.8)
    let progress = Color(red: 0.2, green: 0.6, blue: 0.85)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.99, blue: 1.0),
                Color(red: 0.95, green: 0.97, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.94, green: 0.96, blue: 0.99), // More distinct lighter blue
                Color(red: 0.92, green: 0.94, blue: 0.97)  // More distinct darker blue for better contrast
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.4, blue: 0.8),
                Color(red: 0.1, green: 0.3, blue: 0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundImage: String? {
        nil
    }
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.08),
            radius: 4,
            y: 2
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.12),
            radius: 8,
            y: 4
        )
    }
    
    var neumorphicStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.9),
                radius: 6,
                x: -3,
                y: -3
            ),
            darkShadow: ShadowStyle(
                color: Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.15),
                radius: 6,
                x: 3,
                y: 3
            )
        )
    }
    
    var neumorphicButtonStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.95),
                radius: 4,
                x: -2,
                y: -2
            ),
            darkShadow: ShadowStyle(
                color: Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.12),
                radius: 4,
                x: 2,
                y: 2
            )
        )
    }
    
    var neumorphicPressedStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.12),
                radius: 4,
                x: 2,
                y: 2
            ),
            darkShadow: ShadowStyle(
                color: Color.white.opacity(0.7),
                radius: 4,
                x: -2,
                y: -2
            )
        )
    }
}

// MARK: - Dark Theme (Monochromatic: Black with White accents)
struct DarkTheme: Theme {
    let primary = Color.white
    let secondary = Color(red: 0.85, green: 0.85, blue: 0.85)
    let accent = Color.white
    let background = Color(red: 0.02, green: 0.02, blue: 0.02) // Slightly lighter than pure black
    let surface = Color(red: 0.08, green: 0.08, blue: 0.08) // Lighter surface for better distinction
    let surfaceSecondary = Color(red: 0.10, green: 0.10, blue: 0.10) // Lighter secondary surface for better contrast
    let text = Color.white
    let textSecondary = Color(red: 0.75, green: 0.75, blue: 0.75) // Better contrast for secondary text
    let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.6)
    let success = Color(red: 0.3, green: 0.9, blue: 0.3) // Bright green for success actions
    let warning = Color(red: 1.0, green: 0.8, blue: 0.2) // Bright orange for warnings  
    let error = Color(red: 1.0, green: 0.3, blue: 0.3) // Bright red for error actions
    let shadow = Color.black.opacity(0.4)
    let border = Color(red: 0.18, green: 0.18, blue: 0.18) // More visible border for better card distinction
    let borderSecondary = Color(red: 0.15, green: 0.15, blue: 0.15) // Lighter secondary border for better contrast
    let toggle = Color.accentColor
    let progress = Color(red: 0.3, green: 0.7, blue: 0.9) // A slightly brighter blue for dark mode
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.02, blue: 0.02),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.08, blue: 0.08),  // Lighter top for better distinction
                Color(red: 0.05, green: 0.05, blue: 0.05)   // Slightly darker bottom for depth
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white,
                Color(red: 0.9, green: 0.9, blue: 0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundImage: String? {
        nil
    }
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.black.opacity(0.25),
            radius: 10,
            y: 3
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.black.opacity(0.8),  // Stronger shadow for better card separation
            radius: 24,                       // Larger radius for more pronounced depth
            y: 12                            // Increased offset for better distinction
        )
    }
    
    var neumorphicStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.05),
                radius: 8,
                x: -4,
                y: -4
            ),
            darkShadow: ShadowStyle(
                color: Color.black.opacity(0.4),
                radius: 8,
                x: 4,
                y: 4
            )
        )
    }
    
    var neumorphicButtonStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.08),
                radius: 6,
                x: -3,
                y: -3
            ),
            darkShadow: ShadowStyle(
                color: Color.black.opacity(0.3),
                radius: 6,
                x: 3,
                y: 3
            )
        )
    }
    
    var neumorphicPressedStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.black.opacity(0.2),
                radius: 4,
                x: 2,
                y: 2
            ),
            darkShadow: ShadowStyle(
                color: Color.white.opacity(0.03),
                radius: 4,
                x: -2,
                y: -2
            )
        )
    }
}

// MARK: - Dark Blue Theme (Premium)
struct DarkBlueTheme: Theme {
    let primary = Color(red: 0.4, green: 0.6, blue: 0.9) // Bright blue primary for contrast
    let secondary = Color(red: 0.5, green: 0.7, blue: 0.95) // Lighter blue secondary
    let accent = Color(red: 0.3, green: 0.5, blue: 0.85) // Deep blue accent
    let background = Color(red: 0.05, green: 0.08, blue: 0.15) // Deep navy background
    let surface = Color(red: 0.08, green: 0.12, blue: 0.20) // Slightly lighter navy surface
    let surfaceSecondary = Color(red: 0.10, green: 0.15, blue: 0.25) // Even lighter secondary surface
    let text = Color(red: 0.9, green: 0.95, blue: 1.0) // Light blue-white text
    let textSecondary = Color(red: 0.7, green: 0.8, blue: 0.9) // Medium blue-gray secondary text
    let textTertiary = Color(red: 0.5, green: 0.6, blue: 0.7) // Darker blue-gray tertiary text
    let success = Color(red: 0.3, green: 0.8, blue: 0.5) // Green for success
    let warning = Color(red: 1.0, green: 0.7, blue: 0.3) // Orange for warnings
    let error = Color(red: 1.0, green: 0.4, blue: 0.4) // Red for errors
    let shadow = Color.clear // No shadow for clean look
    let border = Color(red: 0.2, green: 0.3, blue: 0.4) // Blue-tinted border
    let borderSecondary = Color(red: 0.15, green: 0.25, blue: 0.35) // Darker blue secondary border
    let toggle = Color(red: 0.4, green: 0.6, blue: 0.9)
    let progress = Color(red: 0.4, green: 0.6, blue: 0.9) // Blue progress color
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.08, blue: 0.15),
                Color(red: 0.03, green: 0.06, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.09, green: 0.13, blue: 0.22),
                Color(red: 0.07, green: 0.11, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.6, blue: 0.9),
                Color(red: 0.3, green: 0.5, blue: 0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundImage: String? {
        nil
    }
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.clear,
            radius: 0,
            y: 0
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.clear,
            radius: 0,
            y: 0
        )
    }
    
    var neumorphicStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            ),
            darkShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            )
        )
    }
    
    var neumorphicButtonStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            ),
            darkShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            )
        )
    }
    
    var neumorphicPressedStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            ),
            darkShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            )
        )
    }
}

// MARK: - Dark Purple Theme (Premium)
struct DarkPurpleTheme: Theme {
    let primary = Color(red: 0.6, green: 0.4, blue: 0.9) // Bright purple primary for contrast
    let secondary = Color(red: 0.7, green: 0.5, blue: 0.95) // Lighter purple secondary
    let accent = Color(red: 0.5, green: 0.3, blue: 0.85) // Deep purple accent
    let background = Color(red: 0.08, green: 0.05, blue: 0.15) // Deep purple background
    let surface = Color(red: 0.12, green: 0.08, blue: 0.20) // Slightly lighter purple surface
    let surfaceSecondary = Color(red: 0.15, green: 0.10, blue: 0.25) // Even lighter secondary surface
    let text = Color(red: 0.95, green: 0.9, blue: 1.0) // Light purple-white text
    let textSecondary = Color(red: 0.8, green: 0.7, blue: 0.9) // Medium purple-gray secondary text
    let textTertiary = Color(red: 0.6, green: 0.5, blue: 0.7) // Darker purple-gray tertiary text
    let success = Color(red: 0.5, green: 0.8, blue: 0.3) // Green for success
    let warning = Color(red: 1.0, green: 0.7, blue: 0.3) // Orange for warnings
    let error = Color(red: 1.0, green: 0.4, blue: 0.4) // Red for errors
    let shadow = Color.clear // No shadow for clean look
    let border = Color(red: 0.3, green: 0.2, blue: 0.4) // Purple-tinted border
    let borderSecondary = Color(red: 0.25, green: 0.15, blue: 0.35) // Darker purple secondary border
    let toggle = Color(red: 0.6, green: 0.4, blue: 0.9)
    let progress = Color(red: 0.6, green: 0.4, blue: 0.9) // Purple progress color
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.05, blue: 0.15),
                Color(red: 0.06, green: 0.03, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.13, green: 0.09, blue: 0.22),
                Color(red: 0.11, green: 0.07, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.6, green: 0.4, blue: 0.9),
                Color(red: 0.5, green: 0.3, blue: 0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundImage: String? {
        nil
    }
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.clear,
            radius: 0,
            y: 0
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.clear,
            radius: 0,
            y: 0
        )
    }
    
    var neumorphicStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            ),
            darkShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            )
        )
    }
    
    var neumorphicButtonStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            ),
            darkShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            )
        )
    }
    
    var neumorphicPressedStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            ),
            darkShadow: ShadowStyle(
                color: Color.clear,
                radius: 0,
                x: 0,
                y: 0
            )
        )
    }
}

// MARK: - Kawaii Theme (Premium)
struct KawaiiTheme: Theme {
    let primary = Color(red: 0.98, green: 0.85, blue: 0.88) // Soft blush pink
    let secondary = Color(red: 0.7, green: 0.95, blue: 0.8) // Mint green
    let accent = Color(red: 0.85, green: 0.45, blue: 0.55) // Deeper Hello Kitty pink for better contrast
    let background = Color(red: 0.97, green: 0.94, blue: 0.92) // Slightly darker background for better contrast
    let surface = Color(red: 0.92, green: 0.88, blue: 0.86) // More distinct kawaii surface with better contrast
    let surfaceSecondary = Color(red: 0.90, green: 0.86, blue: 0.84) // Darker kawaii secondary surface for clear distinction
    let text = Color(red: 0.15, green: 0.05, blue: 0.1) // Even darker text for better readability
    let textSecondary = Color(red: 0.35, green: 0.25, blue: 0.3) // Darker secondary text
    let textTertiary = Color(red: 0.55, green: 0.45, blue: 0.5) // Improved tertiary text contrast
    let success = Color(red: 0.85, green: 0.45, blue: 0.55) // Kawaii pink for success - matches theme accent
    let warning = Color(red: 1.0, green: 0.85, blue: 0.6) // Soft peach warning
    let error = Color(red: 1.0, green: 0.71, blue: 0.76) // Hello Kitty pink error
    let shadow = Color(red: 0.98, green: 0.85, blue: 0.88).opacity(0.2) // Stronger shadow for better definition
    let border = Color(red: 0.85, green: 0.75, blue: 0.78).opacity(0.8) // Enhanced visibility kawaii border
    let borderSecondary = Color(red: 0.8, green: 0.7, blue: 0.73).opacity(0.9) // More visible kawaii secondary border
    let toggle = Color(red: 0.85, green: 0.45, blue: 0.55)
    let progress = Color(red: 0.85, green: 0.45, blue: 0.55) // Kawaii pink progress color - matches theme aesthetic
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                background,
                Color(red: 0.95, green: 0.92, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundImage: String? {
        nil
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.89, blue: 0.87), // More distinct lighter kawaii tone
                Color(red: 0.91, green: 0.87, blue: 0.85)  // More distinct darker kawaii tone for better contrast
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: primary.opacity(0.12),
            radius: 10,
            y: 3
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: primary.opacity(0.18),
            radius: 15,
            y: 5
        )
    }
    
    var neumorphicStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.9),
                radius: 10,
                x: -5,
                y: -5
            ),
            darkShadow: ShadowStyle(
                color: primary.opacity(0.2),
                radius: 10,
                x: 5,
                y: 5
            )
        )
    }
    
    var neumorphicButtonStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.95),
                radius: 8,
                x: -4,
                y: -4
            ),
            darkShadow: ShadowStyle(
                color: primary.opacity(0.15),
                radius: 8,
                x: 4,
                y: 4
            )
        )
    }
    
    var neumorphicPressedStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: primary.opacity(0.1),
                radius: 6,
                x: 3,
                y: 3
            ),
            darkShadow: ShadowStyle(
                color: Color.white.opacity(0.7),
                radius: 6,
                x: -3,
                y: -3
            )
        )
    }
}

// MARK: - Coffee Theme (Warm Sepia and Brown Tones)
struct CoffeeTheme: Theme {
    let primary = Color(red: 0.55, green: 0.42, blue: 0.32) // Rich coffee brown
    let secondary = Color(red: 0.72, green: 0.58, blue: 0.45) // Warm caramel
    let accent = Color(red: 0.45, green: 0.32, blue: 0.22) // Deep espresso brown for contrast
    let background = Color(red: 0.96, green: 0.94, blue: 0.90) // Warm sepia background
    let surface = Color(red: 0.92, green: 0.88, blue: 0.82) // Cream coffee surface with texture feel
    let surfaceSecondary = Color(red: 0.90, green: 0.85, blue: 0.78) // Darker cream secondary surface for distinction
    let text = Color(red: 0.18, green: 0.12, blue: 0.08) // Dark coffee text for readability
    let textSecondary = Color(red: 0.38, green: 0.28, blue: 0.20) // Medium coffee-brown secondary text
    let textTertiary = Color(red: 0.58, green: 0.48, blue: 0.38) // Light coffee-brown tertiary text
    let success = Color(red: 0.52, green: 0.70, blue: 0.42) // Warm sage green for success
    let warning = Color(red: 0.92, green: 0.72, blue: 0.45) // Warm amber for warnings
    let error = Color(red: 0.85, green: 0.52, blue: 0.45) // Warm terracotta for errors
    let shadow = Color(red: 0.55, green: 0.42, blue: 0.32).opacity(0.18) // Coffee-tinted shadow
    let border = Color(red: 0.78, green: 0.68, blue: 0.58).opacity(0.6) // Warm coffee border
    let borderSecondary = Color(red: 0.72, green: 0.62, blue: 0.52).opacity(0.7) // Darker coffee secondary border
    let toggle = Color(red: 0.45, green: 0.32, blue: 0.22)
    let progress = Color(red: 0.55, green: 0.42, blue: 0.32) // Coffee brown progress color
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.94, blue: 0.90),
                Color(red: 0.94, green: 0.91, blue: 0.86)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.89, blue: 0.83), // Lighter cream coffee tone
                Color(red: 0.91, green: 0.86, blue: 0.79)  // Darker cream coffee tone for contrast
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.55, green: 0.42, blue: 0.32),
                Color(red: 0.45, green: 0.32, blue: 0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundImage: String? {
        nil
    }
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: primary.opacity(0.10),
            radius: 6,
            y: 2
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: primary.opacity(0.15),
            radius: 12,
            y: 4
        )
    }
    
    var neumorphicStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color(red: 0.98, green: 0.96, blue: 0.92).opacity(0.9),
                radius: 8,
                x: -4,
                y: -4
            ),
            darkShadow: ShadowStyle(
                color: primary.opacity(0.20),
                radius: 8,
                x: 4,
                y: 4
            )
        )
    }
    
    var neumorphicButtonStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color(red: 0.98, green: 0.96, blue: 0.92).opacity(0.95),
                radius: 6,
                x: -3,
                y: -3
            ),
            darkShadow: ShadowStyle(
                color: primary.opacity(0.18),
                radius: 6,
                x: 3,
                y: 3
            )
        )
    }
    
    var neumorphicPressedStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: primary.opacity(0.15),
                radius: 4,
                x: 2,
                y: 2
            ),
            darkShadow: ShadowStyle(
                color: Color(red: 0.98, green: 0.96, blue: 0.92).opacity(0.8),
                radius: 4,
                x: -2,
                y: -2
            )
        )
    }
}

// MARK: - Serene Theme (Soft Lavender and Dusty Rose)
struct SereneTheme: Theme {
    let primary = Color(red: 0.75, green: 0.68, blue: 0.85) // Soft lavender primary
    let secondary = Color(red: 0.85, green: 0.72, blue: 0.78) // Dusty rose secondary
    let accent = Color(red: 0.68, green: 0.58, blue: 0.82) // Deeper lavender accent for better contrast
    let background = Color(red: 0.97, green: 0.95, blue: 0.98) // Very light lavender background
    let surface = Color(red: 0.92, green: 0.89, blue: 0.94) // More distinct lavender surface with better contrast
    let surfaceSecondary = Color(red: 0.90, green: 0.87, blue: 0.92) // Darker lavender-tinted secondary surface for clear distinction
    let text = Color(red: 0.15, green: 0.12, blue: 0.18) // Dark purple-tinted text for readability
    let textSecondary = Color(red: 0.35, green: 0.32, blue: 0.38) // Medium purple-gray secondary text
    let textTertiary = Color(red: 0.55, green: 0.52, blue: 0.58) // Light purple-gray tertiary text
    let success = Color(red: 0.65, green: 0.85, blue: 0.75) // Soft sage green for success
    let warning = Color(red: 0.95, green: 0.82, blue: 0.68) // Warm peach for warnings
    let error = Color(red: 0.92, green: 0.68, blue: 0.72) // Soft rose for errors
    let shadow = Color(red: 0.75, green: 0.68, blue: 0.85).opacity(0.15) // Lavender-tinted shadow
    let border = Color(red: 0.82, green: 0.78, blue: 0.88).opacity(0.6) // Soft lavender border
    let borderSecondary = Color(red: 0.78, green: 0.74, blue: 0.84).opacity(0.7) // Slightly darker lavender secondary border
    let toggle = Color(red: 0.68, green: 0.58, blue: 0.82)
    let progress = Color(red: 0.75, green: 0.68, blue: 0.85) // Lavender progress color
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.95, blue: 0.98),
                Color(red: 0.95, green: 0.92, blue: 0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.90, blue: 0.95), // More distinct lighter lavender
                Color(red: 0.91, green: 0.88, blue: 0.93)  // More distinct darker lavender for better contrast
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.75, green: 0.68, blue: 0.85),
                Color(red: 0.68, green: 0.58, blue: 0.82)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundImage: String? {
        nil
    }
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: primary.opacity(0.08),
            radius: 6,
            y: 2
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: primary.opacity(0.12),
            radius: 12,
            y: 4
        )
    }
    
    var neumorphicStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.9),
                radius: 8,
                x: -4,
                y: -4
            ),
            darkShadow: ShadowStyle(
                color: primary.opacity(0.18),
                radius: 8,
                x: 4,
                y: 4
            )
        )
    }
    
    var neumorphicButtonStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.95),
                radius: 6,
                x: -3,
                y: -3
            ),
            darkShadow: ShadowStyle(
                color: primary.opacity(0.15),
                radius: 6,
                x: 3,
                y: 3
            )
        )
    }
    
    var neumorphicPressedStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: primary.opacity(0.12),
                radius: 4,
                x: 2,
                y: 2
            ),
            darkShadow: ShadowStyle(
                color: Color.white.opacity(0.8),
                radius: 4,
                x: -2,
                y: -2
            )
        )
    }
}

// MARK: - Theme Extensions
extension View {
    func applyShadow(_ shadowStyle: ShadowStyle) -> some View {
        self.shadow(
            color: shadowStyle.color.opacity(shadowStyle.opacity),
            radius: shadowStyle.radius,
            x: shadowStyle.x,
            y: shadowStyle.y
        )
    }
    
    func applyNeumorphicShadow(_ neumorphicStyle: NeumorphicShadowStyle) -> some View {
        self
            .shadow(
                color: neumorphicStyle.lightShadow.color.opacity(neumorphicStyle.lightShadow.opacity),
                radius: neumorphicStyle.lightShadow.radius,
                x: neumorphicStyle.lightShadow.x,
                y: neumorphicStyle.lightShadow.y
            )
            .shadow(
                color: neumorphicStyle.darkShadow.color.opacity(neumorphicStyle.darkShadow.opacity),
                radius: neumorphicStyle.darkShadow.radius,
                x: neumorphicStyle.darkShadow.x,
                y: neumorphicStyle.darkShadow.y
            )
    }
    
    func themedBackground(_ theme: Theme) -> some View {
        Group {
            if let backgroundImageName = theme.backgroundImage {
                self.background(
                    ZStack {
                        Image(backgroundImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                        
                        // Stronger overlay for better text readability
                        LinearGradient(
                            colors: [
                                theme.background.opacity(0.6),
                                theme.background.opacity(0.4),
                                theme.background.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .ignoresSafeArea()
                )
            } else {
                self.background(theme.backgroundGradient)
            }
        }
    }
    
    func themedSurface(_ theme: Theme) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surfaceGradient)
                .applyShadow(theme.cardShadowStyle)
        )
    }
    
    func neumorphicCard(_ theme: Theme, cornerRadius: CGFloat = 16) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(theme.surfaceGradient)
                .applyNeumorphicShadow(theme.neumorphicStyle)
        )
    }
    
    func neumorphicButton(_ theme: Theme, cornerRadius: CGFloat = 16, isPressed: Bool = false) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(theme.surfaceGradient)
                .applyNeumorphicShadow(isPressed ? theme.neumorphicPressedStyle : theme.neumorphicButtonStyle)
        )
    }
}