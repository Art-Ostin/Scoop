
//  ZoomTransition.swift
//
//  A reusable, catchable zoom-morph navigation transition.
//
//  Public surface:
//
//    ZoomNavigationStack(title:) { Home() }         the navigation container
//    someCardView.zoomTransition(images:) { ... }   the morph source; the
//                                                   builder is the WHOLE
//                                                   destination screen
//    ImageCarousel(horizontalPadding:aspectRatio:)  the hero slot inside it
//    ZoomStyle                                      shared style constants
//
//  Everything else is machinery. The hero carousel and the opened screen's
//  scroll chrome are UIKit-owned so every spring, crop morph, flyback, and
//  mid-air catch runs frame-locked on the UIKit animation clock — the
//  SwiftUI layer supplies content, never motion. The profile is an overlay
//  presentation above an untouched UINavigationController: the system bar
//  is never pushed onto or reconfigured. The open morph and the cancel
//  spring are catchable mid-air; committed dismissals play to completion.
//

import Combine
import SwiftUI
import UIKit

// MARK: - Public style constants

public enum ZoomStyle {
    /// Corner radius shared by the card, the hero pages, and the morph mask.
    /// A source card should use this radius so the flight is pixel-identical.
    public static let cornerRadius: CGFloat = 20
    /// ImageCarousel defaults: side padding, and resting crop
    /// height = width × detailAspect.
    public static let detailInset: CGFloat = 8
    public static let detailAspect: CGFloat = 1.05

    /// One layer of the card's resting drop shadow: black at `opacity`,
    /// blurred by `radius`, offset `yOffset` down.
    public struct ShadowLayer {
        public let opacity: Double
        public let radius: CGFloat
        public let yOffset: CGFloat
        public init(opacity: Double, radius: CGFloat, yOffset: CGFloat) {
            self.opacity = opacity
            self.radius = radius
            self.yOffset = yOffset
        }
    }
    /// The App Store-style press-down: a held card shrinks to `pressScale`,
    /// release or cancel springs it back, and a release-as-tap launches the
    /// open morph FROM the pressed frame. Both springs are overshoot-free —
    /// damping stays 1; only the responses are meant for tuning.
    public static let pressScale: CGFloat = 0.96
    public static let pressDownResponse: TimeInterval = 0.4
    public static let pressReleaseResponse: TimeInterval = 0.3

    /// The flight elevation shadow under the flying/dragged screen. With no
    /// shadowPath it derives from the masked screen's rendered alpha, so it
    /// hugs the reveal at every mid-flight shape.
    public static let flightShadowOpacity: Float = 0.3
    public static let flightShadowRadius: CGFloat = 36
    public static let flightShadowOffset = CGSize(width: 0, height: 12)

    /// The card's resting shadow, drawn by the library beneath every
    /// `.zoomTransition` card — UIKit-owned so the flights can drive it on
    /// their clocks. The repeated pairs are DELIBERATE: the density is
    /// tuned to the card's original four stacked SwiftUI shadows;
    /// deduplicating would halve it.
    public static let cardShadows: [ShadowLayer] = [
        ShadowLayer(opacity: 0.05, radius: 4, yOffset: 0),
        ShadowLayer(opacity: 0.09, radius: 20, yOffset: 2),
        ShadowLayer(opacity: 0.05, radius: 4, yOffset: 0),
        ShadowLayer(opacity: 0.09, radius: 20, yOffset: 2),
    ]
}

// MARK: - Public navigation container

/// Hosts a SwiftUI root inside a UINavigationController whose bar stays
/// 100% system-managed: presentations are overlays above the whole nav
/// controller, never pushes. Any view inside can wear `.zoomTransition`.
public struct ZoomNavigationStack<Root: View>: UIViewControllerRepresentable {
    private let title: String?
    private let root: Root

    public init(title: String? = nil, @ViewBuilder root: () -> Root) {
        self.title = title
        self.root = root()
    }

    public func makeUIViewController(context: Context) -> ZoomRootController {
        ZoomRootController(root: AnyView(root), title: title)
    }

    public func updateUIViewController(_ root: ZoomRootController, context: Context) {}
}

// MARK: - Root container (nav below, overlay presentations above)

/// Owns the untouched UINavigationController and hosts profile
/// presentations in a layer above it. Nothing here ever pushes, pops, or
/// reconfigures the navigation bar — that is the whole point.
public final class ZoomRootController: UIViewController {

    let nav: UINavigationController
    let host: ZoomHostController
    /// The profile currently presented (or mid-flight), if any.
    private(set) var presentedDetail: ZoomDetailController?

    init(root: AnyView, title: String?) {
        let host = ZoomHostController(root: root, title: title)
        self.host = host
        nav = UINavigationController(rootViewController: host)
        nav.navigationBar.prefersLargeTitles = true
        // Absolute layout margins keep the large title glued to the nav
        // plane; screen-relative margins would snap mid-recede.
        nav.viewRespectsSystemMinimumLayoutMargins = false
        host.viewRespectsSystemMinimumLayoutMargins = false
        super.init(nibName: nil, bundle: nil)
        host.rootController = self
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        addChild(nav)
        nav.view.frame = view.bounds
        nav.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Absolute 16pt side margins (see init): the bar derives the large
        // title's leading from these; they must not float with the screen.
        nav.view.directionalLayoutMargins.leading = 16
        nav.view.directionalLayoutMargins.trailing = 16
        view.addSubview(nav.view)
        nav.didMove(toParent: self)
    }

    /// While a LANDED profile is presented, it owns the status bar. The
    /// hand-off is gated on the landing, not the present: flipping
    /// authority at flight start re-resolves while the dark image still
    /// fills the top, and the content-adaptive bar fights it.
    private var detailOwnsStatusBar = false

    func detailDidTakeStatusBar() {
        guard presentedDetail != nil, !detailOwnsStatusBar else { return }
        detailOwnsStatusBar = true
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    public override var childForStatusBarStyle: UIViewController? {
        detailOwnsStatusBar ? presentedDetail : nav
    }
    public override var childForStatusBarHidden: UIViewController? {
        detailOwnsStatusBar ? presentedDetail : nav
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Rotation / iPad resize while presented: re-fit the persistent scene.
        presentedDetail?.dismissController.refreshRestGeometry()
    }

    /// Presents the profile for a tapped card as an overlay morph.
    func present(from marker: ZoomSourceMarkerView) {
        // One presentation at a time; also covers taps landing while a
        // dismissal flight is still airborne.
        guard presentedDetail == nil else { return }
        // No hero, no morph: an empty image set (bad names at the call
        // site) would crash on pageImages[0] mid-flight.
        guard !marker.images.isEmpty else { return }
        host.activeSource = marker
        // The card's own aspect IS the flight crop: page 1 at this crop is
        // pixel-identical to the card at the first frame of the morph.
        let f = marker.bounds
        let aspect = f.width > 0 ? f.height / f.width : ZoomStyle.detailAspect
        let detail = ZoomDetailController(
            images: marker.images, sourceAspect: aspect,
            detailContent: marker.detail())
        presentedDetail = detail
        addChild(detail)
        detail.dismissController.present(root: self, home: host, detail: detail)
        detail.didMove(toParent: self)
        // The covered home must not scroll or retap.
        nav.view.isUserInteractionEnabled = false
    }

    /// Called by the dismiss controller's teardown once a dismissal lands.
    func presentationDidEnd() {
        presentedDetail?.willMove(toParent: nil)
        presentedDetail?.view.removeFromSuperview()
        presentedDetail?.removeFromParent()
        presentedDetail = nil
        nav.view.isUserInteractionEnabled = true
        // Status bar authority returns to the home in one crossfade.
        detailOwnsStatusBar = false
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
}

// MARK: - Public modifier

public extension View {
    /// Makes this view a zoom-transition source: tapping it morphs it into a
    /// full screen whose hero is `images` (a paging carousel when several
    /// are given). `content` is the ENTIRE destination screen, free SwiftUI,
    /// hosted in a vertical scroll — place `ImageCarousel()` inside it
    /// wherever the carousel should live. Dismissal is the drag, or your
    /// own control calling `@Environment(\.zoomDismiss)`.
    /// `cardOverlay` is chrome drawn over the card (labels, badges): it
    /// hides during flights and fades back in over the landing card. The
    /// library also draws the card's resting drop shadow
    /// (ZoomStyle.cardShadows) — do not add your own .shadow to the card.
    func zoomTransition<Overlay: View, Content: View>(
        images: [String],
        @ViewBuilder cardOverlay: @escaping () -> Overlay,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ZoomTransitionModifier(
            images: images.compactMap { UIImage(named: $0) },
            cardOverlay: { AnyView(cardOverlay()) },
            detail: { AnyView(content()) }))
    }

    /// Overlay-less variant.
    func zoomTransition<Content: View>(
        images: [String],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        zoomTransition(images: images, cardOverlay: { EmptyView() }, content: content)
    }
}

/// Programmatic dismissal for a zoom destination: read it in the content via
/// `@Environment(\.zoomDismiss)` and call it — the screen collapses into its
/// card with the same catchable morph the Back button drives. Outside a
/// zoom destination it is a no-op.
public struct ZoomDismissAction {
    let run: () -> Void
    public func callAsFunction() { run() }
}

private struct ZoomDismissKey: EnvironmentKey {
    static let defaultValue = ZoomDismissAction(run: {})
}

public extension EnvironmentValues {
    var zoomDismiss: ZoomDismissAction {
        get { self[ZoomDismissKey.self] }
        set { self[ZoomDismissKey.self] = newValue }
    }
}

/// The hero slot: renders the transition's image carousel (the morph-around
/// object — its first image is always the one that flies) inline in the
/// destination screen's SwiftUI layout. Place exactly one inside a
/// `.zoomTransition` content builder; it spans the proposed width.
/// - `horizontalPadding`: gap between the screen edge and each page image.
/// - `aspectRatio`: the resting image crop, as height = width × aspectRatio.
///   The in-flight crop is always the tapped card's own measured aspect,
///   morphing to this one.
public struct ImageCarousel: View {
    @Environment(\.zoomHeroContainer) private var container
    private let horizontalPadding: CGFloat
    private let aspectRatio: CGFloat

    public init(horizontalPadding: CGFloat = ZoomStyle.detailInset,
                aspectRatio: CGFloat = ZoomStyle.detailAspect) {
        self.horizontalPadding = horizontalPadding
        self.aspectRatio = aspectRatio
    }

    public var body: some View {
        ZoomHeroRepresentable(container: container,
                              horizontalPadding: horizontalPadding,
                              aspectRatio: aspectRatio)
    }
}

private struct ZoomHeroRepresentable: UIViewRepresentable {
    let container: ZoomHeroContainer?
    let horizontalPadding: CGFloat
    let aspectRatio: CGFloat

    func makeUIView(context: Context) -> UIView {
        container?.setHorizontalPadding(horizontalPadding)
        return container ?? UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        container?.setHorizontalPadding(horizontalPadding)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        // Resting crop: the pages carry the side padding themselves, so the
        // slot spans full width and the image height drives the slot height.
        let w = proposal.width ?? uiView.bounds.width
        guard w > 0 else { return nil }
        return CGSize(width: w, height: max(0, w - 2 * horizontalPadding) * aspectRatio)
    }
}

private struct ZoomHeroContainerKey: EnvironmentKey {
    static let defaultValue: ZoomHeroContainer? = nil
}

extension EnvironmentValues {
    var zoomHeroContainer: ZoomHeroContainer? {
        get { self[ZoomHeroContainerKey.self] }
        set { self[ZoomHeroContainerKey.self] = newValue }
    }
}

// MARK: - Modifier plumbing

/// Bridges the SwiftUI card to the UIKit machinery: an invisible marker view
/// behind the card gives the transition a measurable, always-current frame in
/// UIKit coordinates, a place to hang the landing overlay, and a responder
/// chain up to the host controller.
private struct ZoomTransitionModifier: ViewModifier {
    @StateObject private var state = ZoomSourceState()
    let images: [UIImage]
    let cardOverlay: () -> AnyView
    let detail: () -> AnyView

    func body(content: Content) -> some View {
        // A Button (not a tap gesture) so the press-down rides UIKit scroll
        // interplay for free: a drag that becomes a scroll cancels the
        // press, and the action fires on touch-up. The marker sits INSIDE
        // the scaled label, so the morph measures and launches from the
        // pressed frame exactly.
        Button {
            state.marker?.requestPush()
        } label: {
            content
                .overlay { cardOverlay() } // rest-state chrome; hides with the card
                .opacity(state.isHidden ? 0 : 1)
                .background(ZoomSourceRepresentable(
                    state: state, images: images,
                    cardOverlay: cardOverlay, detail: detail))
                .contentShape(Rectangle())
        }
        .buttonStyle(ZoomCardPressStyle())
    }
}

/// The App Store press-down: shrink to pressScale on a no-overshoot spring,
/// spring back on release — no bounce either way, no dim. A rendering
/// effect on the unmodified label; layout is untouched.
private struct ZoomCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? ZoomStyle.pressScale : 1)
            .animation(
                configuration.isPressed
                    ? .spring(response: ZoomStyle.pressDownResponse, dampingFraction: 1)
                    : .spring(response: ZoomStyle.pressReleaseResponse, dampingFraction: 1),
                value: configuration.isPressed)
    }
}

final class ZoomSourceState: ObservableObject {
    /// Hides the SwiftUI card while the flying copy owns the screen.
    @Published var isHidden = false
    weak var marker: ZoomSourceMarkerView?
}

private struct ZoomSourceRepresentable: UIViewRepresentable {
    let state: ZoomSourceState
    let images: [UIImage]
    let cardOverlay: () -> AnyView
    let detail: () -> AnyView

    func makeUIView(context: Context) -> ZoomSourceMarkerView {
        let v = ZoomSourceMarkerView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        configure(v)
        // A covered home can re-render and REMOUNT the marker
        // mid-presentation: a fresh view must re-derive the shadow's alpha
        // from the card's hidden state. Once, here — updateUIView would
        // stomp the alpha mid-landing-spring.
        v.restingShadow.alpha = state.isHidden ? 0 : 1
        return v
    }

    func updateUIView(_ v: ZoomSourceMarkerView, context: Context) { configure(v) }

    private func configure(_ v: ZoomSourceMarkerView) {
        v.state = state
        state.marker = v
        v.images = images
        v.cardOverlay = cardOverlay
        v.detail = detail
    }
}

/// The card's resting drop shadow (ZoomStyle.cardShadows), rendered
/// shadow-only: an even-odd cutout mask removes the card's interior, so a
/// hidden card never shows a dark card-shaped blob while its shadow is
/// mid-fade. Serves two roles: the marker's resting instance, and the
/// dismissal's landing rig riding the flying card — same class, so the two
/// render identically by construction.
final class CardRestingShadowView: UIView {
    private var shadowLayers: [CALayer] = []
    private let cutout = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        for spec in ZoomStyle.cardShadows {
            let l = CALayer()
            l.shadowColor = UIColor.black.cgColor
            l.shadowOpacity = Float(spec.opacity)
            l.shadowRadius = spec.radius
            l.shadowOffset = CGSize(width: 0, height: spec.yOffset)
            layer.addSublayer(l)
            shadowLayers.append(l)
        }
        cutout.fillRule = .evenOdd
        layer.mask = cutout
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let slot = bounds
        let card = UIBezierPath(roundedRect: slot, cornerRadius: ZoomStyle.cornerRadius)
        // Outer margin covers the blur's full extent; even-odd punches the
        // card shape back out. No implicit actions: layout must not animate.
        let punched = UIBezierPath(rect: slot.insetBy(dx: -200, dy: -200))
        punched.append(card)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for l in shadowLayers {
            l.frame = slot
            l.shadowPath = card.cgPath
        }
        cutout.path = punched.cgPath
        CATransaction.commit()
    }
}

final class ZoomSourceMarkerView: UIView {
    weak var state: ZoomSourceState?
    var images: [UIImage] = []
    var cardOverlay: () -> AnyView = { AnyView(EmptyView()) }
    var detail: () -> AnyView = { AnyView(EmptyView()) }
    private weak var host: ZoomHostController?

