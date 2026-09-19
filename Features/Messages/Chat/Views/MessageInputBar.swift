//
//  MessageInputBar.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI
import os

struct MessageInputBar: View {

    //Injected
    @Bindable var vm: ChatViewModel
    let ui: ChatUIState
    var isFocused: Binding<Bool>
    let onSendFailed: (Error) -> Void

    //Local view state
    @State private var text = ""

    private static let sendGap = Spacing.sm //The field ↔ its send button

    var body: some View {
            HStack(alignment: .bottom, spacing: Self.sendGap) {
                chatTextField
                sendMessageView
            }
            .frame(maxWidth: .infinity, alignment: .trailing) //The field has its own width: the room left opens at the leading edge
            .padding(.horizontal)

            .padding(.bottom, isFocused.wrappedValue ? Spacing.sm : 0)
            .padding(.top, Spacing.sm) // determines how much above the fade gradient goes ontop of the view
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(ChatUIState.space)) } action: {
                if ui.barFrame != $0 { ui.barFrame = $0 }
            }
            .modifier(SendFlightHost(ui: ui))
            .onChange(of: text.isEmpty) { _, empty in
                if ui.hasDraft == empty { ui.hasDraft = !empty } //Pins the list to its floor while a draft is open (ChatScrollView)
            }

            //When no keyboard want it to ignore safe area. When is keyboard, bottom of fade is keyboard so don't ignore safe area
            .background(isFocused.wrappedValue ? nil : reachingField(fadeGradient.ignoresSafeArea()))
            .background(isFocused.wrappedValue ? reachingField(fadeGradientFocused.offset(y: 2)) : nil) //Offset needed as keyboard is rounded
    }
}

extension MessageInputBar {

