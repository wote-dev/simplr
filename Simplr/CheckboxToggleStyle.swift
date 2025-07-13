//
//  CheckboxToggleStyle.swift
//  Simplr
//
//  Created by Daniel Zverev on 11/7/2024.
//

import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    @Environment(\.theme) var theme

    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? theme.accent : theme.textSecondary)
                configuration.label
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}