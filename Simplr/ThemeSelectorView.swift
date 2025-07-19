//
//  ThemeSelectorView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct ThemeSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var premiumManager: PremiumManager
    @Environment(\.theme) var theme
    
    @State private var showingPaywall = false
    @State private var isChangingTheme = false
    
    var body: some View {
        ZStack {
            // Background with image support
            Color.clear
                .themedBackground(theme)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header description
                    VStack(spacing: 8) {
                        Text("Select your preferred appearance")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    // Theme options
                    VStack(spacing: 16) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            ThemeOptionCard(
                                mode: mode,
                                isSelected: themeManager.themeMode == mode,
                                canAccess: themeManager.canAccessTheme(mode),
                                isChanging: isChangingTheme && themeManager.themeMode == mode,
                                onSelect: {
                                    selectTheme(mode)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Preview section
                    VStack(spacing: 16) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(theme.text)
                        
                        ThemePreviewCard()
                    }
                    .padding(.horizontal, 20)
                    
                    // Hidden onboarding reset for testing (only visible in debug builds)
                    #if DEBUG
                    Button {
                        UserDefaults.standard.set(false, forKey: "HasCompletedOnboarding")
                        HapticManager.shared.buttonTap()
                    } label: {
                        Text("Reset Onboarding (Debug)")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary.opacity(0.6))
                            .padding(.vertical, 8)
                    }
                    .animatedButton()
                    .padding(.bottom, 20)
                    #endif
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(theme.background == .black || theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? .dark : .light, for: .navigationBar)
        .toolbarBackground(theme.surface.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    HapticManager.shared.buttonTap()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Settings")
                            .font(.body)
                    }
                    .foregroundColor(theme.accent)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(targetFeature: .kawaiiTheme)
                .environmentObject(premiumManager)
        }
        .onChange(of: premiumManager.showingPaywall) { _, newValue in
            showingPaywall = newValue
        }
    }
    
    private func selectTheme(_ mode: ThemeMode) {
        // Prevent rapid theme changes that could cause UI freezing
        guard !isChangingTheme else { return }
        
        HapticManager.shared.buttonTap()
        
        if mode.isPremium && !themeManager.canAccessTheme(mode) {
            // Show paywall for premium themes
            premiumManager.showPaywall(for: .kawaiiTheme)
        } else {
            // Set debounce flag to prevent rapid changes
            isChangingTheme = true
            
            // Optimize theme change with proper animation and state management
            withAnimation(.easeInOut(duration: 0.3)) {
                themeManager.setThemeMode(mode, checkPremium: false)
            }
            
            // Provide success feedback and reset debounce flag
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                HapticManager.shared.successFeedback()
            }
            
            // Reset debounce flag after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isChangingTheme = false
            }
        }
    }
}

struct ThemeOptionCard: View {
    @Environment(\.theme) var theme
    let mode: ThemeMode
    let isSelected: Bool
    let canAccess: Bool
    let isChanging: Bool
    let onSelect: () -> Void
    
    /// Returns subtle, consistent border color for all themes with enhanced visibility for light themes
    private func getBorderColor(for theme: Theme) -> Color {
        // Enhanced border visibility for light and kawaii themes while maintaining subtlety
        if theme is KawaiiTheme {
            // Kawaii theme: soft pink-gray border that's visible but not prominent
            return Color(red: 0.75, green: 0.65, blue: 0.68).opacity(0.6)
        } else if theme.background == Color.white || 
                  theme.background == Color(red: 0.98, green: 0.98, blue: 0.98) ||
                  theme.background == Color(red: 0.98, green: 0.99, blue: 1.0) ||
                  theme.background == Color(red: 0.98, green: 1.0, blue: 0.99) {
            // Light themes: subtle gray border with better visibility
            return Color(red: 0.85, green: 0.85, blue: 0.85).opacity(0.7)
        } else {
            // Dark themes: use existing border with reduced opacity
            return theme.border.opacity(0.3)
        }
    }
    
    /// Returns consistent border width across all themes for uniform appearance
    private func getBorderWidth(for theme: Theme) -> CGFloat {
        // Consistent 0.8pt border width for all themes - subtle but visible
        return 0.8
    }
    
