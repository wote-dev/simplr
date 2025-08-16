//
//  AnimationExtensions.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import AudioToolbox

// MARK: - Animation Timing Extensions
extension Animation {
    // MARK: - Ultra-Performance Animations (120fps Optimized)
    
    // iOS 17+ ultra-smooth animations with reduced CPU usage
    @available(iOS 17.0, *)
    static let smoothSpring = Animation.smooth(duration: 0.32, extraBounce: 0.08)
    
    @available(iOS 17.0, *)
    static let snappySpring = Animation.snappy(duration: 0.24)
    
    @available(iOS 17.0, *)
    static let bouncySpring = Animation.bouncy(duration: 0.42, extraBounce: 0.15)
    
    // Enhanced elastic bounce optimized for 120fps
    @available(iOS 17.0, *)
    static let elasticBounce = Animation.spring(duration: 0.52, bounce: 0.32, blendDuration: 0.02)
    
    // Hyper bounce with reduced duration for better responsiveness
    @available(iOS 17.0, *)
    static let hyperBounce = Animation.spring(duration: 0.58, bounce: 0.45, blendDuration: 0.01)
    
    // Responsive spring with minimal CPU impact
    @available(iOS 17.0, *)
    static let responsiveSpring = Animation.snappy(duration: 0.18)
    
    // Gentle bounce optimized for battery life
    @available(iOS 17.0, *)
    static let gentleBounce = Animation.smooth(duration: 0.42, extraBounce: 0.05)
    
    // Smooth tab transition with reduced motion blur
    @available(iOS 17.0, *)
    static let smoothTabTransition = Animation.smooth(duration: 0.28, extraBounce: 0.02)
    
    // MARK: - Legacy Optimized Animations (iOS 16+)
    static let smoothSpringLegacy = Animation.interpolatingSpring(stiffness: 420, damping: 32, initialVelocity: 0.8)
    static let bounceSpringLegacy = Animation.interpolatingSpring(stiffness: 520, damping: 28, initialVelocity: 1.2)
    static let gentleSpringLegacy = Animation.interpolatingSpring(stiffness: 320, damping: 38, initialVelocity: 0.6)
    static let quickSpringLegacy = Animation.interpolatingSpring(stiffness: 680, damping: 22, initialVelocity: 1.0)
    
    // Enhanced spring animations with performance tuning
    static let elasticBounceLegacy = Animation.interpolatingSpring(stiffness: 380, damping: 18, initialVelocity: 1.4)
    static let playfulBounceLegacy = Animation.interpolatingSpring(stiffness: 480, damping: 25, initialVelocity: 1.1)
    static let dramaticBounceLegacy = Animation.interpolatingSpring(stiffness: 720, damping: 16, initialVelocity: 1.3)
    static let gentleBounceLegacy = Animation.interpolatingSpring(stiffness: 280, damping: 42, initialVelocity: 0.7)
    
    // Extreme personality animations with reduced duration
    static let hyperBounceLegacy = Animation.interpolatingSpring(stiffness: 850, damping: 12, initialVelocity: 1.5)
    static let rubberBandLegacy = Animation.interpolatingSpring(stiffness: 220, damping: 15, initialVelocity: 0.9)
    static let snappyElasticLegacy = Animation.interpolatingSpring(stiffness: 580, damping: 20, initialVelocity: 1.2)
    
    // Optimized curves for gesture interactions
    static let responsiveSpringLegacy = Animation.interpolatingSpring(stiffness: 450, damping: 30, initialVelocity: 1.0)
    static let interactiveGestureLegacy = Animation.interactiveSpring(response: 0.18, dampingFraction: 0.92, blendDuration: 0.0)
    static let smoothSnapLegacy = Animation.interpolatingSpring(stiffness: 380, damping: 35, initialVelocity: 0.8)
    
    // Unified smooth tab animation optimized for performance
    static let smoothTabTransitionLegacy = Animation.interactiveSpring(response: 0.25, dampingFraction: 0.85, blendDuration: 0.05)
    
    // High-performance tab switching with reduced motion
    static let ultraSmoothTab = Animation.interpolatingSpring(stiffness: 420, damping: 32, initialVelocity: 0.9)
    static let responsiveTab = Animation.interpolatingSpring(stiffness: 520, damping: 34, initialVelocity: 1.1)
    static let silkyTab = Animation.interpolatingSpring(stiffness: 380, damping: 28, initialVelocity: 0.8)
    
