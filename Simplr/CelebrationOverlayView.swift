//
//  CelebrationOverlayView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct CelebrationOverlayView: View {
    @ObservedObject var celebrationManager: CelebrationManager
    @Environment(\.theme) var theme
    
    var body: some View {
        ZStack {
            if celebrationManager.showCelebrationOverlay,
               let celebration = celebrationManager.activeCelebration {
                
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        celebrationManager.showCelebrationOverlay = false
                    }
                
                // Celebration content
                VStack(spacing: 20) {
                    celebrationIcon(for: celebration)
                    celebrationText(for: celebration)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(theme.surface)
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                )
                .scaleEffect(celebrationManager.showCelebrationOverlay ? 1.0 : 0.3)
                .opacity(celebrationManager.showCelebrationOverlay ? 1.0 : 0.0)
                .animation(.elasticBounce, value: celebrationManager.showCelebrationOverlay)
                
                // Particle effects
                ParticleSystemView(
                    particles: celebrationManager.celebrationParticles,
                    isActive: celebrationManager.showCelebrationOverlay
                )
            }
        }
        .allowsHitTesting(celebrationManager.showCelebrationOverlay)
    }
    
    @ViewBuilder
    private func celebrationIcon(for celebration: CelebrationManager.CelebrationType) -> some View {
        ZStack {
            // Animated background circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: celebration.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(celebrationManager.showCelebrationOverlay ? 1.0 : 0.5)
                .animation(.elasticBounce.delay(0.1), value: celebrationManager.showCelebrationOverlay)
            
            // Icon
            Image(systemName: celebration.icon)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(celebrationManager.showCelebrationOverlay ? 1.0 : 0.3)
                .animation(.elasticBounce.delay(0.2), value: celebrationManager.showCelebrationOverlay)
        }
    }
    
    @ViewBuilder
    private func celebrationText(for celebration: CelebrationManager.CelebrationType) -> some View {
        VStack(spacing: 8) {
            Text(celebration.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .scaleEffect(celebrationManager.showCelebrationOverlay ? 1.0 : 0.5)
                .animation(.elasticBounce.delay(0.3), value: celebrationManager.showCelebrationOverlay)
            
            Text(celebration.message)
                .font(.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .scaleEffect(celebrationManager.showCelebrationOverlay ? 1.0 : 0.5)
                .animation(.elasticBounce.delay(0.4), value: celebrationManager.showCelebrationOverlay)
        }
    }
}

struct ParticleSystemView: View {
    let particles: [CelebrationParticle]
    let isActive: Bool
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(
                        x: isActive ? particle.endPosition.x + UIScreen.main.bounds.width / 2 : particle.startPosition.x + UIScreen.main.bounds.width / 2,
                        y: isActive ? particle.endPosition.y + UIScreen.main.bounds.height / 2 : particle.startPosition.y + UIScreen.main.bounds.height / 2
                    )
                    .scaleEffect(isActive ? 0.0 : 1.0)
                    .opacity(isActive ? 0.0 : 1.0)
                    .animation(
                        .easeOut(duration: 2.0)
                        .delay(particle.delay),
                        value: isActive
                    )
            }
        }
        .allowsHitTesting(false)
    }
}



#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        CelebrationOverlayView(celebrationManager: CelebrationManager.shared)
            .onAppear {
                CelebrationManager.shared.triggerCelebration(.tenTasksCompleted)
            }
    }
} 