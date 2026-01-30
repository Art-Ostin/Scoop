//
//  FocusedTextView.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI
import UIKit


//AI Code here
struct FocusedTextView: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont
    var lineSpacing: CGFloat
    var placeholderLineSpacing: CGFloat? = nil
    var maxLength: Int? = nil
    var placeholder: String? = nil
    var placeholderColor: UIColor = .placeholderText
    
    
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.backgroundColor = .clear
        tv.font = font
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        tv.textContainer.lineBreakMode = .byWordWrapping
        tv.textContainer.widthTracksTextView = true
        tv.text = text
        tv.isScrollEnabled = true
        tv.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.062) { // makes it appear at same rate as screen. 
            tv.alpha = 1
            tv.becomeFirstResponder()
        }
        applyParagraphStyle(to: tv)
        context.coordinator.configurePlaceholderLabel(
            in: tv,
            placeholder: placeholder,
            font: font,
            color: placeholderColor,
            lineSpacing: placeholderLineSpacing ?? lineSpacing
        )
        context.coordinator.updatePlaceholderVisibility(for: tv, placeholder: placeholder)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.font != font {
            uiView.font = font
        }
        context.coordinator.configurePlaceholderLabel(
            in: uiView,
            placeholder: placeholder,
            font: font,
            color: placeholderColor,
            lineSpacing: placeholderLineSpacing ?? lineSpacing
        )
        context.coordinator.updatePlaceholderVisibility(for: uiView, placeholder: placeholder)
        applyParagraphStyle(to: uiView)
    }

    private func applyParagraphStyle(to textView: UITextView) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing

        let attributed = NSAttributedString(
            string: textView.text ?? "",
            attributes: [
                .font: font,
                .paragraphStyle: paragraph
            ]
        )
        textView.attributedText = attributed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, maxLength: maxLength)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        private var placeholderLabel: UILabel?
        private var placeholderWidthConstraint: NSLayoutConstraint?
        private let maxLength: Int?

        init(text: Binding<String>, maxLength: Int?) {
            _text = text
            self.maxLength = maxLength
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText replacement: String
        ) -> Bool {
            guard let maxLength else { return true }
            let currentText = textView.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: replacement)

            if updatedText.count <= maxLength {
                return true
            }

            let limitedText = String(updatedText.prefix(maxLength))
            textView.text = limitedText
            text = limitedText
            updatePlaceholderVisibility(for: textView, placeholder: placeholderLabel?.text)
            return false
        }

        func textViewDidChange(_ textView: UITextView) {
            if let maxLength, textView.text.count > maxLength {
                let limitedText = String(textView.text.prefix(maxLength))
                textView.text = limitedText
                text = limitedText
            } else {
                text = textView.text
            }
            updatePlaceholderVisibility(for: textView, placeholder: placeholderLabel?.text)
        }

        func configurePlaceholderLabel(
            in textView: UITextView,
            placeholder: String?,
            font: UIFont,
            color: UIColor,
            lineSpacing: CGFloat
        ) {
            guard let placeholder else {
                placeholderLabel?.removeFromSuperview()
                placeholderLabel = nil
                return
            }

            let label = placeholderLabel ?? UILabel()
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = lineSpacing
            label.attributedText = NSAttributedString(
                string: placeholder,
                attributes: [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
            )
            label.text = placeholder
            label.textColor = color
            label.font = font
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.translatesAutoresizingMaskIntoConstraints = false

            if placeholderLabel == nil {
                textView.addSubview(label)
                let widthConstraint = label.widthAnchor.constraint(
                        equalTo: textView.widthAnchor,
                        constant: -(textView.textContainerInset.left
                                    + textView.textContainerInset.right
                                    + textView.textContainer.lineFragmentPadding * 2)
                    )
                placeholderWidthConstraint = widthConstraint
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(
                        equalTo: textView.topAnchor,
                        constant: textView.textContainerInset.top
                    ),
                    label.leadingAnchor.constraint(
                        equalTo: textView.leadingAnchor,
                        constant: textView.textContainerInset.left + textView.textContainer.lineFragmentPadding
                    ),
                    widthConstraint
                ])
                placeholderLabel = label
            }
        }

        func updatePlaceholderVisibility(for textView: UITextView, placeholder: String?) {
            guard let placeholderLabel else { return }
            let hasText = !(textView.text ?? "").isEmpty
            placeholderLabel.isHidden = hasText || placeholder?.isEmpty == true
        }
    }
}

