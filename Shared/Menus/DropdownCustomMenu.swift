//AI Code Beware!
//
//  DropdownCustomMenu.swift
//  Scoop
//
//  Created by Art Ostin on 11/06/2026.
//

import SwiftUI
import UIKit

private typealias Spec = DropdownCustomMenuSpec

// MARK: - DropdownCustomMenu

struct DropdownCustomMenu<Content: View, Label: View>: View {

    //Injected
    let cornerRadii: RectangleCornerRadii //the footer carries its own (AddMessageFooter)
    let placementOffset: CGSize //nudge on the final placement, positive = right / down
    let retractOnEmptyDismiss: Bool //tap-away retracts instead of morphing; false keeps every dismiss on the morph
    let onOpen: (() -> Void)? //fires the instant an open is requested, before the bloom
    let onClose: (() -> Void)? //fires the instant a dismiss is requested, any style, before the close
    let message: String //titles the Add-Message footer ("Add a Message" when empty)
    let showMessageScreen: Binding<Bool>? //supplying it shows the footer; nil = no footer
    let content: () -> Content
    let label: () -> Label

    //Local view state
    @Environment(\.scenePhase) private var scenePhase
    @State private var controller = DropdownCustomMenuController()
    @State private var labelFrame: CGRect = .zero
    @State private var pressed = false
    @State private var pressStart: Date?
    @State private var panCancelled = false //this touch became a pan: no open until the finger lifts

    init(cornerRadii: RectangleCornerRadii = DropdownCustomMenuSpec.platterCornerRadii,
         placementOffset: CGSize = DropdownCustomMenuSpec.placementOffset,
         retractOnEmptyDismiss: Bool = true,
         onOpen: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil,
         message: String = "",
         showMessageScreen: Binding<Bool>? = nil,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder label: @escaping () -> Label) {
        self.cornerRadii = cornerRadii
        self.placementOffset = placementOffset
        self.retractOnEmptyDismiss = retractOnEmptyDismiss
        self.onOpen = onOpen
        self.onClose = onClose
        self.message = message
        self.showMessageScreen = showMessageScreen
        self.content = content
        self.label = label
    }

    var body: some View {
        let _ = pushLiveLabel()
        let shrunk = pressed || controller.labelPressed //labelPressed: the re-tap, seen only by the overlay window
        label()
            .contentShape(Rectangle()) //hit area = morph rect: padding the label widens the bloom too
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                labelFrame = frame
                controller.updateLabelFrame(frame)
            }
            //Geometry read stays ABOVE the press scale, so the shrink never feeds the morph rect
            .scaleEffect(shrunk ? PressEffect.shrink.scale : 1)
            .opacity(controller.hidesLabel ? 0 : (shrunk ? PressEffect.shrink.opacity : 1))
            .animation(pressAnimation(shrunk: shrunk), value: shrunk)
            .simultaneousGesture(pressGesture)
            .onChange(of: scenePhase) { _, phase in //a cancelled touch never delivers onEnded
                guard phase != .active else { return }
                pressed = false
                panCancelled = false
            }
            .onDisappear { //the window must never outlive its host
                pressed = false
                panCancelled = false
                controller.dismiss(style: .instant)
            }
    }
}

//Press and open
extension DropdownCustomMenu {

    //Must stay a .simultaneousGesture min-0 drag (a Button shrinks only at release) in GLOBAL space (the card chases the finger)
    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                guard !controller.isPresented else { return }
                let moved = hypot(value.translation.width, value.translation.height)
                if moved >= Spec.tapSlop {
                    panCancelled = true //latched for the whole touch, even if it circles back under the slop
                    pressed = false
                } else if !panCancelled, !pressed {
                    pressed = true
                    pressStart = .now
                }
            }
            .onEnded { value in
                let wasPan = panCancelled
                panCancelled = false
                guard !controller.isPresented else { pressed = false; return }
                //Hold the shrink so a fast tap still reads; the open fires while the label is still pressed
                let hold = PressEffect.shrink.releaseHold
                let shown = pressStart.map { Date.now.timeIntervalSince($0) } ?? hold
                DispatchQueue.main.asyncAfter(deadline: .now() + max(0, hold - shown)) { pressed = false }
                let moved = hypot(value.translation.width, value.translation.height)
                guard !wasPan, moved < Spec.tapSlop else { return }
                openMenu()
            }
    }

    private func pressAnimation(shrunk: Bool) -> Animation {
        shrunk ? .snappy(duration: PressEffect.shrink.pressDuration)
               : .spring(response: PressEffect.shrink.release.response,
                         dampingFraction: PressEffect.shrink.release.damping)
    }

    private func openMenu() {
        guard !controller.isPresented else { return }
        onOpen?()
        controller.present(
            anchor: labelFrame,
            cornerRadii: cornerRadii,
            placementOffset: placementOffset,
            retractOnEmptyDismiss: retractOnEmptyDismiss,
            onClose: onClose,
            footer: addMessageFooter,
            label: { AnyView(label()) },
            content: { AnyView(content()) }
        )
    }

    //Re-pushes the label closure each body pass (closures aren't Equatable), so the dismiss copy shows the current value
    private func pushLiveLabel() {
        guard controller.isPresented else { return }
        let makeLabel = label
        DispatchQueue.main.async { controller.updateLabel { AnyView(makeLabel()) } }
    }

    private var addMessageFooter: (() -> AnyView)? {
        guard let showMessageScreen else { return nil }
        let message = self.message
        return { AnyView(AddMessageFooter(message: message) { showMessageScreen.wrappedValue = true }) }
    }
}

