//AI Code Beware!
//  SelectTypeTest.swift
//  Scoop
//
//  Created by Art Ostin on 11/06/2026.
//
//  TypeCustomMenu — a reusable recreation of the native menu presentation that
//  accepts fully arbitrary content. On iOS 26+ it reproduces the Liquid Glass
//  menu: a glass bubble that morphs ("blooms") out of the label, and morphs
//  back into it on dismissal. Pre-26 it falls back to the classic scale/fade.
//
//  Usage:
//      TypeCustomMenu {
//          // any SwiftUI view / layout
//      } label: {
//          // the trigger view
//      }
//
//  Inside the content closure:
//      .typeCustomMenuItem { ... }        — row participates in drag-to-select highlight,
//                                       runs its action and dismisses on selection.
//      @Environment(\.typeCustomMenuDismiss) — programmatic dismissal from content. A tap
//                                       on the menu's own content never auto-dismisses;
//                                       call this action (or use .typeCustomMenuItem) to
//                                       close it. Tapping outside still dismisses.
//
//  ── iOS 26 bloom mechanics ──────────────────────────────────────────────────
//  OPEN: the glass platter grows directly out of the LABEL'S FULL FRAME (the whole
//  button), straight into the rounded-rect platter, while the menu content de-blurs
//  and materializes. There is no intermediate droplet or travelling phase — the
//  shape only ever grows monotonically from the button's rect to the platter.
//  CLOSE is NOT the reverse: the platter shrinks down toward the label but, instead
//  of landing on its rect, passes through a GLASS CIRCLE at the label's centre, then
//  relaxes that circle back onto the label while the selected value materializes and
//  the glass melts off it. That final half (circle → label) is byte-for-byte
//  TimeCustomMenu's end-of-close — same droplet size, glass fade and timing. The label
//  is captured and re-materializes as the glass dissolves; the real label is HIDDEN in
//  the app tree from open through the end of the close (`hidesLabel`), then restored
//  underneath as the last of the glass melts.
//  (An earlier version grew the morph out of a small trailing-edge circle, and closed
//  by simply shrinking back into the button; the close was reworked into the circle →
//  reveal by request.)
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
//  and shadow values are not public; `TypeCustomMenuSpec` holds tuned approximations
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

struct TypeCustomMenuBuilder: View {

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
        TypeCustomMenu {
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
            .frame(width: TypeCustomMenuSpec.standardWidth)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 24))
                .foregroundStyle(Color.successGreen)
                .padding(8)
        }
    }

    /// Arbitrary layout: a reaction bar over a colour grid — impossible in a native Menu.
    private var freeformMenu: some View {
        TypeCustomMenu {
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    ForEach(["🍦", "🍨", "🍧", "🍫", "🍓"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 28))
                            .typeCustomMenuItem { flavour = emoji }
                    }
                }
                Divider()
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(44)), count: 4), spacing: 10) {
                    ForEach([Color.successGreen, .accent, .warningYellow,
                             .border, .textTertiary, .appCanvas, .dangerRed], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 38, height: 38)
                            .typeCustomMenuItem { }
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
        .typeCustomMenuItem(action: action)
    }
}

#Preview {
    TypeCustomMenuBuilder()
}

// MARK: - Spec (approximations of the private native values)