    //The composer wears the bubble's face and text column (BubbleMetrics), so the lines it types are the lines it
    //sends, and it is as wide as the widest bubble plus a little more air leading; top and bottom its insets are its
    //own, level with the send button. RoundedRectangle, not Capsule: it grows to five lines, and the one-line clamp to a
    //pill is deliberate. The text view fills the pill (its insets are the padding), so a tap anywhere on it focuses and
    //places the caret.
    private var chatTextField: some View {
        ComposerField(text: $text, isFocused: isFocused, placeholder: "Message...",
                      wrapWidth: MessageBubbleView.textColumn(containerWidth: ui.containerWidth),
                      onScroll: { ui.fieldScroll = $0 })
            .frame(width: fieldWidth) //Flexible until the container's width is known
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl)) //Past five lines the text scrolls to the pill's edge, never out of its corners
            .glassEffectIfAvailable(clear: true, interactive: true, shape: RoundedRectangle(cornerRadius: CornerRadius.xl)) //Clear: a send's bubble is born under it and shows through, as under Messages' field
            //The press: the field lifts while the send button is held and snaps back on the send frame
            .scaleEffect(ui.sendPressed ? liftScale : 1)
            .animation(ui.sendPressed ? SendChoreography.lift : nil, value: ui.sendPressed)
            //Measured outside the lift: a frame read inside a scaleEffect reports the scaled rect, and the flight must be
            //born on the field at rest
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(ChatUIState.space)) } action: {
                if ui.fieldFrame != $0 { ui.fieldFrame = $0 }
                //What the draft stands above one line, held as room under the list's last row (a send closes it itself, on its spring)
                let overflow = max(0, $0.height - BubbleMetrics.fieldSingleLineHeight)
                if abs(ui.draftOverflow - overflow) > 0.01 { ui.draftOverflow = overflow }
            }
            //One line tall to the bar, whatever the draft: a taller field stands up out of its slot, over the list. The bar's
            //inset on the list then never changes with the draft, and the send's collapse is the field's alone to animate
            .frame(height: BubbleMetrics.fieldSingleLineHeight, alignment: .bottom)
    }

    //The widest bubble, plus the field's extra leading air: its text then runs the bubble's column edge to edge
    private var fieldWidth: CGFloat? {
        guard ui.containerWidth > 0 else { return nil }
        return MessageBubbleView.columnWidth(containerWidth: ui.containerWidth) + BubbleMetrics.fieldLeading - BubbleMetrics.leading
    }

    //The press lift, capped so the field's trailing growth stays inside the gap to the send button on a layout where
    //that gap is tight against the field's width; a phone in portrait gets the full measured lift
    private var liftScale: CGFloat {
        guard ui.fieldFrame.width > 0 else { return SendChoreography.liftScale }
        return min(SendChoreography.liftScale, 1 + 2 * Self.sendGap * SendChoreography.liftGapShare / ui.fieldFrame.width)
    }

    //The original send button beside the field. Its press dims it while the field lifts, as Messages presses
    @ViewBuilder
    private var sendMessageView: some View {
        let color = text.isEmpty ? Color.fillGray : Color.accent
        let elevation: Elevation? = text.isEmpty ? nil : .glass

        ScoopButton(style: .tinted(color, shadow: elevation), shape: Circle(), size: .large, press: .dim,
                    onPressChanged: { pressChanged($0) }) {
            send()
        } label: {
            Image("SendArrow")
                .scaleEffect(0.8)
        }
        .disabled(text.isEmpty)
        .animation(nil, value: text.isEmpty) //Grey on the send frame itself: the draft clears inside the field's collapse spring, which is the field's alone
    }

    //Geometry: the bar is one line tall whatever the draft, so its fade reaches up by the draft's overflow to stay behind
    //the whole field. It steps with the field as a draft wraps, and comes back down with it on a send's collapse, whose
    //transaction carries the overflow's write (`clearDraft`)
    private func reachingField<Fade: View>(_ fade: Fade) -> some View {
        fade.padding(.top, -ui.draftOverflow)
    }

    private var fadeGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .appCanvas.opacity(0.0), location: 0.0),
                .init(color: .appCanvas.opacity(0.5), location: 0.2),
                .init(color: .appCanvas.opacity(0.65), location: 0.4),
                .init(color: .appCanvas.opacity(0.75), location: 0.6),
                .init(color: .appCanvas.opacity(0.85), location: 0.85),
                .init(color: .appCanvas, location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    //Sharper Gradient needed when focused
    private var fadeGradientFocused: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .appCanvas.opacity(0.0), location: 0.0),
                .init(color: .appCanvas.opacity(0.5), location: 0.2),
                .init(color: .appCanvas.opacity(0.7), location: 0.4),
                .init(color: .appCanvas.opacity(0.85), location: 0.6),
                .init(color: .appCanvas, location: 0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

//The send, in the order Messages does it
extension MessageInputBar {

    //The press only lifts the field: the flight is born in the send's own update, posed from its own clock
    private func pressChanged(_ pressed: Bool) {
        if ui.sendPressed != pressed { ui.sendPressed = pressed }
    }

    //T0, all in one update: the field clears and starts back down to one line, the lift snaps back, the send button
    //turns grey, the row is staged as a ghost the list shifts up to, and the clone is born on the composer's frame —
    //under its glass, which still stands at the draft's full height — with its clock started.
    private func send() {
        let draft = text
        guard !draft.isEmpty, ui.containerWidth > 0 else { return }
        //Scrolled up, the row lands below the screen: nothing to fly to, so the list is brought down to the row instead.
        //A draft that wrapped does not count as scrolled up: the list stays pinned to its floor while the field grows.
        guard ui.fieldFrame.width > 0, ui.distanceFromFloor <= SendChoreography.floorSlop else { return sendUnflown(draft) }

        //The geometry the flight lands on, all known before the row exists
        let column = MessageBubbleView.columnWidth(containerWidth: ui.containerWidth)
        let now = Date()
        let placement = MessageBubbleView.timePlacement(text: draft, maxBubbleWidth: column, date: now)
        let rowSize = MessageBubbleView.restingSize(text: draft, maxBubbleWidth: column, date: now)
        //The row's text wraps against the column, not against the bubble that hugs it: the clone lays its text out the
        //same way, and the field has wrapped the draft against that column all along, so the lines never re-break
        let textWidth = column - BubbleMetrics.leading - BubbleMetrics.trailing - placement.reservation
        let id = vm.newMessageId()
        let fieldRadius = min(CornerRadius.xl, ui.fieldFrame.height / 2)

        var flight = SendFlight(text: draft, birth: ui.fieldFrame, timeline: SendChoreography.timeline(fieldRadius: fieldRadius))
        flight.messageId = id
        flight.rowSize = rowSize
        flight.textWidth = textWidth
        flight.trailingX = ui.containerWidth - Spacing.gutter
        flight.birthScroll = ui.fieldScroll
        flight.start = now

        var settle = Transaction()
        settle.disablesAnimations = true
        withTransaction(settle) {
            ui.flights.append(flight) //Registered before the append: the row mounts as a ghost
            if ui.sendPressed { ui.sendPressed = false }
        }
        clearDraft()
        #if DEBUG
        SendMotionLog.begin(flight: flight.id, birth: flight.birth, landing: ui.landing(for: flight), distanceFromFloor: ui.distanceFromFloor)
        #endif
        let message = withAnimation(SendChoreography.shift) { vm.stage(text: draft, id: id, at: now) }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(SendChoreography.duration))
            //The pose clock starts on the first posed frame, after the send's own slow frame: what it still has to run is
            //waited out, so the clone rests on its final pose when the row un-hides beneath it
            if let rest = ui.remaining(for: flight.id), rest > 0 { try? await Task.sleep(for: .seconds(rest)) }
            handOff(flight.id)
        }
        Task { await commit(message, flight: flight.id) }
    }

    //A send with nothing on screen to fly to (the list scrolled up): the row slides in the standard way and the
    //list's own-message scroll brings the floor down to it
    private func sendUnflown(_ draft: String) {
        #if DEBUG
        SendMotionLog.unflown(distanceFromFloor: ui.distanceFromFloor, fieldFrame: ui.fieldFrame)
        #endif
        var settle = Transaction()
        settle.disablesAnimations = true
        withTransaction(settle) {
            if ui.sendPressed { ui.sendPressed = false }
        }
        clearDraft()
        let message = withAnimation(.move) { vm.stage(text: draft, id: vm.newMessageId()) }
        Task { await commit(message, flight: nil) }
    }

    //The draft clears on the collapse spring: a field taller than one line comes back down to it, glass and all, from
    //the send frame on (the text itself is gone on that frame, a UIKit write), and the room it held under the list
    //closes on the same spring, a frame at a time — never in one step, which a list at its floor is clamped by.
    private func clearDraft() {
        withAnimation(SendChoreography.collapse) {
            text = ""
            if ui.draftOverflow != 0 { ui.draftOverflow = 0 }
        }
    }

    //The clock has run out, so the clone rests exactly on its landing: the row un-hides beneath it with animations
    //disabled — no frame where the bubble doubles or gaps — then the clone dissolves over it while the badge fades in.
    private func handOff(_ flightId: UUID) {
        guard let i = ui.index(of: flightId), ui.flights[i].phase == .flying else { return }
        var settle = Transaction()
        settle.disablesAnimations = true
        withTransaction(settle) { ui.flights[i].phase = .landed }
        Task { @MainActor in
            try? await Task.sleep(for: SendChoreography.handOffBeat)
            if let j = ui.index(of: flightId) { ui.flights[j].phase = .dissolving }
            try? await Task.sleep(for: SendChoreography.teardown)
            #if DEBUG
            SendMotionLog.flush(flight: flightId)
            #endif
            //A row the flight kept tailed (a later send joined its run) regroups on the settle curve, not in a jump
            withAnimation(.move) { ui.flights.removeAll { $0.id == flightId } }
            ui.forget(flightId)
        }
    }

    //The write. On failure a flight still in the air lands first — a bubble vanishing mid-air reads as a
    //glitch, not an error — then the row goes and the container is told, unless the message is already stored.
    private func commit(_ message: ChatMessage, flight flightId: UUID?) async {
        do {
            try await vm.commit(message)
        } catch {
            if let flightId { await landed(flightId) }
            if vm.discard(message.id, after: error) { onSendFailed(error) }
        }
    }

    //Waits for a flight to land, for at most 1.5 s: a flight whose chat has closed never completes
    private func landed(_ flightId: UUID) async {
        for _ in 0..<30 {
            guard ui.flights.contains(where: { $0.id == flightId && $0.phase == .flying }) else { return }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
}

//MARK: - The draft field

//The composer's text view, wearing the field's padding as its own inset. A vertical TextField is a UITextView sized to
//exactly its lines and clipped there, and ModernEra's line box is its point size, so the hooks of g, y and j — which
//hang a pixel or two past it — were cut flat. Here the clip edge is the pill's. The text still sets where the padding
//put it (TextKit 2, the bubble's face and pitch, no fragment padding), so the line it types is the line the flight flies.
private struct ComposerField: UIViewRepresentable {

    //Injected
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let wrapWidth: CGFloat //The bubble's text column: the draft wraps where its bubble will, so nothing re-breaks on the send frame
    let onScroll: (CGFloat) -> Void //How far a draft past five lines is scrolled: a send's text is born at that scroll

    func makeUIView(context: Context) -> ComposerTextView {
        //TextKit 2, this initializer's default. Not `init(usingTextLayoutManager:)`: that factory skips a subclass's
        //stored-property initializers, and the first read of one crashes
        let view = ComposerTextView(frame: .zero, textContainer: nil)
        view.backgroundColor = .clear
        view.textContainer.lineFragmentPadding = 0
        view.contentInsetAdjustmentBehavior = .never //Its insets are the padding, never the safe area's or the keyboard's
        view.automaticallyAdjustsScrollIndicatorInsets = false
        view.alwaysBounceVertical = false
        view.tintColor = UIColor(Color.accent)
        view.accessibilityLabel = placeholder
        view.placeholderLabel.text = placeholder
        view.placeholderLabel.textColor = UIColor(Color.textPlaceholder)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ view: ComposerTextView, context: Context) {
        context.coordinator.parent = self
        view.typeset(font: BubbleMetrics.uiFont, lineSpacing: BubbleMetrics.lineSpacing, inset: Self.inset(scale: context.environment.displayScale), wrapWidth: wrapWidth)
        if view.text != text { view.setDraft(text) } //Only a change from outside (the send's clear): rewriting what is typed would jump the caret
        followFocus(view)
    }

    //The draft's own height up to five lines; past them the text scrolls inside
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: ComposerTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite else { return nil }
        uiView.fitColumn(width: width) //Before the measure: the lines break against the bubble's column at this width
        let height = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return CGSize(width: width, height: min(height, uiView.maxHeight))
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    //Out of the update: a responder change fires the keyboard's notifications and the delegate's writes
    private func followFocus(_ view: UITextView) {
        let wantsFocus = isFocused
        guard view.isFirstResponder != wantsFocus else { return }
        DispatchQueue.main.async { [weak view] in
            guard let view, view.window != nil, isFocused == wantsFocus, view.isFirstResponder != wantsFocus else { return }
            if wantsFocus { view.becomeFirstResponder() } else { view.resignFirstResponder() }
        }
    }

    //Geometry: the field's vertical padding, inside the clip. The top lands on a whole pixel as the padded TextField's own
    //frame did (SwiftUI rounds what it places), so the line keeps its pixels; the bottom takes the rest, one line 44 pt
    private static func inset(scale: CGFloat) -> UIEdgeInsets {
        let top = (BubbleMetrics.fieldVertical * scale).rounded() / scale
        return UIEdgeInsets(top: top, left: BubbleMetrics.fieldLeading, bottom: 2 * BubbleMetrics.fieldVertical - top, right: BubbleMetrics.trailing)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: ComposerField

        init(parent: ComposerField) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            (textView as? ComposerTextView)?.showsPlaceholder(!textView.hasText)
            if parent.text != textView.text { parent.text = textView.text }
        }

        //A selection change clears the typing attributes, and an emptied field would then type off the bubble's pitch
        func textViewDidChangeSelection(_ textView: UITextView) {
            (textView as? ComposerTextView)?.restoreTypingAttributes()
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if !parent.isFocused { parent.isFocused = true }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if parent.isFocused { parent.isFocused = false }
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.onScroll(max(0, scrollView.contentOffset.y))
        }
    }
}

