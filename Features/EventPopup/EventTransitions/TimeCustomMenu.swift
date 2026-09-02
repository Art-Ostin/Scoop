//AI Code Beware!
//  SelectTypeTest.swift
//  Scoop
//
//  Created by Art Ostin on 11/06/2026.
//
//  TimeCustomMenu — a reusable recreation of the native menu presentation that
//  accepts fully arbitrary content. On iOS 26+ it reproduces the Liquid Glass
//  menu: a glass bubble that morphs ("blooms") out of the label, and morphs
//  back into it on dismissal. Pre-26 it falls back to the classic scale/fade.
//
//  Usage:
//      TimeCustomMenu {
//          // any SwiftUI view / layout
//      } label: {
//          // the trigger view
//      }
//
//      Pass labelCornerRadius if the label is not a capsule, so the closing
//      lens lands exactly on its shape:
//      TimeCustomMenu(cornerRadius: 20, labelCornerRadius: 25) { ... } label: { ... }
//
//  Inside the content closure:
//      .timeCustomMenuItem { ... }        — row participates in drag-to-select highlight,
//                                       runs its action and dismisses on selection.
//      @Environment(\.timeCustomMenuDismiss) — programmatic dismissal from content. A tap
//                                       on the menu's own content never auto-dismisses;
//                                       call this action (or use .timeCustomMenuItem) to
//                                       close it. Tapping outside still dismisses.
//
//  ── iOS 26 lens-morph mechanics (frame-matched to the stock menu) ───────────
//  Measured from the native menu's presentation layers at 120Hz: on touch the
//  label line becomes the glass lens (SWALLOWING the text, whose copy dissolves
//  across nearly the whole flight) and blooms STRAIGHT into the rounded-rect
//  platter — no separate circle phase. The width pinches slightly while the
//  body rises, then re-expands trailing the height; the alignment edge stays
//  pinned; the trailing edge bows toward the flight mid-way; the content sits
//  full-size on its resting rect, MASKED to the glass — the lens uncovers it
//  as it blooms across the rect. The platter COVERS the
//  button's rect (near edges flush, no gap). Dismissal is the reverse; the
//  label re-materializes inside the landing capsule as the glass melts off it.
//  Implementation: ONE persistent glass view whose measured-curve frame/radius/
//  content are interpolated by an Animatable modifier (MenuLensMorph) under
//  withAnimation. The real label hides while the lens carries its copy (it IS
//  the menu, like native).
//  No glass transitions are used — verified broken/limited on iOS 26.0:
//   • glassEffectID same-ID "replace" swaps render as an INSTANT swap.
//   • The liquid metaball merge only occurs between comparably-sized glass
//     shapes (toolbar-button territory), never button → menu platter.
//   • .clipShape on a glass view kills its transitions.
//   • Glass geometry in a container follows LAYOUT positions — place glass
//     views with padding, never .offset.
//   • State driving an appearance animation must escape the first layout pass
//     (deferred one runloop turn) or it snaps with no animation.
//
//  ── Fidelity notes / limitations ─────────────────────────────────────────────
//  The real menu is drawn by private UIKit classes whose exact spring, material
//  and shadow values are not public; `TimeCustomMenuSpec` holds tuned approximations
//  (community references converge on .bouncy(≈0.4) for glass morphs).
//   • The platter uses .glassEffect(.regular); the system menu material adds
//     private vibrancy/shadow treatment that public glass lacks.
//   • Platter corner radius defaults to a 26pt stand-in for the system's
//     container-concentric radius and can be overridden per menu.
//   • Platter content is not hard-clipped to the glass shape (.clipShape breaks
//     glass transitions); keep menu content padded inside its corners.
//   • The menu is presented in its own transparent UIWindow (level .alert + 1),
//     like UIKit does, so it can never be clipped by scroll views, the nav stack
//     or the tab bar. Anchor frames assume the app window fills the scene
//     (always true on iPhone; iPad floating windows may offset slightly).
//   • Opens on native's touch-down — the menu presents the instant the finger
//     lands, and the same continuing touch drives the native press-drag-release
//     selection. Accepted trade-off (exactly like a native Menu label): a drag
//     that STARTS on the label — a pager swipe, the invite card's swipe-dismiss —
//     opens the menu instead of scrolling.
//

import SwiftUI
import UIKit

// MARK: - Demo / harness

struct TimeCustomMenuBuilder: View {

    @State private var flavour = "Vanilla"
    @State private var doubleScoop = false

    var body: some View {
        VStack {
            HStack {
                classicMenu
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                freeformMenu
            }
        }
        .padding(24)
        .background(Color.appCanvas)
    }

    /// Looks like a stock pull-down menu, built from arbitrary rows.
    private var classicMenu: some View {
        TimeCustomMenu {
            VStack(spacing: 0) {
                menuRow("Edit Event", icon: "pencil") { }
                Divider()
                menuRow("Share", icon: "square.and.arrow.up") { }
                Divider()
                HStack {
                    Text("Double Scoop").font(.body(15))
                    Spacer()
                    Toggle("", isOn: $doubleScoop).labelsHidden()
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                Divider()
                menuRow("Delete", icon: "trash", role: .destructive) { }
            }
            .frame(width: TimeCustomMenuSpec.standardWidth)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 24))
                .foregroundStyle(Color.successGreen)
                .padding(8)
        }
    }

    /// Arbitrary layout: a reaction bar over a colour grid — impossible in a native Menu.
    private var freeformMenu: some View {
        TimeCustomMenu {
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    ForEach(["🍦", "🍨", "🍧", "🍫", "🍓"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 28))
                            .timeCustomMenuItem { flavour = emoji }
                    }
                }
                Divider()
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(44)), count: 4), spacing: 10) {
                    ForEach([Color.successGreen, .accent, .warningYellow,
                             .border, .textTertiary, .appCanvas, .dangerRed], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 38, height: 38)
                            .timeCustomMenuItem { }
                    }
                }
            }
            .padding(14)
        } label: {
            Text("Pick \(flavour)")
                .font(.body(16, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.successGreen, in: Capsule())
        }
    }

    /// iOS 26 menu row layout: glyph on the leading edge.
    private func menuRow(_ title: String, icon: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 22)
            Text(title).font(.body(15))
            Spacer()
        }
        .foregroundStyle(role == .destructive ? Color.dangerRed : .primary)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .timeCustomMenuItem(action: action)
    }
}

#Preview {
    TimeCustomMenuBuilder()
}

// MARK: - Spec (approximations of the private native values)

enum TimeCustomMenuSpec {

