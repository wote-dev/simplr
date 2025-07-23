//
//  Task.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import Foundation
import SwiftUI

// MARK: - Task Category
struct TaskCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var color: CategoryColor
    var isCustom: Bool
    
    init(name: String, color: CategoryColor, isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.isCustom = isCustom
    }
    
    // Custom init for creating categories with specific IDs (for predefined categories)
    init(id: UUID, name: String, color: CategoryColor, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.color = color
        self.isCustom = isCustom
    }
    
    // Predefined categories with fixed UUIDs to maintain consistency across app launches
    static let work = TaskCategory(id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440001")!, name: "Work", color: .blue)
    static let personal = TaskCategory(id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440002")!, name: "Personal", color: .green)
    static let shopping = TaskCategory(id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440003")!, name: "Shopping", color: .teal)
    static let health = TaskCategory(id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440004")!, name: "Health", color: .red)
    static let learning = TaskCategory(id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440005")!, name: "Learning", color: .purple)
    static let travel = TaskCategory(id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440006")!, name: "Travel", color: .indigo)
    static let important = TaskCategory(id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440009")!, name: "IMPORTANT", color: .orange)
    static let urgent = TaskCategory(id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440008")!, name: "URGENT", color: .red)
    static let uncategorized = TaskCategory(id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440007")!, name: "Uncategorized", color: .gray)
    
    static let predefined: [TaskCategory] = [
        .work, .personal, .shopping, .health, .learning, .travel, .important, .urgent
    ]
    
    static func == (lhs: TaskCategory, rhs: TaskCategory) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Category Colors
enum CategoryColor: String, CaseIterable, Codable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case purple = "purple"
    case indigo = "indigo"
    case pink = "pink"
    case teal = "teal"
    case yellow = "yellow"
    case gray = "gray"
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .indigo: return .indigo
        case .pink: return .pink
        case .teal: return .teal
        case .yellow: return .yellow
        case .gray: return .gray
        }
    }
    
    var lightColor: Color {
        color.opacity(0.2)
    }
    
    var mediumColor: Color {
        color.opacity(0.6)
    }
    
    var darkColor: Color {
        switch self {
        case .blue: return Color.blue.opacity(0.8)
        case .green: return Color.green.opacity(0.8)
        case .orange: return Color.orange.opacity(0.8)
        case .red: return Color.red.opacity(0.8)
        case .purple: return Color.purple.opacity(0.8)
        case .indigo: return Color.indigo.opacity(0.8)
        case .pink: return Color.pink.opacity(0.8)
        case .teal: return Color.teal.opacity(0.8)
        case .yellow: return Color.yellow.opacity(0.8)
        case .gray: return Color.gray.opacity(0.8)
        }
    }
    
    /// Soft pastel colors for kawaii theme
    var kawaiiColor: Color {
        switch self {
        case .blue: return Color(red: 0.85, green: 0.92, blue: 0.98)    // Soft sky blue
        case .green: return Color(red: 0.88, green: 0.96, blue: 0.88)   // Soft mint green
        case .orange: return Color(red: 0.98, green: 0.92, blue: 0.85)  // Soft peach
        case .red: return Color(red: 0.98, green: 0.88, blue: 0.88)     // Soft rose
        case .purple: return Color(red: 0.94, green: 0.88, blue: 0.98)  // Soft lavender
        case .indigo: return Color(red: 0.90, green: 0.90, blue: 0.98)  // Soft periwinkle
        case .pink: return Color(red: 0.98, green: 0.88, blue: 0.92)    // Soft blush
        case .teal: return Color(red: 0.85, green: 0.96, blue: 0.94)    // Soft aqua
        case .yellow: return Color(red: 0.98, green: 0.96, blue: 0.85)  // Soft cream
        case .gray: return Color(red: 0.92, green: 0.92, blue: 0.94)    // Soft silver
        }
    }
    
    /// Kawaii light color for backgrounds
    var kawaiiLightColor: Color {
        kawaiiColor.opacity(0.3)
    }
    
    /// Kawaii dark color for text and borders
    var kawaiiDarkColor: Color {
        switch self {
        case .blue: return Color(red: 0.65, green: 0.75, blue: 0.85)
        case .green: return Color(red: 0.70, green: 0.82, blue: 0.70)
        case .orange: return Color(red: 0.85, green: 0.75, blue: 0.65)
        case .red: return Color(red: 0.85, green: 0.70, blue: 0.70)
        case .purple: return Color(red: 0.80, green: 0.70, blue: 0.85)
        case .indigo: return Color(red: 0.75, green: 0.75, blue: 0.85)
        case .pink: return Color(red: 0.85, green: 0.70, blue: 0.78)
        case .teal: return Color(red: 0.65, green: 0.82, blue: 0.80)
        case .yellow: return Color(red: 0.85, green: 0.82, blue: 0.65)
        case .gray: return Color(red: 0.75, green: 0.75, blue: 0.78)
        }
    }
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, darkColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Kawaii gradient for soft pastel appearance
    var kawaiiGradient: LinearGradient {
        LinearGradient(
            colors: [kawaiiColor, kawaiiDarkColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Enhanced pastel colors for serene theme - more apparent yet still calming
    var sereneColor: Color {
        switch self {
        case .blue: return Color(red: 0.65, green: 0.75, blue: 0.90)     // Enhanced serene blue
        case .green: return Color(red: 0.70, green: 0.88, blue: 0.75)    // Enhanced serene sage
        case .orange: return Color(red: 0.92, green: 0.78, blue: 0.68)   // Enhanced serene terracotta
        case .red: return Color(red: 0.88, green: 0.68, blue: 0.72)      // Enhanced serene rose
        case .purple: return Color(red: 0.78, green: 0.70, blue: 0.92)   // Enhanced serene lavender
        case .indigo: return Color(red: 0.70, green: 0.75, blue: 0.90)   // Enhanced serene periwinkle
        case .pink: return Color(red: 0.92, green: 0.70, blue: 0.80)     // Enhanced serene blush
        case .teal: return Color(red: 0.65, green: 0.88, blue: 0.80)     // Enhanced serene aqua
        case .yellow: return Color(red: 0.92, green: 0.88, blue: 0.68)   // Enhanced serene cream
        case .gray: return Color(red: 0.75, green: 0.75, blue: 0.85)     // Enhanced serene silver
        }
    }
    
    /// Serene light color for backgrounds
    var sereneLightColor: Color {
        sereneColor.opacity(0.25)
    }
    
    /// Enhanced serene dark color for text and borders
    var sereneDarkColor: Color {
        switch self {
        case .blue: return Color(red: 0.50, green: 0.62, blue: 0.78)
        case .green: return Color(red: 0.55, green: 0.75, blue: 0.62)
        case .orange: return Color(red: 0.78, green: 0.62, blue: 0.52)
        case .red: return Color(red: 0.75, green: 0.52, blue: 0.58)
        case .purple: return Color(red: 0.62, green: 0.55, blue: 0.78)
        case .indigo: return Color(red: 0.55, green: 0.62, blue: 0.78)
        case .pink: return Color(red: 0.78, green: 0.55, blue: 0.65)
        case .teal: return Color(red: 0.50, green: 0.75, blue: 0.68)
        case .yellow: return Color(red: 0.78, green: 0.75, blue: 0.52)
        case .gray: return Color(red: 0.62, green: 0.62, blue: 0.72)
        }
    }
    
    /// Serene gradient for subdued appearance
    var sereneGradient: LinearGradient {
        LinearGradient(
            colors: [sereneColor, sereneDarkColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Enhanced warm pastel colors for coffee theme - more apparent yet still warm and cozy
    var coffeeColor: Color {
        switch self {
        case .blue: return Color(red: 0.68, green: 0.75, blue: 0.85)     // Enhanced coffee-blue
        case .green: return Color(red: 0.72, green: 0.85, blue: 0.68)    // Enhanced coffee-sage
        case .orange: return Color(red: 0.88, green: 0.72, blue: 0.62)   // Enhanced coffee-terracotta
        case .red: return Color(red: 0.85, green: 0.65, blue: 0.62)      // Enhanced coffee-rose
        case .purple: return Color(red: 0.80, green: 0.68, blue: 0.85)   // Enhanced coffee-lavender
        case .indigo: return Color(red: 0.70, green: 0.75, blue: 0.85)   // Enhanced coffee-periwinkle
        case .pink: return Color(red: 0.88, green: 0.68, blue: 0.75)     // Enhanced coffee-blush
        case .teal: return Color(red: 0.65, green: 0.85, blue: 0.78)     // Enhanced coffee-aqua
        case .yellow: return Color(red: 0.88, green: 0.82, blue: 0.62)   // Enhanced coffee-cream
        case .gray: return Color(red: 0.78, green: 0.75, blue: 0.72)     // Enhanced coffee-silver
        }
    }
    
    /// Coffee light color for backgrounds
    var coffeeLightColor: Color {
        coffeeColor.opacity(0.25)
    }
    
    /// Enhanced coffee dark color for text and borders
    var coffeeDarkColor: Color {
        switch self {
        case .blue: return Color(red: 0.52, green: 0.62, blue: 0.72)
        case .green: return Color(red: 0.58, green: 0.72, blue: 0.52)
        case .orange: return Color(red: 0.72, green: 0.58, blue: 0.48)
        case .red: return Color(red: 0.72, green: 0.50, blue: 0.48)
        case .purple: return Color(red: 0.65, green: 0.52, blue: 0.72)
        case .indigo: return Color(red: 0.55, green: 0.62, blue: 0.72)
        case .pink: return Color(red: 0.72, green: 0.52, blue: 0.62)
        case .teal: return Color(red: 0.50, green: 0.72, blue: 0.65)
        case .yellow: return Color(red: 0.72, green: 0.68, blue: 0.48)
        case .gray: return Color(red: 0.65, green: 0.62, blue: 0.58)
        }
    }
    
    /// Coffee gradient for subdued appearance
    var coffeeGradient: LinearGradient {
        LinearGradient(
            colors: [coffeeColor, coffeeDarkColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}



// MARK: - Checklist Item
struct ChecklistItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var isCompleted: Bool
    var dueDate: Date?
    var hasReminder: Bool
    var reminderDate: Date?
    var createdAt: Date
    var completedAt: Date?
    var categoryId: UUID?
    var checklist: [ChecklistItem]

    
    init(title: String, description: String = "", dueDate: Date? = nil, hasReminder: Bool = false, reminderDate: Date? = nil, categoryId: UUID? = nil, checklist: [ChecklistItem] = []) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.isCompleted = false
        self.dueDate = dueDate
        self.hasReminder = hasReminder
        self.reminderDate = reminderDate
        self.createdAt = Date()
        self.completedAt = nil
        self.categoryId = categoryId
        self.checklist = checklist
    }
    
    // MARK: - Task Status Computed Properties
    // Optimized with cached date calculations to reduce repeated Calendar operations
    
    private static let calendar = Calendar.current
    private static var todayCache: (date: Date, startOfDay: Date) = {
        let now = Date()
        return (now, calendar.startOfDay(for: now))
    }()
    
    private static func updateTodayCache() {
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        if !calendar.isDate(todayCache.date, inSameDayAs: now) {
            todayCache = (now, startOfDay)
        }
    }
    
    /// Returns true if the task is overdue (past due date and not completed)
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        Task.updateTodayCache()
        return dueDate < Task.todayCache.date
    }
    
    /// Returns true if the task is pending (has a future due date and not completed)
    var isPending: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        Task.updateTodayCache()
        return dueDate >= Task.todayCache.date
    }
    
    /// Returns true if the task is due today
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        Task.updateTodayCache()
        return Task.calendar.isDate(dueDate, inSameDayAs: Task.todayCache.date)
    }
    
    /// Returns true if the task is due in the future (tomorrow or later)
    var isDueFuture: Bool {
        guard let dueDate = dueDate else { return false }
        Task.updateTodayCache()
        let tomorrow = Task.calendar.date(byAdding: .day, value: 1, to: Task.todayCache.startOfDay)!
        return dueDate >= tomorrow
    }
    
    /// Returns the number of days until due date (negative if overdue)
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        Task.updateTodayCache()
        let due = Task.calendar.startOfDay(for: dueDate)
        return Task.calendar.dateComponents([.day], from: Task.todayCache.startOfDay, to: due).day
    }
    
    /// Returns true if the completed task is older than 7 days
    var shouldBeAutoDeleted: Bool {
        guard isCompleted, let completedAt = completedAt else { return false }
        Task.updateTodayCache()
        let sevenDaysAgo = Task.calendar.date(byAdding: .day, value: -7, to: Task.todayCache.date) ?? Task.todayCache.date
        return completedAt < sevenDaysAgo
    }
    

}