// MARK: - Dismiss styles & environment actions

//morph: pinch to a circle and reveal the new value; retract: the bloom reversed; instant: no animation
enum DropdownCustomMenuDismissStyle { case morph, retract, instant }

struct DropdownCustomMenuDismissAction {
    var action: (DropdownCustomMenuDismissStyle) -> Void = { _ in }
    func callAsFunction(_ style: DropdownCustomMenuDismissStyle = .morph) { action(style) }
}

//Snapshots the label's current value; call before mutating the selection so .morph collapses the OLD value
struct DropdownCustomMenuFreezeLabelAction {
    var action: () -> Void = {}
    func callAsFunction() { action() }
}

extension EnvironmentValues {
    @Entry var dropdownCustomMenuDismiss = DropdownCustomMenuDismissAction()
    @Entry var dropdownCustomMenuFreezeLabel = DropdownCustomMenuFreezeLabelAction()
}

// MARK: - Add-Message footer

struct AddMessageFooter: View {

    @Environment(\.dropdownCustomMenuDismiss) private var menuDismiss

    let message: String
    var corners: RectangleCornerRadii = DropdownCustomMenuSpec.footerCornerRadii
    let onSelect: () -> Void

    var body: some View {
        Text(message.isEmpty ? "Add a Message" : "Edit Message")
            .foregroundStyle(Color.textAccent)
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.body(16, .bold))
            .kerning(0.5)
            .frame(height: 40)
            .frame(width: SelectTypeView.cardWidth, alignment: .leading)
            .dropdownCustomMenuFooterPlatter(corners: corners)
            .contentShape(.rect)
            .shrinkPress {
                onSelect()
                Task { //let the sheet start presenting, then drop the window that sits above it
                    try? await Task.sleep(for: .seconds(0.04))
                    menuDismiss(.instant)
                }
            }
    }
}

private extension View {
    /// The footer's own material: glass on iOS 26, frosted material + shadow before.
    func dropdownCustomMenuFooterPlatter(corners: RectangleCornerRadii) -> some View {
        modifier(FooterPlatter(corners: corners))
    }
}

private struct FooterPlatter: ViewModifier {
    let corners: RectangleCornerRadii
    func body(content: Content) -> some View {
        let shape = UnevenRoundedRectangle(cornerRadii: corners)
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(shape.fill(.regularMaterial)).clipShape(shape).shadow(.floating)
        }
    }
}

// MARK: - Spec

/// Tuned as a set: the iOS 26 curves replicate the system menu and stay in-file (CLAUDE.md).
enum DropdownCustomMenuSpec {

    //Platter
    static let platterCornerRadii = RectangleCornerRadii(top: 20, bottom: 6) //the invite type card's split corners
    static let footerCornerRadii = RectangleCornerRadii(top: 6, bottom: 18) //the platter's shape continued past the gap
    static let footerGap: CGFloat = 6
    static let placementOffset = CGSize(width: 12, height: 24) //from the anchor-aligned position: right / down
    static let screenMargin: CGFloat = 9 //kept from the safe-area edges
    /// The native platter's shadow, scaled with the bloom so the button-sized start casts none.
    static let platterShadowOpacity: CGFloat = 0.1
    static let platterShadowRadius: CGFloat = 24
    static let platterShadowY: CGFloat = 10

    //Touch
    static let tapSlop: CGFloat = 10 //drags shorter than this are a tap on the label
    static let labelPressHitSlop: CGFloat = 24 //re-tap-to-close hit area around the label; the bare frame is too small a target

    //iOS 26 open bloom
    static let bloomOpen = Animation.spring(response: 0.32, dampingFraction: 0.82)
    static let bloomClose = Animation.snappy(duration: 0.25) //also the .retract dismiss
    static let reflowResize = Animation.expand //post-open reflow; must equal the curve the content itself reflows on
    static let lensBlur: CGFloat = 8 //peak refraction blur while content materialises
    static let contentMaterializeStart: CGFloat = 0.55 //content (and footer) fade in over the back stretch of the bloom
    static let closeGlassFadeProgress: CGFloat = 0.05 //on a retract the glass stays solid until here, then melts

