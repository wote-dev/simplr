//
//  FloatingAddTaskButton.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

/// A reusable floating action button for adding tasks across all tab views
/// Optimized for performance with minimal state changes and efficient animations
struct FloatingAddTaskButton: View {
    @Environment(\.theme) var theme
    @Binding var showingAddTask: Bool
    
    // Performance optimization: Use @State for internal animation state
    @State private var isPressed = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button {
                        // Optimized animation with reduced bounce for better performance
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                            showingAddTask = true
                        }
                        HapticManager.shared.buttonTap()
                    } label: {
                        ZStack {
                            // Background with optimized shadow rendering
                            Circle()
                                .fill(theme.accentGradient)
                                .frame(width: 56, height: 56)
                                .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                            
                            // Plus icon with optimized rendering
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(theme.background)
                                .shadow(
                                    color: theme.background == .black ? Color.white.opacity(0.3) : Color.black.opacity(0.3),
                                    radius: 2,
                                    x: 0,
                                    y: 1
                                )
                        }
                        // Optimized scale animation - only animate when pressed
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                    }
                    .buttonStyle(OptimizedFloatingButtonStyle(isPressed: $isPressed))
                    .accessibilityLabel("Add new task")
                    .accessibilityHint("Double tap to create a new task")
                    .padding(.trailing, 24)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom + 70, 90)) // Dynamic positioning above tab bar
                }
            }
        }
        // Prevent unnecessary redraws by avoiding complex transitions
        .allowsHitTesting(true)
    }
}

/// Optimized button style for floating action button
/// Minimizes state changes and animation overhead
private struct OptimizedFloatingButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                // Only update state when actually needed
                if isPressed != pressed {
                    isPressed = pressed
                }
            }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        FloatingAddTaskButton(showingAddTask: .constant(false))
    }
    .environmentObject(ThemeManager())
}