    // MARK: - Performance-First Adaptive Animations
    
    /// Adaptive animation that automatically adjusts based on device capabilities
    static var adaptiveSmooth: Animation {
        if #available(iOS 17.0, *) {
            return .smooth(duration: 0.32, extraBounce: 0.08)
        } else {
            return smoothSpringLegacy
        }
    }
    
    /// Ultra-responsive animation for immediate feedback
    static var adaptiveSnappy: Animation {
        if #available(iOS 17.0, *) {
            return .snappy(duration: 0.18)
        } else {
            return Animation.interpolatingSpring(stiffness: 720, damping: 28, initialVelocity: 1.2)
        }
    }
    
    /// Balanced bounce with performance optimization
    static var adaptiveBouncy: Animation {
        if #available(iOS 17.0, *) {
            return .bouncy(duration: 0.42, extraBounce: 0.15)
        } else {
            return elasticBounceLegacy
        }
    }
    
    /// Elastic animation with reduced CPU usage
    static var adaptiveElastic: Animation {
        if #available(iOS 17.0, *) {
            return .spring(duration: 0.52, bounce: 0.32, blendDuration: 0.02)
        } else {
            return elasticBounceLegacy
        }
    }
    
    // MARK: - Battery-Optimized Legacy Animations
    
    static let bounceSpring = Animation.interpolatingSpring(stiffness: 520, damping: 28, initialVelocity: 1.0)
    static let gentleSpring = Animation.interpolatingSpring(stiffness: 320, damping: 38, initialVelocity: 0.7)
    static let quickSpring = Animation.interpolatingSpring(stiffness: 680, damping: 22, initialVelocity: 0.9)
    static let playfulBounce = Animation.interpolatingSpring(stiffness: 480, damping: 25, initialVelocity: 1.0)
    static let dramaticBounce = Animation.interpolatingSpring(stiffness: 720, damping: 16, initialVelocity: 1.2)
    static let rubberBand = Animation.interpolatingSpring(stiffness: 220, damping: 15, initialVelocity: 0.8)
    static let snappyElastic = Animation.interpolatingSpring(stiffness: 580, damping: 20, initialVelocity: 1.0)
    static let interactiveGesture = Animation.interactiveSpring(response: 0.18, dampingFraction: 0.92, blendDuration: 0.0)
    static let smoothSnap = Animation.interpolatingSpring(stiffness: 380, damping: 35, initialVelocity: 0.8)
    
    static let smoothEase = Animation.easeInOut(duration: 0.18)
    static let quickEase = Animation.easeInOut(duration: 0.12)
    static let gentleEase = Animation.easeInOut(duration: 0.15)
    
    // MARK: - Ultra-Smooth Timing Curves
    
    /// Optimized snappy curve for immediate response
    static let snappy = Animation.timingCurve(0.22, 0.08, 0.36, 1, duration: 0.32)
    
    /// Refined elastic curve with reduced overshoot
    static let elastic = Animation.timingCurve(0.68, -0.45, 0.265, 1.45, duration: 0.48)
    
    /// Smooth back-out curve for natural deceleration
    static let backOut = Animation.timingCurve(0.34, 1.45, 0.64, 1, duration: 0.42)
    
    // MARK: - Advanced Performance Curves
    
    /// Subtle anticipation curve for micro-interactions
    static let anticipation = Animation.timingCurve(0.12, 0, 0.28, 1, duration: 0.65)
    
    /// Controlled overshoot for delightful feedback
    static let overshoot = Animation.timingCurve(0.28, 0, 0.12, 1.4, duration: 0.48)
    
    /// Gentle bounce-back for soft interactions
    static let bounceBack = Animation.timingCurve(0.68, -0.5, 0.32, 1.5, duration: 0.58)
    
    // MARK: - Performance Monitoring Helpers
    
    /// Returns appropriate animation based on device performance
    static func performanceOptimized(duration: Double = 0.3) -> Animation {
        let reducedMotion = UIAccessibility.isReduceMotionEnabled
        let lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        if reducedMotion || lowPowerMode {
            return Animation.easeInOut(duration: max(duration * 0.5, 0.15))
        }
        
        return adaptiveSmooth
    }
    
    /// Ultra-smooth animation for critical interactions
    static func ultraSmooth(duration: Double = 0.28) -> Animation {
        if #available(iOS 17.0, *) {
            return .smooth(duration: duration, extraBounce: 0.05)
        } else {
            return Animation.interpolatingSpring(
                stiffness: 450,
                damping: 32,
                initialVelocity: 1.0
            )
        }
    }
    
    /// Instant response animation for gestures
    static func instantResponse(duration: Double = 0.16) -> Animation {
        Animation.interpolatingSpring(
            stiffness: 800,
            damping: 25,
            initialVelocity: 1.3
        )
    }
}

