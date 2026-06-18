//AI Code Beware!
//  SelectTypeTest.swift
//  Scoop Test
//
//  Created by Art Ostin on 11/06/2026.
//
//  CustomMenu — a reusable recreation of the native menu presentation that
//  accepts fully arbitrary content. On iOS 26+ it reproduces the Liquid Glass
//  menu: a glass bubble that morphs ("blooms") out of the label, and morphs
//  back into it on dismissal. Pre-26 it falls back to the classic scale/fade.
//
//  Usage:
//      CustomMenu {
//          // any SwiftUI view / layout
//      } label: {
//          // the trigger view
//      }
//
//      Pass labelCornerRadius if the label is not a capsule, so the closing
//      lens lands exactly on its shape:
//      CustomMenu(labelCornerRadius: 25) { ... } label: { ... }
//
//  Inside the content closure:
//      .customMenuItem { ... }        — row participates in drag-to-select highlight,
//                                       runs its action and dismisses on selection.
//      @Environment(\.customMenuDismiss) — programmatic dismissal from content. A tap
//                                       on the menu's own content never auto-dismisses;
//                                       call this action (or use .customMenuItem) to
//                                       close it. Tapping outside still dismisses.
//
//  ── iOS 26 lens-morph mechanics (replicated from device recordings) ─────────
//  Native iOS 26 menus do a "lens morph" that passes THROUGH A CIRCLE: on open
//  the button squeezes into a small droplet circle at its own centre (label
//  refracting inside), the circle inflates while travelling toward the menu's
//  centre, then relaxes into the rounded-rect platter — which COVERS the
//  button's rect (near edges flush, no gap) and is centred on it — while the
//  menu content de-blurs and materializes. Dismissal is the exact reverse;
//  the button re-materializes inside the shrinking droplet.
//  Implementation: ONE persistent glass view whose keyframed frame/radius/
//  content are interpolated by an Animatable modifier (MenuLensMorph) under
//  withAnimation. The real label hides while the lens covers it (it IS the
//  menu, like native).
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
//  and shadow values are not public; `CustomMenuSpec` holds tuned approximations
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
//   • Touch-down opening means a label inside a ScrollView will claim drags that
//     start on it; UIKit avoids this with delaysContentTouches, which has no
//     public SwiftUI equivalent.
//

import SwiftUI
import UIKit

// MARK: - Demo / harness

struct CustomMenuBuilder: View {

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
        CustomMenu {
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
            .frame(width: CustomMenuSpec.standardWidth)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 24))
                .foregroundStyle(Color.appGreen)
                .padding(8)
        }
    }

    /// Arbitrary layout: a reaction bar over a colour grid — impossible in a native Menu.
    private var freeformMenu: some View {
        CustomMenu {
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    ForEach(["🍦", "🍨", "🍧", "🍫", "🍓"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 28))
                            .customMenuItem { flavour = emoji }
                    }
                }
                Divider()
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(44)), count: 4), spacing: 10) {
                    ForEach([Color.appGreen, .accent, .warningYellow,
                             .grayPlaceholder, .grayText, .appCanvas, .dangerRed], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 38, height: 38)
                            .customMenuItem { }
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
        .customMenuItem(action: action)
    }
}

#Preview {
    CustomMenuBuilder()
}

// MARK: - Spec (approximations of the private native values)

enum CustomMenuSpec {

