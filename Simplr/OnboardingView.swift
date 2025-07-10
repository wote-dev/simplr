//
//  OnboardingView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @State private var currentStep = 0
    @Binding var showOnboarding: Bool
    
    private let steps = [
        OnboardingStep(
            icon: "checkmark.circle.fill",
            title: "Welcome to Simplr",
            description: "Your beautiful, powerful task manager designed for iOS. Stay organized with an interface that feels right at home."
        ),
        OnboardingStep(
            icon: "bell.fill",
            title: "Smart Reminders",
            description: "Set custom reminders for any time - 15 minutes before, 1 hour before, or pick your perfect moment with our beautiful scheduler."
        ),
        OnboardingStep(
            icon: "rectangle.3.group.fill",
            title: "Home Screen Widgets",
            description: "Add Simplr widgets to your home screen and lock screen. Complete tasks, see your progress, and stay on top of deadlines without opening the app."
        ),
        OnboardingStep(
            icon: "magnifyingglass",
            title: "Spotlight Integration",
            description: "Search for your tasks directly from iOS Spotlight. Your tasks are indexed and searchable system-wide for instant access."
        ),
        OnboardingStep(
            icon: "folder.fill",
            title: "Categories & Themes",
            description: "Organize tasks with colorful categories and choose from beautiful themes. Customize Simplr to match your style and workflow."
        ),
        OnboardingStep(
            icon: "hand.tap.fill",
            title: "Quick Actions",
            description: "Access quick actions from your home screen. Add tasks instantly or jump to today's view with convenient shortcuts."
        )
    ]
    
    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer(minLength: 20)
                
                // App icon and title
                VStack(spacing: 20) {
                    Image(themedIcon: "simplr", themeManager: themeManager)
                        .resizable()
                        .frame(width: 70, height: 70)
                    
                    Text("Simplr")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.text)
                }
                
                // Step content with swipe gesture
                VStack(spacing: 30) {
                    let step = steps[currentStep]
                    
                    Image(systemName: step.icon)
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(theme.accent)
                        .scaleEffect(1.0)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                            removal: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 1.2))
                        ))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                    
                    VStack(spacing: 16) {
                        Text(step.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.text)
                            .multilineTextAlignment(.center)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        ScrollView {
                            Text(step.description)
                                .font(.callout)
                                .foregroundColor(theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .lineLimit(nil)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxHeight: 120)
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
                
                Spacer(minLength: 20)
                
                // Bottom section
                VStack(spacing: 24) {
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
                                Text(currentStep < steps.count - 1 ? "Continue" : "Start Organizing")
                                    .font(.system(size: 17, weight: .medium))
                                if currentStep < steps.count - 1 {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                } else {
                                    Image(systemName: "arrow.right")
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
        
        // Request notification permissions for reminders
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                }
                // Complete onboarding regardless of permission result
                UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
                
                withAnimation(.easeInOut(duration: 0.5)) {
                    showOnboarding = false
                }
            }
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