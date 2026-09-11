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
    var isFocused: FocusState<Bool>.Binding
    let onSendFailed: (Error) -> Void

    //Local view state
    @State private var text = ""

    var body: some View {
            HStack(alignment: .bottom, spacing: Spacing.xs) {
                chatTextField
                sendMessageView
            }
            .frame(maxWidth: .infinity)
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
            .background(isFocused.wrappedValue ? nil : fadeGradient.ignoresSafeArea())
            .background(isFocused.wrappedValue ? fadeGradientFocused.offset(y: 2) : nil) //Offset needed as keyboard is rounded
    }
}

extension MessageInputBar {

    //The composer wears the bubble's face and side insets (BubbleMetrics), so the line it types is the line it
    //sends; its top and bottom insets are its own, level with the send button. RoundedRectangle, not Capsule: it
    //grows to five lines, and the one-line clamp to a pill is deliberate.
    private var chatTextField: some View {
        TextField("Message...", text: $text, axis: .vertical)
            .font(BubbleMetrics.font)
            .lineSpacing(BubbleMetrics.lineSpacing)
            .lineLimit(1...5)
            .focused(isFocused)
            .padding(.horizontal, BubbleMetrics.leading)
            .padding(.vertical, BubbleMetrics.fieldVertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffectIfAvailable(interactive: true, shape: RoundedRectangle(cornerRadius: CornerRadius.xl))
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
            .onTapGesture { isFocused.wrappedValue = true }
            //The press: the field lifts while the send button is held and snaps back on the send frame
            .scaleEffect(ui.sendPressed ? liftScale : 1)
            .animation(ui.sendPressed ? SendChoreography.lift : nil, value: ui.sendPressed)
            //Measured outside the lift: a frame read inside a scaleEffect reports the scaled rect, and the flight must be
            //born on the field at rest
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(ChatUIState.space)) } action: {
                if ui.fieldFrame != $0 { ui.fieldFrame = $0 }
            }
    }

    //The press lift, capped so the field's trailing growth stays inside the gap to the send button on a wide layout
    //(iPad, landscape); a phone in portrait gets the full measured lift
    private var liftScale: CGFloat {
        guard ui.fieldFrame.width > 0 else { return SendChoreography.liftScale }
        return min(SendChoreography.liftScale, 1 + 2 * Spacing.xs * SendChoreography.liftGapShare / ui.fieldFrame.width)
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

    //T0, all in one update: the field clears, the lift snaps back, the send button turns grey, the row is staged as a
    //ghost growing in on the shift curve, and the clone is born on the composer's frame with its clock started.
    private func send() {
        let draft = text
        guard !draft.isEmpty, ui.containerWidth > 0 else { return }
        //Scrolled up, the row lands below the screen: nothing to fly to, so the list is brought down to the row instead.
        //A draft that wrapped does not count as scrolled up: the list stays pinned to its floor while the field grows.
        guard ui.fieldFrame.width > 0, ui.distanceFromFloor <= SendChoreography.floorSlop else { return sendUnflown(draft) }

        //The geometry the flight lands on, all known before the row exists
        let column = MessageBubbleView.columnWidth(containerWidth: ui.containerWidth, isMyChat: true)
        let now = Date()
        let placement = MessageBubbleView.timePlacement(text: draft, maxBubbleWidth: column, date: now)
        let rowSize = MessageBubbleView.restingSize(text: draft, maxBubbleWidth: column, date: now)
        //The row's text wraps against the column, not against the bubble that hugs it: the clone lays its text out the same way
        let textWidth = column - BubbleMetrics.leading - BubbleMetrics.trailing - placement.reservation
        let rowLines = textLayoutMetrics(text: draft, width: textWidth, font: BubbleMetrics.uiFont).lineCount
        let id = vm.newMessageId()
        let fieldRadius = min(CornerRadius.xl, ui.fieldFrame.height / 2)

        var flight = SendFlight(text: draft, birth: ui.fieldFrame, timeline: SendChoreography.timeline(fieldRadius: fieldRadius))
        flight.messageId = id
        flight.rowSize = rowSize
        flight.textWidth = textWidth
        flight.trailingX = ui.containerWidth - Spacing.gutter
        //The wraps differ whenever either side runs past one line (a one-line draft can wrap in the narrower bubble)
        flight.isMultiline = flight.birth.height > BubbleMetrics.fieldSingleLineHeight + 1 || rowLines > 1
        flight.start = now

        var settle = Transaction()
        settle.disablesAnimations = true
        withTransaction(settle) {
            ui.flights.append(flight) //Registered before the append: the row mounts as a ghost with the growth transition
            if ui.sendPressed { ui.sendPressed = false }
            text = ""
        }
        #if DEBUG
        SendMotionLog.begin(flight: flight.id, birth: flight.birth, landing: ui.landing(for: flight), distanceFromFloor: ui.distanceFromFloor)
        #endif
        let message = withAnimation(SendChoreography.shift) { vm.stage(text: draft, id: id, at: now) }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(SendChoreography.duration))
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
            text = ""
        }
        let message = withAnimation(.move) { vm.stage(text: draft, id: vm.newMessageId()) }
        Task { await commit(message, flight: nil) }
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
    //75.3 pt, response 0.30 s). Drives the sent row's growth, so the bottom-anchored list moves by exactly that.
    static let shift = Animation.interpolatingSpring(Spring(response: 0.30, dampingRatio: 1.0), initialVelocity: 48.0 / 75.3)

    //The press: the draft field lifts 4 % over five frames while the send button is held and snaps back at T0
    static let liftScale: CGFloat = 1.04
    static let liftGapShare: CGFloat = 0.9 //How much of the gap to the send button a lifted field may grow into
    static let lift = Animation.linear(duration: 5 * frame)

    //The hand-off: one frame for the row's reveal to commit under the clone, then the clone dissolves over the
    //identical row on the `.handOff` role and the flight is torn down once that has run
    static let handOffBeat: Duration = .milliseconds(16)
    static let teardown: Duration = .milliseconds(300)

    //A multi-line text cannot morph 1:1 (the wraps differ): the clone's text is posed at its landing wrap from
    //T0 and blurs in over the first eight frames
    static let veilDuration: Double = 8 * frame
    static let veilBlur: CGFloat = 4

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
                    SendBubbleClone(flight: flight, ui: ui, elapsed: flight.start.map { context.date.timeIntervalSince($0) } ?? 0)
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
//time. The shape is laid out unscaled and scaled about its top-trailing corner so corner, tail and body shrink and
//grow as one unit; the text rides the leading edge, scaled about its own top-leading corner.
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
        //The field's height becomes the row's on the contraction ease — a multi-line field is taller than its row,
        //a one-line field whose text wraps in the bubble shorter; from T+12 the body is the row, scaled
        let height = rowH * s + (flight.birth.height - rowH) * (1 - pose.contraction)
        //The trailing edge travels from the field's to the bubble column's on the width's ease: Messages' composer and
        //bubbles share one edge, Scoop's field stops short of its send button
        let right = flight.birth.maxX + (flight.trailingX - flight.birth.maxX) * pose.contraction - origin.x
        let top = flight.birth.minY + (landing.minY - flight.birth.minY) * pose.rise - origin.y
        //The text's top inset eases from the field's to the bubble's on that ease too, so the line does not jump at T0
        let textInset = BubbleMetrics.fieldVertical + (BubbleMetrics.vertical - BubbleMetrics.fieldVertical) * pose.contraction
        let veil = flight.isMultiline ? max(0, 1 - t / SendChoreography.veilDuration) : 0
        //The column's width, not the row's measured one: a rounded measurement a hair under the text's own width wraps it
        let textWidth = max(1, flight.textWidth)

        #if DEBUG
        //One row per rendered frame, in the chat space: the acceptance table the send is measured against
        let _ = SendMotionLog.record(flight: flight.id, t: t, left: right + origin.x - width, top: top + origin.y,
                                     width: width, height: height, scale: s, opacity: pose.opacity)
        #endif

        ZStack(alignment: .topLeading) {
            MessageBubbleShape(messageCornerRadius: pose.radius, tail: .trailing)
                .fill(Color.accent)
                .frame(width: width / s, height: height / s)
                //The clock from birth, where the row's badge sits, shrinking and settling with the bubble
                .overlay(alignment: .bottomTrailing) {
                    MessageTimeBadge(date: flight.start ?? Date(), showsTime: false, isMyChat: true)
                }
                .scaleEffect(s, anchor: .topTrailing)
                .offset(x: right - width / s, y: top)

            Text(flight.text)
                .font(BubbleMetrics.font)
                .lineSpacing(BubbleMetrics.lineSpacing)
                .foregroundStyle(Color.white)
                .frame(width: textWidth, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .blur(radius: SendChoreography.veilBlur * veil)
                .opacity(1 - veil)
                .scaleEffect(s, anchor: .topLeading)
                .offset(x: right - width + BubbleMetrics.leading, y: top + textInset * s)
        }
        .opacity(pose.opacity)
        .opacity(flight.phase == .dissolving ? 0 : 1)
        .animation(.handOff, value: flight.phase == .dissolving)
    }
}