    #if DEBUG
    /// Launch with "-timeMenuSlowMotion" to stretch the morph clocks 10× —
    /// simulator recordings drop frames at real speed, so animation review
    /// happens slowed (same pattern as ProfileZoomTransition's -morphSlowMotion).
    /// "-timeMenuTimeScale N" picks a custom factor.
    static let slowMotion = ProcessInfo.processInfo.arguments.contains("-timeMenuSlowMotion")
    static let timeScale: Double = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-timeMenuTimeScale"), i + 1 < args.count,
           let n = Double(args[i + 1]), n >= 1 {
            return n
        }
        return slowMotion ? 10 : 1
    }()
    #else
    static let timeScale: Double = 1
    #endif

    // ── iOS 26 Liquid Glass lens morph ──
    /// Default platter corner radius — stand-in for the system's concentric radius.
    static let platterCornerRadius = CornerRadius.customMenu
    /// Glass shapes closer than this blend/morph inside the container.
    static let morphSpacing: CGFloat = 40
    /// Peak refraction blur while the label is being swallowed (matched
    /// against device recordings of the native lens).
    static let lensBlur: CGFloat = 8
    // Device-measured open morph (frame-diffed 59fps recording, 2026-08-04):
    // the shape is born AS the label text's rect and inflates UP-AND-LEFT as a
    // near-perfect CIRCLE (measured 178×181 → 235×235), its trailing edge
    // pinned to the label's trailing edge the entire flight; the platter width
    // then arrives on its own later clock (`widthBloom`) while corners resolve
    // and material/content/label-occlusion ride that same platterize phase.
    // The label itself stays PINNED in place — it never rides the lens.
    /// The label IMPLODES into the collapse point together with the glass: it
    /// shrinks and is dragged in fast, MASKED to the lens the whole way — never
    /// a glimpse or a blur trail outside the glass — its dissolve completing
    /// INSIDE the droplet (the close re-emerges it in reverse). The
    /// ride completes at this rise progress...
    static let labelRideEnd: CGFloat = 0.22
    /// ...shrinking down to this scale as it merges into the droplet.
    static let labelRideScale: CGFloat = 0.25
    /// The CIRCLE carries the whole flight (re-fitted against the 2026-08-06
    /// 50fps device frames): it inflates to nearly the platter's SHORT SIDE
    /// and holds that circular shape — the rect arrives only in the late
    /// FLOWERING (`flowerStart`), never during the rise.
    static let ballArriveScale: CGFloat = 0.95
    /// The fraction of the platterize clock where the held circle starts to
    /// flower into the platter rect. Before this the lens is a (distorted)
    /// circle; after it the corners resolve, the sides bulge and settle, and
    /// the rows are uncovered. Device: circle holds ~150ms of a ~300ms open.
    static let flowerStart: CGFloat = 0.55
    /// Barrel beat: mid-flowering the sides bow OUTWARD past the lerp by this
    /// fraction and settle — the liquid bulge the device frames show as the
    /// square opens.
    static let flowerBulge: CGFloat = 0.045
    /// The flowering's FREE edge (the one opening away from the label)
    /// OVERSHOOTS its resting position by this fraction of the platter's
    /// height and settles back — device: the native top edge rises ~19pt past
    /// its rest (8% of the platter) and bounces down while the label-side
    /// edge stays pinned. The width spring's residual (~3%) reads as nothing;
    /// this pulse is what makes the open land with the native's bounce.
    static let flowerOvershoot: CGFloat = 0.08
    /// The lens is CLEAR glass at birth and gains the platter's regular
    /// material across this platterize window — the device circle is already
    /// heavily frosted while still round (+95ms), well before the flowering.
    static let glassMaterialRange: ClosedRange<CGFloat> = 0.12...0.5
    /// Content opacity's short on-ramp, straddling `flowerStart`: the circle
    /// flies EMPTY (device — the ball travels frosted and bare), the rows
    /// snapping to full strength just as the flowering begins. From there the
    /// lens MASK alone carries the reveal — the glass uncovers full-size,
    /// full-opacity rows (device frames: the row text is crisp and clipped by
    /// the glass edges, never faded in place or squashed).
    static let contentArriveRange: ClosedRange<CGFloat> = 0.45...0.6
    /// The glass presence follows the native's measured material fade-in
    /// (CASDFLayer alpha: .18 at p≈.13, .32 at .24, .71 at .59, full ~.9):
    /// presence = p^exponent — the lens is BARELY THERE at birth and
    /// materializes across the whole flight, reversed on close. This fade, not
    /// the geometry, carries most of the native's "liquid" feel; a constant
    /// floor (tried at 0.55) reads as a rigid white blob from frame one.
    static let glassPresenceExponent: Double = 0.75
    /// The CLEAR lens rises on its own faster clock: the device droplet is a
    /// crisp refractive lens by ~20ms into the flight (frame-diffed
    /// 2026-08-06), while only the FROST obeys the slow material ramp above.
    /// Still ~0 on the birth frame, so the label isn't washed white pre-lift.
    static let clearPresenceExponent: Double = 0.4
    /// The RISE spring — drives the circle's flight, fitted to the device
    /// recording's per-frame progress (0.10 → 0.38 → 0.63 → 0.76…): it
    /// ACCELERATES into the flight — a slow first frame (which is what keeps
    /// the tiny row-collapse circle VISIBLE for a beat), a rocketing second and
    /// third, then the decelerating settle with ~+2% overshoot. A high
    /// initialVelocity (tried 20) completes the collapse sub-frame — invisible,
    /// reading as "expands into a circle straight away". NOTE: the device menu
    /// is NOT the simulator's menu — never fit to the sim.
    static let bloomOpen = Animation.interpolatingSpring(
        Spring(response: 0.32 * timeScale, dampingRatio: 0.80), initialVelocity: 4 / timeScale)
    /// The BLOSSOM — the droplet opens into the platter, corners resolving and
    /// material/content arriving with it. Starts WITH the throw (no delay — a
    /// delayed start reads as a two-step stop-start open) on a longer soft
    /// spring: its early progress is naturally tiny, so the ball beat still
    /// reads, but the expansion never pauses — one continuous fluid open that
    /// unfolds with momentum, overshoots ~3% and settles (the end bounce).
    static let widthBloom = Animation.spring(response: 0.46 * timeScale, dampingFraction: 0.76)
    /// Keeps the glass platter attached to content whose height changes while
    /// the menu is open (for example, when a pager reveals a taller page).
    static let reflowResize = Animation.spring(duration: 0.2)
    /// Aborting a HALF-OPEN menu (release-outside before the bloom lands)
    /// reverses the open geometry on this back-loaded clock. The full droplet
    /// close below assumes it starts from the settled platter.
    static let bloomClose = Animation.easeIn(duration: 0.26)
    // ── The droplet close (frame-fitted to the default menu, 2026-08-06 20:10
    //    device recording) ── NOT the open in reverse. Three stages on ONE
    //    linear clock:
    //   the shrink (0→30%): frost, fill and rows defrost off the collapsing
    //     platter while it shrinks FAST — no shape warp, a plain rounded rect —
    //     into a small line-height capsule at the CENTRE of the label line
    //     (device: platter → capsule in ~85ms);
    //   the spread (30→60%): the mini capsule widens FROM THE CENTRE OUTWARDS
    //     across the line into the landing capsule, the text revealed through
    //     (and refracted by) the widening glass — its mask IS the reveal;
    //   the settle (60→100%): the text emerges displaced a few points DOWN —
    //     pushed by the arriving glass — and rises to rest (the down-and-up
    //     bounce, device: ~3pt low at first legibility, level by ~85%) while
    //     the lens melts off it.
    /// One linear clock so the stage curves own every channel.
    static let closeMorph = Animation.linear(duration: closeMorphDuration)
    /// The rows dissolve INSIDE the collapsing circle, gone by here.
    static let closeContentFadeEnd: Double = 0.28
    /// Beat 1 — the platter is a fully ROUND, still-large circle by here
    /// (22:11 reference: round at ~200pt within ~65ms; early roundness is
    /// what lets the speed read as liquid instead of aggressive)…
    static let closeCircleEnd: Double = 0.16
    /// …its diameter as a fraction of the platter's short side…
    static let closeCircleScale: CGFloat = 0.58
    /// Beat 2 — …and has condensed onto the text line's centre by here…
    static let closeCollapseEnd: Double = 0.33
    /// …arriving as a small pale capsule this wide…
    static let closeArriveWidth: CGFloat = 76
    /// Reverse `opacityPop`: the text EXPANDS WITH the glass — born small and
    /// faint at the line's centre, scaling up and brightening on exactly the
    /// spread's own curve, so glass and text inflate as one thing (never a
    /// static line uncovered by a sliding edge).
    static let closeTextGrowFrom: CGFloat = 0.4
    /// Beat 3's reveal curve — the SelectType (DropdownCustomMenu) landing
    /// pop, sampled onto the close clock: a damped spring LAUNCHED with the
    /// condense's momentum (no apex dwell — the Dropdown's measured
    /// stop-then-relaunch hitch), overshooting ~11% of the travel (≈5–6% of
    /// the landed size, its measured organic pop) and blending to land
    /// exactly at 1 for the label swap. Glass AND text ride it together —
    /// the whole reveal pops as one thing, like the Dropdown's label.
    static func closeReveal(_ t: CGFloat) -> CGFloat {
        let a: CGFloat = 3.22, b: CGFloat = 4.6, c: CGFloat = 0.5
        let raw = 1 - exp(-a * t) * (cos(b * t) + c * sin(b * t))
        let land = ((t - 0.85) / 0.15).clamped(to: 0...1)
        let blend = land * land * (3 - 2 * land)
        return raw + (1 - raw) * blend
    }
    /// The bounce: the text emerges this far BELOW its rest — carried down by
    /// the landing glass — and rises level (zero by `closeTextSettleEnd`, so
    /// the copy lands pixel-identical before the real label is restored).
    static let closeTextDrop: CGFloat = 3
    static let closeTextSettleEnd: Double = 0.72
    /// The milky wash (frost + platterFill) does NOT defrost early: it stays
    /// on the collapsing circle — content ghosting inside it — and lingers as
    /// the soft pill behind the revealed text, fading across this window.
    static let closeWashFade: ClosedRange<Double> = 0.35...0.85
    /// The clear lens melts through the reveal and the wash fade, gone by
    /// `closeLensFadeEnd` — never a full-strength lens popping at the end.
    static let closeLensFadeStart: Double = 0.50
    static let closeLensFadeEnd: Double = 0.95
    /// The landing capsule stands this much taller than the label rect.
    static let closeLandHeightPad: CGFloat = 8
    /// The row-collapse beat: the label capsule contracts into a TINY circle ON
    /// the text within the first frames of the rise ("extremely quickly")...
    static let collapseEnd: CGFloat = 0.10
    /// ...this small (device-measured ~40pt lens on the word itself)...
    static let collapseCircleDiameter: CGFloat = 40
    /// ...offset from the label's centre TOWARD the platter's centre in X —
    /// clamped to this fraction of the label's own width...
    static let collapsePullX: CGFloat = 0.25
    /// ...and lifted JUST PAST the text on the platter's side (device: the
    /// birth droplet forms immediately above the label, never on it) by this
    /// many label-heights.
    static let collapseLift: CGFloat = 1.0
    /// Comet-tail taper: trailing control points pinch toward the travel axis
    /// by this fraction — the tail narrows while the leading dome stays full.
    static let dragPinch: CGFloat = 0.22
    /// Aerodynamic DRAG: the ball's tail lags behind — the leading edge stays
    /// on the spring's path while the trailing side stretches BACKWARD along
    /// the travel line (a comet/teardrop), by this fraction of the ball's
    /// diameter at peak speed, relaxing round at either end. Symmetric
    /// elongation (tried) just reads as an oval — the drag must be one-sided.
    /// Device mid-growth aspect ≈ 1.09 → ~0.15 of the (now platter-sized)
    /// circle; the old 0.45 belonged to the small 0.45-scale ball.
    static let dragStretch: CGFloat = 0.15
    /// After the close morph lands on the button, the real label is restored
    /// under the lens's pixel-identical copy and the copy melts off it.
    static let lensFadeOut = Animation.easeOut(duration: 0.10)
    /// Close morph length before the label is restored and the residual lens
    /// melts off it. Deliberately stretched past the device reference (22:11:
    /// text readable ~230ms, wash gone ~400ms) — the native pace read too snappy
    /// here. Every beat above is a fraction of this clock, so they all stretch
    /// with it and the choreography's proportions are unchanged.
    static let closeMorphDuration: TimeInterval = 0.50 * timeScale
    static let lensFadeDuration: TimeInterval = 0.10 * timeScale
    /// An opaque platter fill (`TimeCustomMenu.platterFill`) ramps in across the
    /// eruption: nothing at birth, where the lens is pure refraction over the label
    /// line and a fill would white it out, arriving WITH the frost while the
    /// circle grows (same window as `glassMaterialRange`). Reversed on close with
    /// the rest of the morph, so the fill only ever exists mid-flight.
    static let platterFillRange: ClosedRange<CGFloat> = 0.12...0.5

    // ── Pre-26 fallback (classic menu) ──
    /// Scale the menu collapses to at the anchor point when hidden.
    static let collapsedScale: CGFloat = 0.2
    /// Opening scale spring — slight overshoot like the classic platter.
    static let openScale = Animation.spring(response: 0.42, dampingFraction: 0.8)
    /// Opacity ramps in faster than the scale settles.
    static let openFade = Animation.easeOut(duration: 0.2)
    /// Closing is quicker and never bounces.
    static let closeScale = Animation.spring(response: 0.3, dampingFraction: 1)
    static let closeFade = Animation.easeIn(duration: 0.18)
    /// Window teardown after the classic close animation has finished.
    static let teardownDelay: TimeInterval = 0.32

    // ── Shared metrics ──
    /// Standard native menu width; opt in with .frame(width:) on your content.
    static let standardWidth: CGFloat = 250
    /// Gap between the label and the menu edge.
    static let anchorGap: CGFloat = 6
    /// Fine-tuning nudge applied to the final placement: shifts the platter
    /// right and down from its anchor-aligned position.
    static let placementOffsetX: CGFloat = 19 //Surgical so central
    static let placementOffsetY: CGFloat = -84
    /// Minimum distance kept from safe-area edges.
    static let screenMargin: CGFloat = 9
    /// Drags shorter than this count as a tap on the label (menu stays open).
    static let tapSlop: CGFloat = 10
    /// Touch-down open waits this long for the finger to prove it isn't a
    /// pan (the label can sit on a pager row, and the invite card behind it
    /// dismisses on a vertical drag): stationary touches open after this beat
    /// — imperceptible on a press — fast taps open at release, and any move
    /// past `tapSlop` cancels the open so the pan (pager scroll or card
    /// dismiss drag, whichever owns that axis) takes the gesture instead of
    /// both firing. UIKit's own delaysContentTouches disambiguation, in miniature.
    static let openStillDelay: TimeInterval = 0.08

    static let highlightFill = Color(.tertiarySystemFill)
    /// iOS 26 rows highlight with a rounded, inset shape rather than full-bleed.
    static let highlightCornerRadius = CornerRadius.customMenuRowHighlight
    static let pressedLabelOpacity: CGFloat = 0.5
    /// Release fade for the dim-only press (native labels dim, never shrink).
    /// The dim itself lands with no animation — the same frame as touch-down —
    /// so the label reads pressed the instant the menu starts to bloom.
    static let pressDimRelease = Animation.easeOut(duration: 0.15)
}

