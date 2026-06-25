//AI Code Beware!
//  DropdownCustomMenu.swift
//  Scoop Test
//
//  NOTE: The OPEN is the pre-2026-06-24 `TypeCustomMenu` behaviour, lifted into its
//  own type (all symbols renamed `TypeCustomMenu*` → `DropdownCustomMenu*`): the label
//  stays visible underneath while the menu opens (it is never hidden/captured then),
//  and the platter blooms straight out of the button's frame.
//  The DISMISS is NO LONGER a simple reverse. It now plays a polished
//  circle→label reveal borrowed from TimeCustomMenu: the platter and a hidden copy of
//  the label both shrink STRAIGHT into ONE centred glass circle (the platter no longer
//  pauses at the label's rectangle on the way down), which finally expands back out and
//  reveals the label. See the "iOS 26 dismiss" block in `DropdownCustomMenuSpec` and
//  `PlatterDismissMorph` / `LabelCollapseMorph`.
//
//  Created by Art Ostin on 11/06/2026.
//
//  DropdownCustomMenu — a reusable recreation of the native menu presentation that
//  accepts fully arbitrary content. On iOS 26+ it reproduces the Liquid Glass
//  menu: a glass bubble that morphs ("blooms") out of the label, and morphs
//  back into it on dismissal. Pre-26 it falls back to the classic scale/fade.
//
//  Usage:
//      DropdownCustomMenu {
//          // any SwiftUI view / layout
//      } label: {
//          // the trigger view
//      }
//
//  Inside the content closure:
//      .dropdownCustomMenuItem { ... }        — row participates in drag-to-select highlight,
//                                       runs its action and dismisses on selection.
//      @Environment(\.dropdownCustomMenuDismiss) — programmatic dismissal from content. A tap
//                                       on the menu's own content never auto-dismisses;
//                                       call this action (or use .dropdownCustomMenuItem) to
//                                       close it. Tapping outside still dismisses.
//
//  ── iOS 26 bloom mechanics ──────────────────────────────────────────────────
//  On OPEN, the glass platter grows directly out of the LABEL'S FULL FRAME (the
//  whole button), straight into the rounded-rect platter, while the menu content
//  de-blurs and materializes. There is no intermediate droplet or travelling
//  phase: the shape only ever grows monotonically from the button's rect to the
//  platter. The real label is NOT captured or hidden during the open: it stays
//  visible in the app tree underneath, and the glass simply blooms out from over it.
//  (An earlier version grew the morph out of a small trailing-edge circle; the
//  start/end geometry was widened to the whole button by request.)
//  On DISMISS (the default `.morph`) the label DOES participate — see the
//  `dismissPresentation` / `PlatterDismissMorph` / `LabelCollapseMorph` block below:
//  the platter and a hidden copy of the label both shrink straight into one centred
//  glass circle (the platter goes directly to the circle, not via the label's rect),
//  which expands back out and reveals the label (the TimeCustomMenu reveal). Two timed
//  phases driven by `morphProgress` (1→0) then `revealProgress` (0→1), both meeting at the circle.
//  Implementation: ONE persistent glass view whose frame/radius/content are
//  interpolated by an Animatable modifier (MenuLensMorph) under withAnimation.
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
//  and shadow values are not public; `DropdownCustomMenuSpec` holds tuned approximations
//  (community references converge on .bouncy(≈0.4) for glass morphs).
//   • The platter uses .glassEffect(.regular); the system menu material adds
//     private vibrancy/shadow treatment that public glass lacks.
//   • Platter corner radius is a fixed 26pt stand-in for the system's
//     container-concentric radius (no container to be concentric with here).
//   • Platter content is not hard-clipped to the glass shape (.clipShape breaks
//     glass transitions); keep menu content padded inside the 26pt corners.
//   • The menu is presented in its own transparent UIWindow (level .alert + 1),
//     like UIKit does, so it can never be clipped by scroll views, the nav stack
//     or the tab bar. Anchor frames assume the app window fills the scene
//     (always true on iPhone; iPad floating windows may offset slightly).
//   • The label opens the menu on release (a completed tap), not touch-down, so it
//     reads like a normal button press; the zero-distance press gesture still claims
//     the touch, so a label inside a ScrollView can still swallow a scroll that
//     begins on it (UIKit's delaysContentTouches has no public SwiftUI equivalent).
//

import SwiftUI
import UIKit

// MARK: - Demo / harness

struct DropdownCustomMenuBuilder: View {

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
        DropdownCustomMenu {
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
            .frame(width: DropdownCustomMenuSpec.standardWidth)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 24))
                .foregroundStyle(Color.appGreen)
                .padding(8)
        }
    }

    /// Arbitrary layout: a reaction bar over a colour grid — impossible in a native Menu.
    private var freeformMenu: some View {
        DropdownCustomMenu {
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    ForEach(["🍦", "🍨", "🍧", "🍫", "🍓"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 28))
                            .dropdownCustomMenuItem { flavour = emoji }
                    }
                }
                Divider()
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(44)), count: 4), spacing: 10) {
                    ForEach([Color.appGreen, .accent, .warningYellow,
                             .grayPlaceholder, .grayText, .appCanvas, .dangerRed], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 38, height: 38)
                            .dropdownCustomMenuItem { }
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
                .background(Color.appGreen, in: Capsule())
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
        .dropdownCustomMenuItem(action: action)
    }
}

#Preview {
    DropdownCustomMenuBuilder()
}

// MARK: - Spec (approximations of the private native values)

enum DropdownCustomMenuSpec {

    // ── iOS 26 Liquid Glass lens morph ──
    /// Platter corner radius — fixed stand-in for the system's concentric radius.
    static let platterCornerRadius: CGFloat = 26
    /// Glass shapes closer than this blend/morph inside the container.
    static let morphSpacing: CGFloat = 40
    /// Peak refraction blur while the menu content is materializing as the
    /// platter grows (de-blurs to 0 by the time the platter is full).
    static let lensBlur: CGFloat = 8
    /// Diameter of the small circle the platter grows out of / collapses back into
    /// when a call site opts into the trailing-point origin (`morphsFromTrailingPoint`).
    /// Unused for the default whole-button morph.
    static let expansionOriginDiameter: CGFloat = 16
    /// Bloom timing (slightly quicker than the native ~0.45s open, same slight settle).
    static let bloomOpen = Animation.spring(response: 0.32, dampingFraction: 0.82) //0.82
    /// Shrinking back into the button frame never bounces (~0.4s on device).
    static let bloomClose = Animation.snappy(duration: 0.25) //Slightly snappier close
    /// After the menu is open, content can reflow (e.g. an info row expands) and
    /// change the platter's height. Grow it with this curve — matched to the
    /// content's own expand animation — so the glass tracks the content instead
    /// of snapping. Only applies post-open; the initial sizing stays unanimated.
    /// Must stay identical to the curve the content reflows on (SelectTypeView's
    /// info toggle uses `.snappy(duration: 0.3)`); a different spring here makes
    /// the platter fill drift ahead of the content's own stroke as it extends.
    static let reflowResize = Animation.snappy(duration: 0.3)
    /// After the dismiss reveal lands the label, any leftover glass halo melts off rather
    /// than popping out in one frame (driven on the reveal animation's completion).
    static let lensFadeOut = Animation.snappy(duration: 0.05)
    /// How long the `.pop` dismiss (the `.scoopPop` transition) runs before the window
    /// tears down. Matches the settle of `Animation.scoopPop` (response 0.35, slight bounce).
    static let popCloseDuration: TimeInterval = 0.5
    /// On close, the glass stays fully opaque until progress drops below this, then
    /// melts linearly to nothing by progress 0 — so the platter shrinks back into the
    /// button's frame still solid (mirroring the opaque grow on open) and only
    /// fades over the final stretch, leaving nothing to pop. Larger starts the
    /// fade earlier / while the platter is still big (0.35 washed it out mid-shrink);
    /// smaller keeps it solid longer and concentrates the fade right at the button.
    static let closeGlassFadeProgress: CGFloat = 0.05
    /// Platter shadow at full bloom (native casts a wide soft shadow).
    static let platterShadowOpacity: CGFloat = 0.1
    static let platterShadowRadius: CGFloat = 24
    static let platterShadowY: CGFloat = 10

