//AI Code Beware!
//
//  TimeCustomMenu.swift
//  Scoop
//
//  Created by Art Ostin on 11/06/2026.
//
//  Native-style menu in its own window. iOS 26: on touch-down the label implodes into a glass droplet that flies
//  to the platter and flowers open; the close runs the device-fitted droplet keyframes. Pre-26: scale/fade.
//
//  TimeCustomMenu(estimatedContentSize:tracksContentSizeChanges:verticalPlacement:placementOffsetX:placementOffsetY:isOpen:onOpen:onClose:) { content } label: { trigger }
//  Content must be its own View struct (it renders in the menu window); inside it call @Environment(\.timeCustomMenuDismiss).
//  Every iOS 26 beat below is fitted to DEVICE recordings of the native menu; the sim animates differently. -timeMenuSlowMotion for review.
//

import SwiftUI
import UIKit

private typealias Spec = TimeCustomMenuSpec

// MARK: - TimeCustomMenu

//Which side of the label the menu opens toward; .automatic follows the native roomier-side rule
enum TimeCustomMenuVerticalPlacement {
    case automatic, above, below
}

struct TimeCustomMenu<Content: View, Label: View>: View {

    //Injected
    let estimatedContentSize: CGSize? //lets the very first open bloom before any measure exists
    let tracksContentSizeChanges: Bool //keeps measuring while open so the platter follows reflowing content
    let verticalPlacement: TimeCustomMenuVerticalPlacement
    let placementOffset: CGSize //nudge on the final placement, positive = right / down
    let isOpen: Binding<Bool>? //mirrors the presentation; written by the menu, never a way to open it
    let onOpen: (() -> Void)? //fires the instant the menu presents, before the bloom
    let onClose: (() -> Void)? //fires the instant a dismiss is requested, before the close
    let content: () -> Content
    let label: () -> Label

    //Local view state
    @Environment(\.scenePhase) private var scenePhase
    @State private var controller = TimeCustomMenuController()
    @State private var labelFrame: CGRect = .zero
    @State private var pressed = false //dim shown only when present FAILED (no active scene); normally the lens is the feedback
    @State private var pendingOpen: Task<Void, Never>? //the armed touch-down open, waiting out openStillDelay

    init(estimatedContentSize: CGSize? = nil,
         tracksContentSizeChanges: Bool = false,
         verticalPlacement: TimeCustomMenuVerticalPlacement = .automatic,
         placementOffsetX: CGFloat = TimeCustomMenuSpec.placementOffsetX,
         placementOffsetY: CGFloat = TimeCustomMenuSpec.placementOffsetY,
         isOpen: Binding<Bool>? = nil,
         onOpen: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder label: @escaping () -> Label) {
        self.estimatedContentSize = estimatedContentSize
        self.tracksContentSizeChanges = tracksContentSizeChanges
        self.verticalPlacement = verticalPlacement
        self.placementOffset = CGSize(width: placementOffsetX, height: placementOffsetY)
        self.isOpen = isOpen
        self.onOpen = onOpen
        self.onClose = onClose
        self.content = content
        self.label = label
    }

    var body: some View {
        let _ = pushLiveLabel()
        //A Button, not a gesture: only a nested Button wins the tap inside the card's zoom Button and yields the pan to the pager
        Button(action: openFromTap) {
            label()
                .contentShape(Rectangle())
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                    labelFrame = frame
                    controller.updateLabelFrame(frame)
                }
                //Below the geometry read so the dim never feeds the anchor; hidesLabel: the lens carries a copy of the label
                .opacity(controller.hidesLabel ? 0 : (pressed ? Spec.pressedLabelOpacity : 1))
                .animation(pressed ? nil : Spec.pressDimRelease, value: pressed) //dim lands instantly, releases eased
        }
        .buttonStyle(MenuLabelPress(onPressChange: pressChanged))
        .instantPressDelivery()
        .onChange(of: scenePhase) { _, phase in //a cancelled touch never releases
            guard phase != .active else { return }
            resetTouchLatches()
        }
        .onDisappear { //the window must never outlive its host
            resetTouchLatches()
            controller.dismiss(animated: false)
        }
    }
}

//Touch-down open
extension TimeCustomMenu {

    private func pressChanged(_ isPressed: Bool) {
        guard isPressed else { //released, or the scroll took the touch: nothing pending survives it
            resetTouchLatches()
            return
        }
        guard !controller.isPresented, pendingOpen == nil else { return }
        pendingOpen = Task { @MainActor in //stillness gate: a still touch opens after 80ms; a scroll cancels the press first
            try? await Task.sleep(for: .seconds(Spec.openStillDelay))
            guard !Task.isCancelled, !controller.isPresented else { return }
            pendingOpen = nil
            presentMenu()
            if !controller.isPresented { pressed = true }
        }
    }

    private func openFromTap() { //a tap faster than the gate opens at release; a pan never gets here
        pendingOpen?.cancel()
        pendingOpen = nil
        guard !controller.isPresented else { return }
        presentMenu()
        if !controller.isPresented { pressed = true }
    }

    private func resetTouchLatches() {
        pendingOpen?.cancel()
        pendingOpen = nil
        pressed = false
    }

