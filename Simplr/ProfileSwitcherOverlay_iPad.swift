//
//  ProfileSwitcherOverlay_iPad.swift
//  Simplr
//
//  Created by AI Assistant on 2025-01-20.
//  iPadOS-optimized profile switching overlay with adaptive layouts
//

import SwiftUI
import UIKit

@available(iOS 17.0, *)
struct ProfileSwitcherOverlay_iPad: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @Binding var isPresented: Bool
    
    // iPad-specific state management
    @State private var selectedProfile: UserProfile?
    @State private var showingConfirmation = false
    @State private var animationPhase: AnimationPhase = .initial
    
    // Performance optimization: Pre-calculate colors and layouts
    private var currentProfileColor: Color {
        profileManager.currentProfile.themeAwareColor(for: theme)
    }
    
    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
    private var sidebarWidth: CGFloat {
        // Calculate optimal width based on content
        let baseWidth: CGFloat = isCompactLayout ? 280 : 320
        let maxWidth: CGFloat = isCompactLayout ? 360 : 420
        let minWidth: CGFloat = isCompactLayout ? 260 : 300
        
        // Calculate content-based width
        let contentWidth = calculateOptimalContentWidth()
        return max(minWidth, min(maxWidth, max(baseWidth, contentWidth)))
    }
    
    // MARK: - Content Width Calculation
    private func calculateOptimalContentWidth() -> CGFloat {
        let horizontalPadding: CGFloat = 48 // 24pt on each side
        let iconWidth: CGFloat = 56
        let iconSpacing: CGFloat = 20
        let selectionIndicatorWidth: CGFloat = 28
        let selectionIndicatorSpacing: CGFloat = 16
        
        // Calculate maximum text width needed
        let maxTextWidth = UserProfile.allCases.map { profile in
            calculateTextContentWidth(for: profile)
        }.max() ?? 200
        
        let totalWidth = horizontalPadding + iconWidth + iconSpacing + maxTextWidth + selectionIndicatorSpacing + selectionIndicatorWidth
        
        return totalWidth + 40 // Add some breathing room
    }
    
    private func calculateTextContentWidth(for profile: UserProfile) -> CGFloat {
        let titleFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        let descriptionFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        let badgeFont = UIFont.systemFont(ofSize: 11, weight: .bold)
        
        // Calculate title width (including CURRENT badge if applicable)
        let titleText = profile.displayName
        let titleWidth = titleText.size(withAttributes: [.font: titleFont]).width
        
        let badgeWidth: CGFloat = profile == profileManager.currentProfile ? 
            "CURRENT".size(withAttributes: [.font: badgeFont]).width + 16 + 8 : 0 // padding + spacing
        
        let titleRowWidth = titleWidth + badgeWidth
        
        // Calculate description width
        let descriptionText = profileDescription(for: profile)
        let descriptionWidth = descriptionText.size(withAttributes: [.font: descriptionFont]).width
        
        // Calculate task indicators width
        let taskIndicatorsWidth: CGFloat = 120 // Approximate width for "Active 5 Total 12"
        
        return max(titleRowWidth, descriptionWidth, taskIndicatorsWidth)
    }
    
    enum AnimationPhase {
        case initial, appearing, stable
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar content with optimized width
            sidebarContent
                .frame(width: optimizedSidebarWidth)
                .background(sidebarBackground)
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 2, y: 0)
                .offset(x: animationPhase == .initial ? -optimizedSidebarWidth : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animationPhase)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissWithAnimation()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation {
                animationPhase = .appearing
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animationPhase = .stable
            }
        }
        .onDisappear {
            // Clean up cached values for memory optimization
            cachedContentWidth = 0
            lastCalculationTheme = ""
            lastProfileCount = 0
        }
    }
    
    private var sidebarBackground: some View {
        ZStack {
            // Primary background
            Rectangle()
                .fill(theme.surface)
            
            // Subtle gradient overlay for depth
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.surface,
                            theme.surface.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Border for definition
            Rectangle()
                .stroke(theme.border.opacity(0.1), lineWidth: 1)
        }
    }
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            sidebarHeaderView
            
            Divider()
                .background(theme.border.opacity(0.1))
                .padding(.horizontal, 24)
            
            profileOptionsView
            
            Spacer()
            
            Divider()
                .background(theme.border.opacity(0.1))
                .padding(.horizontal, 24)
            
            sidebarActionButtonsView
        }
    }
    
    private var sidebarHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profiles")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.text)
                    
                    Text("Switch between Personal and Work")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    dismissWithAnimation()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 60) // Account for status bar
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
    }
    
    private var profileOptionsView: some View {
        VStack(spacing: 16) {
            ForEach(UserProfile.allCases, id: \.self) { profile in
                profileCard(for: profile)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
    }
    
    private func profileCard(for profile: UserProfile) -> some View {
        Button(action: {
            selectProfile(profile)
        }) {
            // Use adaptive HStack with content-based sizing
            HStack(spacing: 16) {
                // Optimized icon with better visual hierarchy
                profileIconView(for: profile)
                
                // Content-aware text section
                profileTextContent(for: profile)
                
                // Selection indicator with proper spacing
                profileSelectionIndicator(for: profile)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(profileCardBackground(for: profile))
            .overlay(profileCardBorder(for: profile))
        }
        .buttonStyle(iPadProfileButtonStyle())
    }
    
    // MARK: - Profile Card Components
    @ViewBuilder
    private func profileIconView(for profile: UserProfile) -> some View {
        ZStack {
            Circle()
                .fill(profile.themeAwareColor(for: theme).opacity(0.12))
                .frame(width: 48, height: 48)
            
            if profile == profileManager.currentProfile {
                Circle()
                    .stroke(profile.themeAwareColor(for: theme), lineWidth: 2)
                    .frame(width: 48, height: 48)
            }
            
            Image(systemName: profile.icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(profile.themeAwareColor(for: theme))
        }
    }
    
    @ViewBuilder
    private func profileTextContent(for profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title row with adaptive layout
            HStack(spacing: 8) {
                Text(profile.displayName)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.text)
                    .fixedSize(horizontal: true, vertical: false)
                
                if profile == profileManager.currentProfile {
                    Text("CURRENT")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(profile.themeAwareColor(for: theme))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(profile.themeAwareColor(for: theme).opacity(0.15))
                        )
                        .fixedSize()
                }
            }
            
            // Description with content-aware width
            Text(profileDescription(for: profile))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            
            // Compact task indicators
            HStack(spacing: 8) {
                compactTaskIndicator(for: profile, label: "Active", count: profileManager.getActiveTaskCount(for: profile))
                compactTaskIndicator(for: profile, label: "Total", count: profileManager.getTaskCount(for: profile))
            }
        }
    }
    
    @ViewBuilder
    private func profileSelectionIndicator(for profile: UserProfile) -> some View {
        if profile == profileManager.currentProfile {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(profile.themeAwareColor(for: theme))
        } else {
            Image(systemName: "circle")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(theme.textSecondary.opacity(0.3))
        }
    }
    
    @ViewBuilder
    private func profileCardBackground(for profile: UserProfile) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                profile == profileManager.currentProfile ?
                profile.themeAwareColor(for: theme).opacity(0.08) :
                theme.surfaceSecondary
            )
    }
    
    @ViewBuilder
    private func profileCardBorder(for profile: UserProfile) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(
                profile == profileManager.currentProfile ?
                profile.themeAwareColor(for: theme).opacity(0.3) :
                Color.clear,
                lineWidth: 1.5
            )
    }
    
    @ViewBuilder
    private func compactTaskIndicator(for profile: UserProfile, label: String, count: Int) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
            
            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(profile.themeAwareColor(for: theme))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(theme.surface)
                .overlay(
                    Capsule()
                        .stroke(theme.border.opacity(0.2), lineWidth: 0.5)
                )
        )
        .fixedSize()
    }
    
    // MARK: - Performance Optimizations
    @State private var cachedContentWidth: CGFloat = 0
    @State private var lastCalculationTheme: String = ""
    @State private var lastProfileCount: Int = 0
    
    private var optimizedSidebarWidth: CGFloat {
        let currentThemeId = theme.id
        let currentProfileCount = UserProfile.allCases.count
        
        // Check if cache is valid (same theme and profile count)
        if cachedContentWidth > 0 && 
           lastCalculationTheme == currentThemeId && 
           lastProfileCount == currentProfileCount {
            return cachedContentWidth
        }
        
        let calculatedWidth = calculateOptimalContentWidth()
        
        // Update cache on main thread to prevent race conditions
        DispatchQueue.main.async {
            self.cachedContentWidth = calculatedWidth
            self.lastCalculationTheme = currentThemeId
            self.lastProfileCount = currentProfileCount
        }
        
        return calculatedWidth
    }
    
    private var sidebarActionButtonsView: some View {
        VStack(spacing: 16) {
            // Switch button (if different profile selected)
            if let selectedProfile = selectedProfile,
               selectedProfile != profileManager.currentProfile {
                Button(action: {
                    switchToSelectedProfile()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Switch to \(selectedProfile.displayName)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        selectedProfile.themeAwareColor(for: theme),
                                        selectedProfile.themeAwareColor(for: theme).opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
                .buttonStyle(iPadActionButtonStyle())
            }
            
            // Settings/Manage Profiles button
            Button(action: {
                // TODO: Navigate to profile settings
                dismissWithAnimation()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Manage Profiles")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surfaceSecondary)
                )
            }
            .buttonStyle(iPadActionButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    private func profileDescription(for profile: UserProfile) -> String {
        switch profile {
        case .personal:
            return "Your personal tasks, reminders, and daily activities"
        case .work:
            return "Work-related tasks, projects, and professional commitments"
        }
    }
    
    private func selectProfile(_ profile: UserProfile) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedProfile = profile
        }
        
        // Immediate haptic feedback
        HapticManager.shared.selectionChange()
        
        // If selecting current profile, dismiss immediately
        if profile == profileManager.currentProfile {
            dismissWithAnimation()
        }
    }
    
    private func switchToSelectedProfile() {
        guard let selectedProfile = selectedProfile,
              selectedProfile != profileManager.currentProfile else {
            dismissWithAnimation()
            return
        }
        
        // Enhanced haptic feedback for profile switch
        HapticManager.shared.buttonTap()
        
        // Perform the switch with optimized animation
        withAnimation(.easeInOut(duration: 0.3)) {
            profileManager.switchToProfile(selectedProfile)
        }
        
        // Dismiss with slight delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismissWithAnimation()
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationPhase = .initial
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

// MARK: - String Extension for Text Size Calculation
private extension String {
    func size(withAttributes attributes: [NSAttributedString.Key: Any]) -> CGSize {
        let attributedString = NSAttributedString(string: self, attributes: attributes)
        let boundingRect = attributedString.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return boundingRect.size
    }
}

// MARK: - iPad-Specific Button Styles

struct iPadProfileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct iPadActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - iPad-Specific Extension

extension View {
    @available(iOS 17.0, *)
    func profileSwitcherOverlay_iPad(isPresented: Binding<Bool>) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            ProfileSwitcherOverlay_iPad(isPresented: isPresented)
                .background(.clear)
        }
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
struct ProfileSwitcherOverlay_iPad_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPad Pro 12.9" Preview
            ZStack {
                Color.blue.ignoresSafeArea()
                ProfileSwitcherOverlay_iPad(isPresented: .constant(true))
                    .environmentObject(ProfileManager())
                    .environmentObject(ThemeManager())
            }
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewDisplayName("iPad Pro 12.9\"")
            
            // iPad Air Preview
            ZStack {
                Color.green.ignoresSafeArea()
                ProfileSwitcherOverlay_iPad(isPresented: .constant(true))
                    .environmentObject(ProfileManager())
                    .environmentObject(ThemeManager())
            }
            .previewDevice("iPad Air (5th generation)")
            .previewDisplayName("iPad Air")
            
            // iPad Mini Preview (Compact)
            ZStack {
                Color.purple.ignoresSafeArea()
                ProfileSwitcherOverlay_iPad(isPresented: .constant(true))
                    .environmentObject(ProfileManager())
                    .environmentObject(ThemeManager())
            }
            .previewDevice("iPad mini (6th generation)")
            .previewDisplayName("iPad Mini")
        }
    }
}