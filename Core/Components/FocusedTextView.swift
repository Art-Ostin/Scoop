//
//  FocusedTextView.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct FocusedTextView: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont
    var lineSpacing: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.backgroundColor = .clear
        tv.font = font
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        tv.text = text
        tv.isScrollEnabled = true
        tv.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.045) { //tiny delay so it appears at same rate as screen
            tv.alpha = 1
            tv.becomeFirstResponder()
        }
        applyParagraphStyle(to: tv)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.font != font {
            uiView.font = font
        }
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
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        init(text: Binding<String>) { _text = text }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}