    //iOS 26 morph dismiss: platter + old label pinch to a circle, the new label re-expands
    static let dismissCircleScale: CGFloat = 1.45 //× the label's smaller side, clamped so tall labels don't blob
    static let dismissCircleMinDiameter: CGFloat = 28
    static let dismissCircleMaxDiameter: CGFloat = 64
    static let collapseToCircle = Animation.smooth(duration: 0.26) //ease-out: the reveal launches underneath while this lands
    static let revealLaunchDelay: TimeInterval = 0.13 //the liquidity knob; ≥ ~0.05 keeps the label fade windows apart
    static let circleReveal = Animation.interpolatingSpring(Spring(response: 0.37, dampingRatio: 0.70), initialVelocity: 4)
    static let revealOvershoot: CGFloat = 1.08 //cap on the spring's pop past resting size
    static let oldLabelFadeEnd: CGFloat = 0.35 //collapse progress at which the old copy is fully faded
    static let newLabelFadeStart: CGFloat = 0.3 //reveal progress at which the new copy starts appearing
    static let revealGlassFadeProgress: CGFloat = 0.35 //glass melts over the reveal's final relax onto the label
    static let lensFadeOut = Animation.snappy(duration: 0.05) //leftover halo after the reveal lands
    static let dismissSafetyTimeout: TimeInterval = 1.2 //must exceed the reveal's settle

    //Pre-26 (iOS 18.x): the classic platter
    static let anchorGap: CGFloat = 6 //the classic menu floats off the label; iOS 26 sits flush
    static let collapsedScale: CGFloat = 0.2
    static let openScale = Animation.spring(response: 0.42, dampingFraction: 0.8)
    static let openFade = Animation.easeOut(duration: 0.2)
    static let closeScale = Animation.spring(response: 0.3, dampingFraction: 1)
    static let closeFade = Animation.easeIn(duration: 0.18)
    static let teardownDelay: TimeInterval = 0.32 //must outlast closeScale
}

// MARK: - Controller (owns the overlay window; persists across opens)

@MainActor @Observable
private final class DropdownCustomMenuController {

    enum Phase { case measuring, shown, dismissing }

    //Presentation: set by present(), cleared by tearDown()
    private(set) var phase: Phase = .measuring
    private(set) var anchor: CGRect = .zero //the label frame at open; placement never moves underfoot
    private(set) var labelFrame: CGRect = .zero //the label's LIVE frame; the close lands on it
    private(set) var cornerRadii = Spec.platterCornerRadii
    private(set) var placementOffset: CGSize = .zero
    private(set) var retractOnEmptyDismiss = true
    private(set) var content: (() -> AnyView)?
    private(set) var label: (() -> AnyView)? //refreshed while open, so the dismiss copy shows the current value
    private(set) var footer: (() -> AnyView)?

    //Dismiss: set by dismiss(), cleared by tearDown()
    private(set) var dismissStyle: DropdownCustomMenuDismissStyle = .morph
    private(set) var labelFrameAtDismiss: CGRect = .zero //where the label VISUALLY sat when dismissal began
    private(set) var frozenLabel: UIImage? //the OLD value, captured before the selection mutated state
    private(set) var hidesLabel = false //the real label hides under the carried copy during a .morph

    //Cross-window: the overlay covers the label, so it reports the re-tap press here
    var labelPressed = false

    var isPresented: Bool { window != nil } //reads an unobserved field on purpose

    @ObservationIgnored private var window: UIWindow?
    @ObservationIgnored private var onClose: (() -> Void)?
    @ObservationIgnored private var generation = 0 //guards wall-clock teardowns from a previous open

    // MARK: Lifecycle