    // ── iOS 26 dismiss: rectangular collapse → centered circle → snappy reveal ──
    /// Diameter of the centered glass circle the label + platter collapse into. Sized off
    /// the SMALLER of the label's dimensions (× this scale) and clamped to the range below,
    /// so it always reads as a tidy circle: a tall multi-line label won't balloon it into a
    /// large blob, and a tiny label still gets a visible one. Centred on the label's frame.
    static let dismissCircleScale: CGFloat = 1.45
    static let dismissCircleMinDiameter: CGFloat = 28
    static let dismissCircleMaxDiameter: CGFloat = 64
    /// Phase 1 curve (platter → circle, label → circle — both shrink straight into the same
    /// centred circle, no intermediate label-rect stop). The overlay chains
    /// phase 2 off this animation's *completion* (logicallyComplete), so the reveal kicks
    /// in the instant the collapse reaches the circle — no fixed wall-clock wait that could
    /// desync from the animation under load.
    ///
    /// LINEAR, deliberately not an ease-out. An ease-out curve (`.smooth`) decelerates to
    /// ~zero velocity *exactly as it arrives at the circle*, so the collapse visibly stalled
    /// at the apex for a beat before the reveal launched — the "velocity comes to nil, then
    /// springs sharply out" hitch. Linear reaches the circle still moving at full speed and
    /// hands straight off to the momentum-launched reveal (`circleReveal`'s `initialVelocity`),
    /// so the motion rolls continuously through the apex as one clean velocity cusp (reverse-
    /// through, like a bounce) instead of stop-then-relaunch. Verified frame-by-frame in the
    /// simulator: switching `.smooth`→`.linear` here cut the apex dwell from ~0.05s to ~1
    /// frame (the irreducible latency of the two-`withAnimation` handoff). The shape morph
    /// (rect→circle) masks the constant speed, so it doesn't read as mechanical.
    static let collapseToCircle = Animation.linear(duration: 0.14) //0.24
    /// Phase 2 — the circle expands back into the label's rectangle and the label is
    /// revealed. Driven as an INTERPOLATING spring with a nonzero `initialVelocity` so the
    /// reveal LAUNCHES with the momentum the collapse carried in, instead of starting from
    /// rest. A plain `.spring` here starts at velocity 0, so the platter comes to a dead stop
    /// at the circle before springing out — the exact hitch we don't want. Injecting launch
    /// velocity lets it "roll" through the circle as one continuous motion (squash in, spring
    /// straight back out, like a bounce). The reveal geometry may overshoot slightly past the
    /// label's resting size (see `revealOvershoot`) for an organic pop.
    /// `circleRevealLaunchVelocity` is the feel knob: higher = more momentum out of the circle
    /// (less dwell, punchier), lower = gentler. In `initialVelocity` units (1 = the full
    /// circle→label distance per second). Tuned frame-by-frame in the simulator.
    static let circleRevealLaunchVelocity: Double = 6.9
    static let circleReveal = Animation.interpolatingSpring(
        Spring(response: 0.3, dampingRatio: 0.86),
        initialVelocity: circleRevealLaunchVelocity
    )
    /// Upper bound the reveal geometry may extrapolate the label past its resting size, so
    /// the spring's overshoot reads as a real pop without ever running away.
    static let revealOvershoot: CGFloat = 1.08
    /// Safety net: if the completion-chained morph ever fails to fire, tear the window down
    /// after this long so it can't leak. The normal path tears down ~0.45s via completions.
    static let dismissSafetyTimeout: TimeInterval = 1.2
    /// On the reveal, the glass is fully present at the circle and melts to nothing over
    /// the final relax onto the label (mirrors TimeCustomMenu's `closeGlassFadeProgress`),
    /// so the label alone lands and there's no glass left to pop.
    static let revealGlassFadeProgress: CGFloat = 0.35

    // ── `.flex` dismiss (no-change close) ──
    /// When a dismiss leaves the selection unchanged (tap-away, or re-picking the already-
    /// selected row) the circle morph is wasted motion — the label would suck into a circle
    /// and pop back as the *same* label. The `.flex` style instead melts the platter away
    /// (the `.pop` transition) and gives the real label — which stays visible underneath the
    /// whole time — a quick scale-up + lift that settles back: a light "nothing changed"
    /// acknowledgement. A `flexing` pulse on the controller drives it; the label reads it.
    static let flexScale: CGFloat = 1.10
    static let flexOffsetY: CGFloat = -7
    /// Wait for the platter to melt away (the `.scoopPop` is ~0.3s) before flexing, so the
    /// pulse lands on the now-exposed label instead of peaking *under* the fading platter
    /// where it's invisible. Verified in the sim: without this the flex peaks ~0.15s in,
    /// while the platter is still clearing, and reads as almost nothing.
    static let flexDelay: TimeInterval = 0.16
    /// How long the label holds at the peak before settling back. The settle interrupts the
    /// rise if it hasn't finished, which is fine — SwiftUI carries the velocity through.
    static let flexHold: TimeInterval = 0.12
    /// Quick rise, then a softer settle with a hair of bounce so it reads as a flex, not a jump.
    static let flexUp = Animation.spring(response: 0.18, dampingFraction: 0.7)
    static let flexDown = Animation.spring(response: 0.34, dampingFraction: 0.6)

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
    static let legacyCornerRadius: CGFloat = 13

    // ── Shared metrics ──
    /// Standard native menu width; opt in with .frame(width:) on your content.
    static let standardWidth: CGFloat = 250
    /// Gap between the label and the menu edge.
    static let anchorGap: CGFloat = 6
    /// Gap between the main platter and the detached footer accessory.
    static let footerGap: CGFloat = 6
    /// The footer sits `footerGap` below the platter at a LOWER z-order, so the
    /// platter's drop shadow (platterShadow* below) paints over the footer's
    /// finished pixels and it reads ~5% darker than the platter face (measured
    /// F0F4F5 vs E4EAEC over the same wallpaper). The shadow can't be cast
    /// selectively around the footer, so the footer pre-brightens by this much:
    /// once the platter shadow darkens it, it lands back on the platter's tone.
    /// Additive (SwiftUI `.brightness`); tune alongside `platterShadowOpacity`.
    static let footerShadowCompensation: Double = 0.05
    /// Fine-tuning nudge applied to the final placement: shifts the platter
    /// right and down from its anchor-aligned position.
    static let placementOffsetX: CGFloat = 12
    static let placementOffsetY: CGFloat = 24
    /// Minimum distance kept from safe-area edges.
    static let screenMargin: CGFloat = 9
    /// Drags shorter than this count as a tap on the label (menu stays open).
    static let tapSlop: CGFloat = 10
    /// How far beyond the label's rect a touch still counts as "on the label" when the
    /// menu is open, for the re-tap-to-close shrink. The bare anchor is a small target,
    /// so pad it generously to make the press feedback fire reliably.
    static let labelPressHitSlop: CGFloat = 24

    static let highlightFill = Color(.tertiarySystemFill)
    /// iOS 26 rows highlight with a rounded, inset shape rather than full-bleed.
    static let highlightCornerRadius: CGFloat = 14
}

// MARK: - DropdownCustomMenu

/// Which edge of the label the menu aligns its corresponding edge to.
/// `.automatic` picks the edge by whichever screen half the label's centre sits
/// in (the native default) — use `.leading` / `.trailing` when the label is wide
/// enough that its centre is ambiguous (e.g. a full-width row with a Spacer).
enum DropdownCustomMenuAlignment {
    case leading, trailing, automatic
}

struct DropdownCustomMenu<Content: View, Label: View>: View {

    @ViewBuilder var content: () -> Content
    @ViewBuilder var label: () -> Label
    /// Corner radius of the menu platter itself. `nil` uses the spec defaults
    /// (26pt on iOS 26's glass, 13pt on the pre-26 platter); pass a value to
    /// override from the call site without touching `DropdownCustomMenu`.
    var cornerRadius: CGFloat?
    /// The label's own corner radius, so the iOS 26 dismiss reveal lands the glass
    /// back on the label's shape (defaults to a capsule). Only used by the close
    /// morph's final circle → label relax; mismatched corners read as a snap.
    var labelCornerRadius: CGFloat?
    /// Per-corner platter radii, for cards whose top/bottom corners differ. When
    /// set it overrides `cornerRadius`, and the footer (if any) uses the vertical
    /// mirror of these so a card + footer read as one split rounded group.
    var cornerRadii: RectangleCornerRadii?
    /// Explicit footer corners. `nil` keeps the mirror-of-platter default; set this
    /// to give the footer its own radii independent of the platter.
    var footerCornerRadii: RectangleCornerRadii?
    /// Which label edge the menu aligns to (see `DropdownCustomMenuAlignment`).
    var alignment: DropdownCustomMenuAlignment
    /// iOS 26 glass bloom origin. `false` (default) grows the platter from / collapses
    /// it back into the label's full frame (the whole button). `true` reverts to the
    /// original behaviour: a small circle at the label's trailing edge. No effect on
    /// the pre-26 fallback (which always scales from an anchor point near the label).
    var morphsFromTrailingPoint: Bool
    /// When `true`, a no-change dismiss flexes the label instead of running the circle morph:
    /// re-selecting the already-selected row uses `dismiss(.flex)`, and a tap-away (which is
    /// always no-change) flexes too. `false` (default) keeps every dismiss on the morph.
    var flexOnEmptyDismiss: Bool
    /// Nudge applied to the final placement (positive = right / down). Defaults
    /// to the spec values; override per call site to fine-tune.
    var placementOffset: CGSize
    /// Fires the instant the menu is requested to open (on touch-down, before the
    /// bloom animation) — not when the content view appears, so there's no morph
    /// lag. Use this instead of `.onAppear` on the content.
    var onOpen: (() -> Void)?
    /// Fires the instant dismissal is requested (any path: tap-away, drag-release,
    /// selection, programmatic) — not when the close morph + teardown finishes, so
    /// there's no ~0.58s lag. Use this instead of `.onDisappear` on the content.
    var onClose: (() -> Void)?
    /// Optional detached accessory card rendered as its own platter below the main menu,
    /// with a gap (the wallpaper shows through). The footer supplies its own material via
    /// `.dropdownCustomMenuFooterPlatter`; DropdownCustomMenu only sizes, positions and morphs it. It is
    /// never part of the lens morph — it fades/scales in once the menu is open and out on
    /// close. `nil` (the default) means no footer, so existing call sites are unaffected.
    /// Items inside it use `.dropdownCustomMenuItem` / `dropdownCustomMenuDismiss` just like content.
    var footer: (() -> AnyView)?