// MARK: - Sound Effects for Animations
enum AnimationSound {
    case pop
    case click
    case whoosh
    case sparkle
    case bounce
    case magical
    case dramatic
    case gentle
    case none
    
    var systemSoundID: SystemSoundID? {
        switch self {
        case .pop: return 1104 // Camera shutter sound
        case .click: return 1103 // Key click
        case .whoosh: return 1110 // Whoosh
        case .sparkle: return 1108 // Sparkle
        case .bounce: return 1105 // Short low sound
        case .magical: return 1109 // High pitch
        case .dramatic: return 1107 // Alert sound
        case .gentle: return 1106 // Gentle tap
        case .none: return nil
        }
    }
    
    func play() {
        guard let soundID = systemSoundID else { return }
        AudioServicesPlaySystemSound(soundID)
    }
}

// MARK: - Custom Transition Extensions
extension AnyTransition {
    static let slideInFromTrailing = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    static let slideInFromLeading = AnyTransition.asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
    )
    
    static let scaleAndSlide = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: 20)),
        removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: -20))
    )
    
    static let gentleScale = AnyTransition.scale(scale: 0.95).combined(with: .opacity)
    
    static let bounceIn = AnyTransition.scale(scale: 0.3).combined(with: .opacity)
    static let elasticScale = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
    
    // New dramatic transitions
    static let explosiveEntry = AnyTransition.scale(scale: 0.1).combined(with: .opacity).combined(with: .offset(y: -50))
    static let magicalAppear = AnyTransition.scale(scale: 0.5).combined(with: .opacity).combined(with: .offset(x: 20, y: 20))
    static let dimensionalSlide = AnyTransition.scale(scale: 0.8).combined(with: .offset(x: -100)).combined(with: .opacity)
}

// MARK: - Enhanced Button Animation Styles

/// Button style with enhanced personality and context awareness
struct PersonalityButtonStyle: ViewModifier {
    @State private var isPressed = false
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0
    @State private var jiggleOffset: CGFloat = 0
    @State private var shadowIntensity: CGFloat = 1.0
    @State private var colorShift: Double = 0
    @State private var sparkleScale: CGFloat = 0
    
    let style: ButtonPersonality
    let animation: Animation
    let enableSound: Bool
    
