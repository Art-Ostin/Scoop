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
                    //A linear clock — DeclineChoreo.pose owns every curve on it. It only has
                    //to outlive the flight; the exit rides `closing`, not this clock.
                    KeyframeTrack { LinearKeyframe(DeclineChoreo.clockEnd, duration: DeclineChoreo.clockEnd) }
                }
        }
        .ignoresSafeArea()
        .onAppear { launch() }
        //The last tap sits a full second out on the schedule — a close before then must take it
        .onDisappear { buzz.stop() }
    }
}

//The staged frame: cross — and optionally the caption — posed off one shared clock
extension DeclineOverlay {

    private func choreography(at t: Double, launch: CGRect, size: CGSize) -> some View {
        let pose = DeclineChoreo.pose(at: t, launch: launch, in: size)
        return ZStack(alignment: .top) {
            if DeclineChoreo.showsTitle {
                title(progress: pose.title)
                    //Hangs off the cross's resting edge rather than a fraction of its own, so
                    //the pair stays together if the rest pose moves
                    .padding(.top, DeclineChoreo.restBottom(in: size) + Spacing.xxxl)
            }
            cross(pose: pose)
        }
        .frame(width: size.width, height: size.height)
    }

    //Rides the same clock as the cross, so the reveal lands exactly on the first impact
    private func title(progress: Double) -> some View {
        Text("Declined")
            .font(.title(36))
            .opacity(closing ? 0 : progress)
            .offset(y: closing ? Spacing.xs : (1 - progress) * ResponseCoverEntrance.titleRise)
            //Keyed to `closing` alone — the entrance is per-frame pose, not a transition
            .animation(ResponseCoverExit.title, value: closing)
    }

    private func cross(pose: DeclineChoreo.Pose) -> some View {
        ZStack {
            Image("DeclineIconRed").resizable()
            Image("DeclineIconBlack").resizable()
                .opacity(1 - pose.red)
        }
        .frame(width: DeclineChoreo.finalSize, height: DeclineChoreo.finalSize)
        .opacity(closing ? 0 : 1)
        .scaleEffect(closing ? DeclineChoreo.exitScaleEnd : 1)
        .animation(DeclineChoreo.vanish, value: closing)
        .rotationEffect(pose.spin)
        .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .bottom)
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

    /*
     Fired straight from onAppear — no commit guard. The keyframe clock doesn't interpolate
     between committed states (every frame IS pose(t)), so all the trigger needs is to flip
     *after* the mount's own evaluation, which onAppear guarantees; the async hop + 30ms sleep
     that used to sit here cost ~4 frames of the cross parked on the button. The one rule left:
     never move the flip into the first evaluation itself — an initial `play = true` means the
     trigger never changes and the flight never runs.
     */
    private func launch() {
        buzz.prepare() //Non-blocking — the engine warms while the cross is still climbing
        play = true
        buzz.playImpacts(DeclineChoreo.impactTaps) //Handed over on the clock's zero
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
        var title: Double     //Reveal progress of the "Declined" caption
    }

    /*
     Whether the word "Declined" sits under the cross. Off: the cross alone carries the whole
     message, resting dead-centre. On: it reads as a captioned moment and the cross keeps its
     centred rest with the word hung beneath — flip this and re-check the pair's balance, since
     nothing re-centres the group for the caption's height.
     */
    static let showsTitle = false

    /*
     Beats in seconds on the keyframe clock, taken at `tempo`. The launch and first bounce are
     lifted from the retired video; the tail was A/B-retuned (2026-08-19) to a CONSTANT 0.70
     restitution — each hop's gap is 0.70× the previous, so each bounce keeps the same fraction
     of its height (70 → 34 → 17pt), the decay a real object has. The video's own ladder
     (0.62/0.57) compressed at this tempo into a stutter, and an uneven ladder (0.75/0.55)
     read as the object suddenly dying on its last hop. Heights always derive from gap *ratios*
     (see ratioSq), so any beat choice stays one gravity family — keep the ladder constant,
     and repace the whole flight only through `tempo`.
     */
    static let tempo = 0.72
    static let riseEnd = 0.30 * tempo
    static let impact1 = 0.48 * tempo
    static let impact2 = 0.82 * tempo
    static let impact3 = (0.82 + 0.34 * 0.70) * tempo
    static let rest = (0.82 + 0.34 * 0.70 + 0.34 * 0.70 * 0.70) * tempo