//The draft's UITextView: the bubble's typesetting, a placeholder on the line the text types into, and the five-line cap
private final class ComposerTextView: UITextView {
    let placeholderLabel = UILabel()
    private var attributes: [NSAttributedString.Key: Any] = [:]
    private var padding = UIEdgeInsets.zero //The field's own insets; the text's trailing inset grows past it to leave the bubble's column
    private var wrapWidth: CGFloat = 0
    private static let maxLines: CGFloat = 5

    var maxHeight: CGFloat {
        guard let font = attributes[.font] as? UIFont, let paragraph = attributes[.paragraphStyle] as? NSParagraphStyle else { return .greatestFiniteMagnitude }
        return Self.maxLines * font.lineHeight + (Self.maxLines - 1) * paragraph.lineSpacing + textContainerInset.top + textContainerInset.bottom
    }

    //The bubble's face and pitch, reapplied only when the text size changes them
    func typeset(font: UIFont, lineSpacing: CGFloat, inset: UIEdgeInsets, wrapWidth: CGFloat) {
        if padding != inset || self.wrapWidth != wrapWidth {
            padding = inset
            self.wrapWidth = wrapWidth
            verticalScrollIndicatorInsets = UIEdgeInsets(top: inset.top, left: 0, bottom: inset.bottom, right: inset.right)
            fitColumn(width: bounds.width)
        }
        let paragraph = attributes[.paragraphStyle] as? NSParagraphStyle
        guard attributes[.font] as? UIFont != font || paragraph?.lineSpacing != lineSpacing else { return }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.lineBreakStrategy = .standard //As the bubble's Text breaks its lines (it pushes a word down rather than orphan the last one)
        attributes = [.font: font, .paragraphStyle: style, .foregroundColor: UIColor.label] //The system text color every field in the app types in
        if markedTextRange == nil { textStorage.setAttributes(attributes, range: NSRange(location: 0, length: textStorage.length)) }
        typingAttributes = attributes
        placeholderLabel.font = font
        setNeedsLayout()
    }

