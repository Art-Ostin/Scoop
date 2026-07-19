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
//      TimeCustomMenu(labelCornerRadius: 25) { ... } label: { ... }
//
//  Inside the content closure:
//      .timeCustomMenuItem { ... }        — row participates in drag-to-select highlight,
//                                       runs its action and dismisses on selection.
//      @Environment(\.timeCustomMenuDismiss) — programmatic dismissal from content. A tap
//                                       on the menu's own content never auto-dismisses;
//                                       call this action (or use .timeCustomMenuItem) to
//                                       close it. Tapping outside still dismisses.
//
//  ── iOS 26 lens-morph mechanics (frame-matched against the native Menu in the
//     iOS 26.0 simulator, 60fps recordings, 2026-07-19) ──────────────────────
//  The native menu inflates a SINGLE rounded rect straight from the button's
//  rect to the platter's rect (top-leading edges flush with the button — no
//  droplet/circle phase in the simulator's rendering). While it grows, the
//  label blurs/fades out in place over the first ~quarter of the morph and the
//  menu content rides the platter scaled, materializing blur→sharp by ~70%.
//  Open is a spring (peak +~2.5% at ~270ms, settled ~370ms); close is a
//  ~220ms bounce-free reverse with the glass melting off late so the label
//  alone lands on the button. The trigger matches native too: a quick tap
//  opens on RELEASE; a still press opens at touch-down + holdOpenDelay while
//  the finger is down (drag-select continues); the pressed label dims only —
//  never shrinks (a scale would pop when the lens takes over). A tap during
//  the close morph reopens the menu from wherever the collapse is (native
//  interruptibility).
//  Implementation: ONE persistent glass view whose frame/radius/content are
//  interpolated by an Animatable modifier (MenuLensMorph) under withAnimation.
//  The real label hides while the lens covers it (it IS the menu, like native).
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
//   • Platter corner radius is a fixed 26pt stand-in for the system's
//     container-concentric radius (no container to be concentric with here).
//   • Platter content is not hard-clipped to the glass shape (.clipShape breaks
//     glass transitions); keep menu content padded inside the 26pt corners.
//   • The menu is presented in its own transparent UIWindow (level .alert + 1),
//     like UIKit does, so it can never be clipped by scroll views, the nav stack
//     or the tab bar. Anchor frames assume the app window fills the scene
//     (always true on iPhone; iPad floating windows may offset slightly).
//   • Opens like native: on the tap's release, or at touch-down + holdOpenDelay
//     for a still press (drag-select then continues on the same touch). Drags
//     that start on the label — pager swipes, the invite card's swipe-dismiss —
//     still never open the menu: movement past tapSlop cancels both paths,
//     which is also how native behaves under a scroll view's delayed touches.
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

    // ── iOS 26 Liquid Glass lens morph (fitted to sim recordings, 2026-07-19) ──
    /// Platter corner radius — fixed stand-in for the system's concentric radius.
    static let platterCornerRadius = CornerRadius.customMenu
    /// Peak refraction blur on the materializing/dissolving menu content.
    static let lensBlur: CGFloat = 9
    /// Open spring: native peaks +~3% at ~270ms and settles by ~370ms.
    static let bloomOpen = Animation.spring(response: 0.36, dampingFraction: 0.73)
    /// Close never bounces and is much quicker than the open (~220ms native).
    static let bloomClose = Animation.smooth(duration: 0.22)
    /// Label dissolve: gone by this progress on open (native shows the label
    /// refracting in the droplet for the first few frames before it clears);
    /// on close the label re-materializes over a longer window, like native.
    static let labelFadeProgress: CGFloat = 0.35
    static let labelFadeProgressClosing: CGFloat = 0.45
    /// Content materialize ramp: fades in over this progress window.
    static let contentFadeStart: CGFloat = 0.05
    static let contentFadeEnd: CGFloat = 0.55
    /// After the close morph lands on the button, the lens halo melts off the
    /// restored label rather than popping out in one frame.
    static let lensFadeOut = Animation.easeOut(duration: 0.12)
    /// Close morph length before the label is restored and the halo melts.
    static let closeMorphDuration: TimeInterval = 0.24
    static let lensFadeDuration: TimeInterval = 0.14
    /// A press held this long (within tapSlop) opens while the finger is still
    /// down, like native; a quicker tap opens on release.
    static let holdOpenDelay: TimeInterval = 0.25
    /// On close, the glass is fully present at this progress and melts linearly to
    /// nothing by progress 0 — i.e. it fades across the final expand (the circle
    /// relaxing back into the label), so the label alone lands and there's no
    /// glass left to pop. 0.35 lines the fade up with the start of the expand;
    /// smaller concentrates it later / quicker near the very end.
    static let closeGlassFadeProgress: CGFloat = 0.35

    static var platterShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: platterCornerRadius)
    }

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

    static let highlightFill = Color(.tertiarySystemFill)
    /// iOS 26 rows highlight with a rounded, inset shape rather than full-bleed.
    static let highlightCornerRadius = CornerRadius.customMenuRowHighlight
    /// Native pressed labels DIM only (reaching plateau in ~80-100ms) — never
    /// shrink. A scale would pop when the pixel-identical lens takes the label
    /// over. Values fitted to sim recordings of the native pressed state.
    static let pressedLabelOpacity: CGFloat = 0.65
    static let pressDim = Animation.easeOut(duration: 0.1)
    static let pressUndim = Animation.easeOut(duration: 0.2)
}