    /// The card's resting shadow: hidden with the card at the open, faded
    /// back in by the landing spring, retreated on cancel/catch.
    let restingShadow = CardRestingShadowView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        restingShadow.frame = bounds
        restingShadow.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(restingShadow)
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            host?.unregister(self)
            host = nil
        } else {
            var r: UIResponder? = next
            while let cur = r, !(cur is ZoomHostController) { r = cur.next }
            host = r as? ZoomHostController
            host?.register(self)
            // Instant press delivery: the enclosing scroll's content-touch
            // delay would hold every touch ~150ms before the card's Button
            // sees it. The scroll still cancels the press the moment a
            // drag wins (canCancelContentTouches stays true).
            var v: UIView? = superview
            while let cur = v, !(cur is UIScrollView) { v = cur.superview }
            (v as? UIScrollView)?.delaysContentTouches = false
        }
    }

    func requestPush() { host?.push(from: self) }

    /// The flying image just landed pixel-identical on this card's slot, and
    /// the SwiftUI card un-hides on the NEXT render transaction — this UIKit
    /// overlay carries the exact card pixels through the gap so the landing
    /// never blinks.
    func showLandingOverlay() {
        guard let image = images.first else { return }
        let iv = UIImageView(image: image)
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = ZoomStyle.cornerRadius
        iv.layer.cornerCurve = .continuous
        iv.frame = bounds
        iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(iv)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            iv.removeFromSuperview()
        }
    }

    /// Adopts a scene view (the landed card-overlay copy) for the same
    /// landing bridge: pinned over the card slot, removed once SwiftUI has
    /// re-rendered the real card beneath.
    func adoptLandingOverlay(_ view: UIView) {
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            view.removeFromSuperview()
        }
    }
}

// MARK: - Drag tuning

private enum DragTuning {
    /// Vertical drag that scrubs the collapse 0→1.
    static let collapseDistance: CGFloat = 300
    /// Release past this progress (or a downward flick) dismisses.
    static let dismissThreshold: CGFloat = 0.3
    /// Progressive shrink of the whole screen at full collapse.
    static let minDragScale: CGFloat = 0.82
    /// Gesture-path flight durations. With bounceDamping's 0.8 these are
    /// deliberately underdamped; the close's duration·damping = 0.36
    /// matches the open's 0.4·0.9 so the two directions read as one
    /// physical object.
    static let openFlightDuration: TimeInterval = 0.3   // cancel: spring back to presented
    static let closeFlightDuration: TimeInterval = 0.45 // complete: collapse into the card
    /// Back-button pop: a tap carries no gesture momentum, so no bounce is
    /// earned — near-critical damping at the family stiffness.
    static let buttonFlightDuration: TimeInterval = 0.4
    static let buttonDamping: CGFloat = 0.9
    /// Underdamped ratio for the gesture-driven dismiss springs (cancel
    /// spring-back + drag-release collapse). 1.0 = bounce-free.
    static let bounceDamping: CGFloat = 0.8
    /// ── THE TWO-BEAT ARC ──
    /// Every gesture dismissal dives BELOW its destination and springs up
    /// into it: at the pivot the flying image's top sits at
    /// slotTop + arcOvershoot(slotTop, velocity). The overshoot is an
    /// S-curve per velocity edge:
    ///
    ///   edge(D) = (shelf + (plateau − shelf) · logistic((mid − D)/steep))
    ///             · smoothstep((arcCutoffY − D)/arcCliffWidth)
    ///   O(D, v) = lerp(gentleEdge(D), hardEdge(D), flick(v))
    ///
    /// A flat plateau for slots at/above the screen top (negative minY
    /// needs no special case — the logistic saturates), a steep sigmoid
    /// dip through mid-screen, a low shelf to ~400, then a rounded cliff
    /// to zero at arcCutoffY — slots past the line keep the continuous
    /// morph, the arc's own zero-overshoot limit, no seam. flick(v) blends
    /// the gentle and hard parameter sets. The dive drives the DRAG RULE
    /// via a ghost finger's impulse (ω = launch/(e·Δ) soft-hovers exactly
    /// at the pivot); mask + crop + shadow rig complete by the pivot, and
    /// the physical spring then takes the card up from rest.
    static let arcCutoffY: CGFloat = 450
    static let arcMaxOvershoot: CGFloat = 320
    static let arcGentlePlateau: CGFloat = 290
    static let arcGentleShelf: CGFloat = 45
    static let arcGentleMid: CGFloat = 120
    static let arcGentleSteep: CGFloat = 40
    static let arcHardPlateau: CGFloat = 320
    static let arcHardShelf: CGFloat = 65
    static let arcHardMid: CGFloat = 205
    static let arcHardSteep: CGFloat = 55
    static let arcCliffWidth: CGFloat = 50
    /// What the cliff lands ON at arcCutoffY, per edge: the gentle edge
    /// dies to zero (seamless into the continuous morph), but a hard flick
    /// overextends by at least this much across the whole arc regime — a
    /// deliberate hard-flick seam at the 450 line.
    static let arcHardEndHold: CGFloat = 60
    static let arcFlickFloor: CGFloat = 300
    static let arcFlickCeil: CGFloat = 3000
    /// Flick blend shape: normalized exponential over the flick fraction —
    /// the blend hugs the gentle edge through most of the range and sweeps
    /// toward hard only near the top. Higher = harder flick needed for the
    /// same overshoot; → 0 ≈ linear.
    static let arcFlickBlendSteep: CGFloat = 4
    /// Below each join the edge is a cubic Hermite: diving from the
    /// unchanged position-0 value at the start slope, flattening through
    /// the middle, rolling into the sigmoid's exact value AND slope at the
    /// join. At/beyond the join and above the screen the curve is
    /// bit-identical to the plain sigmoid edge. Gentle: keep the slope
    /// ≤ ~−4 or the flat middle bottoms out; hard: keep it within ~−1.8 or
    /// the monotone rule forces an upward mid-range hump.
    static let arcGentleJoin: CGFloat = 175
    static let arcGentleStartSlope: CGFloat = -3.0
    static let arcHardJoin: CGFloat = 175
    static let arcHardStartSlope: CGFloat = -1.5
    /// The dive-pace band: launch = clamp(vy·arcPaceScale, min, max). The
    /// impulse's duration is e·Δ/launch, so the whole gesture family dives
    /// at similar tempos — depth, not speed, differentiates the band.
    static let arcMinLaunch: CGFloat = 2375
    static let arcMaxLaunch: CGFloat = 2850
    static let arcPaceScale: CGFloat = 0.95
    /// Hard ceiling on the descent beat; an exit here hands the spring a
    /// real downward residual, which the hand-over math absorbs.
    static let arcMaxDiveTime: TimeInterval = 0.6
    /// The whole dismissal (dive + return) is pinned to a total that
    /// varies only with overshoot depth — lerp(arcTimeMin, arcTimeMax,
    /// O / arcMaxOvershoot) — by rescaling both beats proportionally:
    /// each keeps its shape and their ratio; only the shared clock
    /// stretches or compresses.
    static let arcTimeMin: TimeInterval = 0.44
    static let arcTimeMax: TimeInterval = 0.50
    /// Above-screen destinations extend the SETTLE ONLY (never the dive —
    /// that would lengthen the visible drop and invert the arc's rhythm),
    /// proportionally to how far above the top the slot sits: the climb
    /// then moves at the same visible pace as an on-screen arc's rise.
    static let arcAboveScreenPace: TimeInterval = 0.00055
    static func aboveScreenTime(destinationTop D: CGFloat) -> TimeInterval {
        TimeInterval(max(-D, 0)) * arcAboveScreenPace
    }
    /// A fast flick's climb earns a settle-only extension so its ending
    /// dissolves gently. Ramps in with flick strength (zero at
    /// arcFlickFloor, full at fastFlickVelocity) so the gentle band is
    /// untouched; the dive never changes and the total grows by exactly
    /// the extension. Raise arcFlickFadeExtra for more fade.
    static let arcFlickFadeExtra: TimeInterval = 0.15
    static func arcFlickFadeTime(velocity vy: CGFloat) -> TimeInterval {
        let f = min(max((vy - arcFlickFloor)
            / (fastFlickVelocity - arcFlickFloor), 0), 1)
        return arcFlickFadeExtra * TimeInterval(f * f * (3 - 2 * f))
    }
    /// The dive's minimum share of the pinned total: guarantees the
    /// screen-to-card condense — bound to complete by the pivot — a
    /// workable window on gentle dives; the settle absorbs the remainder.
    static let arcMinDiveShare: TimeInterval = 0.4

    static func arcOvershoot(destinationTop D: CGFloat, velocity vy: CGFloat) -> CGFloat {
        func edge(_ plateau: CGFloat, _ shelf: CGFloat,
                  _ mid: CGFloat, _ steep: CGFloat, _ endHold: CGFloat) -> CGFloat {
            let sigmoid = 1 / (1 + exp((D - mid) / steep))
            let c = min(max((arcCutoffY - D) / arcCliffWidth, 0), 1)
            let cliff = c * c * (3 - 2 * c)
            return endHold + ((shelf + (plateau - shelf) * sigmoid) - endHold) * cliff
        }
        let f = min(max((vy - arcFlickFloor) / (arcFlickCeil - arcFlickFloor), 0), 1)
        let flick = (exp(arcFlickBlendSteep * f) - 1) / (exp(arcFlickBlendSteep) - 1)
        let gentle: CGFloat
        if D > 0 && D < arcGentleJoin {
            let sig1 = 1 / (1 + exp((arcGentleJoin - arcGentleMid) / arcGentleSteep))
            let g0 = arcGentleShelf + (arcGentlePlateau - arcGentleShelf)
                / (1 + exp(-arcGentleMid / arcGentleSteep))
            let g1 = arcGentleShelf + (arcGentlePlateau - arcGentleShelf) * sig1
            let m1 = -(arcGentlePlateau - arcGentleShelf) * sig1 * (1 - sig1) / arcGentleSteep
            let t = D / arcGentleJoin
            let t2 = t * t, t3 = t2 * t
            gentle = (2 * t3 - 3 * t2 + 1) * g0
                + (t3 - 2 * t2 + t) * arcGentleStartSlope * arcGentleJoin
                + (-2 * t3 + 3 * t2) * g1
                + (t3 - t2) * m1 * arcGentleJoin
        } else {
            gentle = edge(arcGentlePlateau, arcGentleShelf, arcGentleMid, arcGentleSteep, 0)
        }
        let hard: CGFloat
        if D > 0 && D < arcHardJoin {
            let sig1 = 1 / (1 + exp((arcHardJoin - arcHardMid) / arcHardSteep))
            let h0 = arcHardShelf + (arcHardPlateau - arcHardShelf)
                / (1 + exp(-arcHardMid / arcHardSteep))
            let h1 = arcHardShelf + (arcHardPlateau - arcHardShelf) * sig1
            let m1 = -(arcHardPlateau - arcHardShelf) * sig1 * (1 - sig1) / arcHardSteep
            let t = D / arcHardJoin
            let t2 = t * t, t3 = t2 * t
            hard = (2 * t3 - 3 * t2 + 1) * h0
                + (t3 - 2 * t2 + t) * arcHardStartSlope * arcHardJoin
                + (-2 * t3 + 3 * t2) * h1
                + (t3 - t2) * m1 * arcHardJoin
        } else {
            hard = edge(arcHardPlateau, arcHardShelf, arcHardMid, arcHardSteep, arcHardEndHold)
        }
        return min(gentle + (hard - gentle) * flick, arcMaxOvershoot)
    }

    /// Slots past arcCutoffY only: a release this fast takes the direct
    /// continuous collapse (momentum fed into the spring's kick) instead of
    /// the standard one — the arc never plays there.
    static let fastFlickVelocity: CGFloat = 1200
    /// The commit flights' mask race: every dismissal flight closes the
    /// reveal on its own quick clock instead of the spring's. It crops the
    /// white chrome plate away in one condense beat, and leaves the landing
    /// spring ~zero mask delta so the spring's overshoot renders instead of
    /// being counter-clipped. A critically-damped spring from rest, over a
    /// duration scaled by how open the mask is at commit, so the condense
    /// reads at one consistent speed.
    static let maskRaceDuration: TimeInterval = 0.3
    /// The arc's return spring.
    /// throwSpringScale: relative stiffness of the metaphorical spring
    /// anchored at the destination. Lower = softer: the same flick carries
    /// deeper (÷√scale), the turnaround arrives later, and the pull home +
    /// settle slow by the same √scale — the whole gesture loosens
    /// coherently. Higher = tighter everything.
    /// throwSettleDuration: the baseline flight-settle length (also paces
    /// the commit: scene undim, shadow).
    /// throwBounceDamping: the landing's character — 1 bounce-free;
    /// overshoot fraction e^{−ζπ/√(1−ζ²)}.
    /// The collapse's spring is built in PHYSICAL units (mass 1, envelope
    /// rate ζω = 6.6/settle × √scale): UIKit's duration+dampingRatio
    /// initializer refits the curve and crushes the amplitude at lower
    /// ratios.
    static let throwSpringScale: CGFloat = 0.1
    static let throwSettleDuration: TimeInterval = 0.11
    static let throwBounceDamping: CGFloat = 1
    /// Effective settle after the spring scale (softer spring = longer).
    static var throwSettle: TimeInterval {
        throwSettleDuration / TimeInterval(max(throwSpringScale, 0.01).squareRoot())
    }
    /// Slow releases return home a touch quicker: the settle shortens
    /// smoothly toward (1 − trim) as the release velocity falls to zero;
    /// at/above the ceiling it is the standard throwSettle unchanged.
    static let arcSlowReturnTrim: CGFloat = 0.2
    static let arcSlowReturnCeil: CGFloat = 250
    /// Every release slower than this (a drag let go, not a flick) skips
    /// the arc machinery entirely and plays the calm continuous morph
    /// straight into place — above the slot, below it, or past the pivot
    /// alike. The dive and the deep-release climb are flick language.
    static let arcSlowMorphCeil: CGFloat = 250
    /// The slow morph's calmer clock: its own flight duration, with the
    /// mask race spanning arcSlowMorphRaceShare of the flight instead of
    /// the quick openness-scaled race. The share stays below the settle's
    /// target-crossing so the landing bounce is never counter-clipped.
    static let arcSlowMorphDuration: TimeInterval = 0.6
    static let arcSlowMorphRaceShare: TimeInterval = 0.6
    static func arcReturnSettle(velocity vy: CGFloat) -> TimeInterval {
        let f = min(max(vy / arcSlowReturnCeil, 0), 1)
        let s = f * f * (3 - 2 * f)
        return throwSettle * TimeInterval(1 - arcSlowReturnTrim * (1 - s))
    }
    /// Lower destinations dismiss progressively quicker (the rubber band's
    /// inverse makes deep targets superlinearly expensive in time): a
    /// smoothstep pace boost, ARC REGIME ONLY — applied to the dive launch
    /// and mildly (√boost) to the return settle. The ≥arcCutoffY morphs
    /// and the X button keep their standard tempo.
    static let arcTravelPace: CGFloat = 0.6
    static let arcTravelPaceStart: CGFloat = 200
    static let arcTravelPaceRamp: CGFloat = 300
    static func travelPaceBoost(destinationTop D: CGFloat) -> CGFloat {
        let t = min(max((D - arcTravelPaceStart) / arcTravelPaceRamp, 0), 1)
        return 1 + arcTravelPace * (t * t * (3 - 2 * t))
    }
    /// Scrim over home while a dismiss drag is live: slightly lighter than
    /// the presented 0.25, acknowledging the grab.
    static let dragScrimAlpha: CGFloat = 0.12
    /// Status-bar hand-off beat: the expanding sheet covers the bar within
    /// the open spring's first stretch, so the bar flips to the profile's
    /// style this long after flight start instead of waiting for the
    /// landing. A mid-open catch inside this beat skips the flip.
    static let statusBarHandOffDelay: TimeInterval = 0.12

    /// Asymptotic rubber band: tracks at ~response·d near zero, saturating at `limit`.
    static func rubberBand(_ d: CGFloat, limit: CGFloat, response: CGFloat) -> CGFloat {
        guard d != 0 else { return 0 }
        let m = abs(d) * response
        return (1 - 1 / (m / limit + 1)) * limit * (d < 0 ? -1 : 1)
    }

    /// Instantaneous slope of rubberBand at distance `d` — the fraction of
    /// the finger's speed the banded offset is actually moving at.
    static func rubberBandSlope(_ d: CGFloat, limit: CGFloat, response: CGFloat) -> CGFloat {
        let u = limit / (abs(d) * response + limit)
        return u * u * response
    }

    /// Distance a touch travelling at `velocity` pt/s would coast — the same
    /// projection behind SwiftUI's `predictedEndTranslation`.
    static func projectedTravel(_ velocity: CGFloat) -> CGFloat {
        velocity / 1000 * 0.998 / (1 - 0.998)
    }

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    static func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
        CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
               width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
    }
}

