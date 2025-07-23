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
    var allowsTextSelection: Bool = true
    
    @Environment(\.theme) private var theme

    func makeUIView(context: Context) -> UIView {
        if isMultiline {
            let containerView = UIView()
            let textView = UITextView()
            textView.delegate = context.coordinator
            textView.font = .preferredFont(forTextStyle: .body)
            textView.isScrollEnabled = true
            textView.isEditable = true
            textView.isUserInteractionEnabled = true
            textView.backgroundColor = .clear
            textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            
            // Enhanced text selection configuration
            textView.isSelectable = allowsTextSelection
            textView.dataDetectorTypes = []
            textView.textDragInteraction?.isEnabled = allowsTextSelection
            textView.textContainer.lineFragmentPadding = 0
            
            // Add border styling
            textView.layer.borderWidth = 1.0
            textView.layer.borderColor = UIColor(theme.border).cgColor
            textView.layer.cornerRadius = 8.0
            textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
            
            // Set placeholder
            let placeholderLabel = UILabel()
            placeholderLabel.text = placeholder
            placeholderLabel.font = .preferredFont(forTextStyle: .body)
            placeholderLabel.textColor = .placeholderText
            placeholderLabel.sizeToFit()
            textView.addSubview(placeholderLabel)
            placeholderLabel.frame.origin = CGPoint(x: 13, y: 12 + (textView.font?.pointSize ?? 17) / 4)
            placeholderLabel.isHidden = !textView.text.isEmpty
            context.coordinator.placeholderLabel = placeholderLabel
            context.coordinator.currentInputView = textView
            
            containerView.addSubview(textView)
            textView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalTo: containerView.topAnchor),
                textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            return containerView
        } else {
            let containerView = UIView()
            let textField = UITextField(frame: .zero)
            textField.delegate = context.coordinator
            textField.placeholder = placeholder
            textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
            textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            
            // Enhanced text selection configuration
            textField.isUserInteractionEnabled = true
            // Enable text selection and editing capabilities
            textField.isEnabled = true
            // Text field inherently supports becoming first responder when enabled
            
            // Add border styling
            textField.layer.borderWidth = 1.0
            textField.layer.borderColor = UIColor(theme.border).cgColor
            textField.layer.cornerRadius = 8.0
            textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: textField.frame.height))
            textField.leftViewMode = .always
            textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: textField.frame.height))
            textField.rightViewMode = .always
            
            context.coordinator.currentInputView = textField
            containerView.addSubview(textField)
            textField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textField.topAnchor.constraint(equalTo: containerView.topAnchor),
                textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            return containerView
        }
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Find the actual text input view within the container
        if let textView = uiView.subviews.first(where: { $0 is UITextView }) as? UITextView {
            if text != textView.text {
                textView.text = text
                context.coordinator.internalText = text
            }
            context.coordinator.placeholderLabel?.isHidden = !text.isEmpty
            if isFirstResponder && !textView.isFirstResponder {
                textView.becomeFirstResponder()
            }
            // Update border color for theme changes
            textView.layer.borderColor = UIColor(theme.border).cgColor
        } else if let textField = uiView.subviews.first(where: { $0 is UITextField }) as? UITextField {
            if text != textField.text {
                textField.text = text
                context.coordinator.internalText = text
            }
            if isFirstResponder && !textField.isFirstResponder {
                textField.becomeFirstResponder()
            }
            // Update border color for theme changes
            textField.layer.borderColor = UIColor(theme.border).cgColor
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate, UITextViewDelegate {
        var parent: CustomTextField
        var placeholderLabel: UILabel?
        var internalText: String
        var currentInputView: UIView?
        private var isTextSelectionActive = false

        init(_ textField: CustomTextField) {
            self.parent = textField
            self.internalText = textField.text
        }
        
        private func updateBorderForFocusState(_ inputView: UIView, isFocused: Bool) {
            let borderColor = isFocused ? UIColor(parent.theme.accent) : UIColor(parent.theme.border)
            let borderWidth: CGFloat = isFocused ? 2.0 : 1.0
            
            inputView.layer.borderColor = borderColor.cgColor
            inputView.layer.borderWidth = borderWidth
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            let newText = textField.text ?? ""
            if newText != internalText {
                internalText = newText
                parent.text = newText
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            // Smooth keyboard dismissal with gentle spring animation
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]) {
                textField.resignFirstResponder()
            } completion: { _ in
                self.parent.onCommit?()
            }
            return true
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            currentInputView = textField
            updateBorderForFocusState(textField, isFocused: true)
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            let newText = textField.text ?? ""
            if newText != internalText {
                internalText = newText
                parent.text = newText
            }
            updateBorderForFocusState(textField, isFocused: false)
            parent.onCommit?()
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            currentInputView = textView
            updateBorderForFocusState(textView, isFocused: true)
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
            updateBorderForFocusState(textView, isFocused: false)
            isTextSelectionActive = false
            parent.onCommit?()
        }
        
        // Handle return key for multiline text views
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Check if return key was pressed
            if text == "\n" {
                // For single-line behavior, dismiss keyboard smoothly with gentle animation
                UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]) {
                    textView.resignFirstResponder()
                } completion: { _ in
                    self.parent.onCommit?()
                }
                return false // Prevent the newline from being added
            }
            return true
        }
        
        // MARK: - Enhanced Text Selection Support
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            // Track when text selection is active to prevent gesture interference
            let hasSelection = textView.selectedRange.length > 0
            isTextSelectionActive = hasSelection
        }
        
        // MARK: - Modern Text Interaction Support (iOS 17+)
        
        @available(iOS 17.0, *)
        func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
            // Return nil to use default behavior when text selection is allowed
            return parent.allowsTextSelection ? nil : UITextItem.MenuConfiguration(menu: UIMenu(children: []))
        }
        
        // Fallback for iOS 16 and earlier
        @available(iOS, deprecated: 17.0, message: "Use textView(_:menuConfigurationFor:defaultMenu:) instead")
        func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            return parent.allowsTextSelection
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            // Track when text selection is active for UITextField
            if let selectedRange = textField.selectedTextRange {
                let hasSelection = !selectedRange.isEmpty
                isTextSelectionActive = hasSelection
            }
        }
    }
}