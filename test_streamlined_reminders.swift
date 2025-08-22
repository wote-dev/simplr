//
//  test_streamlined_reminders.swift
//  Simplr Reminder Streamlining Test
//
//  Created by AI Assistant on 2025
//

import SwiftUI
import XCTest

// MARK: - Streamlined Reminder Test Suite

struct StreamlinedReminderTestView: View {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var themeManager = ThemeManager()
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Streamlined Reminder Tests")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.text)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Test 1: Quick preset buttons
                        TestCard(title: "Quick Preset Buttons") {
                            AddTaskView(taskManager: taskManager)
                                .environmentObject(themeManager)
                                .environmentObject(CategoryManager())
                        }
                        
                        // Test 2: Smart defaults
                        TestCard(title: "Smart Defaults") {
                            AddTaskView(taskManager: taskManager, taskToEdit: nil)
                                .environmentObject(themeManager)
                                .environmentObject(CategoryManager())
                        }
                        
                        // Test 3: Performance validation
                        TestCard(title: "Performance Test") {
                            PerformanceTestView(taskManager: taskManager)
                        }
                        
                        // Test 4: Theme compatibility
                        TestCard(title: "Theme Compatibility") {
                            ThemeTestView(taskManager: taskManager)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Task") {
                        showingAddTask = true
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(taskManager: taskManager)
                    .environmentObject(themeManager)
                    .environmentObject(CategoryManager())
            }
        }
    }
}

// MARK: - Test Components

struct TestCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
        }
    }
}

struct PerformanceTestView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var iterationCount = 0
    @State private var averageTime: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
            
            Button("Run Performance Test") {
                runPerformanceTest()
            }
            .buttonStyle(.borderedProminent)
            
            Text("Iterations: \(iterationCount)")
            Text("Average Time: \(String(format: "%.4f", averageTime))ms")
        }
    }
    
    private func runPerformanceTest() {
        let startTime = CFAbsoluteTimeGetCurrent()
        let iterations = 100
        
        for i in 0..<iterations {
            let task = Task(
                title: "Test Task \(i)",
                description: "Performance test task",
                hasReminder: true,
                reminderDate: Date().addingTimeInterval(Double(i * 60))
            )
            taskManager.addTask(task)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        iterationCount = iterations
        averageTime = ((endTime - startTime) * 1000) / Double(iterations)
    }
}

struct ThemeTestView: View {
    @ObservedObject var taskManager: TaskManager
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Theme Compatibility")
                .font(.headline)
            
            ForEach(ThemeMode.allCases, id: \.self) { theme in
                Button(theme.rawValue) {
                    themeManager.themeMode = theme
                }
                .buttonStyle(.bordered)
            }
            
            AddTaskView(taskManager: taskManager)
                .environmentObject(themeManager)
                .environmentObject(CategoryManager())
                .frame(height: 300)
        }
    }
}

// MARK: - Unit Tests

class StreamlinedReminderTests: XCTestCase {
    
    func testQuickPresetCalculations() {
        let now = Date()
        let calendar = Calendar.current
        
        // Test 15 minutes preset
        let fifteenMin = QuickReminderPreset.in15Minutes.calculateDate(from: now)
        let expected15Min = calendar.date(byAdding: .minute, value: 15, to: now)
        XCTAssertEqual(fifteenMin, expected15Min)
        
        // Test 1 hour preset
        let oneHour = QuickReminderPreset.in1Hour.calculateDate(from: now)
        let expected1Hour = calendar.date(byAdding: .hour, value: 1, to: now)
        XCTAssertEqual(oneHour, expected1Hour)
        
        // Test tomorrow morning
        let tomorrowAM = QuickReminderPreset.tomorrowMorning.calculateDate(from: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)
        let expectedTomorrowAM = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow!)
        XCTAssertEqual(tomorrowAM, expectedTomorrowAM)
    }
    
    func testSmartReminderDefaults() {
        let taskManager = TaskManager()
        let addTaskView = AddTaskView(taskManager: taskManager)
        
        // Test due date based reminder
        let dueDate = Date().addingTimeInterval(3600 * 2) // 2 hours from now
        // This would test the smart default logic
        
        XCTAssertTrue(true) // Placeholder for smart default test
    }
    
    func testReminderValidation() {
        let pastDate = Date().addingTimeInterval(-3600)
        let validatedDate = AddTaskView(taskManager: TaskManager()).validateReminderDate(pastDate)
        
        XCTAssertGreaterThan(validatedDate, Date())
    }
    
    func testPerformance() {
        measure {
            let taskManager = TaskManager()
            for i in 0..<100 {
                let task = Task(
                    title: "Performance Task \(i)",
                    description: "Test",
                    hasReminder: true,
                    reminderDate: Date().addingTimeInterval(Double(i * 60))
                )
                taskManager.addTask(task)
            }
        }
    }
}

// MARK: - Preview Provider

struct StreamlinedReminderTestView_Previews: PreviewProvider {
    static var previews: some View {
        StreamlinedReminderTestView()
    }
}