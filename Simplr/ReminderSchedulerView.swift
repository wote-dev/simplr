//
//  ReminderSchedulerView.swift
//  Simplr
//
//  Created by Daniel Zverev on 2/7/2025.
//

import SwiftUI

struct ReminderSchedulerView: View {
    @Environment(\.theme) var theme
    @Binding var isPresented: Bool
    @Binding var reminderDate: Date
    @Binding var hasReminder: Bool
    
    let dueDate: Date?
    
    @State private var selectedDateTime = Date()
    @State private var dragOffset: CGFloat = 0
    @State private var showContent = false
    @State private var pickerMode: PickerMode = .dateAndTime
    
    private enum PickerMode: CaseIterable {
        case dateAndTime
        case dateOnly
        case timeOnly
        
        var title: String {
            switch self {
            case .dateAndTime: return "Date & Time"
            case .dateOnly: return "Date Only"
            case .timeOnly: return "Time Only"
            }
        }
        
        var icon: String {
            switch self {
            case .dateAndTime: return "calendar.clock"
            case .dateOnly: return "calendar"
            case .timeOnly: return "clock"
            }
        }
        
        var components: DatePickerComponents {
            switch self {
            case .dateAndTime: return [.date, .hourAndMinute]
            case .dateOnly: return [.date]
            case .timeOnly: return [.hourAndMinute]
            }
        }
    }
    