enum TypeCustomMenuSpec {

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
    static let bloomOpen = Animation.spring(response: 0.32, dampingFraction: 0.82)
    /// The close runs the platter down to a glass circle at the label's centre, then
    /// relaxes that circle back out into the label, the value materializing as the
    /// glass melts off it. The final-expand half (circle → label) is byte-for-byte the
    /// time menu's end-of-close, so all four constants below match TimeCustomMenu's.
    static let bloomClose = Animation.smooth(duration: 0.38)
    /// Progress at which the platter has fully shrunk to the centre circle; below this
    /// the circle relaxes back into the label (the reveal). Matches the time menu's
    /// droplet keyframe, so the final expand runs over the identical [0, 0.35] window.
    static let closeRevealStart: CGFloat = 0.35
    /// Centre-circle diameter as a multiple of the label height — the small circle the
    /// label squeezes into. Identical to TimeCustomMenu's `dropletScale`.
    static let dropletScale: CGFloat = 1.45
    /// On close the glass is fully present at this progress and melts linearly to
    /// nothing by progress 0 — i.e. it fades across the final expand (the circle
    /// relaxing back into the label), so the value alone lands. Matches the time menu.
    static let closeGlassFadeProgress: CGFloat = 0.35
    /// After the menu is open, content can reflow (e.g. an info row expands) and
    /// change the platter's height. Grow it with this curve — matched to the
    /// content's own expand animation — so the glass tracks the content instead
    /// of snapping. Only applies post-open; the initial sizing stays unanimated.
    /// Must stay identical to the curve the content reflows on (SelectTypeView's
    /// info toggle uses `.snappy(duration: 0.3)`); a different spring here makes
    /// the platter fill drift ahead of the content's own stroke as it extends.
    static let reflowResize = Animation.snappy(duration: 0.3)
    /// After the close morph lands on the label, the leftover lens halo melts off the
    /// restored label rather than popping out in one frame. Matches the time menu.
    static let lensFadeOut = Animation.easeOut(duration: 0.15)
    /// Close morph length before the real label is restored and the halo melts.
    /// Matches the time menu.
    static let closeMorphDuration: TimeInterval = 0.4
    static let lensFadeDuration: TimeInterval = 0.18
    /// How long the `.pop` dismiss (the `.scoopPop` transition) runs before the window
    /// tears down. Matches the settle of `Animation.scoopPop` (response 0.35, slight bounce).
    static let popCloseDuration: TimeInterval = 0.5
    /// Platter shadow at full bloom (native casts a wide soft shadow).
    static let platterShadowOpacity: CGFloat = 0.1
    static let platterShadowRadius: CGFloat = 24
    static let platterShadowY: CGFloat = 10

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

// MARK: - TypeCustomMenu

/// Which edge of the label the menu aligns its corresponding edge to.
/// `.automatic` picks the edge by whichever screen half the label's centre sits
/// in (the native default) — use `.leading` / `.trailing` when the label is wide
/// enough that its centre is ambiguous (e.g. a full-width row with a Spacer).
enum TypeCustomMenuAlignment {
    case leading, trailing, automatic
}

struct TypeCustomMenu<Content: View, Label: View>: View {

    @ViewBuilder var content: () -> Content
    @ViewBuilder var label: () -> Label
    /// Corner radius of the menu platter itself. `nil` uses the spec defaults
    /// (26pt on iOS 26's glass, 13pt on the pre-26 platter); pass a value to
    /// override from the call site without touching `TypeCustomMenu`.
    var cornerRadius: CGFloat?
    /// Per-corner platter radii, for cards whose top/bottom corners differ. When
    /// set it overrides `cornerRadius`, and the footer (if any) uses the vertical
    /// mirror of these so a card + footer read as one split rounded group.
    var cornerRadii: RectangleCornerRadii?
    /// Explicit footer corners. `nil` keeps the mirror-of-platter default; set this
    /// to give the footer its own radii independent of the platter.
    var footerCornerRadii: RectangleCornerRadii?
    /// Which label edge the menu aligns to (see `TypeCustomMenuAlignment`).
    var alignment: TypeCustomMenuAlignment
    /// iOS 26 glass bloom origin. `false` (default) grows the platter from / collapses
    /// it back into the label's full frame (the whole button). `true` reverts to the
    /// original behaviour: a small circle at the label's trailing edge. No effect on
    /// the pre-26 fallback (which always scales from an anchor point near the label).
    var morphsFromTrailingPoint: Bool
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
    /// `.typeCustomMenuFooterPlatter`; TypeCustomMenu only sizes, positions and morphs it. It is
    /// never part of the lens morph — it fades/scales in once the menu is open and out on
    /// close. `nil` (the default) means no footer, so existing call sites are unaffected.
    /// Items inside it use `.typeCustomMenuItem` / `typeCustomMenuDismiss` just like content.
    var footer: (() -> AnyView)?

    @State private var controller = TypeCustomMenuController()
    @State private var labelFrame: CGRect = .zero
    @GestureState private var isPressed = false

