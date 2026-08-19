//
//  DeclineScreen.swift
//  Scoop
//
//  Created by Art Ostin on 13/08/2026.
//

import SwiftUI

/*
 The cross is the decline button's own icon made big: it launches from the button's measured
 frame, leaps up while growing to full size, and bounces into place. The beats are lifted
 frame-accurate from the retired declined.mov (impacts at 0.48 / 0.82 / 1.03s), one restitution
 family — every hop is a true parabola under a single gravity, so the whole flight derives
 from one bounce height. Measured choreography: the curves live here, never in the motion roles.
 */
struct DeclineOverlay: View {

    //The tone the old bounce-driven fill settled on, now held flat
    private static let titleTint = Color.textPrimary.mix(with: .declineRed, by: 0.85)

    //Injected
    var closing = false
    var source: CGRect? = nil //The decline button's global frame — the cross's launch pad

    //Local view state
    @State private var play = false
    @State private var buzz = LandingBuzz()

    var body: some View {
        GeometryReader { geo in
            let launch = launchRect(in: geo)
            Color.clear
                .keyframeAnimator(initialValue: 0.0, trigger: play) { _, t in
                    choreography(at: t, launch: launch, size: geo.size)
                } keyframes: { _ in
                    //A linear clock — DeclineChoreo.pose owns every curve on it. It runs past
                    //the flight's rest to the cover's own window, so the cross's exit is a beat
                    //of the choreography rather than a state flip the keyframe body never sees.
                    KeyframeTrack { LinearKeyframe(DeclineChoreo.clockEnd, duration: DeclineChoreo.clockEnd) }
                }
        }
        .ignoresSafeArea()
        .onAppear { launchAfterCommit() }
        //The last tap sits a full second out on the schedule — a close before then must take it
        .onDisappear { buzz.stop() }
    }
}

//The staged frame: title and cross posed off one shared clock
extension DeclineOverlay {

    @ViewBuilder
    private func choreography(at t: Double, launch: CGRect, size: CGSize) -> some View {
        let pose = DeclineChoreo.pose(at: t, launch: launch, in: size)
        ZStack(alignment: .top) {
            title(progress: pose.title)
                .padding(.top, size.height * DeclineChoreo.floorFraction + Spacing.xxxl)
            cross(pose: pose)
        }
        .frame(width: size.width, height: size.height)
    }

    //Rides the same clock as the cross, so the reveal lands exactly on the first impact
    private func title(progress: Double) -> some View {
        Text("Declined")
//            .foregroundStyle(Self.titleTint)
            .font(.title(36))
            .opacity(closing ? 0 : progress)
            .offset(y: closing ? Spacing.xs : (1 - progress) * ResponseCoverEntrance.titleRise)
            //Keyed to `closing` alone — the entrance is per-frame pose, not a transition
            .animation(ResponseCoverExit.title, value: closing)
    }

    //Black at launch so it lifts straight off the button's icon, blushing red on the way up;
    //squash is bottom-anchored so every impact stays pinned to the floor line
    private func cross(pose: DeclineChoreo.Pose) -> some View {
        ZStack {
            Image("DeclineIconRed").resizable()
            Image("DeclineIconBlack").resizable()
                .opacity(1 - pose.red)
        }
        .frame(width: DeclineChoreo.finalSize, height: DeclineChoreo.finalSize)
        //Leaves on the clock, not on `closing` — shrinking toward its own centre as it thins,
        //so the two read as one pop. Centred, unlike the bottom-anchored impact squash: this
        //one is leaving the floor rather than landing on it.
        .opacity(pose.opacity)
        .rotationEffect(pose.spin)
        .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .bottom)
        .scaleEffect(pose.exitScale)
        .position(x: pose.centerX, y: pose.bottom - DeclineChoreo.finalSize / 2)
    }

    //Global → overlay space, shrunk to the icon centred in the button's circle
    private func launchRect(in geo: GeometryProxy) -> CGRect {
        let size = geo.size
        guard let source, source.width > 1 else {
            //No measured button (Invites-tab declines): the cross hops up into place instead
            return CGRect(x: (size.width - DeclineChoreo.iconSize) / 2,
                          y: size.height * DeclineChoreo.fallbackLaunchFraction,
                          width: DeclineChoreo.iconSize,
                          height: DeclineChoreo.iconSize)
        }
        let origin = geo.frame(in: .global).origin
        return CGRect(x: source.midX - origin.x - DeclineChoreo.iconSize / 2,
                      y: source.midY - origin.y - DeclineChoreo.iconSize / 2,
                      width: DeclineChoreo.iconSize,
                      height: DeclineChoreo.iconSize)
    }

    //One rendered frame so the launch pose commits before the clock starts —
    //a flight fired inside the mount's own transaction snaps to its destination
    private func launchAfterCommit() {
        Task {
            buzz.prepare() //Warm the engine now — a cold start smears the first impact
            try? await Task.sleep(for: .milliseconds(30))
            guard !Task.isCancelled else { return }
            play = true
            buzz.playImpacts(DeclineChoreo.impactTaps) //Handed over on the clock's zero
        }
    }
}


enum DeclineChoreo {

    struct Pose {
        var bottom: CGFloat   //The cross's contact point — its bottom edge
        var centerX: CGFloat
        var scaleX: CGFloat
        var scaleY: CGFloat
        var spin: Angle
        var red: Double       //0 = the button's black icon, 1 = the red cross
        var opacity: Double   //The cross's own fade-out at the tail of the cover's window
        var exitScale: CGFloat//Shrinks on the same ramp — the pop and the fade are one event
        var title: Double     //Reveal progress of the "Declined" title
    }

