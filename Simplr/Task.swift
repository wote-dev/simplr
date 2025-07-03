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
    let id = UUID()
    var name: String
    var color: CategoryColor
    var isCustom: Bool
    
    init(name: String, color: CategoryColor, isCustom: Bool = false) {
        self.name = name
        self.color = color
        self.isCustom = isCustom
    }
    
    // Predefined categories
    static let work = TaskCategory(name: "Work", color: .blue)
    static let personal = TaskCategory(name: "Personal", color: .green)
    static let shopping = TaskCategory(name: "Shopping", color: .orange)
    static let health = TaskCategory(name: "Health", color: .red)
    static let learning = TaskCategory(name: "Learning", color: .purple)
    static let travel = TaskCategory(name: "Travel", color: .indigo)
    static let uncategorized = TaskCategory(name: "Uncategorized", color: .gray)
    
    static let predefined: [TaskCategory] = [
        .work, .personal, .shopping, .health, .learning, .travel
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
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, darkColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct Task: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var isCompleted: Bool
    var dueDate: Date?
    var hasReminder: Bool
    var reminderDate: Date?
    var createdAt: Date
    var completedAt: Date?
    var categoryId: UUID?
    
    init(title: String, description: String = "", dueDate: Date? = nil, hasReminder: Bool = false, reminderDate: Date? = nil, categoryId: UUID? = nil) {
        self.title = title
        self.description = description
        self.isCompleted = false
        self.dueDate = dueDate
        self.hasReminder = hasReminder
        self.reminderDate = reminderDate
        self.createdAt = Date()
        self.completedAt = nil
        self.categoryId = categoryId
    }
    
    // MARK: - Task Status Computed Properties
    
    /// Returns true if the task is overdue (past due date and not completed)
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
    
    /// Returns true if the task is pending (has a future due date and not completed)
    var isPending: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate >= Date()
    }
    
    /// Returns true if the task is due today
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    /// Returns true if the task is due in the future (tomorrow or later)
    var isDueFuture: Bool {
        guard let dueDate = dueDate else { return false }
        let today = Date()
        let calendar = Calendar.current
        return dueDate > calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: today)!)
    }
    
    /// Returns the number of days until due date (negative if overdue)
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)
        return calendar.dateComponents([.day], from: today, to: due).day
    }
    
    /// Returns true if the completed task is older than 7 days
    var shouldBeAutoDeleted: Bool {
        guard isCompleted, let completedAt = completedAt else { return false }
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return completedAt < sevenDaysAgo
    }
}