    //One gravity ties every arc to the beats: heights follow h ∝ gap², so the later
    //bounces and the leap's fall all derive from the first bounce's height
    static let bounce1Height: CGFloat = 70
    static let bounce2Height: CGFloat = bounce1Height * ratioSq(impact3 - impact2)
    static let bounce3Height: CGFloat = bounce1Height * ratioSq(rest - impact3)
    static let leapDrop: CGFloat = 4 * bounce1Height * ratioSq(impact1 - riseEnd)

    //The resting cross sits dead-centre: its bottom edge — the flight's contact point —
    //lands half a cross below the screen's midline
    static func restBottom(in size: CGSize) -> CGFloat { (size.height + finalSize) / 2 }

    /*
     The cross holds whole until the screen actually starts to go, then pops — shrinking toward
     its own centre as it thins, so the two read as one event instead of the plain crossfade the
     rest of the cover wears. It leaves on `closing` rather than on this clock: timed off the
     clock it cleared itself *before* the dismissal, and landed on a different beat in each
     respond flow's hold.
     */
    //A pop, not a slow shrink: front-loaded and short so the cross is gone well before the
    //plane tears down on ResponseCoverExit.duration, which would otherwise clip the tail.
    static let vanish = Animation.easeOut(duration: 0.16)
    static let exitScaleEnd: CGFloat = 0.22 //Collapses toward its own centre as it goes

    //The clock has to outlive whatever runs longest on it: the flight plus its settle absorb,
    //and — when the caption shows — its reveal, which starts at impact1 and does NOT scale
    //with tempo. Without this guard a low enough tempo would silently truncate a tail mid-play.
    static let clockEnd = max(rest + settleWindow, showsTitle ? impact1 + titleReveal : 0) + 0.05
    static let finalSize: CGFloat = 150
    static let iconSize: CGFloat = DeclineButton.iconSize //The launch size — the button's icon, exactly
    static let fallbackLaunchFraction: CGFloat = 0.78

    static let spinEnd = impact2      //One full turn, unwinding through the first bounces
    static let redFadeEnd = 0.12 * tempo //The black icon blushes red on the way up

    //Deliberately unscaled by tempo — it mirrors ResponseCoverEntrance.titleReveal, the shape
    //the accept card's title wears, and the two should read as the same beat
    static let titleReveal = 0.5

    /*
     Bottom-anchored impact squash. Deformation is a floor phenomenon: each recovery window is
     capped to end early in the following hop, so the cross never rides the air half-squashed —
     the old fixed window spent two-thirds of the smallest hop still recovering. The final
     touch-down gets its own soft absorb over `settleWindow`: without it the cross arrives at
     landing speed and freezes dead, which read as an abrupt stop.
     */
    static let settleWindow = 0.06
    static let squashDepths: [(beat: Double, depth: CGFloat, window: Double)] = [
        (impact1, 0.20, min(0.08 * tempo, 0.4 * (impact2 - impact1))),
        (impact2, 0.12, min(0.08 * tempo, 0.4 * (impact3 - impact2))),
        (impact3, 0.07, min(0.08 * tempo, 0.4 * (rest - impact3))),
        (rest, 0.03, settleWindow),
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
        let floor = restBottom(in: size)
        let startScale = iconSize / finalSize
        let scale = startScale + (1 - startScale) * easeOut(t / impact1)
        let squash = squashFactor(at: t)
        return Pose(
            bottom: bottom(at: t, from: launch.maxY, floor: floor),
            centerX: launch.midX + (size.width / 2 - launch.midX) * easeOut(t / impact1),
            scaleX: scale * (1 + (1 - squash) * 0.7), //Widens as it squashes — volume held
            scaleY: scale * squash,
            spin: .degrees(360 * easeOut(t / spinEnd)),
            red: min(max(t / redFadeEnd, 0), 1),
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
        for (beat, depth, window) in squashDepths where t >= beat && t < beat + window {
            return 1 - depth * sin(.pi * (t - beat) / window)
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