    private func presentMenu() {
        controller.present(
            anchor: labelFrame,
            verticalPlacement: verticalPlacement,
            placementOffset: placementOffset,
            estimatedContentSize: estimatedContentSize,
            tracksContentSizeChanges: tracksContentSizeChanges,
            onPresent: { isOpen?.wrappedValue = true; onOpen?() },
            onClose: { isOpen?.wrappedValue = false; onClose?() },
            label: { AnyView(label()) },
            content: { AnyView(content()) }
        )
    }

    //Re-pushes the label closure each body pass (closures aren't Equatable), so the lens copy shows the current value
    private func pushLiveLabel() {
        guard controller.isPresented else { return }
        let makeLabel = label
        DispatchQueue.main.async { controller.updateLabel { AnyView(makeLabel()) } }
    }
}

//Passthrough style: reports isPressed only; the label owns its own dim
private struct MenuLabelPress: ButtonStyle {
    let onPressChange: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in onPressChange(isPressed) }
    }
}

// MARK: - Dismiss action environment

struct TimeCustomMenuDismissAction {
    var action: () -> Void = {}
    func callAsFunction() { action() }
}

extension EnvironmentValues {
    @Entry var timeCustomMenuDismiss = TimeCustomMenuDismissAction()
}

// MARK: - Spec

//The iOS 26 beats are tuned as a set against DEVICE recordings; the sim animates differently, never refit here
enum TimeCustomMenuSpec {

    //DEBUG slow motion for sim capture: -timeMenuSlowMotion (10×) or -timeMenuTimeScale N; clocks multiply, launch velocity divides
    #if DEBUG
    static let timeScale: Double = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-timeMenuTimeScale"), i + 1 < args.count, let n = Double(args[i + 1]), n >= 1 {
            return n
        }
        return args.contains("-timeMenuSlowMotion") ? 10 : 1
    }()
    #else
    static let timeScale: Double = 1
    #endif

    //Platter and placement
    static let platterCornerRadius = CornerRadius.customMenu
    static let placementOffsetX: CGFloat = 19 //default nudge right of the anchor-aligned placement (Arthur: surgical so central)
    static let placementOffsetY: CGFloat = -84 //default nudge up; callers override per row
    static let screenMargin: CGFloat = 9 //kept from the safe-area edges
    static let anchorGap: CGFloat = 6 //pre-26 only: the classic menu floats off the label; iOS 26 sits flush

    //Touch
    static let openStillDelay: TimeInterval = 0.08 //a still touch opens after this; a scroll cancelling the press drops the open
    static let pressedLabelOpacity: CGFloat = 0.5 //native label dim, shown only when present failed
    static let pressDimRelease = Animation.easeOut(duration: 0.15)

    //iOS 26 open: the rise spring accelerates into the flight (a slow first frame keeps the tiny collapse circle visible)
    static let bloomOpen = Animation.interpolatingSpring(Spring(response: 0.32 * timeScale, dampingRatio: 0.80), initialVelocity: 4 / timeScale)
    static let widthBloom = Animation.spring(response: 0.46 * timeScale, dampingFraction: 0.76) //the platterize, starting WITH the rise; its overshoot is the end bounce
    static let reflowResize = Animation.spring(duration: 0.2) //post-open content reflow (tracksContentSizeChanges)
    static let bloomClose = Animation.easeIn(duration: 0.26) //aborting a half-open bloom reverses the open geometry
    //Open beat 1: the label implodes into a tiny circle just past the text
    static let collapseEnd: CGFloat = 0.10 //of the rise
    static let collapseCircleDiameter: CGFloat = 40
    static let collapsePullX: CGFloat = 0.25 //toward the platter's centre, as a fraction of the label width
    static let collapseLift: CGFloat = 1.0 //label-heights above the text
    //Open beat 2: the ball rises to the platter's top-middle as a comet, arriving slightly past it
    static let ballArriveScale: CGFloat = 0.95 //of the platter's short side
    static let flowerOvershoot: CGFloat = 0.08 //of the platter height past the top edge, settled back during the flowering
    static let dragStretch: CGFloat = 0.15 //tail stretch as a fraction of the ball diameter at peak speed
    static let dragPinch: CGFloat = 0.22 //tail taper toward the travel axis
    //Open beat 3: the held circle flowers into the platter rect, every edge on the same fraction
    static let flowerStart: CGFloat = 0.55 //of the platterize
    static let flowerBulge: CGFloat = 0.045 //sides bow outward past the lerp mid-flower
    //Open: the label swallow, masked to the lens
    static let labelRideEnd: CGFloat = 0.22 //of the rise
    static let labelRideScale: CGFloat = 0.25
    static let lensBlur: CGFloat = 8 //peak refraction blur; the swallow uses half
    //Open: material and content ride the platterize
    static let glassMaterialRange: ClosedRange<CGFloat> = 0.12...0.5 //the clear lens frosts into the regular platter
    static let contentArriveRange: ClosedRange<CGFloat> = 0.45...0.6 //rows snap in as the flowering begins; the mask does the reveal
    static let glassPresenceExponent: Double = 0.75 //the frost materialises across the whole flight
    static let clearPresenceExponent: Double = 0.4 //the clear lens is crisp almost immediately

    //iOS 26 droplet close: three beats on one linear clock (fitted to the 2026-08-06 device recording)
    static let closeMorphDuration: TimeInterval = 0.50 * timeScale
    static let lensFadeDuration: TimeInterval = 0.10 * timeScale
    static let closeMorph = Animation.linear(duration: closeMorphDuration)
    static let lensFadeOut = Animation.easeOut(duration: lensFadeDuration) //melts the halo off the restored label
    static let closeContentFadeEnd: CGFloat = 0.28 //rows dissolve inside the collapsing circle
    //Close beat 1: the platter rounds into a large circle, radius racing ahead of size
    static let closeCircleEnd: CGFloat = 0.16
    static let closeCircleScale: CGFloat = 0.58 //of the platter's short side
    //Close beat 2: the circle condenses onto the text line at speed
    static let closeCollapseEnd: CGFloat = 0.33
    static let closeArriveWidth: CGFloat = 76
    static let closeLandHeightPad: CGFloat = 8 //the landing capsule stands this much taller than the label
    //Close beat 3: the capsule springs open centre-outwards with the text growing inside it
    static let closeTextGrowFrom: CGFloat = 0.4
    static let closeTextDrop: CGFloat = 3 //the text emerges this far below rest and rises level
    static let closeTextSettleEnd: CGFloat = 0.72
    static let closeWashFade: ClosedRange<CGFloat> = 0.35...0.85 //the milky wash lingers as a soft pill behind the text
    static let closeLensFadeStart: CGFloat = 0.50
    static let closeLensFadeEnd: CGFloat = 0.95
    //The Dropdown's landing pop sampled onto the close clock: a damped spring launched with the condense's momentum
    static func closeReveal(_ t: CGFloat) -> CGFloat {
        let a: CGFloat = 3.22, b: CGFloat = 4.6, c: CGFloat = 0.5
        let raw = 1 - exp(-a * t) * (cos(b * t) + c * sin(b * t))
        let land = ((t - 0.85) / 0.15).clamped(to: 0...1)
        let blend = land * land * (3 - 2 * land)
        return raw + (1 - raw) * blend
    }

    //Pre-26 (iOS 18.x): the classic platter
    static let collapsedScale: CGFloat = 0.2
    static let openScale = Animation.spring(response: 0.42, dampingFraction: 0.8)
    static let openFade = Animation.easeOut(duration: 0.2)
    static let closeScale = Animation.spring(response: 0.3, dampingFraction: 1)
    static let closeFade = Animation.easeIn(duration: 0.18)
    static let teardownDelay: TimeInterval = 0.32 //must outlast closeScale
}