    @State private var controller = DropdownCustomMenuController()
    @State private var labelFrame: CGRect = .zero
    @GestureState private var isPressed = false

    init(cornerRadius: CGFloat? = nil,
         cornerRadii: RectangleCornerRadii? = nil,
         footerCornerRadii: RectangleCornerRadii? = nil,
         labelCornerRadius: CGFloat? = nil,
         alignment: DropdownCustomMenuAlignment = .automatic,
         morphsFromTrailingPoint: Bool = false,
         flexOnEmptyDismiss: Bool = false,
         placementOffsetX: CGFloat = DropdownCustomMenuSpec.placementOffsetX,
         placementOffsetY: CGFloat = DropdownCustomMenuSpec.placementOffsetY,
         onOpen: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil,
         footer: (() -> AnyView)? = nil,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder label: @escaping () -> Label) {
        self.cornerRadius = cornerRadius
        self.cornerRadii = cornerRadii
        self.footerCornerRadii = footerCornerRadii
        self.labelCornerRadius = labelCornerRadius
        self.alignment = alignment
        self.morphsFromTrailingPoint = morphsFromTrailingPoint
        self.flexOnEmptyDismiss = flexOnEmptyDismiss
        self.placementOffset = CGSize(width: placementOffsetX, height: placementOffsetY)
        self.onOpen = onOpen
        self.onClose = onClose
        self.footer = footer
        self.content = content
        self.label = label
    }

    var body: some View {
        // The label stays in place while the menu is open: the glass platter blooms
        // out of a small circle at the label's trailing edge, so the real label is
        // always visible underneath (never swallowed/hidden). It reflows naturally
        // on selection, so the close morph collapses onto its current value.
        // Same shrink + opacity as `.shrinkPress`, reusing only the shared
        // `PressEffect.shrink` *values*. The press is driven by this view's own
        // `isPressed` gesture state below, so all of the drop-down's tap/press logic
        // lives in this file (no second gesture from PressEffectModifier to fight
        // `pressAndDrag`, and nothing added to ButtonPressStyle).
        let press = PressEffect.shrink
        // Shrink while the finger is on the label — whether the menu is closed (this
        // view's own `pressAndDrag` sets `isPressed`) or already open (the overlay
        // window sits on top and swallows the touch, so it reports the press back
        // through `controller.labelPressed`). Without the second term, re-tapping the
        // label to close it wouldn't shrink, since this view's gesture never sees it.
        let pressed = isPressed || controller.labelPressed
        // While the iOS 26 dismiss runs, the overlay carries a pixel-identical copy of
        // the label and morphs it (label → centred glass circle → label). Hide the real
        // one for that window so we don't see a static double underneath the morph; the
        // overlay restores it (under the copy) right before melting the halo + teardown.
        let _ = syncPresentedLabel()
        return label()
            .contentShape(Rectangle())
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                labelFrame = frame
                // Keep the close target on the label's current frame (it reflows
                // when a selection changes its text) so the morph lands cleanly.
                controller.updateCollapseAnchor(frame)
            }
            // Press feedback applied AFTER the geometry read so the shrink transform
            // never feeds back into the anchor frame used to place/collapse the menu.
            .scaleEffect(pressed ? press.scale : 1)
            .opacity(controller.hidesLabel ? 0 : (pressed ? press.opacity : 1))
            .animation(pressed
                       ? .snappy(duration: press.pressDuration)
                       : .spring(response: press.release.response, dampingFraction: press.release.damping),
                       value: pressed)
            // `.flex` dismiss: a quick scale-up + lift that settles back, in place of the
            // circle morph when nothing changed. Applied after the geometry read (like the
            // press shrink) so it never feeds the flex transform back into the anchor frame.
            .scaleEffect(controller.flexing ? DropdownCustomMenuSpec.flexScale : 1)
            .offset(y: controller.flexing ? DropdownCustomMenuSpec.flexOffsetY : 0)
            .animation(controller.flexing ? DropdownCustomMenuSpec.flexUp
                                          : DropdownCustomMenuSpec.flexDown,
                       value: controller.flexing)
            .gesture(pressAndDrag)
            .onDisappear { controller.dismiss(style: .instant) }
    }

    /// Pushes the freshest label closure into the controller while presented, so the
    /// dismiss morph's carried copy shows the current value (e.g. the chevron flips to
    /// closed the instant dismissal begins) rather than the snapshot taken at open time.
    /// Deferred one runloop turn so it lands cleanly after the current update pass.
    /// No-op while the menu is closed.
    private func syncPresentedLabel() {
        guard controller.isPresented else { return }
        let makeLabel = label
        DispatchQueue.main.async {
            controller.updateLabel { AnyView(makeLabel()) }
        }
    }

    /// The label presses (shrinks) under the finger via `$isPressed`, then expands
    /// the menu on release — a completed tap — instead of on touch-down, so it reads
    /// like a normal button tap. (This drops the native press-drag-to-select flow;
    /// once the menu is open, items are chosen by tapping them.)
    private var pressAndDrag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($isPressed) { _, state, _ in state = true }
            .onEnded { value in
                guard !controller.isPresented else { return }
                // Releases that travelled too far are scrolls/drags, not taps.
                let distance = hypot(value.translation.width, value.translation.height)
                guard distance < DropdownCustomMenuSpec.tapSlop else { return }
                onOpen?()
                controller.present(
                    anchor: labelFrame,
                    cornerRadius: cornerRadius,
                    cornerRadii: cornerRadii,
                    footerCornerRadii: footerCornerRadii,
                    labelCornerRadius: labelCornerRadius,
                    alignment: alignment,
                    morphsFromTrailingPoint: morphsFromTrailingPoint,
                    flexOnEmptyDismiss: flexOnEmptyDismiss,
                    placementOffset: placementOffset,
                    onClose: onClose,
                    footer: footer,
                    label: { AnyView(label()) },
                    content: { AnyView(content()) }
                )
            }
    }
}

// MARK: - Dismiss action environment

/// How the menu leaves the screen.
/// - `morph`: the default glass bloom-close (the platter shrinks back into the label).
/// - `pop`: removes the platter + footer with the `.scoopPop` transition (blur + scale).
/// - `flex`: pops the platter like `.pop`, but instead of the circle morph it gives the
///   (still-visible) label a quick scale-up + lift that settles back — for a no-change
///   dismiss, where the morph would just shrink and re-expand the same label. See the
///   `.flex` spec block and `flexLabel()`.
/// - `instant`: tears the window down immediately, no animation.
enum DropdownCustomMenuDismissStyle { case morph, pop, flex, instant }

struct DropdownCustomMenuDismissAction {
    /// Pass a `DropdownCustomMenuDismissStyle` to pick the exit (default `.morph`). E.g.
    /// `dismiss(.pop)` for the scoopPop transition, `dismiss(.instant)` for no animation.
    var action: (DropdownCustomMenuDismissStyle) -> Void = { _ in }
    func callAsFunction(_ style: DropdownCustomMenuDismissStyle = .morph) { action(style) }
}

/// Freezes the menu's label to a bitmap of its CURRENT value. Call from content *before*
/// you mutate the state the label reads, then dismiss with `.morph`: the dismiss then
/// collapses the OLD label into the circle and only reveals the NEW value as it expands.
/// Only needed for content that selects via its own gesture (e.g. `.shrinkPress`) instead of
/// `.dropdownCustomMenuItem`, which already freezes at the right moment. No-op once frozen
/// or while closed, so a stray call can't double-capture the wrong value.
struct DropdownCustomMenuFreezeLabelAction {
    var action: () -> Void = {}
    func callAsFunction() { action() }
}

extension EnvironmentValues {
    @Entry var dropdownCustomMenuDismiss = DropdownCustomMenuDismissAction()
    /// Snapshot the label before a self-driven selection mutates it; see the action's docs.
    @Entry var dropdownCustomMenuFreezeLabel = DropdownCustomMenuFreezeLabelAction()
    /// True inside the hidden copy used only for sizing — items must not register.
    @Entry var dropdownCustomMenuIsMeasuring = false
}

// MARK: - Content modifiers

extension View {
    /// Marks a view as a selectable menu row: it highlights while a drag hovers it,
    /// fires `action` on tap or drag-release, and dismisses the menu.
    func dropdownCustomMenuItem(action: @escaping () -> Void) -> some View {
        modifier(DropdownCustomMenuItemModifier(action: action))
    }

    /// The detached menu-footer material — glass on iOS 26, frosted material + soft shadow
    /// on the classic platter — so a footer card matches the menu's own material. Exposed
    /// (rather than imposed by DropdownCustomMenu) so a footer owns its platter: a press effect on
    /// the footer then scales the whole glass card, not just its inner content.
    func dropdownCustomMenuFooterPlatter(corners: RectangleCornerRadii) -> some View {
        modifier(DropdownCustomMenuFooterPlatter(corners: corners))
    }
}