    //Geometry: the trailing inset that leaves the text exactly the bubble's column in a field this wide. The field is sized
    //to that column, so this is the bubble's own inset; it only runs wider while a field is laid out before the container's
    //width is known, and a draft still wraps where its bubble will
    func fitColumn(width: CGFloat) {
        var inset = padding
        if wrapWidth > 0, width > 0 { inset.right = max(padding.right, width - padding.left - wrapWidth) }
        if textContainerInset != inset { textContainerInset = inset }
    }

    func setDraft(_ text: String) {
        attributedText = NSAttributedString(string: text, attributes: attributes)
        typingAttributes = attributes
        showsPlaceholder(text.isEmpty)
    }

    func restoreTypingAttributes() {
        guard markedTextRange == nil, !attributes.isEmpty else { return }
        typingAttributes = attributes
    }

    func showsPlaceholder(_ shows: Bool) {
        placeholderLabel.isHidden = !shows
    }

    //Scrolling to the caret keeps the padding around its line, as typing at the end already does: a caret brought into
    //view by focus alone would otherwise sit its line flush on the pill's edge, the descenders under the clip again
    override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        let padded = rect.inset(by: UIEdgeInsets(top: -textContainerInset.top, left: 0, bottom: -textContainerInset.bottom, right: 0))
        super.scrollRectToVisible(padded, animated: animated)
    }

    //The placeholder rides the first line's box, where the draft's first line sets
    override func layoutSubviews() {
        super.layoutSubviews()
        fitColumn(width: bounds.width)
        if placeholderLabel.superview == nil {
            placeholderLabel.isAccessibilityElement = false //The field reads it as its label
            addSubview(placeholderLabel)
        }
        let inset = textContainerInset
        placeholderLabel.frame = CGRect(x: inset.left, y: inset.top, width: max(0, bounds.width - inset.left - inset.right), height: placeholderLabel.font.lineHeight)
    }
}

