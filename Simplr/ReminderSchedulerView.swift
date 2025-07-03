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
    
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showContent = false
    @GestureState private var dragState = DragState.inactive
    
    let dueDate: Date?
    
    private enum DragState {
        case inactive
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
        
        var isDragging: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }
    
    init(isPresented: Binding<Bool>, reminderDate: Binding<Date>, hasReminder: Binding<Bool>, dueDate: Date?) {
        self._isPresented = isPresented
        self._reminderDate = reminderDate
        self._hasReminder = hasReminder
        self.dueDate = dueDate
        
        let initialDate = reminderDate.wrappedValue
        self._selectedDate = State(initialValue: initialDate)
        self._selectedTime = State(initialValue: initialDate)
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                // Background overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                    .transition(.opacity)
                
                // Bottom sheet
                VStack(spacing: 0) {
                    Spacer()
                    
                    bottomSheetContent
                        .offset(y: dragOffset + dragState.translation.height)
                        .scaleEffect(showContent ? 1.0 : 0.95)
                        .opacity(showContent ? 1.0 : 0.0)
                        .gesture(dragGesture)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.95)).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
            }
        }
        .onAppear {
            withAnimation(.smoothSpring) {
                showContent = true
            }
        }
    }
    
    private var bottomSheetContent: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(theme.textTertiary)
                .frame(width: 40, height: 6)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            // Header
            headerSection
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    customTimeSection
                    actionButtons
                }
                .padding(20)
                .padding(.bottom, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.surface)
                .shadow(color: theme.shadow, radius: 20, x: 0, y: -5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom Reminder")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.text)
                    
                    Text("Set a specific date and time")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(theme.surfaceSecondary)
                        )
                }
                .animatedButton()
            }
            
            Divider()
                .background(theme.surfaceSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    private var customTimeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.accent)
                
                Text("Select Date & Time")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.text)
                
                Spacer()
            }
            
            // Combined date and time picker
            DatePicker("Reminder Date & Time", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .foregroundColor(theme.text)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface)
                        .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                )
                .onChange(of: selectedDate) { _, newValue in
                    selectedTime = newValue
                }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Set Reminder Button
            Button(action: setReminder) {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Set Reminder")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(theme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.accentGradient)
                        .applyNeumorphicShadow(theme.neumorphicButtonStyle)
                )
            }
            .animatedButton(pressedScale: 0.97)
            .hapticFeedback(.medium)
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragState) { drag, state, _ in
                state = .dragging(translation: drag.translation)
            }
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = min(value.translation.height * 0.8, 200)
                }
            }
            .onEnded { value in
                withAnimation(.smoothSpring) {
                    if value.translation.height > 100 || value.predictedEndTranslation.height > 200 {
                        dismiss()
                    } else {
                        dragOffset = 0
                    }
                }
            }
    }
    
    private func setReminder() {
        reminderDate = selectedDate
        hasReminder = true
        HapticManager.shared.taskAdded()
        dismiss()
    }
    
    private func removeReminder() {
        hasReminder = false
        HapticManager.shared.taskDeleted()
        dismiss()
    }
    

    
    private func dismiss() {
        withAnimation(.smoothSpring) {
            showContent = false
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