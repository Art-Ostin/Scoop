//AI Code Beware!
//  DropdownCustomMenu.swift
//  Scoop
//
//  NOTE: The OPEN is the pre-2026-06-24 `TypeCustomMenu` behaviour, lifted into its
//  own type (all symbols renamed `TypeCustomMenu*` → `DropdownCustomMenu*`): the label
//  stays visible underneath while the menu opens (it is never hidden/captured then),
//  and the platter blooms straight out of the button's frame.
//  The DISMISS is NO LONGER a simple reverse. It plays a circle→label reveal borrowed
//  from TimeCustomMenu as ONE OVERLAPPED flow: the platter and a hidden copy of the
//  label pinch toward ONE centred glass circle while the reveal spring launches under
//  the still-landing collapse (`revealLaunchDelay`), so the shape bottoms out just
//  short of the circle — never parking on it — and flows straight back out to reveal
//  the label. See the "iOS 26 dismiss" block in `DropdownCustomMenuSpec` and
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
//  the platter and a hidden copy of the label both pinch toward one centred glass
//  circle while the reveal launches underneath the still-landing collapse, expanding
//  back out to reveal the label (the TimeCustomMenu reveal). Two OVERLAPPED phases
//  driven by `morphProgress` (1→0) and `revealProgress` (0→1), blended additively in
//  the morph modifiers so the pair reads as one continuous flow through the pinch.
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
                .foregroundStyle(Color.successGreen)
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
                    ForEach([Color.successGreen, .accent, .warningYellow,
                             .border, .textTertiary, .appCanvas, .dangerRed], id: \.self) { color in
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
    static let platterCornerRadius = CornerRadius.customMenu
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
    /// Also drives the `.retract` dismiss — the no-change close is literally the open
    /// played backwards.
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
    /// Platter shadow at full bloom, measured from the native platter — a system
    /// stand-in kept outside the Elevation ramp (it scales radius/offset with the
    /// bloom progress, which `.shadow(_:strength:)` deliberately doesn't do).
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
    /// Phase 1 curve (platter → circle, label → circle — both pinch toward the same centred
    /// circle). EASE-OUT (`.smooth`) — a deliberate reversal of the earlier deliberately-
    /// LINEAR choice. That linearity existed to hide a stall the SEQUENTIAL handoff had at
    /// the apex (ease-out arrived at the circle at ~zero velocity, then phase 2 sprang out
    /// of a dead stop). The phases now OVERLAP instead (`revealLaunchDelay`): the reveal is
    /// already accelerating underneath while this curve decelerates into the pinch, and the
    /// additive blend in `PlatterDismissMorph` / `LabelCollapseMorph` sums the two into ONE
    /// smooth size-over-time valley — the shape bottoms out just short of the circle, still
    /// moving, where the old back-to-back phases always met in a V-cusp (however well their
    /// velocities were matched) and read as shrink-then-snap-open. Deceleration into the
    /// turn is exactly what makes it read liquid; the ~2× longer clock spends its extra
    /// time under the overlap, so the wall-clock total still matches the old dismiss
    /// (~launch delay + reveal settle).
    static let collapseToCircle = Animation.smooth(duration: 0.26)
    /// How long after the collapse starts the reveal launches — THE liquidity knob. The
    /// collapse still has about half its clock to run past this point; everything after is
    /// overlap. Larger delays deepen the pinch toward a full circle-stop (past the
    /// collapse's ~0.3s settle it degenerates to the old sequential two-stage handoff);
    /// smaller ones make it shallower and blobbier — but keep it ≥ ~0.05s: the old label
    /// needs the collapse to reach c ≈ 0.35 (~0.09s in) to fully fade before the new one
    /// can start appearing (r ≥ 0.3, ~0.045s after launch), or both ghost in one frame.
    /// At 0.13 the two fade windows sit ~80ms apart, so the turn-around is always label-free.
    static let revealLaunchDelay: TimeInterval = 0.13
    /// Phase 2 — the shape expands back into the label's rectangle and the label is
    /// revealed. Still an interpolating spring, but the launch velocity drops from the old
    /// 20 to a nudge: continuity through the pinch now comes from the OVERLAP (this spring
    /// is already mid-flight when the collapse lands), not from punching out of a dead stop
    /// — at 20 the reveal would cover most of its distance in its first ~100ms and flatten
    /// the pinch to nothing under the overlap. In `initialVelocity` units (1 = the full
    /// circle→label distance per second). `dampingRatio` drops 0.78 → 0.70 to keep the
    /// ~5–6% landing pop the old launch velocity used to contribute (a 0.78 spring from
    /// near-rest overshoots only ~2%); it still sits under the `revealOvershoot` cap, so
    /// the landing reads as the same organic settle as before.
    static let circleRevealLaunchVelocity: Double = 4
    static let circleReveal = Animation.interpolatingSpring(
        Spring(response: 0.37, dampingRatio: 0.70),
        initialVelocity: circleRevealLaunchVelocity
    )
    /// Upper bound the reveal geometry may extrapolate the label past its resting size, so
    /// the spring's overshoot reads as a real pop without ever running away.
    static let revealOvershoot: CGFloat = 1.08
    /// Safety net: if the completion-chained morph ever fails to fire, tear the window down
    /// after this long so it can't leak. The normal path tears down ~0.7s via completions.
    static let dismissSafetyTimeout: TimeInterval = 1.2
    /// On the reveal, the glass is fully present at the circle and melts to nothing over
    /// the final relax onto the label (mirrors TimeCustomMenu's `closeGlassFadeProgress`),
    /// so the label alone lands and there's no glass left to pop.
    static let revealGlassFadeProgress: CGFloat = 0.35

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
    /// Gap between the main platter and the detached footer accessory.
    static let footerGap: CGFloat = 6
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
    static let highlightCornerRadius = CornerRadius.customMenuRowHighlight
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
    /// Explicit (global) rect the glass lens blooms from / collapses into, overriding the
    /// label's own measured frame. Use when the label is larger than what should visually
    /// morph — e.g. a pager whose scroll view carries vertical padding the bloom must not
    /// include (the zoom point would otherwise read far taller than the visible text).
    /// Placement still uses the full label frame; only the morph geometry uses this.
    /// Mirrors `TimeCustomMenu.morphAnchor`.
    var morphAnchor: CGRect?
    /// When `true`, a no-change dismiss retracts the platter back into the label (the
    /// reverse of the open bloom) instead of running the circle morph: re-selecting the
    /// already-selected row uses `dismiss(.retract)`, and a tap-away (which is always
    /// no-change) retracts too. `false` (default) keeps every dismiss on the morph.
    var retractOnEmptyDismiss: Bool
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
    /// Intercepts a completed tap on the label, just before the menu would open. Return `true`
    /// to claim the tap so the menu stays CLOSED and the call site handles it instead (e.g. the
    /// type pager routes a tap on its message page to the message editor); `false`/`nil` opens
    /// the menu as usual. Only the open tap is gated — re-tapping an open menu to close it is
    /// unaffected (that path lives in the overlay window).
    var onLabelTap: (() -> Bool)?
    /// A one-shot programmatic open, for a control that sits OUTSIDE the label (the invite
    /// rows' "What" caption). Set it `true` and the menu opens exactly as a completed label
    /// tap would — `onLabelTap` gate included, blooming from the label's own frame — then the
    /// menu clears it so the same binding can fire again. It is not a presentation state:
    /// read `onOpen`/`onClose` for that.
    var openRequest: Binding<Bool>?

    @State private var controller = DropdownCustomMenuController()
    @State private var labelFrame: CGRect = .zero
    //Touch-down press state, driven by `pressGesture` (a simultaneous gesture so it fires on
    //touch-down over the pager instead of waiting for the scroll to fail at release). `pressStart`
    //holds the shrink briefly on a fast tap, like PressEffectModifier.
    @State private var pressed = false
    @State private var pressStart: Date?

    init(cornerRadius: CGFloat? = nil,
         cornerRadii: RectangleCornerRadii? = nil,
         footerCornerRadii: RectangleCornerRadii? = nil,
         labelCornerRadius: CGFloat? = nil,
         alignment: DropdownCustomMenuAlignment = .automatic,
         morphsFromTrailingPoint: Bool = false,
         morphAnchor: CGRect? = nil,
         retractOnEmptyDismiss: Bool = false,
         placementOffsetX: CGFloat = DropdownCustomMenuSpec.placementOffsetX,
         placementOffsetY: CGFloat = DropdownCustomMenuSpec.placementOffsetY,
         onOpen: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil,
         onLabelTap: (() -> Bool)? = nil,
         openRequest: Binding<Bool>? = nil,
         footer: (() -> AnyView)? = nil,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder label: @escaping () -> Label) {
        self.cornerRadius = cornerRadius
        self.cornerRadii = cornerRadii
        self.footerCornerRadii = footerCornerRadii
        self.labelCornerRadius = labelCornerRadius
        self.alignment = alignment
        self.morphsFromTrailingPoint = morphsFromTrailingPoint
        self.morphAnchor = morphAnchor
        self.retractOnEmptyDismiss = retractOnEmptyDismiss
        self.placementOffset = CGSize(width: placementOffsetX, height: placementOffsetY)
        self.onOpen = onOpen
        self.onClose = onClose
        self.onLabelTap = onLabelTap
        self.openRequest = openRequest
        self.footer = footer
        self.content = content
        self.label = label
    }

    var body: some View {
        // The label stays in place while the menu is open: the glass platter blooms
        // out of a small circle at the label's trailing edge, so the real label is
        // always visible underneath (never swallowed/hidden). It reflows naturally
        // on selection, so the close morph collapses onto its current value.
        let _ = syncPresentedLabel()
        // Keep the morph collapse/bloom target current too (the pager's active page can
        // reflow), so the lens lands on the tight content rather than the padded label.
        let _ = syncMorphAnchor()
        // Press feedback is driven by a `.simultaneousGesture` (NOT `.gesture`, NOT a Button). A
        // plain `.gesture`/Button DEFERS to the inner pager ScrollView and only resolves the press
        // on release — that's why every prior attempt shrank late. A SIMULTANEOUS min-0 drag
        // recognises alongside the scroll, so `onChanged` fires on touch-DOWN (translation .zero)
        // and the shrink lands immediately, while a real drag still scrolls/pages the row.
        // `labelPressed` is the open-menu re-tap, reported by the overlay (the label sits under it
        // then, so the gesture below can't see that press).
        let shrunk = pressed || controller.labelPressed
        return label()
            .contentShape(Rectangle())
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                labelFrame = frame
                // Keep the close target on the label's current frame (it reflows when a
                // selection changes its text) so the morph lands cleanly.
                controller.updateCollapseAnchor(frame)
            }
            // Press shrink applied AFTER the geometry read so the transform never feeds back into
            // the anchor frame used to place/collapse the menu.
            .scaleEffect(shrunk ? PressEffect.shrink.scale : 1)
            .opacity(controller.hidesLabel ? 0 : (shrunk ? PressEffect.shrink.opacity : 1))
            .animation(shrunk ? .snappy(duration: PressEffect.shrink.pressDuration)
                              : .spring(response: PressEffect.shrink.release.response,
                                        dampingFraction: PressEffect.shrink.release.damping),
                       value: shrunk)
            .simultaneousGesture(pressGesture)
            //Programmatic open from outside the label; cleared immediately so it can fire again.
            .onChange(of: openRequest?.wrappedValue ?? false) { _, wants in
                guard wants else { return }
                openRequest?.wrappedValue = false
                openMenu()
            }
            .onDisappear { controller.dismiss(style: .instant) }
    }

    /// Drives the touch-DOWN shrink and the tap-to-open. A `.simultaneousGesture` so it recognises
    /// alongside the pager's scroll instead of waiting for it to fail (which only happens at
    /// release). `onChanged` with translation ~0 = touch-down → shrink; a drag past `tapSlop` is a
    /// scroll/page → release the shrink and don't open; a release under `tapSlop` is a tap → open.
    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !controller.isPresented else { return }
                let moved = max(abs(value.translation.width), abs(value.translation.height))
                if moved < DropdownCustomMenuSpec.tapSlop {
                    if !pressed { pressed = true; pressStart = .now }
                } else if pressed {
                    pressed = false   // turned into a scroll/page — let the shrink go
                }
            }
            .onEnded { value in
                guard !controller.isPresented else { pressed = false; return }
                // Hold the shrink briefly so a fast tap still reads, then release (PressEffect's hold).
                let elapsed = pressStart.map { Date.now.timeIntervalSince($0) } ?? 0.12
                DispatchQueue.main.asyncAfter(deadline: .now() + max(0, 0.12 - elapsed)) { pressed = false }
                let moved = max(abs(value.translation.width), abs(value.translation.height))
                guard moved < DropdownCustomMenuSpec.tapSlop else { return }  // a scroll, not a tap
                openMenu()
            }
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

    /// Pushes the freshest morph anchor into the controller while presented, so the
    /// close morph collapses onto the active page's current (tight) bounds. Deferred one
    /// runloop turn like the label sync. No-op while closed or when no override is set.
    private func syncMorphAnchor() {
        guard controller.isPresented, let morphAnchor else { return }
        DispatchQueue.main.async {
            controller.updateMorphAnchor(morphAnchor)
        }
    }

    /// A completed tap on the label opens the menu — fired by `pressGesture` on a release that
    /// barely moved (a drag that pages the scroller doesn't qualify). The call site can claim the
    /// tap first via `onLabelTap` (e.g. the type pager routing to the message editor), in which
    /// case the menu stays closed. No-op while already presented.
    private func openMenu() {
        guard !controller.isPresented else { return }
        if onLabelTap?() == true { return }
        onOpen?()
        // Seed the morph collapse/bloom target before the overlay renders, so the
        // open bloom starts from the tight content (not the padded label frame).
        controller.updateMorphAnchor(morphAnchor)
        controller.present(
            anchor: labelFrame,
            cornerRadius: cornerRadius,
            cornerRadii: cornerRadii,
            footerCornerRadii: footerCornerRadii,
            labelCornerRadius: labelCornerRadius,
            alignment: alignment,
            morphsFromTrailingPoint: morphsFromTrailingPoint,
            retractOnEmptyDismiss: retractOnEmptyDismiss,
            placementOffset: placementOffset,
            onClose: onClose,
            footer: footer,
            label: { AnyView(label()) },
            content: { AnyView(content()) }
        )
    }
}

