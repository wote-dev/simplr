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
            textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
            textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return textField
        }
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let textView = uiView as? UITextView {
            if text != textView.text {
                textView.text = text
                context.coordinator.internalText = text
            }
            context.coordinator.placeholderLabel?.isHidden = !text.isEmpty
            if isFirstResponder && !textView.isFirstResponder {
                textView.becomeFirstResponder()
            }
        } else if let textField = uiView as? UITextField {
            if text != textField.text {
                textField.text = text
                context.coordinator.internalText = text
            }
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
        var internalText: String

        init(_ textField: CustomTextField) {
            self.parent = textField
            self.internalText = textField.text
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            let newText = textField.text ?? ""
            if newText != internalText {
                internalText = newText
                parent.text = newText
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            parent.onCommit?()
            return true
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            let newText = textField.text ?? ""
            if newText != internalText {
                internalText = newText
                parent.text = newText
            }
            parent.onCommit?()
        }

        func textViewDidChange(_ textView: UITextView) {
            let newText = textView.text ?? ""
            if newText != internalText {
                internalText = newText
                parent.text = newText
                placeholderLabel?.isHidden = !newText.isEmpty
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.onCommit?()
        }
    }
}