    // ── iOS 26 Liquid Glass lens morph ──
    /// Platter corner radius — fixed stand-in for the system's concentric radius.
    static let platterCornerRadius: CGFloat = 26
    /// Glass shapes closer than this blend/morph inside the container.
    static let morphSpacing: CGFloat = 40
    /// Peak refraction blur while content is being swallowed/materialized
    /// (matched against device recordings of the native lens).
    static let lensBlur: CGFloat = 8
    /// Droplet circle diameter as a multiple of the label height (the small
    /// circle the button squeezes into — ~64pt for a 44pt button on device).
    static let dropletScale: CGFloat = 1.45
    /// Inflated circle diameter relative to the menu's smaller dimension
    /// (~180pt for a 240×140 menu in the device recording).
    static let lensCircleScale: CGFloat = 1.25
    /// How far toward the menu's centre the inflated circle has travelled.
    static let lensTravelBias: CGFloat = 0.75
    /// Lens morph timing against the native open (~0.45s, slight settle).
    static let bloomOpen = Animation.spring(response: 0.45, dampingFraction: 0.82)
    /// Shrinking back through the circles never bounces (~0.4s on device).
    static let bloomClose = Animation.smooth(duration: 0.38)
    /// After the menu is open, content can reflow (e.g. an info row expands) and
    /// change the platter's height. Grow it with this curve — matched to the
    /// content's own expand animation — so the glass tracks the content instead
    /// of snapping. Only applies post-open; the initial sizing stays unanimated.
    static let reflowResize = Animation.smooth(duration: 0.3)
    /// After the close morph lands on the button, the lens halo melts off the
    /// restored label rather than popping out in one frame.
    static let lensFadeOut = Animation.easeOut(duration: 0.15)
    /// Close morph length before the label is restored and the halo melts.
    static let closeMorphDuration: TimeInterval = 0.4
    static let lensFadeDuration: TimeInterval = 0.18
    /// On close, the glass is fully present at this progress and melts linearly to
    /// nothing by progress 0 — i.e. it fades across the final expand (the circle
    /// relaxing back into the label), so the label alone lands and there's no
    /// glass left to pop. 0.35 lines the fade up with the start of the expand;
    /// smaller concentrates it later / quicker near the very end.
    static let closeGlassFadeProgress: CGFloat = 0.35
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
    /// Fine-tuning nudge applied to the final placement: shifts the platter
    /// right and down from its anchor-aligned position.
    static let placementOffsetX: CGFloat = 12
    static let placementOffsetY: CGFloat = 24
    /// Minimum distance kept from safe-area edges.
    static let screenMargin: CGFloat = 9
    /// Drags shorter than this count as a tap on the label (menu stays open).
    static let tapSlop: CGFloat = 10

    static let highlightFill = Color(.tertiarySystemFill)
    /// iOS 26 rows highlight with a rounded, inset shape rather than full-bleed.
    static let highlightCornerRadius: CGFloat = 14
    static let pressedLabelOpacity: CGFloat = 0.5
}

// MARK: - CustomMenu

/// Which edge of the label the menu aligns its corresponding edge to.
/// `.automatic` picks the edge by whichever screen half the label's centre sits
/// in (the native default) — use `.leading` / `.trailing` when the label is wide
/// enough that its centre is ambiguous (e.g. a full-width row with a Spacer).
enum CustomMenuAlignment {
    case leading, trailing, automatic
}

struct CustomMenu<Content: View, Label: View>: View {

    @ViewBuilder var content: () -> Content
    @ViewBuilder var label: () -> Label
    /// Corner radius of the label's own shape so the closing lens lands on it
    /// exactly (defaults to a capsule). Mismatched corners read as a snap.
    var labelCornerRadius: CGFloat?
    /// Corner radius of the menu platter itself. `nil` uses the spec defaults
    /// (26pt on iOS 26's glass, 13pt on the pre-26 platter); pass a value to
    /// override from the call site without touching `CustomMenu`.
    var cornerRadius: CGFloat?
    /// Which label edge the menu aligns to (see `CustomMenuAlignment`).
    var alignment: CustomMenuAlignment
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

    @State private var controller = CustomMenuController()
    @State private var labelFrame: CGRect = .zero
    @GestureState private var isPressed = false

