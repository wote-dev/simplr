//
//  CelebrationManager.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI
import AudioToolbox

/// Manager for handling milestone celebrations and achievements
class CelebrationManager: ObservableObject {
    static let shared = CelebrationManager()
    
    @Published var activeCelebration: CelebrationType?
    @Published var celebrationParticles: [CelebrationParticle] = []
    @Published var showCelebrationOverlay = false
    
    private init() {}
    
    // MARK: - Celebration Types
    
    enum CelebrationType: Equatable {
        case firstTaskCompleted
        case fiveTasksCompleted
        case tenTasksCompleted
        case twentyFiveTasksCompleted
        case fiftyTasksCompleted
        case oneHundredTasksCompleted
        case allCompletedCleared
        case perfectDay // All today's tasks completed
        case streak(days: Int) // Consecutive days of completing tasks
        case speedRunner // Completed 10 tasks in under an hour
        case nightOwl // Completed task after 10 PM
        case earlyBird // Completed task before 6 AM
        case taskMaster // Completed 100+ tasks total
        
        var title: String {
            switch self {
            case .firstTaskCompleted:
                return "First Steps!"
            case .fiveTasksCompleted:
                return "Getting Things Done!"
            case .tenTasksCompleted:
                return "Productivity Pro!"
            case .twentyFiveTasksCompleted:
                return "Quarter Century!"
            case .fiftyTasksCompleted:
                return "Half Century Hero!"
            case .oneHundredTasksCompleted:
                return "Century Champion!"
            case .allCompletedCleared:
                return "Clean Slate!"
            case .perfectDay:
                return "Perfect Day!"
            case .streak(let days):
                return "\(days) Day Streak!"
            case .speedRunner:
                return "Speed Runner!"
            case .nightOwl:
                return "Night Owl!"
            case .earlyBird:
                return "Early Bird!"
            case .taskMaster:
                return "Task Master!"
            }
        }
        
        var message: String {
            switch self {
            case .firstTaskCompleted:
                return "You completed your first task!"
            case .fiveTasksCompleted:
                return "5 tasks down, keep it up!"
            case .tenTasksCompleted:
                return "10 tasks completed like a pro!"
            case .twentyFiveTasksCompleted:
                return "25 tasks conquered!"
            case .fiftyTasksCompleted:
                return "50 tasks mastered!"
            case .oneHundredTasksCompleted:
                return "100 tasks! You're unstoppable!"
            case .allCompletedCleared:
                return "All completed tasks cleared!"
            case .perfectDay:
                return "All today's tasks completed!"
            case .streak(let days):
                return "You've been productive for \(days) days straight!"
            case .speedRunner:
                return "10 tasks in record time!"
            case .nightOwl:
                return "Getting things done after hours!"
            case .earlyBird:
                return "Starting the day productively!"
            case .taskMaster:
                return "You've mastered task management!"
            }
        }
        
        var icon: String {
            switch self {
            case .firstTaskCompleted:
                return "star.fill"
            case .fiveTasksCompleted:
                return "hand.thumbsup.fill"
            case .tenTasksCompleted:
                return "crown.fill"
            case .twentyFiveTasksCompleted:
                return "medal.fill"
            case .fiftyTasksCompleted:
                return "trophy.fill"
            case .oneHundredTasksCompleted:
                return "star.circle.fill"
            case .allCompletedCleared:
                return "sparkles"
            case .perfectDay:
                return "sun.max.fill"
            case .streak:
                return "flame.fill"
            case .speedRunner:
                return "bolt.fill"
            case .nightOwl:
                return "moon.stars.fill"
            case .earlyBird:
                return "sunrise.fill"
            case .taskMaster:
                return "diamond.fill"
            }
        }
        
        var colors: [Color] {
            switch self {
            case .firstTaskCompleted:
                return [.yellow, .orange]
            case .fiveTasksCompleted:
                return [.green, .mint]
            case .tenTasksCompleted:
                return [.purple, .pink]
            case .twentyFiveTasksCompleted:
                return [.blue, .cyan]
            case .fiftyTasksCompleted:
                return [.orange, .red]
            case .oneHundredTasksCompleted:
                return [.purple, .indigo, .blue]
            case .allCompletedCleared:
                return [.mint, .green, .cyan]
            case .perfectDay:
                return [.yellow, .orange, .red]
            case .streak:
                return [.red, .orange, .yellow]
            case .speedRunner:
                return [.cyan, .blue]
            case .nightOwl:
                return [.indigo, .purple]
            case .earlyBird:
                return [.orange, .yellow]
            case .taskMaster:
                return [.purple, .pink, .red]
            }
        }
        