// MARK: - Controller (owns the overlay window; persists across opens)

@MainActor @Observable
private final class TimeCustomMenuController {

    enum Phase { case measuring, shown, dismissing }

    //Presentation: set by present(); tearDown clears all of it but the anchor
    private(set) var phase: Phase = .measuring
    private(set) var anchor: CGRect = .zero //the label frame at open; placement never moves underfoot
    private(set) var labelFrame: CGRect = .zero //the label's LIVE frame: the lens is born on it and lands on it
    private(set) var verticalPlacement: TimeCustomMenuVerticalPlacement = .automatic
    private(set) var placementOffset: CGSize = .zero
    private(set) var content: (() -> AnyView)?
    private(set) var label: (() -> AnyView)? //refreshed while open, so the lens copy shows the current value

    //Dismiss hand-offs
    private(set) var hidesLabel = false //the real label hides while the lens carries its copy
    private(set) var lensDissolve = false //tells the overlay to melt the halo off the restored label

    var isPresented: Bool { window != nil } //reads an unobserved field on purpose

    //Unobserved: sizes and the cache must never re-render the label view
    @ObservationIgnored private(set) var estimatedContentSize: CGSize?
    @ObservationIgnored private(set) var tracksContentSizeChanges = false
    @ObservationIgnored private(set) var cachedMenuSize: CGSize? //survives teardown: later opens bloom from the exact size
    @ObservationIgnored private var window: UIWindow?
    @ObservationIgnored private var onClose: (() -> Void)?
    @ObservationIgnored private var generation = 0 //voids wall-clock teardowns from a previous open

    // MARK: Lifecycle