// MARK: - TimeCustomMenu

/// Which edge of the label the menu aligns its corresponding edge to.
/// `.automatic` picks the edge by whichever screen half the label's centre sits
/// in (the native default) — use `.leading` / `.trailing` when the label is wide
/// enough that its centre is ambiguous (e.g. a full-width row with a Spacer).
enum TimeCustomMenuAlignment {
    case leading, trailing, automatic
}

struct TimeCustomMenu<Content: View, Label: View>: View {

    @ViewBuilder var content: () -> Content
    @ViewBuilder var label: () -> Label
    /// Corner radius of the label's own shape so the closing lens lands on it
    /// exactly (defaults to a capsule). Mismatched corners read as a snap.
    var labelCornerRadius: CGFloat?
    /// Explicit (global) rect the morph lens collapses to / blooms from, overriding
    /// the label's own measured frame. Use when the label is larger than what should
    /// visually morph — e.g. a multi-item pager that should collapse onto just its
    /// first item, pinned to that item's bounds (no surrounding padding or chevron).
    /// Pair it with a label that renders only that item while in the morph overlay.
    var morphAnchor: CGRect?
    /// Rough platter size used to bloom on the very first tap, before any live
    /// measure exists (later opens reuse the cached measured size). Without it, the
    /// first-ever open falls back to blooming after the content has been measured.
    var estimatedContentSize: CGSize?
    /// Which label edge the menu aligns to (see `TimeCustomMenuAlignment`).
    var alignment: TimeCustomMenuAlignment
    /// Nudge applied to the final placement (positive = right / down). Defaults
    /// to the spec values; override per call site to fine-tune.
    var placementOffset: CGSize
    /// Fires the instant the menu is requested to open (on the opening tap's release,
    /// before the bloom animation) — not when the content view appears, so there's no
    /// morph lag. Use this instead of `.onAppear` on the content.
    var onOpen: (() -> Void)?
    /// Fires the instant dismissal is requested (any path: tap-away, drag-release,
    /// selection, programmatic) — not when the close morph + teardown finishes, so
    /// there's no ~0.58s lag. Use this instead of `.onDisappear` on the content.
    var onClose: (() -> Void)?

    @State private var controller = TimeCustomMenuController()
    @State private var labelFrame: CGRect = .zero
    //Touch-down press state, driven by `pressGesture` (simultaneous so it fires on touch-down over
    //the time pager instead of waiting for the scroll to fail at release). `pressStart` holds the
    //dim briefly on a fast tap. Separate from `pressAndDrag`, which owns open + drag-select.
    @State private var pressed = false
    @State private var pressStart: Date?
    //True while the touch that hold-opened the menu is still down, so its own release
    //isn't mistaken for a fresh tap (a fresh tap during the infant bloom cancels it,
    //like native; the opening touch's release must not).
    @State private var openingTouchActive = false