    func present(anchor: CGRect,
                 cornerRadii: RectangleCornerRadii,
                 placementOffset: CGSize,
                 retractOnEmptyDismiss: Bool,
                 onClose: (() -> Void)?,
                 footer: (() -> AnyView)?,
                 label: @escaping () -> AnyView,
                 content: @escaping () -> AnyView) {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive })
        else { return }
        self.anchor = anchor
        labelFrame = anchor
        self.cornerRadii = cornerRadii
        self.placementOffset = placementOffset
        self.retractOnEmptyDismiss = retractOnEmptyDismiss
        self.onClose = onClose
        self.footer = footer
        self.label = label
        self.content = content
        phase = .measuring

        //Own window at .alert+1 so nothing can clip it; shown but never made key, so first responder stays in the app
        let host = UIHostingController(rootView: DropdownCustomMenuOverlay(controller: self))
        host.view.backgroundColor = .clear
        let window = UIWindow(windowScene: scene)
        window.rootViewController = host
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.isHidden = false
        self.window = window
    }

    func markShown() {
        if phase == .measuring { phase = .shown }
    }

    func updateLabelFrame(_ frame: CGRect) {
        guard window != nil, frame != .zero else { return }
        labelFrame = frame
    }

    func updateLabel(_ label: @escaping () -> AnyView) {
        guard window != nil else { return }
        self.label = label
    }

    //No-op if already frozen, so a selection's early freeze wins over the dismiss's own
    func freezeLabel() {
        guard frozenLabel == nil, let label else { return }
        let renderer = ImageRenderer(content: label())
        renderer.scale = window?.traitCollection.displayScale ?? 3
        renderer.isOpaque = false
        frozenLabel = renderer.uiImage
    }

    func dismiss(style: DropdownCustomMenuDismissStyle) {
        guard window != nil, phase != .dismissing else { return }
        labelFrameAtDismiss = labelFrame //frame updates only arrive from layout, so onClose can't move this
        onClose?() //first, once, for every style
        guard style != .instant else { tearDown(); return }
        dismissStyle = style
        phase = .dismissing //the overlay's onChange(of: phase) runs the choreography
        if #available(iOS 26.0, *) {
            if style == .morph {
                freezeLabel()
                hidesLabel = true //instantly, under the pixel-identical copy
            }
            scheduleTearDown(after: Spec.dismissSafetyTimeout) //safety net only; the completion chain beats it
        } else {
            scheduleTearDown(after: Spec.teardownDelay)
        }
    }

    /// Reveal landed: the real (now-current) label comes back under the copy before the halo melts.
    func restoreLabel() {
        guard phase == .dismissing else { return }
        hidesLabel = false
    }

    func finishDismiss() {
        guard phase == .dismissing else { return }
        tearDown()
    }

    private func scheduleTearDown(after delay: TimeInterval) {
        let gen = generation
        Task {
            try? await Task.sleep(for: .seconds(delay))
            if generation == gen { tearDown() }
        }
    }

    private func tearDown() {
        generation += 1
        window?.isHidden = true
        window = nil
        onClose = nil
        content = nil
        label = nil
        footer = nil
        anchor = .zero
        labelFrame = .zero
        cornerRadii = Spec.platterCornerRadii
        placementOffset = .zero
        retractOnEmptyDismiss = true
        dismissStyle = .morph
        labelFrameAtDismiss = .zero
        frozenLabel = nil
        hidesLabel = false
        labelPressed = false
        phase = .measuring
    }
}

// MARK: - Overlay (the root view of the menu window)

private struct DropdownCustomMenuOverlay: View {

    let controller: DropdownCustomMenuController

    //Per-open animation state lives here: the overlay is recreated with every window
    @State private var menuSize: CGSize?
    @State private var contentIdealHeight: CGFloat = 0
    @State private var appeared = false
    @State private var morphProgress: CGFloat = 0 //0 = label frame, 1 = platter; .morph runs it back toward the circle
    @State private var revealProgress: CGFloat = 0 //.morph only: 0 = the circle, 1 = re-expanded onto the label
    @State private var lensOpacity: Double = 0

    private var isGlass: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = Metrics(geo: geo, anchor: controller.anchor, overlapsAnchor: isGlass,
                                  placementOffset: controller.placementOffset)
            let platterRect = menuSize.map { metrics.platterRect(for: $0) }
            ZStack(alignment: .topLeading) {
                tapAwayCatcher
                if let footer = controller.footer, let platterRect {
                    footerCard(footer(), platterRect: platterRect)
                        .zIndex(1) //above the platter, whose glass would otherwise sample the footer's colour
                }
                if let content = controller.content {
                    if #available(iOS 26.0, *) {
                        glassPresentation(content: content(), metrics: metrics, platterRect: platterRect)
                    } else {
                        legacyPresentation(content: content(), metrics: metrics)
                    }
                }
            }
            .onChange(of: geo.size) { _, _ in controller.dismiss(style: .instant) } //anchors are stale after a resize
            .onChange(of: controller.phase) { _, phase in
                guard phase == .dismissing else { return }
                if #available(iOS 26.0, *) { runDismiss() }
            }
        }
        .ignoresSafeArea() //overlay coords = window coords, so the label's global frame places directly
    }
}

//Tap-away catcher: swallows every outside touch, like the native menu
extension DropdownCustomMenuOverlay {

    //The window covers the label, so its re-tap press is reported through labelPressed, then dismissed on release
    private var tapAwayCatcher: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        let hit = controller.anchor.insetBy(dx: -Spec.labelPressHitSlop, dy: -Spec.labelPressHitSlop)
                        controller.labelPressed = hit.contains(value.startLocation)
                    }
                    .onEnded { _ in
                        controller.labelPressed = false
                        controller.dismiss(style: controller.retractOnEmptyDismiss ? .retract : .morph)
                    }
            )
    }
}

//Detached footer: its own glass card a gap below the platter, never part of the lens morph
extension DropdownCustomMenuOverlay {

    //Anchored to the platter's live placement, so it stays locked to it through the bloom and reflows
    @ViewBuilder
    private func footerCard(_ footer: AnyView, platterRect: CGRect) -> some View {
        let card = footer
            .menuEnvironment(controller)
            .fixedSize() //keeps its own width
        if #available(iOS 26.0, *) {
            card.modifier(FooterMorph(progress: morphProgress, top: platterRect.minY, bottom: platterRect.maxY,
                                      leftX: platterRect.minX, width: platterRect.width))
        } else {
            let visible = appeared && controller.phase == .shown
            card
                .frame(width: platterRect.width)
                .opacity(visible ? 1 : 0)
                .scaleEffect(visible ? 1 : 0.96, anchor: .top)
                .animation(.transition, value: visible)
                .offset(x: platterRect.minX, y: platterRect.maxY + Spec.footerGap)
        }
    }
}

