//
//  AdaptiveProfileSwitcherOverlay.swift
//  Simplr
//
//  Created by AI Assistant on 2025-01-20.
//  Adaptive profile switcher that automatically selects the optimal layout for each device
//

import SwiftUI

/// Adaptive profile switcher overlay that automatically chooses the best implementation
/// based on device type and screen characteristics
struct AdaptiveProfileSwitcherOverlay: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @Binding var isPresented: Bool
    
    // Device detection for optimal experience
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var shouldUseiPadLayout: Bool {
        // Use iPad layout for:
        // 1. Actual iPad devices
        // 2. iPhone in landscape with regular width (iPhone Pro Max in landscape)
        // 3. Any device with both regular size classes
        return isIPad || 
               (horizontalSizeClass == .regular && verticalSizeClass == .regular) ||
               (horizontalSizeClass == .regular && verticalSizeClass == .compact)
    }
    
    var body: some View {
        Group {
            if shouldUseiPadLayout {
                // Use iPad-optimized version for larger screens
                if #available(iOS 17.0, *) {
                    ProfileSwitcherOverlay_iPad(isPresented: $isPresented)
                        .environmentObject(profileManager)
                        .environmentObject(themeManager)
                } else {
                    // Fallback to standard version for older iOS versions
                    ProfileSwitcherOverlay(isPresented: $isPresented)
                        .environmentObject(profileManager)
                        .environmentObject(themeManager)
                }
            } else {
                // Use standard iPhone-optimized version
                ProfileSwitcherOverlay(isPresented: $isPresented)
                    .environmentObject(profileManager)
                    .environmentObject(themeManager)
            }
        }
    }
}

// MARK: - Performance-Optimized Device Detection

/// Singleton for caching device characteristics to avoid repeated calculations
class DeviceCharacteristics: ObservableObject {
    static let shared = DeviceCharacteristics()
    
    let isIPad: Bool
    let screenSize: CGSize
    let deviceModel: String
    
    // Performance metrics for layout decisions
    let prefersiPadLayout: Bool
    let supportsAdvancedAnimations: Bool
    
    private init() {
        self.isIPad = UIDevice.current.userInterfaceIdiom == .pad
        self.screenSize = UIScreen.main.bounds.size
        self.deviceModel = UIDevice.current.model
        
        // Determine if device should prefer iPad layout based on screen real estate
        let screenArea = screenSize.width * screenSize.height
        self.prefersiPadLayout = isIPad || screenArea > 400000 // Threshold for large screens
        
        // Check if device supports advanced animations without performance impact
        self.supportsAdvancedAnimations = {
            if #available(iOS 17.0, *) {
                return true
            }
            return false
        }()
    }
}

// MARK: - Adaptive Extension

extension View {
    /// Adaptive profile switcher overlay that automatically selects the optimal implementation
    /// - Parameter isPresented: Binding to control the presentation state
    /// - Returns: A view that presents the appropriate profile switcher for the current device
    func adaptiveProfileSwitcherOverlay(isPresented: Binding<Bool>) -> some View {
        let deviceCharacteristics = DeviceCharacteristics.shared
        
        if deviceCharacteristics.isIPad {
            // For iPad, use overlay to show sidebar alongside main content
            return AnyView(
                self.overlay(
                    Group {
                        if isPresented.wrappedValue {
                            AdaptiveProfileSwitcherOverlay(isPresented: isPresented)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading),
                                    removal: .move(edge: .leading)
                                ))
                                .animation(.easeInOut(duration: 0.3), value: isPresented.wrappedValue)
                        }
                    },
                    alignment: .leading
                )
            )
        } else {
            // For iPhone, use fullScreenCover as before
            return AnyView(
                 self.fullScreenCover(isPresented: isPresented) {
                     AdaptiveProfileSwitcherOverlay(isPresented: isPresented)
                 }
             )
         }
     }
}

// MARK: - Migration Helper

/// Helper struct to gradually migrate from the original implementation
/// This allows for A/B testing and gradual rollout of the new iPad experience
struct ProfileSwitcherMigrationWrapper: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @Binding var isPresented: Bool
    
    // Feature flag for enabling iPad-optimized experience
    @AppStorage("enableiPadOptimizedProfileSwitcher") private var enableiPadOptimization = true
    
    var body: some View {
        Group {
            if enableiPadOptimization {
                AdaptiveProfileSwitcherOverlay(isPresented: $isPresented)
                    .environmentObject(profileManager)
                    .environmentObject(themeManager)
            } else {
                // Fallback to original implementation
                ProfileSwitcherOverlay(isPresented: $isPresented)
                    .environmentObject(profileManager)
                    .environmentObject(themeManager)
            }
        }
    }
}

// MARK: - Performance Monitoring

/// Performance monitor for profile switcher interactions
class ProfileSwitcherPerformanceMonitor {
    static let shared = ProfileSwitcherPerformanceMonitor()
    
    private var presentationStartTime: CFAbsoluteTime = 0
    private var switchStartTime: CFAbsoluteTime = 0
    
    private init() {}
    
    func trackPresentationStart() {
        presentationStartTime = CFAbsoluteTimeGetCurrent()
    }
    
    func trackPresentationEnd() {
        let duration = CFAbsoluteTimeGetCurrent() - presentationStartTime
        logPerformanceMetric("profile_switcher_presentation", duration: duration)
    }
    
    func trackSwitchStart() {
        switchStartTime = CFAbsoluteTimeGetCurrent()
    }
    
    func trackSwitchEnd() {
        let duration = CFAbsoluteTimeGetCurrent() - switchStartTime
        logPerformanceMetric("profile_switch_duration", duration: duration)
    }
    
    private func logPerformanceMetric(_ metric: String, duration: CFAbsoluteTime) {
        #if DEBUG
        print("[ProfileSwitcher Performance] \(metric): \(String(format: "%.3f", duration * 1000))ms")
        #endif
        
        // In production, you might want to send this to analytics
        // Analytics.track(metric, properties: ["duration_ms": duration * 1000])
    }
}

// MARK: - Accessibility Enhancements

extension AdaptiveProfileSwitcherOverlay {
    /// Enhanced accessibility support for profile switching
    private var accessibilityLabel: String {
        "Profile switcher. Current profile: \(profileManager.currentProfile.displayName). \(UserProfile.allCases.count) profiles available."
    }
    
    private var accessibilityHint: String {
        "Double tap to switch between personal and work profiles. Swipe up or down to hear profile options."
    }
}

// MARK: - Preview Provider

struct AdaptiveProfileSwitcherOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone Preview
            ZStack {
                Color.blue.ignoresSafeArea()
                AdaptiveProfileSwitcherOverlay(isPresented: .constant(true))
                    .environmentObject(ProfileManager())
                    .environmentObject(ThemeManager())
            }
            .previewDevice("iPhone 15 Pro")
            .previewDisplayName("iPhone (Standard Layout)")
            
            // iPad Preview
            ZStack {
                Color.green.ignoresSafeArea()
                AdaptiveProfileSwitcherOverlay(isPresented: .constant(true))
                    .environmentObject(ProfileManager())
                    .environmentObject(ThemeManager())
            }
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewDisplayName("iPad (Optimized Layout)")
            
            // iPhone Pro Max Landscape (Should use iPad layout)
            ZStack {
                Color.purple.ignoresSafeArea()
                AdaptiveProfileSwitcherOverlay(isPresented: .constant(true))
                    .environmentObject(ProfileManager())
                    .environmentObject(ThemeManager())
            }
            .previewDevice("iPhone 15 Pro Max")
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("iPhone Pro Max Landscape")
        }
    }
}
