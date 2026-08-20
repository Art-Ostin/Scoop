//
//  AcceptInviteOverlay.swift
//  Scoop
//
//  Created by Art Ostin on 13/08/2026.
//

import SwiftUI
import CoreHaptics

/*
 The dismissal's flight (the send flight's shape, reversed): the resting circle grows and
 seats into its event card's image slot in ONE spring — travel, size, clip radii and the
 shadows' dissolve all in the same transaction, so the morph reads as a single movement while
 the glass ring, glow and title dissolve in place and BlurCover's wash clears beneath it.

 The hand-off is seam-free by construction: the card's own image sat hidden the whole flight
 (armed at show(), behind the still-opaque wash), un-hides beneath the fully-settled, still-
 OPAQUE copy in a no-animation transaction, and only then does the copy dissolve — over
 pixel-identical artwork (one ImageLoader cache feeds both sides, and both crop the same
 rect), so no frame exists in which the image doubles, gaps or jumps.

 Geometry-matched hero flight: its measured curves live in-file, per the motion rules.
 */
enum AcceptFlightMotion {
    //THE tuning knob — the flight's clock. Bounce 0 (chosen 2026-08-20 over a landing
    //overshoot): the circle grows and seats into the card top as one continuous settle.
    static let spring = Spring(duration: 0.55, bounce: 0)
    static let flight = Animation.spring(spring)

    //The copy's dissolve over the identical card image beneath — diffuses the sub-pixel
    //corner seam (the copy's .circular clip over the card's continuous one) instead of
    //betting the hand-off on shape identity.
    static let handOff = Animation.smooth(duration: 0.12)

    //Derived, never tuned: .removed — the hand-off's trigger — fires at the spring's
    //SETTLING time (~0.9s here, well past the perceptual 0.55s), so both holds anchor to it
    //and cannot drift under a retune. Teardown covers the hand-off dissolve plus margin;
    //BlurCover's hold outlasts teardown, as BlurCoverMotion.contentHold outlasts the shared exit.
    static var teardown: Duration { .seconds(spring.settlingDuration + 0.25) }
    static var contentHold: Duration { .seconds(spring.settlingDuration + 0.33) }
}

struct AcceptInviteCard: View {

    //Injected
    var flight: AcceptFlightSource? = nil //nil (previews) falls back to the mock hero
    var closing = false
    var destination: CGRect? = nil //The landing rect the presenter resolved as `closing` flipped
    var name: String? = nil
    var onFlightLanded: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    //Local view state
    @State private var angle: Double = 0
    @State private var scale: CGFloat = Entrance.startScale
    @State private var lift: CGFloat = Entrance.liftTravel
    @State private var landed = false
    @State private var hasFired = false
    @State private var buzz = LandingBuzz()

    //Flight state
    @State private var clusterFrame: CGRect = .zero //The cluster's resting global rect — the flight's coordinate bridge
    @State private var departed = false //The ONE flight flag: travel, size, clip and shadows all key on it
    @State private var handedOff = false //The copy dissolving over the identical card image beneath

    static let imageSize: CGFloat = 225
    static let ringSize: CGFloat = 275

    //A close with a resolved landing rect flies; anything else (no destination, reduced
    //motion, an unmeasured cluster) keeps the shared fade exit.
    private var canFly: Bool { destination != nil && clusterFrame != .zero && !reduceMotion }
    private var exitFading: Bool { closing && !canFly }

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            ZStack {
                Circle()
                    .fill(.accent.opacity(0.1))
                    .frame(width: Self.ringSize, height: Self.ringSize)
                    .blur(radius: 50)
                    .opacity(landed && !closing ? 1 : 0)
                    .animation(.quick, value: closing)
                    .allowsHitTesting(false)

                Circle()
                    .fill(.clear)
                    .frame(width: Self.ringSize, height: Self.ringSize)
                    .glassEffectIfAvailable(shape: Circle())
                    .opacity(closing ? 0 : 1)
                    .animation(.quick, value: closing)

                heroImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageRect.width, height: imageRect.height)
                    .clipShape(imageClip)
                    .shadow(color: .black.opacity(departed ? 0 : 0.25), radius: 2, x: 0, y: 0)
                    .shadow(color: .black.opacity(departed ? 0 : 0.15), radius: 10, x: 0, y: 0)
                    .modifier(BackfaceCulled(angle: angle))
                    .opacity(handedOff ? 0 : 1)
                    .position(x: imageRect.midX, y: imageRect.midY)
            }
            //The pin matters twice: it keeps the .position-wrapped image from inflating the
            //cluster (VStack layout, and the spin's perspective, stay exactly pre-flight),
            //and the frame is measured BELOW the transforms, so it is the resting layout rect
            //whatever the entrance is doing.
            .frame(width: Self.ringSize, height: Self.ringSize)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { clusterFrame = $0 }
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.1)
            .scaleEffect(scale * (exitFading ? ResponseCoverExit.endScale : 1))
            .offset(y: lift + (exitFading ? ResponseCoverExit.riseTravel : 0))
            .opacity(exitFading ? 0 : 1)
            .animation(ResponseCoverExit.card, value: closing)
            .task { await enter() }
            .onChange(of: closing) { _, isClosing in
                guard isClosing, canFly else { return }
                fly()
            }

            //First out, since it was last in
            Text("You’re Meeting \n \(name ?? "Arthur")!")
                .font(.title(32, .bold))
                .multilineTextAlignment(.center)
                .opacity(landed && !closing ? 1 : 0)
                .offset(y: landed ? (closing ? Spacing.xs : 0) : ResponseCoverEntrance.titleRise)
                .animation(ResponseCoverExit.title, value: closing)
        }
    }
}

