//
//  CustomTextField.swift
//  Scoop Test
//
//  Created by Art Ostin on 21/07/2026.
//

import SwiftUI

struct CustomTextField: View {

    @Binding var text: String?
    @Binding var isFocused: Bool

    let placeHolder: String
    var isEventMessage: Bool = true

    private var textLimit: Int {
        130 + (isEventMessage ? 5 : 0) //Extra 10 if is EventMessage
    }

    var body: some View {
        InstantKeyboardField(
            text: $text,
            textLimit: textLimit,
            placeholder: placeHolder,
            scrollEnabledAfterLineCount: 4,
            isFocused: $isFocused
        )
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .frame(height: 148)
            .customScrollFade(height: Spacing.lg, color: .white, edge: .top)
            .customScrollFade(height: Spacing.lg, color: .white, edge: .bottom)
            .clipShape(.rect(cornerRadius: CornerRadius.xl))
            .stroke(CornerRadius.xl, color: Color.border)
            .overlay(alignment: .bottomTrailing) {countRemainingText}
    }

    @ViewBuilder
    private var countRemainingText: some View {
        let warningThreshold = 25
        let remaining = max(0, textLimit - (text ?? "").count)
        if remaining <= warningThreshold {
            Text("\(remaining)")
                .font(.body(14))
                .foregroundStyle(Color.warningYellow)
                .padding(.trailing, Spacing.sm)
                .padding(.bottom, Spacing.sm)
        }
    }
}
