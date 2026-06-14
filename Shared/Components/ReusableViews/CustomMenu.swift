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
//      .customMenuKeepsPresented()    — opt a control (Toggle, Stepper…) out of the
//                                       tap-anywhere auto-dismiss.
//      @Environment(\.customMenuDismiss) — programmatic dismissal from content.
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
                .customMenuKeepsPresented()
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
                    ForEach([Color.appGreen, .appRed, .warningYellow, .appColorTint,
                             .secondary, .grayText, .appBackground, .dangerRed], id: \.self) { color in
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
        .foregroundStyle(role == .destructive ? Color.appRed : .primary)
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
    /// After the close morph lands on the button, the lens halo melts off the
    /// restored label rather than popping out in one frame.
    static let lensFadeOut = Animation.easeOut(duration: 0.15)
    /// Close morph length before the label is restored and the halo melts.
    static let closeMorphDuration: TimeInterval = 0.4
    static let lensFadeDuration: TimeInterval = 0.18
    /// Platter shadow at full bloom (native casts a wide soft shadow).
    static let platterShadowOpacity: CGFloat = 0.1
    static let platterShadowRadius: CGFloat = 24
    static let platterShadowY: CGFloat = 10

    static var platterShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: platterCornerRadius, style: .continuous)
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
    static let legacyCornerRadius: CGFloat = 13

    static var legacyShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: legacyCornerRadius, style: .continuous)
    }

    // ── Shared metrics ──
    /// Standard native menu width; opt in with .frame(width:) on your content.
    static let standardWidth: CGFloat = 250
    /// Gap between the label and the menu edge.
    static let anchorGap: CGFloat = 6
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

struct CustomMenu<Content: View, Label: View>: View {

    @ViewBuilder var content: () -> Content
    @ViewBuilder var label: () -> Label
    /// Corner radius of the label's own shape so the closing lens lands on it
    /// exactly (defaults to a capsule). Mismatched corners read as a snap.
    var labelCornerRadius: CGFloat?

    @State private var controller = CustomMenuController()
    @State private var labelFrame: CGRect = .zero
    @GestureState private var isPressed = false

    init(labelCornerRadius: CGFloat? = nil,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder label: @escaping () -> Label) {
        self.labelCornerRadius = labelCornerRadius
        self.content = content
        self.label = label
    }

