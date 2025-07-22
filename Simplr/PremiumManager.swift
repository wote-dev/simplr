//
//  PremiumManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import StoreKit
import RevenueCat

// MARK: - Premium Features
enum PremiumFeature: String, CaseIterable {
    case premiumAccess = "premium"
    
    var displayName: String {
        return "Premium Access"
    }
    
    var description: String {
        return "Unlock all premium themes and advanced features"
    }
    
    var icon: String {
        return "star.fill"
    }
}

// MARK: - Premium Manager
class PremiumManager: NSObject, ObservableObject, PurchasesDelegate {
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var showingPaywall: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let premiumKey = "isPremium"
    
    // Product IDs for App Store
    private let productIDs: [String] = [
        "simplr.premium.monthly.sub",
        "simplr.premium.annual.sub"
    ]
    
    override init() {
        super.init()
        loadPremiumStatus()
        setupRevenueCat()
        checkSubscriptionStatus()
    }
    
    private func setupRevenueCat() {
        // Configure RevenueCat with the provided API key
        Purchases.configure(withAPIKey: "appl_RGXidiAkFqiTrNXFrpRQrYgZvTY")
        
        // Set up delegate to listen for subscription changes
        Purchases.shared.delegate = self
    }
    
    private func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                guard let self = self, let customerInfo = customerInfo, error == nil else {
                    return
                }
                
                self.updatePremiumStatus(from: customerInfo)
            }
        }
    }
    
    // Public method to refresh subscription status
    func refreshSubscriptionStatus() {
        checkSubscriptionStatus()
    }
    
    private func updatePremiumStatus(from customerInfo: CustomerInfo) {
        // Simplified entitlement check - only check for the single 'premium' entitlement
        isPremium = customerInfo.entitlements["premium"]?.isActive == true
        savePremiumStatus()
    }
    
    // MARK: - Premium Status Management
    
    func loadPremiumStatus() {
        isPremium = userDefaults.bool(forKey: premiumKey)
    }
    
    private func savePremiumStatus() {
        userDefaults.set(isPremium, forKey: premiumKey)
    }
    
    // MARK: - Feature Access
    
    func hasAccess(to feature: PremiumFeature) -> Bool {
        return isPremium
    }
    
    func requiresPremium(for feature: PremiumFeature) -> Bool {
        return !isPremium
    }
    
    // MARK: - Purchase Management
    
    func purchaseFeature(_ feature: PremiumFeature) {
        guard let productId = getProductId(for: feature) else { return }
        
        isLoading = true
        
        Purchases.shared.getOfferings { [weak self] offerings, error in
            guard let self = self, let offerings = offerings, error == nil else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                return
            }
            
            // Find the package for this product
            var packageToPurchase: Package?
            for offering in offerings.all.values {
                if let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == productId }) {
                    packageToPurchase = package
                    break
                }
            }
            
            guard let package = packageToPurchase else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    if let customerInfo = customerInfo, error == nil, !userCancelled {
                        self.updatePremiumStatus(from: customerInfo)
                        self.showingPaywall = false
                        HapticManager.shared.successFeedback()
                    }
                }
            }
        }
    }
    
    private func getProductId(for feature: PremiumFeature) -> String? {
        return "simplr.premium.monthly.sub"
    }
    
    // Get product ID for annual subscription
    private func getAnnualProductId() -> String {
        return "simplr.premium.annual.sub"
    }
    
    func purchasePremium() {
        // Purchase the premium monthly subscription
        purchaseFeature(.premiumAccess)
    }
    
    func purchaseAnnualPremium() {
        // Purchase the premium annual subscription
        isLoading = true
        
        let productId = getAnnualProductId()
        
        Purchases.shared.getOfferings { [weak self] offerings, error in
            guard let self = self, let offerings = offerings, error == nil else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                return
            }
            
            // Find the package for the annual subscription
            var packageToPurchase: Package?
            for offering in offerings.all.values {
                if let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == productId }) {
                    packageToPurchase = package
                    break
                }
            }
            
            guard let package = packageToPurchase else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    if let customerInfo = customerInfo, error == nil, !userCancelled {
                        self.updatePremiumStatus(from: customerInfo)
                        self.showingPaywall = false
                        HapticManager.shared.successFeedback()
                    }
                }
            }
        }
    }
    
    func restorePurchases() {
        isLoading = true
        
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let customerInfo = customerInfo, error == nil {
                    self.updatePremiumStatus(from: customerInfo)
                }
                
                HapticManager.shared.buttonTap()
            }
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

// MARK: - PurchasesDelegate
extension PremiumManager {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        DispatchQueue.main.async {
            self.updatePremiumStatus(from: customerInfo)
        }
    }
    
    func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase startPurchase: @escaping StartPurchaseBlock) {
        // Handle promoted purchases if needed
        startPurchase { [weak self] transaction, customerInfo, error, userCancelled in
            DispatchQueue.main.async {
                if let customerInfo = customerInfo, error == nil, !userCancelled {
                    self?.updatePremiumStatus(from: customerInfo)
                }
            }
        }
    }
}

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