    init(labelCornerRadius: CGFloat? = nil,
         cornerRadius: CGFloat? = nil,
         alignment: CustomMenuAlignment = .automatic,
         placementOffsetX: CGFloat = CustomMenuSpec.placementOffsetX,
         placementOffsetY: CGFloat = CustomMenuSpec.placementOffsetY,
         onOpen: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder label: @escaping () -> Label) {
        self.labelCornerRadius = labelCornerRadius
        self.cornerRadius = cornerRadius
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
        return label()
            .contentShape(Rectangle())
            // iOS 26: the overlay's lens swallows the label, so the real one
            // hides while the menu is up (it is the menu now), like native.
            .opacity(controller.hidesLabel ? 0 : (isPressed ? CustomMenuSpec.pressedLabelOpacity : 1))
            .animation(.easeOut(duration: 0.1), value: isPressed)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                labelFrame = frame
                // Keep the close target on the label's current frame (it reflows
                // when a selection changes its text) so the lens lands cleanly.
                controller.updateCollapseAnchor(frame)
            }
            .gesture(pressAndDrag)
            .onDisappear { controller.dismiss(animated: false) }
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

    /// Native menus open on touch-down and support press-drag-release selection,
    /// so a single zero-distance drag drives the whole interaction.
    private var pressAndDrag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($isPressed) { _, state, _ in state = true }
            .onChanged { value in
                if !controller.isPresented {
                    onOpen?()
                    controller.present(
                        anchor: labelFrame,
                        label: { AnyView(label()) },
                        labelCornerRadius: labelCornerRadius,
                        cornerRadius: cornerRadius,
                        alignment: alignment,
                        placementOffset: placementOffset,
                        onClose: onClose,
                        content: { AnyView(content()) }
                    )
                }
                controller.dragMoved(to: value.location)
            }
            .onEnded { value in
                controller.dragEnded(at: value.location, translation: value.translation)
            }
    }
}

// MARK: - Dismiss action environment

struct CustomMenuDismissAction {
    var action: () -> Void = {}
    func callAsFunction() { action() }
}

extension EnvironmentValues {
    @Entry var customMenuDismiss = CustomMenuDismissAction()
    /// True inside the hidden copy used only for sizing — items must not register.
    @Entry var customMenuIsMeasuring = false
}

// MARK: - Content modifiers

extension View {
    /// Marks a view as a selectable menu row: it highlights while a drag hovers it,
    /// fires `action` on tap or drag-release, and dismisses the menu.
    func customMenuItem(action: @escaping () -> Void) -> some View {
        modifier(CustomMenuItemModifier(action: action))
    }
}

