//
//  PaywallView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//
//  OPTIMIZED POST-PURCHASE FLOW:
//  1. User previews and selects a premium theme in the paywall
//  2. After successful purchase, welcome message displays with selected theme styling
//  3. User acknowledges welcome message
//  4. Selected theme is automatically applied
//  5. User returns directly to main app with their chosen theme
//  
//  PERFORMANCE OPTIMIZATIONS:
//  - Theme instances are cached to avoid repeated creation
//  - Theme updates only occur when actually changed
//  - Welcome message uses selected premium theme instead of environment theme
//  - Optimized animation timing for smoother user experience
//  - Efficient memory management with proper cleanup
//  
//  This eliminates the extra theme selection step and provides
//  a seamless, performance-optimized user experience.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPlan: PurchasePlan = .premiumAnnual
    @State private var offerings: Offerings?
    @State private var selectedThemePreview: ThemeMode = .kawaii
    @State private var previewTheme: Theme = KawaiiTheme()
    @State private var showWelcomeMessage = false
    @State private var purchaseCompleted = false
    @State private var selectedPremiumTheme: ThemeMode = .kawaii // Track the theme selected during purchase for post-purchase application
    
    // Performance optimization: Cache theme instances to avoid repeated creation
    private let themeCache: [ThemeMode: Theme] = [
        .kawaii: KawaiiTheme(),
        .lightGreen: LightGreenTheme(),
        .serene: SereneTheme(),
        .coffee: CoffeeTheme()
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background based on selected theme preview
                previewTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Theme preview section
                        themePreviewSection
                        
                        // Premium themes showcase
                        premiumThemesSection
                        
                        // Pricing plans
                        pricingSection
                        
                        // Purchase buttons
                        purchaseSection
                        
                        // Footer
                        footerSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(previewTheme.surface.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        // Reset paywall state in PremiumManager to allow re-access
                        premiumManager.dismissPaywall()
                        dismiss()
                        HapticManager.shared.buttonTap()
                    }
                    .foregroundColor(previewTheme.accent)
                }
            }
        }
        .overlay {
            // Welcome message overlay
            if showWelcomeMessage {
                WelcomeMessageOverlay(
                    selectedTheme: getTheme(for: selectedPremiumTheme),
                    selectedThemeMode: selectedPremiumTheme,
                    onContinue: {
                        // Provide haptic feedback for successful completion
                        HapticManager.shared.successFeedback()
                        
                        // Apply the selected premium theme only if it's different from current
                        if themeManager.themeMode != selectedPremiumTheme {
                            themeManager.setThemeMode(selectedPremiumTheme, checkPremium: false)
                        }
                        
                        // Dismiss welcome message with animation
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showWelcomeMessage = false
                        }
                        
                        // Small delay before dismissing paywall to return to main app
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // Reset paywall state before dismissing
                            premiumManager.dismissPaywall()
                            dismiss()
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity.combined(with: .scale(scale: 1.1))
                ))
                .zIndex(1000)
            }
        }
        // Theme selector is no longer needed in post-purchase flow
        // Users will return directly to the main app with their selected theme
        .onAppear {
            selectedPlan = .premiumAnnual
            loadOfferings()
            updatePreviewTheme()
            // Initialize the selected premium theme to match the preview
            selectedPremiumTheme = selectedThemePreview
        }
        .onDisappear {
            // Ensure paywall state is reset when view disappears (handles swipe-to-dismiss)
            premiumManager.dismissPaywall()
        }
        .onChange(of: selectedThemePreview) { _, newTheme in
            updatePreviewTheme()
            // Track the selected theme for post-purchase application
            selectedPremiumTheme = newTheme
        }
        // showThemeSelector onChange handler removed - no longer needed in optimized flow
    }
    
    // MARK: - Helper Functions
    private func updatePreviewTheme() {
        // Performance optimization: Only update if theme actually changed
        let newTheme = getTheme(for: selectedThemePreview)
        guard type(of: newTheme) != type(of: previewTheme) else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            previewTheme = newTheme
        }
    }
    
    // MARK: - Pricing Logic
    private func getDisplayPrice(for plan: PurchasePlan) -> String {
        guard let offerings = offerings,
              let currentOffering = offerings.current else {
            // Fallback prices when no offerings available
            return plan.fallbackPrice
        }
        
        switch plan {
        case .premiumMonthly:
            // First try the standard monthly package
            if let package = currentOffering.monthly {
                return package.storeProduct.localizedPriceString
            }
            // Fallback: search all packages for monthly product ID
            if let package = currentOffering.availablePackages.first(where: { 
                $0.storeProduct.productIdentifier == "simplr.premium.monthly.sub" 
            }) {
                return package.storeProduct.localizedPriceString
            }
            return plan.fallbackPrice
            
        case .premiumAnnual:
            // First try the standard annual package
            if let package = currentOffering.annual {
                return package.storeProduct.localizedPriceString
            }
            // Fallback: search all packages for annual product ID
            if let package = currentOffering.availablePackages.first(where: { 
                $0.storeProduct.productIdentifier == "simplr.premium.annual.sub" 
            }) {
                return package.storeProduct.localizedPriceString
            }
            return plan.fallbackPrice
        }
    }
    
    // MARK: - Purchase Logic
    private func initiatePurchase(for plan: PurchasePlan) {
        guard let offerings = offerings,
              let currentOffering = offerings.current else {
            print("Error: No offerings available")
            return
        }
        
        let packageToPurchase: Package?
        
        switch plan {
        case .premiumAnnual:
            // First try the standard annual package
            packageToPurchase = currentOffering.annual ??
                currentOffering.availablePackages.first(where: {
                    $0.storeProduct.productIdentifier == "simplr.premium.annual.sub"
                })
        case .premiumMonthly:
            // First try the standard monthly package
            packageToPurchase = currentOffering.monthly ??
                currentOffering.availablePackages.first(where: {
                    $0.storeProduct.productIdentifier == "simplr.premium.monthly.sub"
                })
        }
        
        guard let package = packageToPurchase else {
            print("Error: Package not found for plan \(plan)")
            return
        }
        
        premiumManager.isLoading = true
        
        // --- THIS IS THE UPDATED AND SAFER PURCHASE LOGIC ---
        Purchases.shared.purchase(package: package) { [weak premiumManager] transaction, customerInfo, error, userCancelled in
            DispatchQueue.main.async {
                premiumManager?.isLoading = false
                
                if userCancelled {
                    print("Purchase cancelled by user.")
                    return
                }

                if let error = error {
                    print("Purchase error: \(error.localizedDescription)")
                    return
                }
                
                guard let customerInfo = customerInfo else {
                    print("Error: CustomerInfo is missing after purchase.")
                    return
                }

                // Explicitly check if the 'premium' entitlement is now active.
                if customerInfo.entitlements["premium"]?.isActive == true {
                    
                    // The user is officially premium. NOW we can show the welcome message.
                    print("✅ Purchase successful! User has 'premium' entitlement.")
                    HapticManager.shared.successFeedback()
                    
                    self.purchaseCompleted = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            self.showWelcomeMessage = true
                        }
                    }
                    
                } else {
                    // This is a rare but important edge case.
                    // The purchase succeeded, but for some reason, the entitlement isn't active.
                    print("❌ Purchase succeeded, but entitlement 'premium' is not active. Check RevenueCat dashboard setup.")
                }
            }
        }
    }
    
    // MARK: - RevenueCat Integration
    private func loadOfferings() {
        Purchases.shared.getOfferings { [self] offerings, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error loading offerings: \(error.localizedDescription)")
                } else if let offerings = offerings {
                    self.offerings = offerings
                    print("✅ Loaded offerings successfully")
                }
            }
        }
    }
    
    // MARK: - Restore Purchases
    private func restorePurchases() {
        premiumManager.restorePurchases()
        HapticManager.shared.buttonTap()
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Dynamic icon based on selected theme
            ZStack {
                Circle()
                    .fill(previewTheme.accentGradient)
                    .frame(width: 80, height: 80)
                    .applyShadow(previewTheme.cardShadowStyle)
                
                Image(systemName: selectedThemePreview.icon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(previewTheme.background)
            }
            
            VStack(spacing: 8) {
                Text("Unlock Beautiful Themes")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(-0.5)
                    .foregroundColor(previewTheme.text)
                    .multilineTextAlignment(.center)
                
                Text("Transform your Simplr experience with stunning premium themes that match your style")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(previewTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
    }
    
    // MARK: - Theme Preview Section
    private var themePreviewSection: some View {
        VStack(spacing: 20) {
            Text("Live Preview")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .tracking(-0.3)
                .foregroundColor(previewTheme.text)
            
            // Mock task card preview
            VStack(spacing: 12) {
                HStack {
                    Text("Today")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(previewTheme.text)
                    Spacer()
                    Text("3 tasks")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(previewTheme.textSecondary)
                }
                
                VStack(spacing: 8) {
                    mockTaskRow("Review quarterly goals", isCompleted: false)
                    mockTaskRow("Team standup meeting", isCompleted: true)
                    mockTaskRow("Update project timeline", isCompleted: false)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(previewTheme.surfaceGradient)
                    .applyShadow(previewTheme.cardShadowStyle)
            )
        }
    }
    
    private func mockTaskRow(_ title: String, isCompleted: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isCompleted ? previewTheme.success : previewTheme.accent)
            
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(isCompleted ? previewTheme.textSecondary : previewTheme.text)
                .strikethrough(isCompleted)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Premium Themes Section
    private var premiumThemesSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Style")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .tracking(-0.3)
                .foregroundColor(previewTheme.text)
            
            // Two rows of theme cards for better layout with 4 themes
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ForEach([ThemeMode.kawaii, ThemeMode.lightGreen], id: \.self) { themeMode in
                        themePreviewCard(themeMode)
                    }
                }
                
                HStack(spacing: 12) {
                    ForEach([ThemeMode.serene, ThemeMode.coffee], id: \.self) { themeMode in
                        themePreviewCard(themeMode)
                    }
                }
            }
        }
    }
    
    private func themePreviewCard(_ themeMode: ThemeMode) -> some View {
        let isSelected = selectedThemePreview == themeMode
        let cardTheme = getTheme(for: themeMode)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedThemePreview = themeMode
            }
            HapticManager.shared.buttonTap()
        } label: {
            VStack(spacing: 8) {
                // Theme color preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(cardTheme.accentGradient)
                    .frame(height: 40)
                    .overlay(
                        Image(systemName: themeMode.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(cardTheme.background)
                    )
                
                Text(themeMode.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(previewTheme.text)
                    .lineLimit(1)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(previewTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? previewTheme.accent : Color.clear, lineWidth: 2)
                    )
                    .applyShadow(isSelected ? previewTheme.cardShadowStyle : previewTheme.shadowStyle)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func getTheme(for mode: ThemeMode) -> Theme {
        // Performance optimization: Use cached theme instances
        return themeCache[mode] ?? KawaiiTheme()
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Unlock All Themes")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .tracking(-0.3)
                .foregroundColor(previewTheme.text)
            
            Text("Get unlimited access to all premium themes and future releases")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(previewTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(PurchasePlan.allCases, id: \.self) { plan in
                    pricingCard(plan)
                }
            }
        }
    }
    
    private func pricingCard(_ plan: PurchasePlan) -> some View {
        let isSelected = selectedPlan == plan
        
        return Button {
            selectedPlan = plan
            HapticManager.shared.buttonTap()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(previewTheme.text)
                        
                        if plan.isPopular {
                            Text("POPULAR")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(previewTheme.background)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(previewTheme.accent)
                                )
                        }
                        
                        Spacer()
                    }
                    
                    Text(plan.description)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(previewTheme.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(getDisplayPrice(for: plan))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(previewTheme.accent)
                    
                    Text(plan.period)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(previewTheme.textSecondary)
                }
                
                Image(systemName: selectedPlan == plan ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selectedPlan == plan ? previewTheme.accent : previewTheme.textSecondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(previewTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                selectedPlan == plan ? 
                                previewTheme.accent : 
                                previewTheme.accent.opacity(0.3),
                                lineWidth: isSelected ? 2 : 0.8
                            )
                    )
                    .applyShadow(isSelected ? previewTheme.cardShadowStyle : previewTheme.shadowStyle)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedPlan == plan ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPlan)
    }
    
    // MARK: - Purchase Section
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            Button {
                initiatePurchase(for: selectedPlan)
                HapticManager.shared.buttonTap()
            } label: {
                HStack {
                    if premiumManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: previewTheme.background))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                    }
                    
                    Text(premiumManager.isLoading ? "Processing..." : "Unlock All Themes")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(previewTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(previewTheme.accentGradient)
                        .applyShadow(previewTheme.cardShadowStyle)
                )
            }
            .disabled(premiumManager.isLoading)
            .scaleEffect(premiumManager.isLoading ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: premiumManager.isLoading)
            
            Button {
                restorePurchases()
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(previewTheme.textSecondary)
            }
            .disabled(premiumManager.isLoading)
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("• Cancel anytime • Secure payment • Instant access")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(previewTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Terms") {
                    // Handle terms
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(previewTheme.textSecondary)
                
                Button("Privacy") {
                    // Handle privacy
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(previewTheme.textSecondary)
            }
        }
    }
}

