//
//  SharedModels.swift
//  SimplrWidget
//
//  Created by Daniel Zverev on 2/7/2025.
//

import Foundation
import SwiftUI

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
}

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

// MARK: - Task
// MARK: - Quick List Item
struct QuickListItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    
    init(text: String) {
        self.id = UUID()
        self.text = text
        self.isCompleted = false
        self.createdAt = Date()
        self.completedAt = nil
    }
    
    static func == (lhs: QuickListItem, rhs: QuickListItem) -> Bool {
        return lhs.id == rhs.id
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
    var quickListItems: [QuickListItem]
    
    init(title: String, description: String = "", dueDate: Date? = nil, hasReminder: Bool = false, reminderDate: Date? = nil, categoryId: UUID? = nil, quickListItems: [QuickListItem] = []) {
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
        self.quickListItems = quickListItems
    }
    
    // MARK: - Task Status Computed Properties
    private static let calendar = Calendar.current
    
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
        return Task.calendar.isDate(dueDate, inSameDayAs: Date())
    }
    
    /// Returns true if the task is due in the future (tomorrow or later)
    var isDueFuture: Bool {
        guard let dueDate = dueDate else { return false }
        let today = Task.calendar.startOfDay(for: Date())
        let tomorrow = Task.calendar.date(byAdding: .day, value: 1, to: today)!
        return dueDate >= tomorrow
    }
    
    /// Returns the number of days until due date (negative if overdue)
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let today = Task.calendar.startOfDay(for: Date())
        let due = Task.calendar.startOfDay(for: dueDate)
        return Task.calendar.dateComponents([.day], from: today, to: due).day
    }
}