//iOS 26: the hidden sizer and the glass platter
extension DropdownCustomMenuOverlay {

    @available(iOS 26.0, *)
    @ViewBuilder
    private func glassPresentation(content: AnyView, metrics: Metrics, platterRect: CGRect?) -> some View {
        //Hidden sizer, always mounted: content renders twice, so height-changing state must live in shared bindings
        chrome(content, metrics: metrics)
            .opacity(0)
            .allowsHitTesting(false)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                sized(size, metrics: metrics)
            }

        if let platterRect {
            let isMorphDismiss = controller.phase == .dismissing && controller.dismissStyle == .morph
            if isMorphDismiss {
                morphDismissPresentation(content: content, metrics: metrics, platterRect: platterRect)
            } else {
                //The open bloom; .retract runs this SAME view backwards (a branch swap would replace the glass mid-frame)
                chrome(content, metrics: metrics)
                    .modifier(MenuLensMorph(progress: morphProgress,
                                            collapsed: controller.labelFrame,
                                            expanded: platterRect,
                                            platterCorners: controller.cornerRadii,
                                            isClosing: controller.phase == .dismissing))
                    .opacity(lensOpacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private func sized(_ size: CGSize, metrics: Metrics) {
        if appeared {
            withAnimation(Spec.reflowResize) { menuSize = size } //platter and footer both derive from it
            return
        }
        menuSize = size
        //The first pass may report the UNCAPPED height: bloom only once the scroll-capped pass lands
        guard size.height <= metrics.maxHeight + 1 else { return }
        appeared = true
        controller.markShown()
        lensOpacity = 1 //the glass is on screen the same frame as the tap
        DispatchQueue.main.async { //the bloom must leave this layout transaction, or it snaps open
            withAnimation(Spec.bloomOpen) { morphProgress = 1 }
        }
    }
}

//iOS 26 dismiss choreography, run from onChange(of: phase) once the dismiss branch is mounted
extension DropdownCustomMenuOverlay {

    @available(iOS 26.0, *)
    private func runDismiss() {
        switch controller.dismissStyle {
        case .retract:
            withAnimation(Spec.bloomClose, completionCriteria: .logicallyComplete) {
                morphProgress = 0
            } completion: {
                meltAndFinish()
            }
        case .morph:
            //The async hop gives the reveal its own animation record; same-turn writes would merge
            withAnimation(Spec.collapseToCircle) { morphProgress = 0 }
            DispatchQueue.main.async {
                withAnimation(Spec.circleReveal.delay(Spec.revealLaunchDelay), completionCriteria: .removed) {
                    revealProgress = 1
                } completion: {
                    controller.restoreLabel() //real label back UNDER the copy first, then melt copy + glass over it
                    meltAndFinish()
                }
            }
        case .instant:
            break //handled synchronously in the controller
        }
    }

    private func meltAndFinish() {
        withAnimation(Spec.lensFadeOut) {
            lensOpacity = 0
        } completion: {
            controller.finishDismiss()
        }
    }
}

//iOS 26 .morph dismiss: platter + OLD label pinch into a circle, the NEW label re-expands; both copies stay mounted throughout
extension DropdownCustomMenuOverlay {

    @available(iOS 26.0, *)
    @ViewBuilder
    private func morphDismissPresentation(content: AnyView, metrics: Metrics, platterRect: CGRect) -> some View {
        let collapseSource = controller.labelFrameAtDismiss //where the label visually sat at dismiss
        let landing = controller.labelFrame //live on purpose: the reveal side is still invisible if it moves
        let side = (min(collapseSource.width, collapseSource.height) * Spec.dismissCircleScale)
            .clamped(to: Spec.dismissCircleMinDiameter...Spec.dismissCircleMaxDiameter)
        let circle = CGRect(x: collapseSource.midX - side / 2, y: collapseSource.midY - side / 2, width: side, height: side)

        ZStack(alignment: .topLeading) {
            chrome(content, metrics: metrics)
                .modifier(PlatterDismissMorph(collapse: morphProgress,
                                              reveal: revealProgress,
                                              expanded: platterRect,
                                              labelRect: landing,
                                              circleRect: circle,
                                              platterCorners: controller.cornerRadii))
                .opacity(lensOpacity)
            if let oldLabel {
                labelCopy(oldLabel, at: collapseSource, circle: circle, reveals: false)
            }
            if let live = controller.label {
                labelCopy(live(), at: landing, circle: circle, reveals: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var oldLabel: AnyView? {
        if let frozen = controller.frozenLabel { return AnyView(Image(uiImage: frozen)) }
        return controller.label.map { AnyView($0()) } //no bitmap: fall back to the live label
    }

    @available(iOS 26.0, *)
    private func labelCopy(_ view: AnyView, at rect: CGRect, circle: CGRect, reveals: Bool) -> some View {
        view
            .modifier(LabelCollapseMorph(collapse: morphProgress, reveal: revealProgress,
                                         labelRect: rect, circleRect: circle, isRevealLayer: reveals))
            .opacity(lensOpacity)
            .allowsHitTesting(false) //SwiftUI hit-tests at model values: an invisible copy would still eat a tap
    }
}

//Pre-26 (iOS 18.x): the classic scale/fade platter
extension DropdownCustomMenuOverlay {

    @ViewBuilder
    private func legacyPresentation(content: AnyView, metrics: Metrics) -> some View {
        let visible = appeared && controller.phase == .shown
        let placement = metrics.placement(for: menuSize ?? .zero)
        let shape = UnevenRoundedRectangle(cornerRadii: controller.cornerRadii)
        chrome(content, metrics: metrics)
            .background { shape.fill(.regularMaterial).shadow(.floating) }
            .clipShape(shape)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                menuSize = size
                if !appeared, size.height <= metrics.maxHeight + 1 { //wait for the scroll-capped pass
                    appeared = true
                    controller.markShown()
                }
            }
            .scaleEffect(visible ? 1 : Spec.collapsedScale, anchor: placement.anchor)
            .animation(visible ? Spec.openScale : Spec.closeScale, value: visible)
            .opacity(visible ? 1 : 0)
            .animation(visible ? Spec.openFade : Spec.closeFade, value: visible)
            .opacity(menuSize == nil ? 0 : 1)
            .offset(x: placement.origin.x, y: placement.origin.y)
    }
}

//Shared chrome: environment plumbing, the scroll cap, and hugging the content's width
extension DropdownCustomMenuOverlay {

    @ViewBuilder
    private func chrome(_ content: AnyView, metrics: Metrics) -> some View {
        let inner = content
            .menuEnvironment(controller)
            .getHeight($contentIdealHeight)
        Group {
            if contentIdealHeight != 0, contentIdealHeight > metrics.maxHeight {
                ScrollView { inner }.frame(height: metrics.maxHeight)
            } else {
                inner
            }
        }
        .fixedSize(horizontal: true, vertical: false) //maxWidth is greedy under the window's infinite proposal
    }
}

private extension View {
    //The only route back to the controller from the menu window; consumers must be their own View structs
    func menuEnvironment(_ controller: DropdownCustomMenuController) -> some View {
        environment(\.dropdownCustomMenuDismiss, DropdownCustomMenuDismissAction { [weak controller] style in
            controller?.dismiss(style: style)
        })
        .environment(\.dropdownCustomMenuFreezeLabel, DropdownCustomMenuFreezeLabelAction { [weak controller] in
            controller?.freezeLabel()
        })
    }
}

//Placement: safe-area aware, below the label when it fits, else above, else the larger side
extension DropdownCustomMenuOverlay {

    struct Metrics {
        let bounds: CGSize
        let available: CGRect
        let anchor: CGRect
        let placementOffset: CGSize
        let belowTop: CGFloat //where the platter's top lands when placed below
        let aboveBottom: CGFloat //where its bottom lands when placed above

        var spaceBelow: CGFloat { available.maxY - belowTop }
        var spaceAbove: CGFloat { aboveBottom - available.minY }
        var maxHeight: CGFloat { max(spaceBelow, spaceAbove) }

        //iOS 26 sits flush on the label edge; the classic menu floats 6pt off
        init(geo: GeometryProxy, anchor: CGRect, overlapsAnchor: Bool, placementOffset: CGSize) {
            let safe = geo.safeAreaInsets
            let margin = Spec.screenMargin
            bounds = geo.size
            available = CGRect(x: safe.leading + margin,
                               y: safe.top + margin,
                               width: max(0, bounds.width - safe.leading - safe.trailing - 2 * margin),
                               height: max(0, bounds.height - safe.top - safe.bottom - 2 * margin))
            self.anchor = anchor
            self.placementOffset = placementOffset
            belowTop = overlapsAnchor ? anchor.minY : anchor.maxY + Spec.anchorGap
            aboveBottom = overlapsAnchor ? anchor.maxY : anchor.minY - Spec.anchorGap
        }

        func platterRect(for size: CGSize) -> CGRect {
            CGRect(origin: placement(for: size).origin, size: size)
        }

        //Edge-aligns to the label; the unit anchor is the platter point nearest it (pre-26 scale origin)
        func placement(for size: CGSize) -> (origin: CGPoint, anchor: UnitPoint) {
            let below: Bool
            if size.height <= spaceBelow {
                below = true
            } else if size.height <= spaceAbove {
                below = false
            } else {
                below = spaceBelow >= spaceAbove
            }
            var y = below ? belowTop : aboveBottom - size.height
            y += placementOffset.height
            y = y.clamped(to: available.minY...max(available.minY, available.maxY - size.height))

            var x = anchor.midX <= bounds.width / 2 ? anchor.minX : anchor.maxX - size.width
            x += placementOffset.width
            x = x.clamped(to: available.minX...max(available.minX, available.maxX - size.width))

            let unitX = ((anchor.midX - x) / max(size.width, 1)).clamped(to: 0...1)
            return (CGPoint(x: x, y: y), UnitPoint(x: unitX, y: below ? 0 : 1))
        }
    }
}

// MARK: - Lens morphs (iOS 26)

/// One frame of the glass platter: where it is, its corners, and how present each layer is.
private struct LensPose {
    var rect: CGRect
    var corners: RectangleCornerRadii
    var contentOpacity: Double
    var blur: CGFloat
    var glassOpacity: Double
    var shadowScale: CGFloat
}

//Content laid out once and scaled in; glass placed by padding, standalone (a container ignores .opacity)
@available(iOS 26.0, *)
private struct GlassLens: ViewModifier {
    let pose: LensPose
    let expanded: CGRect

    func body(content: Content) -> some View {
        let w = pose.rect.width
        let h = pose.rect.height
        content
            .frame(width: expanded.width, height: expanded.height, alignment: .topLeading)
            .scaleEffect(x: w / max(expanded.width, 1), y: h / max(expanded.height, 1), anchor: .topLeading)
            .blur(radius: pose.blur)
            .opacity(pose.contentOpacity)
            .frame(width: w, height: h, alignment: .topLeading)
            .glassEffect(.regular, in: UnevenRoundedRectangle(cornerRadii: pose.corners))
            //Raw shadow is sanctioned here (CLAUDE.md): it must scale with the bloom
            .shadow(color: .black.opacity(Spec.platterShadowOpacity * pose.shadowScale),
                    radius: Spec.platterShadowRadius * pose.shadowScale,
                    y: Spec.platterShadowY * pose.shadowScale)
            .opacity(pose.glassOpacity)
            .frame(width: w, height: h, alignment: .topLeading)
            .padding(.leading, max(0, pose.rect.minX))
            .padding(.top, max(0, pose.rect.minY))
    }
}

//The open bloom (0 → 1) from the label frame to the platter; .retract runs it back with the glass melting at the end
@available(iOS 26.0, *)
private struct MenuLensMorph: ViewModifier, Animatable {
    var progress: CGFloat
    let collapsed: CGRect
    let expanded: CGRect
    let platterCorners: RectangleCornerRadii
    let isClosing: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.modifier(GlassLens(pose: pose, expanded: expanded))
    }

    //At progress 1 this must equal PlatterDismissMorph at (1, 0): that identity hides the branch swap
    private var pose: LensPose {
        let t = progress.clamped(to: 0...1)
        let rect = lerp(collapsed, expanded, t)
        let startCorner = min(collapsed.width, collapsed.height) / 2 //the button's capsule
        return LensPose(
            rect: rect,
            corners: platterCorners.map { lerp(startCorner, $0, t) }.capped(toHalfSideOf: rect.size),
            contentOpacity: ramp(t, over: Spec.contentMaterializeStart...1),
            blur: (1 - t) * Spec.lensBlur,
            glassOpacity: isClosing ? ramp(t, over: 0...Spec.closeGlassFadeProgress) : 1,
            shadowScale: t
        )
    }
}

//The .morph platter: collapse (1 → 0) and reveal (0 → 1) blend additively around the circle into one flow
@available(iOS 26.0, *)
private struct PlatterDismissMorph: ViewModifier, Animatable {
    var collapse: CGFloat
    var reveal: CGFloat
    let expanded: CGRect
    let labelRect: CGRect
    let circleRect: CGRect
    let platterCorners: RectangleCornerRadii

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(collapse, reveal) }
        set { collapse = newValue.first; reveal = newValue.second }
    }

    func body(content: Content) -> some View {
        content.modifier(GlassLens(pose: pose, expanded: expanded))
    }

    private var pose: LensPose {
        let c = collapse.clamped(to: 0...1)
        let r = reveal.clamped(to: 0...1)
        let rect = CGRect(
            x: circleRect.minX + (expanded.minX - circleRect.minX) * c + (labelRect.minX - circleRect.minX) * r,
            y: circleRect.minY + (expanded.minY - circleRect.minY) * c + (labelRect.minY - circleRect.minY) * r,
            width: circleRect.width + (expanded.width - circleRect.width) * c + (labelRect.width - circleRect.width) * r,
            height: circleRect.height + (expanded.height - circleRect.height) * c + (labelRect.height - circleRect.height) * r
        )
        let circleRadius = min(circleRect.width, circleRect.height) / 2
        let labelRadius = min(labelRect.width, labelRect.height) / 2 //the label's capsule
        return LensPose(
            rect: rect,
            corners: platterCorners
                .map { circleRadius + ($0 - circleRadius) * c + (labelRadius - circleRadius) * r }
                .capped(toHalfSideOf: rect.size),
            contentOpacity: ramp(c, over: Spec.contentMaterializeStart...1),
            blur: (1 - c) * (1 - r) * Spec.lensBlur * 0.5,
            glassOpacity: ramp(1 - r, over: 0...Spec.revealGlassFadeProgress),
            shadowScale: c
        )
    }
}

//A label copy on the circle ↔ label axis; OLD fades out by oldLabelFadeEnd, NEW fades in from newLabelFadeStart
@available(iOS 26.0, *)
private struct LabelCollapseMorph: ViewModifier, Animatable {
    var collapse: CGFloat
    var reveal: CGFloat
    let labelRect: CGRect
    let circleRect: CGRect
    let isRevealLayer: Bool

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(collapse, reveal) }
        set { collapse = newValue.first; reveal = newValue.second }
    }

    func body(content: Content) -> some View {
        let c = collapse.clamped(to: 0...1)
        let r = reveal.clamped(to: 0...1)
        let t = (c + r).clamped(to: 0...1) //1 = resting on the label (either end), 0 = at the circle
        let rect = lerp(circleRect, labelRect, t)
        let opacity = isRevealLayer ? ramp(r, over: Spec.newLabelFadeStart...1)
                                    : ramp(c, over: Spec.oldLabelFadeEnd...1)
        //Explicit overshoot pop: the min-ratio scale below would cancel a lerp-based one
        let pop = isRevealLayer ? 1 + (reveal - 1).clamped(to: 0...(Spec.revealOvershoot - 1)) : 1
        let scale = min(rect.width / max(labelRect.width, 1), rect.height / max(labelRect.height, 1))
        content
            .fixedSize() //before the scale, so the text never reflows or truncates
            .scaleEffect(scale * pop)
            .frame(width: rect.width, height: rect.height)
            .blur(radius: (1 - t) * Spec.lensBlur)
            .opacity(opacity)
            .padding(.leading, max(0, rect.minX))
            .padding(.top, max(0, rect.minY))
    }
}

//The footer rides the bloom: it tracks the platter's interpolated bottom edge + gap and fades in on the content's ramp
@available(iOS 26.0, *)
private struct FooterMorph: ViewModifier, Animatable {
    var progress: CGFloat
    var top: CGFloat
    var bottom: CGFloat
    let leftX: CGFloat
    let width: CGFloat

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(progress, AnimatablePair(top, bottom)) }
        set {
            progress = newValue.first
            top = newValue.second.first
            bottom = newValue.second.second
        }
    }

    func body(content: Content) -> some View {
        let appear = ramp(progress, over: Spec.contentMaterializeStart...1)
        content
            .frame(width: width)
            .scaleEffect(0.97 + 0.03 * appear, anchor: .top)
            .opacity(appear)
            .offset(x: leftX, y: top + (bottom - top) * progress + Spec.footerGap)
    }
}

