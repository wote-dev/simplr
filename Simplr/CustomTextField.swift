//
//  CustomTextField.swift
//  Simplr
//
//  Created by Daniel Zverev on 11/7/2024.
//

import SwiftUI
import UIKit

struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isFirstResponder: Bool = false
    var isMultiline: Bool = false
    var onCommit: (() -> Void)?

    func makeUIView(context: Context) -> UIView {
        if isMultiline {
            let textView = UITextView()
            textView.delegate = context.coordinator
            textView.font = .preferredFont(forTextStyle: .body)
            textView.isScrollEnabled = true
            textView.isEditable = true
            textView.isUserInteractionEnabled = true
            textView.backgroundColor = .clear // Set background to clear
            textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            // Set placeholder
            let placeholderLabel = UILabel()
            placeholderLabel.text = placeholder
            placeholderLabel.font = .preferredFont(forTextStyle: .body)
            placeholderLabel.textColor = .placeholderText
            placeholderLabel.sizeToFit()
            textView.addSubview(placeholderLabel)
            placeholderLabel.frame.origin = CGPoint(x: 5, y: (textView.font?.pointSize ?? 17) / 2)
            placeholderLabel.isHidden = !textView.text.isEmpty
            context.coordinator.placeholderLabel = placeholderLabel
            return textView
        } else {
            let textField = UITextField(frame: .zero)
            textField.delegate = context.coordinator
            textField.placeholder = placeholder
            textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return textField
        }
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let textView = uiView as? UITextView {
            textView.text = text
            context.coordinator.placeholderLabel?.isHidden = !text.isEmpty
            if isFirstResponder && !textView.isFirstResponder {
                textView.becomeFirstResponder()
            }
        } else if let textField = uiView as? UITextField {
            textField.text = text
            if isFirstResponder && !textField.isFirstResponder {
                textField.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate, UITextViewDelegate {
        var parent: CustomTextField
        var placeholderLabel: UILabel?

        init(_ textField: CustomTextField) {
            self.parent = textField
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            if let onCommit = parent.onCommit {
                onCommit()
            } else {
                textField.resignFirstResponder()
            }
            return true
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            placeholderLabel?.isHidden = !textView.text.isEmpty
        }
    }
}

struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    var isFirstResponder: Bool = false

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextEditor

        init(_ textView: CustomTextEditor) {
            self.parent = textView
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}