//
//  Task+Widget.swift
//  SimplrWidget
//
//  Created by Daniel Zverev on 2/7/2025.
//

import Foundation
import SwiftUI

// MARK: - Widget Category Models
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
    
    static func == (lhs: TaskCategory, rhs: TaskCategory) -> Bool {
        lhs.id == rhs.id
    }
}

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
}

// Shared Task model for widget extension
// This mirrors the main app's Task model
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
}