// MARK: - Host controller (the presenting side)

final class ZoomHostController: UIViewController {

    /// The overlay container presentations run in (set by ZoomRootController).
    weak var rootController: ZoomRootController?

    private let contentHost: UIHostingController<AnyView>
    private let titleText: String?
    /// Registered `.zoomTransition` sources, in registration order.
    private var sources: [Weak<ZoomSourceMarkerView>] = []
    /// The source whose card the current presentation morphs around. The
    /// marker VIEW can be remounted by a covered-home re-render (the weak
    /// pointer dies), but the card's STATE object survives remounts — the
    /// accessor recovers the replacement by state IDENTITY (=== is exact),
    /// so setCardHidden/cardFrame/landing adoption never no-op against a
    /// dead pointer.
    private weak var activeSourceView: ZoomSourceMarkerView?
    private weak var activeSourceState: ZoomSourceState?
    var activeSource: ZoomSourceMarkerView? {
        get {
            if let v = activeSourceView { return v }
            guard let st = activeSourceState,
                  let revived = sources.compactMap(\.value).first(where: { $0.state === st })
            else { return nil }
            activeSourceView = revived
            return revived
        }
        set {
            activeSourceView = newValue
            activeSourceState = newValue?.state
        }
    }

    init(root: AnyView, title: String?) {
        contentHost = UIHostingController(rootView: root)
        titleText = title
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        // A real, fully system-managed large title: presentations never
        // touch the bar, so its scroll-collapse/blur behavior stays stock.
        if let titleText {
            navigationItem.title = titleText
            navigationItem.largeTitleDisplayMode = .always
        }

        addChild(contentHost)
        contentHost.view.backgroundColor = .clear
        contentHost.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentHost.view)
        NSLayoutConstraint.activate([
            contentHost.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentHost.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentHost.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentHost.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        contentHost.didMove(toParent: self)
    }

    // MARK: Source registry

    func register(_ marker: ZoomSourceMarkerView) {
        sources.removeAll { $0.value == nil || $0.value === marker }
        sources.append(Weak(marker))
    }

    func unregister(_ marker: ZoomSourceMarkerView) {
        sources.removeAll { $0.value == nil || $0.value === marker }
    }

    /// The tapped card's frame in `view` coordinates — the morph's start rect.
    var cardFrame: CGRect {
        guard let marker = activeSource else { return .zero }
        return marker.convert(marker.bounds, to: view)
    }

    /// The interactive dismiss hides the card for its whole duration so the
    /// dragged detail content is the only copy of it on screen. Unhiding
    /// bridges SwiftUI's async re-render with a UIKit landing overlay; the
    /// resting shadow swaps with the flight's rig in the same runloop turn —
    /// one CA transaction, no gap and no double-composite.
    func setCardHidden(_ hidden: Bool) {
        guard let marker = activeSource else { return }
        if !hidden { marker.showLandingOverlay() }
        marker.restingShadow.alpha = hidden ? 0 : 1
        marker.state?.isHidden = hidden
    }

    // MARK: Present (forwarded to the overlay root)

    func push(from marker: ZoomSourceMarkerView) {
        rootController?.present(from: marker)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if DEBUG
        autoDriveIfRequested()
        #endif
    }

    #if DEBUG
    // Headless transition validation: the simulator offers no touch
    // injection, so launch arguments drive the morph instead.
    //   -morphSlowMotion  runs the window's layer clock at 1/10 speed so
    //                     `simctl io screenshot` bursts catch mid-flight frames
    //   -morphAutoOpen    taps the first registered card 1s after launch
    //   -morphAutoClose   then drives the Back-button pop
    //   -morphCancelDance deep-drag + cancel gesture before the pop
    //   -morphOpenCatchDance  seize the OPEN mid-flight, scrub, cancel
    //   -morphOpenCatchDismissDance  seize the open, then flick-dismiss
    //   -morphCatchDance  flick-dismiss, catch mid-air, cancel, then pop
    //   -morphFastFlickDance  hard-flick dismiss (the expansive fast path)
    //   -morphThrowCatchDance hard flick, catch mid-dive, cancel, then pop
    //   -morphScrollFirst  scroll home 400pt down before the auto-open
    //   -morphScrollY N    override the pre-scroll distance (default 400)
    //   -morphSourceIndex N  open the Nth registered card (default 0) —
    //                     low-slot flights need a card deeper in the scroll
    //   -morphFlickDragY N  fast-flick dance's pre-flick scrub (default 60)
    private var didArmAutoDrive = false

    private func autoDriveIfRequested() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-morphSlowMotion") { view.window?.layer.speed = 0.1 }
        guard args.contains("-morphAutoOpen"), !didArmAutoDrive else { return }
        didArmAutoDrive = true
        if args.contains("-morphScrollFirst") {
            // Scroll the home down before opening, to validate the
            // inline-title/blur states through flights.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self else { return }
                func findScroll(_ v: UIView) -> UIScrollView? {
                    if let sv = v as? UIScrollView { return sv }
                    for sub in v.subviews { if let f = findScroll(sub) { return f } }
                    return nil
                }
                if let scroll = findScroll(view) {
                    // double(forKey:) coerces the launch-arg string; 0 = unset.
                    let override = UserDefaults.standard.double(forKey: "morphScrollY")
                    let dy = override != 0 ? override : 400
                    scroll.setContentOffset(
                        CGPoint(x: 0, y: scroll.contentOffset.y + dy), animated: false)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            let index = UserDefaults.standard.integer(forKey: "morphSourceIndex")
            let list = sources.compactMap(\.value)
            guard let marker = list.indices.contains(index) ? list[index] : list.first
            else { return }
            push(from: marker)
        }
        if args.contains("-morphOpenCatchDance") || args.contains("-morphOpenCatchDismissDance") {
            // Push fires at +1s; with -morphSlowMotion the 0.4s open runs
            // ~4s wall — catch it ~40% in.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
                self?.rootController?.presentedDetail?.debugOpenCatchDance(
                    dismiss: args.contains("-morphOpenCatchDismissDance"))
            }
        }
        if args.contains("-morphCancelDance") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak self] in
                self?.rootController?.presentedDetail?.debugCancelDance()
            }
        }
        if args.contains("-morphCatchDance") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak self] in
                self?.rootController?.presentedDetail?.debugCatchDance()
            }
        }
        if args.contains("-morphFastFlickDance") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak self] in
                self?.rootController?.presentedDetail?.debugFastFlickDance()
            }
        }
        if args.contains("-morphThrowCatchDance") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak self] in
                self?.rootController?.presentedDetail?.debugThrowCatchDance()
            }
        }
        if args.contains("-morphAutoClose") {
            let closeDelay: TimeInterval = args.contains("-morphCatchDance") ? 16
                : args.contains("-morphThrowCatchDance") ? 16
                : args.contains("-morphFastFlickDance") ? 16 // after the dismissal lands (no-op pop)
                : args.contains("-morphCancelDance") ? 14 : 8
            DispatchQueue.main.asyncAfter(deadline: .now() + closeDelay) { [weak self] in
                self?.rootController?.presentedDetail?.requestDismiss()
            }
        }
    }

    #endif
}

private struct Weak<T: AnyObject> {
    weak var value: T?
    init(_ value: T) { self.value = value }
}

// MARK: - Hero container

/// The UIKit-owned hero band that `ImageCarousel()` places inline in the
/// user's SwiftUI layout. SwiftUI always sees the RESTING crop size; the
/// flight crop is realized by the page images overflowing the container
/// downward (the crop's top edge stays put), so the crop morph animates on
/// the UIKit spring clock inside a layout SwiftUI never re-solves mid-flight.
final class ZoomHeroContainer: UIView {

    let carousel = UIScrollView()
    private(set) var pageImages: [UIImageView] = []
    private var flightConstraints: [NSLayoutConstraint] = []
    private var restingConstraints: [NSLayoutConstraint] = []

    private let aspect: CGFloat

    init(images: [UIImage], sourceAspect: CGFloat) {
        aspect = sourceAspect
        super.init(frame: .zero)
        // Overflow must draw: nothing between the image views and the
        // hosting view may clip. The image views themselves DO clip — that
        // crop IS the hero crop.
        clipsToBounds = false
        carousel.clipsToBounds = false
        carousel.isPagingEnabled = true
        carousel.showsHorizontalScrollIndicator = false
        carousel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(carousel)

        let pages = UIStackView()
        pages.axis = .horizontal
        pages.spacing = 0
        pages.translatesAutoresizingMaskIntoConstraints = false
        carousel.addSubview(pages)

        NSLayoutConstraint.activate([
            carousel.topAnchor.constraint(equalTo: topAnchor),
            carousel.bottomAnchor.constraint(equalTo: bottomAnchor),
            carousel.leadingAnchor.constraint(equalTo: leadingAnchor),
            carousel.trailingAnchor.constraint(equalTo: trailingAnchor),

            pages.topAnchor.constraint(equalTo: carousel.contentLayoutGuide.topAnchor),
            pages.bottomAnchor.constraint(equalTo: carousel.contentLayoutGuide.bottomAnchor),
            pages.leadingAnchor.constraint(equalTo: carousel.contentLayoutGuide.leadingAnchor),
            pages.trailingAnchor.constraint(equalTo: carousel.contentLayoutGuide.trailingAnchor),
            pages.heightAnchor.constraint(equalTo: carousel.frameLayoutGuide.heightAnchor),
        ])

        for image in images {
            let page = UIView()
            page.clipsToBounds = false
            let iv = UIImageView(image: image)
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = ZoomStyle.cornerRadius
            iv.layer.cornerCurve = .continuous
            iv.translatesAutoresizingMaskIntoConstraints = false

            // The curtain: while the flight crop is active, sibling SwiftUI
            // content sits partially inside the crop band and would peek
            // below the image's edge as sliced text. This background-colored
            // strip covers the band; it fades with the flight springs.
            let curtain = UIView()
            curtain.backgroundColor = .systemBackground
            curtain.translatesAutoresizingMaskIntoConstraints = false
            page.addSubview(curtain)
            page.addSubview(iv)
            pages.addArrangedSubview(page) // must precede the cross-hierarchy width constraint

            let leading = iv.leadingAnchor.constraint(equalTo: page.leadingAnchor, constant: ZoomStyle.detailInset)
            let trailing = iv.trailingAnchor.constraint(equalTo: page.trailingAnchor, constant: -ZoomStyle.detailInset)
            leadingInsets.append(leading)
            trailingInsets.append(trailing)
            NSLayoutConstraint.activate([
                leading, trailing,
                iv.topAnchor.constraint(equalTo: page.topAnchor),
                page.widthAnchor.constraint(equalTo: carousel.frameLayoutGuide.widthAnchor),

                curtain.topAnchor.constraint(equalTo: iv.bottomAnchor),
                curtain.leadingAnchor.constraint(equalTo: page.leadingAnchor),
                curtain.trailingAnchor.constraint(equalTo: page.trailingAnchor),
                curtain.heightAnchor.constraint(equalToConstant: 1200),
            ])
            // The crop, per state: resting fills the container; flight is the
            // source card's aspect, extending DOWNWARD past the container.
            restingConstraints.append(iv.bottomAnchor.constraint(equalTo: page.bottomAnchor))
            flightConstraints.append(iv.heightAnchor.constraint(
                equalTo: iv.widthAnchor, multiplier: sourceAspect))
            pageImages.append(iv)
            curtains.append(curtain)
        }
        // Born in flight crop; the animator swaps it mid-spring.
        NSLayoutConstraint.activate(flightConstraints)
        setProminent(true)
    }

    private var curtains: [UIView] = []
    private var leadingInsets: [NSLayoutConstraint] = []
    private var trailingInsets: [NSLayoutConstraint] = []

    /// Animatable: 1 while a flight crop owns the hero (content beneath is
    /// veiled), 0 at rest and through drags (the live screen shows normally).
    func setCurtainAlpha(_ alpha: CGFloat) {
        curtains.forEach { $0.alpha = alpha }
    }

    /// Marks the page layout dirty so an ANIMATED layoutIfNeeded can carry
    /// a caught open's mid-crop frames back to the active constraint set
    /// (setCrop no-ops when the constraint set is already right, and a
    /// clean tree gives layoutIfNeeded nothing to re-solve).
    func setNeedsCropLayout() {
        pageImages.forEach { $0.superview?.setNeedsLayout() }
    }

    /// ImageCarousel's per-instance page padding (screen edge → image edge).
    func setHorizontalPadding(_ p: CGFloat) {
        leadingInsets.forEach { $0.constant = p }
        trailingInsets.forEach { $0.constant = -p }
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    var isFlightCrop: Bool { flightConstraints.first?.isActive == true }

    /// The hosting view: the prominence walk stops here (exclusive).
    weak var prominenceBoundary: UIView?
    private var prominent = false

    func setCrop(flight: Bool) {
        // A live crop SCRUB (the dive's clock) hands off here: clear it
        // and land directly on the requested constraint set.
        if !scrubConstraints.isEmpty {
            NSLayoutConstraint.deactivate(scrubConstraints)
            scrubConstraints.removeAll()
            NSLayoutConstraint.activate(flight ? flightConstraints : restingConstraints)
            if flight { setProminent(true) }
            return
        }
        guard isFlightCrop != flight else { return }
        NSLayoutConstraint.deactivate(flight ? restingConstraints : flightConstraints)
        NSLayoutConstraint.activate(flight ? flightConstraints : restingConstraints)
        if flight { setProminent(true) } // resting prominence is dropped at landing
    }

    private var scrubConstraints: [NSLayoutConstraint] = []

    /// Scrubs the crop morph on the DIVE'S OWN CLOCK — plain model writes
    /// each tick, no CA animation (a render-server crop interpolates one
    /// frame out of phase with the model writes; the card then isn't rigid
    /// frame-to-frame). fraction: 0 = resting crop, 1 = flight crop; any
    /// setCrop(flight:) call clears the scrub and takes over.
    func setCropScrub(_ fraction: CGFloat) {
        if scrubConstraints.isEmpty {
            NSLayoutConstraint.deactivate(flightConstraints)
            NSLayoutConstraint.deactivate(restingConstraints)
            scrubConstraints = pageImages.map {
                let c = $0.heightAnchor.constraint(equalToConstant: 0)
                c.isActive = true
                return c
            }
            setProminent(true) // the scrubbed crop overflows like the flight's
        }
        let resting = bounds.height
        for (i, c) in scrubConstraints.enumerated() {
            let flightHeight = pageImages[i].bounds.width * aspect
            c.constant = resting + (flightHeight - resting) * fraction
        }
        layoutIfNeeded()
    }

    /// While overflowing, the hero must draw ABOVE later SwiftUI siblings.
    /// zPosition only competes between siblings of one parent, so the
    /// elevation is applied along the WHOLE ancestor chain up to the
    /// hosting view: at whichever level the hero branch and the sibling
    /// content split, the hero side wins. At rest the elevation is dropped
    /// so user overlays stack naturally again.
    func setProminent(_ p: Bool) {
        prominent = p
        applyProminence()
    }

    private func applyProminence() {
        var v: UIView? = self
        while let cur = v, cur !== prominenceBoundary {
            cur.layer.zPosition = prominent ? 1 : 0
            v = cur.superview
        }
    }

    // The wrapper chain doesn't exist at init, and SwiftUI may rebuild
    // wrappers or reset layer state on its own passes — re-assert whenever
    // the hierarchy or layout changes.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyProminence()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyProminence()
    }
}

// MARK: - Detail controller (the presented screen)

final class ZoomDetailController: UIViewController {

    private let scrollView = UIScrollView()
    private let heroContainer: ZoomHeroContainer
    private var carousel: UIScrollView { heroContainer.carousel }
    private var pageImages: [UIImageView] { heroContainer.pageImages }

    let images: [UIImage]
    /// The source card's aspect, measured at push — the flight crop.
    let sourceAspect: CGFloat
    private let detailHost: UIHostingController<AnyView>

    /// Drives the overlay presentation and its gesture dismissal.
    let dismissController = MorphDismissController()
    private let dismissPan = UIPanGestureRecognizer()

    // Drag state machine.
    private enum Axis { case vertical, horizontal }
    private var dragAxis: Axis?
    private var dragging = false
    private var landed = false // Only a landed screen is grabbable

