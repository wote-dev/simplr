//
//  ButtonPersonalityDemo.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

extension View {
    func `let`<T>(_ transform: (Self) -> T) -> T {
        return transform(self)
    }
}

struct ButtonPersonalityDemo: View {
    @Environment(\.theme) var theme
    @State private var showingDemo = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Button Animation Personalities")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(theme.text)
                        
                        Text("Tap buttons to experience different animation styles")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Personality Buttons Section
                    personalityButtonsSection
                    
                    // Enhanced Effects Section
                    enhancedEffectsSection
                    
                    // Context-Aware Buttons Section
                    contextAwareButtonsSection
                    
                    // Special Effects Section
                    specialEffectsSection
                    
                    // Celebrations & Transitions Section
                    celebrationsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(theme.background)
            .navigationBarHidden(true)
        }
    }
    
    private var personalityButtonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Personality Types")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                personalityButton("Gentle", style: .gentle, color: .green)
                personalityButton("Playful", style: .playful, color: .orange)
                personalityButton("Dramatic", style: .dramatic, color: .red)
                personalityButton("Excited", style: .excited, color: .purple)
                personalityButton("Professional", style: .professional, color: .blue)
                personalityButton("Magical", style: .magical, color: .pink)
                personalityButton("Hyperactive", style: .hyperactive, color: .cyan)
                personalityButton("Zen", style: .zen, color: .mint)
                personalityButton("Bouncy", style: .bouncy, color: .indigo)
            }
        }
    }
    
    private var enhancedEffectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Enhanced Effects")
            
            VStack(spacing: 12) {
                enhancedEffectButton("Rotation Effect", enableRotation: true)
                enhancedEffectButton("Pulse Effect", enablePulse: true)
                enhancedEffectButton("Both Effects", enableRotation: true, enablePulse: true)
                interactiveEffectButton("Breathing Effect", enableBreathe: true)
                interactiveEffectButton("Glow Effect", enableGlow: true)
                interactiveEffectButton("All Interactive", enableBreathe: true, enableGlow: true, enableRotation: true)
            }
        }
    }
    
    private var contextAwareButtonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Context-Aware Styles")
            
            VStack(spacing: 12) {
                contextButton("Primary Action", style: "primary")
                contextButton("Secondary Action", style: "secondary")
                contextButton("Playful Action", style: "playful")
                contextButton("Magical Action", style: "magical")
                contextButton("Excited Action", style: "excited")
                contextButton("Hyperactive Action", style: "hyperactive")
                contextButton("Zen Action", style: "zen")
                contextButton("Bouncy Action", style: "bouncy")
                contextButton("Celebration", style: "celebration")
            }
        }
    }
    
    private var specialEffectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Special Effects")
            
            VStack(spacing: 12) {
                specialEffectButton("Magnetic Button")
                specialEffectButton("Ripple Effect")
                specialEffectButton("Shimmer Effect")
            }
        }
    }
    
    private var celebrationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Celebrations & Transitions")
            
            VStack(spacing: 12) {
                celebrationButton("Party Time!", transition: .explosiveEntry)
                celebrationButton("Magical Entrance", transition: .magicalAppear)
                celebrationButton("Dimensional Slide", transition: .dimensionalSlide)
                celebrationButton("Particle Celebration", transition: .bounceIn)
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(theme.text)
    }
    
    private func personalityButton(_ title: String, style: ButtonPersonality, color: Color) -> some View {
        Button(action: {
            // Button action
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: iconForPersonality(style))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .personalityButton(style: style)
        .hapticFeedback(.light)
    }
    
    private func enhancedEffectButton(_ title: String, enableRotation: Bool = false, enablePulse: Bool = false) -> some View {
        Button(action: {
            // Button action
        }) {
            HStack {
                Image(systemName: enableRotation && enablePulse ? "sparkles" : enableRotation ? "arrow.clockwise" : "heart.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.text)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .stroke(theme.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .enhancedButton(
            pressedScale: 0.95,
            animation: .elasticBounce,
            enableRotation: enableRotation,
            enablePulse: enablePulse
        )
        .hapticFeedback(.medium)
    }
    
    private func interactiveEffectButton(_ title: String, enableBreathe: Bool = false, enableGlow: Bool = false, enableRotation: Bool = false) -> some View {
        Button(action: {
            // Button action
        }) {
            HStack {
                Image(systemName: iconForInteractiveEffect(enableBreathe: enableBreathe, enableGlow: enableGlow, enableRotation: enableRotation))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.text)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .stroke(theme.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .interactiveButton(
            pressedScale: 0.95,
            animation: .elasticBounce,
            enableBreathe: enableBreathe,
            enableGlow: enableGlow,
            enableRotation: enableRotation
        )
        .hapticFeedback(.medium)
    }
    
    private func contextButton(_ title: String, style: String) -> some View {
        Button(action: {
            // Button action
        }) {
            HStack {
                Image(systemName: iconForContextStyle(style))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorForContextStyle(style))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(gradientForContextStyle(style))
            )
        }
        .let { view in
            applyContextStyle(view, style: style)
        }
        .hapticFeedback(.medium)
    }
    
    private func specialEffectButton(_ title: String) -> some View {
        Button(action: {
            // Button action
        }) {
            HStack {
                Image(systemName: iconForSpecialEffect(title))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.accent)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.text)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .stroke(theme.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .let { view in
            applySpecialEffect(view, title: title)
        }
        .hapticFeedback(.light)
    }
    
    private func celebrationButton(_ title: String, transition: AnyTransition) -> some View {
        Button(action: {
            // Trigger celebration effect
            showingDemo.toggle()
        }) {
            HStack {
                Image(systemName: "party.popper")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if showingDemo {
                    ParticleSystem(particleCount: 15, size: 4)
                        .frame(width: 30, height: 30)
                        .transition(transition)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [.purple, .pink, .orange], startPoint: .leading, endPoint: .trailing))
            )
        }
        .celebrationButton()
        .hapticFeedback(.heavy)
    }
    
    // Helper functions
    private func iconForPersonality(_ style: ButtonPersonality) -> String {
        switch style {
        case .gentle: return "heart"
        case .playful: return "gamecontroller"
        case .dramatic: return "flame"
        case .excited: return "bolt"
        case .professional: return "briefcase"
        case .magical: return "wand.and.stars"
        case .hyperactive: return "speedometer"
        case .zen: return "leaf"
        case .bouncy: return "basketball"
        }
    }
    
    private func iconForInteractiveEffect(enableBreathe: Bool, enableGlow: Bool, enableRotation: Bool) -> String {
        if enableBreathe && enableGlow && enableRotation {
            return "sparkles"
        } else if enableBreathe && enableGlow {
            return "moon.stars"
        } else if enableBreathe {
            return "lungs"
        } else if enableGlow {
            return "sun.max"
        } else if enableRotation {
            return "arrow.clockwise"
        } else {
            return "circle"
        }
    }
    
    private func iconForContextStyle(_ style: String) -> String {
        switch style {
        case "primary": return "star.fill"
        case "secondary": return "circle"
        case "playful": return "face.smiling"
        case "magical": return "sparkles"
        case "excited": return "exclamationmark"
        case "hyperactive": return "bolt.horizontal"
        case "zen": return "om"
        case "bouncy": return "arrow.up.and.down.circle"
        case "celebration": return "party.popper"
        default: return "circle"
        }
    }
    
    private func colorForContextStyle(_ style: String) -> Color {
        switch style {
        case "primary": return .white
        case "secondary": return .white
        case "playful": return .white
        case "magical": return .white
        case "excited": return .white
        default: return .white
        }
    }
    
    private func gradientForContextStyle(_ style: String) -> LinearGradient {
        switch style {
        case "primary": return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        case "secondary": return LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
        case "playful": return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        case "magical": return LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
        case "excited": return LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
        case "hyperactive": return LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
        case "zen": return LinearGradient(colors: [.mint, .green], startPoint: .leading, endPoint: .trailing)
        case "bouncy": return LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
        case "celebration": return LinearGradient(colors: [.pink, .yellow, .green], startPoint: .leading, endPoint: .trailing)
        default: return LinearGradient(colors: [.blue], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    @ViewBuilder
    private func applyContextStyle<V: View>(_ view: V, style: String) -> some View {
        switch style {
        case "primary": view.primaryActionButton()
        case "secondary": view.secondaryActionButton()
        case "playful": view.playfulActionButton()
        case "magical": view.magicalActionButton()
        case "excited": view.excitedActionButton()
        case "hyperactive": view.hyperActionButton()
        case "zen": view.zenActionButton()
        case "bouncy": view.bouncyActionButton()
        case "celebration": view.celebrationButton()
        default: view.secondaryActionButton()
        }
    }
    
    private func iconForSpecialEffect(_ title: String) -> String {
        switch title {
        case "Magnetic Button": return "magnet"
        case "Ripple Effect": return "water.waves"
        case "Shimmer Effect": return "sparkles"
        default: return "star"
        }
    }
    
    @ViewBuilder
    private func applySpecialEffect<V: View>(_ view: V, title: String) -> some View {
        switch title {
        case "Magnetic Button": view.magneticButton()
        case "Ripple Effect": view.rippleEffect()
        case "Shimmer Effect": view.shimmer()
        default: view.personalityButton()
        }
    }
}



#Preview {
    ButtonPersonalityDemo()
        .environmentObject(ThemeManager())
        .environment(\.theme, LightTheme())
} 