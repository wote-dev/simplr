//
//  OnboardingView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @State private var currentStep = 0
    @Binding var showOnboarding: Bool
    
    private let steps = [
        OnboardingStep(
            icon: "checkmark.circle.fill",
            title: "Stay Organized",
            description: "Keep track of your tasks with a simple and beautiful interface"
        ),
        OnboardingStep(
            icon: "calendar",
            title: "Never Miss a Deadline",
            description: "Set due dates and get notifications to stay on top of everything"
        ),
        OnboardingStep(
            icon: "sparkles",
            title: "Boost Your Productivity",
            description: "Complete tasks, track progress, and achieve your goals effortlessly"
        )
    ]
    
    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 60) {
                Spacer()
                
                // App icon and title
                VStack(spacing: 24) {
                    Image(themeManager.currentTheme is DarkTheme ? "simplr-dark" : "simplr-light")
                        .resizable()
                        .frame(width: 80, height: 80)
                    
                    Text("Simplr")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.text)
                }
                
                // Step content with swipe gesture
                VStack(spacing: 40) {
                    let step = steps[currentStep]
                    
                    Image(systemName: step.icon)
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(theme.accent)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                    VStack(spacing: 12) {
                        Text(step.title)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(theme.text)
                            .multilineTextAlignment(.center)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .lineLimit(nil)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                .id(currentStep) // Force view recreation for smooth transitions
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width > threshold && currentStep > 0 {
                                // Swipe right - go to previous step
                                goToPreviousStep()
                            } else if value.translation.width < -threshold && currentStep < steps.count - 1 {
                                // Swipe left - go to next step
                                goToNextStep()
                            }
                        }
                )
                
                Spacer()
                
                // Bottom section
                VStack(spacing: 32) {
                    // Step indicator
                    HStack(spacing: 8) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(currentStep == index ? theme.accent : theme.textSecondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentStep == index ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: currentStep)
                        }
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        // Previous button (only show if not on first step)
                        if currentStep > 0 {
                            Button {
                                goToPreviousStep()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Previous")
                                        .font(.system(size: 17, weight: .medium))
                                }
                                .foregroundColor(theme.textSecondary)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(theme.textSecondary.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                        
                        // Next/Get Started button
                        Button {
                            if currentStep < steps.count - 1 {
                                goToNextStep()
                            } else {
                                completeOnboarding()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(currentStep < steps.count - 1 ? "Continue" : "Get Started")
                                    .font(.system(size: 17, weight: .medium))
                                if currentStep < steps.count - 1 {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                }
                            }
                            .foregroundColor(theme.background)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.accent)
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                    
                    // Skip option
                    if currentStep < steps.count - 1 {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func goToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
        HapticManager.shared.buttonTap()
    }
    
    private func goToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep -= 1
        }
        HapticManager.shared.buttonTap()
    }
    
    private func completeOnboarding() {
        HapticManager.shared.successFeedback()
        UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
        
        withAnimation(.easeInOut(duration: 0.5)) {
            showOnboarding = false
        }
    }
}

struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .themedEnvironment(ThemeManager())
}