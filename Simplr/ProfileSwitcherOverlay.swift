//
//  ProfileSwitcherOverlay.swift
//  Simplr
//
//  Created by AI Assistant on 2025-01-20.
//  Optimized profile switching overlay for instant profile changes
//

import SwiftUI

struct ProfileSwitcherOverlay: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    @Binding var isPresented: Bool
    
    // Performance optimization: Pre-calculate colors
    private var currentProfileColor: Color {
        profileManager.currentProfile.themeAwareColor(for: theme)
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Profile selection card
            VStack(spacing: 0) {
                headerView
                profileOptionsView
                cancelButton
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.surface)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Switch Profile")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(theme.text)
            
            Text("Choose which profile to use")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
    
    private var profileOptionsView: some View {
        VStack(spacing: 12) {
            ForEach(UserProfile.allCases, id: \.self) { profile in
                profileButton(for: profile)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func profileButton(for profile: UserProfile) -> some View {
        Button(action: {
            switchToProfile(profile)
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: profile.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(profile.themeAwareColor(for: theme))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(profile.themeAwareColor(for: theme).opacity(0.1))
                    )
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.displayName)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.text)
                    
                    Text(profileDescription(for: profile))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                // Checkmark for current profile
                if profile == profileManager.currentProfile {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(profile.themeAwareColor(for: theme))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        profile == profileManager.currentProfile ? profile.themeAwareColor(for: theme) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(ProfileButtonStyle())
    }
    
    private var cancelButton: some View {
        Button(action: {
            dismiss()
        }) {
            Text("Cancel")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surfaceSecondary)
                )
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .buttonStyle(CancelButtonStyle())
    }
    
    private func profileDescription(for profile: UserProfile) -> String {
        switch profile {
        case .personal:
            return "Your personal tasks and reminders"
        case .work:
            return "Work-related tasks and projects"
        }
    }
    
    private func switchToProfile(_ profile: UserProfile) {
        guard profile != profileManager.currentProfile else {
            dismiss()
            return
        }
        
        // Immediate haptic feedback
        HapticManager.shared.selectionChange()
        
        // Perform the switch with optimized animation - no delay needed
        profileManager.switchToProfile(profile)
        
        // Dismiss immediately - no delay for better responsiveness
        dismiss()
    }
    
    private func dismissOverlay() {
        dismiss()
    }
}

// Custom button styles for better performance
struct ProfileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CancelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Extension for presenting the overlay using fullScreenCover for better state management
extension View {
    func profileSwitcherOverlay(isPresented: Binding<Bool>) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            ProfileSwitcherOverlay(isPresented: isPresented)
        }
    }
}

// Preview
struct ProfileSwitcherOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            ProfileSwitcherOverlay(isPresented: .constant(true))
                .environmentObject(ProfileManager())
                .environmentObject(ThemeManager())
        }
    }
}