    init(images: [UIImage], sourceAspect: CGFloat, detailContent: AnyView) {
        self.images = images
        self.sourceAspect = sourceAspect
        let hero = ZoomHeroContainer(images: images, sourceAspect: sourceAspect)
        heroContainer = hero
        detailHost = UIHostingController(rootView: AnyView(EmptyView()))
        super.init(nibName: nil, bundle: nil)
        // The user's builder IS the screen; ImageCarousel() inside it resolves
        // to this controller's hero container, and zoomDismiss runs the same
        // catchable morph pop the Back button drives.
        detailHost.rootView = AnyView(
            detailContent
                .environment(\.zoomHeroContainer, hero)
                .environment(\.zoomDismiss, ZoomDismissAction { [weak self] in
                    self?.programmaticDismiss()
                }))
    }

    /// Programmatic dismissal (the X button / zoomDismiss). Ignored while a
    /// flight or drag already owns the screen, or before the open has landed.
    private func programmaticDismiss() {
        guard landed, !dismissController.isInteracting else { return }
        dismissController.dismissProgrammatically()
    }

    /// Internal entry for the DEBUG harness.
    func requestDismiss() { programmaticDismiss() }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    /// The profile's top is systemBackground: .default re-adapts the bar
    /// the moment the profile takes status-bar authority
    /// (ZoomRootController.childForStatusBarStyle).
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        dismissController.detail = self
        dismissPan.addTarget(self, action: #selector(handleDismissPan))
        dismissPan.delegate = self
        view.addGestureRecognizer(dismissPan)

        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        // The detail bar is invisible chrome, but automatic adjustment would
        // still reserve its height — content pins to the top SAFE AREA
        // instead (applyTopInset); bar chrome floats over content.
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)

        addChild(detailHost)
        heroContainer.prominenceBoundary = detailHost.view
        detailHost.view.backgroundColor = .clear
        detailHost.sizingOptions = .intrinsicContentSize
        // The library owns the top clearance (applyTopInset). Without this,
        // the hosting view ALSO pads the content by its own propagated safe
        // area — doubling the gap.
        detailHost.safeAreaRegions = []
        detailHost.view.translatesAutoresizingMaskIntoConstraints = false
        // The hero's flight-crop overflow must not be clipped by the hosting
        // view or the scroll container.
        detailHost.view.clipsToBounds = false
        scrollView.clipsToBounds = false
        scrollView.addSubview(detailHost.view)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            detailHost.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            detailHost.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            detailHost.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            detailHost.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            detailHost.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
        detailHost.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyTopInset()
    }

    /// Status-bar-only clearance: the WINDOW's safe area top, not the view's
    /// (which includes the invisible navigation bar).
    private var didPinInitialOffset = false
    private func applyTopInset() {
        let top = view.window?.safeAreaInsets.top ?? view.safeAreaInsets.top
        guard scrollView.contentInset.top != top else { return }
        scrollView.contentInset.top = top
        scrollView.verticalScrollIndicatorInsets.top = top
        // Pin to the top only on FIRST layout: later safe-area changes
        // must not teleport a scrolled reader.
        if !didPinInitialOffset {
            didPinInitialOffset = true
            scrollView.contentOffset.y = -top
        }
    }

    /// The `landed` interactivity latch, driven explicitly by the flight
    /// completions — as an overlay child there are no navigation appearance
    /// callbacks to ride. Settles the hero to its resting state.
    func markLanded() {
        setHeroCrop(flight: false)
        setHeroCurtain(0)
        // At rest the hero no longer overflows, so it rejoins normal
        // sibling stacking.
        heroContainer.setProminent(false)
        landed = true
    }

    /// A dismissal owns the screen: only a catch may re-grab it.
    func markInFlight() { landed = false }

    /// Whether the open has landed and the screen is at interactive rest.
    var isLanded: Bool { landed }

    /// Whether the vertical scroll sits at (or within a hair of) its top.
    var isScrolledToTop: Bool {
        scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 2
    }

    /// Animated glide to the top, for programmatic dismissals from depth —
    /// the morph anchors on the hero, which must be back on screen.
    func glideToTop(then completion: @escaping () -> Void) {
        let top = CGPoint(x: 0, y: -scrollView.adjustedContentInset.top)
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
            self.scrollView.contentOffset = top
        } completion: { _ in completion() }
    }

    // MARK: Morph hooks (used by the present morph and the dismissal flights)

    /// The first carousel page image's frame in `view` coordinates.
    func heroImageFrame() -> CGRect {
        view.layoutIfNeeded()
        return pageImages[0].convert(pageImages[0].bounds, to: view)
    }

    /// The hero image's RESTING height — valid under either active crop,
    /// without forcing a layout pass that would defeat the animated crop swap.
    var heroRestingHeight: CGFloat { heroContainer.bounds.height }

    /// The image on the currently visible carousel page — the one that flies
    /// home on an interactive dismiss.
    var currentPageImageView: UIImageView { pageImages[currentPageIndex()] }

    /// Page 1's content, which a close-from-page-N fades into mid-flight.
    var firstPageContent: UIImage? { images.first }

    func currentPageIndex() -> Int {
        let width = max(carousel.bounds.width, 1)
        return min(max(Int(round(carousel.contentOffset.x / width)), 0), pageImages.count - 1)
    }

    /// The current page image's frame in `view` coordinates (resting crop).
    func currentHeroFrame() -> CGRect {
        view.layoutIfNeeded()
        let iv = currentPageImageView
        return iv.convert(iv.bounds, to: view)
    }

    /// Swaps the hero's active crop constraints. Call inside an animation
    /// block (followed by `layoutIfNeeded`) to animate the crop morph.
    func setHeroCrop(flight: Bool) {
        heroContainer.setCrop(flight: flight)
    }

    /// Animatable curtain over sibling content beneath the hero's crop band.
    func setHeroCurtain(_ alpha: CGFloat) {
        heroContainer.setCurtainAlpha(alpha)
    }

    /// See ZoomHeroContainer.setNeedsCropLayout — the caught-open arm uses
    /// this so the grab beat's animated layout re-solves the folded crop.
    func setHeroNeedsCropLayout() {
        heroContainer.setNeedsCropLayout()
    }

    /// Per-tick crop scrub on the dive's clock (ZoomHeroContainer.setCropScrub).
    func setHeroCropScrub(_ fraction: CGFloat) {
        heroContainer.setCropScrub(fraction)
    }

    /// Deadens the destination content's touches for the open flight: the
    /// catchable open must not deliver mid-flight taps to controls
    /// hit-tested at their final full-screen geometry. The dismiss pan
    /// lives on the controller's root view, so catching stays live.
    func setContentTouchesEnabled(_ enabled: Bool) {
        detailHost.view.isUserInteractionEnabled = enabled
    }

    // MARK: Dismiss drag

    @objc private func handleDismissPan(_ pan: UIPanGestureRecognizer) {
        // Translation/velocity are read in WINDOW space (in: nil): the detail
        // view is the view being scaled by the drag, so measuring in it would
        // inflate the reported travel by 1/scale as the drag deepens.
        switch pan.state {
        case .changed:
            let t = pan.translation(in: nil)
            if dragAxis == nil {
                let vertical = abs(t.y) >= abs(t.x)
                let atTop = scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 1
                let canBegin = landed && !dragging && t.y > 0 && atTop

                if vertical, dismissController.catchFlight() {
                    // A flight in progress is catchable: seize it and
                    // continue as a live drag from the caught pose. Bypasses
                    // canBegin — `landed` is false mid-pop, and the scroll
                    // gates don't apply to a card that is already flying.
                    dragAxis = .vertical
                    dragging = true
                    // Zero the pan's ~10pt recognition slop so the pose
                    // departs from the caught frame under the finger — the
                    // regrab blend starts at exactly w = 0.
                    pan.setTranslation(.zero, in: nil)
                    return
                } else if vertical && canBegin {
                    dragAxis = .vertical
                    beginDrag()
                    // Same slop-zeroing on a fresh grab: the card departs
                    // from rest instead of popping the slop down in a frame.
                    pan.setTranslation(.zero, in: nil)
                    return
                } else {
                    dragAxis = .horizontal // Voided: horizontal belongs to the pager
                }
            }
            guard dragAxis == .vertical, dragging else { return }
            dismissController.updateDrag(translation: t)
        case .ended, .cancelled, .failed:
            let owned = dragAxis == .vertical && dragging
            dragAxis = nil
            guard owned else { return }
            // A pan the SYSTEM took away (Control Center, app switcher,
            // lock, incoming call) is not a release — never dismiss on it.
            endDrag(translation: pan.translation(in: nil),
                    velocity: pan.velocity(in: nil),
                    systemCancelled: pan.state != .ended)
        default:
            break
        }
    }

    private func beginDrag() {
        dragging = true
        prepareForCollapse()
        dismissController.beginDrag()
    }

    /// Settle the geometry the collapse flies from: pin the vertical scroll
    /// to its exact top (a grab or Back tap can land mid-bounce) and
    /// snap+freeze the carousel on its current page. Shared by the drag and
    /// the Back-button pop. Idempotent.
    func prepareForCollapse() {
        scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.adjustedContentInset.top), animated: false)
        // Freeze the vertical scroll for the rest of the touch, not just its
        // offset: its pan tracks simultaneously with the dismiss drag, and a
        // release flick would hand it deceleration that outlives the pinned
        // flight. Disabling mid-touch cancels the tracking; endDrag
        // re-enables on cancel.
        scrollView.isScrollEnabled = false
        let page = currentPageIndex()
        carousel.setContentOffset(CGPoint(x: CGFloat(page) * carousel.bounds.width, y: 0), animated: false)
        carousel.isScrollEnabled = false
    }

    /// Re-enables the scrolls prepareForCollapse froze — the open landing's
    /// counterpart to the drag-cancel completion's re-enable.
    func unfreezeScrolls() {
        scrollView.isScrollEnabled = true
        carousel.isScrollEnabled = true
    }

    #if DEBUG
    /// Replays the mid-air catch headlessly: flick-dismiss, seize the commit
    /// flight partway (catchFlight), scrub briefly, release below threshold —
    /// the caught pop must cancel cleanly back to fully presented.
    func debugCatchDance() {
        beginDrag()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            dismissController.updateDrag(translation: CGPoint(x: 0, y: 80))
            // Below fastFlickVelocity: this dance catches the STANDARD
            // collapse; debugThrowCatchDance covers the fast path's carry.
            endDrag(translation: CGPoint(x: 0, y: 80),
                    velocity: CGPoint(x: 0, y: 1000), systemCancelled: false)
            // With -morphSlowMotion the commit flight runs ~4.5s; catch at ~1/3.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
                guard dismissController.catchFlight() else { return }
                dragging = true
                dismissController.updateDrag(translation: CGPoint(x: 0, y: 30))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                    endDrag(translation: CGPoint(x: 0, y: 30),
                            velocity: .zero, systemCancelled: false)
                }
            }
        }
    }

    /// Replays the bug-report gesture headlessly: grab, scrub deep, scrub
    /// back up, release below threshold — a cancelled dismiss. Scrubs are
    /// instant transform writes; only the cancel spring is affected by
    /// -morphSlowMotion.
    func debugCancelDance() {
        beginDrag()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            dismissController.updateDrag(translation: CGPoint(x: 0, y: 260))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [self] in
                dismissController.updateDrag(translation: CGPoint(x: 0, y: 40))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                    endDrag(translation: CGPoint(x: 0, y: 40), velocity: .zero, systemCancelled: false)
                }
            }
        }
    }

    /// Replays a hard downward flick headlessly: shallow grab, release above
    /// fastFlickVelocity — must take the fast path.
    func debugFastFlickDance() {
        beginDrag()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            // -morphFlickDragY N scrubs deeper before the flick (default 60);
            // -morphFlickVelocity N overrides the release speed (default
            // 2200) — the arc's depth band is velocity-modulated, so the
            // harness must drive both edges. double(forKey:) coerces the
            // launch-arg string; 0 = unset.
            let override = UserDefaults.standard.double(forKey: "morphFlickDragY")
            let y = override != 0 ? override : 60
            let vOverride = UserDefaults.standard.double(forKey: "morphFlickVelocity")
            let vy = vOverride != 0 ? vOverride : 2200
            dismissController.updateDrag(translation: CGPoint(x: 0, y: y))
            endDrag(translation: CGPoint(x: 0, y: y),
                    velocity: CGPoint(x: 0, y: vy), systemCancelled: false)
        }
    }

    /// Catches the OPEN morph mid-flight, scrubs briefly, then releases —
    /// below threshold (the caught open must resolve as a cancelled
    /// dismissal, finishing the presentation) or, with `dismiss`, as a
    /// hard flick (the caught open must fly home and land pixel-exact).
    func debugOpenCatchDance(dismiss: Bool) {
        guard dismissController.catchFlight() else { return }
        dragging = true
        dismissController.updateDrag(translation: CGPoint(x: 0, y: 40))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            endDrag(translation: CGPoint(x: 0, y: 40),
                    velocity: dismiss ? CGPoint(x: 0, y: 2200) : .zero,
                    systemCancelled: false)
        }
    }

    /// Catches the fast path mid-DIVE (the ride-down beat), scrubs, and
    /// releases below threshold — must cancel back to fully presented, the
    /// same contract as catching the collapse (debugCatchDance).
    func debugThrowCatchDance() {
        beginDrag()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            dismissController.updateDrag(translation: CGPoint(x: 0, y: 60))
            endDrag(translation: CGPoint(x: 0, y: 60),
                    velocity: CGPoint(x: 0, y: 2200), systemCancelled: false)
            // With -morphSlowMotion the throw dive runs ~1.2s; catch inside it.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [self] in
                guard dismissController.catchFlight() else { return }
                dragging = true
                dismissController.updateDrag(translation: CGPoint(x: 0, y: 30))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                    endDrag(translation: CGPoint(x: 0, y: 30),
                            velocity: .zero, systemCancelled: false)
                }
            }
        }
    }
    #endif

    private func endDrag(translation t: CGPoint, velocity v: CGPoint, systemCancelled: Bool) {
        let progress = min(max(t.y / DragTuning.collapseDistance, 0), 1)
        // flick = the distance the touch would coast from its release velocity.
        let flick = DragTuning.projectedTravel(v.y)
        if !systemCancelled, progress > DragTuning.dismissThreshold || (t.y > 20 && flick > 90) {
            dragging = false
            dismissController.finishDismiss(translation: t, velocity: v)
        } else {
            dismissController.cancelDismiss(velocity: v) { [weak self] in
                guard let self else { return }
                dragging = false
                scrollView.isScrollEnabled = true
                carousel.isScrollEnabled = true
            }
        }
    }
}

extension ZoomDetailController: UIGestureRecognizerDelegate {
    // The dismiss pan observes alongside the scroll views' own pans; the
    // axis lock and scroll-top gate decide who owns any given drag.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

extension ZoomDetailController: UIScrollViewDelegate {
    // While a dismiss drag or its release flight owns the screen, the
    // vertical scroll stays pinned to its top so the screen moves as one
    // piece — isInteracting outlives `dragging` through the close flight.
    func scrollViewDidScroll(_ sv: UIScrollView) {
        guard sv === scrollView, dragging || dismissController.isInteracting else { return }
        let top = -sv.adjustedContentInset.top
        if sv.contentOffset.y != top { sv.contentOffset = CGPoint(x: 0, y: top) }
    }
}

// MARK: - Display corner estimate

/// Public-API estimate of the physical display's corner radius, which UIKit
/// does not expose. The reveal's corners animate to this value so they land
/// concentric with the screen's own — making the mask's removal at
/// completion invisible. Safe-area extents identify the hardware class;
/// unknown future rounded devices fall back to the modern 55pt.
private func estimatedDisplayCornerRadius(around view: UIView) -> CGFloat {
    let insets = view.window?.safeAreaInsets ?? view.safeAreaInsets
    guard insets.bottom > 0 else { return 0 } // home-button device: square display
    // iPads: modern home-indicator models use ~18pt display corners; the
    // iPhone edge-class table below would misread them as 55.
    if UIDevice.current.userInterfaceIdiom == .pad { return 18 }
    let edge = max(insets.top, insets.left, insets.right)
    switch edge {
    case 62...: return 62       // 16 Pro / 17 class
    case 59..<62: return 55     // Dynamic Island / 14 Pro–16 class
    case 47..<59: return 47.33  // notch class (12–14)
    case 44..<47: return 39     // X / XS / 11 Pro class
    default: return 55
    }
}

// MARK: - Interactive dismiss

/// Owns the overlay presentation scene and drives every flight in it: the
/// open morph, the gesture-following dismissal (manipulated frame-by-frame
/// from the drag — not a percent scrub), release/cancel springs from
/// wherever the finger let go, and the programmatic (X-button) collapse.
/// The scene — scrim over the WHOLE nav view (bar included), receded home
/// plane, shadow host wrapping the masked detail — is built once at
/// presentation and persists until a dismissal lands, so dismissals arm
/// instantly. Every flight runs on a property animator, so a new touch can
/// seize the card mid-air (catchFlight). No UIKit transition machinery is
/// involved: the navigation bar is never told anything happened.
final class MorphDismissController: NSObject {

