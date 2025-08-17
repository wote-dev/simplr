//
//  ProfileManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import Foundation
import SwiftUI
import os.log
#if !WIDGET_TARGET
import WidgetKit
#endif

// MARK: - User Profile
enum UserProfile: String, CaseIterable, Codable {
    case personal = "Personal"
    case work = "Work"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .personal:
            return "person.circle"
        case .work:
            return "briefcase.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .personal:
            return .blue
        case .work:
            return .orange
        }
    }
    
    // Profile-specific categories
    var defaultCategories: [TaskCategory] {
        switch self {
        case .personal:
            return TaskCategory.personalPredefined
        case .work:
            return TaskCategory.workPredefined
        }
    }
}



// MARK: - Profile Manager
class ProfileManager: ObservableObject {
    @Published var currentProfile: UserProfile = .personal
    @Published var isProfileSwitchingEnabled: Bool = true
    
    private let userDefaults = UserDefaults(suiteName: "group.com.danielzverev.simplr") ?? UserDefaults.standard
    private let currentProfileKey = "CurrentUserProfile"
    private let profileSwitchingEnabledKey = "ProfileSwitchingEnabled"
    
    // Profile-specific storage keys
    private func tasksKey(for profile: UserProfile) -> String {
        return "SavedTasks_\(profile.rawValue)"
    }
    
    private func categoriesKey(for profile: UserProfile) -> String {
        return "SavedCategories_\(profile.rawValue)"
    }
    
    private func selectedFilterKey(for profile: UserProfile) -> String {
        return "SelectedCategoryFilter_\(profile.rawValue)"
    }
    
    private func collapsedCategoriesKey(for profile: UserProfile) -> String {
        return "CollapsedCategories_\(profile.rawValue)"
    }
    
    init() {
        loadCurrentProfile()
        loadProfileSwitchingEnabled()
        
        // Migrate existing data to personal profile if needed
        migrateExistingDataIfNeeded()
    }
    
    // MARK: - Profile Management
    
    func switchToProfile(_ profile: UserProfile) {
        guard profile != currentProfile else { return }
        
        let previousProfile = currentProfile
        currentProfile = profile
        saveCurrentProfile()
        
        // Post notification for profile switch
        NotificationCenter.default.post(
            name: NSNotification.Name("ProfileDidChange"),
            object: self,
            userInfo: [
                "previousProfile": previousProfile,
                "currentProfile": profile
            ]
        )
        
        // Force immediate widget update to reflect new profile data
        #if !WIDGET_TARGET
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
        
        // Haptic feedback
        HapticManager.shared.selectionChange()
        
        os_log("Switched from %@ to %@ profile", log: OSLog.default, type: .info, 
               previousProfile.rawValue, profile.rawValue)
    }
    
    func enableProfileSwitching() {
        isProfileSwitchingEnabled = true
        saveProfileSwitchingEnabled()
        
        // Initialize work profile with default categories if not already done
        initializeWorkProfileIfNeeded()
    }
    
    func disableProfileSwitching() {
        // Switch back to personal profile when disabling
        if currentProfile != .personal {
            switchToProfile(.personal)
        }
        
        isProfileSwitchingEnabled = false
        saveProfileSwitchingEnabled()
    }
    
    // MARK: - Profile-Specific Data Access
    
    func getTasksKey() -> String {
        return tasksKey(for: currentProfile)
    }
    
    func getCategoriesKey() -> String {
        return categoriesKey(for: currentProfile)
    }
    
    func getSelectedFilterKey() -> String {
        return selectedFilterKey(for: currentProfile)
    }
    
    func getCollapsedCategoriesKey() -> String {
        return collapsedCategoriesKey(for: currentProfile)
    }
    
    // MARK: - Data Migration
    
    private func migrateExistingDataIfNeeded() {
        let migrationKey = "ProfileDataMigrated"
        guard !userDefaults.bool(forKey: migrationKey) else { return }
        
        // Migrate existing tasks to personal profile
        if let existingTasksData = userDefaults.data(forKey: "SavedTasks") {
            userDefaults.set(existingTasksData, forKey: tasksKey(for: .personal))
            os_log("Migrated existing tasks to personal profile", log: OSLog.default, type: .info)
        }
        
        // Migrate existing categories to personal profile
        if let existingCategoriesData = userDefaults.data(forKey: "SavedCategories") {
            userDefaults.set(existingCategoriesData, forKey: categoriesKey(for: .personal))
            os_log("Migrated existing categories to personal profile", log: OSLog.default, type: .info)
        }
        
        // Migrate existing filter selection to personal profile
        if let existingFilterData = userDefaults.data(forKey: "SelectedCategoryFilter") {
            userDefaults.set(existingFilterData, forKey: selectedFilterKey(for: .personal))
        }
        
        // Migrate existing collapsed categories to personal profile
        if let existingCollapsedData = userDefaults.data(forKey: "CollapsedCategories") {
            userDefaults.set(existingCollapsedData, forKey: collapsedCategoriesKey(for: .personal))
        }
        
        userDefaults.set(true, forKey: migrationKey)
        os_log("Profile data migration completed", log: OSLog.default, type: .info)
    }
    
    private func initializeWorkProfileIfNeeded() {
        let workInitKey = "WorkProfileInitialized"
        guard !userDefaults.bool(forKey: workInitKey) else { return }
        
        // Initialize work profile with default categories
        let workCategories = UserProfile.work.defaultCategories
        if let encoded = try? JSONEncoder().encode(workCategories) {
            userDefaults.set(encoded, forKey: categoriesKey(for: .work))
        }
        
        userDefaults.set(true, forKey: workInitKey)
        os_log("Initialized work profile with default categories", log: OSLog.default, type: .info)
    }
    
    // MARK: - Persistence
    
    private func saveCurrentProfile() {
        userDefaults.set(currentProfile.rawValue, forKey: currentProfileKey)
        userDefaults.set(currentProfile.rawValue, forKey: "CurrentProfile") // For widget compatibility
    }
    
    private func loadCurrentProfile() {
        if let profileString = userDefaults.string(forKey: currentProfileKey),
           let profile = UserProfile(rawValue: profileString) {
            currentProfile = profile
        }
    }
    
    private func saveProfileSwitchingEnabled() {
        userDefaults.set(isProfileSwitchingEnabled, forKey: profileSwitchingEnabledKey)
    }
    
    private func loadProfileSwitchingEnabled() {
        isProfileSwitchingEnabled = userDefaults.bool(forKey: profileSwitchingEnabledKey)
    }
    
    // MARK: - Profile Statistics
    
    func getTaskCount(for profile: UserProfile) -> Int {
        guard let tasksData = userDefaults.data(forKey: tasksKey(for: profile)),
              let tasks = try? JSONDecoder().decode([Task].self, from: tasksData) else {
            return 0
        }
        return tasks.count
    }
    
    func getActiveTaskCount(for profile: UserProfile) -> Int {
        guard let tasksData = userDefaults.data(forKey: tasksKey(for: profile)),
              let tasks = try? JSONDecoder().decode([Task].self, from: tasksData) else {
            return 0
        }
        return tasks.filter { !$0.isCompleted }.count
    }
    
    // MARK: - Profile Validation
    
    func hasDataInProfile(_ profile: UserProfile) -> Bool {
        return getTaskCount(for: profile) > 0
    }
    
    func shouldShowProfileSwitcher() -> Bool {
        return hasDataInProfile(.personal) && hasDataInProfile(.work)
    }
}

// MARK: - Profile Manager Singleton
extension ProfileManager {
    static let shared = ProfileManager()
}