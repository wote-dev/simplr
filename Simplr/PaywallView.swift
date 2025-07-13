//
//  PaywallView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var premiumManager: PremiumManager
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    let targetFeature: PremiumFeature?
    
    @State private var selectedPlan: PurchasePlan = .kawaiiTheme
    @State private var showingFeatureDetail = false
    
    init(targetFeature: PremiumFeature? = nil) {
        self.targetFeature = targetFeature
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Kawaii inspired gradient background
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.97),
                        Color(red: 1.0, green: 0.88, blue: 0.93),
                        Color(red: 1.0, green: 0.82, blue: 0.89)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Feature showcase
                        if let feature = targetFeature {
                            featuredThemeSection(feature)
                        } else {
                            allFeaturesSection
                        }
                        
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                        HapticManager.shared.buttonTap()
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.6))
                }
            }
        }
        .onAppear {
            if let feature = targetFeature, feature == .kawaiiTheme {
                selectedPlan = .kawaiiTheme
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Cute icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.2, blue: 0.6),
                                Color(red: 1.0, green: 0.4, blue: 0.7),
                                Color(red: 1.0, green: 0.6, blue: 0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: Color(red: 1.0, green: 0.4, blue: 0.7).opacity(0.3),
                        radius: 15,
                        y: 8
                    )
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Unlock Premium Themes")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(-0.5)
                    .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.3))
                
                Text("Transform your Simplr experience with adorable themes and exclusive features")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
    }
    
    // MARK: - Featured Theme Section
    private func featuredThemeSection(_ feature: PremiumFeature) -> some View {
        VStack(spacing: 20) {
            Text("✨ " + feature.displayName)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .tracking(-0.3)
                .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.6))
            
            // Theme preview card
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kawaii Theme")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.3))
                        
                        Text("Adorable pink gradients with cute aesthetics")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.5))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.7))
                }
                
                // Mini preview
                HStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.98, blue: 0.99),
                                        Color(red: 1.0, green: 0.92, blue: 0.95)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(red: 1.0, green: 0.4, blue: 0.7).opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: Color(red: 1.0, green: 0.4, blue: 0.7).opacity(0.15),
                        radius: 12,
                        y: 6
                    )
            )
        }
    }
    
    // MARK: - All Features Section
    private var allFeaturesSection: some View {
        VStack(spacing: 16) {
            Text("Premium Features")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .tracking(-0.3)
                .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.3))
            
            VStack(spacing: 12) {
                ForEach(PremiumFeature.allCases, id: \.self) { feature in
                    featureRow(feature)
                }
            }
        }
    }
    
    private func featureRow(_ feature: PremiumFeature) -> some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title3)
                .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.6))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.3))
                
                Text(feature.description)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.5))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 1.0, green: 0.4, blue: 0.7).opacity(0.2), lineWidth: 0)
                )
        )
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .tracking(-0.3)
                .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.3))
            
            VStack(spacing: 12) {
                pricingCard(.kawaiiTheme)
                pricingCard(.premiumMonthly)
            }
        }
    }
    
    private func pricingCard(_ plan: PurchasePlan) -> some View {
        Button {
            selectedPlan = plan
            HapticManager.shared.buttonTap()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.3))
                        
                        if plan.isPopular {
                            Text("POPULAR")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 1.0, green: 0.2, blue: 0.6))
                                )
                        }
                        
                        Spacer()
                    }
                    
                    Text(plan.description)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.5))
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(plan.price)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.6))
                    
                    if !plan.period.isEmpty {
                        Text(plan.period)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.5))
                    }
                }
                
                Image(systemName: selectedPlan == plan ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selectedPlan == plan ? Color(red: 1.0, green: 0.2, blue: 0.6) : Color(red: 0.7, green: 0.5, blue: 0.6))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                selectedPlan == plan ? 
                                Color(red: 1.0, green: 0.2, blue: 0.6) : 
                                Color(red: 1.0, green: 0.4, blue: 0.7).opacity(0.3),
                                lineWidth: 0
                            )
                    )
                    .shadow(
                        color: selectedPlan == plan ? 
                        Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.2) : 
                        Color(red: 1.0, green: 0.4, blue: 0.7).opacity(0.1),
                        radius: selectedPlan == plan ? 12 : 6,
                        y: selectedPlan == plan ? 6 : 3
                    )
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
                purchaseSelected()
            } label: {
                HStack {
                    if premiumManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                    }
                    
                    Text(premiumManager.isLoading ? "Processing..." : "Unlock \(selectedPlan.title)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.2, blue: 0.6),
                                    Color(red: 1.0, green: 0.4, blue: 0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(
                            color: Color(red: 1.0, green: 0.2, blue: 0.6).opacity(0.4),
                            radius: 12,
                            y: 6
                        )
                )
            }
            .disabled(premiumManager.isLoading)
            .scaleEffect(premiumManager.isLoading ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: premiumManager.isLoading)
            
            Button {
                premiumManager.restorePurchases()
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.5))
            }
            .disabled(premiumManager.isLoading)
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("• Cancel anytime • Secure payment • Instant access")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.5))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Terms") {
                    // Handle terms
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.5))
                
                Button("Privacy") {
                    // Handle privacy
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.5))
            }
        }
    }
    
    // MARK: - Actions
    private func purchaseSelected() {
        HapticManager.shared.buttonTap()
        
        switch selectedPlan {
        case .kawaiiTheme:
            premiumManager.purchaseFeature(.kawaiiTheme)
        case .premiumMonthly:
            premiumManager.purchasePremium()
        }
    }
}

// MARK: - Purchase Plans
enum PurchasePlan: CaseIterable {
    case kawaiiTheme
    case premiumMonthly
    
    var title: String {
        switch self {
        case .kawaiiTheme:
            return "Kawaii Theme"
        case .premiumMonthly:
            return "Premium Monthly"
        }
    }
    
    var description: String {
        switch self {
        case .kawaiiTheme:
            return "Unlock the adorable kawaii theme with pink gradients"
        case .premiumMonthly:
            return "All premium themes and features included"
        }
    }
    
    var price: String {
        switch self {
        case .kawaiiTheme:
            return "$2.99"
        case .premiumMonthly:
            return "$4.99"
        }
    }
    
    var period: String {
        switch self {
        case .kawaiiTheme:
            return "one-time"
        case .premiumMonthly:
            return "per month"
        }
    }
    
    var isPopular: Bool {
        switch self {
        case .kawaiiTheme:
            return true
        case .premiumMonthly:
            return false
        }
    }
}

// MARK: - Preview
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView(targetFeature: .kawaiiTheme)
            .environmentObject(PremiumManager())
            .environment(\.theme, LightTheme())
    }
}