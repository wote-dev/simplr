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
            // Optimized background
            theme.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header description - simplified
                    Text("Select your preferred appearance")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                    
                    // Theme options - optimized
                    LazyVStack(spacing: 12) {
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
                    
                    // Preview section - simplified
                    VStack(spacing: 12) {
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
                    .padding(.bottom, 20)
                    #endif
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(theme.background == .black || theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) || theme.background == Color(red: 0.08, green: 0.05, blue: 0.15) || theme.background == Color(red: 0.05, green: 0.08, blue: 0.15) ? .dark : .light, for: .navigationBar)
        .toolbarBackground(theme.surface.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    HapticManager.shared.buttonTap()
                    dismiss()
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
            PaywallView()
                .environmentObject(premiumManager)
        }
        .onChange(of: premiumManager.showingPaywall) { _, newValue in
            showingPaywall = newValue
        }
    }
    
    private func selectTheme(_ mode: ThemeMode) {
        // Prevent rapid theme changes that could cause UI freezing
        guard !isChangingTheme else { return }
        
        // Ultra-subtle haptic feedback for theme selection - optimized for minimal disruption
        HapticManager.shared.themeChange()
        
        if mode.isPremium && !themeManager.canAccessTheme(mode) {
            // Show paywall for premium themes
            premiumManager.showPaywall()
        } else {
            // Set debounce flag to prevent rapid changes - reduced debounce time for responsiveness
            isChangingTheme = true
            
            // Optimize theme change with faster animation for responsiveness
            withAnimation(.easeInOut(duration: 0.2)) {
                themeManager.setThemeMode(mode, checkPremium: false)
            }
            
            // Reset debounce flag after shorter delay - improved responsiveness
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
    
    // Cached colors for performance
    private let premiumGoldColor = Color(red: 0.85, green: 0.65, blue: 0.13)
    
    // Simplified color logic with cached values
    private var borderColor: Color {
        theme.border.opacity(isSelected ? 0.8 : 0.3)
    }
    
    private var iconColor: Color {
        isSelected ? theme.background : theme.text
    }
    
    var body: some View {
        Button(action: isChanging ? {} : onSelect) {
            HStack(spacing: 16) {
                // Simplified icon
                Circle()
                    .fill(isSelected ? theme.accent : theme.surface)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: mode.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isSelected ? theme.background : iconColor)
                    )
                
                // Simplified content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(mode.displayName)
                            .font(.headline)
                            .foregroundColor(theme.text)
                        
                        if mode.isPremium {
                            Image(systemName: canAccess ? "crown.fill" : "lock.fill")
                                .font(.caption)
                                .foregroundColor(canAccess ? Color.orange : premiumGoldColor)
                        }
                    }
                    
                    Text(description(for: mode))
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.accent)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
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
        case .darkBlue:
            return "Deep and sophisticated"

        case .system:
            return "Follows your device"
        case .kawaii:
            return "Cute and colorful"
        case .serene:
            return "Peaceful and calming"
        case .coffee:
            return "Warm and cozy"
        }
    }
}

struct ThemePreviewCard: View {
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 12) {
            // Simplified task preview
            HStack(spacing: 12) {
                Circle()
                    .fill(theme.success)
                    .frame(width: 28, height: 28)
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
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Reminder pill
                HStack(spacing: 4) {
                    Image(systemName: "bell")
                        .font(.caption)
                    Text("2:00 PM")
                        .font(.caption)
                }
                .foregroundColor(theme.warning)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(theme.warning.opacity(0.1))
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
            )
            
            // Add button preview
            HStack {
                Spacer()
                Circle()
                    .fill(theme.accent)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "plus")
                            .foregroundColor(theme.background)
                            .font(.system(size: 18, weight: .semibold))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface.opacity(0.8))
        )
    }
}

#Preview {
    ThemeSelectorView()
        .environmentObject(ThemeManager())
        .environmentObject(PremiumManager())
        .environment(\.theme, LightTheme())
}