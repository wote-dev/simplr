//
//  WidgetBackgroundView.swift
//  SimplrWidget
//
//  Created by AI Assistant on 2025-02-07.
//

import SwiftUI

// MARK: - Widget Background View
struct WidgetBackgroundView: View {
    @Environment(\.widgetFamily) private var family
    
    private let theme: WidgetTheme
    private let useGradient: Bool
    private let cornerRadius: CGFloat?
    
    init(theme: WidgetTheme? = nil, useGradient: Bool = true, cornerRadius: CGFloat? = nil) {
        self.theme = theme ?? WidgetThemeManager.shared.currentTheme()
        self.useGradient = useGradient
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Group {
            if useGradient {
                theme.backgroundGradient
            } else {
                theme.backgroundColor
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius ?? theme.cornerRadius)
                .stroke(theme.borderColor.opacity(0.5), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? theme.cornerRadius))
    }
}

// MARK: - Widget Surface View
struct WidgetSurfaceView: View {
    @Environment(\.widgetFamily) private var family
    
    private let theme: WidgetTheme
    private let useGradient: Bool
    private let elevation: WidgetElevation
    private let cornerRadius: CGFloat?
    
    init(theme: WidgetTheme? = nil, useGradient: Bool = true, elevation: WidgetElevation = .low, cornerRadius: CGFloat? = nil) {
        self.theme = theme ?? WidgetThemeManager.shared.currentTheme()
        self.useGradient = useGradient
        self.elevation = elevation
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Group {
            if useGradient {
                theme.surfaceGradient
            } else {
                theme.surfaceColor
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius ?? theme.cornerRadius)
                .stroke(theme.borderColor.opacity(0.3), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? theme.cornerRadius))
        .shadow(
            color: theme.shadowColor.opacity(elevation.shadowOpacity(theme.shadowOpacity)),
            radius: elevation.shadowRadius(theme.shadowRadius),
            x: 0,
            y: elevation.shadowOffset
        )
    }
}

// MARK: - Widget Elevation
enum WidgetElevation {
    case none
    case low
    case medium
    case high
    
    func shadowOpacity(_ baseOpacity: Double) -> Double {
        switch self {
        case .none: return 0
        case .low: return baseOpacity * 0.5
        case .medium: return baseOpacity
        case .high: return baseOpacity * 1.5
        }
    }
    
    func shadowRadius(_ baseRadius: CGFloat) -> CGFloat {
        switch self {
        case .none: return 0
        case .low: return baseRadius * 0.5
        case .medium: return baseRadius
        case .high: return baseRadius * 1.5
        }
    }
    
    var shadowOffset: CGFloat {
        switch self {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 4
        }
    }
}

// MARK: - Theme-aware Text Styles
struct WidgetTextStyle {
    let theme: WidgetTheme
    
    var primary: some ViewModifier {
        ThemeTextStyleModifier(color: theme.primaryTextColor)
    }
    
    var secondary: some ViewModifier {
        ThemeTextStyleModifier(color: theme.secondaryTextColor)
    }
    
    var accent: some ViewModifier {
        ThemeTextStyleModifier(color: theme.accentColor)
    }
}

private struct ThemeTextStyleModifier: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content.foregroundColor(color)
    }
}

// MARK: - Preview Provider
struct WidgetBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WidgetBackgroundView(theme: WidgetLightTheme())
                .previewDisplayName("Light Theme")
            
            WidgetBackgroundView(theme: WidgetDarkTheme())
                .previewDisplayName("Dark Theme")
            
            WidgetBackgroundView(theme: WidgetKawaiiTheme())
                .previewDisplayName("Kawaii Theme")
        }
        .frame(width: 200, height: 200)
        .previewLayout(.sizeThatFits)
    }
}