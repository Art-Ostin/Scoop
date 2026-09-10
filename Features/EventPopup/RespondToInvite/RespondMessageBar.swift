//
//  RespondMessageBar.swift
//  Scoop
//
//  Created by Art Ostin on 10/09/2026.
//

import SwiftUI

struct RespondToMessageBar: View {
    
    @Binding var text: String
    
    var isFocused: FocusState<Bool>.Binding
    
    private var textLimit: Int { 130 }

    ///The bar's inset above its glass. The respond card scrolls the bar to a gap measured from the glass,
    ///so it backs this out — one number, read from here, or the two drift apart
    static let fieldTopInset: CGFloat = 6
    
    var body: some View {
        chatTextField
            .frame(maxWidth: .infinity)
            .padding(.bottom, 18)
            .padding(.top, Self.fieldTopInset)
            //Hung below the bar's foot, outside its layout: the card's height never moves for it
            .overlay(alignment: .bottomTrailing) { doneButton }
            .padding(.horizontal, Spacing.lg)
    }
}

//Done: the focused note's only control, in and out on the blur pop
extension RespondToMessageBar {

    private var doneButton: some View {
        ScoopButton(style: .tinted(.black, shadow: nil, glass: true), shape: Capsule()) {
            isFocused.wrappedValue = false
        } label: {
            Text("Done")
                .font(.body(14, .bold))
                .foregroundStyle(Color.white)
                .padding(Spacing.sm)
                .padding(.horizontal, Spacing.xxs)
        }
        .blurPop(visible: isFocused.wrappedValue) //Hidden it also stops taking taps
        .alignmentGuide(.bottom) { $0[.top] - Spacing.xs } //Its top `Spacing.xs` under the bar's foot
    }
}

extension RespondToMessageBar {
    
    private var chatTextField: some View {
        TextField("Add a note...", text: $text, axis: .vertical)
            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)
            .lineSpacing(2.5)
            .lineLimit(1...4)
            .focused(isFocused)
            .onChange(of: text) { _, newValue in
                if newValue.count > textLimit {
                    text = String(newValue.prefix(textLimit))
                }
            }
            .overlay(alignment: .bottomTrailing) { countRemainingText }
            .glassEffectIfAvailable(interactive: true, shape: RoundedRectangle(cornerRadius: CornerRadius.xl))
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
            .onTapGesture { isFocused.wrappedValue = true }
    }
    
    @ViewBuilder
     private var countRemainingText: some View {
         let remaining = max(0, textLimit - text.count)
         if remaining <= 25 {
             Text("\(remaining)")
                 .font(.body(14))
                 .foregroundStyle(Color.warningYellow)
                 .padding(.trailing, Spacing.sm)
                 .padding(.bottom, Spacing.sm)
         }
     }
}