//Flight geometry and choreography
extension AcceptInviteCard {

    private var heroImage: Image {
        if let flight { Image(uiImage: flight.image) } else { Image("ProfileMockB") }
    }

    //The flight's two poses in cluster space: the resting circle, and the handed-over global
    //rect brought local through the cluster's own measured origin.
    private var imageRect: CGRect {
        if departed, let destination {
            return destination.offsetBy(dx: -clusterFrame.minX, dy: -clusterFrame.minY)
        }
        let inset = (Self.ringSize - Self.imageSize) / 2
        return CGRect(x: inset, y: inset, width: Self.imageSize, height: Self.imageSize)
    }

    //Sanctioned .circular: at rest the radii are half the frame — a pixel-exact Circle()
    //inside the true-Circle glass ring; in flight they morph continuously to the event
    //card's clip (top corners CornerRadius.image, bottom edge square inside the card).
    private var imageClip: UnevenRoundedRectangle {
        let radii = departed
            ? RectangleCornerRadii(topLeading: CornerRadius.image, bottomLeading: 0,
                                   bottomTrailing: 0, topTrailing: CornerRadius.image)
            : CornerRadius.uniform(Self.imageSize / 2)
        return UnevenRoundedRectangle(cornerRadii: radii, style: .circular)
    }

    //ONE transaction moves every part of the morph. Completion is .removed, not
    //.logicallyComplete: the hand-off swaps pixels, so the copy must sit EXACTLY on the
    //landing rect — the spring's last sub-point of tail included — before it runs.
    private func fly() {
        withAnimation(AcceptFlightMotion.flight, completionCriteria: .removed) {
            departed = true
        } completion: {
            handOff()
        }
    }

    //The destination un-hides beneath the still-opaque copy with animations disabled — no
    //frame exists where the image doubles or gaps — then the copy dissolves over it.
    private func handOff() {
        var settle = Transaction()
        settle.disablesAnimations = true
        withTransaction(settle) { onFlightLanded() }
        withAnimation(AcceptFlightMotion.handOff) { handedOff = true }
    }
}

//Entrance choreography
extension AcceptInviteCard {

    private enum Entrance {
        static let spinTurns: Double = 2 //The tuning knob — 1–4 all read cleanly; spin duration scales with it so the backface blinks never strobe (each ≥ ~85ms)
        static var spinDegrees: Double { spinTurns * 360 } //Multiple of 360 by construction: always lands facing front
        static var coinSpin: Animation { .spring(duration: 0.7 + 0.2 * spinTurns, bounce: 0.15) } //Bounce ≤ 0.15: the ~4.5° over-rotation is invisible at perspective 0.1 — settle physics for the beat, not a visible wobble
        static let coinLanding = Animation.spring(duration: 1.2, bounce: 0.3) //Shared by scale + lift so the pop and the vertical catch are one beat
        static let reveal = ResponseCoverEntrance.titleReveal
        static let startScale: CGFloat = 0.6
        static let liftTravel = Spacing.xxxl
        static let commitGuard: Duration = .milliseconds(30) //One rendered frame so the start pose is committed — a flip fired inside an in-flight parent transaction snaps to destination
    }

    private func enter() async {
        guard !hasFired else { return }
        hasFired = true
        buzz.prepare() //Warm the engine now — it has the whole flight (~0.9s) before the beat
        try? await Task.sleep(for: Entrance.commitGuard)
        if Task.isCancelled { hasFired = false; return }

        if reduceMotion {
            withAnimation(Entrance.coinLanding, completionCriteria: .logicallyComplete) {
                scale = 1
                lift = 0
            } completion: {
                land()
            }
        } else {
            withAnimation(Entrance.coinSpin, completionCriteria: .logicallyComplete) {
                angle = Entrance.spinDegrees
            } completion: {
                land()
            }
            withAnimation(Entrance.coinLanding) {
                scale = 1
                lift = 0
            }
        }
    }

