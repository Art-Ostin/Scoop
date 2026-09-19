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
    var onDone: () -> Void = {} //Done's tap, and the Return key's: the container closes the ride, then resigns the field (its `closeNote`) — never a bare resign from here
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo? //The zoom the card stands in: how wide the focused card will be, and how wide it rests

    //Local view state
    @State private var noteHeight: CGFloat = 0
    @State private var rowWidth: CGFloat = 0 //The note's row as laid out, read only with no zoom around it (see `bubbleColumn`)
    @State private var labelHeight: CGFloat = 0 //The bubble's label as laid out, whichever pose the note is in: what the resting bubble's slot is cut to (see `bubbleRestHeight`)
    @State private var holdHeight: CGFloat = 0
    @State private var hidden = EdgeOverflow()
    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var showsDone = false //Done pops in as the ride arrives, not as it leaves (see `doneLag`)

    //Open, the field stands at its `visibleLines` height from the first line, rather than growing into it: part of the ride
    private var isFixedHeight: Bool { isOpen }

    //A written note rests as a bubble, and the bubble IS this field: one surface in two poses (`noteSurface`). The pose
    //flips with `isOpen`, so inside the ride's own transaction: the morph between them is the ride — it leaves with the
    //card and lands with it, on the keyboard's spring. They used to be two views swapped once the ride was home: the note
    //landed as a full-width field, waited, then cut to a bubble at the other side of the card (device, 2026-09-18). An
    //empty note never takes the pose, so its ride is the one it always had
    private var restsAsBubble: Bool { !isOpen && !text.isEmpty }

    //The text's column as the OPEN card lays it out, held from the start: the card widens on a ride, and a text view
    //whose width rides with it is re-typeset on every frame — a sixth of the ride's main thread, with the hold probe's
    //(profile, 2026-09-17). Wider than the resting glass by the card's gap a side, which nothing shows: at rest an empty
    //field's placeholder is a line, and a written one's face is hidden under its bubble's. nil outside a zoom: the glass's own width
    private var columnWidth: CGFloat? {
        guard let width = flight?.keyboardCardWidth, width > 0 else { return nil }
        return max(width - 2 * Spacing.lg - 2 * Self.fieldSideInset, 0)
    }

    //The widest a written note's bubble may rest: the RESTING card's column, inside the reveal's margins. From the zoom,
    //never a measure: the open card is wider, the bubble is laid out in the very commit the card starts home in, and a
    //width read under a card changing its gap comes back mid-spring on every frame of the ride. 0 = not known yet
    private var bubbleColumn: CGFloat {
        guard let flight else { return rowWidth } //No zoom around it: the row's own width, which nothing rides
        //A zoom's plane lays out a pass after the card mounts: until then, the column the last card rested in (a card
        //mounted over a written note was open before, in this session) — the slot is right from the first pass
        guard flight.restingCardWidth > 0 else { return Self.lastBubbleColumn }
        return max(flight.restingCardWidth - 2 * Spacing.lg, 0)
    }
    private static var lastBubbleColumn: CGFloat = 0

    private static let font: Font = .body(17, .regularItalic)
    private static let lineSpacing: CGFloat = 2.5
    private static let visibleLines = 4
    private static let holdProbe = Array(repeating: "x", count: visibleLines).joined(separator: "\n")
    private static let holdProbeWidth: CGFloat = 100 //Geometry: room for the probe's one-letter lines, no more
    private static let textLimit = 130
    private static let countWarning = 25
    private static let fieldBottomInset: CGFloat = 18 //Geometry: with the action row's own 4, the glass ↔ CTA gap
    private static let fieldSideInset: CGFloat = Spacing.md //The glass ↔ its text, each side
    private static let bubbleLift: CGFloat = 2 //Geometry: the resting bubble's body starts this far above the note's slot, under the rows — what evens its gap to the CTA with the rows' own
    private static let bubbleFootInset: CGFloat = BubbleMetrics.runGap + Spacing.xxs //Under the bubble's body: the run gap its tail hangs in, then the CTA's share
    private static let faceBlur: CGFloat = 4 //The bubble's face resolving over the field's: a line of type, not a block — the body swap's 6 smears it

    //The pose's two faces. The field's italic line and the bubble's upright one hang off the same leading inset, so the
    //text glides with the surface's leading edge while one face gives way to the other: the reveal's own swap — the
    //leaver dismissed at once, the arriver resolving a beat into the ride
    private static let faceOut: Animation = RespondNoteRevealSpec.threadOut
    private static let faceIn: Animation = RespondNoteRevealSpec.threadIn

    //The note's height in lines: its share of the `visibleLines` the field holds at
    private var lineCount: Int {
        holdHeight > 0 ? Int((noteHeight / holdHeight * CGFloat(Self.visibleLines)).rounded()) : 1
    }
    private var overflows: Bool { lineCount > Self.visibleLines }
    private var verticalPad: CGFloat { lineCount > 1 || isFixedHeight ? Spacing.xs : Spacing.sm }
    private var fieldHeight: CGFloat { (overflows || isFixedHeight ? holdHeight : noteHeight) + verticalPad * 2 }
    //How far below the glass's top the last line in view ends: the note's text, or its last `visibleLines` once it scrolls
    private var textDepth: CGFloat { verticalPad + min(noteHeight, holdHeight) }

    //The resting bubble's corner: Thread once messages sit above the note in the reveal, Edit while there are none
    private var noteBadge: MessageNoteBadge.Kind { hasPreviousMessages ? .thread : .edit }
    //What the bubble reads: the Return key's break lives a pass in `text` (`takeLineBreaks`), and a label that laid it
    //out would hand the close a slot a line too tall
    private var bubbleText: String { text.withoutLineBreaks }
    private var bubblePlacement: MessageBubbleView.BadgePlacement {
        MessageBubbleView.badgePlacement(text: bubbleText, maxBubbleWidth: bubbleColumn, badgeWidth: MessageNoteBadge.inlineWidth(for: noteBadge))
    }
    //The note's slot while it rests as its bubble: its label as SwiftUI lays it out, which the pose never changes (it
    //keeps its own column), so the height is known before any close and right in the very commit the pose flips in —
    //what the old bubble's own layout gave the card. Until its first reading, the chat's measure of it: exact for plain
    //type, but it counts every line at the face's height, and a line an emoji stands in is some 5pt taller — slotted by
    //the measure alone, an emoji note's bubble sinks into its gap over the CTA (two such lines, and the card's clip
    //takes its tail)
    private var bubbleRestHeight: CGFloat {
        let label = labelHeight > 0 ? labelHeight
            : MessageBubbleView.restingSize(text: bubbleText, maxBubbleWidth: bubbleColumn, placement: bubblePlacement).height
        return label + Self.bubbleFootInset
    }

    //Bare while the note is open (nothing shows it) and on a mount's first reading; resting as a bubble, on the ride's
    //own clock: what changed it is a field's late commit (see the body's transaction), a turn into a close
    private func measureLabel(_ height: CGFloat) {
        guard abs(height - labelHeight) > 0.5 else { return }
        withAnimation(restsAsBubble && labelHeight > 0 ? .keyboard : nil) { labelHeight = height }
    }

    //Focused, the note scrolls to reveal what sits above it: all of that scroll lives in RespondNoteReveal
    var body: some View {
        RespondNoteReveal(
            thread: thread,
            userId: userId,
            otherUserId: otherUserId,
            isFocused: isFocused,
            isOpen: isOpen,
            text: text,
            restHeight: restsAsBubble ? bubbleRestHeight : fieldHeight + Self.fieldBottomInset,
            noteFootInset: Self.fieldBottomInset,
            textDepth: textDepth) {
                noteSurface
                    .frame(maxWidth: .infinity, alignment: .trailing) //The bubble hugs its text on the sender's side; the field takes the column
                    //The row beside a resting bubble opens the note too, as it always did — and catches a tap on a closing
                    //field's leading half, which is still on screen after the pose (what is hit-tested) has left it. Behind
                    //the surface and outside its glass, so its switch is no flip inside a glass subtree
                    .background {
                        Color.clear.contentShape(Rectangle())
                            .onTapGesture { isFocused.wrappedValue = true }
                            .allowsHitTesting(restsAsBubble) //The field's own corners stay the card's: a tap there still closes an open note, as it did
                    }
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { if flight == nil { rowWidth = $0 } }
                    .padding(.bottom, restsAsBubble ? Self.bubbleFootInset : Self.fieldBottomInset)
            } pinned: {
                doneSlot
            }
            .padding(.top, restsAsBubble ? -Self.bubbleLift : 0)
            //A field commits what it was holding as it resigns (an autocorrection, a dictated tail): the text changes
            //bare, a turn into the close, and the bubble the surface is closing onto changes size with it. On the ride's
            //clock that is a retarget; bare, the leading edge would cut to its new place while everything else rode
            .transaction(value: text) { if !isOpen, $0.animation == nil { $0.animation = .keyboard } }
            .eventZoomKeyboardAccessory(Self.doneTitle, visible: showsDone) { onDone() } //Done itself: the zoom draws it on the keyboard's line
            .onChange(of: isOpen) { _, open in
                if !open { showsDone = false } //Out with the resign itself
                if open, overflows { scrollPosition.scrollTo(edge: .bottom) } //Reopened from its bubble the field is the one that was always mounted, its first lines in view: the caret is on the last
            }
            .onChange(of: bubbleColumn, initial: true) { _, column in
                if column > 0 { Self.lastBubbleColumn = column }
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

    //The note's one surface, in the pose it stands in: the glass field it is written in, or the bubble a written note
    //rests as. Both faces stay mounted — a face inserted mid-ride would be born at its destination, and a focus written
    //with no field mounted to take it is dropped — and the pose only re-lays the surface out: hugging the bubble's label
    //on the sender's side, or across the column at the field's height. So a close sweeps the glass's leading edge and its
    //foot in onto the text while the card rides home, and a press on the bubble swells it back out under the thread
    private var noteSurface: some View {
        let bubble = restsAsBubble
        //No hit-testing switch on either face: a face at opacity 0 takes no touches (hit-testing reads the model, so the
        //bubble is pressable from a close's first frame), and a switch flipped inside a glass subtree mid-animation stalls it
        return NotePoseLayout(restsAsBubble: bubble, fieldHeight: fieldHeight) {
            noteField
                .animation(bubble ? Self.faceOut : Self.faceIn) { $0.opacity(bubble ? 0 : 1) }
                .accessibilityHidden(bubble)
            noteBubble
        }
        //The field's glass, exactly as it always was; resting as a bubble the material is off (the bubble's fill stands in
        //front of it all the way there). Its shape holds: on a one-line bubble a 24pt corner clamps to the same pill
        .glassEffectIfAvailable(interactive: true, isActive: !bubble, shape: RoundedRectangle(cornerRadius: CornerRadius.xl))
        .contentShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .onTapGesture { isFocused.wrappedValue = true }
    }

    //The bubble's face, in the chat bubble's own shape and label (`MessageBubbleShape`, `MessageBubbleLabel`) but the
    //received gray, its tail on the sender's side: it is the user's, and not sent. Its fill takes the whole surface,
    //so it is the surface's own shape all the way through the morph, the glass melting into it; its label keeps
    //the bubble's column whatever the surface does, so it is typeset once and rides the leading edge as one piece.
    //The press is the bubble's alone — the field's glass never wears it — and the flat one (`.select`): its fill turns to
    //glass under the finger's release, and a sprung release would still be wobbling a full-width field a ride later
    private var noteBubble: some View {
        let bubble = restsAsBubble
        let placement = text.isEmpty ? .hidden : bubblePlacement
        return NoteBubbleLayout(column: bubbleColumn) {
            MessageBubbleShape(messageCornerRadius: bubble ? BubbleMetrics.cornerRadius : CornerRadius.xl, tail: .trailing) //The field's corner while it is the field's size
                .fill(Color.fillGray)
            MessageBubbleLabel(text: bubbleText, foreground: .textPrimary, placement: placement) { MessageNoteBadge(kind: noteBadge) }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { measureLabel($0) }
        }
        .press(.select, shadow: nil, tint: .accent) { isFocused.wrappedValue = true } //Straight to the field: it is mounted under this face, so the focus lands
        .animation(bubble ? Self.faceIn : Self.faceOut) {
            $0.blur(radius: bubble ? 0 : Self.faceBlur)
                .opacity(bubble ? 1 : 0) //Outermost: the same pixels either way round (a fade scales a blur), but a field's hidden bubble is then a blur INSIDE a layer at 0, which nothing renders
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { isFocused.wrappedValue = true }
        .accessibilityHidden(!bubble)
    }

    private var noteField: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                if text.isEmpty { placeholder } //In the layout, as the field's own was: an empty note is as tall as its words
                TextField("", text: $text, axis: .vertical)
                    .font(Self.font)
                    .lineSpacing(Self.lineSpacing)
                    .submitLabel(.done) //Return reads Done (a ✓ on iOS 26) and closes the note: see `takeLineBreaks`
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
        //No height of its own: the surface's pose gives it one (`NotePoseLayout` — `fieldHeight` while it is a field), and
        //as the surface closes onto the bubble this scroll's own clip crops the line to it
        .mask { edgeFadeMask }
        .background { holdTwin }
        .onChange(of: text) { old, new in
            if takeLineBreaks(old, new) { return }
            if new.count > Self.textLimit { text = String(new.prefix(Self.textLimit)) }
            let afterBreak = old.contains(where: \.isNewline) //`takeLineBreaks`' own write, its edit already handled: a Return's close shows the lines left in view, as Done's does
            if !afterBreak, new.hasPrefix(old) || old.hasPrefix(new) { revealLastLine() } //An edit at the tail
        }
        .onChange(of: lineCount) { _, _ in revealLastLine() }
        .overlay(alignment: .bottomTrailing) { countRemainingText }
    }

    //A note is one paragraph (as `MessageComposerField`'s is). A vertical field types Return as a line break and never
    //calls `.onSubmit` (sim, iOS 26), so the break is caught here, read off what the edit wrote. A run ending in its only
    //break is the key: it closes the note through Done's own path. A lone break puts back whatever it replaced (a selected
    //word stays, as Done leaves it); after a correction the key accepted ("cant" → "can't") the correction stays. Any other
    //break was pasted or dictated and reads as a space. The break is in the field for one pass: measured in a mimic of this
    //bar, it never reaches a frame. A binding that drops it before it lands does worse: the field keeps its two-line size
    //and grows through the close
    private func takeLineBreaks(_ old: String, _ new: String) -> Bool {
        guard new.contains(where: \.isNewline) else { return false }
        //The run the edit wrote: `new` less what it still shares with `old` at either end
        let head = zip(old, new).prefix { $0 == $1 }.count
        let tail = zip(old.dropFirst(head).reversed(), new.dropFirst(head).reversed()).prefix { $0 == $1 }.count
        let typed = new.dropFirst(head).dropLast(tail)
        guard typed.last?.isNewline == true, !typed.dropLast().contains(where: \.isNewline) else {
            text = new.withoutLineBreaks
            if new.hasPrefix(old) { revealLastLine() } //A paste at the tail: the pass after skips the tail rule
            return true
        }
        text = typed.count == 1 ? old : String(new.prefix(head) + typed.dropLast() + new.suffix(tail))
        onDone()
        return true
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

//The note's surface in the pose it stands in. Its two faces — the field, then the bubble — always take the whole surface;
//only the surface's own size is the pose's: across the column at the field's height, or hugging the bubble's label. A
//pose flipped inside a transaction is a change of layout, so the frames between are the transaction's
private struct NotePoseLayout: Layout {
    var restsAsBubble: Bool
    var fieldHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        guard restsAsBubble, let bubble = subviews.last else { return CGSize(width: width, height: fieldHeight) }
        return bubble.sizeThatFits(ProposedViewSize(width: width, height: nil)) //No height asked of it: the bubble's label, at its own column inside this width (`NoteBubbleLayout`)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for face in subviews { face.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size)) }
    }
}

//The bubble's face: its fill, then its label. Asked for its own height it is the label's size, at the bubble's column;
//given a surface, the fill takes all of it and the label still only its column, hung off the leading top corner — never
//re-wrapped by a surface morphing around it. No column yet (the card unmeasured): the width it is given, both times
private struct NoteBubbleLayout: Layout {
    var column: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let label = subviews.last else { return .zero }
        let hug = label.sizeThatFits(ProposedViewSize(width: labelWidth(in: proposal.width), height: nil))
        guard let height = proposal.height else { return hug }
        return CGSize(width: proposal.width ?? hug.width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let fill = subviews.first, let label = subviews.last else { return }
        fill.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
        //Hugging, the surface IS the label's size, so an unknown column's pass wraps as it was measured; a surface
        //wider than the column never widens it
        label.place(at: bounds.origin, proposal: ProposedViewSize(width: column > 0 ? column : bounds.width, height: nil))
    }

    private func labelWidth(in offered: CGFloat?) -> CGFloat? {
        guard column > 0 else { return offered }
        return min(column, offered ?? column)
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