//MARK: - The choreography

//Apple Messages' send on iOS 26, measured frame by frame from a 60 fps device recording (2026-09-11) and
//replicated as a system choreography: its curves live here, not in the motion roles. T0 is the frame
//the composer clears; every figure is in frames of 1/60 s or as a fraction of Scoop's own distances,
//so Messages' pixel sizes are never typed in.
enum SendChoreography {
    static let frame: Double = 1.0 / 60.0
    //The flight's clock, sampled every display frame: rise settled T+38, shift T+39, tail T+40; it runs on to T+45
    static let duration: Double = 45 * frame

    //Birth: the composer's full frame at 65 %, the tail already on, the text white at scale 1
    static let birthOpacity: CGFloat = 0.65
    static let opacityRamp: Double = 11 * frame //Linear to 1.0 by T+11, as the bubble clears the composer's top
    static let radiusBlend: Double = 3 * frame //The composer's pill corner → the bubble's own, over T0…T+3

    //Contraction, T+1…T+12: the text scale falls near-linearly to its floor while the width runs its own ease and
    //the trailing edge travels, on that ease, from the field's to the bubble column's — a shape morph, not a uniform scale
    static let scale: [CGFloat] = [1.0, 0.97, 0.96, 0.95, 0.92, 0.90, 0.87, 0.83, 0.81, 0.80, 0.78, 0.76, 0.763] //T0…T+12
    static let ease: [CGFloat] = [0, 0, 0, 0.176, 0.285, 0.401, 0.544, 0.676, 0.780, 0.868, 0.940, 0.989, 1.0] //T0…T+12
    static let contractionFloor: CGFloat = 0.763 //The scale minimum at T+12; width = W_field − (W_field − floor·W_row)·ease
    static let contractionEnd: Double = 12 * frame //From here width = W_row × scale: the release is one rigid unit