        var animationStyle: AnimationStyle {
            switch self {
            case .firstTaskCompleted, .fiveTasksCompleted:
                return .gentle
            case .tenTasksCompleted, .twentyFiveTasksCompleted:
                return .playful
            case .fiftyTasksCompleted, .oneHundredTasksCompleted:
                return .dramatic
            case .allCompletedCleared:
                return .satisfying
            case .perfectDay:
                return .radiant
            case .streak:
                return .fiery
            case .speedRunner:
                return .electric
            case .nightOwl:
                return .mysterious
            case .earlyBird:
                return .bright
            case .taskMaster:
                return .majestic
            }
        }
    }
    
    enum AnimationStyle {
        case gentle, playful, dramatic, satisfying, radiant, fiery, electric, mysterious, bright, majestic
        
        var hapticPattern: HapticManager.HapticPattern {
            switch self {
            case .gentle: return .gentle
            case .playful: return .playful
            case .dramatic: return .dramatic
            case .satisfying: return .satisfying
            case .radiant: return .radiant
            case .fiery: return .intense
            case .electric: return .sharp
            case .mysterious: return .mysterious
            case .bright: return .bright
            case .majestic: return .triumphant
            }
        }
        
        var particleCount: Int {
            switch self {
            case .gentle: return 15
            case .playful: return 25
            case .dramatic: return 40
            case .satisfying: return 30
            case .radiant: return 50
            case .fiery: return 35
            case .electric: return 30
            case .mysterious: return 20
            case .bright: return 45
            case .majestic: return 60
            }
        }
        
        var animationDuration: Double {
            switch self {
            case .gentle: return 1.5
            case .playful: return 2.0
            case .dramatic: return 2.5
            case .satisfying: return 1.8
            case .radiant: return 3.0
            case .fiery: return 2.2
            case .electric: return 1.0
            case .mysterious: return 2.5
            case .bright: return 2.0
            case .majestic: return 3.5
            }
        }
    }
    
    // MARK: - Milestone Checking
    
    func checkMilestones(taskManager: TaskManager) {
        let completedTasksCount = getCompletedTasksCount(taskManager: taskManager)
        
        // Check various milestones
        checkCompletionMilestones(completedTasksCount: completedTasksCount)
        checkPerfectDay(taskManager: taskManager)
        checkTimeBasedMilestones()
        checkSpeedRunner(taskManager: taskManager)
    }
    
    private func checkCompletionMilestones(completedTasksCount: Int) {
        let milestone: CelebrationType? = {
            switch completedTasksCount {
            case 1: return .firstTaskCompleted
            case 5: return .fiveTasksCompleted
            case 10: return .tenTasksCompleted
            case 25: return .twentyFiveTasksCompleted
            case 50: return .fiftyTasksCompleted
            case 100: return .oneHundredTasksCompleted
            default: return nil
            }
        }()
        
        if let milestone = milestone {
            triggerCelebration(milestone)
        }
    }
    