    weak var detail: ZoomDetailController?
    /// True from dismissal-begin (drag or programmatic) until it lands or
    /// cancels back to presented.
    private(set) var isInteracting = false

    private weak var root: ZoomRootController?
    private weak var home: ZoomHostController?
    /// The receding plane: the whole navigation controller's view, BAR
    /// INCLUDED — scaling it keeps the real title pinned to the home.
    private weak var homeView: UIView?
    private weak var detailView: UIView?
    private var scrim: UIView?
    private var shadowHost: UIView?
    private var maskView: UIView?
    private var sourceRect = CGRect.zero  // home card, root coords
    private var presentSourceRect = CGRect.zero // landing fallback if the card unmounts
    /// The hero's RESTING frame in detail coords, recorded at present time:
    /// a caught open arms the drag rule from this without forcing a layout
    /// pass mid-grab.
    private var presentRestingHeroRect = CGRect.zero
    /// The home scroll's offset at presentation: scaling the nav plane can
    /// drift its adjusted insets — re-pinned at rest and before landing
    /// measurement so the home's scroll position is provably preserved.
    private weak var homeScroll: UIScrollView?
    private var homeOffset = CGPoint.zero

    /// The recede, top-pinned: a plain center-anchored scale would move the
    /// nav plane's top edge down in window space, re-slicing the safe area
    /// (bar metrics and home scroll insets then drift by that amount).
    /// The compensating upward translation keeps the top edge glued to the
    /// screen top, so the bar's geometry is invariant through every recede.
    private func recedeTransform(_ k: CGFloat) -> CGAffineTransform {
        let h = homeView?.bounds.height ?? 0
        return CGAffineTransform(translationX: 0, y: -h * (1 - k) / 2)
            .scaledBy(x: k, y: k)
    }

    /// The top-pinned recede vacates height×(1−0.94) at the plane's bottom
    /// edge; growing the canvas to height/0.94 for the whole presentation
    /// lets it render that strip, so no content is cut off there. Only call
    /// with the transform at identity — setting frame under a live
    /// transform is undefined.
    private func setHomeCanvas(grown: Bool) {
        guard let root, let homeView else { return }
        let bounds = root.view.bounds
        let target = grown
            ? CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height / 0.94)
            : bounds
        guard homeView.frame != target else { return }
        homeView.frame = target
        homeView.layoutIfNeeded()
    }

    /// Re-fits the persistent scene after a container size change while at
    /// presented REST. Flights measure at arm time; mid-flight size changes
    /// are explicitly unsupported.
    private var lastRestSize = CGSize.zero
    func refreshRestGeometry() {
        guard let root, scrim != nil, !isInteracting,
              detail?.isLanded == true, let homeView else { return }
        let size = root.view.bounds.size
        guard size != lastRestSize else { return }
        lastRestSize = size
        homeView.transform = .identity
        setHomeCanvas(grown: true)
        homeView.transform = recedeTransform(0.94)
        pinHomeOffset()
    }

    private func pinHomeOffset() {
        guard let homeScroll, homeScroll.contentOffset != homeOffset else { return }
        homeScroll.setContentOffset(homeOffset, animated: false)
        homeScroll.layoutIfNeeded()
    }
    private var heroRect = CGRect.zero    // current page image, detail coords, resting crop
    private var anchor = CGPoint.zero     // drag scaling anchor: the image's center
    private var displayRadius: CGFloat = 0 // mask corners at full-screen

    // The card's overlay chrome, hosted ABOVE the flying detail at the
    // card's resting slot: alpha 0 through the drag, fading in with the
    // collapse spring, back out on cancel/catch.
    private var sceneOverlayHost: UIHostingController<AnyView>?
    // The LANDING shadow rig: the resting-shadow stack RIDING THE FLYING
    // CARD through commit flights. Slot-anchored fades ring the still-empty
    // slot (a phantom "card background"); anchored to the card there is
    // nothing to ring, by construction. Same class as the marker's
    // instance, so the landed rendering is identical and the completion
    // swaps rig → marker in ONE CA transaction. Deliberately cheap:
    // transform-driven against fixed shadowPaths — the spring animates it
    // inside the card's own animator (matched endpoints, same curve →
    // exact tracking), and the dive adds one transform write per tick.
    private var landingShadowRig: CardRestingShadowView?

    /// Installs the landing chrome copy and shadow rig at the card's
    /// resting slot geometry, above the flying detail. Alpha 0 through the
    /// drag; a commit seeds their shared transform on the flying window and
    /// they ride the card home (updateLandingRigs), fading in across the
    /// whole flight; cancel/catch retreat the alpha; the landing adopts the
    /// chrome as a bridge. Shared by the dismissal arm and the caught-open
    /// arm.
    private func installCardChrome() {
        guard let root, let marker = home?.activeSource else { return }
        let rig = CardRestingShadowView(frame: sourceRect)
        rig.alpha = 0
        if let shadowHost {
            root.view.insertSubview(rig, belowSubview: shadowHost)
        } else {
            root.view.addSubview(rig)
        }
        landingShadowRig = rig

        let overlay = UIHostingController(rootView: marker.cardOverlay())
        overlay.view.backgroundColor = .clear
        overlay.safeAreaRegions = []
        overlay.view.isUserInteractionEnabled = false
        overlay.view.frame = sourceRect
        overlay.view.alpha = 0
        root.view.addSubview(overlay.view)
        sceneOverlayHost = overlay
    }

    // Catchable-flight machinery. The flight springs live on a property
    // animator; the landing commits only in the animator's .end completion,
    // so stopping the animator mid-air leaves the dismissal undecided and
    // the finger back in charge.
    private var flightAnimator: UIViewPropertyAnimator?
    /// The commit flights' racing mask (maskRaceDuration) — its own animator
    /// so a mid-race catch can fold the mask's on-screen pose into the
    /// model the same way the main flight folds.
    private var maskRaceAnimator: UIViewPropertyAnimator?
    /// The OPEN morph's animator — deliberately separate from
    /// flightAnimator (whose catch branch assumes an armed dismissal): a
    /// caught open must first build the drag rule's world
    /// (armFromCaughtOpen) before the shared catch tail runs.
    private var openAnimator: UIViewPropertyAnimator?
    /// Foreground force-lander for a backgrounding-stalled open (present).
    private var openForegroundObserver: NSObjectProtocol?

    private func retireOpenObserver() {
        if let obs = openForegroundObserver {
            NotificationCenter.default.removeObserver(obs)
            openForegroundObserver = nil
        }
    }
    private var coverFade: UIImageView? // mid-commit page-N cover, undone on catch
    private var regrabTransform: CGAffineTransform? // caught pose blend baseline
    private var regrabMaskFrame = CGRect.zero
    private var regrabMaskRadius: CGFloat = 0

    // MARK: Present (the open morph; builds the persistent scene)