    //Release from rest at T+12 (Messages: ζ 0.80, response 0.49 s; back to 1.0 by T+31, ≤ 0.3 % overshoot)
    static let release = Spring(response: 0.49, dampingRatio: 0.80)

    //Rise: the top edge holds through T+4, then a spring already moving (Messages: −52 pt/s over a 57.3 pt
    //travel, ζ 0.76, response 0.55 s; 1.3 pt overshoot at T+25…27, landed T+38)
    static let riseHold: Double = 4 * frame
    static let rise = Spring(response: 0.55, dampingRatio: 0.76)
    static let riseVelocity: CGFloat = 52.0 / 57.3 //As a fraction of the travel per second

    //The list shift from T0: critically damped and already moving on the T0 frame (Messages: −48 pt/s over
    //75.3 pt, response 0.30 s). The transaction the sent row is staged in: the bottom-anchored list rides it up to the
    //row. Declared at 0.41 s because the scroll view runs the move it makes under a transaction's spring about 1.37×
    //fast (sim-traced, fitted per frame: declared 0.30 moved as 0.225, declared 0.41 as 0.300 — Messages' figure).
    static let shift = Animation.interpolatingSpring(Spring(response: 0.41, dampingRatio: 1.0), initialVelocity: 48.0 / 75.3)

    //The press: the draft field lifts 4 % over five frames while the send button is held and snaps back at T0
    static let liftScale: CGFloat = 1.04
    static let liftGapShare: CGFloat = 0.9 //How much of the gap to the send button a lifted field may grow into
    static let lift = Animation.linear(duration: 5 * frame)

    //The hand-off: one frame for the row's reveal to commit under the clone, then the clone dissolves over the
    //identical row on the `.handOff` role and the flight is torn down once that has run
    static let handOffBeat: Duration = .milliseconds(16)
    static let teardown: Duration = .milliseconds(300)

    //The collapse from T0: a field taller than one line comes back down to it under the rising bubble (Messages, a
    //three-line send: from rest, ζ 0.89, response 0.36 s — 47 % by T+5, 83 % by T+10, home at T+18 with a third of a
    //point of overshoot). The room that draft held under the list closes on it too, frame by frame, and the list
    //follows each frame's close at once: its glide is the shift up to the sent row less this collapse, Messages' own sum.
    static let collapse = Animation.interpolatingSpring(Spring(response: 0.36, dampingRatio: 0.89))

    //How far above its floor the list may rest and still fly a send: a list at rest there drifts by a sub-point
    static let floorSlop: CGFloat = 2

    static func timeline(fieldRadius: CGFloat) -> KeyframeTimeline<SendPose> {
        KeyframeTimeline(initialValue: SendPose(contraction: 0, scale: 1, rise: 0, opacity: birthOpacity, radius: fieldRadius)) {
            KeyframeTrack(\.contraction) {
                for value in ease.dropFirst() { LinearKeyframe(value, duration: frame) }
            }
            KeyframeTrack(\.scale) {
                for value in scale.dropFirst() { LinearKeyframe(value, duration: frame) }
                SpringKeyframe(1, spring: release)
            }
            KeyframeTrack(\.rise) {
                LinearKeyframe(0, duration: riseHold)
                SpringKeyframe(1, spring: rise, startVelocity: riseVelocity)
            }
            KeyframeTrack(\.opacity) {
                LinearKeyframe(1, duration: opacityRamp)
            }
            KeyframeTrack(\.radius) {
                LinearKeyframe(BubbleMetrics.cornerRadius, duration: radiusBlend)
            }
        }
    }
}

#if DEBUG
//MARK: - Motion log (DEBUG)

//The per-frame record the acceptance compares against Messages: every rendered pose of a clone, the list's
//content offset as it shifts, and the main thread's frame gaps, written to Documents/send-motion.csv when
//the flight is torn down. Pull it with `xcrun simctl get_app_container booted <bundle id> data`.
@MainActor
enum SendMotionLog {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Scoop", category: "send-motion")
    private static var current: UUID?
    private static var t0: CFTimeInterval = 0
    private static var header = ""
    private static var poses: [String] = []
    private static var scrolls: [String] = []
    private static var lastPoseT: Double = -1
    private static var gapWatch: DisplayGapWatch?

    static func unflown(distanceFromFloor: CGFloat, fieldFrame: CGRect) {
        log.notice("send unflown: distanceFromFloor=\(distanceFromFloor, privacy: .public) field=\(fieldFrame.debugDescription, privacy: .public)")
    }