    init(labelCornerRadius: CGFloat? = nil,
         morphAnchor: CGRect? = nil,
         estimatedContentSize: CGSize? = nil,
         alignment: TimeCustomMenuAlignment = .automatic,
         placementOffsetX: CGFloat = TimeCustomMenuSpec.placementOffsetX,
         placementOffsetY: CGFloat = TimeCustomMenuSpec.placementOffsetY,
         onOpen: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder label: @escaping () -> Label) {
        self.labelCornerRadius = labelCornerRadius
        self.morphAnchor = morphAnchor
        self.estimatedContentSize = estimatedContentSize
        self.alignment = alignment
        self.placementOffset = CGSize(width: placementOffsetX, height: placementOffsetY)
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
        return label()
            .contentShape(Rectangle())
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                labelFrame = frame
                // Keep the close target on the label's current frame (it reflows
                // when a selection changes its text) so the lens lands cleanly.
                controller.updateCollapseAnchor(frame)
            }
            // Press DIM on touch-DOWN, driven by `pressGesture` (a simultaneous gesture so it
            // fires the instant the finger lands, even over the time pager's ScrollView).
            // Native menu labels dim only — no scale — so the lens (an unpressed copy) can
            // take over pixel-cleanly. iOS 26: `hidesLabel` swallows the real label while
            // the menu's lens is up (it is the menu now), like native.
            .opacity(controller.hidesLabel ? 0 : (pressed ? TimeCustomMenuSpec.pressedLabelOpacity : 1))
            .animation(pressed ? TimeCustomMenuSpec.pressDim : TimeCustomMenuSpec.pressUndim,
                       value: pressed)
            .gesture(pressAndDrag)
            .simultaneousGesture(pressGesture)
            .onDisappear { controller.dismiss(animated: false) }
    }

    /// Pushes the freshest label closure into the controller, deferred one runloop
    /// turn so it lands cleanly after the current view-update pass. No-op while the
    /// menu is closed — and while it is DISMISSING: the close morph shows the value
    /// captured at dismissal, and a deferred write landing mid-close can interrupt
    /// the in-flight glass transaction (seen as a frozen half-collapsed ghost).
    private func syncPresentedLabel() {
        guard controller.isPresented, controller.phase != .dismissing else { return }
        let makeLabel = label
        DispatchQueue.main.async {
            guard controller.phase != .dismissing else { return }
            controller.updateLabel { AnyView(makeLabel()) }
        }
    }

    /// Pushes the freshest morph anchor into the controller while presented, so the
    /// close morph collapses onto the first item's current bounds. Deferred one
    /// runloop turn like the label sync, with the same dismissing guard. No-op while
    /// closed or when no override set.
    private func syncMorphAnchor() {
        guard controller.isPresented, controller.phase != .dismissing, let morphAnchor else { return }
        DispatchQueue.main.async {
            guard controller.phase != .dismissing else { return }
            controller.updateMorphAnchor(morphAnchor)
        }
    }

    /// Native trigger semantics, frame-matched in the simulator: a still press opens at
    /// touch-down + `holdOpenDelay` while the finger is down (drag-select continues on the
    /// same touch); a quicker tap opens on RELEASE. A release past `tapSlop` is a
    /// scroll/page/card-drag, not a tap, so nothing opens: this keeps the invite card's
    /// swipe-dismiss from popping the menu when the drag starts on this label — matching
    /// native, whose scroll-delayed touches behave the same way. A tap landing during the
    /// close morph reopens the menu mid-collapse (native interruptibility).
    private var pressAndDrag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                guard controller.isPresented else { return }
                controller.dragMoved(to: value.location)
            }
            .onEnded { value in
                let distance = hypot(value.translation.width, value.translation.height)
                if controller.isPresented {
                    endTouchOnPresentedMenu(at: value.location, translation: value.translation,
                                            distance: distance)
                    return
                }
                guard distance < TimeCustomMenuSpec.tapSlop else { return } // a scroll/drag, not a tap
                openMenu()
            }
    }

    /// Routes a touch that ends while the menu is up. A FRESH tap landing in the
    /// brief window before the overlay is hit-testable (`.measuring` — right after
    /// a tap-open, before the first laid-out frame) cancels the infant bloom, the
    /// way a native menu's open aborts when tapped again immediately. The touch
    /// that hold-opened the menu is exempt — its release just ends drag-select.
    private func endTouchOnPresentedMenu(at location: CGPoint, translation: CGSize,
                                         distance: CGFloat) {
        if controller.phase == .dismissing {
            // The dissolve tail: the close has visually landed and the overlay is
            // interaction-disabled, so this tap reached the restored label — treat
            // it as a fresh open (present() drops the lingering halo). Setting the
            // flag stops the other gesture's onEnded for this same touch from
            // cancelling the fresh open via the .measuring branch below.
            if distance < TimeCustomMenuSpec.tapSlop, controller.lensDissolve {
                openingTouchActive = true
                openMenu()
            }
        } else if !openingTouchActive, distance < TimeCustomMenuSpec.tapSlop,
                  controller.phase == .measuring {
            controller.dismiss()
        } else {
            controller.dragEnded(at: location, translation: translation)
        }
        // Deferred so BOTH gestures' onEnded (same touch, same event cycle) see the
        // flag; a later fresh tap then correctly reads false.
        DispatchQueue.main.async { openingTouchActive = false }
    }

    /// The single open path (tap-release, hold-to-open, and reopen-mid-close all land here).
    private func openMenu() {
        onOpen?()
        // Seed the morph collapse target before the overlay renders, so
        // the open bloom starts from the first item (not the full label).
        controller.updateMorphAnchor(morphAnchor)
        controller.present(
            anchor: labelFrame,
            label: { AnyView(label()) },
            labelCornerRadius: labelCornerRadius,
            alignment: alignment,
            placementOffset: placementOffset,
            estimatedContentSize: estimatedContentSize,
            onOpen: onOpen,
            onClose: onClose,
            content: { AnyView(content()) }
        )
    }

    /// Opens the menu at touch-down + `holdOpenDelay` if the finger is still resting
    /// within `tapSlop` — the native long-press open. Cancelled by movement (a scroll)
    /// or release (which opens via the tap path instead).
    private func scheduleHoldOpen() {
        let start = pressStart
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeCustomMenuSpec.holdOpenDelay) {
            guard pressed, pressStart == start,
                  !controller.isPresented, controller.phase != .dismissing else { return }
            openingTouchActive = true // the finger is still down; see endTouchOnPresentedMenu
            openMenu()
        }
    }

    /// Drives the touch-DOWN press dim + the native hold-to-open, separate from `pressAndDrag`.
    /// A `.simultaneousGesture` so it fires on touch-down even over the time pager's ScrollView
    /// instead of waiting for the scroll to fail at release; a drag past `tapSlop` is a
    /// scroll/page, so the dim releases and the scheduled hold-open is cancelled. Once the menu
    /// opened under the held finger, this gesture also feeds drag-select — in the pager,
    /// `pressAndDrag` may never activate (the ScrollView owns plain gestures), so the
    /// simultaneous one carries the native press-drag-release selection there.
    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if controller.isPresented {
                    controller.dragMoved(to: value.location)
                }
                let moved = max(abs(value.translation.width), abs(value.translation.height))
                if moved < TimeCustomMenuSpec.tapSlop {
                    if !pressed {
                        pressed = true
                        pressStart = .now
                        scheduleHoldOpen()
                    }
                } else if pressed {
                    pressed = false   // turned into a scroll/page — let the dim go
                }
            }
            .onEnded { value in
                if controller.isPresented {
                    endTouchOnPresentedMenu(at: value.location, translation: value.translation,
                                            distance: hypot(value.translation.width,
                                                            value.translation.height))
                }
                // Hold the dim briefly so a fast tap still reads, then release.
                let elapsed = pressStart.map { Date.now.timeIntervalSince($0) } ?? 0.12
                DispatchQueue.main.asyncAfter(deadline: .now() + max(0, 0.12 - elapsed)) { pressed = false }
            }
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
    private(set) var labelCornerRadius: CGFloat?
    private(set) var alignment: TimeCustomMenuAlignment = .automatic
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
    /// Size measured on a previous open of this menu. Lets later opens bloom from
    /// the exact size with no measure wait; persists across teardown (the controller
    /// instance outlives each presentation).
    @ObservationIgnored private(set) var cachedMenuSize: CGSize?

    var isPresented: Bool { window != nil }

    @ObservationIgnored private var window: UIWindow?
    @ObservationIgnored private var items: [UUID: Item] = [:]
    /// Re-fired when a mid-close tap reopens the menu, so caller state stays in sync.
    @ObservationIgnored private var onOpen: (() -> Void)?
    /// Fired once at the top of `dismiss()` (any path), cleared on teardown.
    @ObservationIgnored private var onClose: (() -> Void)?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private let selectionHaptic = UISelectionFeedbackGenerator()
    /// Target for the overlay's UIKit-level early-tap recognizer (see `present`).
    @ObservationIgnored private lazy var earlyTapRelay = TapRelay { [weak self] location in
        self?.overlayTapped(at: location)
    }

    struct Item {
        var frame: CGRect
        var action: () -> Void
    }

    /// NSObject shim so a non-NSObject controller can target a UIGestureRecognizer.
    final class TapRelay: NSObject {
        private let action: (CGPoint) -> Void
        init(action: @escaping (CGPoint) -> Void) { self.action = action }
        @objc func fire(_ recognizer: UIGestureRecognizer) {
            action(recognizer.location(in: nil))
        }
    }

    // MARK: Presentation

    func present(anchor: CGRect,
                 label: @escaping () -> AnyView,
                 labelCornerRadius: CGFloat?,
                 alignment: TimeCustomMenuAlignment,
                 placementOffset: CGSize,
                 estimatedContentSize: CGSize? = nil,
                 onOpen: (() -> Void)? = nil,
                 onClose: (() -> Void)? = nil,
                 content: @escaping () -> AnyView) {
        // A re-tap during the dissolve tail reaches the restored label (the old
        // window is interaction-disabled by then); the lingering halo melt is
        // cosmetic — drop it and open fresh.
        if window != nil, phase == .dismissing, lensDissolve { tearDown() }
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive })
        else { return }

        self.anchor = anchor
        self.collapseAnchor = anchor
        self.labelView = label
        self.labelCornerRadius = labelCornerRadius
        self.alignment = alignment
        self.placementOffset = placementOffset
        self.estimatedContentSize = estimatedContentSize
        self.onOpen = onOpen
        self.onClose = onClose
        self.content = content
        phase = .measuring

        let host = UIHostingController(rootView: TimeCustomMenuOverlayRoot(controller: self))
        host.view.backgroundColor = .clear
        // A UIKit-level recognizer, live the instant the window exists: a tap in
        // the 1-2 frame gap before the SwiftUI overlay content commits (the 2nd
        // tap of a fast double-tap) would otherwise be swallowed and dropped.
        // Native cancels the infant open on such a tap — mirror that. Once the
        // overlay is laid out and `markShown` has run, SwiftUI owns tap routing.
        let earlyTap = UITapGestureRecognizer(target: earlyTapRelay,
                                              action: #selector(TapRelay.fire(_:)))
        earlyTap.cancelsTouchesInView = false
        host.view.addGestureRecognizer(earlyTap)
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

    /// Retargets a mid-close collapse back into a bloom — a tap on the collapsing
    /// button during dismissal reopens the menu from wherever the shrink is, like
    /// native. The overlay drives this (new touches land on its window, not the
    /// label's), and re-fires `onOpen` so caller state re-enters the open state.
    func reopen() {
        guard window != nil, phase == .dismissing else { return }
        generation += 1          // cancels the scheduled label-restore + teardown
        // Conditional writes: Observation fires on every set (no equality check),
        // and a spurious invalidation rebuilding the overlay mid-retarget can
        // stall the glass view's compositing.
        if !hidesLabel { hidesLabel = true }  // re-swallow (label may be mid-restore)
        if lensDissolve { lensDissolve = false }
        onOpen?()
        phase = .shown
    }

    /// One routing point for overlay taps — both the SwiftUI backdrop and the
    /// UIKit early-tap recognizer (which fires exactly when SwiftUI has not
    /// claimed the touch, e.g. the 2nd tap of a fast double-tap landing before
    /// the overlay content is hit-testable). Outside taps close, like native;
    /// while dismissing, only a tap on the collapsing button reopens.
    func overlayTapped(at location: CGPoint) {
        if phase == .dismissing {
            let target = morphAnchor ?? (collapseAnchor == .zero ? anchor : collapseAnchor)
            if target.insetBy(dx: -TimeCustomMenuSpec.tapSlop,
                              dy: -TimeCustomMenuSpec.tapSlop).contains(location) {
                reopen()
            }
        } else {
            dismiss()
        }
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
                // The morph has landed; only the cosmetic halo melt remains. Let
                // touches through to the restored label so a rapid re-tap opens a
                // fresh menu instead of dying against an invisible window.
                window?.isUserInteractionEnabled = false
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
        onOpen = nil
        onClose = nil
        content = nil
        labelView = nil
        labelCornerRadius = nil
        alignment = .automatic
        placementOffset = .zero
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
        if let id = highlightedItemID, let item = items[id] {
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
    /// iOS 26 lens morph: 0 = lens sits on the label, 1 = full menu platter.
    @State private var morphProgress: CGFloat = 0
    /// iOS 26: the halo materializes over the button on open and melts off
    /// the restored button at the end of the close — never pops.
    @State private var lensOpacity: Double = 0

    private var overlapsAnchor: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = Metrics(geo: geo, anchor: controller.anchor, overlapsAnchor: overlapsAnchor,
                                  alignment: controller.alignment, placementOffset: controller.placementOffset)
            ZStack(alignment: .topLeading) {
                // Swallows every outside touch, exactly like the native menu.
                // Mid-close, a tap landing on the collapsing button reopens the
                // menu from wherever the shrink is (native interruptibility);
                // any other tap is inert while dismissing.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .global) { location in
                        controller.overlayTapped(at: location)
                    }

                if let content = controller.content {
                    if #available(iOS 26.0, *) {
                        glassPresentation(content: content(), metrics: metrics)
                    } else {
                        legacyPresentation(content: content(), metrics: metrics)
                    }
                }

                // While DISMISSING, this always-mounted catcher sits above the
                // collapsing platter and owns every tap (the glass effect's own
                // UIPlatformGlassInteractionView would otherwise swallow them
                // before the backdrop sees them): a tap on the collapsing button
                // reopens, anywhere else is inert. Hit-through whenever not
                // dismissing, and never a structural change mid-animation — a
                // mounted/unmounted swap or a trait flip on the GLASS subtree
                // mid-flight stalls its rendering.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .global) { location in
                        controller.overlayTapped(at: location)
                    }
                    .allowsHitTesting(controller.phase == .dismissing)
            }
            .onChange(of: geo.size) { _, _ in
                controller.dismiss(animated: false)
            }
            .onChange(of: controller.phase) { _, newPhase in
                if #available(iOS 26.0, *) {
                    if newPhase == .dismissing {
                        withAnimation(TimeCustomMenuSpec.bloomClose) {
                            morphProgress = 0
                        }
                    } else if newPhase == .shown, bloomStarted {
                        // Reopen mid-close: retarget the collapse back into a
                        // bloom from wherever the morph currently is.
                        lensOpacity = 1
                        withAnimation(TimeCustomMenuSpec.bloomOpen) {
                            morphProgress = 1
                        }
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

    /// The native iOS 26 lens morph, replicated from frame-by-frame analysis of
    /// a real device recording: on open, the button's rect becomes a glass lens
    /// that swallows the label (its pixels blur/refract inside), then the lens
    /// grows from the label's rect to the menu's rect while the menu content
    /// de-blurs and materializes. Dismissal is the exact reverse — the menu
    /// liquefies back into the button and the label re-materializes inside.
    /// One persistent glass view + Animatable frame interpolation; no glass
    /// transitions involved (the broken ones aren't needed).
    @available(iOS 26.0, *)
    @ViewBuilder
    private func glassPresentation(content: AnyView, metrics: Metrics) -> some View {
        // Bloom from a size known up front — measured on a previous open (cached on
        // the controller) or the caller's estimate — so the morph starts on the tap
        // frame. The content is already warm (pre-built by the caller, see the picker
        // warm-up at the call site) so it rides the morph from frame 0 and fades in
        // with it (MenuLensMorph ramps content opacity over progress 0.55→1) without
        // a build hitch.
        let knownSize = menuSize ?? controller.cachedMenuSize ?? controller.estimatedContentSize

        // Hidden sizing copy — only needed until we have a real measured size to
        // cache. Once cached, later opens skip it entirely, so the heavy content is
        // built once per open (not twice) and the bloom stays cheap.
        if controller.cachedMenuSize == nil {
            chromeCore(content: content, metrics: metrics)
                .environment(\.timeCustomMenuIsMeasuring, true)
                .opacity(0)
                .allowsHitTesting(false)
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { size in
                    // Wait for the scroll-capped pass before trusting oversized menus.
                    guard size.height <= metrics.maxHeight + 1 else { return }
                    menuSize = size
                    controller.cacheMenuSize(size)
                    controller.menuFrame = CGRect(origin: metrics.placement(for: size).origin, size: size)
                }
        }

        if let size = knownSize {
            let menuRect = CGRect(origin: metrics.placement(for: size).origin, size: size)
            // Collapse onto the caller's explicit morph target if given (e.g. the
            // pager's first item), else the label's live frame, else the open-time
            // anchor before the first geometry update lands.
            let collapsedRect = controller.morphAnchor
                ?? (controller.collapseAnchor == .zero ? controller.anchor : controller.collapseAnchor)
            // No GlassEffectContainer: with a single lens shape it isn't needed,
            // and the container both composites its glass ABOVE sibling content
            // (so the label can't sit over it) and ignores per-view .opacity (so
            // the glass can't fade). Standalone .glassEffect honours both, which is
            // what lets the glass melt out under the label on close.
            // Positioned with layout padding (inside the modifier), never .offset.
            ZStack(alignment: .topLeading) {
                chromeCore(content: content, metrics: metrics)
                    .modifier(MenuLensMorph(
                        progress: morphProgress,
                        collapsed: collapsedRect,
                        collapsedRadius: controller.labelCornerRadius ?? collapsedRect.height / 2,
                        expanded: menuRect,
                        label: controller.labelView?(),
                        isClosing: controller.phase == .dismissing
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
        // The lens is pixel-identical to the label at progress 0, so it takes over
        // the button instantly (no fade-in — that adds perceptible lag).
        lensOpacity = 1
        controller.hideSourceLabel()
        // Escape the layout transaction so the morph animates from a committed frame
        // instead of snapping on initial render.
        DispatchQueue.main.async {
            withAnimation(TimeCustomMenuSpec.bloomOpen) { morphProgress = 1 }
        }
    }

    // MARK: Pre-26 — classic scale/fade

    @ViewBuilder
    private func legacyPresentation(content: AnyView, metrics: Metrics) -> some View {
        let visible = appeared && controller.phase == .shown
        let placement = metrics.placement(for: menuSize ?? .zero)

        chromeCore(content: content, metrics: metrics)
            .background {
                TimeCustomMenuSpec.platterShape
                    .fill(.regularMaterial)
                    .shadow(.floating)
            }
            .clipShape(TimeCustomMenuSpec.platterShape)
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
            // full-screen backdrop and close the menu. This gesture simply absorbs
            // those taps; child buttons and the Done button still win on their own
            // frames, and the wheel still scrolls (it's a drag). One exception:
            // while DISMISSING, the collapsing platter still covers the button, so
            // a tap here is the "reopen mid-close" tap — route it like a backdrop
            // tap instead of swallowing it.
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

    /// The lens morph, frame-matched against the native menu in the iOS 26
    /// simulator: ONE rounded rect inflating straight from the button's rect to
    /// the platter's rect (top-leading edges flush with the button — the
    /// simulator's native menu has no droplet/circle phase). While it grows,
    /// the swallowed label blurs/fades out in place over the first
    /// `labelFadeProgress` of the morph, and the menu content rides the platter
    /// scaled, materializing blur→sharp across the content ramp. Dismissal runs
    /// the same path in reverse with the glass melting off over the final
    /// expand, so the label alone lands on the button. Animatable progress
    /// drives layout, so SwiftUI interpolates every spring frame — overshoot
    /// extrapolates past the platter rect exactly like the native spring.
    @available(iOS 26.0, *)
    private struct MenuLensMorph: ViewModifier, Animatable {
        var progress: CGFloat
        let collapsed: CGRect
        /// The label's own corner radius, so the lens lands exactly on its shape.
        let collapsedRadius: CGFloat
        let expanded: CGRect
        let label: AnyView?
        /// While dismissing, the glass melts off over the final expand so the
        /// label finishes the motion alone (no glass left to pop afterwards).
        let isClosing: Bool

        var animatableData: CGFloat {
            get { progress }
            set { progress = newValue }
        }

        private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
            a + (b - a) * t
        }

        func body(content: Content) -> some View {
            let p = progress
            let w = max(1, lerp(collapsed.width, expanded.width, p))
            let h = max(1, lerp(collapsed.height, expanded.height, p))
            let x = lerp(collapsed.minX, expanded.minX, p)
            let y = lerp(collapsed.minY, expanded.minY, p)
            // Radius runs label shape → platter shape, capped so tiny lenses
            // stay capsule-legal.
            let radius = min(min(w, h) / 2,
                             lerp(collapsedRadius, TimeCustomMenuSpec.platterCornerRadius, p))
            let contentOpacity = Double(((p - TimeCustomMenuSpec.contentFadeStart)
                / (TimeCustomMenuSpec.contentFadeEnd - TimeCustomMenuSpec.contentFadeStart))
                .clamped(to: 0...1))
            // On close only, melt the glass off across the final expand (p → 0) so
            // the label — layered on top — is what finishes landing on the button,
            // with no glass left to fade out in a separate beat afterwards.
            let glassOpacity: Double = isClosing
                ? Double((p / TimeCustomMenuSpec.closeGlassFadeProgress).clamped(to: 0...1))
                : 1

            ZStack(alignment: .topLeading) {
                // Glass platter + menu content. The glass rides this layer so it
                // can fade out independently of the label on close.
                content
                    .frame(width: expanded.width, height: expanded.height, alignment: .topLeading)
                    .scaleEffect(x: w / max(expanded.width, 1),
                                 y: h / max(expanded.height, 1),
                                 anchor: .topLeading)
                    .blur(radius: (1 - p).clamped(to: 0...1) * TimeCustomMenuSpec.lensBlur)
                    .opacity(contentOpacity)
                    .frame(width: w, height: h, alignment: .topLeading)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius))
                    .opacity(glassOpacity)

                // The swallowed label, pinned to the button's screen spot inside
                // the growing lens and layered ON TOP of the glass so on close it
                // outlives the glass fade and is what lands on the button. Native
                // labels blur/fade out in place — they never move or scale.
                if let label {
                    let labelFade = isClosing ? TimeCustomMenuSpec.labelFadeProgressClosing
                                              : TimeCustomMenuSpec.labelFadeProgress
                    label
                        .fixedSize()
                        .position(x: collapsed.midX - x, y: collapsed.midY - y)
                        .frame(width: w, height: h)
                        .blur(radius: (p / labelFade).clamped(to: 0...1)
                                      * TimeCustomMenuSpec.lensBlur * 0.45)
                        .opacity(Double((1 - p / labelFade).clamped(to: 0...1)))
                        // Visual chrome only. SwiftUI hit-tests at MODEL values —
                        // mid-close the model sits at p=0 where this copy is fully
                        // opaque over the button, and it would eat the reopen tap
                        // before the backdrop (routing) ever sees it.
                        .allowsHitTesting(false)
                }
            }
            .frame(width: w, height: h, alignment: .topLeading)
            .padding(.leading, max(0, x))
            .padding(.top, max(0, y))
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
        /// Nudge applied to the final placement (positive = right / down).
        let placementOffset: CGSize
        let spaceBelow: CGFloat
        let spaceAbove: CGFloat

        var maxHeight: CGFloat { max(spaceBelow, spaceAbove) }
        var maxWidth: CGFloat { available.width }

        init(geo: GeometryProxy, anchor: CGRect, overlapsAnchor: Bool,
             alignment: TimeCustomMenuAlignment, placementOffset: CGSize) {
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
            self.placementOffset = placementOffset
            if overlapsAnchor {
                spaceBelow = available.maxY - anchor.minY
                spaceAbove = anchor.maxY - available.minY
            } else {
                spaceBelow = available.maxY - (anchor.maxY + TimeCustomMenuSpec.anchorGap)
                spaceAbove = (anchor.minY - TimeCustomMenuSpec.anchorGap) - available.minY
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
