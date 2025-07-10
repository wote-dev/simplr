//
//  PremiumManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import StoreKit

// MARK: - Premium Features
enum PremiumFeature: String, CaseIterable {
    case kawaiiTheme = "kawaii_theme"
    case additionalThemes = "additional_themes"
    case advancedFeatures = "advanced_features"
    
    var displayName: String {
        switch self {
        case .kawaiiTheme:
            return "Kawaii Theme"
        case .additionalThemes:
            return "Premium Themes"
        case .advancedFeatures:
            return "Advanced Features"
        }
    }
    
    var description: String {
        switch self {
        case .kawaiiTheme:
            return "Adorable kawaii inspired theme with pink gradients and cute aesthetics"
        case .additionalThemes:
            return "Access to exclusive premium themes"
        case .advancedFeatures:
            return "Unlock advanced productivity features"
        }
    }
    
    var icon: String {
        switch self {
        case .kawaiiTheme:
            return "heart.fill"
        case .additionalThemes:
            return "paintbrush.pointed.fill"
        case .advancedFeatures:
            return "star.fill"
        }
    }
}

// MARK: - Premium Manager
class PremiumManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var purchasedFeatures: Set<PremiumFeature> = []
    @Published var isLoading: Bool = false
    @Published var showingPaywall: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let premiumKey = "isPremium"
    private let featuresKey = "purchasedFeatures"
    
    // Product IDs for App Store
    private let productIDs: [String] = [
        "com.danielzverev.simplr.kawaii_theme",
        "com.danielzverev.simplr.premium_themes",
        "com.danielzverev.simplr.premium_monthly"
    ]
    
    init() {
        loadPremiumStatus()
        
        // For development/testing - uncomment to simulate premium access
        // Temporarily enable kawaii theme access for testing theme persistence
        isPremium = true
        purchasedFeatures = Set(PremiumFeature.allCases)
    }
    
    // MARK: - Premium Status Management
    
    func loadPremiumStatus() {
        isPremium = userDefaults.bool(forKey: premiumKey)
        
        if let featuresData = userDefaults.data(forKey: featuresKey),
           let features = try? JSONDecoder().decode(Set<PremiumFeature>.self, from: featuresData) {
            purchasedFeatures = features
        }
    }
    
    private func savePremiumStatus() {
        userDefaults.set(isPremium, forKey: premiumKey)
        
        if let featuresData = try? JSONEncoder().encode(purchasedFeatures) {
            userDefaults.set(featuresData, forKey: featuresKey)
        }
    }
    
    // MARK: - Feature Access
    
    func hasAccess(to feature: PremiumFeature) -> Bool {
        return isPremium || purchasedFeatures.contains(feature)
    }
    
    func requiresPremium(for feature: PremiumFeature) -> Bool {
        return !hasAccess(to: feature)
    }
    
    // MARK: - Purchase Management
    
    func purchaseFeature(_ feature: PremiumFeature) {
        isLoading = true
        
        // Simulate purchase process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isLoading = false
            
            // For demo purposes, always succeed
            // In production, integrate with StoreKit
            self.purchasedFeatures.insert(feature)
            
            if feature == .kawaiiTheme || self.purchasedFeatures.count >= 2 {
                self.isPremium = true
            }
            
            self.savePremiumStatus()
            self.showingPaywall = false
            
            // Show success feedback
            HapticManager.shared.successFeedback()
        }
    }
    
    func purchasePremium() {
        isLoading = true
        
        // Simulate premium purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isLoading = false
            self.isPremium = true
            self.purchasedFeatures = Set(PremiumFeature.allCases)
            self.savePremiumStatus()
            self.showingPaywall = false
            
            // Show success feedback
            HapticManager.shared.successFeedback()
        }
    }
    
    func restorePurchases() {
        isLoading = true
        
        // Simulate restore process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            
            // For demo purposes, restore some features
            // In production, query StoreKit for actual purchases
            self.purchasedFeatures.insert(.kawaiiTheme)
            self.savePremiumStatus()
            
            HapticManager.shared.buttonTap()
        }
    }
    
    // MARK: - Paywall Presentation
    
    func showPaywall(for feature: PremiumFeature? = nil) {
        showingPaywall = true
        HapticManager.shared.buttonTap()
    }
    
    func dismissPaywall() {
        showingPaywall = false
    }
}

// MARK: - Premium Feature Extensions
extension PremiumFeature: Codable {}

// MARK: - View Extensions
extension View {
    func premiumGated(_ feature: PremiumFeature, premiumManager: PremiumManager) -> some View {
        self.onTapGesture {
            if premiumManager.requiresPremium(for: feature) {
                premiumManager.showPaywall(for: feature)
            }
        }
    }
}