    init(cornerRadius: CGFloat? = nil,
         cornerRadii: RectangleCornerRadii? = nil,
         footerCornerRadii: RectangleCornerRadii? = nil,
         alignment: TypeCustomMenuAlignment = .automatic,
         morphsFromTrailingPoint: Bool = false,
         placementOffsetX: CGFloat = TypeCustomMenuSpec.placementOffsetX,
         placementOffsetY: CGFloat = TypeCustomMenuSpec.placementOffsetY,
         onOpen: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil,
         footer: (() -> AnyView)? = nil,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder label: @escaping () -> Label) {
        self.cornerRadius = cornerRadius
        self.cornerRadii = cornerRadii
        self.footerCornerRadii = footerCornerRadii
        self.alignment = alignment
        self.morphsFromTrailingPoint = morphsFromTrailingPoint
        self.placementOffset = CGSize(width: placementOffsetX, height: placementOffsetY)
        self.onOpen = onOpen
        self.onClose = onClose
        self.footer = footer
        self.content = content
        self.label = label
    }

    var body: some View {
        // Keep the captured label current while the menu is open, so the close reveal
        // shows the value as it is now (e.g. the type just selected), not the snapshot
        // taken when it opened.
        let _ = syncPresentedLabel()
        // The real label is hidden in the app tree from open through the very end of
        // the close: the glass platter (and on close the value re-materializing inside
        // it) stands in for it, like the time menu. It reflows naturally on selection
        // so the close morph and reveal land on its current value.
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
            // Hidden for the whole presentation (`hidesLabel`); the glass carries the
            // value until it melts off at the end of the close, then the real label
            // takes over again.
            .opacity(controller.hidesLabel ? 0 : (pressed ? press.opacity : 1))
            .animation(pressed
                       ? .snappy(duration: press.pressDuration)
                       : .spring(response: press.release.response, dampingFraction: press.release.damping),
                       value: pressed)
            .gesture(pressAndDrag)
            .onDisappear { controller.dismiss(style: .instant) }
    }

    /// Pushes the freshest label closure into the controller, deferred one runloop turn
    /// so it lands cleanly after the current view-update pass. No-op while closed.
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
                guard distance < TypeCustomMenuSpec.tapSlop else { return }
                onOpen?()
                controller.present(
                    anchor: labelFrame,
                    label: { AnyView(label()) },
                    cornerRadius: cornerRadius,
                    cornerRadii: cornerRadii,
                    footerCornerRadii: footerCornerRadii,
                    alignment: alignment,
                    morphsFromTrailingPoint: morphsFromTrailingPoint,
                    placementOffset: placementOffset,
                    onClose: onClose,
                    footer: footer,
                    content: { AnyView(content()) }
                )
            }
    }
}

// MARK: - Dismiss action environment

/// How the menu leaves the screen.
/// - `morph`: the default glass bloom-close (the platter shrinks back into the label).
/// - `pop`: removes the platter + footer with the `.scoopPop` transition (blur + scale).
/// - `instant`: tears the window down immediately, no animation.
enum TypeCustomMenuDismissStyle { case morph, pop, instant }

struct TypeCustomMenuDismissAction {
    /// Pass a `TypeCustomMenuDismissStyle` to pick the exit (default `.morph`). E.g.
    /// `dismiss(.pop)` for the scoopPop transition, `dismiss(.instant)` for no animation.
    var action: (TypeCustomMenuDismissStyle) -> Void = { _ in }
    func callAsFunction(_ style: TypeCustomMenuDismissStyle = .morph) { action(style) }
}

extension EnvironmentValues {
    @Entry var typeCustomMenuDismiss = TypeCustomMenuDismissAction()
    /// True inside the hidden copy used only for sizing — items must not register.
    @Entry var typeCustomMenuIsMeasuring = false
}

// MARK: - Content modifiers

extension View {
    /// Marks a view as a selectable menu row: it highlights while a drag hovers it,
    /// fires `action` on tap or drag-release, and dismisses the menu.
    func typeCustomMenuItem(action: @escaping () -> Void) -> some View {
        modifier(TypeCustomMenuItemModifier(action: action))
    }

    /// The detached menu-footer material — glass on iOS 26, frosted material + soft shadow
    /// on the classic platter — so a footer card matches the menu's own material. Exposed
    /// (rather than imposed by TypeCustomMenu) so a footer owns its platter: a press effect on
    /// the footer then scales the whole glass card, not just its inner content.
    func typeCustomMenuFooterPlatter(corners: RectangleCornerRadii) -> some View {
        modifier(TypeCustomMenuFooterPlatter(corners: corners))
    }
}