    init(style: ButtonPersonality = .playful, animation: Animation = .elasticBounce, enableSound: Bool = true) {
        self.style = style
        self.animation = animation
        self.enableSound = enableSound
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? style.pressedScale : 1.0)
            .offset(x: jiggleOffset)
            .shadow(
                color: .black.opacity(0.1),
                radius: shadowIntensity * 4,
                x: 0,
                y: shadowIntensity * 2
            )
            .hueRotation(.degrees(colorShift))
            .background(
                Group {
                    // Ripple effect overlay
                    Circle()
                        .fill(.white.opacity(0.3))
                        .scaleEffect(rippleScale)
                        .opacity(rippleOpacity)
                        .animation(.easeOut(duration: 0.6), value: rippleScale)
                        .allowsHitTesting(false)
                    
                    // Sparkle effect for magical style
                    if style == .magical {
                        ZStack {
                            ForEach(0..<6, id: \.self) { index in
                                Circle()
                                    .fill(Color.random.opacity(0.8))
                                    .frame(width: 4, height: 4)
                                    .offset(
                                        x: cos(Double(index) * .pi / 3) * 25 * sparkleScale,
                                        y: sin(Double(index) * .pi / 3) * 25 * sparkleScale
                                    )
                                    .scaleEffect(sparkleScale)
                                    .opacity(sparkleScale)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                }
            )
            .animation(animation, value: isPressed)
            .animation(Animation.adaptiveSmooth, value: shadowIntensity)
            .animation(Animation.adaptiveSmooth, value: sparkleScale)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
                // Empty action
            } onPressingChanged: { pressing in
                handlePress(pressing)
            }
    }
    
    private func handlePress(_ pressing: Bool) {
        if enableSound && pressing {
            style.sound.play()
        }
        
        withAnimation(animation) {
            isPressed = pressing
            shadowIntensity = pressing ? 0.5 : 1.0
        }
        
        if pressing {
            // Color shift for dramatic style
            if style == .dramatic {
                withAnimation(Animation.adaptiveSnappy) {
                    colorShift = 30
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(Animation.adaptiveSmooth) {
                        colorShift = 0
                    }
                }
            }
            
            // Sparkle effect for magical style
            if style == .magical {
                withAnimation(Animation.adaptiveElastic) {
                    sparkleScale = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    sparkleScale = 0
                }
            }
            
            // Trigger ripple effect
            withAnimation(Animation.adaptiveSmooth) {
                rippleScale = 3.0
                rippleOpacity = 0.0
            }
            
            // Reset ripple
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                rippleScale = 0
                rippleOpacity = 1.0
            }
            
            // Add jiggle for playful style
            if style == .playful || style == .excited {
                withAnimation(Animation.adaptiveSnappy.repeatCount(3, autoreverses: true)) {
                    jiggleOffset = style == .excited ? 3 : 1.5
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    jiggleOffset = 0
                }
            }
        }
    }
}

// MARK: - Color Extensions for Enhanced Effects
extension Color {
    static var random: Color {
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}

// MARK: - Advanced Interactive Button Style
struct InteractiveButtonStyle: ViewModifier {
    @State private var isPressed = false
    @State private var isHovered = false
    @State private var breatheScale: CGFloat = 1.0
    @State private var glowIntensity: Double = 0
    @State private var rotationEffect: Double = 0
    
    let pressedScale: CGFloat
    let animation: Animation
    let enableBreathe: Bool
    let enableGlow: Bool
    let enableRotation: Bool
    
    init(
        pressedScale: CGFloat = 0.95,
        animation: Animation = .adaptiveElastic,
        enableBreathe: Bool = false,
        enableGlow: Bool = false,
        enableRotation: Bool = false
    ) {
        self.pressedScale = pressedScale
        self.animation = animation
        self.enableBreathe = enableBreathe
        self.enableGlow = enableGlow
        self.enableRotation = enableRotation
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect((isPressed ? pressedScale : 1.0) * breatheScale)
            .rotationEffect(.degrees(rotationEffect))
            .shadow(
                color: enableGlow ? .blue.opacity(glowIntensity * 0.5) : .clear,
                radius: glowIntensity * 10,
                x: 0,
                y: 0
            )
            .animation(animation, value: isPressed)
            .animation(Animation.adaptiveSmooth.repeatForever(autoreverses: true), value: breatheScale)
            .animation(Animation.adaptiveSmooth, value: glowIntensity)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
                // Empty action
            } onPressingChanged: { pressing in
                withAnimation(animation) {
                    isPressed = pressing
                }
                
                if enableGlow {
                    withAnimation(Animation.adaptiveSmooth) {
                        glowIntensity = pressing ? 1.0 : 0.0
                    }
                }
                
                if enableRotation && pressing {
                    withAnimation(Animation.adaptiveElastic) {
                        rotationEffect = Double.random(in: -15...15)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(Animation.adaptiveElastic) {
                            rotationEffect = 0
                        }
                    }
                }
            }
            .onAppear {
                if enableBreathe {
                    breatheScale = 1.05
                }
            }
    }
}

/// Simple animated button style with tap gesture (no long press)
struct SimpleAnimatedButtonStyle: ViewModifier {
    @State private var isPressed = false
    
    let pressedScale: CGFloat
    let animation: Animation
    
    init(pressedScale: CGFloat = 0.95, animation: Animation = .adaptiveSnappy) {
        self.pressedScale = pressedScale
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? pressedScale : 1.0)
            .animation(animation, value: isPressed)
            .onTapGesture {
                // Provide immediate visual feedback
                withAnimation(animation) {
                    isPressed = true
                }
                
                // Reset after short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(animation) {
                        isPressed = false
                    }
                }
            }
    }
}

