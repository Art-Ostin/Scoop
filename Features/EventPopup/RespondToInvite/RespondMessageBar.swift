//
//  RespondMessageBar.swift
//  Scoop
//
//  Created by Art Ostin on 10/09/2026.
//

import SwiftUI

struct RespondToMessageBar: View {

    //Injected
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    //Local view state
    @State private var noteHeight: CGFloat = 0
    @State private var holdHeight: CGFloat = 0
    @State private var hidden = EdgeOverflow()
    @State private var scrollPosition = ScrollPosition(edge: .top)

    private static let font: Font = .body(17, .regularItalic)
    private static let lineSpacing: CGFloat = 2.5
    private static let visibleLines = 4
    private static let holdProbe = Array(repeating: "x", count: visibleLines).joined(separator: "\n")
    private static let textLimit = 130
    private static let countWarning = 25

    //The bar's inset above its glass: the respond card's focus lift reads it
    static let fieldTopInset: CGFloat = 6
    //…and below: with the action row's own 4, the glass ↔ CTA gap
    static let fieldBottomInset: CGFloat = 18

    //The note's height in lines: its share of the `visibleLines` the field holds at
    private var lineCount: Int {
        holdHeight > 0 ? Int((noteHeight / holdHeight * CGFloat(Self.visibleLines)).rounded()) : 1
    }
    private var overflows: Bool { lineCount > Self.visibleLines }
    private var verticalPad: CGFloat { lineCount > 1 ? Spacing.xs : Spacing.sm }
    private var fieldHeight: CGFloat { (overflows ? holdHeight : noteHeight) + verticalPad * 2 }

    var body: some View {
        noteField
            .frame(maxWidth: .infinity)
            .padding(.bottom, Self.fieldBottomInset)
//            .padding(.top, Self.fieldTopInset)
            .overlay(alignment: .bottomTrailing) { doneButton }
            .padding(.horizontal, Spacing.lg)
    }
}

//The note: grows a line at a time to `visibleLines`, then holds and scrolls to the line being typed
extension RespondToMessageBar {

    private var noteField: some View {
        ScrollView {
            TextField("Add a note...", text: $text, axis: .vertical)
                .font(Self.font)
                .lineSpacing(Self.lineSpacing)
                .focused(isFocused)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    withAnimation(.transition) { noteHeight = height } //Every write resizes a landed card
                }
                .padding(.horizontal)
                .padding(.vertical, verticalPad)
        }
        .scrollPosition($scrollPosition)
        .defaultScrollAnchor(.bottom, for: .initialOffset)
        .scrollDisabled(!overflows || !isFocused.wrappedValue) //Only while focused, where the shell holds the card's drag
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: EdgeOverflow.self, of: { EdgeOverflow($0) }) { hidden = $1 }
        .frame(height: fieldHeight)
        .mask { edgeFadeMask }
        .background { holdTwin }
        .onChange(of: text) { old, new in
            if new.count > Self.textLimit { text = String(new.prefix(Self.textLimit)) }
            if new.hasPrefix(old) || old.hasPrefix(new) { revealLastLine() } //An edit at the tail
        }
        .onChange(of: lineCount) { _, _ in revealLastLine() }
        .overlay(alignment: .bottomTrailing) { countRemainingText }
        .glassEffectIfAvailable(interactive: true, shape: RoundedRectangle(cornerRadius: CornerRadius.xl))
        .contentShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .onTapGesture { isFocused.wrappedValue = true }
    }

    //The caret lives on the last line: a wrap, or typing at the tail after a scroll up, brings it back
    private func revealLastLine() {
        guard overflows else { return }
        withAnimation(.move) { scrollPosition.scrollTo(y: noteHeight - holdHeight) }
    }

    //The same field at `visibleLines`: the height the note holds at, measured
    private var holdTwin: some View {
        TextField("", text: .constant(Self.holdProbe), axis: .vertical)
            .font(Self.font)
            .lineSpacing(Self.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .getHeight($holdHeight)
            .hidden()
    }

    //In scroll mode each edge fades across its padding, as deep as the note has scrolled past it
    private var edgeFadeMask: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: fadeDepth(hidden.above))
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: fadeDepth(hidden.below))
        }
    }

    private func fadeDepth(_ overflow: CGFloat) -> CGFloat {
        overflows ? min(overflow, verticalPad) : 0
    }

    @ViewBuilder
    private var countRemainingText: some View {
        let remaining = max(0, Self.textLimit - text.count)
        if remaining <= Self.countWarning {
            Text("\(remaining)")
                .font(.body(14))
                .foregroundStyle(Color.warningYellow)
                .padding(.trailing, Spacing.sm)
                .padding(.bottom, Spacing.sm)
        }
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
                .padding(Spacing.sm)
                .padding(.horizontal, Spacing.xxs)
        }
        .blurPop(visible: isFocused.wrappedValue)
        .alignmentGuide(.bottom) { $0[.top] - Spacing.xs } //Hangs `Spacing.xs` under the bar's foot
        .eventZoomKeyboardClearance() //The lowest thing on the focused card: the shell raises it clear of the keyboard
    }
}

//How much note lies past each edge of the scroll, in points
private struct EdgeOverflow: Equatable {
    var above: CGFloat = 0
    var below: CGFloat = 0

    init() {}
    init(_ geometry: ScrollGeometry) {
        above = max(0, geometry.visibleRect.minY)
        below = max(0, geometry.contentSize.height - geometry.visibleRect.maxY)
    }
}
