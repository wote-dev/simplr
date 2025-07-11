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

    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var badgeCountEnabled = true
    @State private var reminderTimeOffset = 15 // minutes before due time
    @State private var showingCreateCategory = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingThemeSelector = false

    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
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
                                        isOn: $badgeCountEnabled
                                    )
                                    
                                    reminderTimePicker
                                }
                            }
                        }
                        
                        // Categories Section
                        settingsSection(title: "Categories", icon: "tag") {
                            VStack(spacing: 16) {
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
                                            .stroke(theme.accent.opacity(0.3), lineWidth: 1)
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
                                    value: "1.5",
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
            NavigationView {
                ThemeSelectorView()
                    .environmentObject(themeManager)
                    .environmentObject(premiumManager)
                    .navigationTitle("Choose Theme")
                    .navigationBarTitleDisplayMode(.inline)
            }
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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.accent)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
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
                            .stroke(theme.textTertiary.opacity(0.1), lineWidth: 1)
                    )
                    .applyNeumorphicShadow(theme.neumorphicStyle)
            )
        }
    }
    
    private var themeModeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme")
                .font(.subheadline)
                .fontWeight(.medium)
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
                    .font(.caption)
                    .fontWeight(.medium)
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
                .font(.caption)
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.text)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(theme.accent)
                .scaleEffect(1.1) // Slightly larger toggle for better visibility
        }
        .padding(.vertical, 4) // Added vertical padding
    }
    
    private var reminderTimePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder Time")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.text)
            
            Text("Notify me before due time")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            Picker("Reminder Time", selection: $reminderTimeOffset) {
                Text("5 minutes before").tag(5)
                Text("15 minutes before").tag(15)
                Text("30 minutes before").tag(30)
                Text("1 hour before").tag(60)
                Text("2 hours before").tag(120)
            }
            .pickerStyle(MenuPickerStyle())
            .tint(theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.accent.opacity(0.2), lineWidth: 0)
                    )
            )
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
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.text)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textSecondary)
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textTertiary)
            }
        }
        .padding(.vertical, 4) // Added vertical padding for better touch targets
        .contentShape(Rectangle())
    }
    
    private var footerView: some View {
        VStack(spacing: 16) {
            Divider()
                .background(theme.textTertiary.opacity(0.3))
            
            Button {
                if let url = URL(string: "https://blackcubesolutions.com") {
                    #if os(iOS)
                    UIApplication.shared.open(url)
                    #endif
                }
                HapticManager.shared.buttonTap()
            } label: {
                HStack(spacing: 8) {
                    Text("Built by")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    
                    Image(themedBCSLogo: themeManager)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 20)
                }
            }
            .animatedButton()
            
            // Support text
            Text("If you like our work, feel free to support us by buying us a coffee")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Buy Me A Coffee link
            Button {
                if let url = URL(string: "https://coff.ee/danielzverev") {
                    #if os(iOS)
                    UIApplication.shared.open(url)
                    #endif
                }
                HapticManager.shared.buttonTap()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)
                    
                    Text("Buy Me A Coffee")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.accent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.accent.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.accent.opacity(0.3), lineWidth: 0)
                        )
                )
            }
            .animatedButton()
        }
        .padding(.top, 20)
    }
    

    
    private func categoryInfoCard(_ category: TaskCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(themeManager.themeMode == .kawaii ? category.color.kawaiiGradient : category.color.gradient)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(
                                themeManager.themeMode == .kawaii ? category.color.kawaiiDarkColor : category.color.darkColor,
                                lineWidth: 1
                            )
                            .opacity(0.3)
                    )
                
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.text)
                    .lineLimit(1)
                
                Spacer()
                
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
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(category.isCustom ? theme.warning : theme.success)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill((category.isCustom ? theme.warning : theme.success).opacity(0.15))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    (themeManager.themeMode == .kawaii ? category.color.kawaiiLightColor.opacity(0.3) : category.color.lightColor.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            (themeManager.themeMode == .kawaii ? category.color.kawaiiColor.opacity(0.3) : category.color.color.opacity(0.3)),
                            lineWidth: 0
                        )
                )
        )
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