    //The landing beat: title + glow reveal and the buzz fire as one event
    private func land() {
        withAnimation(Entrance.reveal) { landed = true }
        buzz.play()
    }
}


#Preview {
    AcceptInviteCard()
}


//Landing buzz: a thunk plus a rumble whose decay matches the springs' settle window, and a
//scheduled tap series for choreographies that land on more than one beat
@MainActor
final class LandingBuzz {
    private var engine: CHHapticEngine?
    private var scheduled: CHHapticPatternPlayer?

    //Impacts handed over before the start finished, stamped with their choreography's zero
    private var engineRunning = false
    private var pendingImpacts: (taps: [(time: Double, intensity: Float, sharpness: Float)], zero: Date)?

    //A play() handed over before the start finished, stamped with its landing beat
    private var pendingPlay: (duration: Double, zero: Date)?

    //How late a deferred play() may still fire: within the title reveal it accompanies a
    //slightly late thunk still reads as the landing; past it, as a stray (the schedule()
    //rationale, applied to the beat at zero)
    private static let pendingPlayWindow: TimeInterval = 0.3

    /*
     Call ahead of the beat — a cold engine start adds latency or drops the first pattern.
     The start is asynchronous: the blocking start() holds the main thread for the engine's
     cold spin-up (tens of ms on device), long enough to read as launch lag on paths that
     animate the instant they call this. But a pattern started before the engine finishes is
     rejected outright — the player checks the engine's running state synchronously — so
     impacts that arrive during the warm-up wait in `pendingImpacts` and are rescheduled from
     the completion, beats shifted by the elapsed wait: the taps land on the choreography's
     clock, not a late copy of it.
     */
    func prepare() {
        guard engine == nil, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        engine?.start { [weak self] error in
            guard error == nil else { return }
            Task { @MainActor [weak self] in self?.engineDidStart() }
        }
    }

    private func engineDidStart() {
        engineRunning = true
        if let pendingPlay {
            if Date().timeIntervalSince(pendingPlay.zero) < Self.pendingPlayWindow {
                playNow(duration: pendingPlay.duration)
            }
            self.pendingPlay = nil
        }
        guard let pendingImpacts else { return }
        schedule(pendingImpacts.taps, delayed: Date().timeIntervalSince(pendingImpacts.zero))
        self.pendingImpacts = nil
    }

    /*
     The beat may land before the start finished — SendInviteScreen's flightless covers call
     this ~30ms after prepare() — and a pattern started then is rejected outright, so it
     waits in `pendingPlay` and fires from the completion instead, or is dropped once it
     would read as a stray rather than the landing.
     */
    func play(duration: Double = 1) {
        guard engine != nil else { return }
        if engineRunning {
            playNow(duration: duration)
        } else {
            pendingPlay = (duration, Date())
        }
    }

    private func playNow(duration: Double) {
        let thunk = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
        ], relativeTime: 0)

        let rumble = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
        ], relativeTime: 0, duration: duration)

        let decay = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            .init(relativeTime: 0, value: 1),
            .init(relativeTime: duration, value: 0)
        ], relativeTime: 0)

        guard let engine,
              let pattern = try? CHHapticPattern(events: [thunk, rumble], parameterCurves: [decay]),
              let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    func playImpacts(_ impacts: [(time: Double, intensity: Float, sharpness: Float)]) {
        guard engine != nil else { return }
        if engineRunning {
            schedule(impacts, delayed: 0)
        } else {
            pendingImpacts = (impacts, Date())
        }
    }

    private func schedule(_ impacts: [(time: Double, intensity: Float, sharpness: Float)], delayed: TimeInterval) {
        let events: [CHHapticEvent] = impacts.compactMap {
            let beat = $0.time - delayed
            guard beat > 0 else { return nil } //Its squash frame has passed — a late tap reads as a stray
            return CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: $0.intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: $0.sharpness)
            ], relativeTime: beat)
        }

        guard !events.isEmpty, let engine,
              let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        scheduled = player
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    //A dismissal mid-flight takes the taps still sitting on the schedule with it
    func stop() {
        pendingImpacts = nil
        pendingPlay = nil
        try? scheduled?.stop(atTime: CHHapticTimeImmediate)
        scheduled = nil
    }
}


//Hides it if facing the back
struct BackfaceCulled: ViewModifier, Animatable {
    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private var facingViewer: Bool {
        let turn = angle.truncatingRemainder(dividingBy: 360)
        let normalized = turn < 0 ? turn + 360 : turn
        return normalized <= 90 || normalized >= 270
    }

    func body(content: Content) -> some View {
        content.opacity(facingViewer ? 1 : 0)
    }
}