    private func checkPerfectDay(taskManager: TaskManager) {
        let calendar = Calendar.current
        let today = Date()
        
        let todayTasks = taskManager.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: today)
        }
        
        if !todayTasks.isEmpty && todayTasks.allSatisfy({ $0.isCompleted }) {
            triggerCelebration(.perfectDay)
        }
    }
    
    private func checkTimeBasedMilestones() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= 22 || hour <= 2 {
            // Night owl (10 PM - 2 AM)
            triggerCelebration(.nightOwl)
        } else if hour >= 5 && hour <= 7 {
            // Early bird (5 AM - 7 AM)
            triggerCelebration(.earlyBird)
        }
    }
    
    private func checkSpeedRunner(taskManager: TaskManager) {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let recentCompletions = taskManager.tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt > oneHourAgo
        }
        
        if recentCompletions.count >= 10 {
            triggerCelebration(.speedRunner)
        }
    }
    
    func checkClearAllMilestone(clearedCount: Int) {
        if clearedCount > 0 {
            triggerCelebration(.allCompletedCleared)
        }
    }
    
    private func getCompletedTasksCount(taskManager: TaskManager) -> Int {
        return taskManager.tasks.filter { $0.isCompleted }.count
    }
    
    private func getTodayCompletedCount(taskManager: TaskManager) -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        return taskManager.tasks.filter { task in
            guard task.isCompleted,
                  let completedAt = task.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: today)
        }.count
    }
    
    // MARK: - Celebration Triggering
    
    func triggerCelebration(_ type: CelebrationType) {
        // Prevent duplicate celebrations
        guard activeCelebration != type else { return }
        
        DispatchQueue.main.async {
            self.activeCelebration = type
            self.showCelebrationOverlay = true
            
            // Trigger haptic feedback
            HapticManager.shared.triggerCelebration(type.animationStyle.hapticPattern)
            
            // Create particle effect
            self.createParticleEffect(for: type)
            
            // Auto-dismiss after animation duration
            DispatchQueue.main.asyncAfter(deadline: .now() + type.animationStyle.animationDuration) {
                self.dismissCelebration()
            }
        }
    }
    
    private func createParticleEffect(for celebration: CelebrationType) {
        let style = celebration.animationStyle
        celebrationParticles.removeAll()
        
        for i in 0..<style.particleCount {
            let particle = CelebrationParticle(
                id: UUID(),
                color: celebration.colors.randomElement() ?? .blue,
                startPosition: CGPoint(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -50...50)),
                endPosition: CGPoint(
                    x: CGFloat.random(in: -200...200),
                    y: CGFloat.random(in: -300...300)
                ),
                size: CGFloat.random(in: 4...12),
                delay: Double(i) * 0.02
            )
            celebrationParticles.append(particle)
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.5)) {
            showCelebrationOverlay = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.activeCelebration = nil
            self.celebrationParticles.removeAll()
        }
    }
}

// MARK: - Celebration Particle

struct CelebrationParticle: Identifiable {
    let id: UUID
    let color: Color
    let startPosition: CGPoint
    let endPosition: CGPoint
    let size: CGFloat
    let delay: Double
}

// MARK: - Haptic Patterns

extension HapticManager {
    enum HapticPattern {
        case gentle, playful, dramatic, satisfying, radiant, intense, sharp, mysterious, bright, triumphant
    }
    
    func triggerCelebration(_ pattern: HapticPattern) {
        switch pattern {
        case .gentle:
            celebrationGentle()
        case .playful:
            celebrationPlayful()
        case .dramatic:
            celebrationDramatic()
        case .satisfying:
            celebrationSatisfying()
        case .radiant:
            celebrationRadiant()
        case .intense:
            celebrationIntense()
        case .sharp:
            celebrationSharp()
        case .mysterious:
            celebrationMysterious()
        case .bright:
            celebrationBright()
        case .triumphant:
            celebrationTriumphant()
        }
    }
    
    private func celebrationGentle() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            impact.impactOccurred(intensity: 0.7)
        }
    }
    
    private func celebrationPlayful() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let light = UIImpactFeedbackGenerator(style: .light)
            light.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            impact.impactOccurred(intensity: 0.8)
        }
    }
    
    private func celebrationDramatic() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let medium = UIImpactFeedbackGenerator(style: .medium)
            medium.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let light = UIImpactFeedbackGenerator(style: .light)
            light.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            heavy.impactOccurred(intensity: 1.0)
        }
    }
    
    private func celebrationSatisfying() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred(intensity: 0.8)
        }
    }
    
    private func celebrationRadiant() {
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred(intensity: 0.6 + Double(i) * 0.1)
            }
        }
    }
    
    private func celebrationIntense() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.impactOccurred()
        
        for i in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                heavy.impactOccurred(intensity: 0.8)
            }
        }
    }
    
    private func celebrationSharp() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            impact.impactOccurred(intensity: 0.9)
        }
    }
    
    private func celebrationMysterious() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.3)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            impact.impactOccurred(intensity: 0.6)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            impact.impactOccurred(intensity: 0.9)
        }
    }
    
    private func celebrationBright() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let light = UIImpactFeedbackGenerator(style: .light)
            light.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let light = UIImpactFeedbackGenerator(style: .light)
            light.impactOccurred()
        }
    }
    
    private func celebrationTriumphant() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        let notification = UINotificationFeedbackGenerator()
        
        heavy.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            notification.notificationOccurred(.success)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            heavy.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let medium = UIImpactFeedbackGenerator(style: .medium)
            medium.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            notification.notificationOccurred(.success)
        }
    }
}