    /// Returns appropriate icon color for non-selected theme options with proper contrast
    private func getIconColor(for theme: Theme) -> Color {
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
    
    var body: some View {
        Button(action: isChanging ? {} : onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.accentGradient : theme.surfaceGradient)
                        .frame(width: 50, height: 50)
                        .applyShadow(theme.shadowStyle)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? theme.background : getIconColor(for: theme))
                        .shadow(
                            color: isSelected ? (theme.background == .black ? Color.white.opacity(0.3) : Color.black.opacity(0.3)) : Color.clear,
                            radius: isSelected ? 2 : 0,
                            x: 0,
                            y: isSelected ? 1 : 0
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mode.displayName)
                            .font(.headline)
                            .foregroundColor(theme.text)
                        
                        if mode.isPremium {
                            if canAccess {
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.0))
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.6))
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Text(description(for: mode))
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.leading)
                    
                    if mode.isPremium && !canAccess {
                        Text("Premium Feature")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.6))
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    if isChanging {
                        // Show loading indicator when theme is changing
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.accent))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.accent)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surfaceGradient)
                    .applyShadow(isSelected ? theme.cardShadowStyle : theme.shadowStyle)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? theme.accent : getBorderColor(for: theme),
                                lineWidth: isSelected ? 2.0 : getBorderWidth(for: theme)
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .opacity(isChanging && !isSelected ? 0.6 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isChanging)
    }
    
    private func description(for mode: ThemeMode) -> String {
        switch mode {
        case .light:
            return "Clean and minimal"
        case .lightBlue:
            return "Soft and calming"
        case .lightGreen:
            return "Fresh and natural"
        case .minimal:
            return "Ultra-clean white"
        case .dark:
            return "Easy on the eyes"
        case .system:
            return "Follows your device"
        case .kawaii:
            return "Cute and colorful"
        case .serene:
            return "Peaceful and calming"
        }
    }
}

struct ThemePreviewCard: View {
    @Environment(\.theme) var theme
    
    /// Returns subtle, consistent border color for all themes in preview with enhanced visibility for light themes
    private func getPreviewBorderColor(for theme: Theme) -> Color {
        // Enhanced border visibility for light and kawaii themes while maintaining subtlety
        if theme is KawaiiTheme {
            // Kawaii theme: soft pink-gray border that's visible but not prominent
            return Color(red: 0.75, green: 0.65, blue: 0.68).opacity(0.6)
        } else if theme.background == Color.white || 
                  theme.background == Color(red: 0.98, green: 0.98, blue: 0.98) ||
                  theme.background == Color(red: 0.98, green: 0.99, blue: 1.0) ||
                  theme.background == Color(red: 0.98, green: 1.0, blue: 0.99) {
            // Light themes: subtle gray border with better visibility
            return Color(red: 0.85, green: 0.85, blue: 0.85).opacity(0.7)
        } else {
            // Dark themes: use existing border with reduced opacity
            return theme.border.opacity(0.3)
        }
    }
    
    /// Returns consistent border width across all themes for uniform appearance in preview
    private func getPreviewBorderWidth(for theme: Theme) -> CGFloat {
        // Consistent 0.8pt border width for all themes - subtle but visible
        return 0.8
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Modern task card preview matching current TaskRowView design
            HStack(spacing: 12) {
                // Completion toggle (left side)
                Circle()
                    .fill(theme.success)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(theme.success, lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .applyNeumorphicShadow(theme.neumorphicPressedStyle)
                
                // Main content area with text on left and pills on right
                HStack(alignment: .top, spacing: 12) {
                    // Left side: Text content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sample Task")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme is KawaiiTheme ? theme.accent : theme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("This is how your tasks will look")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .opacity(0.8)
                        
                        // Due date display under task text
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(theme.textSecondary)
                            
                            Text("Today 2:00 PM")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(theme.textSecondary)
                            
                            Spacer()
                        }
                    }
                    
                    // Right side: Pills (reminder)
                    VStack(alignment: .trailing, spacing: 6) {
                        // Reminder pill
                        HStack(spacing: 3) {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                            
                            Text("1:45 PM")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(theme.warning)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(theme.warning.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        // Enhanced dark mode task card gradient for sleeker look
                        theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.04, green: 0.04, blue: 0.04),
                                Color(red: 0.02, green: 0.02, blue: 0.02),
                                Color(red: 0.03, green: 0.03, blue: 0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : theme.surfaceGradient
                    )
                    .shadow(
                        color: theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? 
                            Color.black.opacity(0.8) : theme.shadow.opacity(0.6),
                        radius: theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? 15 : 1.0,
                        x: 0,
                        y: theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) ? 8 : 0.3
                    )
            )
            .overlay(
                // Enhanced border for better definition across all themes - using strokeBorder for clean corners
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        getPreviewBorderColor(for: theme),
                        lineWidth: getPreviewBorderWidth(for: theme)
                    )
            )
            
            // Mock add button
            HStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(theme.accentGradient)
                        .frame(width: 44, height: 44)
                        .applyShadow(theme.cardShadowStyle)
                    
                    Image(systemName: "plus")
                        .foregroundColor(theme.background)
                        .font(.system(size: 20, weight: .semibold))
                        .shadow(
                            color: theme.background == .black ? Color.white.opacity(0.3) : Color.black.opacity(0.3),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface.opacity(0.5))
                .applyShadow(theme.shadowStyle)
        )
    }
}

#Preview {
    ThemeSelectorView()
        .environmentObject(ThemeManager())
        .environmentObject(PremiumManager())
        .environment(\.theme, LightTheme())
}