    //Beats in seconds on the keyframe clock, lifted from the retired video
    static let riseEnd = 0.30
    static let impact1 = 0.48
    static let impact2 = 0.82
    static let impact3 = 1.03
    static let rest = 1.15

    //One gravity ties every arc to the beats: heights follow h ∝ gap², so the later
    //bounces and the leap's fall all derive from the first bounce's height
    static let bounce1Height: CGFloat = 70
    static let bounce2Height: CGFloat = bounce1Height * ratioSq(impact3 - impact2)
    static let bounce3Height: CGFloat = bounce1Height * ratioSq(rest - impact3)
    static let leapDrop: CGFloat = 4 * bounce1Height * ratioSq(impact1 - riseEnd)

    //The resting cross: bottom edge pinned to the video's floor line
    static let floorFraction: CGFloat = 419.0 / 852.0

    /*
     The cross clears itself at the very end of the cover's window: the respond flow holds the
     cover 2s (MeetContainer's minDelay), then the canvas fades over ResponseCoverExit.canvas —
     so the screen is gone at ~2.22s. The cross shrinks and thins out on one ramp that lands
     10ms inside that, popping away a beat before the screen it sat on.
     */
    static let screenGone = 2.0 + 0.22 //minDelay + the canvas's own fade
    static let vanishEnd = screenGone - 0.01
    static let vanishStart = vanishEnd - 0.28
    static let exitScaleEnd: CGFloat = 0.75 //Shrinks toward its own centre as it goes
    static let clockEnd = screenGone + 0.05 //A little tail so the clock outlives the fade
    static let finalSize: CGFloat = 150
    static let iconSize: CGFloat = DeclineButton.iconSize //The launch size — the button's icon, exactly
    static let fallbackLaunchFraction: CGFloat = 0.78

    static let spinEnd = impact2      //One full turn, unwinding through the first bounces
    static let redFadeEnd = 0.12      //The black icon blushes red on the way up
    static let titleReveal = 0.5      //Shape of ResponseCoverEntrance.titleReveal, on this clock

    //Bottom-anchored impact squash, one short recovery window per landing
    static let squashWindow = 0.08
    static let squashDepths: [(beat: Double, depth: CGFloat)] = [
        (impact1, 0.20), (impact2, 0.12), (impact3, 0.06),
    ]

    //The buzz is the same event as the squash — one impact table, energy carried by depth, so a
    //retuned bounce can't leave the haptic behind. Sharper than the accept card's settling
    //thunk: a hard object on a hard floor. Times are relative to the clock's zero.
    static var impactTaps: [(time: Double, intensity: Float, sharpness: Float)] {
        squashDepths.map { (time: $0.beat,
                            intensity: Float($0.depth / squashDepths[0].depth),
                            sharpness: 0.9) }
    }

    static func pose(at t: Double, launch: CGRect, in size: CGSize) -> Pose {
        let floor = size.height * floorFraction
        let startScale = iconSize / finalSize
        let scale = startScale + (1 - startScale) * easeOut(t / impact1)
        let squash = squashFactor(at: t)
        let clear = easeOutCubic((t - vanishStart) / (vanishEnd - vanishStart)) //0 → 1 as it goes
        return Pose(
            bottom: bottom(at: t, from: launch.maxY, floor: floor),
            centerX: launch.midX + (size.width / 2 - launch.midX) * easeOut(t / impact1),
            scaleX: scale * (1 + (1 - squash) * 0.7), //Widens as it squashes — volume held
            scaleY: scale * squash,
            spin: .degrees(360 * easeOut(t / spinEnd)),
            red: min(max(t / redFadeEnd, 0), 1),
            opacity: 1 - clear,
            exitScale: 1 - (1 - exitScaleEnd) * clear,
            title: easeOutCubic((t - impact1) / titleReveal)
        )
    }

    //The flight path of the contact point: decelerating leap, free fall, parabolic hops
    private static func bottom(at t: Double, from start: CGFloat, floor: CGFloat) -> CGFloat {
        let apex = floor - leapDrop
        switch t {
        case ..<riseEnd:
            return start + (apex - start) * easeOut(t / riseEnd)
        case ..<impact1:
            return apex + leapDrop * easeIn((t - riseEnd) / (impact1 - riseEnd))
        case ..<impact2:
            return floor - bounce1Height * hop((t - impact1) / (impact2 - impact1))
        case ..<impact3:
            return floor - bounce2Height * hop((t - impact2) / (impact3 - impact2))
        case ..<rest:
            return floor - bounce3Height * hop((t - impact3) / (rest - impact3))
        default:
            return floor
        }
    }

    private static func squashFactor(at t: Double) -> CGFloat {
        for (beat, depth) in squashDepths where t >= beat && t < beat + squashWindow {
            return 1 - depth * sin(.pi * (t - beat) / squashWindow)
        }
        return 1
    }

    //Ballistic hop normalised to its beat: 0 at the floor, 1 at the apex
    private static func hop(_ u: Double) -> CGFloat { 4 * u * (1 - u) }

    private static func ratioSq(_ gap: Double) -> CGFloat {
        let bounce1Gap = impact2 - impact1
        return (gap / bounce1Gap) * (gap / bounce1Gap)
    }

    private static func easeOut(_ u: Double) -> Double {
        let c = min(max(u, 0), 1)
        return 1 - (1 - c) * (1 - c)
    }

    private static func easeIn(_ u: Double) -> Double {
        let c = min(max(u, 0), 1)
        return c * c
    }

    private static func easeOutCubic(_ u: Double) -> Double {
        let c = min(max(u, 0), 1)
        return 1 - (1 - c) * (1 - c) * (1 - c)
    }
}
