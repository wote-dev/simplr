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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with image support
                Color.clear
                    .themedBackground(theme)
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Choose Theme")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.text)
                        
                        Text("Select your preferred appearance")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Theme options
                    VStack(spacing: 16) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            ThemeOptionCard(
                                mode: mode,
                                isSelected: themeManager.themeMode == mode,
                                canAccess: themeManager.canAccessTheme(mode),
                                onSelect: {
                                    selectTheme(mode)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Preview section
                    VStack(spacing: 16) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(theme.text)
                        
                        ThemePreviewCard()
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
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
                    .padding(.bottom, 16)
                    #endif
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                    .fontWeight(.semibold)
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
    }
    
    private func selectTheme(_ mode: ThemeMode) {
        HapticManager.shared.buttonTap()
        
        if mode.isPremium && !themeManager.canAccessTheme(mode) {
            // Show paywall for premium themes
            premiumManager.showPaywall(for: .kawaiiTheme)
        } else {
            // Set theme directly without premium check since we already verified access
            themeManager.setThemeMode(mode, checkPremium: false)
        }
    }
}

struct ThemeOptionCard: View {
    @Environment(\.theme) var theme
    let mode: ThemeMode
    let isSelected: Bool
    let canAccess: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.accentGradient : theme.surfaceGradient)
                        .frame(width: 50, height: 50)
                        .applyShadow(theme.shadowStyle)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? theme.background : theme.primary)
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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.accent)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surfaceGradient)
                    .applyShadow(isSelected ? theme.cardShadowStyle : theme.shadowStyle)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 0)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func description(for mode: ThemeMode) -> String {
        switch mode {
        case .light:
            return "Clean and bright interface"
        case .dark:
            return "Easy on the eyes in low light"
        case .system:
            return "Matches your device settings"
        case .kawaii:
            return "Adorable pink theme with cute aesthetics"
        }
    }
}

struct ThemePreviewCard: View {
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 12) {
            // Mock task row
            HStack(spacing: 12) {
                Circle()
                    .fill(theme.success)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sample Task")
                        .font(.headline)
                        .foregroundColor(theme.text)
                    
                    Text("This is how your tasks will look")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                ZStack {
                    if theme is KawaiiTheme {
                        Circle()
                            .fill(theme.accent.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(theme.accent.opacity(0.4), lineWidth: 1)
                            )
                    }
                    
                    Image(systemName: "pencil")
                        .foregroundColor(
                            theme is KawaiiTheme ? Color.white : theme.primary
                        )
                        .font(.system(size: 14, weight: theme is KawaiiTheme ? .bold : .medium))
                        .shadow(
                            color: theme is KawaiiTheme ? theme.accent.opacity(0.5) : Color.clear,
                            radius: theme is KawaiiTheme ? 1 : 0,
                            x: 0,
                            y: theme is KawaiiTheme ? 0.5 : 0
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surfaceGradient)
                    .applyShadow(theme.shadowStyle)
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