// MARK: - Dismiss action environment

/// How the menu leaves the screen.
/// - `morph`: the default glass bloom-close (the platter shrinks back into the label,
///   carrying the label copy through the circle-collapse → reveal so a just-selected
///   value swaps at the apex).
/// - `morphPlatterOnly`: the platter alone shrinks into the circle and melts — the label
///   copy is NOT carried and the real label is NEVER hidden. For call sites whose visible
///   label isn't what the menu would morph (e.g. the type pager parked on its MESSAGE page,
///   where the menu's label copy is the type icon but the message is what's on screen):
///   the full `morph` would flash the type over the message and yank the pager back, so we
///   only zoom the platter into the chevron and let the row update its own label.
/// - `pop`: removes the platter + footer with the `.scoopPop` transition (blur + scale).
/// - `retract`: the no-change close — the exact reverse of the open bloom. The platter
///   shrinks back into the label's frame on `bloomClose` (footer sliding back underneath,
///   glass melting over the final stretch) while the real label — never hidden, never
///   pulsed — just finishes its own settle. Open and close read symmetric, which is
///   exactly what "nothing changed" should look like.
/// - `instant`: tears the window down immediately, no animation.
enum DropdownCustomMenuDismissStyle { case morph, morphPlatterOnly, pop, retract, instant }

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
        let shape = UnevenRoundedRectangle(cornerRadii: corners)
        if #available(iOS 26.0, *) {
            // No shadow compensation: the footer sits ABOVE the platter, so the
            // platter's drop shadow lands under it rather than darkening its face.
            content
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background(shape.fill(.regularMaterial))
                .clipShape(shape)
                .shadow(.floating)
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
                        RoundedRectangle(cornerRadius: DropdownCustomMenuSpec.highlightCornerRadius)
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
    /// Caller's explicit morph collapse/bloom target (global), preferred over `collapseAnchor`
    /// when set, so the lens morphs around the tight content instead of the padded label
    /// frame. See `DropdownCustomMenu.morphAnchor`.
    private(set) var morphAnchor: CGRect?
    /// The morph anchor as it stood the instant dismissal began — i.e. where the label
    /// VISUALLY is at that moment. The live anchors are model-space reads, so any open-state
    /// displacement the row animates away on close (the invite row's −20/−4 lift) vanishes
    /// from them on the very first dismiss frame; the frozen OLD copy and the pinch circle
    /// ride this snapshot instead, so the collapse starts exactly on the on-screen label.
    /// The reveal side keeps tracking the live anchor and lands on the label's RESTING
    /// place — the lifted→resting travel rides inside the reveal flow rather than snapping.
    private(set) var dismissAnchor: CGRect?
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
    /// Caller opt-in: a tap-away (dismiss with no selection) uses `.retract` instead of
    /// `.morph`, so backing out of the menu shrinks the platter back into the label rather
    /// than running the circle morph.
    private(set) var retractOnEmptyDismiss = false
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
                 retractOnEmptyDismiss: Bool = false,
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
        self.retractOnEmptyDismiss = retractOnEmptyDismiss
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

    /// Sets/clears the caller's explicit morph collapse/bloom target. Seeded just before
    /// `present` (and kept fresh while shown) so the lens morphs around the tight content
    /// rather than the padded label frame.
    func updateMorphAnchor(_ rect: CGRect?) {
        morphAnchor = rect
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
        // Snapshot where the label visually sits BEFORE the model-space anchor updates from
        // onClose's state resets can land (layout + the anchor syncs are deferred, so the
        // pre-close open lift is still in the last-synced rect here).
        dismissAnchor = morphAnchor ?? (collapseAnchor == .zero ? anchor : collapseAnchor)
        dismissStyle = style
        phase = .dismissing
        let gen = generation
        if style == .pop {
            // Melts the platter + footer with the `.scoopPop` transition (driven by the
            // overlay off `phase`). Tear the window down once that spring has settled.
            Task {
                try? await Task.sleep(for: .seconds(DropdownCustomMenuSpec.popCloseDuration))
                if generation == gen { tearDown() }
            }
            return
        }
        if #available(iOS 26.0, *) {
            // Overlapped dismiss choreography (see DropdownCustomMenuSpec dismiss block):
            //   Collapse — the platter and the label copy pinch toward a centred glass
            //              circle, while `revealLaunchDelay` in the reveal spring launches
            //              UNDERNEATH the still-landing collapse.
            //   Reveal   — the pair, blended additively in the morph modifiers, bottoms
            //              out just short of the circle and expands back onto the label,
            //              revealing the new value — one continuous flow, no parked apex.
            //   Tail     — restore the real label under the copy → melt the halo → teardown.
            // The overlay (DropdownCustomMenuOverlayRoot.runMorphDismiss) drives all three;
            // the tail chains off the reveal animation's *completion* rather than a
            // wall-clock timer, so teardown can't desync from the animation under load.
            // The hand-offs call back into `restoreLabel` / `finishMorphDismiss` below.
            // `.morphPlatterOnly` keeps the real label on screen the whole time (the platter
            // just shrinks into the chevron and melts), so it neither freezes a copy nor hides
            // the label. The full `.morph` does both so the label can ride the circle morph.
            if style == .morph {
                // Freeze the label for non-selection dismisses (tap-away / programmatic);
                // a selection already froze the OLD value before mutating state. No-op if
                // already frozen, so the selection's freeze is never overwritten.
                freezeLabel()
                // Hide the real label only if we have a copy to morph in its place; without
                // one we'd leave a gap, so fall back to leaving it visible.
                if labelView != nil { hidesLabel = true }
            }
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

    // MARK: iOS 26 morph dismiss hand-offs (called by the overlay on the reveal's completion)

    /// Reveal done: restore the real (now-current) label under the copy, just before the
    /// overlay melts the leftover halo. Guarded so a stale completion can't act after teardown.
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
        morphAnchor = nil
        dismissAnchor = nil
        items = [:]
        highlightedItemID = nil
        menuFrame = .zero
        hidesLabel = false
        retractOnEmptyDismiss = false
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
    @State private var contentIdealHeight: CGFloat = 0
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
            // Place against the tight morph anchor (the visible label) when supplied, else the
            // full label frame. A padded label (e.g. the type pager's 30pt scroll padding) has
            // a `minY` well above its visible text, so placing off it drops the menu on top of
            // the label instead of below it; the tight anchor lands it below, like the compact
            // label. Only placement uses this — the press hit-test below keeps the full frame.
            let placementAnchor = controller.morphAnchor ?? controller.anchor
            let metrics = Metrics(geo: geo, anchor: placementAnchor, overlapsAnchor: overlapsAnchor,
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
                                // Tap-away is always a no-change dismiss: retract the platter
                                // back into the label instead of the circle morph when the
                                // caller opted in.
                                controller.dismiss(style: controller.retractOnEmptyDismiss ? .retract : .morph)
                            }
                    )

                // Detached accessory, placed once sized: it tracks the platter's bottom
                // edge through the bloom, so it still reads as emerging from the menu.
                // It sits ABOVE the platter (zIndex below) — a footer with a saturated
                // fill would otherwise land inside the platter's Liquid Glass backdrop
                // sample (~0.35 × its width, so ~105pt for a 300pt platter, far past the
                // 6pt gap) and smear its colour across the whole platter face.
                // On a `.pop` dismiss it's removed with the platter via `.scoopPop`.
                // Anchor the footer to the platter's LIVE placement — the same `metrics` + size
                // the platter derives from below — not the cached `controller.menuFrame`, which
                // only refreshes on a size change. When the morph anchor shifts the placement
                // without resizing (the type pager pushes a fresh anchor while open), the platter
                // moves but a stale menuFrame would leave the footer detached. One shared source
                // keeps them locked together.
                if let footer = controller.footer, let size = menuSize, !popExit {
                    let platterRect = CGRect(origin: metrics.placement(for: size).origin, size: size)
                    footerCard(footer(), platterRect: platterRect)
                        .transition(.blurReplace.combined(with: .scale(0.8, anchor: .top)))
                        .zIndex(1)
                }

                // `.pop` dismiss removes this with the `.scoopPop` transition; the morph
                // close instead keeps it mounted and animates `morphProgress` to 0.
                if let content = controller.content, !popExit {
                    if #available(iOS 26.0, *) {
                        glassPresentation(content: content(), metrics: metrics)
                            .transition(.blurReplace.combined(with: .scale(0.8, anchor: .top)))
                    } else {
                        legacyPresentation(content: content(), metrics: metrics)
                            .transition(.blurReplace.combined(with: .scale(0.8, anchor: .top)))
                    }
                }
            }
            .onChange(of: geo.size) { _, _ in
                controller.dismiss(style: .instant)
            }
            .onChange(of: controller.phase) { _, newPhase in
                guard newPhase == .dismissing else { return }
                if controller.dismissStyle == .pop {
                    // Remove the platter + footer with the scoopPop transition.
                    withAnimation(.dismiss) { popExit = true }
                } else if #available(iOS 26.0, *) {
                    runMorphDismiss()
                }
            }
        }
        .ignoresSafeArea()
    }

    /// Drives the iOS 26 morph dismiss as one OVERLAPPED flow: the collapse starts, and the
    /// reveal spring launches `revealLaunchDelay` later — while the collapse is still
    /// landing — so both progresses are mid-flight together and the additive blend in the
    /// morph modifiers rounds the pinch into a single continuous curve (no dead stop, no
    /// cusp at the apex). The tail (restore label → melt halo → teardown) still chains off
    /// the reveal animation's *completion*, never a wall-clock timer, so teardown can't
    /// desync from the animation under load.
    @available(iOS 26.0, *)
    private func runMorphDismiss() {
        // `.morphPlatterOnly`: no label copy and the real label was never hidden, so there's
        // nothing to reveal. Just shrink the platter into the chevron circle and melt the
        // glass — the row's own label handles the value change underneath.
        if controller.dismissStyle == .morphPlatterOnly {
            withAnimation(DropdownCustomMenuSpec.collapseToCircle, completionCriteria: .logicallyComplete) {
                morphProgress = 0
            } completion: {
                withAnimation(DropdownCustomMenuSpec.lensFadeOut) {
                    lensOpacity = 0
                } completion: {
                    controller.finishMorphDismiss()
                }
            }
            return
        }
        // `.retract`: the no-change close — the open bloom played backwards. The platter is
        // still on the MenuLensMorph branch (`isMorphDismiss` excludes `.retract`), so
        // animating the bloom progress home shrinks it back into the label's frame, glass
        // melting over the final stretch (`closeGlassFadeProgress`) and the footer sliding
        // back underneath on the same progress. The real label was never hidden or pulsed —
        // it just finishes its own settle as the glass lands on it.
        if controller.dismissStyle == .retract {
            withAnimation(DropdownCustomMenuSpec.bloomClose, completionCriteria: .logicallyComplete) {
                morphProgress = 0
            } completion: {
                withAnimation(DropdownCustomMenuSpec.lensFadeOut) {
                    lensOpacity = 0
                } completion: {
                    controller.finishMorphDismiss()
                }
            }
            return
        }
        // Collapse and reveal, overlapped. The reveal's launch offset rides the animation
        // clock (`.delay`), and its state write escapes the collapse's update turn (the
        // async hop) so each progress gets its own animation record on the shared
        // animatable pair — they compose additively instead of one transaction retargeting
        // the other's component. The old/new label swap needs no timed flip at all: both
        // label layers are mounted throughout, each fading on its own progress window (see
        // dismissPresentation), so nothing here can desync under load.
        withAnimation(DropdownCustomMenuSpec.collapseToCircle) {
            morphProgress = 0
        }
        DispatchQueue.main.async {
            withAnimation(DropdownCustomMenuSpec.circleReveal.delay(DropdownCustomMenuSpec.revealLaunchDelay),
                          completionCriteria: .removed) {
                revealProgress = 1
            } completion: {
                // Tail — the live copy has settled on the label, so restore the real
                // (now-current) label under it, melt the leftover halo, then tear down.
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
    private func footerCard(_ footer: AnyView, platterRect frame: CGRect) -> some View {
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
                .animation(.transition, value: visible)
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
            // Collapse onto the caller's explicit morph anchor (the tight content) when set,
            // else the label's live frame, falling back to the open-time anchor before the
            // first geometry update lands. The morph grows from / shrinks back into this.
            let collapsedRect = controller.morphAnchor
                ?? (controller.collapseAnchor == .zero ? controller.anchor : controller.collapseAnchor)
            // The `.morph` / `.morphPlatterOnly` dismisses hand off to the circle-collapse
            // choreography (dismissPresentation); the open bloom (and the brief pre-removal
            // frame of a `.pop` dismiss) stay on MenuLensMorph. `.retract` stays here ON
            // PURPOSE — its close IS this morph run in reverse (see runMorphDismiss).
            let isMorphDismiss = controller.phase == .dismissing
                && (controller.dismissStyle == .morph || controller.dismissStyle == .morphPlatterOnly)
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

    /// The dismiss: stacked layers driven by `morphProgress` (collapse, 1 → 0) and
    /// `revealProgress` (reveal, 0 → 1) — OVERLAPPED in time and blended ADDITIVELY inside
    /// the modifiers, so the motion flows through the pinch as one continuous curve.
    ///   • The PLATTER (`PlatterDismissMorph`) pinches from the menu rect toward the centred
    ///     circle, then relaxes back onto the label as its glass melts off — exactly the
    ///     TimeCustomMenu close ending.
    ///   • TWO LABEL COPIES (`LabelCollapseMorph`) ride the same pinch, both mounted for the
    ///     whole dismiss: the frozen OLD value fades out with the collapse, the live NEW
    ///     value fades in over the reveal and is what finally lands on the label (the real
    ///     label is hidden meanwhile and restored under it just before teardown).
    @available(iOS 26.0, *)
    @ViewBuilder
    private func dismissPresentation(content: AnyView, metrics: Metrics,
                                     menuRect: CGRect, labelRect: CGRect) -> some View {
        // Two label rects drive the dismiss:
        //   • `collapseSource` — the dismissAnchor snapshot: where the label VISUALLY sat
        //     when dismissal began (the invite row's open lift still applied). The frozen
        //     OLD copy and the pinch circle ride it, so the collapse starts exactly on the
        //     on-screen label instead of jumping to the already-reset model rect.
        //   • `labelRect` (live) — where the label will REST. The platter's landing and the
        //     NEW copy ride it, so the lifted→resting travel glides inside the reveal flow
        //     and the hand-off to the restored real label is seamless. It may update
        //     mid-dismiss (lift release, new text width), but only while the reveal side is
        //     weightless (r ≈ 0) and invisible, so the retarget is never seen.
        let collapseSource = controller.dismissAnchor ?? labelRect
        // The circle both layers collapse toward. Sized off the SMALLER dimension of the
        // on-screen rect and clamped, so a tall multi-line label collapses to a tidy circle
        // (not a big blob) and a tiny label still gets a visible one. Always centred
        // vertically on the dismiss-start frame; placed at its TRAILING edge when the open
        // bloomed from there (`morphsFromTrailingPoint` — e.g. a wide pager label whose
        // content hugs the trailing edge), otherwise centred. This makes the close collapse
        // onto the same point the open grew from, instead of the empty middle of a wide
        // label (which read as "close in the centre, then snap right").
        let side = (min(collapseSource.width, collapseSource.height) * DropdownCustomMenuSpec.dismissCircleScale)
            .clamped(to: DropdownCustomMenuSpec.dismissCircleMinDiameter ... DropdownCustomMenuSpec.dismissCircleMaxDiameter)
        let circleX = controller.morphsFromTrailingPoint ? collapseSource.maxX - side : collapseSource.midX - side / 2
        let circleRect = CGRect(x: circleX, y: collapseSource.midY - side / 2,
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

            // Both label copies are mounted for the whole dismiss, so the old→new swap is
            // purely declarative: the OLD value (frozen bitmap, captured before any
            // selection mutated state) fades out with the collapse, the NEW value (the live
            // label) fades in over the reveal. The opacity windows never overlap, so the
            // change is never seen mid-air — and no timed flip exists to desync from the
            // overlapped animations. `.morphPlatterOnly` carries no label copy — the real
            // label stays on screen — so both layers are skipped and only the platter
            // collapses into the chevron.
            if controller.dismissStyle == .morph {
                let oldLabel: AnyView? = {
                    if let frozen = controller.frozenLabelImage { return AnyView(Image(uiImage: frozen)) }
                    return controller.labelView.map { AnyView($0()) } // no bitmap — fall back to live
                }()
                // Both copies are pure chrome: hit-testing off, because an `.opacity(0)`
                // view still hit-tests and the live copy could otherwise swallow a tap
                // meant for the screen behind the dismissing menu.
                if let oldLabel {
                    oldLabel
                        .modifier(LabelCollapseMorph(
                            collapse: morphProgress,
                            reveal: revealProgress,
                            labelRect: collapseSource, //collapses from where it visually sat
                            circleRect: circleRect,
                            isRevealLayer: false
                        ))
                        .opacity(lensOpacity)
                        .allowsHitTesting(false)
                }
                if let liveLabel = controller.labelView {
                    liveLabel()
                        .modifier(LabelCollapseMorph(
                            collapse: morphProgress,
                            reveal: revealProgress,
                            labelRect: labelRect,
                            circleRect: circleRect,
                            isRevealLayer: true
                        ))
                        .opacity(lensOpacity)
                        .allowsHitTesting(false)
                }
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
                ?? RectangleCornerRadii(uniform: controller.cornerRadius ?? DropdownCustomMenuSpec.platterCornerRadius)
        )

        chromeCore(content: content, metrics: metrics)
            .background {
                platterShape
                    .fill(.regularMaterial)
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
            .getHeight($contentIdealHeight)

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
                .glassEffect(.regular, in: UnevenRoundedRectangle(cornerRadii: lens.corners))
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

    /// The dismiss platter morph. The two progresses blend ADDITIVELY around the circle —
    /// `collapse` (1 → 0) contributes the platter's displacement from it, `reveal` (0 → 1)
    /// the label's — so run back-to-back they retrace the old two-branch GEOMETRY exactly, and
    /// run OVERLAPPED (the reveal launches while the collapse is still landing) they sum
    /// into one smooth valley: the glass bottoms out just short of the circle, still
    /// moving, then relaxes onto the label as it melts off, so the label copy (layered
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

        func body(content: Content) -> some View {
            let circleRadius = min(circleRect.width, circleRect.height) / 2
            // The label's resting radius, capped so a short label stays a clean capsule.
            // Only the reveal end lands on it; the collapse pulls toward the circle.
            let labelRadius = min(labelCornerRadius, min(labelRect.width, labelRect.height) / 2)

            let c = collapse.clamped(to: 0...1)
            let r = reveal.clamped(to: 0...1)

            // Additive blend around the circle: each progress contributes its own
            // displacement from it. (c 1→0 then r 0→1) run sequentially reproduces the old
            // two-branch path; overlapped, the two displacements sum into one smooth
            // size-over-time valley — the shape bottoms out just short of the circle, still
            // moving, instead of parking on it. This blend is what turns the old
            // shrink-stop-expand into a single liquid flow.
            let rect = CGRect(
                x: circleRect.minX + (expanded.minX - circleRect.minX) * c + (labelRect.minX - circleRect.minX) * r,
                y: circleRect.minY + (expanded.minY - circleRect.minY) * c + (labelRect.minY - circleRect.minY) * r,
                width: circleRect.width + (expanded.width - circleRect.width) * c + (labelRect.width - circleRect.width) * r,
                height: circleRect.height + (expanded.height - circleRect.height) * c + (labelRect.height - circleRect.height) * r
            )
            // Corners blend the same way (platter radii ↔ circle ↔ label capsule), each
            // capped at a half-side so the shape stays clean at every step.
            let cap = min(rect.width, rect.height) / 2
            func corner(_ platter: CGFloat) -> CGFloat {
                min(cap, circleRadius + (platter - circleRadius) * c + (labelRadius - circleRadius) * r)
            }
            let corners = RectangleCornerRadii(
                topLeading: corner(platterCorners.topLeading),
                bottomLeading: corner(platterCorners.bottomLeading),
                bottomTrailing: corner(platterCorners.bottomTrailing),
                topTrailing: corner(platterCorners.topTrailing)
            )

            // Opacities and shadow each ride ONE progress, so the overlap can't
            // double-drive them: menu rows fade out with the collapse, the glass melts over
            // the reveal's final relax onto the label, and the shadow shrinks away with the
            // platter. Blur alone blends both — it joins the old branches' (1-c) / zero
            // legs continuously, and only ever touches the already-faded content layer.
            let contentOpacity = Double(((c - 0.55) / 0.45).clamped(to: 0...1))
            let glassOpacity = Double(((1 - r) / DropdownCustomMenuSpec.revealGlassFadeProgress).clamped(to: 0...1))
            let blur = (1 - c) * (1 - r) * DropdownCustomMenuSpec.lensBlur * 0.5
            let shadowScale = c

            let w = rect.width
            let h = rect.height
            return content
                .frame(width: expanded.width, height: expanded.height, alignment: .topLeading)
                .scaleEffect(x: w / max(expanded.width, 1), y: h / max(expanded.height, 1), anchor: .topLeading)
                .blur(radius: blur)
                .opacity(contentOpacity)
                .frame(width: w, height: h, alignment: .topLeading)
                .glassEffect(.regular, in: UnevenRoundedRectangle(cornerRadii: corners))
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
    /// start apart — the menu is offset from the label — and meet only near the circle).
    /// TWO instances ride every `.morph` dismiss, both mounted throughout: the OLD-value
    /// layer (`isRevealLayer` false — the frozen bitmap) collapses labelRect → circle and
    /// fades out with the collapse; the NEW-value layer (`isRevealLayer` true — the live
    /// label) flows back out circle → labelRect, fading in over the reveal and popping
    /// slightly past resting size on the spring's overshoot. Both phases travel the same
    /// circle↔label axis, so the additive blend reduces to `c + r`: run sequentially it
    /// retraces the old two-branch geometry (the old value's fade completes earlier — by
    /// c ≈ 0.35 — the margin that keeps the turn-around label-free), overlapped it turns
    /// around just short of the circle without stopping. The opacity windows never overlap,
    /// so the old→new swap is never seen mid-air and needs no timed flip. Animatable on
    /// both progresses.
    @available(iOS 26.0, *)
    private struct LabelCollapseMorph: ViewModifier, Animatable {
        var collapse: CGFloat
        var reveal: CGFloat
        let labelRect: CGRect
        let circleRect: CGRect
        /// False = the old value collapsing in; true = the new value revealing out.
        let isRevealLayer: Bool

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
            let c = collapse.clamped(to: 0...1)
            let r = reveal.clamped(to: 0...1)
            // One blended parameter along the circle↔label axis: 1 = at rest on the label
            // (either end of the dismiss), 0 = at the circle.
            let t = (c + r).clamped(to: 0...1)
            let rect = lerpRect(circleRect, labelRect, t)
            // Refraction rises toward the pinch and melts back out — shared by both layers.
            let blur = (1 - t) * DropdownCustomMenuSpec.lensBlur

            let opacity: Double
            // A small uniform pop applied on top of the base scale during the reveal's
            // overshoot. Driven explicitly (not through the circle→label lerp) because the
            // clamped circle and the label can share a dimension, which would let
            // `min(widthRatio, heightRatio)` cancel a lerp-based overshoot.
            var popScale: CGFloat = 1
            if isRevealLayer {
                // Resolve the new label over the reveal's back stretch so it snaps in
                // crisply as the shape re-approaches the label.
                opacity = Double(((r - 0.3) / 0.7).clamped(to: 0...1))
                // The spring overshoots reveal past 1; turn that into a hair of pop on the
                // settled label so it lands organically instead of a hard-clipped stop.
                popScale = 1 + (reveal - 1).clamped(to: 0...(DropdownCustomMenuSpec.revealOvershoot - 1))
            } else {
                // Fully faded by c ≈ 0.35 — comfortably before the overlapped reveal starts
                // pulling this (now invisible) layer back out, so the old value never
                // ghosts back in at the turn-around.
                opacity = Double(((c - 0.35) / 0.65).clamped(to: 0...1))
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