    //One flight per log: a send overlapping one still being logged flies, but is not measured
    static func begin(flight: UUID, birth: CGRect, landing: CGRect, distanceFromFloor: CGFloat) {
        guard current == nil else { return }
        current = flight
        t0 = CACurrentMediaTime()
        lastPoseT = -1
        poses = []
        scrolls = []
        header = "# flight \(flight) birth \(birth) landing@T0 \(landing) distanceFromFloor \(distanceFromFloor)"
        gapWatch = DisplayGapWatch()
        log.notice("send T0 birth=\(birth.debugDescription, privacy: .public) landing=\(landing.debugDescription, privacy: .public)")
    }

    static func record(flight: UUID, t: Double, left: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat, scale: CGFloat, opacity: CGFloat) {
        guard flight == current, t != lastPoseT else { return }
        lastPoseT = t
        let wall = CACurrentMediaTime() - t0
        poses.append(String(format: "%.4f,%.4f,%.2f,%.2f,%.2f,%.2f,%.4f,%.3f", wall, t, left, top, width, height, scale, opacity))
    }

    static func scroll(offset: CGFloat, contentHeight: CGFloat) {
        guard current != nil else { return }
        let wall = CACurrentMediaTime() - t0
        scrolls.append(String(format: "%.4f,%.2f,%.2f", wall, offset, contentHeight))
    }

    static func flush(flight: UUID) {
        guard flight == current else { return }
        let gaps = gapWatch?.finish() ?? []
        gapWatch = nil
        var csv = header + "\n"
        csv += "pose: wall,t,left,top,width,height,scale,opacity\n" + poses.joined(separator: "\n") + "\n"
        csv += "scroll: wall,offset,contentHeight\n" + scrolls.joined(separator: "\n") + "\n"
        csv += "gaps(ms > 20): " + gaps.map { String(format: "%.1f", $0 * 1000) }.joined(separator: " ") + "\n"
        let url = URL.documentsDirectory.appending(path: "send-motion.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            log.notice("send motion log written: \(url.path, privacy: .public) poses=\(poses.count) scrolls=\(scrolls.count) gaps=\(gaps.count)")
        } catch {
            log.error("send motion log failed: \(error.localizedDescription, privacy: .public)")
        }
        current = nil
        t0 = 0
    }
}

//Main-thread frame gaps over the flight: a display link that notes every interval longer than 20 ms
private final class DisplayGapWatch {
    private var link: CADisplayLink?
    private var last: CFTimeInterval = 0
    private var gaps: [CFTimeInterval] = []

    init() {
        let l = CADisplayLink(target: self, selector: #selector(tick))
        l.add(to: .main, forMode: .common)
        link = l
    }

    @objc private func tick(_ l: CADisplayLink) {
        let now = CACurrentMediaTime()
        if last > 0, now - last > 0.020 { gaps.append(now - last) }
        last = now
    }

    func finish() -> [CFTimeInterval] {
        link?.invalidate()
        link = nil
        return gaps
    }
}
#endif

//MARK: - The flight layer

//Where the clones fly. On iOS 26 a background of the bar: under the glass capsule, which lenses the clone
//passing beneath it as Messages' does, and above the bar's gradient and the list. Pre-26 the capsule is a
//flat fill that would hide the clone, so the layer rides above the bar instead.
private struct SendFlightHost: ViewModifier {
    let ui: ChatUIState

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.background { SendFlightLayer(ui: ui) }
        } else {
            content.overlay { SendFlightLayer(ui: ui) }
        }
    }
}

private struct SendFlightLayer: View {
    let ui: ChatUIState

    var body: some View {
        //The flights' own clock: while one is in the air, every display frame samples its pose from the time since
        //its T0. A withAnimation-driven progress was cancelled intermittently by other transactions landing in the
        //send's update (sim, sends that open a new day), snapping the clone straight to its landing.
        TimelineView(.animation(paused: !ui.flights.contains { $0.phase == .flying })) { context in
            ZStack(alignment: .topLeading) {
                ForEach(ui.flights) { flight in
                    SendBubbleClone(flight: flight, ui: ui, elapsed: ui.elapsed(for: flight, at: context.date))
                }
            }
            //Pinned to the bar's own size: a clone reaching far above the bar must not grow the layer, or the
            //host centres the grown layer on the bar and every offset in it drifts
            .frame(width: max(1, ui.barFrame.width), height: max(1, ui.barFrame.height), alignment: .topLeading)
        }
        .allowsHitTesting(false)
    }
}

