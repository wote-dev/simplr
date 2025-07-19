//
//  ThemeSelectionOnboardingView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct ThemeSelectionOnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var premiumManager: PremiumManager
    @Environment(\.theme) var theme
    @Binding var showThemeSelection: Bool
    
    @State private var selectedTheme: ThemeMode = .system
    @State private var showingPaywall = false
    @State private var isChangingTheme = false
    
    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 32) {
                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(theme.accent)
                        
                        VStack(spacing: 8) {
                            Text("Choose Your Style")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.text)
                            
                            Text("Pick a theme that matches your vibe")
                                .font(.callout)
                                .foregroundColor(theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Theme options
                    LazyVStack(spacing: 12) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            ThemeOnboardingCard(
                                mode: mode,
                                isSelected: selectedTheme == mode,
                                canAccess: themeManager.canAccessTheme(mode),
                                onSelect: {
                                    selectTheme(mode)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Continue button
                    VStack(spacing: 16) {
                        Button {
                            completeThemeSelection()
                        } label: {
                            HStack(spacing: 8) {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .medium))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(theme.background)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.accent)
                            )
                        }
                        .padding(.horizontal, 40)
                        
                        // Skip option
                        Button {
                            completeThemeSelection()
                        } label: {
                            Text("Skip for now")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onAppear {
            // Set initial selected theme to current theme
            selectedTheme = themeManager.themeMode
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
                selectedTheme = mode
                themeManager.setThemeMode(mode, checkPremium: false)
            }
            
            // Reset debounce flag after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isChangingTheme = false
            }
        }
    }
    
    private func completeThemeSelection() {
        HapticManager.shared.successFeedback()
        
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
        
        // Dismiss theme selection
        withAnimation(.easeInOut(duration: 0.5)) {
            showThemeSelection = false
        }
    }
}

struct ThemeOnboardingCard: View {
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
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? theme.background : theme.primary)
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
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surfaceGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .animatedButton(pressedScale: 0.96, animation: .quickSpring)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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

#Preview {
    ThemeSelectionOnboardingView(showThemeSelection: .constant(true))
        .themedEnvironment(ThemeManager())
}