// MARK: - TimeCustomMenu

/// Which edge of the label the menu aligns its corresponding edge to.
/// `.automatic` picks the edge by whichever screen half the label's centre sits
/// in (the native default) — use `.leading` / `.trailing` when the label is wide
/// enough that its centre is ambiguous (e.g. a full-width row with a Spacer).
enum TimeCustomMenuAlignment {
    case leading, trailing, automatic
}

/// Which side of the label the menu opens toward. `.automatic` follows the
/// native rule — the roomier side when the menu fits on both, else the side
/// that fits; `.above` / `.below` pin the side for call sites with a designed
/// position (the morph adapts its travel and flowering direction either way).
enum TimeCustomMenuVerticalPlacement {
    case automatic, above, below
}

struct TimeCustomMenu<Content: View, Label: View>: View {

    /// Corner radius of the expanded menu platter.
    var cornerRadius: CGFloat
    @ViewBuilder var content: () -> Content
    @ViewBuilder var label: () -> Label
    /// Corner radius of the label's own shape so the closing lens lands on it
    /// exactly (defaults to a capsule). Mismatched corners read as a snap.
    var labelCornerRadius: CGFloat?
    /// Opaque fill painted over the platter glass, in the lens's own shape, for menus
    /// that bloom over imagery — plain glass there just shows the photo through the
    /// menu's own type. Ramped in with the morph (see `platterFillRange`) so it exists
    /// only while the menu is open, never on the label at rest. Nil keeps pure glass.
    /// It covers the glass rather than tinting it: the menu's window follows the device
    /// appearance, so glass laid on top would grey the fill out on a dark-mode device.
    var platterFill: Color?
    /// Explicit (global) rect the lens is born on and collapses back to, overriding
    /// the label's own measured frame. Use when the label is larger than what should
    /// visually carry the morph — e.g. a multi-item pager whose lens should hug just
    /// its first item, pinned to that item's bounds (no surrounding padding or chevron).
    /// Pair it with a label that renders only that item while in the morph overlay.
    var morphAnchor: CGRect?
    /// Rough platter size used to bloom on the very first tap, before any live
    /// measure exists (later opens reuse the cached measured size). Without it, the
    /// first-ever open falls back to blooming after the content has been measured.
    var estimatedContentSize: CGSize?
    /// Keeps measuring while presented so the platter follows content reflow.
    /// Leave off for fixed-height or expensive menu content.
    var tracksContentSizeChanges: Bool
    /// Which label edge the menu aligns to (see `TimeCustomMenuAlignment`).
    var alignment: TimeCustomMenuAlignment
    /// Which side of the label the menu opens toward (see
    /// `TimeCustomMenuVerticalPlacement`).
    var verticalPlacement: TimeCustomMenuVerticalPlacement
    /// Nudge applied to the final placement (positive = right / down). Defaults
    /// to the spec values; override per call site to fine-tune.
    var placementOffset: CGSize
    /// Optional binding kept in sync with the menu's presentation state.
    var isOpen: Binding<Bool>?
    /// A one-shot programmatic open, for a control that sits OUTSIDE the label (the invite
    /// rows' "When" caption). Set it `true` and the menu presents from the label's own frame,
    /// exactly as touch-down on the label would; the menu clears it so the same binding can
    /// fire again. It is not a presentation state — that's `isOpen`.
    var openRequest: Binding<Bool>?
    /// Fires the instant the menu is requested to open (on touch-down, before the
    /// bloom animation) — not when the content view appears, so there's no
    /// morph lag. Use this instead of `.onAppear` on the content.
    var onOpen: (() -> Void)?
    /// Fires the instant dismissal is requested (any path: tap-away, drag-release,
    /// selection, programmatic) — not when the close morph + teardown finishes, so
    /// there's no ~0.58s lag. Use this instead of `.onDisappear` on the content.
    var onClose: (() -> Void)?

    @Environment(\.scenePhase) private var scenePhase
    @State private var controller = TimeCustomMenuController()
    @State private var labelFrame: CGRect = .zero
    //Touch-down press dim, shown only when the menu could NOT present (no active
    //scene): on the normal path the lens swallows the label at full brightness one
    //frame after touch-down, so dimming first would flash 0.5 → 1 on every open.
    @State private var pressed = false
    /// The armed touch-down open, waiting out `openStillDelay`.
    @State private var pendingOpen: Task<Void, Never>?

    init(cornerRadius: CGFloat = TimeCustomMenuSpec.platterCornerRadius,
         labelCornerRadius: CGFloat? = nil,
         platterFill: Color? = nil,
         morphAnchor: CGRect? = nil,
         estimatedContentSize: CGSize? = nil,
         tracksContentSizeChanges: Bool = false,
         alignment: TimeCustomMenuAlignment = .automatic,
         verticalPlacement: TimeCustomMenuVerticalPlacement = .automatic,
         placementOffsetX: CGFloat = TimeCustomMenuSpec.placementOffsetX,
         placementOffsetY: CGFloat = TimeCustomMenuSpec.placementOffsetY,
         isOpen: Binding<Bool>? = nil,
         openRequest: Binding<Bool>? = nil,
         onOpen: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder label: @escaping () -> Label) {
        self.cornerRadius = cornerRadius
        self.labelCornerRadius = labelCornerRadius
        self.platterFill = platterFill
        self.morphAnchor = morphAnchor
        self.estimatedContentSize = estimatedContentSize
        self.tracksContentSizeChanges = tracksContentSizeChanges
        self.alignment = alignment
        self.verticalPlacement = verticalPlacement
        self.placementOffset = CGSize(width: placementOffsetX, height: placementOffsetY)
        self.isOpen = isOpen
        self.openRequest = openRequest
        self.onOpen = onOpen
        self.onClose = onClose
        self.content = content
        self.label = label
    }

    var body: some View {
        // While the menu is open, keep the controller's rendered label in sync
        // with the latest state so the dismiss morph shrinks showing the
        // post-selection value instead of the snapshot taken when it opened.
        let _ = syncPresentedLabel()
        // Keep the morph collapse target current too (the first item can reflow
        // after a selection), so the close morph lands on its latest bounds.
        let _ = syncMorphAnchor()
        // A Button, and specifically a Button: the label sits inside the invite card's own
        // zoomTransition Button, and only a NESTED Button reliably wins that tap (sim-verified —
        // a bare touch-observing view loses it and the card opens the profile instead). It also
        // yields the pan to the pager, which the old zero-distance DragGesture never did.
        return Button(action: openFromTap) {
            label()
                .contentShape(Rectangle())
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { frame in
                    labelFrame = frame
                    // Keep the close target on the label's current frame (it reflows
                    // when a selection changes its text) so the lens lands cleanly.
                    controller.updateCollapseAnchor(frame)
                }
            // Dim-only press feedback (native labels dim, never shrink), shown only when
            // the touch-down present failed — the lens copy renders at full brightness, so
            // dimming on the normal path would flash 0.5 → 1 as it takes over. Applied
            // AFTER the geometry read so it never feeds back into the placement anchor.
            // iOS 26: `hidesLabel` swallows the real label while the menu's lens is up
            // (it is the menu now), like native.
                .opacity(controller.hidesLabel ? 0 : (pressed ? TimeCustomMenuSpec.pressedLabelOpacity : 1))
                .animation(pressed ? nil : TimeCustomMenuSpec.pressDimRelease, value: pressed)
        }
        .buttonStyle(MenuLabelPress(onPressChange: pressChanged))
        .instantPressDelivery()
            .onChange(of: openRequest?.wrappedValue ?? false) { _, wants in
                guard wants else { return }
                openRequest?.wrappedValue = false
                guard !controller.isPresented else { return }
                presentMenu()
            }
            // A cancelled touch (incoming call, app switch, system alert) never
            // delivers onEnded, which owns the resets — without these the label
            // would strand at the pressed dim and the latch would eat the next tap.
            .onChange(of: scenePhase) { _, phase in
                guard phase != .active else { return }
                resetTouchLatches()
            }
            .onDisappear {
                resetTouchLatches()
                controller.dismiss(animated: false)
            }
    }

    /// Pushes the freshest label closure into the controller, deferred one runloop
    /// turn so it lands cleanly after the current view-update pass. No-op while the
    /// menu is closed.
    private func syncPresentedLabel() {
        guard controller.isPresented else { return }
        let makeLabel = label
        DispatchQueue.main.async {
            controller.updateLabel { AnyView(makeLabel()) }
        }
    }

    /// Pushes the freshest morph anchor into the controller while presented, so the
    /// close morph collapses onto the first item's current bounds. Deferred one
    /// runloop turn like the label sync. No-op while closed or when no override set.
    private func syncMorphAnchor() {
        guard controller.isPresented, let morphAnchor else { return }
        DispatchQueue.main.async {
            controller.updateMorphAnchor(morphAnchor)
        }
    }

    /// Presents on touch-DOWN — the instant the finger lands, like native. The press comes from
    /// the Button's own `isPressed`, which is exactly the signal wanted here: it arrives on
    /// touch-down (given `instantPressDelivery`), and the enclosing scroll CANCELS it the moment
    /// the finger becomes a pan, which is the pan stand-down the old gesture had to infer from a
    /// slop threshold. Horizontal belongs to the pager, vertical to the card's dismiss drag, and
    /// neither may race a menu bloom.
    private func pressChanged(_ isPressed: Bool) {
        guard isPressed else {
            //Released, or the scroll took the touch — either way nothing pending survives it.
            pendingOpen?.cancel()
            pendingOpen = nil
            pressed = false
            return
        }
        guard !controller.isPresented, pendingOpen == nil else { return }
        armTouchDownOpen()
    }

