//
//  Test file to verify urgent pill visibility improvements
//  Created to test the enhanced contrast for urgent task pills in light themes
//

import SwiftUI

struct UrgentPillVisibilityTest: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Urgent Task Pill Visibility Test")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Light Theme Test")
                .font(.headline)
            
            // Simulate urgent task pills in light theme
            HStack(spacing: 12) {
                // Due date pill with new styling
                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("Today 2:30 PM")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.white) // White text for maximum contrast
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.8)) // Dark background
                )
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.9), lineWidth: 1)
                )
                
                // Reminder pill with new styling
                HStack(spacing: 3) {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                    Text("1:00 PM")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.white) // White text for maximum contrast
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(red: 0.9, green: 0.5, blue: 0.0)) // Solid orange background
                )
                .overlay(
                    Capsule()
                        .stroke(Color(red: 0.7, green: 0.4, blue: 0.0), lineWidth: 1.5)
                )
            }
            
            Text("Kawaii Theme Test")
                .font(.headline)
            
            // Same pills but on kawaii background
            HStack(spacing: 12) {
                // Due date pill
                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("Today 2:30 PM")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.8))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.9), lineWidth: 1)
                )
                
                // Reminder pill
                HStack(spacing: 3) {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                    Text("1:00 PM")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(red: 0.9, green: 0.5, blue: 0.0))
                )
                .overlay(
                    Capsule()
                        .stroke(Color(red: 0.7, green: 0.4, blue: 0.0), lineWidth: 1.5)
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.97, green: 0.94, blue: 0.92)) // Kawaii background
            )
            
            Text("✅ Pills should now be clearly visible with white text on dark backgrounds")
                .font(.caption)
                .foregroundColor(.green)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(red: 0.98, green: 0.98, blue: 0.98)) // Light theme background
    }
}

#Preview {
    UrgentPillVisibilityTest()
}