struct DropdownCustomMenuFooterPlatter: ViewModifier {
    let corners: RectangleCornerRadii
    func body(content: Content) -> some View {
        let shape = UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
                // Cancel the platter's drop shadow that bleeds onto this footer (it
                // sits a hair below the platter at a lower z, so the shadow paints
                // over it). Pre-brightening here lands the footer back on the
                // platter's tone once that shadow darkens it. See footerShadowCompensation.
                .brightness(DropdownCustomMenuSpec.footerShadowCompensation)
        } else {
            content
                .background(shape.fill(.regularMaterial))
                .clipShape(shape)
                .shadow(color: .black.opacity(0.12), radius: 24, y: 16)
        }
    }
}

private struct DropdownCustomMenuItemModifier: ViewModifier {
    @Environment(DropdownCustomMenuController.self) private var controller: DropdownCustomMenuController?
    @Environment(\.dropdownCustomMenuIsMeasuring) private var isMeasuring
    let action: () -> Void
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .background {
                if controller?.highlightedItemID == id {
                    if #available(iOS 26.0, *) {
                        RoundedRectangle(cornerRadius: DropdownCustomMenuSpec.highlightCornerRadius, style: .continuous)
                            .fill(DropdownCustomMenuSpec.highlightFill)
                            .padding(3)
                    } else {
                        DropdownCustomMenuSpec.highlightFill
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
final class DropdownCustomMenuController {

    enum Phase { case measuring, shown, dismissing }

    private(set) var phase: Phase = .measuring
    /// How the in-flight dismissal should animate; the overlay reads it to pick the exit.
    private(set) var dismissStyle: DropdownCustomMenuDismissStyle = .morph
    private(set) var anchor: CGRect = .zero
    /// The label's *live* frame, tracked while presented so the close morph
    /// collapses onto where the label is now (it may have reflowed after a
    /// selection), not the frame captured at open time. Placement keeps using the
    /// fixed `anchor` so the open menu never moves underfoot.
    private(set) var collapseAnchor: CGRect = .zero
    private(set) var content: (() -> AnyView)?
    /// Pixel-identical copy of the label, carried by the overlay only during the iOS 26
    /// dismiss so it can morph (label → centred circle → label). The real label hides
    /// while this is on screen. `nil` while open (the real label shows underneath).
    private(set) var labelView: (() -> AnyView)?
    /// Detached accessory rendered as its own glass card below the platter.
    private(set) var footer: (() -> AnyView)?
    /// The label's own corner radius, so the dismiss reveal lands the glass back on the
    /// label's shape (capsule by default). See `DropdownCustomMenu.labelCornerRadius`.
    private(set) var labelCornerRadius: CGFloat?
    /// Caller-supplied platter corner radius; `nil` falls back to the spec value.
    private(set) var cornerRadius: CGFloat?
    /// Caller-supplied per-corner platter radii; overrides `cornerRadius` when set.
    private(set) var cornerRadii: RectangleCornerRadii?
    /// Caller-supplied footer corners; `nil` falls back to the mirror of the platter.
    private(set) var footerCornerRadii: RectangleCornerRadii?
    private(set) var alignment: DropdownCustomMenuAlignment = .automatic
    /// Caller-supplied: iOS 26 glass bloom grows from a small trailing-edge circle
    /// instead of the whole button. See `DropdownCustomMenu.morphsFromTrailingPoint`.
    private(set) var morphsFromTrailingPoint = false
    private(set) var placementOffset: CGSize = .zero
    /// iOS 26 dismiss: the real label hides while the overlay carries + morphs its copy
    /// (it is the morphing circle now), then is restored under the copy at the very end.
    private(set) var hidesLabel = false
    /// iOS 26 dismiss phase 2: flipped true once the rectangular collapse has reached the
    /// circle, so the overlay runs the circle → label reveal (borrowed from TimeCustomMenu).
    private(set) var revealing = false
    /// `.flex` dismiss pulse: pulsed true→false so the (visible) label scales up + lifts and
    /// settles back. The label observes it; see `DropdownCustomMenuSpec`'s `.flex` block.
    private(set) var flexing = false
    /// Caller opt-in: a tap-away (dismiss with no selection) uses `.flex` instead of `.morph`,
    /// so backing out of the menu flexes the label rather than running the circle morph.
    private(set) var flexOnEmptyDismiss = false
    /// The label as it looked the instant dismissal began, frozen to a bitmap so a
    /// just-selected NEW value doesn't appear while the label shrinks: the OLD label
    /// collapses into the circle, and only the live/new label is revealed as it expands
    /// back out. Captured *before* the selection action mutates state. Cleared on teardown.
    private(set) var frozenLabelImage: UIImage?
    private(set) var highlightedItemID: UUID?
    /// Laid-out menu frame in screen coordinates, set by the overlay.
    var menuFrame: CGRect = .zero
    /// While the menu is open the overlay window covers the label, so the label's own
    /// gesture can't see a press on it. The overlay sets this when a touch lands on the
    /// anchor rect, and the label observes it (cross-window, same controller) to shrink
    /// — so re-tapping the label to close it still presses, just like opening it does.
    var labelPressed = false

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
                 cornerRadius: CGFloat? = nil,
                 cornerRadii: RectangleCornerRadii? = nil,
                 footerCornerRadii: RectangleCornerRadii? = nil,
                 labelCornerRadius: CGFloat? = nil,
                 alignment: DropdownCustomMenuAlignment,
                 morphsFromTrailingPoint: Bool = false,
                 flexOnEmptyDismiss: Bool = false,
                 placementOffset: CGSize,
                 onClose: (() -> Void)? = nil,
                 footer: (() -> AnyView)? = nil,
                 label: (() -> AnyView)? = nil,
                 content: @escaping () -> AnyView) {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive })
        else { return }

        self.anchor = anchor
        self.collapseAnchor = anchor
        self.cornerRadius = cornerRadius
        self.cornerRadii = cornerRadii
        self.footerCornerRadii = footerCornerRadii
        self.labelCornerRadius = labelCornerRadius
        self.alignment = alignment
        self.morphsFromTrailingPoint = morphsFromTrailingPoint
        self.flexOnEmptyDismiss = flexOnEmptyDismiss
        self.placementOffset = placementOffset
        self.onClose = onClose
        self.footer = footer
        self.labelView = label
        self.content = content
        phase = .measuring

        let host = UIHostingController(rootView: DropdownCustomMenuOverlayRoot(controller: self))
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

    /// Tracks the label's live frame so the close morph lands exactly on it even
    /// after a selection reflows the label. No-op while not presented.
    func updateCollapseAnchor(_ frame: CGRect) {
        guard window != nil, frame != .zero else { return }
        collapseAnchor = frame
    }

    /// Re-points the carried label copy at the latest closure so the dismiss morph
    /// shrinks/reveals the current value rather than the snapshot captured when the
    /// menu opened. No-op while not presented.
    func updateLabel(_ label: @escaping () -> AnyView) {
        guard window != nil else { return }
        labelView = label
    }

    /// Snapshots the label to a bitmap so the OLD value survives the dismiss shrink even
    /// after the selection mutates the underlying state (the live label reads bindings, so
    /// it would otherwise flip to the new value immediately). Captured once per dismiss —
    /// call it *before* the selection action runs. No-op if already frozen or no label.
    ///
    /// Exposed (via `\.dropdownCustomMenuFreezeLabel`) so content that selects through its
    /// OWN gesture — e.g. SelectTypeView's `.shrinkPress`, which mutates state and then calls
    /// `dropdownCustomMenuDismiss` directly — can freeze the old label up front. Those rows
    /// never go through `select(id:)`, so the only other freeze is the one inside `dismiss()`,
    /// which runs *after* the mutation and would capture the already-updated value (the bug
    /// where the just-picked title shrinks and re-expands instead of the old one shrinking).
    func freezeLabel() {
        guard frozenLabelImage == nil, let labelView else { return }
        let renderer = ImageRenderer(content: labelView())
        renderer.scale = window?.traitCollection.displayScale ?? 3
        renderer.isOpaque = false
        frozenLabelImage = renderer.uiImage
    }

    func dismiss(style: DropdownCustomMenuDismissStyle = .morph) {
        guard window != nil, phase != .dismissing else { return }
        // Fire the moment dismissal is requested — before any close animation runs —
        // so callers don't wait out the animation + teardown.
        onClose?()
        guard style != .instant else { tearDown(); return }
        dismissStyle = style
        phase = .dismissing
        let gen = generation
        if style == .pop || style == .flex {
            // Both melt the platter + footer with the `.scoopPop` transition (driven by the
            // overlay off `phase`); `.flex` additionally pulses the still-visible label.
            // Tear the window down once that spring has settled.
            if style == .flex { flexLabel() }
            Task {
                try? await Task.sleep(for: .seconds(DropdownCustomMenuSpec.popCloseDuration))
                if generation == gen { tearDown() }
            }
            return
        }
        if #available(iOS 26.0, *) {
            // New dismiss choreography (see DropdownCustomMenuSpec dismiss block):
            //   Phase 1 — the platter does its normal rectangular collapse toward the
            //             label, then pinches into a centred glass circle, while the
            //             label copy shrinks into that same circle.
            //   Phase 2 — the circle expands back into the label's rectangle and the
            //             label is revealed.
            //   Tail   — restore the real label under the copy → melt the halo → teardown.
            // The overlay (DropdownCustomMenuOverlayRoot.runMorphDismiss) drives all three,
            // chaining each step off the previous animation's *completion* rather than a
            // wall-clock timer, so the sequence can't desync from the animation under load
            // and there's no dead stop at the apex. The hand-offs call back into
            // `enterRevealPhase` / `restoreLabel` / `finishMorphDismiss` below.
            // Freeze the label for non-selection dismisses (tap-away / programmatic);
            // a selection already froze the OLD value before mutating state. No-op if
            // already frozen, so the selection's freeze is never overwritten.
            freezeLabel()
            // Hide the real label only if we have a copy to morph in its place; without
            // one we'd leave a gap, so fall back to leaving it visible.
            if labelView != nil { hidesLabel = true }
            // Safety net only: if a completion handler is ever dropped, this guarantees the
            // window is still torn down. The normal path beats it via `finishMorphDismiss`,
            // which bumps `generation` so this no-ops.
            Task {
                try? await Task.sleep(for: .seconds(DropdownCustomMenuSpec.dismissSafetyTimeout))
                if generation == gen, phase == .dismissing { tearDown() }
            }
        } else {
            Task {
                try? await Task.sleep(for: .seconds(DropdownCustomMenuSpec.teardownDelay))
                if generation == gen { tearDown() }
            }
        }
    }