    var body: some View {
        if isPresented {
            ZStack {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                
                // Bottom sheet
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Drag handle
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(theme.textSecondary.opacity(0.3))
                            .frame(width: 36, height: 5)
                            .padding(.top, 12)
                        
                        // Header
                        VStack(spacing: 8) {
                            Text("Set Reminder")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(theme.text)
                            
                            Text("Choose when to be reminded")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        // Picker mode selector
                         VStack(spacing: 12) {
                             HStack {
                                 Image(systemName: "slider.horizontal.3")
                                     .font(.system(size: 16, weight: .semibold))
                                     .foregroundColor(theme.accent)
                                 
                                 Text("Picker Mode")
                                     .font(.headline)
                                     .fontWeight(.semibold)
                                     .foregroundColor(theme.text)
                                 
                                 Spacer()
                             }
                             
                             ScrollView(.horizontal, showsIndicators: false) {
                                 HStack(spacing: 12) {
                                     ForEach(PickerMode.allCases, id: \.self) { mode in
                                         Button(action: {
                                             withAnimation(.easeInOut(duration: 0.2)) {
                                                 pickerMode = mode
                                                 HapticManager.shared.selectionChange()
                                             }
                                         }) {
                                             HStack(spacing: 8) {
                                                 Image(systemName: mode.icon)
                                                     .font(.system(size: 14, weight: .medium))
                                                 
                                                 Text(mode.title)
                                                     .font(.system(size: 14, weight: .medium))
                                             }
                                             .foregroundColor(pickerMode == mode ? .white : theme.text)
                                             .padding(.horizontal, 16)
                                             .padding(.vertical, 10)
                                             .background(
                                                 RoundedRectangle(cornerRadius: 20)
                                                     .fill(pickerMode == mode ? theme.accent : theme.surfaceSecondary.opacity(0.5))
                                             )
                                         }
                                         .buttonStyle(PlainButtonStyle())
                                     }
                                 }
                                 .padding(.horizontal)
                             }
                         }
                         .padding(.horizontal)
                         
                         // Date picker
                         VStack(spacing: 16) {
                             HStack {
                                 Image(systemName: pickerMode.icon)
                                     .font(.system(size: 16, weight: .semibold))
                                     .foregroundColor(theme.accent)
                                 
                                 Text("Select \(pickerMode.title)")
                                     .font(.headline)
                                     .fontWeight(.semibold)
                                     .foregroundColor(theme.text)
                                 
                                 Spacer()
                             }
                             
                             DatePicker(
                                 "Reminder \(pickerMode.title)",
                                 selection: $selectedDateTime,
                                 in: Date()...,
                                 displayedComponents: pickerMode.components
                             )
                             .datePickerStyle(.wheel)
                             .labelsHidden()
                             .background(Color.clear)
                             .clipShape(RoundedRectangle(cornerRadius: 12))
                             .padding(.vertical, 16)
                             .background(
                                 RoundedRectangle(cornerRadius: 12)
                                     .fill(theme.background)
                                     .overlay(
                                         RoundedRectangle(cornerRadius: 12)
                                             .stroke(theme.surfaceSecondary, lineWidth: 1)
                                     )
                             )
                         }
                          .padding(.horizontal)
                          
                          // Quick time suggestions for time-only mode
                          if pickerMode == .timeOnly {
                              quickTimeSuggestions
                          }
                         
                         // Reminder preview
                         reminderPreview
                         
                         // Action buttons
                         VStack(spacing: 12) {
                             // Set Reminder button
                             Button(action: setReminder) {
                                 HStack {
                                     Image(systemName: "bell.fill")
                                         .font(.system(size: 16, weight: .semibold))
                                     
                                     Text(isValidReminderTime ? "Set Reminder" : "Set Reminder (Past Time)")
                                         .font(.headline)
                                         .fontWeight(.semibold)
                                 }
                                 .foregroundColor(.white)
                                 .frame(maxWidth: .infinity)
                                 .padding(.vertical, 16)
                                 .background(
                                     RoundedRectangle(cornerRadius: 16)
                                         .fill(isValidReminderTime ? theme.accent : Color.orange.opacity(0.8))
                                 )
                             }
                             .disabled(!isValidReminderTime)
                             
                             // Remove Reminder button (if has reminder)
                             if hasReminder {
                                 Button(action: removeReminder) {
                                     HStack {
                                         Image(systemName: "bell.slash")
                                             .font(.system(size: 16, weight: .semibold))
                                         
                                         Text("Remove Reminder")
                                             .font(.headline)
                                             .fontWeight(.semibold)
                                     }
                                     .foregroundColor(theme.accent)
                                     .frame(maxWidth: .infinity)
                                     .padding(.vertical, 16)
                                     .background(
                                         RoundedRectangle(cornerRadius: 16)
                                             .stroke(theme.accent, lineWidth: 2)
                                             .background(
                                                 RoundedRectangle(cornerRadius: 16)
                                                     .fill(theme.background)
                                             )
                                     )
                                 }
                             }
                         }
                         .padding(.horizontal)
                         .padding(.bottom, 20)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(theme.surface)
                    )
                    .offset(y: dragOffset)
                }
            }
            .opacity(showContent ? 1 : 0)
            .onAppear {
                selectedDateTime = reminderDate
                withAnimation(.easeOut(duration: 0.3)) {
                    showContent = true
                }
            }
        }
    }
     
     private var quickTimeSuggestions: some View {
         VStack(spacing: 12) {
             HStack {
                 Text("Quick Times")
                     .font(.subheadline)
                     .fontWeight(.medium)
                     .foregroundColor(theme.textSecondary)
                 
                 Spacer()
             }
             
             LazyVGrid(columns: [
                 GridItem(.flexible()),
                 GridItem(.flexible()),
                 GridItem(.flexible())
             ], spacing: 8) {
                 quickTimeButton("9:00 AM", hour: 9, minute: 0)
                 quickTimeButton("12:00 PM", hour: 12, minute: 0)
                 quickTimeButton("6:00 PM", hour: 18, minute: 0)
                 quickTimeButton("9:00 PM", hour: 21, minute: 0)
                 quickTimeButton("Now", useCurrentTime: true)
                 quickTimeButton("+1 Hour", addHours: 1)
             }
         }
         .padding(.horizontal)
     }
     
     private func quickTimeButton(_ title: String, hour: Int? = nil, minute: Int? = nil, useCurrentTime: Bool = false, addHours: Int? = nil) -> some View {
         Button(action: {
             var newDate = selectedDateTime
             let calendar = Calendar.current
             
             if useCurrentTime {
                 newDate = Date()
             } else if let addHours = addHours {
                 newDate = calendar.date(byAdding: .hour, value: addHours, to: Date()) ?? Date()
             } else if let hour = hour, let minute = minute {
                 var components = calendar.dateComponents([.year, .month, .day], from: selectedDateTime)
                 components.hour = hour
                 components.minute = minute
                 newDate = calendar.date(from: components) ?? selectedDateTime
             }
             
             withAnimation(.easeInOut(duration: 0.2)) {
                 selectedDateTime = newDate
                 HapticManager.shared.selectionChange()
             }
         }) {
             Text(title)
                 .font(.caption)
                 .fontWeight(.medium)
                 .foregroundColor(theme.text)
                 .padding(.horizontal, 12)
                 .padding(.vertical, 8)
                 .background(
                     RoundedRectangle(cornerRadius: 8)
                         .fill(theme.surfaceSecondary)
                 )
         }
         .buttonStyle(PlainButtonStyle())
     }
     
     private var reminderPreview: some View {
         VStack(spacing: 8) {
             HStack {
                 Image(systemName: "info.circle")
                     .font(.system(size: 14, weight: .medium))
                     .foregroundColor(theme.accent)
                 
                 Text("Reminder Preview")
                     .font(.subheadline)
                     .fontWeight(.medium)
                     .foregroundColor(theme.text)
                 
                 Spacer()
             }
             
             HStack {
                 VStack(alignment: .leading, spacing: 4) {
                     Text(formatPreviewDate(selectedDateTime))
                         .font(.body)
                         .fontWeight(.semibold)
                         .foregroundColor(isValidReminderTime ? theme.text : Color.orange)
                     
                     if !isValidReminderTime {
                         Text("This time is in the past")
                             .font(.caption)
                             .foregroundColor(Color.orange)
                     } else {
                         Text(timeUntilReminder)
                             .font(.caption)
                             .foregroundColor(theme.textSecondary)
                     }
                 }
                 
                 Spacer()
                 
                 if !isValidReminderTime {
                     Button("Fix") {
                         withAnimation(.easeInOut(duration: 0.2)) {
                             selectedDateTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                             HapticManager.shared.selectionChange()
                         }
                     }
                     .font(.caption)
                     .fontWeight(.medium)
                     .foregroundColor(.white)
                     .padding(.horizontal, 12)
                     .padding(.vertical, 6)
                     .background(
                         RoundedRectangle(cornerRadius: 8)
                             .fill(Color.orange)
                     )
                 }
             }
         }
         .padding(16)
         .background(
             RoundedRectangle(cornerRadius: 12)
                 .fill(theme.surfaceSecondary.opacity(0.5))
                 .overlay(
                     RoundedRectangle(cornerRadius: 12)
                         .stroke(isValidReminderTime ? theme.surfaceSecondary : Color.orange.opacity(0.3), lineWidth: 1)
                 )
         )
         .padding(.horizontal)
     }
     
     private var isValidReminderTime: Bool {
         selectedDateTime > Date()
     }
     
     private var timeUntilReminder: String {
         let timeInterval = selectedDateTime.timeIntervalSince(Date())
         let formatter = DateComponentsFormatter()
         formatter.allowedUnits = [.day, .hour, .minute]
         formatter.unitsStyle = .abbreviated
         formatter.maximumUnitCount = 2
         
         if let formattedString = formatter.string(from: timeInterval) {
             return "In \(formattedString)"
         } else {
             return "Soon"
         }
     }
     
     private func formatPreviewDate(_ date: Date) -> String {
         let formatter = DateFormatter()
         let calendar = Calendar.current
         
         if calendar.isDateInToday(date) {
             formatter.timeStyle = .short
             return "Today at \(formatter.string(from: date))"
         } else if calendar.isDateInTomorrow(date) {
             formatter.timeStyle = .short
             return "Tomorrow at \(formatter.string(from: date))"
         } else {
             formatter.dateStyle = .medium
             formatter.timeStyle = .short
             return formatter.string(from: date)
         }
     }
     
     private func setReminder() {
        reminderDate = selectedDateTime
        hasReminder = true
        HapticManager.shared.buttonTap()
        dismiss()
    }
    
    private func removeReminder() {
        hasReminder = false
        HapticManager.shared.buttonTap()
        dismiss()
    }
    
    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    @Previewable @State var reminderDate = Date()
    @Previewable @State var hasReminder = false
    
    return ReminderSchedulerView(
        isPresented: $isPresented,
        reminderDate: $reminderDate,
        hasReminder: $hasReminder,
        dueDate: Date().addingTimeInterval(3600)
    )
    .environment(\.theme, LightTheme())
}