    func present(anchor: CGRect,
                 verticalPlacement: TimeCustomMenuVerticalPlacement,
                 placementOffset: CGSize,
                 estimatedContentSize: CGSize?,
                 tracksContentSizeChanges: Bool,
                 onPresent: @escaping () -> Void,
                 onClose: @escaping () -> Void,
                 label: @escaping () -> AnyView,
                 content: @escaping () -> AnyView) {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive })
        else { return }
        onPresent() //only for a real window: isOpen and onOpen never fire for a refused present
        self.anchor = anchor
        labelFrame = anchor
        self.verticalPlacement = verticalPlacement
        self.placementOffset = placementOffset
        self.estimatedContentSize = estimatedContentSize
        self.tracksContentSizeChanges = tracksContentSizeChanges
        self.onClose = onClose
        self.label = label
        self.content = content
        phase = .measuring

        //Own window at .alert+1 so nothing can clip it; shown but never made key, so first responder stays in the app
        let host = UIHostingController(rootView: TimeCustomMenuOverlay(controller: self))
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

    func updateLabel(_ label: @escaping () -> AnyView) {
        guard window != nil else { return }
        self.label = label
    }

    func updateLabelFrame(_ frame: CGRect) {
        guard window != nil, frame != .zero else { return }
        labelFrame = frame
    }

    func cacheMenuSize(_ size: CGSize) {
        cachedMenuSize = size
    }

    func hideLabel() { //called once per open, on the frame the lens takes the label's place: overlap, never a gap
        hidesLabel = true
    }

    func dismiss(animated: Bool = true) {
        guard window != nil, phase != .dismissing else { return }
        onClose?() //first, once, for every path
        guard animated else { tearDown(); return }
        phase = .dismissing //the overlay's onChange(of: phase) animates the close
        let gen = generation
        if #available(iOS 26.0, *) {
            Task { //when the close lands: restore the real label under the copy, melt the halo, tear down
                try? await Task.sleep(for: .seconds(Spec.closeMorphDuration))
                guard generation == gen else { return }
                hidesLabel = false
                lensDissolve = true
                try? await Task.sleep(for: .seconds(Spec.lensFadeDuration))
                if generation == gen { tearDown() }
            }
        } else {
            Task {
                try? await Task.sleep(for: .seconds(Spec.teardownDelay))
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
        label = nil
        verticalPlacement = .automatic
        placementOffset = .zero
        tracksContentSizeChanges = false
        labelFrame = .zero
        hidesLabel = false
        lensDissolve = false
        phase = .measuring
    }
}

// MARK: - Overlay (the root view of the menu window)

private struct TimeCustomMenuOverlay: View {

    let controller: TimeCustomMenuController

    //Per-open animation state lives here: the overlay is recreated with every window
    @State private var menuSize: CGSize?
    @State private var contentIdealHeight: CGFloat = 0
    @State private var appeared = false //pre-26 reveal gate
    @State private var bloomStarted = false
    @State private var rise: CGFloat = 0 //0 = the lens sits on the label, 1 = flown to rest; the close reads it backwards
    @State private var platterize: CGFloat = 0 //the circle widening into the platter on its own clock
    @State private var lensOpacity: Double = 0
    @State private var closeUsesDroplet = false

    private var isGlass: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = Metrics(geo: geo, anchor: controller.anchor, overlapsAnchor: isGlass,
                                  verticalPlacement: controller.verticalPlacement, placementOffset: controller.placementOffset)
            ZStack(alignment: .topLeading) {
                Color.clear //tap-away catcher: swallows every outside touch, like the native menu
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
            .onChange(of: geo.size) { _, _ in controller.dismiss(animated: false) } //anchors are stale after a resize
            .onChange(of: controller.phase) { _, phase in
                guard phase == .dismissing else { return }
                if #available(iOS 26.0, *) { runClose() }
            }
            .onChange(of: controller.lensDissolve) { _, dissolve in
                guard dissolve else { return }
                if #available(iOS 26.0, *) { withAnimation(Spec.lensFadeOut) { lensOpacity = 0 } }
            }
        }
        .ignoresSafeArea() //overlay coords = window coords, so the label's global frame places directly
    }
}

//iOS 26: the hidden sizer and the glass lens
extension TimeCustomMenuOverlay {

    @available(iOS 26.0, *)
    @ViewBuilder
    private func glassPresentation(content: AnyView, metrics: Metrics) -> some View {
        //Reflowing menus keep the hidden sizer mounted; fixed menus measure once and use the cache
        if controller.cachedMenuSize == nil || controller.tracksContentSizeChanges {
            chrome(content, metrics: metrics)
                .opacity(0)
                .allowsHitTesting(false)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size in sized(size, metrics: metrics) }
        }
        //Bloom from what is known now: this open's measure, else the last open's cache, else the caller's estimate
        if let size = menuSize ?? controller.cachedMenuSize ?? controller.estimatedContentSize {
            chrome(content, metrics: metrics)
                .modifier(MenuLensMorph(rise: rise,
                                        platterize: platterize,
                                        collapsed: controller.labelFrame,
                                        expanded: metrics.platterRect(for: size),
                                        label: controller.label?(),
                                        isClosing: controller.phase == .dismissing,
                                        dropletClose: closeUsesDroplet))
                .opacity(lensOpacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .onAppear { //the sizer may be skipped, so mark shown and bloom here
                    controller.markShown()
                    startBloom()
                }
        }
    }

    private func sized(_ size: CGSize, metrics: Metrics) {
        guard size.height <= metrics.maxHeight + 1 else { return } //trust only the scroll-capped pass
        if bloomStarted && controller.tracksContentSizeChanges { //the first measure lands instantly; later reflows animate
            withAnimation(Spec.reflowResize) { menuSize = size }
        } else {
            menuSize = size
        }
        controller.cacheMenuSize(size)
    }

    private func startBloom() {
        guard !bloomStarted else { return }
        bloomStarted = true
        lensOpacity = 1 //pixel-identical to the label, so the lens takes over with no fade
        controller.hideLabel()
        DispatchQueue.main.async { //the springs must leave this layout transaction, or the morph snaps
            withAnimation(Spec.bloomOpen) { rise = 1 }
            withAnimation(Spec.widthBloom) { platterize = 1 }
        }
    }

    @available(iOS 26.0, *)
    private func runClose() {
        closeUsesDroplet = rise >= 0.95 && platterize >= 0.9 //a settled platter runs the droplet keyframes; else reverse the open
        withAnimation(closeUsesDroplet ? Spec.closeMorph : Spec.bloomClose) {
            rise = 0
            platterize = 0
        }
    }
}

