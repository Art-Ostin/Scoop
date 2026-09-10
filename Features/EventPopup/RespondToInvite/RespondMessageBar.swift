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

    //Local view state
    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1 //The field scaled with the body style before it wore a size: keep that, and lay the note out at the same scale
    @State private var textWidth: CGFloat = 0 //The field's line width — what the shrink lays the note out against
    
    private var textLimit: Int { 130 }

    private static let baseSize: CGFloat = 17 //`preferredFont(.body)`: what the field wore bare, and what the compose note wears
    private static let floorSize: CGFloat = (baseSize * TextShrink.floor).rounded() //12: the house shrink floor; below it the line limit scrolls instead, and 130 characters of SF never get there
    private static let maxLines = 3
    private static let lineSpacing: CGFloat = 2.5
    private static let measureSlack: CGFloat = 12 //Geometry: UITextView's 5pt line-fragment padding a side, should the field keep it, plus a hair

    //Shrink-to-fit across three lines, the editable twin of `lineLimitAndShrink`: `minimumScaleFactor` never reaches a
    //vertical TextField's editing text, so the size is chosen here — the largest, base down to the floor, at which the
    //note holds within `maxLines` of the field's width. Laid out a step NARROW of the field (`measureSlack`), so a
    //boundary can only ever shrink a character early, never wrap a fourth line for the limit to scroll away; a trailing
    //return holds an empty line the layout can't see. Computed in the body, so the size lands in the keystroke's pass
    private var fittedSize: CGFloat {
        guard textWidth > 0, !text.isEmpty else { return Self.baseSize }
        let width = textWidth - Self.measureSlack
        let trailingReturn = text.hasSuffix("\n") ? 1 : 0
        for size in stride(from: Self.baseSize, through: Self.floorSize, by: -1) {
            let lines = text.lineMetrics(font: .field(size * typeScale), lineSpacing: Self.lineSpacing, width: width).count
            if lines + trailingReturn <= Self.maxLines { return size }
        }
        return Self.floorSize
    }

    ///The bar's inset above its glass. The respond card scrolls the bar to a gap measured from the glass,
    ///so it backs this out — one number, read from here, or the two drift apart
    static let fieldTopInset: CGFloat = 6
    ///…and below it: with the action row's own 4, the glass ↔ CTA gap. Done hangs `Spacing.xs` under this foot
    static let fieldBottomInset: CGFloat = 18

    //Typed under `.transition`: a wrapping line grows the card, and the shell re-centres, re-masks and re-pins a
    //LANDED card on that clock — bare, the top hops half the line and eases back (the landed-resize rule)
    private var animatedText: Binding<String> {
        Binding(get: { text }, set: { new in withAnimation(.transition) { text = new } })
    }
    
    var body: some View {
        chatTextField
            .frame(maxWidth: .infinity)
            .padding(.bottom, Self.fieldBottomInset)
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
            Text("Done") //ScoopButton's tinted path sets the white
                .font(.body(14, .bold))
                .padding(Spacing.sm)
                .padding(.horizontal, Spacing.xxs)
        }
        .blurPop(visible: isFocused.wrappedValue) //Hidden it also stops taking taps
        .alignmentGuide(.bottom) { $0[.top] - Spacing.xs } //Its top `Spacing.xs` under the bar's foot
        .eventZoomKeyboardClearance() //The lowest thing on the focused card: the shell raises it clear of the keyboard
    }
}

extension RespondToMessageBar {
    
    private var chatTextField: some View {
        TextField("Add a note...", text: animatedText, axis: .vertical)
            .font(.field(fittedSize * typeScale))
            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
            .getWidth($textWidth) //The line width the shrink lays out against: the field's own, before its padding
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)
            .lineSpacing(Self.lineSpacing)
            .lineLimit(1...Self.maxLines)
            .focused(isFocused)
            .onChange(of: text) { _, newValue in
                if newValue.count > textLimit {
                    withAnimation(.transition) { text = String(newValue.prefix(textLimit)) } //Same clock: it may drop a line
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