// MARK: - Helpers

private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t
}

private func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
    CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
           width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
}

/// 0 → 1 as `x` crosses `range`, clamped either side.
private func ramp(_ x: CGFloat, over range: ClosedRange<CGFloat>) -> Double {
    Double(((x - range.lowerBound) / (range.upperBound - range.lowerBound)).clamped(to: 0...1))
}

private extension RectangleCornerRadii {
    func map(_ transform: (CGFloat) -> CGFloat) -> RectangleCornerRadii {
        RectangleCornerRadii(topLeading: transform(topLeading), bottomLeading: transform(bottomLeading),
                             bottomTrailing: transform(bottomTrailing), topTrailing: transform(topTrailing))
    }

    /// Each corner capped at a half-side, so the shape stays a clean circle / pill / rounded rect.
    func capped(toHalfSideOf size: CGSize) -> RectangleCornerRadii {
        let cap = min(size.width, size.height) / 2
        return map { min(cap, $0) }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    DropdownCustomMenuPreview()
}

private struct DropdownCustomMenuPreview: View {

    @State private var flavour = "Vanilla"
    @State private var showMessage = false

    var body: some View {
        DropdownCustomMenu(showMessageScreen: $showMessage) {
            PreviewRows(selected: $flavour)
        } label: {
            Text("Pick \(flavour)")
                .font(.body(16, .bold))
                .foregroundStyle(Color.textAccent)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appCanvas)
    }
}

//Own struct: it renders in the menu window
private struct PreviewRows: View {

    @Environment(\.dropdownCustomMenuDismiss) private var dismiss
    @Environment(\.dropdownCustomMenuFreezeLabel) private var freezeLabel
    @Binding var selected: String

    var body: some View {
        VStack(spacing: 0) {
            ForEach(["Vanilla", "Chocolate", "Strawberry"], id: \.self) { flavour in
                Text(flavour)
                    .font(.body(17, flavour == selected ? .bold : .medium))
                    .foregroundStyle(flavour == selected ? Color.accent : Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .contentShape(Rectangle())
                    .shrinkPress {
                        let changed = flavour != selected
                        if changed {
                            freezeLabel()
                            selected = flavour
                        }
                        dismiss(changed ? .morph : .retract)
                    }
            }
        }
        .padding(.vertical, Spacing.xs)
        .frame(width: SelectTypeView.cardWidth, alignment: .leading) //the footer is pinned to this width too
    }
}
#endif