// MARK: - Purchase Plans
enum PurchasePlan: CaseIterable {
    case premiumMonthly
    case premiumAnnual
    
    var title: String {
        switch self {
        case .premiumMonthly:
            return "Premium Monthly"
        case .premiumAnnual:
            return "Premium Annual"
        }
    }
    
    var description: String {
        switch self {
        case .premiumMonthly:
            return "All premium themes and features included"
        case .premiumAnnual:
            return "All premium themes and features included - Best Value!"
        }
    }
    
    var fallbackPrice: String {
        switch self {
        case .premiumMonthly:
            return "$1.99"
        case .premiumAnnual:
            return "$14.99"
        }
    }
    
    var period: String {
        switch self {
        case .premiumMonthly:
            return "per month"
        case .premiumAnnual:
            return "per year"
        }
    }
    
    var isPopular: Bool {
        switch self {
        case .premiumMonthly:
            return false
        case .premiumAnnual:
            return true // Annual plan is most popular
        }
    }
}

// MARK: - Welcome Message Overlay
struct WelcomeMessageOverlay: View {
    let selectedTheme: Theme // Use the selected premium theme instead of environment theme
    let selectedThemeMode: ThemeMode // Track the selected theme mode for display
    let onContinue: () -> Void
    
    @State private var animateContent = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Background blur with selected theme colors
            selectedTheme.background.opacity(0.1)
                .overlay(Color.black.opacity(0.3))
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissing by tapping background
                }
            
            // Welcome card
            VStack(spacing: 32) {
                // Success icon with animation using selected theme colors
                ZStack {
                    Circle()
                        .fill(selectedTheme.accent.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                    
                    Circle()
                        .fill(selectedTheme.accent.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateContent ? 1.0 : 0.7)
                    
                    // Use the selected theme's icon instead of crown
                    Image(systemName: selectedThemeMode.icon)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(selectedTheme.accent)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateContent)
                
                // Welcome text with theme-specific messaging
                VStack(spacing: 16) {
                    Text("Welcome to Premium!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.text)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                    
                    Text("You now have access to all premium themes! Your \(selectedThemeMode.displayName) theme has been applied and is ready to use.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateContent)
                
                // Continue button with selected theme styling
                Button {
                    HapticManager.shared.buttonTap()
                    onContinue()
                } label: {
                    HStack(spacing: 12) {
                        Text("Continue to App")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(selectedTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedTheme.accentGradient)
                            .applyShadow(selectedTheme.cardShadowStyle)
                    )
                }
                .scaleEffect(animateButton ? 1.0 : 0.9)
                .opacity(animateButton ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.8), value: animateButton)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(selectedTheme.surfaceGradient)
                    .applyShadow(selectedTheme.cardShadowStyle)
            )
            .padding(.horizontal, 24)
            .scaleEffect(animateContent ? 1.0 : 0.9)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.spring(response: 0.7, dampingFraction: 0.8), value: animateContent)
        }
        .onAppear {
            // Performance optimization: Use more efficient animation timing
            // Trigger animations on appear with optimized timing
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    animateContent = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateButton = true
                }
            }
        }
    }
}

// MARK: - Preview
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
            .environmentObject(PremiumManager())
            .environmentObject(ThemeManager())
            .environment(\.theme, LightTheme())
    }
}