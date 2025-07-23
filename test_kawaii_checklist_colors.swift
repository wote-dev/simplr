//
//  test_kawaii_checklist_colors.swift
//  Simplr
//
//  Test file to verify kawaii theme checklist colors
//

import SwiftUI

struct KawaiiChecklistColorsTest: View {
    @State private var checklistItems = [
        ChecklistItem(title: "Complete task 1", isCompleted: true),
        ChecklistItem(title: "Complete task 2", isCompleted: true),
        ChecklistItem(title: "Complete task 3", isCompleted: false),
        ChecklistItem(title: "Complete task 4", isCompleted: false)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Kawaii Theme Checklist Colors Test")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(KawaiiTheme().text)
            
            // Progress bar test
            VStack(alignment: .leading, spacing: 8) {
                Text("Progress Bar Test")
                    .font(.headline)
                    .foregroundColor(KawaiiTheme().text)
                
                ChecklistProgressHeader(checklist: checklistItems)
                    .environment(\.theme, KawaiiTheme())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(KawaiiTheme().surface)
            )
            
            // Checklist items test
            VStack(alignment: .leading, spacing: 8) {
                Text("Checklist Visual Feedback Test")
                    .font(.headline)
                    .foregroundColor(KawaiiTheme().text)
                
                ForEach(checklistItems) { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(item.isCompleted ? KawaiiTheme().success : KawaiiTheme().textTertiary)
                        
                        Text(item.title)
                            .font(.caption)
                            .foregroundColor(item.isCompleted ? KawaiiTheme().textSecondary : KawaiiTheme().text)
                            .strikethrough(item.isCompleted)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(KawaiiTheme().surface)
            )
            
            // Color comparison
            VStack(alignment: .leading, spacing: 8) {
                Text("Color Values")
                    .font(.headline)
                    .foregroundColor(KawaiiTheme().text)
                
                HStack {
                    Text("Success/Progress:")
                        .font(.caption)
                    Rectangle()
                        .fill(KawaiiTheme().success)
                        .frame(width: 30, height: 20)
                        .cornerRadius(4)
                    Text("RGB(0.85, 0.45, 0.55)")
                        .font(.caption)
                        .foregroundColor(KawaiiTheme().textSecondary)
                }
                
                HStack {
                    Text("Old Mint Green:")
                        .font(.caption)
                    Rectangle()
                        .fill(Color(red: 0.7, green: 0.95, blue: 0.8))
                        .frame(width: 30, height: 20)
                        .cornerRadius(4)
                    Text("RGB(0.7, 0.95, 0.8)")
                        .font(.caption)
                        .foregroundColor(KawaiiTheme().textSecondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(KawaiiTheme().surface)
            )
            
            Spacer()
        }
        .padding()
        .background(KawaiiTheme().background)
    }
}

#Preview {
    KawaiiChecklistColorsTest()
        .environment(\.theme, KawaiiTheme())
}