//The flying bubble: a flat MessageBubbleShape and the row's text, posed from the timeline at the flight's elapsed
//time. The shape is laid out unscaled and scaled about its top-trailing corner so corner, tail, body and text shrink
//and grow as one unit. The text is on it from the first frame, on the lines the field typed it on (one text column),
//so the draft turns white in place and rides the leading edge from there.
private struct SendBubbleClone: View {
    let flight: SendFlight
    let ui: ChatUIState
    let elapsed: Double //Seconds since the flight's T0, from the layer's display-timed clock

    var body: some View {
        //Flying, the pose follows the clock; landed and dissolving, it rests on the final pose
        let t = flight.phase == .flying ? min(max(elapsed, 0), SendChoreography.duration) : SendChoreography.duration
        let pose = flight.timeline.value(time: t)
        let s = max(0.01, pose.scale)
        let origin = ui.barFrame.origin //The layer's origin in the chat space
        let landing = ui.landing(for: flight) //Live: this body re-runs every frame of the flight
        let fieldWidth = flight.birth.width
        let rowW = landing.width
        let rowH = landing.height
        let width: CGFloat = t < SendChoreography.contractionEnd
            ? fieldWidth - (fieldWidth - SendChoreography.contractionFloor * rowW) * pose.contraction
            : rowW * s
        //The field's height becomes the row's on the contraction ease — a field is taller than its row, or shorter when the
        //row's badge takes a line of its own under the text or the draft ran past the field's five lines; from T+12 the
        //body is the row, scaled
        let height = rowH * s + (flight.birth.height - rowH) * (1 - pose.contraction)
        //The trailing edge travels from the field's to the bubble column's on the width's ease: Messages' composer and
        //bubbles share one edge, Scoop's field stops short of its send button
        let right = flight.birth.maxX + (flight.trailingX - flight.birth.maxX) * pose.contraction - origin.x
        //A row far taller than the field (a draft well past five lines) grows faster than the rise lifts it: its bottom
        //holds the field's, so the lines the field kept out of view come in above the composer, never below it
        let top = min(flight.birth.minY + (landing.minY - flight.birth.minY) * pose.rise, flight.birth.maxY - height) - origin.y
        //The text's insets ease from the field's to the bubble's on that ease too, so the lines do not jump at T0
        let textInset = BubbleMetrics.fieldVertical + (BubbleMetrics.top - BubbleMetrics.fieldVertical) * pose.contraction
        let textLeading = BubbleMetrics.fieldLeading + (BubbleMetrics.leading - BubbleMetrics.fieldLeading) * pose.contraction
        //A draft past the field's five lines was scrolled to its caret: the text is born at that scroll and settles to its
        //first line on the same ease, as the body grows to hold every line
        let scrolled = flight.birthScroll * (1 - pose.contraction)
        //The column's width, not the row's measured one: a rounded measurement a hair under the text's own width wraps it
        let textWidth = max(1, flight.textWidth)
        let shape = MessageBubbleShape(messageCornerRadius: pose.radius, tail: .trailing)

        #if DEBUG
        //One row per rendered frame, in the chat space: the acceptance table the send is measured against
        let _ = SendMotionLog.record(flight: flight.id, t: t, left: right + origin.x - width, top: top + origin.y,
                                     width: width, height: height, scale: s, opacity: pose.opacity)
        #endif

        shape
            .fill(Color.accent)
            .frame(width: width / s, height: height / s)
            //Inside the scale, so its side inset is set in unscaled points: on screen the text keeps its leading inset —
            //the field's, easing to the bubble's — while the body contracts around it
            .overlay(alignment: .topLeading) {
                Text(flight.text)
                    .font(BubbleMetrics.font)
                    .lineSpacing(BubbleMetrics.lineSpacing)
                    .foregroundStyle(Color.white)
                    .frame(width: textWidth, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(x: textLeading / s, y: textInset - scrolled)
            }
            //The clock from birth, where the row's badge sits, shrinking and settling with the bubble
            .overlay(alignment: .bottomTrailing) {
                MessageTimeBadge(date: flight.start ?? Date(), showsTime: false, isMyChat: true)
            }
            .clipShape(shape) //Lines the field had scrolled out of view stay inside the body until it has grown to them
            .scaleEffect(s, anchor: .topTrailing)
            .offset(x: right - width / s, y: top)
            .opacity(pose.opacity)
            .opacity(flight.phase == .dissolving ? 0 : 1)
            .animation(.handOff, value: flight.phase == .dissolving)
    }
}
