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
//  ── iOS 26 lens-morph mechanics (replicated from device recordings) ─────────
//  On touch the label line becomes a glass capsule that SWALLOWS the text (its
//  pixels refract inside) and — within a frame or two — contracts into a small
//  circle risen above the line, dissolving the text as it goes (the "birth"
//  gesture); the circle then erupts into the rounded-rect platter — which
//  COVERS the button's rect (near edges flush, no gap) — while the menu
//  content materializes. Dismissal is the reverse: the platter sinks back
//  through the circle onto the line, the label re-materializing inside the
//  landing capsule as the glass melts off it.
//  Implementation: ONE persistent glass view whose keyframed frame/radius/
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

    // ── iOS 26 Liquid Glass lens morph ──
    /// Default platter corner radius — stand-in for the system's concentric radius.
    static let platterCornerRadius = CornerRadius.customMenu
    /// Glass shapes closer than this blend/morph inside the container.
    static let morphSpacing: CGFloat = 40
    /// Peak refraction blur while the label is being swallowed / content
    /// materializes (matched against device recordings of the native lens).
    static let lensBlur: CGFloat = 8
    /// Progress at which the birth gesture (label-line capsule → risen circle)
    /// completes. Kept tiny so it spans a frame or two of the open spring —
    /// near-instant, like the native recording.
    static let birthProgress: CGFloat = 0.08
    /// Birth circle diameter as a fraction of the platter's resting height
    /// (device recording: ~82pt circle for a ~248pt menu).
    static let birthHeightFraction: CGFloat = 0.33
    /// How far the birth circle's near edge — the edge toward the label line —
    /// sits inside the platter's resting frame, as a fraction of resting height
    /// (measured ~60pt on a ~248pt upward-opening menu: the circle hangs off the
    /// source line, never on it, leading the eruption; mirrored when the menu
    /// opens downward).
    static let birthLiftFraction: CGFloat = 0.24
    /// The swallowed label copy is fully dissolved by this progress: its pixels
    /// refract through the capsule's contraction and are gone as the circle
    /// rises (re-materializing across the same window on close). Roughly double
    /// the birth leg, so the dissolve trails the geometry by a beat.
    static let labelFadeProgress: CGFloat = 0.16
    /// Lens morph timing against the native open (~0.45s, slight settle).
    static let bloomOpen = Animation.spring(response: 0.45, dampingFraction: 0.82)
    /// Keeps the glass platter attached to content whose height changes while
    /// the menu is open (for example, when a pager reveals a taller page).
    static let reflowResize = Animation.spring(duration: 0.2)
    /// Shrinking back through the circles never bounces (~0.4s on device).
    static let bloomClose = Animation.smooth(duration: 0.38)
    /// After the close morph lands on the button, the lens halo melts off the
    /// restored label rather than popping out in one frame.
    static let lensFadeOut = Animation.easeOut(duration: 0.15)
    /// Close morph length before the label is restored and the halo melts.
    static let closeMorphDuration: TimeInterval = 0.4
    static let lensFadeDuration: TimeInterval = 0.18
    /// On close, the glass is fully present at this progress and melts linearly to
    /// nothing by progress 0 — i.e. it fades across the tail of the shrink (the
    /// circle sinking back onto the label line), so the dimmed label is all that
    /// remains and there's no glass left to pop. Smaller concentrates the melt
    /// later / quicker near the very end.
    static let closeGlassFadeProgress: CGFloat = 0.35
    /// An opaque platter fill (`TimeCustomMenu.platterFill`) ramps in across the
    /// eruption: nothing at birth, where the lens is pure refraction over the label
    /// line and a fill would white it out, full by the time the circle has grown
    /// into the platter and the content materializes. Reversed on close with the
    /// rest of the morph, so the fill only ever exists mid-flight.
    static let platterFillRange: ClosedRange<CGFloat> = 0.35...0.7

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
    /// Nudge applied to the final placement (positive = right / down). Defaults
    /// to the spec values; override per call site to fine-tune.
    var placementOffset: CGSize
    /// Optional binding kept in sync with the menu's presentation state.
    var isOpen: Binding<Bool>?
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
    //Present-once latch for the current touch, so a mid-touch teardown (e.g. a
    //second finger selecting an item) can't instantly re-present on the next move.
    @State private var openAttempted = false

    init(cornerRadius: CGFloat = TimeCustomMenuSpec.platterCornerRadius,
         labelCornerRadius: CGFloat? = nil,
         platterFill: Color? = nil,
         morphAnchor: CGRect? = nil,
         estimatedContentSize: CGSize? = nil,
         tracksContentSizeChanges: Bool = false,
         alignment: TimeCustomMenuAlignment = .automatic,
         placementOffsetX: CGFloat = TimeCustomMenuSpec.placementOffsetX,
         placementOffsetY: CGFloat = TimeCustomMenuSpec.placementOffsetY,
         isOpen: Binding<Bool>? = nil,
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
        self.placementOffset = CGSize(width: placementOffsetX, height: placementOffsetY)
        self.isOpen = isOpen
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
            // Dim-only press feedback (native labels dim, never shrink), shown only when
            // the touch-down present failed — the lens copy renders at full brightness, so
            // dimming on the normal path would flash 0.5 → 1 as it takes over. Applied
            // AFTER the geometry read so it never feeds back into the placement anchor.
            // iOS 26: `hidesLabel` swallows the real label while the menu's lens is up
            // (it is the menu now), like native.
            .opacity(controller.hidesLabel ? 0 : (pressed ? TimeCustomMenuSpec.pressedLabelOpacity : 1))
            .animation(pressed ? nil : TimeCustomMenuSpec.pressDimRelease, value: pressed)
            .simultaneousGesture(openAndDragSelect)
            // A cancelled touch (incoming call, app switch, system alert) never
            // delivers onEnded, which owns the resets — without these the label
            // would strand at the pressed dim and the latch would eat the next tap.
            .onChange(of: scenePhase) { _, phase in
                guard phase != .active else { return }
                pressed = false
                openAttempted = false
            }
            .onDisappear {
                pressed = false
                openAttempted = false
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

    /// Presents the menu on touch-DOWN — the instant the finger lands, like native —
    /// then the same continuing touch drives the native press-drag-release selection:
    /// drag highlights items (`dragMoved`), release selects, dismisses, or holds open
    /// (`dragEnded`; a sub-`tapSlop` release keeps the menu open, so a quick tap just
    /// opens it). A `.simultaneousGesture` so touch-down fires even over the time
    /// pager's ScrollView (a plain `.gesture` defers to the scroll and only fires at
    /// release). Accepted trade-off, exactly like a native Menu label: a drag that
    /// starts on the label opens the menu instead of scrolling/paging.
    private var openAndDragSelect: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if controller.isPresented {
                    // Drag-select needs a real drag: a stationary opening tap must
                    // not highlight (and later select) whatever item the platter
                    // lays under the finger once it covers the anchor.
                    let moved = hypot(value.translation.width, value.translation.height)
                    if moved >= TimeCustomMenuSpec.tapSlop {
                        controller.dragMoved(to: value.location)
                    }
                    return
                }
                guard !openAttempted else { return }
                openAttempted = true
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
                // Dim only when the menu could not open (rare: no active scene) —
                // on the normal path the swallow itself is the press feedback.
                if !controller.isPresented { pressed = true }
            }
            .onEnded { value in
                openAttempted = false
                pressed = false
                guard controller.isPresented else { return }
                controller.dragEnded(at: value.location, translation: value.translation)
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
    private(set) var cornerRadius = TimeCustomMenuSpec.platterCornerRadius
    private(set) var labelCornerRadius: CGFloat?
    /// Caller's opaque platter fill, painted over the glass. See `TimeCustomMenu.platterFill`.
    private(set) var platterFill: Color?
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
    /// iOS 26 lens morph: 0 = lens sits on the label, 1 = full menu platter.
    @State private var morphProgress: CGFloat = 0
    /// iOS 26: the halo materializes over the button on open and melts off
    /// the restored button at the end of the close — never pops.
    @State private var lensOpacity: Double = 0

    private var overlapsAnchor: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    private var platterShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: controller.cornerRadius)
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = Metrics(geo: geo, anchor: controller.anchor, overlapsAnchor: overlapsAnchor,
                                  alignment: controller.alignment, placementOffset: controller.placementOffset)
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
                    withAnimation(TimeCustomMenuSpec.bloomClose) {
                        morphProgress = 0
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
    /// real device recordings: on open, the label line becomes a glass capsule
    /// that swallows the text (its pixels blur/refract inside), darts into a
    /// small circle risen off the line — dissolving the text as it goes — then
    /// erupts into the menu's rect while the menu content de-blurs and
    /// materializes. Dismissal is the reverse — the platter sinks back through
    /// the circle onto the line and the label re-materializes inside the
    /// landing capsule.
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
                        collapsed: collapsedRect,
                        collapsedRadius: controller.labelCornerRadius ?? collapsedRect.height / 2,
                        expanded: menuRect,
                        expandedRadius: controller.cornerRadius,
                        platterFill: controller.platterFill,
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
        // The lens is pixel-identical to the label at progress 0 (its copy at full
        // brightness inside the capsule), so it takes over the button instantly
        // (no fade-in — that adds perceptible lag).
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

    /// The lens morph, keyframed from device recordings of the native menu.
    /// The lens moves in two legs, swallowing the label as it goes:
    ///   p 0 → birthProgress   the birth gesture: a capsule of glass hugging
    ///                         the label line — the label's pixels refracting
    ///                         inside — contracts into a small circle risen
    ///                         above it, a frame or two, near-instant;
    ///   p birthProgress → 1   the circle erupts into the rounded-rect platter
    ///                         while the menu content materializes (the label
    ///                         copy has dissolved by labelFadeProgress).
    /// Dismissal runs the same path in reverse, the glass melting as it sinks
    /// back onto the line and the label re-materializing inside the landing
    /// capsule. Animatable progress drives layout, so SwiftUI interpolates
    /// every spring frame through this modifier.
    @available(iOS 26.0, *)
    private struct MenuLensMorph: ViewModifier, Animatable {
        var progress: CGFloat
        let collapsed: CGRect
        /// The label's own corner radius, so the lens is born exactly on its shape.
        let collapsedRadius: CGFloat
        let expanded: CGRect
        /// Corner radius of the expanded menu platter.
        let expandedRadius: CGFloat
        /// Opaque fill over the glass, ramped in with the morph. See `TimeCustomMenu.platterFill`.
        let platterFill: Color?
        let label: AnyView?
        /// While dismissing, the glass melts off across the shrink's tail so the
        /// label — landing inside it — finishes the motion alone (no glass left
        /// to pop afterwards).
        let isClosing: Bool
        /// Progress the melt fades down from, captured when the close begins: a
        /// close that interrupts the bloom below `closeGlassFadeProgress` melts
        /// from wherever the glass actually is, keeping its opacity continuous
        /// instead of dropping a step the frame the formula switches.
        @State private var closeFadeCeiling: CGFloat?

        var animatableData: CGFloat {
            get { progress }
            set { progress = newValue }
        }

        private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
            a + (b - a) * t
        }

        /// Piecewise lens geometry across the two legs above.
        private func lensFrame(_ p: CGFloat) -> (rect: CGRect, radius: CGFloat) {
            // Birth circle: sized against the platter's resting height (clamped
            // up for very short menus so the capsule always has a circle to
            // contract into), floating off the label line just inside the
            // platter's territory — it leads the eruption. Horizontally it stays
            // on the label's own centre (drifting to the platter's centre only
            // during the eruption); vertically it's anchored to whichever platter
            // edge carries the line: the bottom edge when the menu opens upward
            // (the measured case), mirrored to the top edge when it opens downward.
            let d = max(collapsed.height * 1.2,
                        expanded.height * TimeCustomMenuSpec.birthHeightFraction)
            let lift = expanded.height * TimeCustomMenuSpec.birthLiftFraction
            let opensUpward = expanded.midY <= collapsed.midY
            let birthCenter = CGPoint(
                x: collapsed.midX,
                y: opensUpward ? expanded.maxY - lift - d / 2
                               : expanded.minY + lift + d / 2
            )
            let birth = TimeCustomMenuSpec.birthProgress

            let w: CGFloat, h: CGFloat, cx: CGFloat, cy: CGFloat, radius: CGFloat
            if p < birth {
                // Birth gesture: capsule on the label line → risen circle. Radius
                // starts at the label's own corner radius so the lens is born (and
                // on close, lands) exactly on the button's shape, never a different one.
                let t = max(0, p / birth)
                w = lerp(collapsed.width, d, t)
                h = lerp(collapsed.height, d, t)
                cx = lerp(collapsed.midX, birthCenter.x, t)
                cy = lerp(collapsed.midY, birthCenter.y, t)
                radius = min(min(w, h) / 2, lerp(collapsedRadius, d / 2, t))
            } else {
                // Eruption: circle grows into the platter (spring overshoot
                // extrapolates past the resting frame).
                let t = (p - birth) / (1 - birth)
                w = lerp(d, expanded.width, t)
                h = lerp(d, expanded.height, t)
                cx = lerp(birthCenter.x, expanded.midX, t)
                cy = lerp(birthCenter.y, expanded.midY, t)
                radius = min(min(w, h) / 2, lerp(d / 2, expandedRadius, t))
            }
            return (CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h), radius)
        }

        func body(content: Content) -> some View {
            let p = progress
            let lens = lensFrame(p)
            let w = lens.rect.width
            let h = lens.rect.height
            // The swallowed label shrinks with the capsule so it stays inside.
            let labelScale = min(2, min(w / max(collapsed.width, 1),
                                        h / max(collapsed.height, 1)))
            // On close only, melt the glass off across the shrink's tail (p → 0) so
            // the label copy — layered on top — is what finishes landing on the
            // button, with no glass left to fade out in a separate beat afterwards.
            let fadeCeiling = closeFadeCeiling ?? TimeCustomMenuSpec.closeGlassFadeProgress
            let glassOpacity: Double = isClosing
                ? Double((p / fadeCeiling).clamped(to: 0...1))
                : 1
            // The opaque fill materializes across the eruption (both directions), so
            // at birth — the lens hugging the label line — nothing is painted over it.
            let fillRange = TimeCustomMenuSpec.platterFillRange
            let fillOpacity = Double(((p - fillRange.lowerBound) /
                                      (fillRange.upperBound - fillRange.lowerBound)).clamped(to: 0...1))

            ZStack(alignment: .topLeading) {
                // Keep the platter glass behind the controls. Applying glass to the
                // content itself captures native control chrome (including a wheel
                // picker's system selection indicator) in the glass foreground pass.
                Color.clear
                    .frame(width: w, height: h)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: lens.radius))
                    .opacity(glassOpacity)

                // Opaque platter OVER the glass, in the lens's own shape so it morphs with
                // it (a fill on the content would stay a hard-cornered rect through the
                // birth circle). Above and not below: glass wears a system-appearance tint
                // and the menu's own UIWindow follows the DEVICE appearance, so a fill
                // underneath reads as tinted glass (flat grey on a dark-appearance device),
                // never as its own colour. The glass beneath still carries the birth leg
                // and early eruption, where the fill has not ramped in yet.
                // Only for menus that bloom over imagery — see `platterFill`.
                if let platterFill {
                    RoundedRectangle(cornerRadius: lens.radius)
                        .fill(platterFill)
                        .frame(width: w, height: h)
                        .opacity(glassOpacity * fillOpacity)
                }

                content
                    .frame(width: expanded.width, height: expanded.height, alignment: .topLeading)
                    .scaleEffect(x: w / max(expanded.width, 1),
                                 y: h / max(expanded.height, 1),
                                 anchor: .topLeading)
                    .blur(radius: (1 - p).clamped(to: 0...1) * TimeCustomMenuSpec.lensBlur)
                    .opacity(Double(((p - 0.55) / 0.45).clamped(to: 0...1)))
                    .frame(width: w, height: h, alignment: .topLeading)

                // The swallowed label, layered ON TOP of the glass so on close it
                // outlives the glass fade and is what lands on the button.
                // fixedSize keeps its intrinsic layout (no reflow/truncation); it
                // shrinks purely visually with the capsule. Dissolved across the
                // birth leg — pixels refracting through the capsule's contraction,
                // gone as the circle rises — and re-materializing there on close.
                if let label {
                    let dissolve = (p / TimeCustomMenuSpec.labelFadeProgress).clamped(to: 0...1)
                    label
                        .fixedSize()
                        .scaleEffect(labelScale)
                        .frame(width: w, height: h)
                        .blur(radius: dissolve * TimeCustomMenuSpec.lensBlur)
                        .opacity(Double(1 - dissolve))
                }
            }
            .frame(width: w, height: h, alignment: .topLeading)
            .padding(.leading, max(0, lens.rect.minX))
            .padding(.top, max(0, lens.rect.minY))
            .onChange(of: isClosing) { _, closing in
                // Captures the in-flight progress the frame the close starts (the
                // retargeted spring continues from it). If this evaluation ever
                // reads the stale open target (1) instead, the min() degrades to
                // the spec ceiling — i.e. exactly the uncaptured behavior.
                guard closing else { return }
                closeFadeCeiling = min(max(progress, 0.02),
                                       TimeCustomMenuSpec.closeGlassFadeProgress)
            }
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
