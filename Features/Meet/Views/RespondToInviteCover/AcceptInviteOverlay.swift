//
//  AcceptInviteOverlay.swift
//  Scoop
//
//  Created by Art Ostin on 13/08/2026.
//

import SwiftUI
import CoreHaptics

struct AcceptInviteCard: View {

    //Injected
    var closing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    //Local view state
    @State private var angle: Double = 0
    @State private var scale: CGFloat = Entrance.startScale
    @State private var lift: CGFloat = Entrance.liftTravel
    @State private var landed = false
    @State private var hasFired = false
    @State private var buzz = LandingBuzz()

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            ZStack {
                Circle()
                    .fill(.accent.opacity(0.1))
                    .frame(width: 275, height: 275)
                    .blur(radius: 50)
                    .opacity(landed ? 1 : 0)
                    .allowsHitTesting(false)

                Circle()
                    .fill(.clear)
                    .frame(width: 275, height: 275)
                    .glassEffectIfAvailable(shape: Circle())
                    .opacity(closing ? 0 : 1)
                    .animation(.quick, value: closing)

                Image("ProfileMockB")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 225, height: 225)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 0)
                    .modifier(BackfaceCulled(angle: angle))
            }
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.1)
            .scaleEffect(scale * (closing ? ResponseCoverExit.endScale : 1))
            .offset(y: lift + (closing ? ResponseCoverExit.riseTravel : 0))
            .opacity(closing ? 0 : 1)
            .animation(ResponseCoverExit.card, value: closing)
            .task { await enter() }

            //First out, since it was last in
            Text("You’re Meeting \n Arthur!")
                .font(.title(32, .bold))
                .multilineTextAlignment(.center)
                .opacity(landed && !closing ? 1 : 0)
                .offset(y: landed ? (closing ? Spacing.xs : 0) : ResponseCoverEntrance.titleRise)
                .animation(ResponseCoverExit.title, value: closing)
        }
    }
}

//Entrance choreography
extension AcceptInviteCard {

    /*
     One physical event: the card arrives from below with momentum, spins down, and catches
     itself facing front. The rotation spring's first target-crossing (~0.86s) is the landing
     beat — scale and lift peak their overshoot there, the haptic fires there (via
     .logicallyComplete), and the title + glow reveal ride the same flip. Settled by ~1.2s.
     */
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

    //Call ahead of the beat — a cold engine start adds latency or drops the first pattern
    func prepare() {
        guard engine == nil, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        try? engine?.start()
    }

    func play(duration: Double = 1) {
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
        let events = impacts.map {
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: $0.intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: $0.sharpness)
            ], relativeTime: $0.time)
        }

        guard let engine,
              let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        scheduled = player
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    //A dismissal mid-flight takes the taps still sitting on the schedule with it
    func stop() {
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
