//
//  ThemePreviewTest.swift
//  Simplr
//
//  Created by AI Assistant on 2025-02-07.
//

import SwiftUI

/// Test view to verify that context menu previews properly adapt to themes
struct ThemePreviewTest: View {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var taskManager = TaskManager()
    @StateObject private var categoryManager = CategoryManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Theme Preview Test")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.text)
                    
                    Text("Long press the task below to test theme adaptation")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    // Theme selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ThemeMode.allCases, id: \.self) { mode in
                                Button(mode.displayName) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        themeManager.themeMode = mode
                                    }
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.themeMode == mode ? 
                                              themeManager.currentTheme.accent : 
                                              themeManager.currentTheme.surfaceSecondary)
                                )
                                .foregroundColor(
                                    themeManager.themeMode == mode ? 
                                    .white : themeManager.currentTheme.text
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Test task with context menu preview
                    let testTask = Task(
                        title: "Test Task for Theme Preview",
                        description: "This task tests whether context menu previews adapt to the selected theme. Long press to see the preview.",
                        dueDate: Date().addingTimeInterval(3600),
                        hasReminder: true
                    )
                    
                    TaskRowView(
                        task: testTask,
                        namespace: Namespace().wrappedValue,
                        onToggleCompletion: {},
                        onEdit: {},
                        onDelete: {},
                        onDeleteCanceled: nil,
                        isInCompletedView: false
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .environment(\.theme, themeManager.currentTheme)
            .environmentObject(themeManager)
            .environmentObject(taskManager)
            .environmentObject(categoryManager)
            .navigationTitle("Theme Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ThemePreviewTest()
}