struct TypeCustomMenuFooterPlatter: ViewModifier {
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
                .brightness(TypeCustomMenuSpec.footerShadowCompensation)
        } else {
            content
                .background(shape.fill(.regularMaterial))
                .clipShape(shape)
                .shadow(color: .black.opacity(0.12), radius: 24, y: 16)
        }
    }
}

private struct TypeCustomMenuItemModifier: ViewModifier {
    @Environment(TypeCustomMenuController.self) private var controller: TypeCustomMenuController?
    @Environment(\.typeCustomMenuIsMeasuring) private var isMeasuring
    let action: () -> Void
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .background {
                if controller?.highlightedItemID == id {
                    if #available(iOS 26.0, *) {
                        RoundedRectangle(cornerRadius: TypeCustomMenuSpec.highlightCornerRadius, style: .continuous)
                            .fill(TypeCustomMenuSpec.highlightFill)
                            .padding(3)
                    } else {
                        TypeCustomMenuSpec.highlightFill
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
final class TypeCustomMenuController {

    enum Phase { case measuring, shown, dismissing }

    private(set) var phase: Phase = .measuring
    /// How the in-flight dismissal should animate; the overlay reads it to pick the exit.
    private(set) var dismissStyle: TypeCustomMenuDismissStyle = .morph
    private(set) var anchor: CGRect = .zero
    /// The label's *live* frame, tracked while presented so the close morph
    /// collapses onto where the label is now (it may have reflowed after a
    /// selection), not the frame captured at open time. Placement keeps using the
    /// fixed `anchor` so the open menu never moves underfoot.
    private(set) var collapseAnchor: CGRect = .zero
    private(set) var content: (() -> AnyView)?
    /// The label closure, captured so the close reveal can render the selected value
    /// inside the shrinking glass (the real label is hidden while the menu is up).
    private(set) var labelView: (() -> AnyView)?
    /// Detached accessory rendered as its own glass card below the platter.
    private(set) var footer: (() -> AnyView)?
    /// Caller-supplied platter corner radius; `nil` falls back to the spec value.
    private(set) var cornerRadius: CGFloat?
    /// Caller-supplied per-corner platter radii; overrides `cornerRadius` when set.
    private(set) var cornerRadii: RectangleCornerRadii?
    /// Caller-supplied footer corners; `nil` falls back to the mirror of the platter.
    private(set) var footerCornerRadii: RectangleCornerRadii?
    private(set) var alignment: TypeCustomMenuAlignment = .automatic
    /// Caller-supplied: iOS 26 glass bloom grows from a small trailing-edge circle
    /// instead of the whole button. See `TypeCustomMenu.morphsFromTrailingPoint`.
    private(set) var morphsFromTrailingPoint = false
    private(set) var placementOffset: CGSize = .zero
    /// The real label is hidden in the app tree from open through the very end of the
    /// close reveal, so only the glass (and the value re-materializing inside it) is
    /// seen; flipped back the instant the glass starts melting, for a clean hand-off.
    private(set) var hidesLabel = false
    /// iOS 26: signals the overlay to melt the leftover lens halo off the restored label at the end of close.
    private(set) var lensDissolve = false
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
                 label: @escaping () -> AnyView,
                 cornerRadius: CGFloat? = nil,
                 cornerRadii: RectangleCornerRadii? = nil,
                 footerCornerRadii: RectangleCornerRadii? = nil,
                 alignment: TypeCustomMenuAlignment,
                 morphsFromTrailingPoint: Bool = false,
                 placementOffset: CGSize,
                 onClose: (() -> Void)? = nil,
                 footer: (() -> AnyView)? = nil,
                 content: @escaping () -> AnyView) {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive })
        else { return }

        self.anchor = anchor
        self.collapseAnchor = anchor
        self.labelView = label
        self.cornerRadius = cornerRadius
        self.cornerRadii = cornerRadii
        self.footerCornerRadii = footerCornerRadii
        self.alignment = alignment
        self.morphsFromTrailingPoint = morphsFromTrailingPoint
        self.placementOffset = placementOffset
        self.onClose = onClose
        self.footer = footer
        self.content = content
        // Hide the real label for the whole presentation; the glass (and on close the
        // value re-materializing inside it) stands in for it until the very end.
        hidesLabel = true
        phase = .measuring

        let host = UIHostingController(rootView: TypeCustomMenuOverlayRoot(controller: self))
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

    /// Re-points the captured label at the latest closure so the close reveal shows the
    /// current value (e.g. the type just selected) rather than the snapshot taken when
    /// the menu opened. No-op while not presented.
    func updateLabel(_ label: @escaping () -> AnyView) {
        guard window != nil else { return }
        labelView = label
    }

    func dismiss(style: TypeCustomMenuDismissStyle = .morph) {
        guard window != nil, phase != .dismissing else { return }
        // Fire the moment dismissal is requested — before any close animation runs —
        // so callers don't wait out the animation + teardown.
        onClose?()
        guard style != .instant else { tearDown(); return }
        dismissStyle = style
        phase = .dismissing
        let gen = generation
        if style == .pop {
            // No circle → label reveal on a `.pop`: the platter + footer just blur/scale
            // away, so bring the real label back right away (as before).
            hidesLabel = false
            // The overlay removes the platter + footer with the `.scoopPop` transition;
            // tear the window down once that spring has settled.
            Task {
                try? await Task.sleep(for: .seconds(TypeCustomMenuSpec.popCloseDuration))
                if generation == gen { tearDown() }
            }
            return
        }
        if #available(iOS 26.0, *) {
            // The platter shrinks to a glass circle at the label's centre, then relaxes
            // back onto the label as the value materializes and the glass melts off →
            // restore the real label underneath → melt the leftover halo → teardown.
            Task {
                try? await Task.sleep(for: .seconds(TypeCustomMenuSpec.closeMorphDuration))
                guard generation == gen else { return }
                hidesLabel = false
                lensDissolve = true
                try? await Task.sleep(for: .seconds(TypeCustomMenuSpec.lensFadeDuration))
                if generation == gen { tearDown() }
            }
        } else {
            // Pre-26 has no lens morph / reveal; the classic platter scales+fades out,
            // so restore the real label immediately like the old behaviour.
            hidesLabel = false
            Task {
                try? await Task.sleep(for: .seconds(TypeCustomMenuSpec.teardownDelay))
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
        footer = nil
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
        lensDissolve = false
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
        } else if distance >= TypeCustomMenuSpec.tapSlop,
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

private struct TypeCustomMenuOverlayRoot: View {

    let controller: TypeCustomMenuController

    @State private var menuSize: CGSize?
    @State private var contentIdealHeight: CGFloat?
    @State private var appeared = false
    /// iOS 26 bloom: 0 = small circle at the label's trailing edge, 1 = full menu platter.
    @State private var morphProgress: CGFloat = 0
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
                                let hit = controller.anchor.insetBy(dx: -TypeCustomMenuSpec.labelPressHitSlop,
                                                                    dy: -TypeCustomMenuSpec.labelPressHitSlop)
                                controller.labelPressed = hit.contains(value.startLocation)
                            }
                            .onEnded { _ in
                                controller.labelPressed = false
                                controller.dismiss()
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
                if controller.dismissStyle == .pop {
                    // Remove the platter + footer with the scoopPop transition.
                    withAnimation(.scoopPop) { popExit = true }
                } else if #available(iOS 26.0, *) {
                    withAnimation(TypeCustomMenuSpec.bloomClose) {
                        morphProgress = 0
                    }
                }
            }
            .onChange(of: controller.lensDissolve) { _, dissolve in
                guard dissolve else { return }
                if #available(iOS 26.0, *) {
                    withAnimation(TypeCustomMenuSpec.lensFadeOut) {
                        lensOpacity = 0
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: Detached footer accessory

    /// A separate card sitting a gap below the platter — never part of the lens morph. The
    /// footer draws its own material (`.typeCustomMenuFooterPlatter`); here we only fade + scale
    /// it in once the menu is shown and out the instant dismissal begins. Positioned off the
    /// platter's settled `menuFrame`, so it tracks width/placement automatically. Items inside
    /// it get the same `controller` + `typeCustomMenuDismiss` environment as the menu content, so
    /// `.typeCustomMenuItem` and `@Environment(\.typeCustomMenuDismiss)` work identically.
    @ViewBuilder
    private func footerCard(_ footer: AnyView) -> some View {
        let frame = controller.menuFrame

        // The footer is a self-contained card: it draws its OWN platter (via
        // `.typeCustomMenuFooterPlatter`) and its own press effect, so a tap scales the whole
        // glass card rather than just its inner content. TypeCustomMenu only sizes, positions
        // and morphs it; items inside still get the menu's environment for dismiss/highlight.
        let card = footer
            .environment(controller)
            .environment(\.typeCustomMenuDismiss, TypeCustomMenuDismissAction { [weak controller] style in
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
                gap: TypeCustomMenuSpec.footerGap,
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
                .offset(x: frame.minX, y: frame.maxY + TypeCustomMenuSpec.footerGap)
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
            .environment(\.typeCustomMenuIsMeasuring, true)
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
                    withAnimation(TypeCustomMenuSpec.reflowResize) {
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
                            withAnimation(TypeCustomMenuSpec.bloomOpen) {
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
            // No GlassEffectContainer: with a single glass shape it isn't needed,
            // and the container ignores per-view .opacity (so the glass couldn't
            // fade). Standalone .glassEffect honours it, which is what lets the
            // glass melt out on close.
            // Positioned with layout padding (inside the modifier), never .offset.
            ZStack(alignment: .topLeading) {
                chromeCore(content: content, metrics: metrics)
                    .modifier(MenuLensMorph(
                        progress: morphProgress,
                        collapsed: collapsedRect,
                        expanded: menuRect,
                        platterCorners: controller.cornerRadii
                            ?? RectangleCornerRadii(uniform: controller.cornerRadius ?? TypeCustomMenuSpec.platterCornerRadius),
                        fromTrailingPoint: controller.morphsFromTrailingPoint,
                        isClosing: controller.phase == .dismissing,
                        // The selected value, revealed on top of the glass over the
                        // final circle → label expand of the close.
                        label: controller.labelView?()
                    ))
                    .opacity(lensOpacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    // MARK: Pre-26 — classic scale/fade

    @ViewBuilder
    private func legacyPresentation(content: AnyView, metrics: Metrics) -> some View {
        let visible = appeared && controller.phase == .shown
        let placement = metrics.placement(for: menuSize ?? .zero)
        let platterShape = UnevenRoundedRectangle(
            cornerRadii: controller.cornerRadii
                ?? RectangleCornerRadii(uniform: controller.cornerRadius ?? TypeCustomMenuSpec.legacyCornerRadius),
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
            .scaleEffect(visible ? 1 : TypeCustomMenuSpec.collapsedScale, anchor: placement.anchor)
            .animation(visible ? TypeCustomMenuSpec.openScale : TypeCustomMenuSpec.closeScale, value: visible)
            .opacity(visible ? 1 : 0)
            .animation(visible ? TypeCustomMenuSpec.openFade : TypeCustomMenuSpec.closeFade, value: visible)
            .opacity(menuSize == nil ? 0 : 1)
            .offset(x: placement.origin.x, y: placement.origin.y)
    }

    // MARK: Shared chrome layout (sizing, scroll cap, environment plumbing)

    @ViewBuilder
    private func chromeCore(content: AnyView, metrics: Metrics) -> some View {
        let inner = content
            .environment(controller)
            .environment(\.typeCustomMenuDismiss, TypeCustomMenuDismissAction { [weak controller] style in
                controller?.dismiss(style: style)
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

    /// The open/close morph. On OPEN the glass platter grows directly out of its start
    /// shape (the whole button, or a trailing-edge circle when `fromTrailingPoint`)
    /// straight into the menu's rounded-rect platter, monotonically — no intermediate
    /// circle — while the menu content de-blurs and materializes. The CLOSE is NOT the
    /// reverse: the platter shrinks down toward the label but, instead of landing on its
    /// rect, passes through a glass circle at the label's centre, then relaxes that
    /// circle back onto the label while the value materializes and the glass melts off.
    /// That final half (circle → label) is byte-for-byte TimeCustomMenu's end-of-close.
    /// The captured `label` rides on top, materializing as the glass dissolves; the real
    /// label is hidden underneath until the last of the glass melts. Animatable progress
    /// drives layout, so SwiftUI interpolates every frame through this modifier.
    @available(iOS 26.0, *)
    private struct MenuLensMorph: ViewModifier, Animatable {
        var progress: CGFloat
        /// The label's live frame (the whole button); the morph grows from it on open
        /// and the close reveal lands its centre circle / value back onto it.
        let collapsed: CGRect
        let expanded: CGRect
        /// The platter's resting per-corner radii (caller-supplied or spec default).
        let platterCorners: RectangleCornerRadii
        /// When true, the OPEN morph starts as a small circle at the label's trailing
        /// edge instead of the whole `collapsed` frame. The close reveal ignores it —
        /// it always passes through a circle centred on the label.
        let fromTrailingPoint: Bool
        /// Drives the close path (circle → label reveal) instead of the open growth.
        let isClosing: Bool
        /// The selected value, revealed on top of the glass over the final circle → label
        /// expand of the close. Hidden during the shrink and on open.
        let label: AnyView?

        var animatableData: CGFloat {
            get { progress }
            set { progress = newValue }
        }

        private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
            a + (b - a) * t
        }

        private func rectLerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
            CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
                   width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
        }

        private func cornerLerp(_ a: RectangleCornerRadii, _ b: RectangleCornerRadii,
                                _ t: CGFloat, in rect: CGRect) -> RectangleCornerRadii {
            let cap = min(rect.width, rect.height) / 2
            return RectangleCornerRadii(
                topLeading: min(cap, lerp(a.topLeading, b.topLeading, t)),
                bottomLeading: min(cap, lerp(a.bottomLeading, b.bottomLeading, t)),
                bottomTrailing: min(cap, lerp(a.bottomTrailing, b.bottomTrailing, t)),
                topTrailing: min(cap, lerp(a.topTrailing, b.topTrailing, t))
            )
        }

        /// The small circle the label squeezes into at the close's `revealStart`,
        /// centred on the label. `dropletScale × label height`, exactly as the time menu.
        private var dropletCircle: CGRect {
            let d = collapsed.height * TypeCustomMenuSpec.dropletScale
            return CGRect(x: collapsed.midX - d / 2, y: collapsed.midY - d / 2, width: d, height: d)
        }

        /// OPEN: a single monotonic growth from the start shape straight to the menu
        /// platter. `p` 0 → 1 grows / translates the shape from start to platter. The
        /// start shape is the whole button by default, or a trailing-edge circle when
        /// `fromTrailingPoint` is set.
        private func openFrame(_ p: CGFloat) -> (rect: CGRect, corners: RectangleCornerRadii) {
            let t = p.clamped(to: 0...1)

            let startRect: CGRect
            let startCorner: CGFloat
            if fromTrailingPoint {
                let d = TypeCustomMenuSpec.expansionOriginDiameter
                startRect = CGRect(x: collapsed.maxX - d, y: collapsed.midY - d / 2, width: d, height: d)
                startCorner = d / 2                                      // a full circle
            } else {
                startRect = collapsed
                startCorner = min(collapsed.width, collapsed.height) / 2 // the button's capsule
            }

            let rect = rectLerp(startRect, expanded, t)
            let corners = cornerLerp(RectangleCornerRadii(uniform: startCorner), platterCorners, t, in: rect)
            return (rect, corners)
        }

        /// CLOSE: `p` 1 → 0 runs the platter down to a glass circle at the label's
        /// centre, then relaxes that circle back into the label.
        ///   p revealStart → 1 : platter shrinks straight into the centre circle (this
        ///                       half is TypeCustomMenu's own shrink — no travel phase)
        ///   p 0 → revealStart : circle → label (this half is identical to the time
        ///                       menu's final expand; see below)
        private func closeFrame(_ p: CGFloat) -> (rect: CGRect, corners: RectangleCornerRadii) {
            let revealStart = TypeCustomMenuSpec.closeRevealStart
            let circle = dropletCircle

            if p >= revealStart {
                // Shrink the platter straight down into the centre circle.
                let t = (p - revealStart) / max(1 - revealStart, 0.0001)
                let rect = rectLerp(circle, expanded, t)
                let corners = cornerLerp(RectangleCornerRadii(uniform: circle.height / 2),
                                         platterCorners, t, in: rect)
                return (rect, corners)
            } else {
                // Final expand — byte-for-byte the time menu's `p < 0.35` button→droplet
                // branch (run in reverse): the circle relaxes back onto the label rect,
                // holding the label's centre, with the label's own capsule radius landing.
                let t = p / max(revealStart, 0.0001)
                let small = circle.width
                let w = lerp(collapsed.width, small, t)
                let h = lerp(collapsed.height, small, t)
                let labelRadius = min(collapsed.width, collapsed.height) / 2
                let radius = min(min(w, h) / 2, lerp(labelRadius, small / 2, t))
                let rect = CGRect(x: collapsed.midX - w / 2, y: collapsed.midY - h / 2, width: w, height: h)
                return (rect, RectangleCornerRadii(uniform: radius))
            }
        }

        private func lensFrame(_ p: CGFloat) -> (rect: CGRect, corners: RectangleCornerRadii) {
            isClosing ? closeFrame(p) : openFrame(p)
        }

        func body(content: Content) -> some View {
            let p = progress
            let lens = lensFrame(p)
            let w = lens.rect.width
            let h = lens.rect.height
            // The captured value shrinks with the circle so it stays inside it.
            let labelScale = min(2, min(w / max(collapsed.width, 1),
                                        h / max(collapsed.height, 1)))
            // On close, melt the glass off across the final expand (p → 0) so the value
            // — layered on top — is what finishes landing on the label, with no glass
            // left to fade out in a separate beat. Identical to TimeCustomMenu.
            let glassOpacity: Double = isClosing
                ? Double((p / TypeCustomMenuSpec.closeGlassFadeProgress).clamped(to: 0...1))
                : 1

            ZStack(alignment: .topLeading) {
                // Glass platter + menu content, scaled from the start shape up to the
                // full platter. The content de-blurs and fades in over the back half of
                // the growth (and fades back out into the circle on close). The glass
                // rides this layer so it can fade out independently of the value on close.
                content
                    .frame(width: expanded.width, height: expanded.height, alignment: .topLeading)
                    .scaleEffect(x: w / max(expanded.width, 1),
                                 y: h / max(expanded.height, 1),
                                 anchor: .topLeading)
                    .blur(radius: (1 - p).clamped(to: 0...1) * TypeCustomMenuSpec.lensBlur)
                    .opacity(Double(((p - 0.55) / 0.45).clamped(to: 0...1)))
                    .frame(width: w, height: h, alignment: .topLeading)
                    .glassEffect(.regular, in: UnevenRoundedRectangle(cornerRadii: lens.corners, style: .continuous))
                    // Native platters cast a wide soft shadow; it grows with the bloom
                    // so the small origin circle casts almost none.
                    .shadow(color: .black.opacity(TypeCustomMenuSpec.platterShadowOpacity * p.clamped(to: 0...1)),
                            radius: TypeCustomMenuSpec.platterShadowRadius * p.clamped(to: 0...1),
                            y: TypeCustomMenuSpec.platterShadowY * p.clamped(to: 0...1))
                    .opacity(glassOpacity)

                // Close only: the selected value, layered ON TOP of the glass so it
                // outlives the glass fade and is what lands on the label as the circle
                // relaxes back. Materialize/blur are byte-for-byte the time menu's.
                if isClosing, let label {
                    label
                        .fixedSize()
                        .scaleEffect(labelScale)
                        .frame(width: w, height: h)
                        .blur(radius: p.clamped(to: 0...1) * TypeCustomMenuSpec.lensBlur)
                        .opacity(Double((1 - p * 2.2).clamped(to: 0...1)))
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
        let alignment: TypeCustomMenuAlignment
        /// Nudge applied to the final placement (positive = right / down).
        let placementOffset: CGSize
        let spaceBelow: CGFloat
        let spaceAbove: CGFloat

        var maxHeight: CGFloat { max(spaceBelow, spaceAbove) }
        var maxWidth: CGFloat { available.width }

        init(geo: GeometryProxy, anchor: CGRect, overlapsAnchor: Bool,
             alignment: TypeCustomMenuAlignment, placementOffset: CGSize) {
            let safe = geo.safeAreaInsets
            let margin = TypeCustomMenuSpec.screenMargin
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
                spaceBelow = available.maxY - (anchor.maxY + TypeCustomMenuSpec.anchorGap)
                spaceAbove = (anchor.minY - TypeCustomMenuSpec.anchorGap) - available.minY
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
                y = below ? anchor.maxY + TypeCustomMenuSpec.anchorGap
                          : anchor.minY - TypeCustomMenuSpec.anchorGap - size.height
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
