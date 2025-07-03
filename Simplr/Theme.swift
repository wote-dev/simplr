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
    
    var backgroundGradient: LinearGradient { get }
    var surfaceGradient: LinearGradient { get }
    var accentGradient: LinearGradient { get }
    
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

// MARK: - Light Theme (Monochromatic: White with Black accents)
struct LightTheme: Theme {
    let primary = Color.black
    let secondary = Color.gray
    let accent = Color.black
    let background = Color.white
    let surface = Color.white
    let surfaceSecondary = Color(red: 0.98, green: 0.98, blue: 0.98)
    let text = Color.black
    let textSecondary = Color.gray
    let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.6)
    let success = Color(red: 0.2, green: 0.8, blue: 0.2) // Green for success actions
    let warning = Color(red: 1.0, green: 0.7, blue: 0.0) // Orange for warnings
    let error = Color(red: 0.9, green: 0.2, blue: 0.2) // Red for error actions
    let shadow = Color.black.opacity(0.1)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white,
                Color(red: 0.99, green: 0.99, blue: 0.99)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white,
                Color(red: 0.99, green: 0.99, blue: 0.99)
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
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 8,
            y: 2
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 12,
            y: 4
        )
    }
    
    var neumorphicStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.8),
                radius: 8,
                x: -4,
                y: -4
            ),
            darkShadow: ShadowStyle(
                color: Color.black.opacity(0.15),
                radius: 8,
                x: 4,
                y: 4
            )
        )
    }
    
    var neumorphicButtonStyle: NeumorphicShadowStyle {
        NeumorphicShadowStyle(
            lightShadow: ShadowStyle(
                color: Color.white.opacity(0.9),
                radius: 6,
                x: -3,
                y: -3
            ),
            darkShadow: ShadowStyle(
                color: Color.black.opacity(0.12),
                radius: 6,
                x: 3,
                y: 3
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

// MARK: - Dark Theme (Monochromatic: Black with White accents)
struct DarkTheme: Theme {
    let primary = Color.white
    let secondary = Color(red: 0.85, green: 0.85, blue: 0.85)
    let accent = Color.white
    let background = Color.black
    let surface = Color(red: 0.05, green: 0.05, blue: 0.05)
    let surfaceSecondary = Color(red: 0.1, green: 0.1, blue: 0.1)
    let text = Color.white
    let textSecondary = Color(red: 0.85, green: 0.85, blue: 0.85)
    let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.6)
    let success = Color(red: 0.3, green: 0.9, blue: 0.3) // Bright green for success actions
    let warning = Color(red: 1.0, green: 0.8, blue: 0.2) // Bright orange for warnings  
    let error = Color(red: 1.0, green: 0.3, blue: 0.3) // Bright red for error actions
    let shadow = Color.black.opacity(0.3)
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.02, green: 0.02, blue: 0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.05),
                Color(red: 0.08, green: 0.08, blue: 0.08)
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
    
    var shadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.black.opacity(0.25),
            radius: 10,
            y: 3
        )
    }
    
    var cardShadowStyle: ShadowStyle {
        ShadowStyle(
            color: Color.black.opacity(0.35),
            radius: 15,
            y: 5
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
        self.background(theme.backgroundGradient)
    }
    
    func themedSurface(_ theme: Theme) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 12)
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
    
    func neumorphicButton(_ theme: Theme, cornerRadius: CGFloat = 12, isPressed: Bool = false) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(theme.surfaceGradient)
                .applyNeumorphicShadow(isPressed ? theme.neumorphicPressedStyle : theme.neumorphicButtonStyle)
        )
    }
}