    /// Builds the overlay scene in the root and flies the detail out of its
    /// card. Scrim, shadow host, and the receded home plane persist for the
    /// whole presentation; the mask is dropped at landing and re-created
    /// when a dismissal arms.
    func present(root: ZoomRootController, home: ZoomHostController,
                 detail: ZoomDetailController) {
        self.root = root
        self.home = home
        self.detail = detail
        let container = root.view!
        let navView = root.nav.view!
        homeView = navView

        let scrim = UIView(frame: container.bounds)
        scrim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrim.backgroundColor = .black
        scrim.alpha = 0
        container.addSubview(scrim)
        self.scrim = scrim

        // Shadow host: the reveal shadow cannot live on detailView itself
        // (its mask would clip it), so an unmasked parent carries it. With
        // no shadowPath the shadow derives from the rendered alpha — the
        // masked, transformed detail — hugging the reveal by construction.
        let shadowHost = UIView(frame: container.bounds)
        shadowHost.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        shadowHost.layer.shadowColor = UIColor.black.cgColor
        shadowHost.layer.shadowRadius = ZoomStyle.flightShadowRadius
        shadowHost.layer.shadowOffset = ZoomStyle.flightShadowOffset
        container.addSubview(shadowHost)
        self.shadowHost = shadowHost

        // Record the home's scroll geometry before anything moves.
        func findScroll(_ v: UIView) -> UIScrollView? {
            if let sv = v as? UIScrollView { return sv }
            for sub in v.subviews { if let f = findScroll(sub) { return f } }
            return nil
        }
        homeScroll = home.view.flatMap(findScroll)
        // Grow the home canvas BEFORE recording or measuring anything: the
        // card's frame is top-anchored so it doesn't move, and growing
        // shifts the bottom adjusted inset — record the offset after it
        // settles.
        setHomeCanvas(grown: true)
        homeOffset = homeScroll?.contentOffset ?? .zero

        let detailView = detail.view!
        self.detailView = detailView
        shadowHost.addSubview(detailView)
        detailView.frame = shadowHost.bounds
        detailView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        detailView.layoutIfNeeded() // flight crop: hero matches the card's aspect

        // Start and end rects of the flight, both in root coordinates.
        sourceRect = container.convert(home.cardFrame, from: home.view)
        // The landing fallback must be the RESTING slot: a tap-to-open
        // measures the card mid-press (scale < 1, center-anchored), and a
        // dismissal landing on a pressed rect would snap up by the press
        // delta at teardown. Same center, unscaled size.
        let restingSize = home.activeSource?.bounds.size ?? sourceRect.size
        presentSourceRect = CGRect(
            x: sourceRect.midX - restingSize.width / 2,
            y: sourceRect.midY - restingSize.height / 2,
            width: restingSize.width, height: restingSize.height)
        #if DEBUG
        // Press-to-open seam: a pressed card should measure its SHRUNKEN
        // frame here (scale ~pressScale), so the morph launches from it.
        print(String(format: "PRESENT sourceRect=(%.1f, %.1f, %.1f, %.1f)",
                     sourceRect.minX, sourceRect.minY,
                     sourceRect.width, sourceRect.height))
        #endif
        let heroRect = detail.heroImageFrame()
        displayRadius = estimatedDisplayCornerRadius(around: container)

        guard heroRect.width > 0, sourceRect.width > 0 else {
            // No usable hero geometry (content without an ImageCarousel, or
            // a zero-sized card): a morph would build a singular transform.
            // Present statically instead — same end state, no flight.
            detail.setHeroCrop(flight: false)
            detail.setHeroCurtain(0)
            home.setCardHidden(true)
            navView.transform = recedeTransform(0.94)
            scrim.alpha = 0.25
            shadowHost.layer.shadowOpacity = 0
            detail.markLanded()
            root.detailDidTakeStatusBar()
            return
        }

        // A uniform scale maps the flight-crop hero exactly onto the card
        // (identical aspect), so the first frame is pixel-identical to what
        // was already on screen — the swap is invisible.
        let s = sourceRect.width / heroRect.width
        let viewCenter = CGPoint(x: detailView.bounds.midX, y: detailView.bounds.midY)
        let heroCenter = CGPoint(x: heroRect.midX, y: heroRect.midY)
        detailView.transform = CGAffineTransform(
            translationX: sourceRect.midX - viewCenter.x - s * (heroCenter.x - viewCenter.x),
            y: sourceRect.midY - viewCenter.y - s * (heroCenter.y - viewCenter.y)
        ).scaledBy(x: s, y: s)

        // Everything outside the hero image is masked away at t = 0; the
        // mask growing to full bounds IS the screen expanding outward from
        // the moving image (mask coords are pre-transform: radius / s).
        // Layered so the young sheet can be translucent without ever fading
        // the hero: the root only shapes the reveal, `surround` is the
        // expanding sheet, and `heroPatch` rides exactly over the hero
        // image at full alpha. Both patch endpoints animate in the same
        // spring block as the root, so it tracks the hero exactly.
        let mask = UIView(frame: heroRect)
        mask.backgroundColor = .clear
        mask.clipsToBounds = true
        mask.layer.cornerRadius = ZoomStyle.cornerRadius / s
        mask.layer.cornerCurve = .continuous
        let surround = UIView(frame: mask.bounds)
        surround.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        surround.backgroundColor = .black
        surround.alpha = 0.55
        mask.addSubview(surround)
        let heroPatch = UIView(frame: CGRect(origin: .zero, size: heroRect.size))
        heroPatch.backgroundColor = .black
        mask.addSubview(heroPatch)
        detailView.mask = mask

        detail.setHeroCrop(flight: false) // crop morph animates with the spring
        home.setCardHidden(true) // never a duplicate card beneath the flight

        // The shadow fades in quickly at lift-off (a layer property
        // UIView.animate cannot drive); at landing the reveal covers the
        // screen so the shadow sits entirely offscreen.
        let lift = CABasicAnimation(keyPath: "shadowOpacity")
        lift.fromValue = 0
        lift.toValue = ZoomStyle.flightShadowOpacity
        lift.duration = 0.18
        shadowHost.layer.shadowOpacity = ZoomStyle.flightShadowOpacity
        shadowHost.layer.add(lift, forKey: "shadowLift")

        // The sheet turns solid on its own quick clock, well before the
        // spring settles: translucent at lift-off, opaque by mid-flight.
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut]) {
            surround.alpha = 1
        }

        // The hero's resting frame, recorded for the patch's endpoint and
        // for arming a caught open without forcing layout mid-grab.
        let restingHero = CGRect(x: heroRect.minX, y: heroRect.minY,
                                 width: heroRect.width,
                                 height: detail.heroRestingHeight)
        presentRestingHeroRect = restingHero
        // The property animator leaves the animated subtree's touches live
        // (that is what makes the open catchable) — freeze the scrolls AND
        // deaden the content's own touches for the flight; only the dismiss
        // pan (on the controller's root view) stays live. The landing
        // completion (and a catch) re-enables.
        detail.prepareForCollapse()
        detail.setContentTouchesEnabled(false)

        // The open flies on a property animator (0.4s/0.9 spring) so a
        // touch can seize the card mid-open (catchFlight's open branch).
        let spring = UISpringTimingParameters(dampingRatio: 0.9,
                                              initialVelocity: .zero)
        let animator = UIViewPropertyAnimator(duration: 0.4, timingParameters: spring)
        animator.addAnimations {
            detailView.transform = .identity
            detail.setHeroCurtain(0) // content beneath fades in with the expansion
            detailView.layoutIfNeeded()
            mask.frame = detailView.bounds
            // The patch's frame in mask coords is (hero − mask.origin),
            // with its height following the crop morph to the RESTING crop:
            // every animated term is linear in the same spring progress, so
            // the patch covers the image's animated frame exactly at every
            // tick.
            heroPatch.frame = restingHero
            // Corners grow from the card's radius to the display's own,
            // staying concentric with the screen.
            mask.layer.cornerRadius = self.displayRadius
            navView.transform = self.recedeTransform(0.94)
            scrim.alpha = 0.25
        }
        animator.addCompletion { [weak self] position in
            // .current = the open was caught mid-flight: the drag owns the
            // card now; nothing lands and nothing retires.
            guard let self, position == .end else { return }
            openAnimator = nil
            retireOpenObserver()
            detail.unfreezeScrolls()
            detail.setContentTouchesEnabled(true)
            // Presented rest state: scrim + recede HOLD (the held plane);
            // only the mask retires until a dismissal arms.
            detailView.mask = nil
            shadowHost.layer.shadowOpacity = 0
            // The recede's safe-area reprojection can drift the home
            // scroll's adjusted insets — re-pin the original offset.
            self.pinHomeOffset()
            #if DEBUG
            if let sv = self.homeScroll {
                print(String(format: "PRESENTED homeOffset=%.1f pinned=%.1f inset=%.1f",
                             sv.contentOffset.y, self.homeOffset.y,
                             sv.adjustedContentInset.top))
            }
            #endif
            detail.markLanded()
            self.root?.detailDidTakeStatusBar()
        }
        openAnimator = animator
        animator.startAnimation()
        // Early status-bar hand-off (statusBarHandOffDelay): the sheet
        // covers the bar well before the spring settles. Guarded so a catch
        // inside the beat leaves the bar with the home until the caught
        // gesture settles.
        let barClock = Double(detailView.window?.layer.speed ?? 1)
        DispatchQueue.main.asyncAfter(
            deadline: .now() + DragTuning.statusBarHandOffDelay / max(barClock, 0.001)
        ) { [weak self] in
            guard let self, openAnimator === animator,
                  animator.state == .active else { return }
            root.detailDidTakeStatusBar()
        }
        // Backgrounding mid-open strips the CA animations and stalls the
        // animator (.active, completion never firing) — force-land the
        // stalled open the moment the app foregrounds.
        openForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main) { [weak self] _ in
            guard let self, openAnimator === animator,
                  animator.state == .active else { return }
            animator.stopAnimation(false)
            animator.finishAnimation(at: .end)
        }
        // FAIL-SAFE twin of armWatchdog for the open: if the completion
        // never fires, the presentation would never mark landed — force-
        // land the same animator. A caught open nils openAnimator,
        // disarming this; the margin runs on the wall clock, scaled by the
        // debug slow-motion.
        let clock = Double(detailView.window?.layer.speed ?? 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.4 / max(clock, 0.001)) { [weak self] in
            guard let self, openAnimator === animator,
                  animator.state == .active else { return }
            animator.stopAnimation(false)
            animator.finishAnimation(at: .end)
        }
    }

    /// True while the live flight is a COMMIT (an actual dismissal, any
    /// path); false for the cancel spring. Committed dismissals are
    /// deliberately un-catchable — only the open and the cancel spring can
    /// be seized.
    private var flightIsDismissal = false

    // MARK: Dismissal arming

    /// Re-arms the persistent scene for a dismissal: settles the detail's
    /// scroll geometry, measures the flight's endpoints, and installs the
    /// closing mask and the landing chrome copy. Idempotent per dismissal.
    private func armDismissal() {
        guard let detail, let detailView, let root else { return }
        detail.prepareForCollapse()
        detail.markInFlight()
        // Measure the landing target AS IF the home plane were at identity:
        // the scene holds the 0.94 recede while presented, but the collapse
        // spring expands the plane back to identity in the same flight — a
        // target measured through the held scale would snap at reveal.
        pinHomeOffset() // land on the geometry the user left, drift-free
        let held = homeView?.transform ?? .identity
        homeView?.transform = .identity
        sourceRect = root.view.convert(home?.cardFrame ?? .zero, from: home?.view)
        homeView?.transform = held
        // A covered home may re-render and unmount the source card (weak
        // marker dies) — collapse toward where the card WAS rather than
        // into a zero rect at the origin.
        if sourceRect.width < 1 {
            sourceRect = presentSourceRect
            #if DEBUG
            print("ARMFALLBACK marker dead, using presentSourceRect")
            #endif
        }
        #if DEBUG
        print(String(format: "ARM minY=%.2f", sourceRect.minY))
        #endif
        heroRect = detail.currentHeroFrame()
        anchor = CGPoint(x: heroRect.midX, y: heroRect.midY)

        let mask = UIView(frame: detailView.bounds)
        mask.backgroundColor = .black
        mask.layer.cornerRadius = displayRadius
        mask.layer.cornerCurve = .continuous
        detailView.mask = mask
        maskView = mask

        // Card overlay chrome copy at the card's resting slot, invisible
        // until a commit spring raises it (the resting shadow needs no
        // copy — the marker's own instance rides the same springs).
        installCardChrome()
    }

    /// A live drag grabbed the card: arm the scene and play the grab beat
    /// (shadow up, scrim lightened a touch; both then hold for the drag).
    func beginDrag() {
        guard !isInteracting else { return }
        isInteracting = true
        armDismissal()
        liftShadow(over: 0.15)
        UIView.animate(withDuration: 0.15) {
            self.scrim?.alpha = DragTuning.dragScrimAlpha
        }
    }

    /// The X button / zoomDismiss: the same collapse, self-driven — a tap
    /// carries no momentum, so no bounce is earned (buttonDamping).
    func dismissProgrammatically() {
        guard !isInteracting else { return }
        isInteracting = true
        detail?.markInFlight() // no drags may start during the glide below
        let collapse = { [weak self] in
            guard let self else { return }
            armDismissal()
            flightIsDismissal = true
            shadowHost?.layer.shadowOpacity = ZoomStyle.flightShadowOpacity
            runCollapse(velocity: .zero,
                        duration: DragTuning.buttonFlightDuration,
                        damping: DragTuning.buttonDamping)
        }
        // A scrolled detail must return to its top before the morph (the
        // hero is the flight's anchor) — glide there instead of teleporting.
        if detail?.isScrolledToTop == false {
            detail?.glideToTop(then: collapse)
        } else {
            collapse()
        }
    }

    func updateDrag(translation t: CGPoint) {
        guard let pose = dragPose(for: t) else { return }
        detailView?.transform = pose.transform
        maskView?.frame = pose.maskFrame
        maskView?.layer.cornerRadius = pose.maskRadius
        // System-zoom behavior: the underlying home plane HOLDS its
        // presented recede (0.94) and dim for the entire interactive phase —
        // releasing them is the commit's job; a cancel leaves a plane that
        // never moved.
    }

    /// The collapse's landing geometry: the current hero projected to the
    /// flight crop (the crop extends DOWNWARD; the top edge stays put) and
    /// the uniform scale that maps it onto the home card. Shared by the
    /// dive's racing mask and the collapse spring so the two can never
    /// diverge.
    private func flightTarget() -> (hero: CGRect, scale: CGFloat)? {
        guard let detail, heroRect.width > 0 else { return nil }
        let hero = CGRect(x: heroRect.minX, y: heroRect.minY,
                          width: heroRect.width,
                          height: heroRect.width * detail.sourceAspect)
        return (hero, sourceRect.width / hero.width)
    }

    /// The on-screen rect of a detail-coordinate rect under a (uniform
    /// scale + translation) view transform — the flying window's screen
    /// frame. Pure model math: no layout, no presentation reads.
    private func screenWindow(of rect: CGRect, under tr: CGAffineTransform,
                              in detailView: UIView) -> CGRect {
        let c = CGPoint(x: detailView.bounds.midX, y: detailView.bounds.midY)
        let mid = CGPoint(x: c.x + tr.a * (rect.midX - c.x) + tr.tx,
                          y: c.y + tr.d * (rect.midY - c.y) + tr.ty)
        return CGRect(x: mid.x - rect.width * tr.a / 2,
                      y: mid.y - rect.height * tr.d / 2,
                      width: rect.width * tr.a, height: rect.height * tr.d)
    }

    /// Points the landing rigs — shadow AND card-chrome copy — at a window:
    /// one transform each against their SHARED fixed sourceRect geometry,
    /// so shadowPaths never mutate mid-flight.
    private func updateLandingRigs(window: CGRect) {
        let k = window.width / max(sourceRect.width, 1)
        let tr = CGAffineTransform(
            translationX: window.midX - sourceRect.midX,
            y: window.midY - sourceRect.midY).scaledBy(x: k, y: k)
        landingShadowRig?.transform = tr
        sceneOverlayHost?.view.transform = tr
    }

    /// The drag rule as a pure pose: transform + mask for a given finger
    /// translation, including any live regrab blend. Shared by the live
    /// drag (updateDrag) and the throw's ghost finger (diveTick), which
    /// replays this same rule along the momentum's decay — a fast dive is
    /// pixel-equivalent to a slow drag at every height.
    private func dragPose(for t: CGPoint)
        -> (transform: CGAffineTransform, maskFrame: CGRect, maskRadius: CGFloat)? {
        guard let detailView else { return nil }
        let progress = min(max(t.y / DragTuning.collapseDistance, 0), 1)
        let offset = CGSize(
            width: DragTuning.rubberBand(t.x, limit: 160, response: 0.8),
            height: t.y >= 0
                ? DragTuning.rubberBand(t.y, limit: 700, response: 1)
                : DragTuning.rubberBand(t.y, limit: 80, response: 0.9)) // upward fights back hard
        // Shrink toward minDragScale with progress, anchored at the image
        // center, plus the rubber-banded finger offset.
        let k = 1 - (1 - DragTuning.minDragScale) * progress
        let c = CGPoint(x: detailView.bounds.midX, y: detailView.bounds.midY)
        var transform = CGAffineTransform(
            translationX: (anchor.x - c.x) * (1 - k) + offset.width,
            y: (anchor.y - c.y) * (1 - k) + offset.height
        ).scaledBy(x: k, y: k)
        // The mask closes linearly from full-screen onto the image's frame
        // (cropping the chrome away), corners easing from the display's
        // radius to the image's. Progress is clamped, so dragging past
        // collapseDistance never shrinks the reveal below the image.
        var maskFrame = DragTuning.lerp(detailView.bounds, heroRect, progress)
        var maskRadius = DragTuning.lerp(displayRadius, ZoomStyle.cornerRadius, progress)
        // A caught flight re-enters the drag from wherever the card was
        // seized: blend from the caught pose onto the drag rule over the
        // first ~120pt of new finger travel — no jump at the catch instant.
        // (Transforms here are uniform scale + translation, so component
        // lerp is well-defined.)
        if let base = regrabTransform {
            let w = min(1, (abs(t.x) + abs(t.y)) / 120)
            transform = CGAffineTransform(
                a: DragTuning.lerp(base.a, transform.a, w), b: 0, c: 0,
                d: DragTuning.lerp(base.d, transform.d, w),
                tx: DragTuning.lerp(base.tx, transform.tx, w),
                ty: DragTuning.lerp(base.ty, transform.ty, w))
            maskFrame = DragTuning.lerp(regrabMaskFrame, maskFrame, w)
            maskRadius = DragTuning.lerp(regrabMaskRadius, maskRadius, w)
            if w >= 1 { regrabTransform = nil }
        }
        return (transform, maskFrame, maskRadius)
    }

    #if DEBUG
    // ── Frame-pacing probe (-morphPerfProbe): measures UI-thread frame
    // delivery through a dismissal at FULL speed — the ground truth for
    // "jitter". Prints per-hitch timing relative to the release, plus
    // the dive tick's own worst-case cost. ──
    private var perfLink: CADisplayLink?
    private var perfStamps: [CFTimeInterval] = []
    private var perfMarks: [(String, CFTimeInterval)] = []
    var perfWorstTickCost: Double = 0

    private var perfProbeEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-morphPerfProbe")
    }

    func perfMark(_ label: String) {
        guard perfLink != nil else { return }
        perfMarks.append((label, CACurrentMediaTime()))
    }

    private func perfBegin() {
        guard perfProbeEnabled, perfLink == nil else { return }
        perfStamps.removeAll(keepingCapacity: true)
        perfWorstTickCost = 0
        perfMarks = [("release", CACurrentMediaTime())]
        let link = CADisplayLink(target: self, selector: #selector(perfTick))
        link.preferredFrameRateRange = CAFrameRateRange(
            minimum: 80, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        perfLink = link
    }

    @objc private func perfTick(_ link: CADisplayLink) {
        perfStamps.append(link.timestamp)
    }

    private func perfEnd() {
        guard let link = perfLink else { return }
        link.invalidate()
        perfLink = nil
        guard perfStamps.count > 4 else { return }
        let deltas = zip(perfStamps.dropFirst(), perfStamps).map { $0 - $1 }
        let nominal = deltas.sorted()[deltas.count / 2]
        let t0 = perfMarks.first?.1 ?? perfStamps[0]
        print(String(format: "PERF frames=%d span=%.0fms nominal=%.1fms diveTickWorst=%.2fms",
                     deltas.count, (perfStamps.last! - perfStamps[0]) * 1000,
                     nominal * 1000, perfWorstTickCost * 1000))
        for (label, t) in perfMarks.dropFirst() {
            print(String(format: "PERF mark %@ +%.0fms", label, (t - t0) * 1000))
        }
        var hitches = 0
        for (i, d) in deltas.enumerated() where d > nominal * 1.55 {
            hitches += 1
            print(String(format: "PERF hitch at +%.0fms: %.1fms (%.1fx nominal)",
                         (perfStamps[i] - t0) * 1000, d * 1000, d / nominal))
        }
        let mean = deltas.reduce(0, +) / Double(deltas.count)
        print(String(format: "PERF hitches=%d worst=%.1fms mean=%.1fms",
                     hitches, (deltas.max() ?? 0) * 1000, mean * 1000))
    }
    #endif

    /// Drag-release: collapse into the card. The landing is deferred to
    /// the flight animator's completion, so a mid-air catch could hand the
    /// card back to the finger. Every gesture release toward a slot above
    /// arcCutoffY plays the TWO-BEAT ARC (runArc); at and below the line
    /// the overshoot is zero by formula and the release flies the
    /// continuous collapse — the same family, arc-less, with a hard flick
    /// still feeding the direct collapse's kick.
    func finishDismiss(translation: CGPoint, velocity: CGPoint) {
        #if DEBUG
        perfBegin()
        print(String(format: "RELEASE minY=%.1f vy=%.0f overshoot=%.1f",
                     sourceRect.minY, velocity.y,
                     DragTuning.arcOvershoot(destinationTop: sourceRect.minY,
                                             velocity: velocity.y)))
        #endif
        flightIsDismissal = true
        if sourceRect.minY < DragTuning.arcCutoffY {
            runArc(translation: translation, velocity: velocity)
        } else if velocity.y >= DragTuning.fastFlickVelocity {
            runDirectCollapse(translation: translation, velocity: velocity)
        } else {
            runCollapse(velocity: velocity,
                        duration: DragTuning.closeFlightDuration,
                        damping: DragTuning.bounceDamping)
        }
    }

    /// The direct flight — a fast flick's one-piece collapse into the card.
    /// It carries the finger's REAL on-screen speed into the spring (the
    /// velocity through the rubber band's slope, signed toward the slot by
    /// runCollapse) and races the mask closed so the landing keeps its
    /// spring character.
    private func runDirectCollapse(translation t: CGPoint, velocity: CGPoint) {
        runCollapse(velocity: velocity,
                    duration: DragTuning.closeFlightDuration,
                    damping: DragTuning.bounceDamping,
                    descentSpeed: velocity.y * DragTuning.rubberBandSlope(
                        t.y, limit: 700, response: 1),
                    signedDescent: true)
    }

    // Ghost-finger dive state (the arc's first beat): see runArc.
    private var diveLink: CADisplayLink?
    private var diveStart: CFTimeInterval = 0
    private var diveClock: Double = 1
    private var diveOrigin = CGPoint.zero    // release translation, finger space
    private var diveVelocity = CGPoint.zero  // dive launch velocity (finger space)
    private var diveOmega: Double = 0        // impulse-response stiffness
    private var diveDuration: TimeInterval = 0
    private var diveSettle: TimeInterval = DragTuning.throwSettle // this arc's return beat
    private var diveScrimStart: CGFloat = 0  // scrim's presented dim at release

    /// Inverts the drag rule: the ghost-finger travel whose pose puts the
    /// flying image's TOP at `screenTop`. In the saturated regime (progress
    /// pinned at 1) only the rubber band varies — closed form; shallow
    /// targets bisect the exact pose expression. Pure model math.
    private func virtualTravel(forImageTop screenTop: CGFloat,
                               in detailView: UIView) -> CGFloat {
        let c = CGPoint(x: detailView.bounds.midX, y: detailView.bounds.midY)
        func poseTop(_ y: CGFloat) -> CGFloat {
            let p = min(max(y / DragTuning.collapseDistance, 0), 1)
            let k = 1 - (1 - DragTuning.minDragScale) * p
            return c.y + k * (heroRect.minY - c.y)
                + (anchor.y - c.y) * (1 - k)
                + DragTuning.rubberBand(y, limit: 700, response: 1)
        }
        let k = DragTuning.minDragScale
        let deepBase = c.y + k * (heroRect.minY - c.y) + (anchor.y - c.y) * (1 - k)
        let bandNeeded = min(screenTop - deepBase, 660) // band saturates at 700
        let bandAtSaturation = DragTuning.rubberBand(
            DragTuning.collapseDistance, limit: 700, response: 1)
        if bandNeeded >= bandAtSaturation {
            return min(700 * bandNeeded / (700 - bandNeeded), 2400)
        }
        var lo: CGFloat = 0, hi = DragTuning.collapseDistance
        guard poseTop(hi) > screenTop else { return hi }
        for _ in 0..<20 {
            let mid = (lo + hi) / 2
            if poseTop(mid) < screenTop { lo = mid } else { hi = mid }
        }
        return (lo + hi) / 2
    }

    /// The TWO-BEAT ARC's first beat: a ghost finger extends the DRAG RULE
    /// along a critically-damped impulse, T(t) = release + launch·t·e^{−ωt},
    /// driving dragPose each frame — every mid-dive pose is a valid drag
    /// pose, so the mask, crop, curtain, and shadow rig behave identically
    /// to a live drag. The impulse's peak is aimed at the PIVOT — the
    /// screen height where the image's top sits overshoot points below its
    /// slot (virtualTravel inverts the rule) — and the exit at the top
    /// (1/ω, velocity ~zero) hands the PHYSICAL spring a from-rest start
    /// at full displacement: the second beat's clean single rise.
    private func runArc(translation t: CGPoint, velocity: CGPoint) {
        guard let detailView, let container = root?.view, heroRect.width > 0
        else {
            runCollapse(velocity: velocity,
                        duration: DragTuning.closeFlightDuration,
                        damping: DragTuning.bounceDamping)
            return
        }
        // Slow releases morph straight in: the two-beat dive and the deep-
        // release climb are flick language — a drag simply let go morphs
        // into place from wherever the finger leaves it, on the calm
        // slow-morph clock with the shrink riding the motion. Everything
        // at/above arcSlowMorphCeil keeps its existing beat.
        if velocity.y < DragTuning.arcSlowMorphCeil {
            runCollapse(velocity: velocity,
                        duration: DragTuning.arcSlowMorphDuration,
                        damping: DragTuning.bounceDamping,
                        raceDuration: DragTuning.arcSlowMorphDuration
                            * DragTuning.arcSlowMorphRaceShare)
            return
        }
        // The formula's depth, clamped by the stage: the fully-collapsed
        // card's bottom stays on screen at the pivot (deep-pose scale).
        let overshootRaw = DragTuning.arcOvershoot(
            destinationTop: sourceRect.minY, velocity: velocity.y)
        let pivotHeight = heroRect.width * (detail?.sourceAspect ?? 1)
            * DragTuning.minDragScale
        // The pivot anchors to the destination ON SCREEN: an above-screen
        // slot (negative minY) would put it above the release pose and rob
        // the arc of its descent — clamping the anchor to the screen top
        // gives those slots the SAME down-then-up arc (continuous at 0),
        // the climb then carrying on to the off-screen slot on its
        // extended settle.
        let pivotAnchor = max(sourceRect.minY, 0)
        // No safety margin: the hard edge's 60pt minimum near the cutoff
        // needs the full stage, and a dive whose card bottom kisses the
        // screen edge at the extreme is fine (it never exceeds it).
        let room = container.bounds.height - pivotAnchor - pivotHeight
        let overshoot = min(overshootRaw, max(room, 0))
        let pivotTop = pivotAnchor + overshoot
        let targetVirtual = virtualTravel(forImageTop: pivotTop, in: detailView)
        let delta = targetVirtual - t.y
        // The return beat, per release: slow flicks spring home a touch
        // quicker (arcReturnSettle); lower slots additionally quicken by
        // √(travel pace boost).
        let pace = DragTuning.travelPaceBoost(destinationTop: sourceRect.minY)
        diveSettle = DragTuning.arcReturnSettle(velocity: velocity.y)
            / TimeInterval(pace.squareRoot())
        guard overshoot > 1, delta > 1 else {
            // Deep release: the finger already sits at/past the pivot — the
            // second beat plays alone, the downward residual feeding the
            // spring's away-kick (velocity stays continuous). The STANDARD
            // settle, deliberately untrimmed (the slow-return trim is sized
            // for the post-dive short hop; on a long climb it read as a
            // snap), extended for above-screen slots whose climb leaves the
            // stage entirely.
            let deepSettle = DragTuning.throwSettle
                + DragTuning.aboveScreenTime(destinationTop: sourceRect.minY)
            let residualKick = max(velocity.y, 0) * DragTuning.rubberBandSlope(
                t.y, limit: 700, response: 1)
            // The climb launches immediately; runCollapse's universal mask
            // race closes any remaining reveal CONCURRENTLY at the standard
            // openness-scaled speed, so the screen visibly shrinks into the
            // card over the climb's first stretch.
            runCollapse(velocity: .zero,
                        duration: deepSettle,
                        descentSpeed: residualKick,
                        physicalSpring: true, physicalSettle: deepSettle)
            return
        }
        diveOrigin = t
        // The dive launches at the finger's pace mapped into the converged
        // band (rule space — the band's slope maps it on-screen by the
        // chain rule); the x-axis keeps the finger's actual drift.
        let launch = min(max(velocity.y * DragTuning.arcPaceScale,
                             DragTuning.arcMinLaunch), DragTuning.arcMaxLaunch)
            * pace // lower slots dive their longer journey quicker
        diveVelocity = CGPoint(x: velocity.x, y: launch)
        // Stiffness from the pivot: T(t) = launch·t·e^{−ωt} tops out at
        // launch/(eω) — so ω = launch/(e·Δ) soft-hovers exactly at the
        // pivot's finger-space depth. Braking grows with depth, not time.
        diveOmega = Double(launch) / (M_E * Double(delta))
        // Exit exactly AT the top (1/ω, velocity zero): the spring then
        // leaves from rest at full displacement. arcMaxDiveTime bounds a
        // pathological crawl; that exit carries a real residual, which the
        // hand-over math absorbs.
        diveDuration = min(1.0 / diveOmega, DragTuning.arcMaxDiveTime)
        // Consistent total: rescale BOTH beats onto the depth-mapped target
        // (proportional split, floored at arcMinDiveShare); the impulse
        // re-derives ω and its launch so the peak still lands exactly at Δ.
        // The above-screen extension joins AFTER the split, settle-only.
        let base = DragTuning.arcTimeMin
            + (DragTuning.arcTimeMax - DragTuning.arcTimeMin)
            * TimeInterval(min(overshoot / DragTuning.arcMaxOvershoot, 1))
        let natural = diveDuration + diveSettle
        if natural > 0.01 {
            let dive = max(diveDuration * (base / natural),
                           base * DragTuning.arcMinDiveShare)
            diveDuration = dive
            diveSettle = (base - dive)
                + DragTuning.aboveScreenTime(destinationTop: sourceRect.minY)
            diveOmega = 1.0 / diveDuration
            diveVelocity.y = CGFloat(M_E * Double(delta) * diveOmega)
        }
        // Flick fade: the settle-only extension (arcFlickFadeExtra), added
        // after the split so the dive is untouched; every consumer below
        // inherits it through diveSettle.
        diveSettle += DragTuning.arcFlickFadeTime(velocity: velocity.y)
        // The commit is visible from the FIRST frame: the shadow starts
        // resolving over the whole flight's span (diveTick eases scrim and
        // home the same way).
        dropShadow(over: diveDuration + diveSettle)
        // The collapse COMPLETES ON THE DIVE: the hero's crop morph rides
        // the descent, finishing just ahead of the racing mask — any
        // transient band under the image is image content, never the white
        // curtain — so the pivot presents the FINISHED bare card and the
        // ascent spring is a pure transform flight. Scrubbed on the dive's
        // own clock (setCropScrub — plain model writes), so it shares the
        // exact frame phase of the transform/mask/rig writes.
        detail?.setHeroCropScrub(0)
        // The grab beat's scrim lighten was created inside the interactive
        // transition start, so UIKit paces it against the reported
        // transition progress — which the throw holds during the dive.
        // Fold the presented value into the model (no visible step) and
        // clear it; the ghost scrubs the model from here.
        if let scrim {
            scrim.alpha = CGFloat(scrim.layer.presentation()?.opacity ?? Float(scrim.alpha))
            scrim.layer.removeAllAnimations()
            diveScrimStart = scrim.alpha
        }
        // The link ticks on the wall clock; scale elapsed time by the
        // window's layer speed so the debug slow-motion harness sees the
        // dive at the animations' rate (speed is 1 in production).
        diveClock = Double(detailView.window?.layer.speed ?? 1)
        diveStart = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(diveTick))
        // ProMotion: without an explicit range, iOS schedules display links
        // at 60Hz even on 120Hz panels — the dive would update at half the
        // rate the CA-driven ascent renders at, a felt texture change.
        link.preferredFrameRateRange = CAFrameRateRange(
            minimum: 80, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        diveLink = link
    }

    @objc private func diveTick(_ link: CADisplayLink) {
        #if DEBUG
        let perfT0 = CACurrentMediaTime()
        defer { perfWorstTickCost = max(perfWorstTickCost, CACurrentMediaTime() - perfT0) }
        #endif
        let elapsed = (link.timestamp - diveStart) * diveClock
        let t = min(elapsed, diveDuration)
        // Critically-damped impulse response: rises at the finger's speed,
        // brakes into a soft hover at the peak, eases back.
        let impulse = CGFloat(t * exp(-diveOmega * t))
        let virtual = CGPoint(x: diveOrigin.x + diveVelocity.x * impulse,
                              y: diveOrigin.y + diveVelocity.y * impulse)
        if let pose = dragPose(for: virtual), let detail {
            detailView?.transform = pose.transform
            // The MASK races ahead of the height rule, fully closed onto
            // the flight crop by the impulse's peak (the rule is a floor,
            // not a ceiling). This leaves the collapse spring ~zero mask
            // delta, so the spring's overshoot cannot be counter-clipped.
            let (flightHero, s) = flightTarget() ?? (pose.maskFrame, 1)
            let f = CGFloat(min(t / max(diveDuration, 0.001), 1))
            // Soft-attack smoothstep: the collapse builds, peaks mid-dive,
            // and eases onto the closed crop exactly at the pivot.
            let closing = f * f * (3 - 2 * f)
            let raced = DragTuning.lerp(pose.maskFrame, flightHero, closing)
            maskView?.frame = raced
            maskView?.layer.cornerRadius = DragTuning.lerp(
                pose.maskRadius, ZoomStyle.cornerRadius / s, closing)
            // The crop morph rides the dive ahead of this racing mask, so
            // the band between them is image, not curtain — the curtain
            // still guards any residual sliver beneath.
            detail.setHeroCurtain(closing)
            // Crop scrub — same clock as every other dive write; eased
            // in-out, complete by 0.8·dive so it stays ahead of the mask.
            let cf = CGFloat(min(t / max(diveDuration * 0.8, 0.001), 1))
            detail.setHeroCropScrub(cf * cf * (3 - 2 * cf))
            // The landing rig rides the dive too — one transform write per
            // tick, fading on the same whole-flight clock as scrim/home.
            if let dv = detailView {
                updateLandingRigs(window: screenWindow(
                    of: raced, under: pose.transform, in: dv))
            }
            let rigAlpha = CGFloat(min(
                elapsed / (diveDuration + diveSettle), 1))
            landingShadowRig?.alpha = rigAlpha
            sceneOverlayHost?.view.alpha = rigAlpha // chrome rides the card too
        }
        // The underlying plane resolves CONTINUOUSLY from the first moving
        // frame — scrim and home ease toward their landed state across the
        // whole flight's span; the collapse spring carries each from
        // wherever the dive leaves it.
        let flightFraction = CGFloat(min(
            elapsed / (diveDuration + diveSettle), 1))
        scrim?.alpha = diveScrimStart * (1 - flightFraction)
        homeView?.transform = recedeTransform(0.94 + 0.06 * flightFraction)
        // The dive ends at the impulse's top (1/ω), where the pose sits at
        // the designed pivot — the arc's dives deliberately ride far past
        // collapseDistance (the pose's scale saturates there but the
        // banded descent keeps moving the card, which IS the plunge).
        guard elapsed >= diveDuration else { return }
        // Hand over with the ghost's actual signed speed: T'(t) =
        // v·e^{−ωt}(1−ωt) — negative past the peak. The band's slope
        // converts it to on-screen speed; the spring absorbs a downward
        // residual or rides a toward-target one.
        let slope = exp(-diveOmega * t) * (1 - diveOmega * t)
        let residual = diveVelocity.y * CGFloat(slope)
            * DragTuning.rubberBandSlope(virtual.y, limit: 700, response: 1)
        stopDive()
        #if DEBUG
        perfMark("pivot-handover")
        print(String(format: "HANDOVER t=%.3f residual=%.1f", t, residual))
        #endif
        runCollapse(velocity: .zero,
                    duration: diveSettle,
                    descentSpeed: residual, physicalSpring: true,
                    physicalSettle: diveSettle)
    }

    private func stopDive() {
        diveLink?.invalidate()
        diveLink = nil
    }

    /// Collapse the visible page into the home card — the shared shrink-to-
    /// card motion, driven from a released drag (underdamped: the flick
    /// earns the bounce), a throw hand-over (physical spring), or the Back
    /// button (near-critical: a tap earns none). `damping` only shapes the
    /// duration-fitted spring; the physical path derives its own.
    private func runCollapse(velocity: CGPoint, duration: TimeInterval,
                             damping: CGFloat = 1,
                             descentSpeed: CGFloat = 0, physicalSpring: Bool = false,
                             physicalSettle: TimeInterval = DragTuning.throwSettle,
                             signedDescent: Bool = false,
                             raceDuration: TimeInterval? = nil) {
        guard let detail, let detailView, let home, let homeView else {
            // FAIL-SAFE: a silent return here mid-dismissal would leave the
            // overlay stuck on screen forever. If the scene has fallen
            // apart (weak views died mid-gesture), tear it down.
            if isInteracting { teardown(completed: true) }
            return
        }

        // Flight target: the current hero projected to the flight crop
        // (the crop change extends downward; the top edge stays put).
        guard let (flightHero, s) = flightTarget() else {
            if isInteracting { teardown(completed: true) }
            return
        }
        let c = CGPoint(x: detailView.bounds.midX, y: detailView.bounds.midY)
        let heroCenter = CGPoint(x: flightHero.midX, y: flightHero.midY)
        let target = CGAffineTransform(
            translationX: sourceRect.midX - c.x - s * (heroCenter.x - c.x),
            y: sourceRect.midY - c.y - s * (heroCenter.y - c.y)
        ).scaledBy(x: s, y: s)

        // Close-from-page-N: the flying page fades into the card's own image
        // mid-flight; geometry is unaffected.
        var cover: UIImageView?
        if detail.currentPageIndex() != 0, let first = detail.firstPageContent {
            let page = detail.currentPageImageView
            let fade = UIImageView(image: first)
            fade.contentMode = .scaleAspectFill
            fade.clipsToBounds = true
            fade.layer.cornerRadius = page.layer.cornerRadius
            fade.layer.cornerCurve = .continuous
            fade.frame = page.bounds
            fade.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            fade.alpha = 0
            page.addSubview(fade)
            cover = fade
        }
        coverFade = cover

        dropShadow(over: duration)
        detail.setHeroCrop(flight: true)
        // A throw hand-over arrives with the ghost's SIGNED speed (in the
        // spring's toward-target units, normalized by this flight's own
        // travel): positive descentSpeed = still moving down = away-kick;
        // negative = easing back up = toward-target kick. Either way
        // velocity stays continuous across the hand-over; the clamp only
        // guards absurd ratios. Every other path passes descentSpeed 0 and
        // keeps the standard kick.
        var dy: CGFloat = descentSpeed != 0
            ? -max(min(descentSpeed / max(abs(target.ty - detailView.transform.ty), 1), 4), -4)
            : normalized(velocity, over: DragTuning.collapseDistance)
        // signedDescent (the low-slot direct flight): descentSpeed is the
        // finger's on-screen DOWNWARD speed, and the slot usually sits
        // BELOW the release pose — downward is then TOWARD the target,
        // the opposite of the throw hand-over's fixed away convention.
        // Flip by the actual geometry; a deep drag released past a
        // mid-height slot keeps the away-kick, so the spring lets the
        // descent finish its arc instead of snapping it into reverse.
        if signedDescent, target.ty > detailView.transform.ty { dy = -dy }
        // The throw's flight uses the PHYSICAL spring: the duration-fitted
        // dampingRatio initializer refits the curve and crushes the
        // oscillation amplitude at lower ratios, so the kept landing
        // bounce needs real physics. Every other path keeps the
        // duration-fitted spring.
        let zw = 6.6 / CGFloat(physicalSettle)
        let spring = physicalSpring
            ? UISpringTimingParameters(
                mass: 1, stiffness: pow(zw / DragTuning.throwBounceDamping, 2),
                damping: 2 * zw,
                initialVelocity: CGVector(dx: 0, dy: dy))
            : UISpringTimingParameters(
                dampingRatio: damping,
                initialVelocity: CGVector(dx: 0, dy: dy))
        // The racing mask — every commit flight (see
        // DragTuning.maskRaceDuration): a separate animator so a mid-race
        // catch can fold the mask's on-screen pose into the model exactly
        // like the main flight. A throw hand-over arrives with the mask
        // already raced closed by the dive — a no-op delta.
        if let maskView {
            // Openness at commit: 1 = full-screen reveal, 0 = already on
            // the flight crop. Scales the race so the condense moves at
            // one consistent speed regardless of how deep the drag was.
            let openness = min(max(
                (maskView.frame.height - flightHero.height)
                    / max(detailView.bounds.height - flightHero.height, 1), 0), 1)
            let race = UIViewPropertyAnimator(
                duration: raceDuration
                    ?? DragTuning.maskRaceDuration * max(TimeInterval(openness), 0.2),
                timingParameters: UISpringTimingParameters(
                    dampingRatio: 1, initialVelocity: .zero))
            race.addAnimations {
                maskView.frame = flightHero
                maskView.layer.cornerRadius = ZoomStyle.cornerRadius / s
                detail.setHeroCurtain(1) // curtain rides the racing crop
                // The crop's dirty constraints resolve HERE, on the race
                // clock: mask bottom and image bottom animate in the SAME
                // animator, in lockstep — the band between them is always
                // image content, never the white curtain. The spring's
                // later layoutIfNeeded then finds a clean tree and no-ops.
                detailView.layoutIfNeeded()
            }
            maskRaceAnimator = race
            race.startAnimation()
        }

        // Seed the landing rigs on the current flying window; the SAME
        // spring then carries card and rigs home — matched endpoints on one
        // timing curve track exactly, so no display link and no per-frame
        // machinery. Card-anchored, the fade safely spans the whole flight:
        // there is no empty-slot ring for an early fade to expose. The
        // marker's own shadow stays hidden until the completion's
        // one-transaction swap.
        updateLandingRigs(window: screenWindow(
            of: flightHero, under: detailView.transform, in: detailView))

        #if DEBUG
        perfMark("collapse-spring-start")
        #endif
        let animator = UIViewPropertyAnimator(duration: duration, timingParameters: spring)
        animator.addAnimations {
            detailView.transform = target
            detailView.layoutIfNeeded()
            self.scrim?.alpha = 0
            homeView.transform = .identity
            cover?.alpha = 1
            self.sceneOverlayHost?.view.alpha = 1 // card chrome returns with the landing
            self.sceneOverlayHost?.view.transform = .identity // riding the card home
            self.landingShadowRig?.transform = .identity // rides the same spring home
            self.landingShadowRig?.alpha = 1 // the card's shadow arrives with it
        }
        animator.addCompletion { [weak self] position in
            // .current means the flight was caught (catchFlight) — the pop
            // stays undecided and the finger owns the card again.
            guard let self, position == .end else { return }
            // Unhide first: the landed image and the card are pixel-identical,
            // and both changes commit in the same transaction — no flash.
            home.setCardHidden(false)
            teardown(completed: true)
        }
        flightAnimator = animator
        animator.startAnimation()
        armWatchdog(for: animator, duration: duration, in: detailView)
    }

    /// FAIL-SAFE watchdog: if a flight animator's completion never fires
    /// (e.g. its CA animations were stripped while the app backgrounded
    /// mid-flight), the DEFERRED finish/cancel never runs and the pop stays
    /// undecided — a frozen UI. Force-land the SAME animator if it is still
    /// the live flight well past its natural duration. A caught flight nils
    /// flightAnimator, and a landed one tears down, so either legitimately
    /// disarms this; the margin runs on the wall clock, scaled by the debug
    /// slow-motion.
    private func armWatchdog(for animator: UIViewPropertyAnimator,
                             duration: TimeInterval, in view: UIView) {
        let clock = Double(view.window?.layer.speed ?? 1)
        let wall = (duration + 3) / max(clock, 0.001)
        DispatchQueue.main.asyncAfter(deadline: .now() + wall) { [weak self] in
            guard let self, flightAnimator === animator, isInteracting else { return }
            animator.stopAnimation(false)
            animator.finishAnimation(at: .end)
        }
    }

    /// Spring back to fully presented (openFlight). The interactive cancel
    /// is DEFERRED to the spring's landing (same as finishDismiss), so a
    /// catch can seize the return flight — and still commit the pop.
    func cancelDismiss(velocity: CGPoint, completion: @escaping () -> Void) {
        flightIsDismissal = false
        guard let detailView, let homeView else {
            // FAIL-SAFE (see runCollapse): a broken scene must still resolve
            // or the overlay stays stuck; return to the presented rest.
            teardown(completed: false)
            completion()
            return
        }
        // The elevation shadow HOLDS through the cancel (fading it mid-air
        // read as de-elevation while the card was still visibly airborne):
        // at the full-screen destination the shadow sits entirely offscreen,
        // and teardown's instant zero lands invisibly under the sheet.
        // This flight's target sits ABOVE the released card, so toward-
        // target — the sign initialSpringVelocity expects — is an UPWARD
        // flick: -velocity.y, the opposite convention from normalized()'s
        // collapse direction. UIKit's unit is remaining animation distance
        // per second, so divide by the view's own displacement back to
        // identity. A downward release floors to 0: the spring starts from
        // rest rather than taking a wrong-signed kick toward the target.
        let returnTravel = max(abs(detailView.transform.ty), 1)
        let v0 = min(max(-velocity.y, 0) / returnTravel, 8)
        let spring = UISpringTimingParameters(
            dampingRatio: DragTuning.bounceDamping,
            initialVelocity: CGVector(dx: 0, dy: v0))
        let animator = UIViewPropertyAnimator(
            duration: DragTuning.openFlightDuration, timingParameters: spring)
        animator.addAnimations {
            detailView.transform = .identity
            self.maskView?.frame = detailView.bounds
            self.maskView?.layer.cornerRadius = self.displayRadius
            self.scrim?.alpha = 0.25
            homeView.transform = self.recedeTransform(0.94)
            self.sceneOverlayHost?.view.alpha = 0 // chrome retreats with the cancel
            self.landingShadowRig?.alpha = 0
        }
        animator.addCompletion { [weak self] position in
            guard let self, position == .end else { return } // .current = caught
            teardown(completed: false)
            completion()
        }
        flightAnimator = animator
        animator.startAnimation()
        armWatchdog(for: animator, duration: DragTuning.openFlightDuration, in: detailView)
    }

    /// Seizes an in-flight OPEN morph or cancel spring and hands the card
    /// back to the finger — the system-zoom mid-air re-grab. The deferred
    /// finish/cancel never fires (the animator ends at .current, which the
    /// completions ignore), so the caught drag is free to commit or cancel
    /// as if the release had never happened. False when nothing is in
    /// flight — and for every COMMITTED dismissal (dive or collapse), which
    /// deliberately refuses the grab and flies home.
    func catchFlight() -> Bool {
        guard let detail, let detailView else { return false }
        if diveLink != nil { return false }
        if let animator = flightAnimator, animator.state == .active,
           flightIsDismissal { return false }
        if let animator = flightAnimator, animator.state == .active {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .current) // on-screen pose becomes the model
            flightAnimator = nil
        } else if let open = openAnimator, open.state == .active {
            // Mid-OPEN grab (the system zoom's both-ways catchability):
            // fold the open at its on-screen pose, then build the drag
            // rule's world — the open never armed a dismissal.
            open.stopAnimation(false)
            open.finishAnimation(at: .current)
            openAnimator = nil
            retireOpenObserver()
            armFromCaughtOpen()
        } else {
            return false
        }
        // A direct flight's racing mask folds to its on-screen pose too,
        // so the regrab baseline below reads presentation truth.
        if let race = maskRaceAnimator, race.state == .active {
            race.stopAnimation(false)
            race.finishAnimation(at: .current)
        }
        maskRaceAnimator = nil
        // Blend baseline: updateDrag morphs from the caught pose onto the
        // drag rule over the first stretch of new finger travel.
        regrabTransform = detailView.transform
        regrabMaskFrame = maskView?.frame ?? .zero
        regrabMaskRadius = maskView?.layer.cornerRadius ?? 0
        // Re-establish the held-drag scene in one grab beat: shadow back up,
        // scrim/home to their hold values, the resting hero crop, and any
        // mid-commit page-N cover fade undone.
        liftShadow(over: 0.15)
        // Capture the RETIRING cover locally: a quick re-release within
        // these 0.15s starts a new collapse that assigns a NEW coverFade —
        // a completion reading the property at fire time would remove the
        // new flight's cover and land page-N pixels over a page-1 card.
        let retiringCover = coverFade
        UIView.animate(withDuration: 0.15) {
            self.scrim?.alpha = DragTuning.dragScrimAlpha
            self.homeView?.transform = self.recedeTransform(0.94)
            detail.setHeroCrop(flight: false)
            detail.setHeroCurtain(0) // the live screen returns beneath the caught card
            self.sceneOverlayHost?.view.alpha = 0 // chrome retreats with the catch
            self.landingShadowRig?.alpha = 0 // the caught card sheds its landing shadow
            detailView.layoutIfNeeded()
            retiringCover?.alpha = 0
        } completion: { _ in
            retiringCover?.removeFromSuperview()
            if self.coverFade === retiringCover { self.coverFade = nil }
        }
        return true
    }

    /// A grab seized the OPEN morph: the presentation never armed a
    /// dismissal, so build the drag rule's world from the pose the fold
    /// left on screen. The open's layered mask becomes a standard dismissal
    /// mask at its caught geometry; the rule's rects come from the geometry
    /// present() recorded (no forced layout pass mid-grab). The landing
    /// target is re-measured from the live marker — but a catch necessarily
    /// happens inside the card's press-release spring, so keep the measured
    /// CENTER (the press is center-anchored) and take the SIZE from the
    /// marker's untransformed bounds, the same normalization present()
    /// bakes into presentSourceRect (which remains the dead-marker
    /// fallback).
    private func armFromCaughtOpen() {
        guard let detail, let detailView, let root else { return }
        isInteracting = true
        detail.prepareForCollapse() // idempotent; scrolls already frozen
        detail.markInFlight()
        // A caught drag is a live dismissal drag — content touches return
        // to their normal-drag state (the finger owns the screen anyway).
        detail.setContentTouchesEnabled(true)
        // The fold wrote mid-morph frames into a CLEAN resting-constraint
        // tree: the shared tail's setHeroCrop(flight: false) is a guard
        // no-op here, so dirty the page layout explicitly — the tail's
        // ANIMATED layoutIfNeeded then carries the caught crop home.
        detail.setHeroNeedsCropLayout()
        pinHomeOffset() // match armDismissal: settle on drift-free geometry
        let held = homeView?.transform ?? .identity
        homeView?.transform = .identity
        let live = root.view.convert(home?.cardFrame ?? .zero, from: home?.view)
        homeView?.transform = held
        if live.width >= 1 {
            let restingSize = home?.activeSource?.bounds.size ?? live.size
            sourceRect = CGRect(
                x: live.midX - restingSize.width / 2,
                y: live.midY - restingSize.height / 2,
                width: restingSize.width, height: restingSize.height)
        } else {
            sourceRect = presentSourceRect
        }
        let caught = detailView.mask
        let mask = UIView(frame: caught?.frame ?? detailView.bounds)
        mask.backgroundColor = .black
        mask.layer.cornerRadius = caught?.layer.cornerRadius ?? displayRadius
        mask.layer.cornerCurve = .continuous
        detailView.mask = mask
        maskView = mask
        heroRect = presentRestingHeroRect
        anchor = CGPoint(x: heroRect.midX, y: heroRect.midY)
        installCardChrome()
    }

    // Lift and drop each retire the opposing animation: they are
    // non-additive on one property, so a stale sibling under the other key
    // would re-expose when the newer one auto-removes.
    private func liftShadow(over duration: TimeInterval) {
        guard let layer = shadowHost?.layer else { return }
        let lift = CABasicAnimation(keyPath: "shadowOpacity")
        lift.fromValue = layer.presentation()?.shadowOpacity ?? layer.shadowOpacity
        lift.toValue = ZoomStyle.flightShadowOpacity
        lift.duration = duration
        layer.removeAnimation(forKey: "shadowDrop")
        layer.shadowOpacity = ZoomStyle.flightShadowOpacity
        layer.add(lift, forKey: "shadowLift")
    }

    private func dropShadow(over duration: TimeInterval) {
        guard let layer = shadowHost?.layer else { return }
        let drop = CABasicAnimation(keyPath: "shadowOpacity")
        drop.fromValue = layer.presentation()?.shadowOpacity ?? layer.shadowOpacity
        drop.toValue = 0
        drop.duration = duration
        layer.removeAnimation(forKey: "shadowLift")
        layer.shadowOpacity = 0
        layer.add(drop, forKey: "shadowDrop")
    }

    private func normalized(_ velocity: CGPoint, over distance: CGFloat) -> CGFloat {
        min(max(velocity.y / max(distance, 1), 0), 4)
    }

    /// Resolves a dismissal. `completed` dismantles the whole presentation
    /// (the card landed home); `!completed` returns the persistent scene to
    /// its presented rest state (the cancel's spring already restored the
    /// scrim/recede — only the dismissal-armed extras retire).
    private func teardown(completed: Bool) {
        #if DEBUG
        perfMark(completed ? "landed" : "cancelled")
        perfEnd()
        if completed, let root, let home {
            let marker = root.view.convert(home.cardFrame, from: home.view)
            let flown = detailView.map { root.view.convert(heroRect, from: $0) }
            print(String(format: "LANDCHK arm=%.2f flown=%.2f marker=%.2f off=%.2f inset=%.2f",
                         sourceRect.minY, flown?.minY ?? -999, marker.minY,
                         homeScroll?.contentOffset.y ?? -999,
                         homeScroll?.adjustedContentInset.top ?? -999))
        }
        #endif
        detailView?.mask = nil
        maskView = nil
        // Completed: the landed chrome copy bridges the SwiftUI card's
        // re-render (same trick as the image landing overlay). Cancelled:
        // it just leaves with the arming.
        if let overlayView = sceneOverlayHost?.view {
            if completed, let marker = home?.activeSource {
                // Adoption assigns frame — undefined on a transformed view,
                // and fail-safe teardowns can arrive with the rig transform
                // still mid-flight.
                overlayView.transform = .identity
                marker.adoptLandingOverlay(overlayView)
            } else {
                overlayView.removeFromSuperview()
            }
        }
        sceneOverlayHost = nil
        isInteracting = false
        flightIsDismissal = false
        stopDive()
        flightAnimator = nil
        if let race = maskRaceAnimator, race.state == .active {
            race.stopAnimation(false)
            race.finishAnimation(at: .current)
        }
        maskRaceAnimator = nil
        // The rig leaves in the SAME transaction as the completed path's
        // setCardHidden(false) raised the marker's identical shadow — an
        // atomic swap, never a double-composite and never a gap.
        landingShadowRig?.removeFromSuperview()
        landingShadowRig = nil
        if let open = openAnimator, open.state == .active {
            open.stopAnimation(false)
            open.finishAnimation(at: .current)
        }
        openAnimator = nil
        retireOpenObserver()
        regrabTransform = nil
        coverFade = nil
        if completed {
            // Fail-safe paths reach here without the animator completion's
            // unhide — never leave the home card permanently invisible.
            if home?.activeSource?.state?.isHidden == true {
                home?.setCardHidden(false)
            }
            // The collapse spring already flew the home plane back to
            // identity and the scrim to clear; dismantle the presentation.
            shadowHost?.removeFromSuperview()
            scrim?.removeFromSuperview()
            shadowHost = nil
            scrim = nil
            homeView?.transform = .identity
            // Hand the plane back its window-sized canvas. Content is
            // top-anchored, so the restore is invisible.
            setHomeCanvas(grown: false)
            // The un-recede reprojects safe areas one last time, which can
            // nudge the home scroll's insets and drift its offset AFTER a
            // pixel-exact landing — pin now, after the hierarchy settles,
            // and once more on the next runloop pass.
            pinHomeOffset()
            root?.presentationDidEnd()
            pinHomeOffset()
            DispatchQueue.main.async { [weak self] in
                self?.pinHomeOffset()
                self?.homeScroll = nil
            }
        } else {
            // Back to presented rest: scene persists, ready to re-arm.
            shadowHost?.layer.shadowOpacity = 0
            detail?.markLanded()
            // A caught-then-cancelled OPEN settles here without ever
            // landing the open animator — the bar hand-off happens now
            // (no-op when the open already landed it).
            root?.detailDidTakeStatusBar()
        }
    }
}