    /// The release path: a tap too quick to have crossed `openStillDelay` still opens. A pan never
    /// reaches here — the scroll cancels the press and the Button's action never fires.
    private func openFromTap() {
        pendingOpen?.cancel()
        pendingOpen = nil
        guard !controller.isPresented else { return } //Touch-down already opened it
        presentMenu()
        if !controller.isPresented { pressed = true }
    }

    /// Fires after `openStillDelay` of stillness (a press); a faster tap opens at release instead.
    private func armTouchDownOpen() {
        pendingOpen = Task { @MainActor in
            try? await Task.sleep(nanoseconds:
                UInt64(TimeCustomMenuSpec.openStillDelay * 1_000_000_000))
            guard !Task.isCancelled, !controller.isPresented else { return }
            pendingOpen = nil
            presentMenu()
            // Dim only when the menu could not open (rare: no active
            // scene) — normally the swallow itself is the feedback.
            if !controller.isPresented { pressed = true }
        }
    }

    private func resetTouchLatches() {
        pendingOpen?.cancel()
        pendingOpen = nil
        pressed = false
    }

    /// The present call itself, shared by the touch-down gesture and the programmatic
    /// `openRequest`. Either way the menu blooms from the label's own frame.
    private func presentMenu() {
        // Seed the morph collapse target before the overlay renders, so
        // the open bloom starts from the first item (not the full label).
        controller.updateMorphAnchor(morphAnchor)
        controller.present(
            anchor: labelFrame,
            label: { AnyView(label()) },
            cornerRadius: cornerRadius,
            labelCornerRadius: labelCornerRadius,
            platterFill: platterFill,
            alignment: alignment,
            verticalPlacement: verticalPlacement,
            placementOffset: placementOffset,
            estimatedContentSize: estimatedContentSize,
            tracksContentSizeChanges: tracksContentSizeChanges,
            onPresent: {
                isOpen?.wrappedValue = true
                onOpen?()
            },
            onClose: {
                isOpen?.wrappedValue = false
                onClose?()
            },
            content: { AnyView(content()) }
        )
    }
}

// MARK: - Dismiss action environment

struct TimeCustomMenuDismissAction {
    var action: () -> Void = {}
    func callAsFunction() { action() }
}

extension EnvironmentValues {
    @Entry var timeCustomMenuDismiss = TimeCustomMenuDismissAction()
    /// True inside the hidden copy used only for sizing — items must not register.
    @Entry var timeCustomMenuIsMeasuring = false
}

// MARK: - Content modifiers

extension View {
    /// Marks a view as a selectable menu row: it highlights while a drag hovers it,
    /// fires `action` on tap or drag-release, and dismisses the menu.
    func timeCustomMenuItem(action: @escaping () -> Void) -> some View {
        modifier(TimeCustomMenuItemModifier(action: action))
    }
}

private struct TimeCustomMenuItemModifier: ViewModifier {
    @Environment(TimeCustomMenuController.self) private var controller: TimeCustomMenuController?
    @Environment(\.timeCustomMenuIsMeasuring) private var isMeasuring
    let action: () -> Void
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .background {
                if controller?.highlightedItemID == id {
                    if #available(iOS 26.0, *) {
                        RoundedRectangle(cornerRadius: TimeCustomMenuSpec.highlightCornerRadius)
                            .fill(TimeCustomMenuSpec.highlightFill)
                            .padding(3)
                    } else {
                        TimeCustomMenuSpec.highlightFill
                    }
                }
            }
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                guard !isMeasuring else { return }
                controller?.registerItem(id: id, frame: frame, action: action)
            }
            .onTapGesture {
                controller?.select(id: id)
            }
            .onDisappear {
                guard !isMeasuring else { return }
                controller?.unregisterItem(id: id)
            }
    }
}

// MARK: - Controller (window lifecycle + drag-select state)

@MainActor @Observable
final class TimeCustomMenuController {

    enum Phase { case measuring, shown, dismissing }

    private(set) var phase: Phase = .measuring
    private(set) var anchor: CGRect = .zero
    /// The label's *live* frame, tracked while presented so the close morph
    /// collapses onto where the label is now (it may have reflowed after a
    /// selection), not the frame captured at open time. Placement keeps using the
    /// fixed `anchor` so the open menu never moves underfoot.
    private(set) var collapseAnchor: CGRect = .zero
    /// Caller-supplied override for the morph collapse target (the first item's
    /// bounds), preferred over `collapseAnchor` when set. See `TimeCustomMenu.morphAnchor`.
    private(set) var morphAnchor: CGRect?
    private(set) var content: (() -> AnyView)?
    private(set) var labelView: (() -> AnyView)?
    private(set) var cornerRadius = TimeCustomMenuSpec.platterCornerRadius
    private(set) var labelCornerRadius: CGFloat?
    /// Caller's opaque platter fill, painted over the glass. See `TimeCustomMenu.platterFill`.
    private(set) var platterFill: Color?
    private(set) var alignment: TimeCustomMenuAlignment = .automatic
    private(set) var verticalPlacement: TimeCustomMenuVerticalPlacement = .automatic
    private(set) var placementOffset: CGSize = .zero
    /// iOS 26: the real label hides while the overlay's lens carries its copy.
    private(set) var hidesLabel = false
    /// iOS 26: signals the overlay to melt the lens halo off the restored label.
    private(set) var lensDissolve = false
    private(set) var highlightedItemID: UUID?
    /// Laid-out menu frame in screen coordinates, set by the overlay.
    var menuFrame: CGRect = .zero

    /// Caller's rough platter size, used to start the open bloom before the live
    /// measure lands (e.g. the first-ever open, when nothing is cached yet).
    @ObservationIgnored private(set) var estimatedContentSize: CGSize?
    /// Whether the overlay keeps a sizing pass mounted after its initial measure.
    @ObservationIgnored private(set) var tracksContentSizeChanges = false
    /// Size measured on a previous open of this menu. Lets later opens bloom from
    /// the exact size with no measure wait; persists across teardown (the controller
    /// instance outlives each presentation).
    @ObservationIgnored private(set) var cachedMenuSize: CGSize?

    var isPresented: Bool { window != nil }

    @ObservationIgnored private var window: UIWindow?
    @ObservationIgnored private var items: [UUID: Item] = [:]
    /// Fired once at the top of `dismiss()` (any path), cleared on teardown.
    @ObservationIgnored private var onClose: (() -> Void)?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private let selectionHaptic = UISelectionFeedbackGenerator()

    struct Item {
        var frame: CGRect
        var action: () -> Void
    }

    // MARK: Presentation

    func present(anchor: CGRect,
                 label: @escaping () -> AnyView,
                 cornerRadius: CGFloat,
                 labelCornerRadius: CGFloat?,
                 platterFill: Color?,
                 alignment: TimeCustomMenuAlignment,
                 verticalPlacement: TimeCustomMenuVerticalPlacement = .automatic,
                 placementOffset: CGSize,
                 estimatedContentSize: CGSize? = nil,
                 tracksContentSizeChanges: Bool = false,
                 onPresent: (() -> Void)? = nil,
                 onClose: (() -> Void)? = nil,
                 content: @escaping () -> AnyView) {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive })
        else { return }

        onPresent?()
        self.anchor = anchor
        self.collapseAnchor = anchor
        self.labelView = label
        self.cornerRadius = cornerRadius
        self.labelCornerRadius = labelCornerRadius
        self.platterFill = platterFill
        self.alignment = alignment
        self.verticalPlacement = verticalPlacement
        self.placementOffset = placementOffset
        self.estimatedContentSize = estimatedContentSize
        self.tracksContentSizeChanges = tracksContentSizeChanges
        self.onClose = onClose
        self.content = content
        phase = .measuring

        let host = UIHostingController(rootView: TimeCustomMenuOverlayRoot(controller: self))
        host.view.backgroundColor = .clear
        let win = UIWindow(windowScene: scene)
        win.rootViewController = host
        win.windowLevel = .alert + 1
        win.backgroundColor = .clear
        win.isHidden = false
        window = win
    }

    func markShown() {
        if phase == .measuring { phase = .shown }
    }

    /// Re-points the rendered label at the latest closure so the dismiss morph
    /// shrinks showing the current value (e.g. after a selection) rather than the
    /// snapshot captured when the menu opened. No-op while not presented.
    func updateLabel(_ label: @escaping () -> AnyView) {
        guard window != nil else { return }
        labelView = label
    }

    /// Tracks the label's live frame so the close morph lands exactly on it even
    /// after a selection reflows the label. No-op while not presented.
    func updateCollapseAnchor(_ frame: CGRect) {
        guard window != nil, frame != .zero else { return }
        collapseAnchor = frame
    }

    /// Sets/clears the caller's explicit morph collapse target. Set just before
    /// `present` (and kept fresh while shown) so the lens morphs around the first
    /// item instead of the whole label.
    func updateMorphAnchor(_ rect: CGRect?) {
        morphAnchor = rect
    }

    /// Remembers the live-measured size so the next open can bloom from it instantly.
    func cacheMenuSize(_ size: CGSize) { cachedMenuSize = size }

    /// Called by the overlay the moment its lens (pixel-identical to the
    /// label at progress 0) is on screen, so there is overlap, never a gap.
    func hideSourceLabel() {
        hidesLabel = true
    }

    func dismiss(animated: Bool = true) {
        guard window != nil, phase != .dismissing else { return }
        // Fire the moment dismissal is requested — before the close morph runs —
        // so callers don't wait out the animation + teardown.
        onClose?()
        guard animated else { tearDown(); return }
        phase = .dismissing
        let gen = generation
        if #available(iOS 26.0, *) {
            // Close morph lands on the button → restore the real label under
            // the pixel-identical lens copy → melt the halo off → teardown.
            Task {
                try? await Task.sleep(for: .seconds(TimeCustomMenuSpec.closeMorphDuration))
                guard generation == gen else { return }
                hidesLabel = false
                lensDissolve = true
                try? await Task.sleep(for: .seconds(TimeCustomMenuSpec.lensFadeDuration))
                if generation == gen { tearDown() }
            }
        } else {
            Task {
                try? await Task.sleep(for: .seconds(TimeCustomMenuSpec.teardownDelay))
                if generation == gen { tearDown() }
            }
        }
    }

    private func tearDown() {
        generation += 1
        window?.isHidden = true
        window = nil
        onClose = nil
        content = nil
        labelView = nil
        labelCornerRadius = nil
        platterFill = nil
        alignment = .automatic
        verticalPlacement = .automatic
        placementOffset = .zero
        tracksContentSizeChanges = false
        collapseAnchor = .zero
        morphAnchor = nil
        items = [:]
        highlightedItemID = nil
        menuFrame = .zero
        hidesLabel = false
        lensDissolve = false
        phase = .measuring
    }

    // MARK: Items

    func registerItem(id: UUID, frame: CGRect, action: @escaping () -> Void) {
        items[id] = Item(frame: frame, action: action)
    }

    func unregisterItem(id: UUID) {
        items[id] = nil
    }

    /// Tap selection: flash the highlight (native rows stay lit while fading out).
    func select(id: UUID) {
        guard phase == .shown, let item = items[id] else { return }
        highlightedItemID = id
        item.action()
        dismiss()
    }

    // MARK: Press-drag-select

    func dragMoved(to point: CGPoint) {
        guard phase == .shown else { return }
        let hit = items.first { $0.value.frame.contains(point) }?.key
        if hit != highlightedItemID {
            if hit != nil { selectionHaptic.selectionChanged() }
            highlightedItemID = hit
        }
    }

    func dragEnded(at point: CGPoint, translation: CGSize) {
        guard phase == .shown else { return }
        let distance = hypot(translation.width, translation.height)
        // Selection needs a real drag (≥ tapSlop): the opening tap's release must
        // hold the menu open — native's hold-open — never select whatever item the
        // platter happens to lay under the stationary finger.
        if distance >= TimeCustomMenuSpec.tapSlop, let id = highlightedItemID, let item = items[id] {
            item.action()
            dismiss()
        } else if distance >= TimeCustomMenuSpec.tapSlop,
                  !menuFrame.contains(point),
                  !anchor.contains(point) {
            // Released after dragging away from both menu and label.
            dismiss()
        } else {
            highlightedItemID = nil
        }
    }
}

