//
//  CustomTextField.swift
//  Scoop
//
//  Created by Art Ostin on 21/07/2026.
//

import SwiftUI

struct UnderlinedTextField: View {

    //Injected
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack {
            TextField(placeholder, text: $text)
                .frame(maxWidth: .infinity)
                .font(.body(24, .medium))
                .autocorrectionDisabled(true)
                .tint(.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Capsule()
                .frame(maxWidth: .infinity)
                .frame(height: 1) //Geometry: hairline rule under the text column
                .foregroundStyle(Color.textPlaceholder)
        }
    }
}

struct MessageComposerField: View {

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
            allowsNewlines: false, //A note is one paragraph: Return reads Done
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

//A stored `String?` read as a field's `String`. Labelled `unwrapping:` on purpose: SwiftUI already
//ships an unlabelled `Binding.init?(_:)` for optionals, which FAILS to nil rather than substituting,
//and an unlabelled twin here would be ambiguous with it at every call site.
extension Binding where Value == String {
    /// - Parameter empty: what a nil reads as, and the value that writes back as nil. A field the user
    ///   never filled in and one they cleared then both persist as nil, never as "".
    init(unwrapping source: Binding<String?>, empty: String = "") {
        self.init(get: { source.wrappedValue ?? empty },
                  set: { source.wrappedValue = $0 == empty ? nil : $0 })
    }
}

//Text kept to one paragraph (a note, a prompt answer): where a line break would have split it, one space
extension String {
    var withoutLineBreaks: String {
        split(whereSeparator: \.isNewline).joined(separator: " ") //A run of breaks is one gap; those at either end go
    }
}