//Pre-26 (iOS 18.x): the classic scale/fade platter
extension TimeCustomMenuOverlay {

    @ViewBuilder
    private func legacyPresentation(content: AnyView, metrics: Metrics) -> some View {
        let visible = appeared && controller.phase == .shown
        let placement = metrics.placement(for: menuSize ?? .zero)
        let shape = RoundedRectangle(cornerRadius: Spec.platterCornerRadius)
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

//Shared chrome: the dismiss environment, the scroll cap, and hugging the content's width
extension TimeCustomMenuOverlay {

    @ViewBuilder
    private func chrome(_ content: AnyView, metrics: Metrics) -> some View {
        let inner = content
            .environment(\.timeCustomMenuDismiss, TimeCustomMenuDismissAction { [weak controller] in controller?.dismiss() })
            .getHeight($contentIdealHeight)
            .contentShape(Rectangle())
            .onTapGesture { } //absorbs taps on the content's dead space: only a tap outside dismisses
        Group {
            if contentIdealHeight != 0, contentIdealHeight > metrics.maxHeight {
                ScrollView { inner }.frame(height: metrics.maxHeight)
            } else {
                inner
            }
        }
        .fixedSize(horizontal: true, vertical: false) //.frame(maxWidth:) is greedy under the window's infinite proposal
    }
}

//Placement: safe-area aware; the roomier side when both fit (native), pinned by verticalPlacement
extension TimeCustomMenuOverlay {

    struct Metrics {
        let bounds: CGSize
        let available: CGRect
        let anchor: CGRect
        let verticalPlacement: TimeCustomMenuVerticalPlacement
        let placementOffset: CGSize
        let belowTop: CGFloat //where the platter's top lands when placed below
        let aboveBottom: CGFloat //where its bottom lands when placed above

        var spaceBelow: CGFloat { available.maxY - belowTop }
        var spaceAbove: CGFloat { aboveBottom - available.minY }
        var maxHeight: CGFloat { max(spaceBelow, spaceAbove) }

        //iOS 26 covers the label's edge; the classic menu floats 6pt off
        init(geo: GeometryProxy, anchor: CGRect, overlapsAnchor: Bool,
             verticalPlacement: TimeCustomMenuVerticalPlacement, placementOffset: CGSize) {
            let safe = geo.safeAreaInsets
            let margin = Spec.screenMargin
            bounds = geo.size
            available = CGRect(x: safe.leading + margin,
                               y: safe.top + margin,
                               width: max(0, bounds.width - safe.leading - safe.trailing - 2 * margin),
                               height: max(0, bounds.height - safe.top - safe.bottom - 2 * margin))
            self.anchor = anchor
            self.verticalPlacement = verticalPlacement
            self.placementOffset = placementOffset
            belowTop = overlapsAnchor ? anchor.minY : anchor.maxY + Spec.anchorGap
            aboveBottom = overlapsAnchor ? anchor.maxY : anchor.minY - Spec.anchorGap
        }

        func platterRect(for size: CGSize) -> CGRect {
            CGRect(origin: placement(for: size).origin, size: size)
        }

        //Edge-aligns to the label on its screen half; the unit anchor is the platter point nearest it (pre-26 scale origin)
        func placement(for size: CGSize) -> (origin: CGPoint, anchor: UnitPoint) {
            let below: Bool
            switch verticalPlacement {
            case .below: below = true
            case .above: below = false
            case .automatic: //the roomier side when both fit, else the side that fits, else the larger
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

// MARK: - Lens morph (iOS 26)

//The travelling lens: the native rounded rect at rest, a velocity-warped comet while it moves; one Shape for every phase
@available(iOS 26.0, *)
private struct MenuLensShape: Shape {
    var cornerRadius: CGFloat
    var drag: CGVector //travel direction × magnitude in points

    func path(in rect: CGRect) -> Path {
        let mag = hypot(drag.dx, drag.dy)
        guard mag > 2 else { //under 2pt of drag return the native path: the hand-built ring refracts lumpy under glass
            return RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
        }
        let ux = drag.dx / mag, uy = drag.dy / mag
        //The frame already reserves the tail: the base rect takes the leading side, the warp fills the rest
        var base = rect
        base.size.width -= abs(ux) * mag
        base.size.height -= abs(uy) * mag
        if ux > 0 { base.origin.x += abs(ux) * mag }
        if uy > 0 { base.origin.y += abs(uy) * mag }
        let r = min(cornerRadius, min(base.width, base.height) / 2)
        let k = r * 0.5523 //κ: circle-faithful cubic corner handles
        let x0 = base.minX, x1 = base.maxX, y0 = base.minY, y1 = base.maxY

        //Anchors and handles, clockwise from the top-left corner's end
        var pts: [CGPoint] = [
            CGPoint(x: x0 + r, y: y0),
            CGPoint(x: x1 - r, y: y0),
            CGPoint(x: x1 - r + k, y: y0), CGPoint(x: x1, y: y0 + r - k),
            CGPoint(x: x1, y: y0 + r),
            CGPoint(x: x1, y: y1 - r),
            CGPoint(x: x1, y: y1 - r + k), CGPoint(x: x1 - r + k, y: y1),
            CGPoint(x: x1 - r, y: y1),
            CGPoint(x: x0 + r, y: y1),
            CGPoint(x: x0 + r - k, y: y1), CGPoint(x: x0, y: y1 - r + k),
            CGPoint(x: x0, y: y1 - r),
            CGPoint(x: x0, y: y0 + r),
            CGPoint(x: x0, y: y0 + r - k), CGPoint(x: x0 + r - k, y: y0),
        ]

        //Comet warp: trailing points stretch backward along the travel axis and pinch toward it; the nose stays full
        let cx = base.midX, cy = base.midY
        let half = min(base.width, base.height) / 2
        for i in pts.indices {
            let dx = pts[i].x - cx, dy = pts[i].y - cy
            let noseToTail = (dx * ux + dy * uy) / max(half, 1) //+1 at the nose, −1 at the tail
            let tail = pow(max(0, (1 - noseToTail) / 2).clamped(to: 0...1.2), 1.6)
            pts[i].x -= ux * mag * tail
            pts[i].y -= uy * mag * tail
            let px = -uy, py = ux
            let perp = dx * px + dy * py
            pts[i].x -= px * perp * Spec.dragPinch * tail
            pts[i].y -= py * perp * Spec.dragPinch * tail
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

//The lens geometry for one frame
private struct Lens {
    var rect: CGRect
    var radius: CGFloat
    var drag: CGVector
}

//A label copy for one frame: the swallow on open, the reveal on close
private struct LabelPose {
    var scale: CGFloat
    var offset: CGSize
    var blur: CGFloat
    var opacity: Double
}

//One frame of the morph: the lens plus how present each layer is
private struct LensPose {
    var lens: Lens
    var frostMix: CGFloat //0 = clear lens only, 1 = regular platter only; the two glass layers MOUNT on this
    var frostOpacity: Double
    var clearOpacity: Double
    var contentOpacity: Double
    var label: LabelPose
}

//Two animatable channels (rise, platterize) drive every frame through pure pose functions; one Shape type carries every phase
@available(iOS 26.0, *)
private struct MenuLensMorph: ViewModifier, Animatable {
    var rise: CGFloat
    var platterize: CGFloat
    let collapsed: CGRect //the label's live capsule
    let expanded: CGRect //the platter
    let label: AnyView?
    let isClosing: Bool
    let dropletClose: Bool //the close runs the droplet keyframes only from a settled platter; else the open reversed

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(rise, platterize) }
        set { rise = newValue.first; platterize = newValue.second }
    }

    func body(content: Content) -> some View {
        let droplet = isClosing && dropletClose
        let pose = droplet ? dropletPose(tau: 1 - rise.clamped(to: 0...1)) : openPose()
        let shape = MenuLensShape(cornerRadius: pose.lens.radius, drag: pose.lens.drag)
        let size = pose.lens.rect.size
        //Standalone glass placed by padding: a container ignores .opacity and sits above siblings; .offset leaves glass at its layout origin
        ZStack(alignment: .topLeading) {
            if pose.frostMix > 0 { //absent, not faded: a stacked glassEffect at opacity 0 still washes the composite milky
                Color.clear
                    .frame(width: size.width, height: size.height)
                    .glassEffect(.regular, in: shape)
                    .opacity(pose.frostOpacity)
            }
            content //always mounted, full-size on its resting rect: the lens mask IS the reveal; opacity only keeps the flying ball empty
                .frame(width: expanded.width, height: expanded.height, alignment: .topLeading)
                .offset(x: expanded.minX - pose.lens.rect.minX, y: expanded.minY - pose.lens.rect.minY)
                .opacity(pose.contentOpacity)
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .mask { shape }
            if let label, !droplet { //the swallowed copy sits UNDER the clear lens: real refraction at the moving edge
                labelCopy(label, pose: pose.label, size: size, shape: shape)
            }
            if pose.frostMix < 1 { //the clear lens rides on top of content and copy so it bends them
                Color.clear
                    .frame(width: size.width, height: size.height)
                    .glassEffect(.clear, in: shape)
                    .opacity(pose.clearOpacity)
            }
            if let label, droplet { //the revealed text sits ABOVE the lens: no refraction echoes around crisp glyphs
                labelCopy(label, pose: pose.label, size: size, shape: shape)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .padding(.leading, max(0, pose.lens.rect.minX))
        .padding(.top, max(0, pose.lens.rect.minY))
    }

    private func labelCopy(_ label: AnyView, pose: LabelPose, size: CGSize, shape: MenuLensShape) -> some View {
        label
            .fixedSize() //before the scale, so the text never reflows
            .scaleEffect(pose.scale, anchor: .center)
            .offset(pose.offset)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .blur(radius: pose.blur)
            .opacity(pose.opacity)
            .mask { shape }
    }
}

//The open (and an aborted close running it backwards): raw rise/platterize so the spring overshoots reach the geometry
@available(iOS 26.0, *)
extension MenuLensMorph {

    private var riseClamped: CGFloat { rise.clamped(to: 0...1) }
    private var platterizeClamped: CGFloat { platterize.clamped(to: 0...1) }

    //Where the label implodes to: pulled toward the platter's centre in X, lifted one label-height above the text
    private var collapsePoint: CGPoint {
        let pull = (expanded.midX - collapsed.midX).clamped(to: -collapsed.width * Spec.collapsePullX ... collapsed.width * Spec.collapsePullX)
        return CGPoint(x: collapsed.midX + pull, y: collapsed.midY - collapsed.height * Spec.collapseLift)
    }

    private func openPose() -> LensPose {
        let pc = riseClamped, wpc = platterizeClamped
        let lens = pc < Spec.collapseEnd ? collapseLens() : flightLens()
        let dissolve: Double = isClosing ? 0.25 + 0.75 * pow(Double(pc), 3) : 1 //an aborted close ghosts everything out
        let frostMix = ramp(wpc, over: Spec.glassMaterialRange)
        let presence = pow(Double(max(pc * 0.35, wpc)), Spec.glassPresenceExponent) //the frost on the slow ramp
        let presenceClear = pow(Double(max(pc, wpc)), Spec.clearPresenceExponent) //the clear lens on the fast one
        let arrive = Double(ramp(wpc, over: Spec.contentArriveRange))
        //The swallow: the copy shrinks into the collapse point with the glass; its fade completes inside the droplet
        let ride = ramp(pc, over: 0...Spec.labelRideEnd)
        let fade = ramp(ride, over: 0.5...1)
        let point = collapsePoint
        let swallow = LabelPose(
            scale: lerp(1, Spec.labelRideScale, ride),
            offset: CGSize(width: lerp(collapsed.minX - lens.rect.minX, point.x - lens.rect.minX - collapsed.width / 2, ride),
                           height: lerp(collapsed.minY - lens.rect.minY, point.y - lens.rect.minY - collapsed.height / 2, ride)),
            blur: ride * Spec.lensBlur * 0.5,
            opacity: Double(1 - fade * fade))
        return LensPose(lens: lens,
                        frostMix: frostMix,
                        frostOpacity: dissolve * Double(frostMix) * presence,
                        clearOpacity: dissolve * Double(1 - frostMix) * presenceClear,
                        contentOpacity: arrive * dissolve,
                        label: swallow)
    }

    //Beat 1: the label capsule contracts into the tiny circle just past the text
    private func collapseLens() -> Lens {
        let t = ramp(riseClamped, over: 0...Spec.collapseEnd)
        let d0 = Spec.collapseCircleDiameter
        let point = collapsePoint
        let w = max(1, lerp(collapsed.width, d0, t))
        let h = max(1, lerp(collapsed.height, d0, t))
        let cx = lerp(collapsed.midX, point.x, t)
        let cy = lerp(collapsed.midY, point.y, t)
        let radius = min(min(w, h) / 2, lerp(collapsed.height / 2, d0 / 2, t))
        return Lens(rect: CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h), radius: radius, drag: .zero)
    }

    //Beats 2 and 3: the ball rises to the platter's top-middle as a comet, then flowers into the rect on the platterize clock
    private func flightLens() -> Lens {
        let point = collapsePoint
        let flight = (rise - Spec.collapseEnd) / (1 - Spec.collapseEnd) //unclamped: the spring overshoot is the arrival dip
        let flightClamped = flight.clamped(to: 0...1)
        let arriveDiameter = max(Spec.collapseCircleDiameter, Spec.ballArriveScale * min(expanded.width, expanded.height))
        let target = CGPoint(x: expanded.midX, y: expanded.minY - Spec.flowerOvershoot * expanded.height + arriveDiameter / 2)
        let cx = lerp(point.x, target.x, flight)
        let cy = lerp(point.y, target.y, flight)
        let ballDiameter = lerp(Spec.collapseCircleDiameter, arriveDiameter, flightClamped)
        //Comet drag on a sin(πp) speed envelope, killed by the platterize; the frame reserves the tail
        let dirX = target.x - point.x, dirY = target.y - point.y
        let length = max(1, hypot(dirX, dirY))
        let ux = dirX / length, uy = dirY / length
        let dragMagnitude = ballDiameter * Spec.dragStretch * sin(.pi * flightClamped) * (1 - platterizeClamped)
        let ballW = ballDiameter + abs(ux) * dragMagnitude
        let ballH = ballDiameter + abs(uy) * dragMagnitude
        let bx = cx - ux * dragMagnitude / 2
        let by = cy - uy * dragMagnitude / 2
        //The flowering: every edge expands on the same fraction about the centre; the arrival dip settles as one translation
        let flower = max(0, (platterize - Spec.flowerStart) / (1 - Spec.flowerStart)) //floored, uncapped: the overshoot is the end bounce
        let flowerClamped = flower.clamped(to: 0...1)
        let bulge = 1 + Spec.flowerBulge * sin(.pi * flowerClamped)
        let w = max(1, lerp(ballW, expanded.width, flower)) * bulge
        let h = max(1, lerp(ballH, expanded.height, flower)) * bulge
        let fx = lerp(bx, expanded.midX, flowerClamped)
        let fy = lerp(by, expanded.midY, smoothstep(flowerClamped))
        let cap = min(w, h) / 2
        let radius = min(cap, lerp(cap, Spec.platterCornerRadius, flowerClamped))
        let dragFade = 1 - flowerClamped //the warp is gone by mid-flower
        return Lens(rect: CGRect(x: fx - w / 2, y: fy - h / 2, width: w, height: h),
                    radius: radius,
                    drag: CGVector(dx: ux * dragMagnitude * dragFade, dy: uy * dragMagnitude * dragFade))
    }
}

//The droplet close: three beats on one linear clock, tau = 1 − rise
@available(iOS 26.0, *)
extension MenuLensMorph {

    private func dropletPose(tau: CGFloat) -> LensPose {
        let lens = dropletLens(tau: tau)
        let wash = 1 - ramp(tau, over: Spec.closeWashFade) //frost + rows stay on the collapsing circle, then linger as a soft pill
        let glass = Double(1 - ramp(tau, over: Spec.closeLensFadeStart...Spec.closeLensFadeEnd)) //the lens melts through the spread
        let contentFade = Double(1 - ramp(tau, over: 0...Spec.closeContentFadeEnd))
        //The reveal: the text is born small and faint at the line's centre and grows on the spread's own spring
        let spread = ramp(tau, over: Spec.closeCollapseEnd...1)
        let grow = Spec.closeReveal(spread) //unclamped for the scale: the spring's overshoot is the pop
        let settle = ramp(tau, over: Spec.closeCollapseEnd...Spec.closeTextSettleEnd)
        let drop = Spec.closeTextDrop * (1 - smoothstep(settle)) //emerges pushed down, level before the label swap
        let reveal = LabelPose(
            scale: lerp(Spec.closeTextGrowFrom, 1, grow),
            offset: CGSize(width: collapsed.minX - lens.rect.minX, height: collapsed.minY - lens.rect.minY + drop),
            blur: 0,
            opacity: Double(grow.clamped(to: 0...1)))
        return LensPose(lens: lens,
                        frostMix: wash,
                        frostOpacity: glass * Double(wash),
                        clearOpacity: glass * Double(1 - wash),
                        contentOpacity: contentFade,
                        label: reveal)
    }

    private func dropletLens(tau: CGFloat) -> Lens {
        let landW = collapsed.width
        let landH = collapsed.height + Spec.closeLandHeightPad
        let circleDiameter = Spec.closeCircleScale * min(expanded.width, expanded.height)
        let cx0 = collapsed.midX, cy0 = collapsed.midY

        if tau < Spec.closeCircleEnd { //beat 1: the platter rounds into a large circle, the radius racing ahead of the size
            let t = ramp(tau, over: 0...Spec.closeCircleEnd)
            let ease = smoothstep(t)
            let w = max(1, lerp(expanded.width, circleDiameter, ease))
            let h = max(1, lerp(expanded.height, circleDiameter, ease))
            let cap = min(w, h) / 2
            let radius = min(cap, lerp(Spec.platterCornerRadius, cap, (t * 2).clamped(to: 0...1)))
            return Lens(rect: CGRect(x: expanded.midX - w / 2, y: expanded.midY - h / 2, width: w, height: h), radius: radius, drag: .zero)
        }
        if tau < Spec.closeCollapseEnd { //beat 2: the circle condenses onto the text line's centre, arriving at speed (ease-in)
            let t = ramp(tau, over: Spec.closeCircleEnd...Spec.closeCollapseEnd)
            let launch = t * t
            let w = max(1, lerp(circleDiameter, Spec.closeArriveWidth, launch))
            let h = max(1, lerp(circleDiameter, landH, launch))
            let cx = lerp(expanded.midX, cx0, launch)
            let cy = lerp(expanded.midY, cy0, launch)
            return Lens(rect: CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h), radius: min(w, h) / 2, drag: .zero)
        }
        //beat 3: the capsule springs open centre-outwards on the landing pop
        let t = ramp(tau, over: Spec.closeCollapseEnd...1)
        let w = max(1, lerp(Spec.closeArriveWidth, landW, Spec.closeReveal(t)))
        return Lens(rect: CGRect(x: cx0 - w / 2, y: cy0 - landH / 2, width: w, height: landH), radius: landH / 2, drag: .zero)
    }
}

// MARK: - Helpers

private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t
}

//0 → 1 as x crosses range, clamped either side
private func ramp(_ x: CGFloat, over range: ClosedRange<CGFloat>) -> CGFloat {
    ((x - range.lowerBound) / (range.upperBound - range.lowerBound)).clamped(to: 0...1)
}

private func smoothstep(_ t: CGFloat) -> CGFloat {
    t * t * (3 - 2 * t)
}

// MARK: - Preview

#if DEBUG
#Preview {
    TimeCustomMenuPreview()
}

private struct TimeCustomMenuPreview: View {

    @State private var isOpen = false
    @State private var flavour = "Vanilla"

    var body: some View {
        TimeCustomMenu(estimatedContentSize: CGSize(width: 240, height: 150), isOpen: $isOpen) {
            TimeMenuPreviewRows(selected: $flavour)
        } label: {
            HStack(spacing: Spacing.xs) {
                Text("Pick \(flavour)").font(.body(17, .medium))
                Image(systemName: "chevron.down").font(.icon(12, .regular))
            }
            .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appCanvas)
    }
}

//Own struct: it renders in the menu window
private struct TimeMenuPreviewRows: View {

    @Environment(\.timeCustomMenuDismiss) private var dismiss
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
                        selected = flavour
                        dismiss()
                    }
            }
        }
        .padding(.vertical, Spacing.xs)
        .frame(width: 240) //Geometry: matches the bloom estimate above
    }
}
#endif