/// Enhanced animated button style with multiple effects
struct AnimatedButtonStyle: ViewModifier {
    @State private var isPressed = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    let pressedScale: CGFloat
    let animation: Animation
    let enableRotation: Bool
    let enablePulse: Bool
    
    init(
        pressedScale: CGFloat = 0.95,
        animation: Animation = .adaptiveSnappy,
        enableRotation: Bool = false,
        enablePulse: Bool = false
    ) {
        self.pressedScale = pressedScale
        self.animation = animation
        self.enableRotation = enableRotation
        self.enablePulse = enablePulse
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect((isPressed ? pressedScale : 1.0) * pulseScale)
            .rotationEffect(.degrees(rotationAngle))
            .animation(animation, value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
                // Empty action
            } onPressingChanged: { pressing in
                withAnimation(animation) {
                    isPressed = pressing
                }
                
                if pressing && enableRotation {
                    withAnimation(Animation.adaptiveSmooth) {
                        rotationAngle = Double.random(in: -5...5)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(Animation.adaptiveSmooth) {
                            rotationAngle = 0
                        }
                    }
                }
            }
            .onAppear {
                if enablePulse {
                    withAnimation(Animation.adaptiveSmooth.repeatForever(autoreverses: true)) {
                        pulseScale = 1.05
                    }
                }
            }
    }
}

/// Magnetic button effect that "attracts" nearby elements
struct MagneticButtonStyle: ViewModifier {
    @State private var isPressed = false
    @State private var magneticField: CGFloat = 0
    @State private var glowIntensity: Double = 0
    
    let pressedScale: CGFloat
    let animation: Animation
    
    init(pressedScale: CGFloat = 0.92, animation: Animation = .adaptiveElastic) {
        self.pressedScale = pressedScale
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? pressedScale : 1.0)
            .background(
                Circle()
                    .fill(.blue.opacity(glowIntensity * 0.3))
                    .scaleEffect(1.0 + magneticField)
                    .blur(radius: magneticField * 10)
                    .allowsHitTesting(false)
            )
            .animation(animation, value: isPressed)
            .animation(Animation.adaptiveSmooth, value: magneticField)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
                // Empty action
            } onPressingChanged: { pressing in
                withAnimation(animation) {
                    isPressed = pressing
                }
                
                withAnimation(Animation.adaptiveSmooth) {
                    magneticField = pressing ? 0.3 : 0
                    glowIntensity = pressing ? 1.0 : 0
                }
            }
    }
}

// MARK: - Button Personality Types
enum ButtonPersonality {
    case gentle
    case playful
    case dramatic
    case excited
    case professional
    case magical
    case hyperactive
    case zen
    case bouncy
    
    var pressedScale: CGFloat {
        switch self {
        case .gentle: return 0.98
        case .playful: return 0.92
        case .dramatic: return 0.88
        case .excited: return 0.85
        case .professional: return 0.96
        case .magical: return 0.90
        case .hyperactive: return 0.80
        case .zen: return 0.99
        case .bouncy: return 0.75
        }
    }
    
    var animation: Animation {
        switch self {
        case .gentle: return .gentleBounce
        case .playful: return .playfulBounce
        case .dramatic: return .dramaticBounce
        case .excited: return .elasticBounce
        case .professional: return .smoothSpring
        case .magical: return .elastic
        case .hyperactive: return .hyperBounce
        case .zen: return .gentleEase
        case .bouncy: return .rubberBand
        }
    }
    
    var adaptiveAnimation: Animation {
        switch self {
        case .gentle: return .adaptiveSmooth
        case .playful: return .adaptiveBouncy
        case .dramatic: return .adaptiveElastic
        case .excited: return .adaptiveBouncy
        case .professional: return .adaptiveSmooth
        case .magical: return .adaptiveElastic
        case .hyperactive: return .adaptiveSnappy
        case .zen: return .adaptiveSmooth
        case .bouncy: return .adaptiveBouncy
        }
    }
    
    var sound: AnimationSound {
        switch self {
        case .gentle: return .gentle
        case .playful: return .pop
        case .dramatic: return .dramatic
        case .excited: return .bounce
        case .professional: return .click
        case .magical: return .magical
        case .hyperactive: return .sparkle
        case .zen: return .none
        case .bouncy: return .whoosh
            }
    }
}