    /// The `.flex` pulse: lift the label, then settle it back. The label reads `flexing` and
    /// animates the scale/offset itself (`flexUp` on the way up, `flexDown` on the settle); we
    /// just toggle the flag with a brief hold between. The label lives in the app tree (not the
    /// overlay window), so it keeps settling after the window tears down. No-op if not presented.
    private func flexLabel() {
        guard window != nil else { return }
        flexing = true
        let gen = generation
        Task {
            try? await Task.sleep(for: .seconds(DropdownCustomMenuSpec.flexHold))
            if generation == gen { flexing = false }
        }
    }

    // MARK: iOS 26 morph dismiss hand-offs (called by the overlay on each animation's completion)

    /// Phase 1 → 2: the rectangular collapse has reached the circle, so reveal the live/new
    /// label as it expands back out. Guarded so a stale completion can't act after teardown.
    func enterRevealPhase() {
        guard phase == .dismissing else { return }
        revealing = true
    }

    /// Phase 2 done: restore the real (now-current) label under the copy, just before the
    /// overlay melts the leftover halo.
    func restoreLabel() {
        guard phase == .dismissing else { return }
        hidesLabel = false
    }

    /// Halo melted: the morph is finished, tear the window down.
    func finishMorphDismiss() {
        guard phase == .dismissing else { return }
        tearDown()
    }

