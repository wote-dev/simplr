//
//  test_kawaii_pill_contrast.swift
//  Enhanced Contrast Test for Kawaii Theme Pills
//
//  This file demonstrates the improved visibility of due date and reminder pills
//  on urgent task cards in kawaii mode with maximum contrast styling.
//

import SwiftUI

struct KawaiiPillContrastTest: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Enhanced Kawaii Theme Pill Contrast")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.15, green: 0.05, blue: 0.1))
            
            // Kawaii background simulation
            VStack(spacing: 16) {
                // Due Date Pill - Maximum Contrast for Kawaii
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("Today 2:30 PM")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white) // White text for maximum contrast
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(red: 0.05, green: 0.05, blue: 0.05)) // Nearly black background
                )
                .overlay(
                    Capsule()
                        .stroke(Color.black, lineWidth: 2.0) // Thick black border
                )
                
                // Reminder Pill - Maximum Contrast for Kawaii
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                    Text("1:30 PM")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white) // White text for maximum contrast
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(red: 0.7, green: 0.3, blue: 0.0)) // Dark orange background
                )
                .overlay(
                    Capsule()
                        .stroke(Color(red: 0.5, green: 0.2, blue: 0.0), lineWidth: 2.0) // Darker orange border
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.97, green: 0.94, blue: 0.92)) // Kawaii background color
            )
            
            Text("Key Improvements:")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.15, green: 0.05, blue: 0.1))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Due Date Pill: Nearly black background (0.05, 0.05, 0.05) with solid black 2pt border")
                Text("• Reminder Pill: Dark orange background (0.7, 0.3, 0.0) with darker orange 2pt border")
                Text("• White text on both pills for maximum contrast against kawaii pink background")
                Text("• Thicker borders (2pt) specifically for kawaii theme visibility")
                Text("• Smart theme detection to apply different contrast levels per theme")
            }
            .font(.caption)
            .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.3))
            .padding(.horizontal)
        }
        .padding()
        .background(Color(red: 0.98, green: 0.96, blue: 0.94))
    }
}

#Preview {
    KawaiiPillContrastTest()
}