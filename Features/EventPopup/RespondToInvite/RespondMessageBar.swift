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
    let thread: [PastEventProposal] //The retired rounds and the live proposal, oldest first
    let hasPreviousMessages: Bool
    let userId: String
    let otherUserId: String
    var isFocused: FocusState<Bool>.Binding
    var isOpen = false //The focus as the note's MOTION reads it: the card's ride, flipped in one transaction a beat behind the raw focus (the container's `rideNote`). Never flip it bare: a landed card snaps a bare resize
    var namesNote = false //The placeholder reads as the note's own: flipped with the card's title, behind the keyboard's settle
    var onDone: () -> Void = {} //Done's tap: the container closes the ride, then resigns the field (its `closeNote`) — never a bare resign from here
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo? //The zoom the card stands in: how wide the focused card will be

    //Local view state
    @State private var noteHeight: CGFloat = 0
    @State private var holdHeight: CGFloat = 0
    @State private var hidden = EdgeOverflow()
    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var showsDone = false //Done pops in as the ride arrives, not as it leaves (see `doneLag`)

    //Open, the field stands at its `visibleLines` height from the first line, rather than growing into it: part of the ride
    private var isFixedHeight: Bool { isOpen }

    //The text's column as the OPEN card lays it out, held from the start: the card widens on a ride, and a text view
    //whose width rides with it is re-typeset on every frame — a sixth of the ride's main thread, with the hold probe's
    //(profile, 2026-09-17). Wider than the resting glass by the card's gap a side, which nothing shows: at rest the field
    //is empty (a written note rests as its bubble) and its placeholder is a line. nil outside a zoom: the glass's own width
    private var columnWidth: CGFloat? {
        guard let width = flight?.keyboardCardWidth, width > 0 else { return nil }
        return max(width - 2 * Spacing.lg - 2 * Self.fieldSideInset, 0)
    }

    private static let font: Font = .body(17, .regularItalic)
    private static let lineSpacing: CGFloat = 2.5
    private static let visibleLines = 4
    private static let holdProbe = Array(repeating: "x", count: visibleLines).joined(separator: "\n")
    private static let holdProbeWidth: CGFloat = 100 //Geometry: room for the probe's one-letter lines, no more
    private static let textLimit = 130
    private static let countWarning = 25
    private static let fieldBottomInset: CGFloat = 18 //Geometry: with the action row's own 4, the glass ↔ CTA gap
    private static let fieldSideInset: CGFloat = Spacing.md //The glass ↔ its text, each side

    //The note's height in lines: its share of the `visibleLines` the field holds at
    private var lineCount: Int {
        holdHeight > 0 ? Int((noteHeight / holdHeight * CGFloat(Self.visibleLines)).rounded()) : 1
    }
    private var overflows: Bool { lineCount > Self.visibleLines }
    private var verticalPad: CGFloat { lineCount > 1 || isFixedHeight ? Spacing.xs : Spacing.sm }
    private var fieldHeight: CGFloat { (overflows || isFixedHeight ? holdHeight : noteHeight) + verticalPad * 2 }

    //Focused, the note scrolls to reveal what sits above it: all of that scroll lives in RespondNoteReveal
    var body: some View {
        RespondNoteReveal(
            thread: thread,
            userId: userId,
            otherUserId: otherUserId,
            isFocused: isFocused,
            isOpen: isOpen,
            text: text,
            restHeight: fieldHeight + Self.fieldBottomInset,
            noteFootInset: Self.fieldBottomInset) {
                noteField
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Self.fieldBottomInset)
            } pinned: {
                doneSlot
            }
            .eventZoomKeyboardAccessory(Self.doneTitle, visible: showsDone) { onDone() } //Done itself: the zoom draws it on the keyboard's line
            .onChange(of: isOpen) { _, open in
                if !open { showsDone = false } //Out with the resign itself
            }
            .task(id: isOpen) {
                guard isOpen else { return }
                try? await Task.sleep(for: Self.doneLag)
                if !Task.isCancelled { showsDone = true }
            }
    }
}

//The note: grows a line at a time to `visibleLines`, then holds and scrolls to the line being typed
extension RespondToMessageBar {

    //The placeholder's words: the thread's over past proposals, the note's own once it stands at full height to be written
    private var placeholderText: String {
        hasPreviousMessages && !namesNote ? "Message Thread..." : "Add a note..."
    }

    private var noteField: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                if text.isEmpty { placeholder } //In the layout, as the field's own was: an empty note is as tall as its words
                TextField("", text: $text, axis: .vertical)
                    .font(Self.font)
                    .lineSpacing(Self.lineSpacing)
                    .focused(isFocused)
                    .accessibilityLabel(placeholderText)
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                withAnimation(.transition) { noteHeight = height } //Every write resizes a landed card
            }
            .frame(width: columnWidth, alignment: .leading)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) //Takes what the glass offers (a min too, or a wider column would size it): the column hangs off the leading inset and overhangs the trailing one
            .padding(.horizontal, Self.fieldSideInset)
            .padding(.vertical, verticalPad)
        }
        .scrollPosition($scrollPosition)
        .defaultScrollAnchor(.bottom, for: .initialOffset)
        .scrollDisabled(!overflows || !isFocused.wrappedValue) //Only while focused, where the shell holds the card's drag
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.never) //Declared here, not inherited from the reveal scroll
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

    //The placeholder, drawn in the field's place so a change of words blur-replaces: the field's own only snaps to a new string
    private var placeholder: some View {
        ZStack(alignment: .topLeading) {
            Text(placeholderText)
                .id(placeholderText)
                .transition(.blurReplace)
        }
        .font(Self.font)
        .lineSpacing(Self.lineSpacing)
        .foregroundStyle(Color.textPlaceholder)
        .animation(.transition, value: placeholderText) //Outside the .id: a rebuilt animation has no old value to diff
        .allowsHitTesting(false)
        .accessibilityHidden(true) //The field carries the words as its label
    }

    //The same field at `visibleLines`: the height the note holds at, measured
    private var holdTwin: some View {
        TextField("", text: .constant(Self.holdProbe), axis: .vertical)
            .font(Self.font)
            .lineSpacing(Self.lineSpacing)
            .frame(width: Self.holdProbeWidth) //Its lines never wrap, so its height is any width's — and a fixed one is typeset once, not on every frame the glass resizes
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

    private static let doneTitle = "Done"

    //Done stands on the KEYBOARD's line, so the zoom draws it there, in its own plane (`.eventZoomKeyboardAccessory`):
    //hung in the card it rode the whole ride while it popped in, a control flying up from under the keyboard. Held until
    //the ride has all but arrived (the keyboard's spring is ~85% home), it appears where it will stand, as the card lands
    private static let doneLag: Duration = .milliseconds(120)

    //Where Done would hang in the card — under the note's resting foot, never scrolled — kept as the zoom's clearance
    //slot: the lowest thing on the focused card, which the shell lifts clear of the keyboard under a long note
    private var doneSlot: some View {
        EventKeyboardAccessoryLabel(title: Self.doneTitle)
            .hidden()
            .eventZoomKeyboardClearance()
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
