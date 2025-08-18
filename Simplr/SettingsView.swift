//
//  SettingsView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import UserNotifications
#if os(iOS)
import UIKit
import SafariServices
#endif

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var profileManager: ProfileManager

    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true

    @State private var showingCreateCategory = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingThemeSelector = false
    
    // Access the shared BadgeManager instance
    private var badgeManager: BadgeManager {
        BadgeManager.shared
    }

    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        settingsSection(title: "Profile", icon: "person.2") {
                            profileSectionContent
                        }
                        
                        // Theme Section
                        settingsSection(title: "Appearance", icon: "paintbrush") {
                            VStack(spacing: 16) {
                                Button {
                                    showingThemeSelector = true
                                } label: {
                                    settingsRow(
                                        title: "Theme",
                                        value: themeManager.themeMode.displayName,
                                        icon: themeManager.themeMode.icon,
                                        showChevron: true
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if themeManager.themeMode == .system {
                                    systemThemeNote
                                }
                            }
                        }
                        

                        
                        // Notifications Section
                        settingsSection(title: "Notifications", icon: "bell") {
                            VStack(spacing: 16) {
                                settingsToggle(
                                    title: "Enable Notifications",
                                    subtitle: "Receive alerts for upcoming tasks",
                                    isOn: $notificationsEnabled
                                )
                                
                                if notificationsEnabled {
                                    settingsToggle(
                                        title: "Sound Alerts",
                                        subtitle: "Play sound with notifications",
                                        isOn: $soundEnabled
                                    )
                                    
                                    settingsToggle(
                                        title: "Badge Count",
                                        subtitle: "Show pending tasks count on app icon",
                                        isOn: Binding(
                                        get: { badgeManager.isBadgeEnabled },
                                        set: { badgeManager.isBadgeEnabled = $0 }
                                    )
                                    )
                                    

                                }
                            }
                        }
                        
                        // Categories Section
                        settingsSection(title: "Categories", icon: "tag") {
                            VStack(spacing: 16) {
                                // Category collapse controls
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Category Display")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(theme.text)
                                        
                                        Spacer()
                                        
                                        Text("\(categoryManager.collapsedCategories.count) collapsed")
                                            .font(.caption)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        // Expand All button
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                categoryManager.expandAllCategories()
                                            }
                                            HapticManager.shared.buttonTap()
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "chevron.down.circle")
                                                    .font(.system(size: 14, weight: .medium))
                                                Text("Expand All")
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .foregroundColor(theme.accent)
                                            .animation(.easeInOut(duration: 0.2), value: theme.accent)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(theme.accent.opacity(0.1))
                                            )
                                        }
                                        .animatedButton()
                                        
                                        // Collapse All button
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                categoryManager.collapseAllCategories()
                                            }
                                            HapticManager.shared.buttonTap()
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "chevron.right.circle")
                                                    .font(.system(size: 14, weight: .medium))
                                                Text("Collapse All")
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .foregroundColor(collapseButtonColor)
                                            .animation(.easeInOut(duration: 0.2), value: collapseButtonColor)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(theme.surfaceSecondary)
                                            )
                                        }
                                        .animatedButton()
                                        
                                        Spacer()
                                    }
                                }
                                
                                Divider()
                                    .background(theme.textSecondary.opacity(0.2))
                                
                                // Category list header
                                HStack {
                                    Text("Manage Categories")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(theme.text)
                                    
                                    Spacer()
                                    
                                    Text("\(categoryManager.categories.count) total")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }
                                
                                // Category grid
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(categoryManager.categories) { category in
                                        categoryInfoCard(category)
                                    }
                                }
                                
                                // Add category button
                                Button(action: {
                                    showingCreateCategory = true
                                    HapticManager.shared.buttonTap()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(theme.accent)
                                        
                                        Text("Add New Category")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(theme.accent)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(theme.accent.opacity(0.3), lineWidth: 0.8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(theme.surface)
                                            )
                                    )
                                }
                                .animatedButton()
                            }
                        }
                        
                        // App Info Section
                        settingsSection(title: "About", icon: "info.circle") {
                            VStack(spacing: 16) {
                                settingsRow(
                                    title: "Version",
                                    value: "1.9.9",
                                    icon: "app.badge"
                                )
                                
                                Button {
                                    #if os(iOS)
                                    showingPrivacyPolicy = true
                                    #endif
                                    HapticManager.shared.buttonTap()
                                } label: {
                                    settingsRow(
                                        title: "Privacy Policy",
                                        value: "",
                                        icon: "hand.raised",
                                        showChevron: true
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button {
                                    #if os(iOS)
                                    showingTermsOfService = true
                                    #endif
                                    HapticManager.shared.buttonTap()
                                } label: {
                                    settingsRow(
                                        title: "Terms of Service",
                                        value: "",
                                        icon: "doc.text",
                                        showChevron: true
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Footer with BCS Logo
                        footerView
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbarColorScheme(theme.background == .black || theme.background == Color(red: 0.02, green: 0.02, blue: 0.02) || theme.background == Color(red: 0.08, green: 0.05, blue: 0.15) || theme.background == Color(red: 0.05, green: 0.08, blue: 0.15) ? .dark : .light, for: .navigationBar)
            .toolbarBackground(theme.surface.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                        HapticManager.shared.buttonTap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Today")
                                .font(.body)
                        }
                        .foregroundColor(theme.accent)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingCreateCategory) {
            CreateCategoryView()
                .environmentObject(categoryManager)
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            #if os(iOS)
            SafariView(url: URL(string: "https://www.blackcubesolutions.com/simplr-privacy")!)
            #endif
        }
        .sheet(isPresented: $showingTermsOfService) {
            #if os(iOS)
            SafariView(url: URL(string: "https://www.blackcubesolutions.com/simplr")!)
            #endif
        }
        .sheet(isPresented: $showingThemeSelector) {
            ThemeSelectorView()
                .environmentObject(themeManager)
                .environmentObject(premiumManager)
        }

    }
    
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(theme.accent)
                
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .tracking(-0.2)
                    .foregroundColor(theme.text)
            }
            
            VStack(spacing: 16) { // Increased spacing between items
                content()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surfaceGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.border, lineWidth: 0.8)
                    )
                    .applyNeumorphicShadow(theme.neumorphicStyle)
            )
        }
    }
    
    private var themeModeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(theme.text)
            
            HStack(spacing: 12) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    themeModeButton(mode)
                }
            }
        }
    }
    
    private func themeModeButton(_ mode: ThemeMode) -> some View {
        Button {
            withAnimation(.smoothSpring) {
                themeManager.setThemeMode(mode, checkPremium: true)
                HapticManager.shared.buttonTap()
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.themeMode == mode ? theme.background : theme.accent)
                
                Text(mode.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.themeMode == mode ? theme.background : theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if themeManager.themeMode == mode {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.accentGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surface)
                    }
                }
                .applyNeumorphicShadow(themeManager.themeMode == mode ? theme.neumorphicPressedStyle : theme.neumorphicButtonStyle)
            )
        }
        .animatedButton()
    }
    
    private var systemThemeNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(theme.accent.opacity(0.7))
            
            Text("Theme will automatically switch based on system appearance")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface.opacity(0.5))
        )
    }
    
    private func settingsToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) { // Increased spacing
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(theme.text)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(theme.toggle)
                .scaleEffect(1.1) // Slightly larger toggle for better visibility
        }
        .padding(.vertical, 4) // Added vertical padding
    }
    

    
    /// Theme-adaptive color for collapse button with enhanced visibility
    private var collapseButtonColor: Color {
        switch themeManager.themeMode {
        case .kawaii:
            return theme.textSecondary.opacity(0.85)
        case .serene:
            return theme.textSecondary.opacity(0.8)
        default:
            if theme is CoffeeTheme {
                return theme.textSecondary.opacity(0.9)
            } else if theme is DarkBlueTheme {
                return theme.textSecondary.opacity(0.95)
            } else {
                return theme.textSecondary
            }
        }
    }
    
    /// Optimized chevron color for settings rows with theme adaptation
    private var settingsChevronColor: Color {
        switch themeManager.themeMode {
        case .kawaii:
            return theme.textTertiary.opacity(0.8)
        case .serene:
            return theme.textTertiary.opacity(0.75)
        default:
            if theme is CoffeeTheme {
                return theme.textTertiary.opacity(0.85)
            } else if theme is DarkBlueTheme {
                return theme.textTertiary.opacity(0.9)
            } else {
                return theme.textTertiary
            }
        }
    }
    
    private func settingsRow(
        title: String,
        value: String,
        icon: String,
        showChevron: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.accent)
                .frame(width: 24, height: 24) // Fixed frame for better alignment
            
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(theme.text)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(settingsChevronColor)
            }
        }
        .padding(.vertical, 4) // Added vertical padding for better touch targets
        .contentShape(Rectangle())
    }
    
    private var profileSectionContent: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Profile")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.text)
                
                Spacer()
                
                Text(profileManager.currentProfile.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accent)
            }
            
            profileSelectionGrid
        }
    }
    
    private var profileSelectionGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 8) {
            ForEach(UserProfile.allCases, id: \.self) { profile in
                profileButton(for: profile)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func profileButton(for profile: UserProfile) -> some View {
        Button(action: {
            profileManager.switchToProfile(profile)
            HapticManager.shared.buttonTap()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    // Circular background for selected state
                    Circle()
                        .fill(profileManager.currentProfile == profile ? 
                              AnyShapeStyle(theme.accentGradient) : 
                              AnyShapeStyle(theme.surface))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(profileManager.currentProfile == profile ? 
                                         Color.clear : 
                                         theme.border.opacity(0.4), 
                                         lineWidth: 0.8)
                        )
                        .animation(.easeInOut(duration: 0.15), value: profileManager.currentProfile)
                    
                    // Icon with optimized size
                    Image(systemName: profile.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(profileManager.currentProfile == profile ? theme.background : profile.themeAwareColor(for: theme))
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Profile name text underneath
                Text(profile.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(profileManager.currentProfile == profile ? theme.accent : theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(profileManager.currentProfile == profile ? 1.02 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: profileManager.currentProfile)
    }
    
    private var footerView: some View {
        VStack(spacing: 16) {
            Divider()
                .background(theme.textTertiary.opacity(0.3))
            
            HStack(spacing: 8) {
                Text("Built by")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)
                
                Image(themedBCSLogo: themeManager)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 20)
            }
        }
        .padding(.top, 20)
    }
    

    
    private func categoryInfoCard(_ category: TaskCategory) -> some View {
        let isKawaii = themeManager.themeMode == .kawaii
        let isSerene = themeManager.themeMode == .serene
        let isCoffee = theme is CoffeeTheme
        let isCollapsed = categoryManager.isCategoryCollapsed(category)
        
        /// Optimized theme-adaptive chevron color for consistent visibility
        let themeAdaptiveChevronColor: Color = {
            switch themeManager.themeMode {
            case .kawaii:
                return theme.textSecondary.opacity(0.8)
            case .serene:
                return theme.textSecondary.opacity(0.75)
            default:
                if theme is CoffeeTheme {
                    return theme.textSecondary.opacity(0.85)
                } else if theme is DarkBlueTheme {
                    return theme.textSecondary.opacity(0.9)
                } else {
                    return theme.textSecondary
                }
            }
        }()
        
        let categoryGradient: LinearGradient = {
            if isKawaii {
                return category.color.kawaiiGradient
            } else if isSerene {
                return category.color.sereneGradient
            } else if isCoffee {
                return category.color.coffeeGradient
            } else {
                return category.color.gradient
            }
        }()
        
        let categoryStrokeColor: Color = {
            if isKawaii {
                return category.color.kawaiiDarkColor
            } else if isSerene {
                return category.color.sereneDarkColor
            } else if isCoffee {
                return category.color.coffeeDarkColor
            } else {
                return category.color.darkColor
            }
        }()
        
        let backgroundFillColor: Color = {
            if isCollapsed {
                return theme.surfaceSecondary
            } else if isKawaii {
                return category.color.kawaiiLightColor.opacity(0.3)
            } else if isSerene {
                return category.color.sereneLightColor.opacity(0.3)
            } else if isCoffee {
                return category.color.coffeeLightColor.opacity(0.25)
            } else {
                return category.color.lightColor.opacity(0.3)
            }
        }()
        
        let strokeColor: Color = {
            if isKawaii {
                return category.color.kawaiiColor.opacity(0.3)
            } else if isSerene {
                return category.color.sereneColor.opacity(0.25)
            } else if isCoffee {
                return category.color.coffeeColor.opacity(0.25) // Enhanced visibility for coffee theme
            } else {
                return category.color.color.opacity(0.3)
            }
        }()
        let statusColor = category.isCustom ? theme.warning : theme.success
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(categoryGradient)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(categoryStrokeColor, lineWidth: 0.8)
                            .opacity(0.3)
                    )
                
                Text(category.name)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(theme.text)
                    .lineLimit(1)
                
                Spacer()
                
                // Theme-adaptive collapse indicator
                if isCollapsed {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(themeAdaptiveChevronColor)
                        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
                }
                
                if category.isCustom {
                    Button(action: {
                        categoryManager.deleteCategory(category)
                        HapticManager.shared.taskDeleted()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.error)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Text(category.isCustom ? "Custom" : "Built-in")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(statusColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.15))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(strokeColor, lineWidth: 0.8)
                )
        )
        .onLongPressGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                categoryManager.toggleCategoryCollapse(category)
            }
            HapticManager.shared.buttonTap()
        }
    }
}

#if os(iOS)
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}
#endif

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(CategoryManager())
        .environmentObject(PremiumManager())
}