    private func tearDown() {
        generation += 1
        window?.isHidden = true
        window = nil
        onClose = nil
        content = nil
        labelView = nil
        footer = nil
        labelCornerRadius = nil
        cornerRadius = nil
        cornerRadii = nil
        footerCornerRadii = nil
        alignment = .automatic
        morphsFromTrailingPoint = false
        placementOffset = .zero
        collapseAnchor = .zero
        items = [:]
        highlightedItemID = nil
        menuFrame = .zero
        hidesLabel = false
        revealing = false
        flexing = false
        flexOnEmptyDismiss = false
        frozenLabelImage = nil
        labelPressed = false
        dismissStyle = .morph
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
        // Freeze the OLD label BEFORE the action mutates state, so the just-selected new
        // value stays hidden until the circle expands back out.
        freezeLabel()
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
        if let id = highlightedItemID, let item = items[id] {
            item.action()
            dismiss()
        } else if distance >= DropdownCustomMenuSpec.tapSlop,
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

private struct DropdownCustomMenuOverlayRoot: View {

    let controller: DropdownCustomMenuController

    @State private var menuSize: CGSize?
    @State private var contentIdealHeight: CGFloat?
    @State private var appeared = false
    /// iOS 26 bloom: 0 = small circle at the label's trailing edge, 1 = full menu platter.
    /// Also drives dismiss phase 1 (1 = open platter → 0 = centred circle).
    @State private var morphProgress: CGFloat = 0
    /// iOS 26 dismiss phase 2: 0 = circle, 1 = relaxed back onto the label (reveal).
    @State private var revealProgress: CGFloat = 0
    /// iOS 26: present for the whole bloom; melts off at the very end of the
    /// close so the leftover glass never pops.
    @State private var lensOpacity: Double = 0
    /// `.pop` dismiss: flipped true to remove the platter + footer with the
    /// `.scoopPop` transition (instead of the morph close). The window tears down
    /// after `popCloseDuration`.
    @State private var popExit = false

    private var overlapsAnchor: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = Metrics(geo: geo, anchor: controller.anchor, overlapsAnchor: overlapsAnchor,
                                  alignment: controller.alignment, placementOffset: controller.placementOffset)
            ZStack(alignment: .topLeading) {
                // Swallows every outside touch, exactly like the native menu. A touch
                // that lands on the label (the anchor rect) drives the label's shrink
                // through the controller — the overlay window covers the label, so its
                // own gesture can't see this press — then dismisses on release, so
                // re-tapping the label to close it presses just like opening it.
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                            .onChanged { value in
                                // Pad the label rect so taps just outside it still press.
                                let hit = controller.anchor.insetBy(dx: -DropdownCustomMenuSpec.labelPressHitSlop,
                                                                    dy: -DropdownCustomMenuSpec.labelPressHitSlop)
                                controller.labelPressed = hit.contains(value.startLocation)
                            }
                            .onEnded { _ in
                                controller.labelPressed = false
                                // Tap-away is always a no-change dismiss: flex the label
                                // instead of the circle morph when the caller opted in.
                                controller.dismiss(style: controller.flexOnEmptyDismiss ? .flex : .morph)
                            }
                    )

                // Detached accessory rides UNDER the platter (lower z) so it emerges
                // from the menu's bottom edge during the bloom (placed once sized).
                // On a `.pop` dismiss it's removed with the platter via `.scoopPop`.
                if let footer = controller.footer, controller.menuFrame != .zero, !popExit {
                    footerCard(footer())
                        .transition(.scoopPop)
                }

                // `.pop` dismiss removes this with the `.scoopPop` transition; the morph
                // close instead keeps it mounted and animates `morphProgress` to 0.
                if let content = controller.content, !popExit {
                    if #available(iOS 26.0, *) {
                        glassPresentation(content: content(), metrics: metrics)
                            .transition(.scoopPop)
                    } else {
                        legacyPresentation(content: content(), metrics: metrics)
                            .transition(.scoopPop)
                    }
                }
            }
            .onChange(of: geo.size) { _, _ in
                controller.dismiss(style: .instant)
            }
            .onChange(of: controller.phase) { _, newPhase in
                guard newPhase == .dismissing else { return }
                if controller.dismissStyle == .pop || controller.dismissStyle == .flex {
                    // Remove the platter + footer with the scoopPop transition. (`.flex` also
                    // pulses the label, driven by the controller — see `flexLabel()`.)
                    withAnimation(.scoopPop) { popExit = true }
                } else if #available(iOS 26.0, *) {
                    runMorphDismiss()
                }
            }
        }
        .ignoresSafeArea()
    }

    /// Drives the iOS 26 morph dismiss as one completion-chained sequence, so each phase
    /// starts off the *previous animation's completion* rather than a wall-clock timer —
    /// the steps can't desync from the animation under load, and phase 2 picks up the
    /// instant the collapse logically reaches the circle (no dead stop at the apex).
    @available(iOS 26.0, *)
    private func runMorphDismiss() {
        // Phase 1 — rectangular collapse → centred circle. `logicallyComplete` fires the
        // moment the collapse reaches the circle (a touch before it fully settles), so the
        // reveal flows straight out of it.
        withAnimation(DropdownCustomMenuSpec.collapseToCircle, completionCriteria: .logicallyComplete) {
            morphProgress = 0
        } completion: {
            // Phase 2 — circle → label reveal. The label layer switches to the live/new
            // label here (controller.revealing flips); it may overshoot slightly for the pop.
            controller.enterRevealPhase()
            withAnimation(DropdownCustomMenuSpec.circleReveal, completionCriteria: .removed) {
                revealProgress = 1
            } completion: {
                // Tail — the copy has settled on the label, so restore the real (now-current)
                // label under it, melt the leftover halo, then tear the window down.
                controller.restoreLabel()
                withAnimation(DropdownCustomMenuSpec.lensFadeOut) {
                    lensOpacity = 0
                } completion: {
                    controller.finishMorphDismiss()
                }
            }
        }
    }

    // MARK: Detached footer accessory

    /// A separate card sitting a gap below the platter — never part of the lens morph. The
    /// footer draws its own material (`.dropdownCustomMenuFooterPlatter`); here we only fade + scale
    /// it in once the menu is shown and out the instant dismissal begins. Positioned off the
    /// platter's settled `menuFrame`, so it tracks width/placement automatically. Items inside
    /// it get the same `controller` + `dropdownCustomMenuDismiss` environment as the menu content, so
    /// `.dropdownCustomMenuItem` and `@Environment(\.dropdownCustomMenuDismiss)` work identically.
    @ViewBuilder
    private func footerCard(_ footer: AnyView) -> some View {
        let frame = controller.menuFrame

        // The footer is a self-contained card: it draws its OWN platter (via
        // `.dropdownCustomMenuFooterPlatter`) and its own press effect, so a tap scales the whole
        // glass card rather than just its inner content. DropdownCustomMenu only sizes, positions
        // and morphs it; items inside still get the menu's environment for dismiss/highlight.
        let card = footer
            .environment(controller)
            .environment(\.dropdownCustomMenuDismiss, DropdownCustomMenuDismissAction { [weak controller] style in
                controller?.dismiss(style: style)
            })
            .fixedSize()                                    //let the footer keep its own width

        if #available(iOS 26.0, *) {
            // Rides the platter's bloom: tracks the menu's interpolated bottom edge as
            // it grows downward and materializes with it, so it slides out from under
            // the menu instead of popping in — and reverses on close.
            card.modifier(FooterMorph(
                progress: morphProgress,
                top: frame.minY,
                bottom: frame.maxY,
                gap: DropdownCustomMenuSpec.footerGap,
                leftX: frame.minX,
                width: frame.width
            ))
        } else {
            // Pre-26 has no lens morph; fall back to a simple fade/scale at rest.
            let visible = appeared && controller.phase == .shown
            card
                .frame(width: frame.width)
                .opacity(visible ? 1 : 0)
                .scaleEffect(visible ? 1 : 0.96, anchor: .top)
                .animation(.easeOut(duration: 0.18), value: visible)
                .offset(x: frame.minX, y: frame.maxY + DropdownCustomMenuSpec.footerGap)
        }
    }

    /// The footer's share of the lens bloom. As `progress` goes 0→1 the card tracks the
    /// menu's interpolated bottom edge (top → bottom) and a gap below it, fading in over
    /// the back half — the same window the menu content materializes in — so it reads as
    /// emerging from under the platter rather than appearing in place. `Animatable`, so
    /// SwiftUI interpolates it every spring frame in lockstep with the menu morph; the
    /// close (progress 1→0) runs it in reverse, sliding the card back up and out.
    @available(iOS 26.0, *)
    private struct FooterMorph: ViewModifier, Animatable {
        var progress: CGFloat
        /// Menu's top / bottom edge in screen space. Animatable alongside
        /// `progress`: post-open the platter reflows (an info row expands) and
        /// `bottom` grows — interpolating it here lets the footer glide down with
        /// the card on the reflow curve instead of snapping to the new edge.
        var top: CGFloat
        var bottom: CGFloat
        let gap: CGFloat
        /// Menu's left edge + width, so the card centres under the platter.
        let leftX: CGFloat
        let width: CGFloat

        // (progress, (top, bottom)) — the bloom drives progress while the edges
        // hold; a reflow holds progress while the edges move. Both interpolate.
        var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
            get { AnimatablePair(progress, AnimatablePair(top, bottom)) }
            set {
                progress = newValue.first
                top = newValue.second.first
                bottom = newValue.second.second
            }
        }

        func body(content: Content) -> some View {
            let p = progress
            // Follow the platter's interpolated bottom edge as it grows down.
            let edge = top + (bottom - top) * p
            // Materialize on the menu content's own ramp (0.55→1 of the bloom).
            let appear = Double(((p - 0.55) / 0.45).clamped(to: 0...1))
            content
                .frame(width: width)
                .scaleEffect(0.97 + 0.03 * appear, anchor: .top)
                .opacity(appear)
                .offset(x: leftX, y: edge + gap)
        }
    }

    // MARK: iOS 26 — Liquid Glass bloom

    /// The iOS 26 glass bloom: on open, the platter grows out of the label's full
    /// frame (the whole button) straight into the menu's rect while the menu
    /// content de-blurs and materializes. Dismissal is the exact reverse — the
    /// platter shrinks back into the button's frame and the glass melts off.
    /// The real label stays visible underneath the whole time (never captured).
    /// One persistent glass view + Animatable frame interpolation (MenuLensMorph);
    /// no glass transitions involved (the broken ones aren't needed).
    @available(iOS 26.0, *)
    @ViewBuilder
    private func glassPresentation(content: AnyView, metrics: Metrics) -> some View {
        // Hidden sizing copy: always laid out so the platter's final rect is
        // known before the morph starts.
        chromeCore(content: content, metrics: metrics)
            .environment(\.dropdownCustomMenuIsMeasuring, true)
            .opacity(0)
            .allowsHitTesting(false)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                let placed = CGRect(origin: metrics.placement(for: size).origin, size: size)
                if appeared {
                    // Post-open reflow (e.g. an info row expanded): animate the
                    // platter's height (menuSize) AND the footer's anchor
                    // (menuFrame) on the same curve, so the detached footer glides
                    // down with the growing card instead of snapping to the new
                    // edge while the platter eases.
                    withAnimation(DropdownCustomMenuSpec.reflowResize) {
                        controller.menuFrame = placed
                        menuSize = size
                    }
                } else {
                    controller.menuFrame = placed
                    menuSize = size
                    // Wait for the scroll-capped pass before blooming oversized menus.
                    if size.height <= metrics.maxHeight + 1 {
                        appeared = true
                        controller.markShown()
                        // The glass starts at the label's full frame, so it's on
                        // screen instantly (no fade-in lag between tap and motion).
                        // The real label stays in place underneath — it is never
                        // hidden or swallowed.
                        lensOpacity = 1
                        // Escape the layout transaction so the morph animates from a
                        // committed frame instead of snapping on initial render.
                        DispatchQueue.main.async {
                            withAnimation(DropdownCustomMenuSpec.bloomOpen) {
                                morphProgress = 1
                            }
                        }
                    }
                }
            }

        if let size = menuSize {
            let menuRect = CGRect(origin: metrics.placement(for: size).origin, size: size)
            // Collapse onto the label's live frame, falling back to the open-time
            // anchor before the first geometry update lands. The morph grows from /
            // shrinks back into this full frame.
            let collapsedRect = controller.collapseAnchor == .zero ? controller.anchor : controller.collapseAnchor
            // The default `.morph` dismiss hands off to the new circle-collapse → reveal
            // choreography (dismissPresentation); the open bloom (and the brief pre-removal
            // frame of a `.pop` dismiss) stay on MenuLensMorph.
            let isMorphDismiss = controller.phase == .dismissing && controller.dismissStyle == .morph
            // No GlassEffectContainer: with a single glass shape it isn't needed,
            // and the container ignores per-view .opacity (so the glass couldn't
            // fade). Standalone .glassEffect honours it, which is what lets the
            // glass melt out on close.
            // Positioned with layout padding (inside the modifier), never .offset.
            if isMorphDismiss {
                dismissPresentation(content: content, metrics: metrics,
                                    menuRect: menuRect, labelRect: collapsedRect)
            } else {
                ZStack(alignment: .topLeading) {
                    chromeCore(content: content, metrics: metrics)
                        .modifier(MenuLensMorph(
                            progress: morphProgress,
                            collapsed: collapsedRect,
                            expanded: menuRect,
                            platterCorners: controller.cornerRadii
                                ?? RectangleCornerRadii(uniform: controller.cornerRadius ?? DropdownCustomMenuSpec.platterCornerRadius),
                            fromTrailingPoint: controller.morphsFromTrailingPoint,
                            isClosing: controller.phase == .dismissing
                        ))
                        .opacity(lensOpacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    // MARK: iOS 26 — dismiss (rectangular collapse → centred circle → reveal)

    /// The new dismiss: two stacked layers driven by `morphProgress` (phase 1, 1 → 0) and
    /// `revealProgress` (phase 2, 0 → 1), both ending at / starting from one centred glass
    /// circle so the hand-off is seamless.
    ///   • The PLATTER (`PlatterDismissMorph`) shrinks directly into the centred circle —
    ///     the same circle the label copy collapses into — then on reveal relaxes back onto
    ///     the label as its glass melts off — exactly the TimeCustomMenu close ending.
    ///   • The LABEL COPY (`LabelCollapseMorph`) shrinks into the same circle, then is
    ///     revealed on top so it is what finally lands on the label (the real label is
    ///     hidden meanwhile and restored under it just before teardown).
    @available(iOS 26.0, *)
    @ViewBuilder
    private func dismissPresentation(content: AnyView, metrics: Metrics,
                                     menuRect: CGRect, labelRect: CGRect) -> some View {
        // The centred circle both collapse into. Sized off the SMALLER label dimension and
        // clamped, so a tall multi-line label collapses to a tidy circle (not a big blob)
        // and a tiny label still gets a visible one. Centred on the label's original frame.
        let side = (min(labelRect.width, labelRect.height) * DropdownCustomMenuSpec.dismissCircleScale)
            .clamped(to: DropdownCustomMenuSpec.dismissCircleMinDiameter ... DropdownCustomMenuSpec.dismissCircleMaxDiameter)
        let circleRect = CGRect(x: labelRect.midX - side / 2, y: labelRect.midY - side / 2,
                                width: side, height: side)
        let platterCorners = controller.cornerRadii
            ?? RectangleCornerRadii(uniform: controller.cornerRadius ?? DropdownCustomMenuSpec.platterCornerRadius)
        // The label's own shape, so the reveal's final relax lands on it (capsule default).
        let labelCorner = controller.labelCornerRadius ?? labelRect.height / 2

        ZStack(alignment: .topLeading) {
            chromeCore(content: content, metrics: metrics)
                .modifier(PlatterDismissMorph(
                    collapse: morphProgress,
                    reveal: revealProgress,
                    expanded: menuRect,
                    labelRect: labelRect,
                    circleRect: circleRect,
                    platterCorners: platterCorners,
                    labelCornerRadius: labelCorner
                ))
                .opacity(lensOpacity)

            // Collapse shows the OLD label (frozen bitmap, captured before any selection
            // mutated state); the reveal shows the live/new label. They swap at the circle
            // apex where the label's opacity is 0, so the change is never seen mid-air.
            let labelLayer: AnyView? = {
                if !controller.revealing, let frozen = controller.frozenLabelImage {
                    return AnyView(Image(uiImage: frozen))
                }
                return controller.labelView.map { AnyView($0()) }
            }()
            if let labelLayer {
                labelLayer
                    .modifier(LabelCollapseMorph(
                        collapse: morphProgress,
                        reveal: revealProgress,
                        labelRect: labelRect,
                        circleRect: circleRect
                    ))
                    .opacity(lensOpacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Pre-26 — classic scale/fade

    @ViewBuilder
    private func legacyPresentation(content: AnyView, metrics: Metrics) -> some View {
        let visible = appeared && controller.phase == .shown
        let placement = metrics.placement(for: menuSize ?? .zero)
        let platterShape = UnevenRoundedRectangle(
            cornerRadii: controller.cornerRadii
                ?? RectangleCornerRadii(uniform: controller.cornerRadius ?? DropdownCustomMenuSpec.legacyCornerRadius),
            style: .continuous
        )

        chromeCore(content: content, metrics: metrics)
            .background {
                platterShape
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 32, y: 16)
                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
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
            .scaleEffect(visible ? 1 : DropdownCustomMenuSpec.collapsedScale, anchor: placement.anchor)
            .animation(visible ? DropdownCustomMenuSpec.openScale : DropdownCustomMenuSpec.closeScale, value: visible)
            .opacity(visible ? 1 : 0)
            .animation(visible ? DropdownCustomMenuSpec.openFade : DropdownCustomMenuSpec.closeFade, value: visible)
            .opacity(menuSize == nil ? 0 : 1)
            .offset(x: placement.origin.x, y: placement.origin.y)
    }

    // MARK: Shared chrome layout (sizing, scroll cap, environment plumbing)

    @ViewBuilder
    private func chromeCore(content: AnyView, metrics: Metrics) -> some View {
        let inner = content
            .environment(controller)
            .environment(\.dropdownCustomMenuDismiss, DropdownCustomMenuDismissAction { [weak controller] style in
                controller?.dismiss(style: style)
            })
            .environment(\.dropdownCustomMenuFreezeLabel, DropdownCustomMenuFreezeLabelAction { [weak controller] in
                controller?.freezeLabel()
            })
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                contentIdealHeight = height
            }

        Group {
            if let ideal = contentIdealHeight, ideal > metrics.maxHeight {
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

    /// The open/close morph. The glass platter grows directly out of its start shape
    /// straight into the menu's rounded-rect platter, while the menu content de-blurs
    /// and materializes. Closing runs the same path in reverse. The start shape is
    /// either the label's full frame (the whole button, default) or a small circle at
    /// the label's trailing edge (`fromTrailingPoint`). There is no "droplet" or
    /// travelling phase — the shape only ever grows monotonically from start to platter
    /// — and the real label is never captured: it stays visible in the app tree
    /// underneath. Animatable progress drives layout, so SwiftUI interpolates every
    /// spring frame through this modifier.
    @available(iOS 26.0, *)
    private struct MenuLensMorph: ViewModifier, Animatable {
        var progress: CGFloat
        /// The label's live frame (the whole button); the morph grows from / collapses into it.
        let collapsed: CGRect
        let expanded: CGRect
        /// The platter's resting per-corner radii (caller-supplied or spec default).
        let platterCorners: RectangleCornerRadii
        /// When true, the morph starts/ends as a small circle at the label's trailing
        /// edge instead of the whole `collapsed` frame.
        let fromTrailingPoint: Bool
        /// While dismissing, the glass melts off as it shrinks back into the
        /// start shape, so nothing pops at the end.
        let isClosing: Bool

        var animatableData: CGFloat {
            get { progress }
            set { progress = newValue }
        }

        private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
            a + (b - a) * t
        }

        /// A single monotonic growth from the start shape straight to the menu
        /// platter — no intermediate droplet or travelling phase. `p` 0 → 1 grows
        /// and translates the shape from start to platter; the close (1 → 0)
        /// reverses it. The start shape is the whole button by default, or a small
        /// circle at the label's trailing edge when `fromTrailingPoint` is set.
        private func lensFrame(_ p: CGFloat) -> (rect: CGRect, corners: RectangleCornerRadii) {
            let t = p.clamped(to: 0...1)

            // Start shape. Whole-button (default): the label's full frame, growing as
            // if the button itself expands. Trailing-point: a small circle just inside
            // the label's trailing edge, blooming out of that dot. End is the platter.
            let startRect: CGRect
            let startCorner: CGFloat
            if fromTrailingPoint {
                let d = DropdownCustomMenuSpec.expansionOriginDiameter
                startRect = CGRect(x: collapsed.maxX - d, y: collapsed.midY - d / 2, width: d, height: d)
                startCorner = d / 2                                      // a full circle
            } else {
                startRect = collapsed
                startCorner = min(collapsed.width, collapsed.height) / 2 // the button's capsule
            }

            let w = lerp(startRect.width, expanded.width, t)
            let h = lerp(startRect.height, expanded.height, t)
            let cx = lerp(startRect.midX, expanded.midX, t)
            let cy = lerp(startRect.midY, expanded.midY, t)

            // Corners ease from the start shape (circle or capsule) to the platter's
            // resting radii, each capped at a half-side so the shape stays a clean
            // circle/pill/rounded-rect at every step.
            let cap = min(w, h) / 2
            let corners = RectangleCornerRadii(
                topLeading: min(cap, lerp(startCorner, platterCorners.topLeading, t)),
                bottomLeading: min(cap, lerp(startCorner, platterCorners.bottomLeading, t)),
                bottomTrailing: min(cap, lerp(startCorner, platterCorners.bottomTrailing, t)),
                topTrailing: min(cap, lerp(startCorner, platterCorners.topTrailing, t))
            )
            return (CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h), corners)
        }

        func body(content: Content) -> some View {
            let p = progress
            let lens = lensFrame(p)
            let w = lens.rect.width
            let h = lens.rect.height
            // On close, melt the glass off as it shrinks back into the button
            // frame (p → 0) so nothing pops at the end; the real label is already
            // visible underneath, so there is nothing left to restore.
            let glassOpacity: Double = isClosing
                ? Double((p / DropdownCustomMenuSpec.closeGlassFadeProgress).clamped(to: 0...1))
                : 1

            // Glass platter + menu content, scaled from the button frame up to
            // the full platter. The content de-blurs and fades in over the back
            // half of the growth (unchanged from before).
            content
                .frame(width: expanded.width, height: expanded.height, alignment: .topLeading)
                .scaleEffect(x: w / max(expanded.width, 1),
                             y: h / max(expanded.height, 1),
                             anchor: .topLeading)
                .blur(radius: (1 - p).clamped(to: 0...1) * DropdownCustomMenuSpec.lensBlur)
                .opacity(Double(((p - 0.55) / 0.45).clamped(to: 0...1)))
                .frame(width: w, height: h, alignment: .topLeading)
                .glassEffect(.regular, in: UnevenRoundedRectangle(cornerRadii: lens.corners, style: .continuous))
                // Native platters cast a wide soft shadow; it grows with the bloom
                // so the small origin circle casts almost none.
                .shadow(color: .black.opacity(DropdownCustomMenuSpec.platterShadowOpacity * p.clamped(to: 0...1)),
                        radius: DropdownCustomMenuSpec.platterShadowRadius * p.clamped(to: 0...1),
                        y: DropdownCustomMenuSpec.platterShadowY * p.clamped(to: 0...1))
                .opacity(glassOpacity)
                .frame(width: w, height: h, alignment: .topLeading)
                .padding(.leading, max(0, lens.rect.minX))
                .padding(.top, max(0, lens.rect.minY))
        }
    }

    /// The dismiss platter morph. Phase 1 (`collapse` 1 → 0): the platter shrinks directly
    /// from the menu rect into the centred circle — the SAME circle the label copy collapses
    /// into — its corners rounding from the platter's radii to the circle as it goes (no
    /// intermediate stop at the label's rectangle). Phase 2 (`reveal` 0 → 1): the circle
    /// relaxes back onto the label while the glass melts off, so the label copy (layered
    /// above) is what lands. Animatable on both progresses so SwiftUI interpolates every
    /// spring frame.
    @available(iOS 26.0, *)
    private struct PlatterDismissMorph: ViewModifier, Animatable {
        var collapse: CGFloat
        var reveal: CGFloat
        let expanded: CGRect
        let labelRect: CGRect
        let circleRect: CGRect
        let platterCorners: RectangleCornerRadii
        let labelCornerRadius: CGFloat

        var animatableData: AnimatablePair<CGFloat, CGFloat> {
            get { AnimatablePair(collapse, reveal) }
            set { collapse = newValue.first; reveal = newValue.second }
        }

        private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
        private func lerpRect(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
            CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
                   width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
        }
        private func lerpCorners(_ a: RectangleCornerRadii, _ b: RectangleCornerRadii, _ t: CGFloat) -> RectangleCornerRadii {
            RectangleCornerRadii(topLeading: lerp(a.topLeading, b.topLeading, t),
                                 bottomLeading: lerp(a.bottomLeading, b.bottomLeading, t),
                                 bottomTrailing: lerp(a.bottomTrailing, b.bottomTrailing, t),
                                 topTrailing: lerp(a.topTrailing, b.topTrailing, t))
        }

        func body(content: Content) -> some View {
            let circleRadius = min(circleRect.width, circleRect.height) / 2
            // The label's resting radius, capped so a short label stays a clean capsule.
            // Only the reveal (phase 2) lands on it; the collapse goes straight to the circle.
            let labelRadius = min(labelCornerRadius, min(labelRect.width, labelRect.height) / 2)

            let rect: CGRect
            let corners: RectangleCornerRadii
            let contentOpacity: Double
            let glassOpacity: Double
            let blur: CGFloat
            let shadowScale: CGFloat

            if reveal <= 0 {
                let c = collapse.clamped(to: 0...1)
                // menuRect → circle, directly: the platter shrinks straight into the SAME
                // centred circle the label copy collapses into (no intermediate label-rect
                // stop), so platter and label pinch into one circle together. `t` 0 = full
                // menu, 1 = circle; the corners round from the platter's radii to the circle
                // as it shrinks, each capped at a half-side so it stays a clean shape.
                let t = 1 - c
                rect = lerpRect(expanded, circleRect, t)
                let cap = min(rect.width, rect.height) / 2
                let lerped = lerpCorners(platterCorners, RectangleCornerRadii(uniform: circleRadius), t)
                corners = RectangleCornerRadii(
                    topLeading: min(cap, lerped.topLeading),
                    bottomLeading: min(cap, lerped.bottomLeading),
                    bottomTrailing: min(cap, lerped.bottomTrailing),
                    topTrailing: min(cap, lerped.topTrailing)
                )
                contentOpacity = Double(((c - 0.55) / 0.45).clamped(to: 0...1))
                glassOpacity = 1
                blur = (1 - c).clamped(to: 0...1) * DropdownCustomMenuSpec.lensBlur * 0.5
                shadowScale = c.clamped(to: 0...1)
            } else {
                let r = reveal.clamped(to: 0...1)
                rect = lerpRect(circleRect, labelRect, r)
                let cap = min(rect.width, rect.height) / 2
                corners = RectangleCornerRadii(uniform: min(cap, lerp(circleRadius, labelRadius, r)))
                contentOpacity = 0
                // Glass melts to nothing over the final relax onto the label.
                glassOpacity = Double(((1 - r) / DropdownCustomMenuSpec.revealGlassFadeProgress).clamped(to: 0...1))
                blur = 0
                shadowScale = 0
            }

            let w = rect.width
            let h = rect.height
            return content
                .frame(width: expanded.width, height: expanded.height, alignment: .topLeading)
                .scaleEffect(x: w / max(expanded.width, 1), y: h / max(expanded.height, 1), anchor: .topLeading)
                .blur(radius: blur)
                .opacity(contentOpacity)
                .frame(width: w, height: h, alignment: .topLeading)
                .glassEffect(.regular, in: UnevenRoundedRectangle(cornerRadii: corners, style: .continuous))
                .shadow(color: .black.opacity(DropdownCustomMenuSpec.platterShadowOpacity * shadowScale),
                        radius: DropdownCustomMenuSpec.platterShadowRadius * shadowScale,
                        y: DropdownCustomMenuSpec.platterShadowY * shadowScale)
                .opacity(glassOpacity)
                .frame(width: w, height: h, alignment: .topLeading)
                .padding(.leading, max(0, rect.minX))
                .padding(.top, max(0, rect.minY))
        }
    }

    /// The dismiss label-copy morph, on its OWN trajectory (the label and the platter
    /// start apart — the menu is offset from the label — and meet only at the circle).
    /// Phase 1 (`collapse` 1 → 0): labelRect → circle, fading/refracting out as it nears
    /// the circle so the glass circle is all that's left at the apex. Phase 2 (`reveal`
    /// 0 → 1): circle → labelRect, materializing over the back half so it lands as the
    /// restored label. Animatable on both progresses.
    @available(iOS 26.0, *)
    private struct LabelCollapseMorph: ViewModifier, Animatable {
        var collapse: CGFloat
        var reveal: CGFloat
        let labelRect: CGRect
        let circleRect: CGRect

        var animatableData: AnimatablePair<CGFloat, CGFloat> {
            get { AnimatablePair(collapse, reveal) }
            set { collapse = newValue.first; reveal = newValue.second }
        }

        private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
        private func lerpRect(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
            CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
                   width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
        }

        func body(content: Content) -> some View {
            let rect: CGRect
            let opacity: Double
            let blur: CGFloat
            // A small uniform pop applied on top of the base scale during the reveal's
            // overshoot. Driven explicitly (not through the circle→label lerp) because the
            // clamped circle and the label can share a dimension, which would let
            // `min(widthRatio, heightRatio)` cancel a lerp-based overshoot.
            var popScale: CGFloat = 1
            if reveal <= 0 {
                let c = collapse.clamped(to: 0...1)
                rect = lerpRect(labelRect, circleRect, 1 - c)
                opacity = Double(((c - 0.15) / 0.85).clamped(to: 0...1))
                blur = (1 - c).clamped(to: 0...1) * DropdownCustomMenuSpec.lensBlur
            } else {
                let r = reveal.clamped(to: 0...1)
                rect = lerpRect(circleRect, labelRect, r)
                // The spring overshoots reveal past 1; turn that into a hair of pop on the
                // settled label so it lands organically instead of a hard-clipped stop.
                popScale = 1 + (reveal - 1).clamped(to: 0...(DropdownCustomMenuSpec.revealOvershoot - 1))
                // Resolve the label early in the (now short) reveal so it snaps back
                // crisply rather than fading in only at the very end.
                opacity = Double(((r - 0.3) / 0.7).clamped(to: 0...1))
                blur = (1 - r).clamped(to: 0...1) * DropdownCustomMenuSpec.lensBlur
            }
            // Shrink uniformly so the (fixedSize) label keeps its intrinsic layout — no
            // reflow or truncation — and stays inside the circle. `popScale` adds the
            // reveal overshoot on top (1 everywhere except the brief pop).
            let scale = min(rect.width / max(labelRect.width, 1), rect.height / max(labelRect.height, 1))
            return content
                .fixedSize()
                .scaleEffect(scale * popScale)
                .frame(width: rect.width, height: rect.height)
                .blur(radius: blur)
                .opacity(opacity)
                .padding(.leading, max(0, rect.minX))
                .padding(.top, max(0, rect.minY))
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
        let alignment: DropdownCustomMenuAlignment
        /// Nudge applied to the final placement (positive = right / down).
        let placementOffset: CGSize
        let spaceBelow: CGFloat
        let spaceAbove: CGFloat

        var maxHeight: CGFloat { max(spaceBelow, spaceAbove) }
        var maxWidth: CGFloat { available.width }

        init(geo: GeometryProxy, anchor: CGRect, overlapsAnchor: Bool,
             alignment: DropdownCustomMenuAlignment, placementOffset: CGSize) {
            let safe = geo.safeAreaInsets
            let margin = DropdownCustomMenuSpec.screenMargin
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
            self.placementOffset = placementOffset
            if overlapsAnchor {
                spaceBelow = available.maxY - anchor.minY
                spaceAbove = anchor.maxY - available.minY
            } else {
                spaceBelow = available.maxY - (anchor.maxY + DropdownCustomMenuSpec.anchorGap)
                spaceAbove = (anchor.minY - DropdownCustomMenuSpec.anchorGap) - available.minY
            }
        }

        /// Below the label when it fits, else above, else whichever side is
        /// larger. iOS 26: top (or bottom) edge flush with the label's; classic:
        /// 6pt gap. Both edge-align horizontally to the label (left edge for a
        /// leading label, right edge for a trailing one). The unit anchor is the
        /// point on the menu nearest the label (legacy scale transform origin).
        func placement(for size: CGSize) -> (origin: CGPoint, anchor: UnitPoint) {
            let below: Bool
            if size.height <= spaceBelow {
                below = true
            } else if size.height <= spaceAbove {
                below = false
            } else {
                below = spaceBelow >= spaceAbove
            }

            var y: CGFloat
            if overlapsAnchor {
                y = below ? anchor.minY : anchor.maxY - size.height
            } else {
                y = below ? anchor.maxY + DropdownCustomMenuSpec.anchorGap
                          : anchor.minY - DropdownCustomMenuSpec.anchorGap - size.height
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