// MARK: - Overlay root (lives in the transparent UIWindow)

private struct TimeCustomMenuOverlayRoot: View {

    let controller: TimeCustomMenuController

    @State private var menuSize: CGSize?
    @State private var contentIdealHeight: CGFloat = 0
    @State private var appeared = false
    /// iOS 26: the open bloom has been kicked (guards against re-firing).
    @State private var bloomStarted = false
    /// iOS 26 lens morph rise: 0 = lens sits on the label, 1 = flown to rest.
    @State private var morphProgress: CGFloat = 0
    /// iOS 26 platterize: the circle widening into the platter on its own clock.
    @State private var widthProgress: CGFloat = 0
    /// iOS 26: the halo materializes over the button on open and melts off
    /// the restored button at the end of the close — never pops.
    @State private var lensOpacity: Double = 0
    /// iOS 26: the close runs the measured droplet choreography only when it
    /// starts from the settled platter; aborting a half-open bloom reverses the
    /// open geometry instead (the droplet keyframes assume the platter rect).
    @State private var closeUsesDroplet = false

    private var overlapsAnchor: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    private var platterShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: controller.cornerRadius)
    }

    var body: some View {
        GeometryReader { geo in
            // Placement anchors to the TIGHT morph anchor (the visible
            // text ∪ chevron) when the caller provides one: the label VIEW
            // itself can be vertically greedy (pager labels fill whatever
            // height their row offers), which drifts the platter far off the
            // visible text. The close morph already lands on the same rect.
            let metrics = Metrics(geo: geo,
                                  anchor: controller.morphAnchor ?? controller.anchor,
                                  overlapsAnchor: overlapsAnchor,
                                  alignment: controller.alignment,
                                  verticalPlacement: controller.verticalPlacement,
                                  placementOffset: controller.placementOffset)
            ZStack(alignment: .topLeading) {
                // Swallows every outside touch, exactly like the native menu.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { controller.dismiss() }

                if let content = controller.content {
                    if #available(iOS 26.0, *) {
                        glassPresentation(content: content(), metrics: metrics)
                    } else {
                        legacyPresentation(content: content(), metrics: metrics)
                    }
                }
            }
            .onChange(of: geo.size) { _, _ in
                controller.dismiss(animated: false)
            }
            .onChange(of: controller.phase) { _, newPhase in
                guard newPhase == .dismissing else { return }
                if #available(iOS 26.0, *) {
                    closeUsesDroplet = morphProgress >= 0.95 && widthProgress >= 0.9
                    withAnimation(closeUsesDroplet ? TimeCustomMenuSpec.closeMorph
                                                   : TimeCustomMenuSpec.bloomClose) {
                        morphProgress = 0
                        widthProgress = 0
                    }
                }
            }
            .onChange(of: controller.lensDissolve) { _, dissolve in
                guard dissolve else { return }
                if #available(iOS 26.0, *) {
                    withAnimation(TimeCustomMenuSpec.lensFadeOut) {
                        lensOpacity = 0
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: iOS 26 — Liquid Glass bloom

    /// The native iOS 26 lens morph, frame-matched to the stock menu's measured
    /// presentation-layer curves: on open, the label line becomes the glass lens
    /// (swallowing the text, which dissolves across the flight) and blooms
    /// straight into the menu's rect while the content — scaled with the platter
    /// — de-blurs and fades in with progress. Dismissal is the reverse; the
    /// label re-materializes inside the landing capsule.
    /// One persistent glass view + Animatable frame interpolation; no glass
    /// transitions involved (the broken ones aren't needed).
    @available(iOS 26.0, *)
    @ViewBuilder
    private func glassPresentation(content: AnyView, metrics: Metrics) -> some View {
        // Bloom from a size known up front — measured on a previous open (cached on
        // the controller) or the caller's estimate — so the morph starts on the tap
        // frame. The content is already warm (pre-built by the caller, see the picker
        // warm-up at the call site) so it is mounted from frame 0 and revealed through
        // the lens mask as the morph blooms over it (MenuLensMorph) without a build
        // hitch.
        let knownSize = menuSize ?? controller.cachedMenuSize ?? controller.estimatedContentSize

        // Dynamic menus keep a non-interactive sizing copy mounted while open;
        // fixed menus drop it after the initial measurement and use the cache.
        if controller.cachedMenuSize == nil || controller.tracksContentSizeChanges {
            chromeCore(content: content, metrics: metrics)
                .environment(\.timeCustomMenuIsMeasuring, true)
                .opacity(0)
                .allowsHitTesting(false)
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { size in
                    // Wait for the scroll-capped pass before trusting oversized menus.
                    guard size.height <= metrics.maxHeight + 1 else { return }
                    let placed = CGRect(origin: metrics.placement(for: size).origin, size: size)
                    if bloomStarted && controller.tracksContentSizeChanges {
                        withAnimation(TimeCustomMenuSpec.reflowResize) {
                            menuSize = size
                            controller.menuFrame = placed
                        }
                    } else {
                        menuSize = size
                        controller.menuFrame = placed
                    }
                    controller.cacheMenuSize(size)
                }
        }

        if let size = knownSize {
            let menuRect = CGRect(origin: metrics.placement(for: size).origin, size: size)
            // The label-line rect the lens is born on and collapses back to: the
            // caller's explicit morph target if given (e.g. the pager's first
            // item), else the label's live frame, else the open-time anchor
            // before the first geometry update lands.
            let collapsedRect = controller.morphAnchor
                ?? (controller.collapseAnchor == .zero ? controller.anchor : controller.collapseAnchor)
            // No GlassEffectContainer: with a single lens shape it isn't needed,
            // and the container both composites its glass ABOVE sibling content
            // (so the label copy can't sit over it) and ignores per-view .opacity
            // (so the glass could never fade). Standalone .glassEffect honours
            // both, which is what lets the glass melt out under the label on close.
            // Positioned with layout padding (inside the modifier), never .offset.
            ZStack(alignment: .topLeading) {
                chromeCore(content: content, metrics: metrics)
                    .modifier(MenuLensMorph(
                        progress: morphProgress,
                        widthProgress: widthProgress,
                        collapsed: collapsedRect,
                        collapsedRadius: controller.labelCornerRadius ?? collapsedRect.height / 2,
                        expanded: menuRect,
                        expandedRadius: controller.cornerRadius,
                        platterFill: controller.platterFill,
                        label: controller.labelView?(),
                        isClosing: controller.phase == .dismissing,
                        dropletClose: closeUsesDroplet
                    ))
                    .opacity(lensOpacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onAppear {
                // With the size known up front the sizing copy may be skipped, so set
                // the hit-test frame and reveal here too.
                controller.menuFrame = CGRect(origin: metrics.placement(for: size).origin, size: size)
                controller.markShown()
                startBloom()
            }
        }
    }

    /// Kicks the open bloom from a known/estimated size on the tap frame. The content
    /// is already mounted (and warm), so it rides the morph and fades in with it.
    /// Idempotent.
    private func startBloom() {
        guard !bloomStarted else { return }
        bloomStarted = true
        // The lens is pixel-identical to the label at progress 0 (its copy at full
        // brightness inside the capsule), so it takes over the button instantly
        // (no fade-in — that adds perceptible lag).
        lensOpacity = 1
        controller.hideSourceLabel()
        // Escape the layout transaction so the morph animates from a committed frame
        // instead of snapping on initial render.
        DispatchQueue.main.async {
            withAnimation(TimeCustomMenuSpec.bloomOpen) { morphProgress = 1 }
            withAnimation(TimeCustomMenuSpec.widthBloom) { widthProgress = 1 }
        }
    }

    // MARK: Pre-26 — classic scale/fade

    @ViewBuilder
    private func legacyPresentation(content: AnyView, metrics: Metrics) -> some View {
        let visible = appeared && controller.phase == .shown
        let placement = metrics.placement(for: menuSize ?? .zero)

        chromeCore(content: content, metrics: metrics)
            .background {
                platterShape
                    .fill(controller.platterFill.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.regularMaterial))
                    .shadow(.floating)
            }
            .clipShape(platterShape)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                menuSize = size
                controller.menuFrame = CGRect(origin: metrics.placement(for: size).origin, size: size)
                // Wait for the scroll-capped pass before revealing oversized menus.
                if !appeared, size.height <= metrics.maxHeight + 1 {
                    appeared = true
                    controller.markShown()
                }
            }
            .scaleEffect(visible ? 1 : TimeCustomMenuSpec.collapsedScale, anchor: placement.anchor)
            .animation(visible ? TimeCustomMenuSpec.openScale : TimeCustomMenuSpec.closeScale, value: visible)
            .opacity(visible ? 1 : 0)
            .animation(visible ? TimeCustomMenuSpec.openFade : TimeCustomMenuSpec.closeFade, value: visible)
            .opacity(menuSize == nil ? 0 : 1)
            .offset(x: placement.origin.x, y: placement.origin.y)
    }

    // MARK: Shared chrome layout (sizing, scroll cap, environment plumbing)

    @ViewBuilder
    private func chromeCore(content: AnyView, metrics: Metrics) -> some View {
        let inner = content
            .environment(controller)
            .environment(\.timeCustomMenuDismiss, TimeCustomMenuDismissAction { [weak controller] in
                controller?.dismiss()
            })
            .getHeight($contentIdealHeight)
            // A tap on the menu's own body must NOT dismiss it — only an outside
            // tap (the Color.clear backdrop), a .timeCustomMenuItem, or the
            // caller's dismiss action (e.g. the Done button) should. Without a
            // hittable shape here, taps on non-interactive areas (the title, the
            // padding, the gaps around the day grid / wheel) fall through to the
            // full-screen backdrop and close the menu. This empty gesture simply
            // absorbs those taps; child buttons and the Done button still win on
            // their own frames, and the wheel still scrolls (it's a drag).
            .contentShape(Rectangle())
            .onTapGesture { }

        Group {
            if contentIdealHeight != 0, contentIdealHeight > metrics.maxHeight {
                ScrollView {
                    inner
                }
                .frame(height: metrics.maxHeight)
            } else {
                inner
            }
        }
        // Hug the content's ideal width (frame(maxWidth:) is greedy under the
        // overlay's infinite proposal and would stretch the platter full-width).
        .fixedSize(horizontal: true, vertical: false)
    }

    /// The travelling lens's shape: an explicit 8-segment Bézier rounded rect
    /// (which IS a circle when the frame is square and the radius is half the
    /// side) with a VELOCITY WARP applied to every control point — trailing
    /// points are dragged backward along the travel vector and pinched toward
    /// the axis (the comet tail), the leading dome stays full. `drag == .zero`
    /// reproduces the continuous rounded rect exactly, so the resting platter,
    /// the flowering and the droplet close are untouched; only a MOVING lens
    /// is ever distorted. One shape type carries every phase, so the glass
    /// never remounts mid-flight.
    @available(iOS 26.0, *)
    private struct MenuLensShape: Shape {
        var cornerRadius: CGFloat
        /// Travel drag: unit direction × magnitude in points.
        var drag: CGVector

        func path(in rect: CGRect) -> Path {
            let mag = hypot(drag.dx, drag.dy)
            // Undistorted, the lens is the NATIVE continuous-curvature rounded
            // rect — the hand-built Bézier ring below exists only for the
            // comet warp. Its eight segment joins carry tiny curvature breaks
            // that a plain fill hides but the glass REFRACTS into a wavy,
            // lumpy outline (device screenshots, mid-flowering) — so it must
            // never render when the warp is effectively off.
            guard mag > 2 else {
                return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .path(in: rect)
            }
            // The frame already includes the tail allowance; the base rounded
            // rect occupies the LEADING side and the warp fills the rest.
            var base = rect
            if mag > 0.5 {
                let ux = drag.dx / mag, uy = drag.dy / mag
                base.size.width -= abs(ux) * mag
                base.size.height -= abs(uy) * mag
                if ux > 0 { base.origin.x += abs(ux) * mag }
                if uy > 0 { base.origin.y += abs(uy) * mag }
            }
            let r = min(cornerRadius, min(base.width, base.height) / 2)
            let k = r * 0.5523  // κ: circle-faithful cubic corner handles
            let x0 = base.minX, x1 = base.maxX, y0 = base.minY, y1 = base.maxY

            // Anchors and handles, clockwise from the top-left corner's end.
            var pts: [CGPoint] = [
                CGPoint(x: x0 + r, y: y0),                                    // 0 start
                CGPoint(x: x1 - r, y: y0),                                    // 1 top edge end
                CGPoint(x: x1 - r + k, y: y0), CGPoint(x: x1, y: y0 + r - k), // 2,3 TR handles
                CGPoint(x: x1, y: y0 + r),                                    // 4 TR end
                CGPoint(x: x1, y: y1 - r),                                    // 5 right edge end
                CGPoint(x: x1, y: y1 - r + k), CGPoint(x: x1 - r + k, y: y1), // 6,7 BR handles
                CGPoint(x: x1 - r, y: y1),                                    // 8 BR end
                CGPoint(x: x0 + r, y: y1),                                    // 9 bottom edge end
                CGPoint(x: x0 + r - k, y: y1), CGPoint(x: x0, y: y1 - r + k), // 10,11 BL handles
                CGPoint(x: x0, y: y1 - r),                                    // 12 BL end
                CGPoint(x: x0, y: y0 + r),                                    // 13 left edge end
                CGPoint(x: x0, y: y0 + r - k), CGPoint(x: x0 + r - k, y: y0), // 14,15 TL handles
            ]

            if mag > 0.5 {
                let ux = drag.dx / mag, uy = drag.dy / mag
                let cx = base.midX, cy = base.midY
                let half = min(base.width, base.height) / 2
                let pinch = TimeCustomMenuSpec.dragPinch
                for i in pts.indices {
                    let dx = pts[i].x - cx, dy = pts[i].y - cy
                    // +1 at the nose, −1 at the tail along the travel axis.
                    let t = (dx * ux + dy * uy) / max(half, 1)
                    let tail = pow(max(0, (1 - t) / 2).clamped(to: 0...1.2), 1.6)
                    // Stretch backward…
                    pts[i].x -= ux * mag * tail
                    pts[i].y -= uy * mag * tail
                    // …and taper toward the travel axis.
                    let px = -uy, py = ux
                    let perp = dx * px + dy * py
                    pts[i].x -= px * perp * pinch * tail
                    pts[i].y -= py * perp * pinch * tail
                }
            }

            var p = Path()
            p.move(to: pts[0])
            p.addLine(to: pts[1])
            p.addCurve(to: pts[4], control1: pts[2], control2: pts[3])
            p.addLine(to: pts[5])
            p.addCurve(to: pts[8], control1: pts[6], control2: pts[7])
            p.addLine(to: pts[9])
            p.addCurve(to: pts[12], control1: pts[10], control2: pts[11])
            p.addLine(to: pts[13])
            p.addCurve(to: pts[0], control1: pts[14], control2: pts[15])
            p.closeSubpath()
            return p
        }
    }

    /// The lens morph, frame-diffed from DEVICE recordings of the real menu
    /// (the simulator's menu animates differently — do not fit to it):
    ///   OPEN — the shape is born as the label rect, collapses to a tiny ball
    ///   and inflates as a DISTORTED CIRCLE (comet drag — never clean while it
    ///   moves) to nearly the platter's short side, pinned to the platter
    ///   corner nearest the label; it HOLDS that circle for roughly half the
    ///   open, frosting while still round, then FLOWERS into the platter rect
    ///   across the late platterize clock — sides bulging out and settling,
    ///   corners resolving, the full-size rows UNCOVERED beneath it (the glass
    ///   is their mask — text exists only where it covers). The label copy is
    ///   masked the same way, extinguished as the departing ball leaves it.
    ///   CLOSE — the droplet choreography (see the spec's keyframe tables):
    ///   frost and rows defrost off the still-full platter, the remaining CLEAR
    ///   lens crashes shut height-first into a wide blob, falls onto the label
    ///   as a tall-stretched droplet, and spreads flat on impact — the label
    ///   fading in beneath it, revealed only through (and refracted by) the
    ///   glass, which then melts off the settled text.
    /// Two independent animatable channels (rise, platterize) interpolate every
    /// spring frame through this modifier; the droplet close reads the rise
    /// channel as its single linear clock.
    @available(iOS 26.0, *)
    private struct MenuLensMorph: ViewModifier, Animatable {
        var progress: CGFloat
        var widthProgress: CGFloat
        let collapsed: CGRect
        /// The label's own corner radius, so the lens is born exactly on its shape.
        let collapsedRadius: CGFloat
        let expanded: CGRect
        /// Corner radius of the expanded menu platter.
        let expandedRadius: CGFloat
        /// Opaque fill over the glass, ramped in with the morph. See `TimeCustomMenu.platterFill`.
        let platterFill: Color?
        let label: AnyView?
        /// The close is running (either close path).
        let isClosing: Bool
        /// This close runs the measured droplet keyframes; false reverses the
        /// open geometry instead (dismissals that abort a half-open bloom).
        let dropletClose: Bool

        var animatableData: AnimatablePair<CGFloat, CGFloat> {
            get { AnimatablePair(progress, widthProgress) }
            set { progress = newValue.first; widthProgress = newValue.second }
        }

        private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
            a + (b - a) * t
        }

        /// The point the row collapses into: pulled toward the platter's
        /// centre in X, and lifted JUST ABOVE the text — the birth droplet
        /// always forms above the label, never on it (device recordings; the
        /// whole open is top-anchored, see `lensFrame`).
        private var collapsePoint: CGPoint {
            CGPoint(
                x: collapsed.midX + (expanded.midX - collapsed.midX)
                    .clamped(to: -collapsed.width * TimeCustomMenuSpec.collapsePullX
                              ... collapsed.width * TimeCustomMenuSpec.collapsePullX),
                y: collapsed.midY - collapsed.height * TimeCustomMenuSpec.collapseLift)
        }

        /// Device-measured OPEN lens geometry — see the type doc for the model.
        /// Only a close that aborts a half-open bloom runs this path in reverse;
        /// the settled-platter close runs `closeLensFrame` instead.
        private func lensFrame(_ p: CGFloat, _ wp: CGFloat)
            -> (rect: CGRect, radius: CGFloat, drag: CGVector) {
            let pc = p.clamped(to: 0...1)
            let wpc = wp.clamped(to: 0...1)
            let a = TimeCustomMenuSpec.collapseEnd
            let d0 = TimeCustomMenuSpec.collapseCircleDiameter
            let cp = collapsePoint

            if pc < a {
                // The row-collapse beat: the label capsule contracts into the
                // tiny circle just past the text — a frame or two at speed.
                let t = (pc / a).clamped(to: 0...1)
                let w = max(1, lerp(collapsed.width, d0, t))
                let h = max(1, lerp(collapsed.height, d0, t))
                let cx = lerp(collapsed.midX, cp.x, t)
                let cy = lerp(collapsed.midY, cp.y, t)
                let radius = min(min(w, h) / 2, lerp(collapsedRadius, d0 / 2, t))
                return (CGRect(x: cx - w / 2, y: cy - h / 2,
                               width: w, height: h), radius, .zero)
            }

            // THE RISE: the circle is launched from just above the label
            // toward the platter's TOP-MIDDLE — always the top, wherever the
            // label sits (the whole open is top-anchored: the menu unfolds
            // DOWNWARD from its minY, like the native) — arriving slightly
            // PAST the top edge, the arrival overshoot the flowering then
            // releases as its gentle settle down.
            let pb = (p - a) / (1 - a)
            let pbc = pb.clamped(to: 0...1)
            let dCircle = max(d0, TimeCustomMenuSpec.ballArriveScale
                        * min(expanded.width, expanded.height))
            let dip = TimeCustomMenuSpec.flowerOvershoot * expanded.height
            let target = CGPoint(
                x: expanded.midX,
                y: expanded.minY - dip + dCircle / 2)
            let cx = lerp(cp.x, target.x, pb)
            let cy = lerp(cp.y, target.y, pb)

            // The circle carries the WHOLE flight (device: it holds ~150ms of
            // a ~300ms open); the flowering below, not the rise, delivers the
            // rect.
            let dBall = lerp(d0, dCircle, pbc)

            // VELOCITY DISTORTION: the travel drag, handed to MenuLensShape,
            // which stretches the trailing side backward along the travel line
            // and tapers it — a comet, never a clean circle while it moves.
            // The frame reserves the tail's room; sin(π·p) shapes the speed
            // envelope and the platterize clock kills it before the flowering.
            let dirX = target.x - cp.x, dirY = target.y - cp.y
            let len = max(1, hypot(dirX, dirY))
            let sx = dirX / len, sy = dirY / len
            let dragMag = dBall * TimeCustomMenuSpec.dragStretch
                * sin(.pi * pbc) * (1 - wpc)
            let drag = CGVector(dx: sx * dragMag, dy: sy * dragMag)
            let ballW = dBall + abs(sx) * dragMag
            let ballH = dBall + abs(sy) * dragMag
            let bx = cx - sx * dragMag / 2
            let by = cy - sy * dragMag / 2

            // THE FLOWERING: only across the LATE part of the platterize clock
            // does the arrived circle fold open into the rect — and it does so
            // SYMMETRICALLY: every edge expands on the SAME fraction around
            // the shape's centre (per-edge curves read as lopsided mid-morph),
            // the comet warp fully faded out by mid-flower, corners resolving
            // uniformly, the whole shape gliding down from its arrival
            // overshoot as one translation: the soft landing. The unclamped
            // spring fraction still supplies the small end bounce — uniformly.
            let fs = TimeCustomMenuSpec.flowerStart
            let ft = max(0, (wp - fs) / (1 - fs))
            let ftc = ft.clamped(to: 0...1)
            let bulge = 1 + TimeCustomMenuSpec.flowerBulge * sin(.pi * ftc)
            let w = max(1, lerp(ballW, expanded.width, ft)) * bulge
            let h = max(1, lerp(ballH, expanded.height, ft)) * bulge
            let settle = ftc * ftc * (3 - 2 * ftc)
            let fx = lerp(bx, expanded.midX, ftc)
            let fy = lerp(by, expanded.midY, settle)
            let cap = min(w, h) / 2
            let radius = min(cap, lerp(cap, expandedRadius, ftc))
            let fade = 1 - ftc
            let dragOut = CGVector(dx: drag.dx * fade, dy: drag.dy * fade)
            return (CGRect(x: fx - w / 2, y: fy - h / 2, width: w, height: h),
                    radius, dragOut)
        }

        /// The droplet close geometry — frame-fitted to the default menu (see
        /// the spec beats): the platter shrinks fast into a line-height
        /// capsule at the label line's centre, then the capsule spreads
        /// centre-outwards across the line. No shape warp on close — the
        /// default's collapse is a plain rounded rect all the way.
        private func closeLensFrame(_ tau: Double) -> (rect: CGRect, radius: CGFloat, drag: CGVector) {
            let landW = collapsed.width
            let landH = collapsed.height + TimeCustomMenuSpec.closeLandHeightPad
            let circleEnd = TimeCustomMenuSpec.closeCircleEnd
            let cEnd = TimeCustomMenuSpec.closeCollapseEnd
            let dia = TimeCustomMenuSpec.closeCircleScale
                * min(expanded.width, expanded.height)
            let arriveW = TimeCustomMenuSpec.closeArriveWidth
            let cx0 = collapsed.midX, cy0 = collapsed.midY

            if tau < circleEnd {
                // Beat 1 — the platter becomes a fully ROUND circle while
                // still large: the radius races to circular well before the
                // size lands, content dissolving inside it.
                let t = CGFloat((tau / circleEnd).clamped(to: 0...1))
                let ease = t * t * (3 - 2 * t)
                let w = max(1, lerp(expanded.width, dia, ease))
                let h = max(1, lerp(expanded.height, dia, ease))
                let cap = min(w, h) / 2
                let radius = min(cap, lerp(expandedRadius, cap, (t * 2).clamped(to: 0...1)))
                return (CGRect(x: expanded.midX - w / 2, y: expanded.midY - h / 2,
                               width: w, height: h), radius, .zero)
            }

            if tau < cEnd {
                // Beat 2 — the circle condenses onto the text line's centre,
                // arriving as a small pale capsule AT SPEED (ease-in, not
                // smoothstep): the reveal spring launches off this momentum,
                // rolling through the capsule with no apex dwell.
                let t = CGFloat(((tau - circleEnd) / (cEnd - circleEnd)).clamped(to: 0...1))
                let ease = t * t
                let w = max(1, lerp(dia, arriveW, ease))
                let h = max(1, lerp(dia, landH, ease))
                let cx = lerp(expanded.midX, cx0, ease)
                let cy = lerp(expanded.midY, cy0, ease)
                return (CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h),
                        min(w, h) / 2, .zero)
            }

            // Beat 3 — the capsule springs open centre-outwards across the
            // line, text growing with it (reverse opacityPop in `body`): the
            // Dropdown's landing pop, overshooting together and settling while
            // the wash and lens fade.
            let t = CGFloat(((tau - cEnd) / (1 - cEnd)).clamped(to: 0...1))
            let u = TimeCustomMenuSpec.closeReveal(t)
            let w = max(1, lerp(arriveW, landW, u))
            return (CGRect(x: cx0 - w / 2, y: cy0 - landH / 2, width: w, height: landH),
                    landH / 2, .zero)
        }

        func body(content: Content) -> some View {
            let p = progress
            let pc = p.clamped(to: 0...1)
            let wpc = widthProgress.clamped(to: 0...1)
            let droplet = isClosing && dropletClose
            // The droplet close reads the rise channel (1 → 0, linear) as its
            // single close clock; every curve below comes off the keyframes.
            let tau = droplet ? Double(1 - pc) : 0
            let lens = droplet ? closeLensFrame(tau) : lensFrame(p, widthProgress)
            let w = lens.rect.width
            let h = lens.rect.height
            // One shape type for every phase (glass must never remount):
            // rounded rect at rest, velocity-warped comet while travelling.
            let lensShape = MenuLensShape(cornerRadius: lens.radius, drag: lens.drag)
            // Aborted half-open closes keep the legacy ghost dissolve; the
            // droplet close scripts its opacities from the close clock instead.
            let dissolve: Double = isClosing && !droplet ? 0.25 + 0.75 * pow(Double(pc), 3) : 1
            // The rows dissolve INSIDE the collapsing circle; the milky wash
            // (frost + fill) stays ON the circle and lingers as the soft pill
            // behind the revealed text, fading late.
            let contentFade = droplet
                ? 1 - (tau / TimeCustomMenuSpec.closeContentFadeEnd).clamped(to: 0...1) : 1
            let washR = TimeCustomMenuSpec.closeWashFade
            let wash = droplet
                ? 1 - ((tau - washR.lowerBound) /
                       (washR.upperBound - washR.lowerBound)).clamped(to: 0...1) : 1
            // The opaque fill, material crossfade, presence, and content all
            // ride the PLATTERIZE phase (device: the circle is pure refraction;
            // frost, rows and label-occlusion arrive as the platter forms), with
            // a whisper of presence during the rise itself.
            let fillRange = TimeCustomMenuSpec.platterFillRange
            let fillOpacity = droplet ? wash
                : Double(((wpc - fillRange.lowerBound) /
                          (fillRange.upperBound - fillRange.lowerBound)).clamped(to: 0...1))
            let matRange = TimeCustomMenuSpec.glassMaterialRange
            let material = droplet ? wash
                : Double(((wpc - matRange.lowerBound) /
                          (matRange.upperBound - matRange.lowerBound)).clamped(to: 0...1))
            let presence = droplet ? 1
                : pow(Double(max(pc * 0.35, wpc)), TimeCustomMenuSpec.glassPresenceExponent)
            // The clear lens is crisp almost immediately (its own fast rise);
            // only the frost materializes on the slow presence ramp above.
            let presenceClear = droplet ? 1
                : pow(Double(max(pc, wpc)), TimeCustomMenuSpec.clearPresenceExponent)
            // The clear lens melts WHILE the spread runs — the expansion
            // dissolves as it goes, never a full-strength lens at the end.
            let fadeStart = TimeCustomMenuSpec.closeLensFadeStart
            let fadeEnd = TimeCustomMenuSpec.closeLensFadeEnd
            let glassOpacity = droplet
                ? 1 - ((tau - fadeStart) / (fadeEnd - fadeStart)).clamped(to: 0...1) : dissolve

            ZStack(alignment: .topLeading) {
                // The platter's regular material sits BENEATH the content (glass on
                // the content itself would capture native control chrome, e.g. a
                // wheel picker's selection indicator, in its foreground pass). The
                // CLEAR glass rides ON TOP of everything — see below. Each layer
                // must be ABSENT outside its range, not faded to 0 — a stacked
                // .glassEffect still washes the composite milky at opacity 0
                // (sim-probed on iOS 26.0); the `if`s flip in the same frame the
                // opacity crosses zero, so nothing pops.
                if material > 0 {
                    Color.clear
                        .frame(width: w, height: h)
                        .glassEffect(.regular, in: lensShape)
                        .opacity(glassOpacity * material * presence)
                }

                // Opaque platter OVER the glass, in the lens's own shape so it morphs with
                // it (a fill on the content would stay a hard-cornered rect through the
                // birth circle). Above and not below: glass wears a system-appearance tint
                // and the menu's own UIWindow follows the DEVICE appearance, so a fill
                // underneath reads as tinted glass (flat grey on a dark-appearance device),
                // never as its own colour. The glass beneath still carries the birth leg
                // and early eruption, where the fill has not ramped in yet.
                // Only for menus that bloom over imagery — see `platterFill`.
                if let platterFill {
                    lensShape
                        .fill(platterFill)
                        .frame(width: w, height: h)
                        .opacity(glassOpacity * fillOpacity * presence)
                }

                // Content sits FULL-SIZE on its resting rect from frame 0 and
                // is MASKED to the lens: the glass IS the reveal — the rows
                // exist exactly where it covers them, uncovered as the
                // flowering opens across the rect and swallowed again as the
                // close shrinks off them (device frames: the row text is crisp
                // and full-size mid-morph, clipped by the glass edges — never
                // squashed, blurred or faded in place). Opacity only keeps the
                // flying circle EMPTY (`contentArriveRange`); on the droplet
                // close the rows dissolve inside the collapsing circle.
                let ar = TimeCustomMenuSpec.contentArriveRange
                let arrive: Double = droplet ? contentFade
                    : Double(((wpc - ar.lowerBound) /
                              (ar.upperBound - ar.lowerBound)).clamped(to: 0...1))
                content
                    .frame(width: expanded.width, height: expanded.height, alignment: .topLeading)
                    .offset(x: expanded.minX - lens.rect.minX,
                            y: expanded.minY - lens.rect.minY)
                    .opacity(arrive * dissolve)
                    .frame(width: w, height: h, alignment: .topLeading)
                    .mask { lensShape }

                // The label's visibility is MASKED to the lens both ways — the
                // text exists only where the glass covers it. OPEN: the copy
                // shrinks and is dragged up into the collapse point WITH the
                // glass (the swallow), never showing outside it, its dissolve
                // completing inside the droplet. On the
                // droplet close it does NOT ride back — it fades in PINNED on
                // its own rect, revealed only through the widening glass (which
                // magnifies it for real — the clear lens above refracts this
                // copy), the mask doing the centre-outward reveal as the dot
                // expands across the text; then the end hop — glass and text
                // rise together and settle back level. Both states are
                // invisible at the switch (the ball has left the collapse
                // point; the close reveal starts at 0).
                if let label, !droplet {
                    let ride = (pc / TimeCustomMenuSpec.labelRideEnd).clamped(to: 0...1)
                    let cp = collapsePoint
                    // The dissolve must still complete INSIDE the droplet: the
                    // flowering re-covers the collapse point late in the open
                    // (the platter overlays the label's rect), so the mask alone
                    // would re-admit the shrunken copy as a smudge at rest. The
                    // mask's job is the other half — the copy never shows
                    // OUTSIDE the glass while it is being swallowed.
                    let fade = ((ride - 0.5) / 0.5).clamped(to: 0...1)
                    label
                        .fixedSize()
                        .scaleEffect(lerp(1, TimeCustomMenuSpec.labelRideScale, ride))
                        .offset(x: lerp(collapsed.minX - lens.rect.minX,
                                        cp.x - lens.rect.minX - collapsed.width / 2, ride),
                                y: lerp(collapsed.minY - lens.rect.minY,
                                        cp.y - lens.rect.minY - collapsed.height / 2, ride))
                        .frame(width: w, height: h, alignment: .topLeading)
                        .blur(radius: ride * TimeCustomMenuSpec.lensBlur * 0.5)
                        .opacity(Double(1 - fade * fade))
                        .mask { lensShape }
                }

                // The CLEAR glass — the liquid lens — rides ON TOP of the content
                // and label so its refraction genuinely BENDS them at the moving
                // edges during flight (the native SDF's text smear; frame-matched
                // against device recordings). It crossfades away as the platter's
                // material lands, so the resting menu is crisp with nothing over it.
                if material < 1 {
                    Color.clear
                        .frame(width: w, height: h)
                        .glassEffect(.clear, in: lensShape)
                        .opacity(glassOpacity * (1 - material) * presenceClear)
                }

                // The close's revealed text sits ABOVE the clear lens — the
                // pill (wash + lens) stays fully glass, but the text is never
                // optically behind it, so the near-static end-of-close lens
                // can't print refraction echoes around the crisp glyphs. The
                // open's swallow keeps its refracted copy below the lens.
                if let label, droplet {
                    // Reverse opacityPop, on the SPREAD'S OWN CURVE: the
                    // text is born small and faint at the line's centre
                    // and scales up + brightens exactly as the glass
                    // widens — one thing inflating, never a static line
                    // uncovered by a sliding edge.
                    let cEnd = TimeCustomMenuSpec.closeCollapseEnd
                    let spread = CGFloat(((tau - cEnd) / (1 - cEnd))
                        .clamped(to: 0...1))
                    // Glass and text ride the SAME spring — the whole
                    // reveal launches, overshoots and settles as one
                    // thing, exactly like the Dropdown's label pop.
                    let grow = TimeCustomMenuSpec.closeReveal(spread)
                    let scale = lerp(TimeCustomMenuSpec.closeTextGrowFrom, 1, grow)
                    // The settle: the text emerges pushed DOWN by the
                    // landing glass and rises to rest — drop hits zero by
                    // closeTextSettleEnd, so the copy lands pixel-identical
                    // for the seamless swap to the real label.
                    let sEnd = TimeCustomMenuSpec.closeTextSettleEnd
                    let rise = ((tau - cEnd) / (sEnd - cEnd)).clamped(to: 0...1)
                    let drop = TimeCustomMenuSpec.closeTextDrop
                        * CGFloat(1 - rise * rise * (3 - 2 * rise))
                    label
                        .fixedSize()
                        .scaleEffect(scale, anchor: .center)
                        .offset(x: collapsed.minX - lens.rect.minX,
                                y: collapsed.minY - lens.rect.minY + drop)
                        .frame(width: w, height: h, alignment: .topLeading)
                        .opacity(Double(grow.clamped(to: 0...1)))
                        .mask { lensShape }
                }
            }
            .frame(width: w, height: h, alignment: .topLeading)
            .padding(.leading, max(0, lens.rect.minX))
            .padding(.top, max(0, lens.rect.minY))
        }
    }

    /// Screen-edge / safe-area aware positioning.
    private struct Metrics {
        let bounds: CGSize
        let available: CGRect
        let anchor: CGRect
        /// iOS 26 menus cover the source button's rect (near edges flush, no
        /// gap, per device recordings); the classic menu floats 6pt away.
        let overlapsAnchor: Bool
        /// Which label edge the menu aligns to.
        let alignment: TimeCustomMenuAlignment
        /// Which side of the label the menu opens toward.
        let verticalPlacement: TimeCustomMenuVerticalPlacement
        /// Nudge applied to the final placement (positive = right / down).
        let placementOffset: CGSize
        let spaceBelow: CGFloat
        let spaceAbove: CGFloat

        var maxHeight: CGFloat { max(spaceBelow, spaceAbove) }
        var maxWidth: CGFloat { available.width }

        init(geo: GeometryProxy, anchor: CGRect, overlapsAnchor: Bool,
             alignment: TimeCustomMenuAlignment,
             verticalPlacement: TimeCustomMenuVerticalPlacement = .automatic,
             placementOffset: CGSize) {
            let safe = geo.safeAreaInsets
            let margin = TimeCustomMenuSpec.screenMargin
            bounds = geo.size
            available = CGRect(
                x: safe.leading + margin,
                y: safe.top + margin,
                width: max(0, bounds.width - safe.leading - safe.trailing - 2 * margin),
                height: max(0, bounds.height - safe.top - safe.bottom - 2 * margin)
            )
            self.anchor = anchor
            self.overlapsAnchor = overlapsAnchor
            self.alignment = alignment
            self.verticalPlacement = verticalPlacement
            self.placementOffset = placementOffset
            if overlapsAnchor {
                spaceBelow = available.maxY - anchor.minY
                spaceAbove = anchor.maxY - available.minY
            } else {
                spaceBelow = available.maxY - (anchor.maxY + TimeCustomMenuSpec.anchorGap)
                spaceAbove = (anchor.minY - TimeCustomMenuSpec.anchorGap) - available.minY
            }
        }

        /// The native opens toward the ROOMIER side of the label when the menu
        /// fits on both (device recordings: a label past mid-screen blooms
        /// upward even though the menu would fit below — fits-below-first put
        /// the platter under the row and sent the whole open diving down);
        /// otherwise the side that fits, else the larger one. iOS 26: top (or
        /// bottom) edge flush with the label's; classic: 6pt gap. Both
        /// edge-align horizontally to the label (left edge for a leading
        /// label, right edge for a trailing one). The unit anchor is the point
        /// on the menu nearest the label (legacy scale transform origin).
        func placement(for size: CGSize) -> (origin: CGPoint, anchor: UnitPoint) {
            let below: Bool
            switch verticalPlacement {
            case .below: below = true
            case .above: below = false
            case .automatic:
                if size.height <= spaceBelow && size.height <= spaceAbove {
                    below = spaceBelow >= spaceAbove
                } else if size.height <= spaceBelow {
                    below = true
                } else if size.height <= spaceAbove {
                    below = false
                } else {
                    below = spaceBelow >= spaceAbove
                }
            }

            var y: CGFloat
            if overlapsAnchor {
                y = below ? anchor.minY : anchor.maxY - size.height
            } else {
                y = below ? anchor.maxY + TimeCustomMenuSpec.anchorGap
                          : anchor.minY - TimeCustomMenuSpec.anchorGap - size.height
            }
            y += placementOffset.height
            y = y.clamped(to: available.minY...max(available.minY, available.maxY - size.height))

            // Edge-align to the label: leading aligns left edges, trailing aligns
            // right edges (so a trailing trigger's menu lines its right edge up
            // with the label's). `.automatic` guesses from the label's centre —
            // unreliable for a full-width label, which is why wide rows pass an
            // explicit alignment.
            let leadingX = anchor.minX
            let trailingX = anchor.maxX - size.width
            var x: CGFloat
            switch alignment {
            case .leading:  x = leadingX
            case .trailing: x = trailingX
            case .automatic: x = anchor.midX <= bounds.width / 2 ? leadingX : trailingX
            }
            x += placementOffset.width
            x = x.clamped(to: available.minX...max(available.minX, available.maxX - size.width))

            let unitX = ((anchor.midX - x) / max(size.width, 1)).clamped(to: 0...1)
            return (CGPoint(x: x, y: y), UnitPoint(x: unitX, y: below ? 0 : 1))
        }
    }
}

/// Surfaces a Button's `isPressed` to the menu without painting anything: the label keeps its
/// own dim (`pressedLabelOpacity`), which is shown only when a present actually failed.
private struct MenuLabelPress: ButtonStyle {
    let onPressChange: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in onPressChange(isPressed) }
    }
}