// MARK: - Shimmer Effect for Loading States
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let opacity: Double
    
    init(duration: Double = 1.5, opacity: Double = 0.6) {
        self.duration = duration
        self.opacity = opacity
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(opacity),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .clipped()
            )
            .onAppear {
                // Use smooth linear animation for shimmer effect
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

// MARK: - Enhanced Ripple Effect
struct RippleEffect: ViewModifier {
    @State private var ripples: [RippleData] = []
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    ForEach(ripples, id: \.id) { ripple in
                        Circle()
                            .stroke(.white.opacity(0.5), lineWidth: 2)
                            .scaleEffect(ripple.scale)
                            .opacity(ripple.opacity)
                            .animation(Animation.adaptiveSmooth, value: ripple.scale)
                    }
                }
                .allowsHitTesting(false)
            )
            .onTapGesture {
                addRipple()
            }
    }
    
    private func addRipple() {
        let newRipple = RippleData()
        ripples.append(newRipple)
        
        withAnimation(Animation.adaptiveSmooth) {
            if let index = ripples.firstIndex(where: { $0.id == newRipple.id }) {
                ripples[index].scale = 3.0
                ripples[index].opacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            ripples.removeAll { $0.id == newRipple.id }
        }
    }
}

private struct RippleData {
    let id = UUID()
    var scale: CGFloat = 0
    var opacity: Double = 1.0
}

// MARK: - Bouncing Dot Animation
struct BouncingDots: View {
    @State private var animating = false
    let dotCount: Int
    let dotSize: CGFloat
    let spacing: CGFloat
    let color: Color
    
    init(dotCount: Int = 3, dotSize: CGFloat = 8, spacing: CGFloat = 4, color: Color = .blue) {
        self.dotCount = dotCount
        self.dotSize = dotSize
        self.spacing = spacing
        self.color = color
    }
    
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(animating ? 1.2 : 0.8)
                    .animation(
                        Animation.adaptiveSmooth
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Floating Animation
struct FloatingAnimation: ViewModifier {
    @State private var isFloating = false
    let intensity: CGFloat
    let duration: Double
    
    init(intensity: CGFloat = 5, duration: Double = 2.0) {
        self.intensity = intensity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -intensity : intensity)
            .animation(
                Animation.performanceOptimized(duration: duration)
                    .repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                // Prevent animation on reduced motion
                if !UIAccessibility.isReduceMotionEnabled {
                    isFloating = true
                }
            }
    }
}

// MARK: - Pulse Animation
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double
    
    init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .animation(
                Animation.adaptiveSmooth
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Wiggle Animation for Error States
struct WiggleAnimation: ViewModifier {
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
    }
    
    func triggerWiggle() {
        withAnimation(Animation.adaptiveSnappy.repeatCount(6, autoreverses: true)) {
            offset = 5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            offset = 0
        }
    }
}

// MARK: - Enhanced View Extensions
extension View {
    // Original simple animated button
    func animatedButton(pressedScale: CGFloat = 0.95, animation: Animation = .quickSpring) -> some View {
        modifier(SimpleAnimatedButtonStyle(pressedScale: pressedScale, animation: animation))
    }
    
    // Enhanced animated button with multiple effects
    func enhancedButton(
        pressedScale: CGFloat = 0.95,
        animation: Animation = .elasticBounce,
        enableRotation: Bool = false,
        enablePulse: Bool = false
    ) -> some View {
        modifier(AnimatedButtonStyle(
            pressedScale: pressedScale,
            animation: animation,
            enableRotation: enableRotation,
            enablePulse: enablePulse
        ))
    }
    
    // Advanced interactive button with breathing and glow effects
    func interactiveButton(
        pressedScale: CGFloat = 0.95,
        animation: Animation = .elasticBounce,
        enableBreathe: Bool = false,
        enableGlow: Bool = false,
        enableRotation: Bool = false
    ) -> some View {
        modifier(InteractiveButtonStyle(
            pressedScale: pressedScale,
            animation: animation,
            enableBreathe: enableBreathe,
            enableGlow: enableGlow,
            enableRotation: enableRotation
        ))
    }
    