    var body: some View {
        label()
            .contentShape(Rectangle())
            // iOS 26: the overlay's lens swallows the label, so the real one
            // hides while the menu is up (it is the menu now), like native.
            .opacity(controller.hidesLabel ? 0 : (isPressed ? CustomMenuSpec.pressedLabelOpacity : 1))
            .animation(.easeOut(duration: 0.1), value: isPressed)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                labelFrame = frame
            }
            .gesture(pressAndDrag)
            .onDisappear { controller.dismiss(animated: false) }
    }

    /// Native menus open on touch-down and support press-drag-release selection,
    /// so a single zero-distance drag drives the whole interaction.
    private var pressAndDrag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($isPressed) { _, state, _ in state = true }
            .onChanged { value in
                if !controller.isPresented {
                    controller.present(
                        anchor: labelFrame,
                        label: { AnyView(label()) },
                        labelCornerRadius: labelCornerRadius,
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

    /// Taps on this view no longer auto-dismiss the menu (for toggles, steppers…).
    func customMenuKeepsPresented() -> some View {
        modifier(CustomMenuKeepsPresentedModifier())
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

private struct CustomMenuKeepsPresentedModifier: ViewModifier {
    @Environment(CustomMenuController.self) private var controller: CustomMenuController?

    func body(content: Content) -> some View {
        content.simultaneousGesture(TapGesture().onEnded {
            controller?.suppressNextAutoDismiss()
        })
    }
}

// MARK: - Controller (window lifecycle + drag-select state)

@MainActor @Observable
final class CustomMenuController {

    enum Phase { case measuring, shown, dismissing }

    private(set) var phase: Phase = .measuring
    private(set) var anchor: CGRect = .zero
    private(set) var content: (() -> AnyView)?
    private(set) var labelView: (() -> AnyView)?
    private(set) var labelCornerRadius: CGFloat?
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
    @ObservationIgnored private var suppressAutoDismiss = false
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
                 content: @escaping () -> AnyView) {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive })
        else { return }

        self.anchor = anchor
        self.labelView = label
        self.labelCornerRadius = labelCornerRadius
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

    /// Called by the overlay the moment its lens (pixel-identical to the
    /// label at progress 0) is on screen, so there is overlap, never a gap.
    func hideSourceLabel() {
        hidesLabel = true
    }

    func dismiss(animated: Bool = true) {
        guard window != nil, phase != .dismissing else { return }
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
        content = nil
        labelView = nil
        labelCornerRadius = nil
        items = [:]
        highlightedItemID = nil
        menuFrame = .zero
        suppressAutoDismiss = false
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

    // MARK: Tap-anywhere auto-dismiss

    /// Runs as a simultaneous gesture on the whole menu. Deferred one runloop turn
    /// so a `.customMenuKeepsPresented()` child seen in the same tap can veto it.
    func insideTapped() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.phase == .shown else { return }
            if self.suppressAutoDismiss {
                self.suppressAutoDismiss = false
            } else {
                self.dismiss()
            }
        }
    }

    func suppressNextAutoDismiss() {
        suppressAutoDismiss = true
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
            let metrics = Metrics(geo: geo, anchor: controller.anchor, overlapsAnchor: overlapsAnchor)
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
                menuSize = size
                controller.menuFrame = CGRect(origin: metrics.placement(for: size).origin, size: size)
                // Wait for the scroll-capped pass before blooming oversized menus.
                if !appeared, size.height <= metrics.maxHeight + 1 {
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

        if let size = menuSize {
            let menuRect = CGRect(origin: metrics.placement(for: size).origin, size: size)
            GlassEffectContainer(spacing: CustomMenuSpec.morphSpacing) {
                // Placed with layout (padding inside the modifier), not .offset:
                // glass geometry inside the container follows layout positions.
                ZStack(alignment: .topLeading) {
                    chromeCore(content: content, metrics: metrics)
                        .modifier(MenuLensMorph(
                            progress: morphProgress,
                            collapsed: controller.anchor,
                            collapsedRadius: controller.labelCornerRadius ?? controller.anchor.height / 2,
                            expanded: menuRect,
                            label: controller.labelView?()
                        ))
                        .opacity(lensOpacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    // MARK: Pre-26 — classic scale/fade

    @ViewBuilder
    private func legacyPresentation(content: AnyView, metrics: Metrics) -> some View {
        let visible = appeared && controller.phase == .shown
        let placement = metrics.placement(for: menuSize ?? .zero)

        chromeCore(content: content, metrics: metrics)
            .background {
                CustomMenuSpec.legacyShape
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 32, y: 16)
                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
            }
            .clipShape(CustomMenuSpec.legacyShape)
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
            .simultaneousGesture(TapGesture().onEnded { controller.insideTapped() })

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
        let label: AnyView?

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
                             lerp(big / 2, CustomMenuSpec.platterCornerRadius, t))
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

            ZStack(alignment: .topLeading) {
                // Menu content squeezes into the current lens bounds, sharpening
                // from a refracted blur as the platter forms (reverse on close).
                content
                    .frame(width: expanded.width, height: expanded.height, alignment: .topLeading)
                    .scaleEffect(x: w / max(expanded.width, 1),
                                 y: h / max(expanded.height, 1),
                                 anchor: .topLeading)
                    .blur(radius: (1 - p).clamped(to: 0...1) * CustomMenuSpec.lensBlur)
                    .opacity(Double(((p - 0.55) / 0.45).clamped(to: 0...1)))

                // The swallowed label: refracts and dissolves inside the droplet,
                // re-materializes as the lens shrinks back onto the button.
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
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: lens.radius, style: .continuous))
            // Native platters cast a wide soft shadow; it grows with the bloom
            // so the resting button state casts none.
            .shadow(color: .black.opacity(CustomMenuSpec.platterShadowOpacity * p.clamped(to: 0...1)),
                    radius: CustomMenuSpec.platterShadowRadius * p.clamped(to: 0...1),
                    y: CustomMenuSpec.platterShadowY * p.clamped(to: 0...1))
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
        let spaceBelow: CGFloat
        let spaceAbove: CGFloat

        var maxHeight: CGFloat { max(spaceBelow, spaceAbove) }
        var maxWidth: CGFloat { available.width }

        init(geo: GeometryProxy, anchor: CGRect, overlapsAnchor: Bool) {
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
            if overlapsAnchor {
                spaceBelow = available.maxY - anchor.minY
                spaceAbove = anchor.maxY - available.minY
            } else {
                spaceBelow = available.maxY - (anchor.maxY + CustomMenuSpec.anchorGap)
                spaceAbove = (anchor.minY - CustomMenuSpec.anchorGap) - available.minY
            }
        }

        /// Below the label when it fits, else above, else whichever side is
        /// larger. iOS 26: top (or bottom) edge flush with the label's and
        /// horizontally centred on it; classic: 6pt gap, edge-aligned. The
        /// unit anchor is the point on the menu nearest the label (legacy
        /// scale transform origin).
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
            y = y.clamped(to: available.minY...max(available.minY, available.maxY - size.height))

            var x = overlapsAnchor
                ? anchor.midX - size.width / 2
                : (anchor.midX <= bounds.width / 2 ? anchor.minX : anchor.maxX - size.width)
            x = x.clamped(to: available.minX...max(available.minX, available.maxX - size.width))

            let unitX = ((anchor.midX - x) / max(size.width, 1)).clamped(to: 0...1)
            return (CGPoint(x: x, y: y), UnitPoint(x: unitX, y: below ? 0 : 1))
        }
    }
}