private struct CustomMenuItemModifier: ViewModifier {
    @Environment(CustomMenuController.self) private var controller: CustomMenuController?
    @Environment(\.customMenuIsMeasuring) private var isMeasuring
    let action: () -> Void
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .background {
                if controller?.highlightedItemID == id {
                    if #available(iOS 26.0, *) {
                        RoundedRectangle(cornerRadius: CustomMenuSpec.highlightCornerRadius, style: .continuous)
                            .fill(CustomMenuSpec.highlightFill)
                            .padding(3)
                    } else {
                        CustomMenuSpec.highlightFill
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
final class CustomMenuController {

    enum Phase { case measuring, shown, dismissing }

    private(set) var phase: Phase = .measuring
    private(set) var anchor: CGRect = .zero
    /// The label's *live* frame, tracked while presented so the close morph
    /// collapses onto where the label is now (it may have reflowed after a
    /// selection), not the frame captured at open time. Placement keeps using the
    /// fixed `anchor` so the open menu never moves underfoot.
    private(set) var collapseAnchor: CGRect = .zero
    private(set) var content: (() -> AnyView)?
    private(set) var labelView: (() -> AnyView)?
    private(set) var labelCornerRadius: CGFloat?
    /// Caller-supplied platter corner radius; `nil` falls back to the spec value.
    private(set) var cornerRadius: CGFloat?
    private(set) var alignment: CustomMenuAlignment = .automatic
    private(set) var placementOffset: CGSize = .zero
    /// iOS 26: the real label hides while the overlay's lens carries its copy.
    private(set) var hidesLabel = false
    /// iOS 26: signals the overlay to melt the lens halo off the restored label.
    private(set) var lensDissolve = false
    private(set) var highlightedItemID: UUID?
    /// Laid-out menu frame in screen coordinates, set by the overlay.
    var menuFrame: CGRect = .zero

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
                 labelCornerRadius: CGFloat?,
                 cornerRadius: CGFloat? = nil,
                 alignment: CustomMenuAlignment,
                 placementOffset: CGSize,
                 onClose: (() -> Void)? = nil,
                 content: @escaping () -> AnyView) {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive })
        else { return }

        self.anchor = anchor
        self.collapseAnchor = anchor
        self.labelView = label
        self.labelCornerRadius = labelCornerRadius
        self.cornerRadius = cornerRadius
        self.alignment = alignment
        self.placementOffset = placementOffset
        self.onClose = onClose
        self.content = content
        phase = .measuring

        let host = UIHostingController(rootView: CustomMenuOverlayRoot(controller: self))
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
                try? await Task.sleep(for: .seconds(CustomMenuSpec.closeMorphDuration))
                guard generation == gen else { return }
                hidesLabel = false
                lensDissolve = true
                try? await Task.sleep(for: .seconds(CustomMenuSpec.lensFadeDuration))
                if generation == gen { tearDown() }
            }
        } else {
            Task {
                try? await Task.sleep(for: .seconds(CustomMenuSpec.teardownDelay))
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
        cornerRadius = nil
        alignment = .automatic
        placementOffset = .zero
        collapseAnchor = .zero
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
        } else if distance >= CustomMenuSpec.tapSlop,
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

private struct CustomMenuOverlayRoot: View {

    let controller: CustomMenuController

    @State private var menuSize: CGSize?
    @State private var contentIdealHeight: CGFloat?
    @State private var appeared = false
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
                    withAnimation(CustomMenuSpec.bloomClose) {
                        morphProgress = 0
                    }
                }
            }
            .onChange(of: controller.lensDissolve) { _, dissolve in
                guard dissolve else { return }
                if #available(iOS 26.0, *) {
                    withAnimation(CustomMenuSpec.lensFadeOut) {
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
        // Hidden sizing copy: always laid out so the platter's final rect is
        // known before the morph starts.
        chromeCore(content: content, metrics: metrics)
            .environment(\.customMenuIsMeasuring, true)
            .opacity(0)
            .allowsHitTesting(false)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                controller.menuFrame = CGRect(origin: metrics.placement(for: size).origin, size: size)
                if appeared {
                    // Post-open reflow (e.g. an info row expanded): animate the
                    // platter's height to track the content instead of snapping.
                    withAnimation(CustomMenuSpec.reflowResize) { menuSize = size }
                } else {
                    menuSize = size
                    // Wait for the scroll-capped pass before blooming oversized menus.
                    if size.height <= metrics.maxHeight + 1 {
                        appeared = true
                        controller.markShown()
                        // The lens is pixel-identical to the label at progress 0, so
                        // it takes over the button instantly (no fade-in — that adds
                        // perceptible lag between tap and motion) and the morph
                        // begins the same beat.
                        lensOpacity = 1
                        controller.hideSourceLabel()
                        // Escape the layout transaction so the morph animates from a
                        // committed frame instead of snapping on initial render.
                        DispatchQueue.main.async {
                            withAnimation(CustomMenuSpec.bloomOpen) {
                                morphProgress = 1
                            }
                        }
                    }
                }
            }

        if let size = menuSize {
            let menuRect = CGRect(origin: metrics.placement(for: size).origin, size: size)
            // Collapse onto the label's live frame, falling back to the open-time
            // anchor before the first geometry update lands.
            let collapsedRect = controller.collapseAnchor == .zero ? controller.anchor : controller.collapseAnchor
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
                        platterRadius: controller.cornerRadius ?? CustomMenuSpec.platterCornerRadius,
                        label: controller.labelView?(),
                        isClosing: controller.phase == .dismissing
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
        let platterShape = RoundedRectangle(
            cornerRadius: controller.cornerRadius ?? CustomMenuSpec.legacyCornerRadius,
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
            .scaleEffect(visible ? 1 : CustomMenuSpec.collapsedScale, anchor: placement.anchor)
            .animation(visible ? CustomMenuSpec.openScale : CustomMenuSpec.closeScale, value: visible)
            .opacity(visible ? 1 : 0)
            .animation(visible ? CustomMenuSpec.openFade : CustomMenuSpec.closeFade, value: visible)
            .opacity(menuSize == nil ? 0 : 1)
            .offset(x: placement.origin.x, y: placement.origin.y)
    }

    // MARK: Shared chrome layout (sizing, scroll cap, environment plumbing)

    @ViewBuilder
    private func chromeCore(content: AnyView, metrics: Metrics) -> some View {
        let inner = content
            .environment(controller)
            .environment(\.customMenuDismiss, CustomMenuDismissAction { [weak controller] in
                controller?.dismiss()
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

    /// The lens morph, keyframed from device recordings of the native menu.
    /// The glass lens travels through a CIRCLE phase rather than interpolating
    /// rect-to-rect:
    ///   p 0.00→0.35  the button squeezes into a small droplet circle at its
    ///                own centre, its label refracting inside;
    ///   p 0.35→0.70  the circle inflates while travelling most of the way
    ///                toward the menu's centre;
    ///   p 0.70→1.00  the circle relaxes into the rounded-rect platter while
    ///                the menu content materializes.
    /// Dismissal runs the same path in reverse (menu → circles → button).
    /// Animatable progress drives layout, so SwiftUI interpolates every spring
    /// frame through this modifier.
    @available(iOS 26.0, *)
    private struct MenuLensMorph: ViewModifier, Animatable {
        var progress: CGFloat
        let collapsed: CGRect
        /// The label's own corner radius, so the lens lands exactly on its shape.
        let collapsedRadius: CGFloat
        let expanded: CGRect
        /// The platter's resting corner radius (caller-supplied or spec default).
        let platterRadius: CGFloat
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

        /// Piecewise lens geometry across the keyframes above.
        private func lensFrame(_ p: CGFloat) -> (rect: CGRect, radius: CGFloat) {
            let small = collapsed.height * CustomMenuSpec.dropletScale
            let big = max(small * 1.5,
                          min(min(expanded.width, expanded.height) * CustomMenuSpec.lensCircleScale,
                              max(expanded.width, expanded.height) * 0.75))
            let start = CGPoint(x: collapsed.midX, y: collapsed.midY)
            let end = CGPoint(x: expanded.midX, y: expanded.midY)
            // The big circle has already travelled most of the way to the menu.
            let mid = CGPoint(x: lerp(start.x, end.x, CustomMenuSpec.lensTravelBias),
                              y: lerp(start.y, end.y, CustomMenuSpec.lensTravelBias))

            let w: CGFloat, h: CGFloat, cx: CGFloat, cy: CGFloat, radius: CGFloat
            if p < 0.35 {
                // Button → droplet circle, holding the button's centre. Radius
                // starts at the label's own corner radius so the closing lens
                // lands exactly on the button's shape, never a different one.
                let t = max(0, p / 0.35)
                w = lerp(collapsed.width, small, t)
                h = lerp(collapsed.height, small, t)
                cx = start.x
                cy = start.y
                radius = min(min(w, h) / 2, lerp(collapsedRadius, small / 2, t))
            } else if p < 0.7 {
                // Droplet inflates and travels toward the menu.
                let t = (p - 0.35) / 0.35
                w = lerp(small, big, t)
                h = w
                cx = lerp(start.x, mid.x, t)
                cy = lerp(start.y, mid.y, t)
                radius = w / 2
            } else {
                // Circle relaxes into the platter (spring overshoot extrapolates).
                let t = (p - 0.7) / 0.3
                w = lerp(big, expanded.width, t)
                h = lerp(big, expanded.height, t)
                cx = lerp(mid.x, end.x, t)
                cy = lerp(mid.y, end.y, t)
                radius = min(min(w, h) / 2,
                             lerp(big / 2, platterRadius, t))
            }
            return (CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h), radius)
        }

        func body(content: Content) -> some View {
            let p = progress
            let lens = lensFrame(p)
            let w = lens.rect.width
            let h = lens.rect.height
            // The swallowed label shrinks with the droplet so it stays inside.
            let labelScale = min(2, min(w / max(collapsed.width, 1),
                                        h / max(collapsed.height, 1)))
            // On close only, melt the glass off across the final expand (p → 0) so
            // the label — layered on top — is what finishes landing on the button,
            // with no glass left to fade out in a separate beat afterwards.
            let glassOpacity: Double = isClosing
                ? Double((p / CustomMenuSpec.closeGlassFadeProgress).clamped(to: 0...1))
                : 1

            ZStack(alignment: .topLeading) {
                // Glass platter + menu content. The glass rides this layer so it
                // can fade out independently of the label on close.
                content
                    .frame(width: expanded.width, height: expanded.height, alignment: .topLeading)
                    .scaleEffect(x: w / max(expanded.width, 1),
                                 y: h / max(expanded.height, 1),
                                 anchor: .topLeading)
                    .blur(radius: (1 - p).clamped(to: 0...1) * CustomMenuSpec.lensBlur)
                    .opacity(Double(((p - 0.55) / 0.45).clamped(to: 0...1)))
                    .frame(width: w, height: h, alignment: .topLeading)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: lens.radius, style: .continuous))
                    // Native platters cast a wide soft shadow; it grows with the
                    // bloom so the resting button state casts none.
                    .shadow(color: .black.opacity(CustomMenuSpec.platterShadowOpacity * p.clamped(to: 0...1)),
                            radius: CustomMenuSpec.platterShadowRadius * p.clamped(to: 0...1),
                            y: CustomMenuSpec.platterShadowY * p.clamped(to: 0...1))
                    .opacity(glassOpacity)

                // The swallowed label, layered ON TOP of the glass so on close it
                // outlives the glass fade and is what lands on the button.
                // fixedSize keeps its intrinsic layout (no reflow/truncation);
                // it shrinks purely visually with the droplet.
                if let label {
                    label
                        .fixedSize()
                        .scaleEffect(labelScale)
                        .frame(width: w, height: h)
                        .blur(radius: p.clamped(to: 0...1) * CustomMenuSpec.lensBlur)
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
        let alignment: CustomMenuAlignment
        /// Nudge applied to the final placement (positive = right / down).
        let placementOffset: CGSize
        let spaceBelow: CGFloat
        let spaceAbove: CGFloat

        var maxHeight: CGFloat { max(spaceBelow, spaceAbove) }
        var maxWidth: CGFloat { available.width }

        init(geo: GeometryProxy, anchor: CGRect, overlapsAnchor: Bool,
             alignment: CustomMenuAlignment, placementOffset: CGSize) {
            let safe = geo.safeAreaInsets
            let margin = CustomMenuSpec.screenMargin
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
                spaceBelow = available.maxY - (anchor.maxY + CustomMenuSpec.anchorGap)
                spaceAbove = (anchor.minY - CustomMenuSpec.anchorGap) - available.minY
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
                y = below ? anchor.maxY + CustomMenuSpec.anchorGap
                          : anchor.minY - CustomMenuSpec.anchorGap - size.height
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