    // Personality-driven button animations
    func personalityButton(style: ButtonPersonality = .playful, enableSound: Bool = true) -> some View {
        modifier(PersonalityButtonStyle(style: style, animation: style.animation, enableSound: enableSound))
    }
    
    // Magnetic attraction effect
    func magneticButton(pressedScale: CGFloat = 0.92, animation: Animation = .elasticBounce) -> some View {
        modifier(MagneticButtonStyle(pressedScale: pressedScale, animation: animation))
    }
    
    // Ripple effect on tap
    func rippleEffect() -> some View {
        modifier(RippleEffect())
    }
    
    func shimmer(duration: Double = 1.5, opacity: Double = 0.6) -> some View {
        modifier(ShimmerEffect(duration: duration, opacity: opacity))
    }
    
    func floating(intensity: CGFloat = 5, duration: Double = 2.0) -> some View {
        modifier(FloatingAnimation(intensity: intensity, duration: duration))
    }
    
    func pulsing(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        modifier(PulseAnimation(minScale: minScale, maxScale: maxScale, duration: duration))
    }
    
    func wiggle() -> some View {
        modifier(WiggleAnimation())
    }
    
    /// Applies a smooth transition when the view appears/disappears
    func smoothTransition(_ transition: AnyTransition = .scaleAndSlide) -> some View {
        self.transition(transition)
    }
    
    func smoothTransition<T: Equatable>(_ value: T, animation: Animation = .adaptiveSmooth) -> some View {
        self.animation(animation, value: value)
    }
    
    func snappyTransition<T: Equatable>(_ value: T) -> some View {
        self.animation(.adaptiveSnappy, value: value)
    }
    
    func bouncyTransition<T: Equatable>(_ value: T) -> some View {
        self.animation(.adaptiveBouncy, value: value)
    }
    
    /// Adds a subtle haptic feedback on tap
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        onTapGesture {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
    
    // Context-aware button styles for different use cases
    func primaryActionButton() -> some View {
        self.personalityButton(style: .dramatic)
            .rippleEffect()
            .snappyTransition(true)
    }
    
    func secondaryActionButton() -> some View {
        self.personalityButton(style: .gentle)
            .smoothTransition(true)
    }
    
    func playfulActionButton() -> some View {
        self.personalityButton(style: .playful)
            .enhancedButton(enableRotation: true)
            .bouncyTransition(true)
    }
    
    func magicalActionButton() -> some View {
        self.personalityButton(style: .magical)
            .magneticButton()
            .smoothTransition(true)
    }
    
    func excitedActionButton() -> some View {
        self.personalityButton(style: .excited)
            .rippleEffect()
            .bouncyTransition(true)
    }
    
    // New advanced context-aware styles
    func hyperActionButton() -> some View {
        self.personalityButton(style: .hyperactive)
            .interactiveButton(enableGlow: true, enableRotation: true)
            .snappyTransition(true)
    }
    
    func zenActionButton() -> some View {
        self.personalityButton(style: .zen, enableSound: false)
            .interactiveButton(enableBreathe: true)
            .smoothTransition(true)
    }
    
    func bouncyActionButton() -> some View {
        self.personalityButton(style: .bouncy)
            .enhancedButton(enableRotation: true)
            .bouncyTransition(true)
    }
    
    func celebrationButton() -> some View {
        self.personalityButton(style: .magical)
            .interactiveButton(enableGlow: true)
            .rippleEffect()
            .smoothTransition(true)
    }
}

// MARK: - Particle System for Celebrations
struct ParticleSystem: View {
    let particleCount: Int
    let colors: [Color]
    let size: CGFloat
    let animationDuration: Double
    @State private var animate = false
    
    init(
        particleCount: Int = 20,
        colors: [Color] = [.blue, .green, .yellow, .red, .purple],
        size: CGFloat = 6,
        animationDuration: Double = 1.0
    ) {
        self.particleCount = particleCount
        self.colors = colors
        self.size = size
        self.animationDuration = animationDuration
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                Circle()
                    .fill(colors.randomElement() ?? .blue)
                    .frame(width: size, height: size)
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : 0,
                        y: animate ? CGFloat.random(in: -200...200) : 0
                    )
                    .scaleEffect(animate ? 0 : 1)
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: animationDuration)
                        .delay(Double(index) * 0.02),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}