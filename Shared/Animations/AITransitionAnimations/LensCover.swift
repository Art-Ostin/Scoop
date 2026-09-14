//
//  LensCover.swift
//  Scoop
//
//  Created by Art Ostin on 13/09/2026.
//

import SwiftUI
import UIKit

//A full-screen cover that opens out of a circular photo and closes back into it: the pending invites lens
//(`.eventZoom`'s `.circle` source) with a whole screen for its card. Underneath it is a real `fullScreenCover`,
//presented without the system animation on a clear background (InstantKeyboard's `instantSlide` recipe), so the
//screen it hosts keeps everything a cover gives it — its `dismiss()`, the keyboard, its own navigation — while
//the flight runs inside.
//
//    @State private var lens = LensCoverSource()
//    avatar.lensCoverSource(lens, image: photo)                   //The circle that lifts off and lands back
//    screen.lensCover(isPresented: $shown, source: lens) { … }    //Where `.fullScreenCover` would go
//    photo.lensCoverTarget(image:cornerRadius:)                   //Inside the cover: the photo it grows into

extension View {

    ///The circle a lens cover opens out of. It hides while its photo is out flying. `inToolbarPlatter`: the circle sits in
    ///a toolbar item, whose iOS 26 glass is its ring — a close flying home hides that glass and lands the photo wearing a
    ///rim grown out of its edge to the same size (the pending invites lens' ring).
    func lensCoverSource(_ source: LensCoverSource, image: UIImage, inToolbarPlatter: Bool = false) -> some View {
        modifier(LensCoverSourceModifier(source: source, image: image, inToolbarPlatter: inToolbarPlatter))
    }

    ///Presents `content` full-screen, grown out of `source` into the photo inside it marked `.lensCoverTarget`, and
    ///flown back into the circle on every close: the content's own `dismiss()`, a swipe down from the top of its
    ///scroll, or `isPresented` set false. With no marked photo on screen (an edit screen, reduce motion) it
    ///arrives and leaves by fade. The content's `interactiveDismissDisabled` also holds off the swipe.
    func lensCover<Content: View>(isPresented: Binding<Bool>, source: LensCoverSource,
                                  @ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(LensCoverModifier(isPresented: isPresented, source: source, coverContent: content))
    }

    ///The photo a lens cover grows into and collapses back out of. A no-op outside a lens cover.
    func lensCoverTarget(image: UIImage, cornerRadius: CGFloat) -> some View {
        modifier(LensCoverTargetModifier(image: image, cornerRadius: cornerRadius))
    }
}

//MARK: - Source and target

//The circle's side of the flight, owned by the screen that shows it
@MainActor
@Observable
final class LensCoverSource {
    private(set) var vacated = false //The photo is out flying: the circle hides, so it is never on screen twice
    @ObservationIgnored var rect: CGRect = .zero //Global, refreshed on every layout: a close re-reads it, so the photo lands where the circle IS
    @ObservationIgnored var image: UIImage?
    @ObservationIgnored var pressPose: PressPose = .rest //The circle's press as rendered, this frame: the copy takes off wearing it
    @ObservationIgnored weak var platter: UIView? //The toolbar glass the circle sits in, found by its probe: its ring

    init() {}

    //The ring's width as drawn right now: the platter's glass beyond the circle's edge. None without a platter, or around
    //one that isn't a circle concentric with it — a rim can only land on glass it matches
    var ringWidth: CGFloat {
        guard let platter, platter.window != nil, rect.width > 1 else { return 0 }
        let glass = platter.convert(platter.bounds, to: nil)
        guard abs(glass.width - glass.height) < 1, abs(glass.midX - rect.midX) < 1, abs(glass.midY - rect.midY) < 1 else { return 0 }
        return max((glass.width - rect.width) / 2, 0)
    }

    func setVacated(_ vacated: Bool) {
        if self.vacated != vacated { self.vacated = vacated }
    }

    func setRingHidden(_ hidden: Bool) {
        guard let platter, platter.isHidden != hidden else { return }
        platter.isHidden = hidden
    }
}

private struct LensCoverSourceModifier: ViewModifier {

    //Injected
    let source: LensCoverSource
    let image: UIImage
    let inToolbarPlatter: Bool

    func body(content: Content) -> some View {
        content
            .background {
                if inToolbarPlatter {
                    LensCoverPlatterProbe(source: source)
                        .frame(width: 0, height: 0)
                }
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { source.rect = $0 }
            //Outside the press, so the resting frame is measured — and the press itself arrives as a preference
            .onPreferenceChange(PressPoseKey.self) { pose in
                MainActor.assumeIsolated { source.pressPose = pose }
            }
            .onAppear { source.image = image }
            .onChange(of: image) { _, image in source.image = image }
            .opacity(source.vacated ? 0 : 1)
    }
}

private struct LensCoverTargetModifier: ViewModifier {

    //Injected
    let image: UIImage
    let cornerRadius: CGFloat
    @Environment(LensCoverFlight.self) private var flight: LensCoverFlight?

    //Local view state
    @State private var key = UUID() //This photo's slot among the ones reporting — every page of a pager does

    @ViewBuilder
    func body(content: Content) -> some View {
        if let flight {
            content
                //In the content's own space, declared inside the morph: the drag's ride never reaches a report
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(LensCoverFlight.contentSpace)) } action: { rect in
                    flight.reportTarget(key, rect: rect, image: image, cornerRadius: cornerRadius)
                }
                .onDisappear { flight.removeTarget(key) }
                .opacity(flight.targetHidden ? 0 : 1) //The flying copy stands in for it: a live photo beside the copy would show twice
        } else {
            content
        }
    }
}

//Finds the glass iOS 26 draws around the toolbar item a circle sits in: the system's `PlatterView`, walking up from inside
//the item. Its lens is drawn by the bar, not the platter, but follows the platter's `isHidden` — gone the next frame and
//back the next, with nothing between, no layout change and taps intact (sim-measured under a cover and under frost; a
//scale leaves the platter's shadow behind). Pre-26, or if the class is ever renamed, there is nothing to find.
private struct LensCoverPlatterProbe: UIViewRepresentable {

    //Injected
    let source: LensCoverSource

    func makeUIView(context: Context) -> Probe { Probe(source: source) }

    func updateUIView(_ probe: Probe, context: Context) {}

    //A circle that leaves mid-close must never take its ring's visibility with it
    static func dismantleUIView(_ probe: Probe, coordinator: ()) {
        probe.release()
    }

    final class Probe: UIView {

        private let source: LensCoverSource
        private weak var platter: UIView?

        init(source: LensCoverSource) {
            self.source = source
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func didMoveToWindow() { super.didMoveToWindow(); find() }
        override func layoutSubviews() { super.layoutSubviews(); find() } //The bar rebuilds its items across a push and pop

        func release() {
            if let platter, platter.isHidden { platter.isHidden = false }
            if source.platter === platter { source.platter = nil }
        }

        private func find() {
            guard window != nil else { return }
            var view = superview
            while let current = view {
                //Walking up, the platter's own glass (`PlatterGlassView`) comes first, and doesn't match
                if String(describing: type(of: current)).contains("PlatterView") {
                    platter = current
                    source.platter = current
                    return
                }
                view = current.superview
            }
        }
    }
}

//MARK: - The cover

private struct LensCoverModifier<CoverContent: View>: ViewModifier {

    //Injected
    @Binding var isPresented: Bool
    let source: LensCoverSource
    let coverContent: () -> CoverContent

    //Local view state
    @State private var coverShown = false //The real cover outlives `isPresented`: it leaves only once the photo has landed
    @State private var flight: LensCoverFlight? //One per presentation

    //The cover's own dismissal — the content's `dismiss()` — asks for the flight home instead of dropping the cover
    private var coverBinding: Binding<Bool> {
        Binding {
            coverShown
        } set: { shown in
            if !shown { flight?.close() }
        }
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, shown in
                if shown { present() } else { flight?.close() }
            }
            .fullScreenCover(isPresented: coverBinding) {
                if let flight {
                    LensCoverScene(flight: flight, content: coverContent)
                }
            }
    }

    private func present() {
        guard !coverShown else { return }
        let flight = LensCoverFlight(source: source)
        //Bindings, never `self`: the flight lives in this modifier's state, and a captured modifier would keep it alive
        let shown = $coverShown
        let presented = $isPresented
        flight.onFinished = {
            withTransaction(instantTransaction()) { shown.wrappedValue = false }
            if presented.wrappedValue { presented.wrappedValue = false }
        }
        self.flight = flight
        withTransaction(instantTransaction()) { coverShown = true } //No system animation: the flight is the transition
    }
}

private struct LensCoverScene<Content: View>: View {

    //Injected
    let flight: LensCoverFlight
    let content: () -> Content

    var body: some View {
        ZStack {
            EventBackdrop() //The pending card's frost: in with the flight, giving way as a drag commits, out on the close's clock
                .opacity(flight.backdropOpacity)

            LensCoverContent(id: flight.id, content: content)
                .equatable() //The flight re-renders this scene every frame; the caller's screen is built once
                .coordinateSpace(.named(LensCoverFlight.contentSpace)) //Inside the morph, so the photo reports its rest pose
                .environment(flight)
                .environment(\.zoomDismiss, flight.dismissAction) //
                .allowsHitTesting(flight.interactive)
                .modifier(flight.morph)
        }
        //The content's own frame, measured outside the morph: the space every flight rect is posed in
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight.setContentFrame($0) }
        .background {
            LensCoverPanProbe(flight: flight)
                .frame(width: 0, height: 0)
        }
        .opacity(flight.contentFrame.width > 1 ? flight.fade : 0) //Nothing draws before the space it is posed in is measured
        .presentationBackground(.clear)
        .onAppear { flight.sceneAppeared() }
    }
}

private struct LensCoverContent<Content: View>: View, Equatable {

    //Injected
    let id: UUID
    let content: () -> Content

    var body: some View { content() }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

//MARK: - The flight

@MainActor
@Observable
final class LensCoverFlight {

    struct Target {
        var rect: CGRect //In the content's own space
        var image: UIImage
        var cornerRadius: CGFloat
    }

    nonisolated static let contentSpace = "lensCoverContent"

    //The pending lens' clocks (EventZoomChoreo), mirrored: the calendar's lens and this cover are one motion, so
    //retune them together. `-eventZoomSlow` stretches both.
    private static let timeScale = EventZoomChoreo.timeScale
    private static let openDuration = 0.32 * timeScale //The invite popup's 0.34s open, less 0.02
    private static let openFlight = Animation.spring(duration: openDuration, bounce: 0.1)
    //The landing's give: a uniform swell of what flies, rising early and long while the flight still has speed,
    //settled on a lightly under-damped spring from the peak
    private static let breathRise = Animation.timingCurve(0.25, 0, 0.9, 1, duration: openDuration * 0.7).delay(openDuration * 0.3)
    private static let breathSettle = Animation.spring(duration: openDuration * 1.3, bounce: 0.18).delay(openDuration)
    private static let openChrome = Animation.spring(duration: 0.34 * timeScale, bounce: 0.25)
    private static let closeDuration = 0.32 * timeScale
    private static let closeFlight = Animation.spring(duration: closeDuration, bounce: 0.15)
    private static let closeChrome = Animation.smooth(duration: 0.25 * timeScale)
    //A tap's landing: the photo compresses into the circle over the flight's last fifth and rebounds past rest,
    //both issued in one commit so they blend into one motion
    private static let landingDip: CGFloat = 0.86
    private static let landingDipIn = Animation.smooth(duration: closeDuration * 0.2).delay(closeDuration * 0.8)
    private static let landingRebound = Animation.spring(duration: 0.32 * timeScale, bounce: 0.55).delay(closeDuration)
    private static let snapBack = Spring(duration: 0.3, bounce: 0.2) //A drag that didn't commit: the invite card's overshooting return

    private static let commitDistance: CGFloat = 90 //Rubber-banded descent that commits a swipe down
    //pt/s down that commits one sooner: the pending card's 90pt flick. SwiftUI projects a quarter second of release
    //speed past the finger (sim-logged: 1546pt/s predicted 387pt on), which a UIKit pan doesn't report
    private static let commitVelocity: CGFloat = 360
    private static let targetWait = Duration.milliseconds(400) //How long a screen gets to report its photo before it arrives by fade

    @ObservationIgnored let id = UUID()
    @ObservationIgnored var onFinished: () -> Void = {}
    @ObservationIgnored var onDragSettled: () -> Void = {} //The swipe's frozen scrolls go back to their owner once a drag springs home
    @ObservationIgnored private(set) var dismissAction = ZoomDismissAction(run: {}) //Built once: a fresh action per render would re-render the screen's readers every frame
    @ObservationIgnored private let source: LensCoverSource
    @ObservationIgnored private let flies: Bool //A circle to leave from, and motion allowed; otherwise the cover fades

    //The pose: every frame re-derives from these
    private(set) var p: CGFloat //0 on the circle, 1 landed on the photo
    private(set) var breath: CGFloat = 0
    private(set) var landing: CGFloat = 1
    private(set) var drag: CGSize = .zero //The dismiss drag's raw translation
    private(set) var chrome: CGFloat = 0
    private(set) var fade: CGFloat
    fileprivate private(set) var wind = LensCoverWind() //A flick's close: its arc off the straight path home, and the pop it lands with

    //The gates
    private(set) var landed = false
    private(set) var closing = false
    private(set) var dragging = false //A finger owns the screen: the content takes no touches, so a swipe begun on a button never fires it
    private(set) var coverShown: Bool //The flying copy of the photo
    private(set) var targetHidden: Bool //The live photo, while the copy stands in for it
    private(set) var sourceRect: CGRect
    private(set) var target: Target? //The photo this flight grows into or leaves from, frozen for the flight
    private(set) var coverImage: UIImage?
    private(set) var landingImage: UIImage? //The circle's own picture, which a close from another page crossfades to while small
    private(set) var pressPose: PressPose = .rest //The circle's press when the copy took its place
    private(set) var homing = false //A close is flying the photo home: the only stretch the circle's ring is away and the rim grows
    private(set) var rimWidth: CGFloat = 0 //The circle's ring as the close began: the rim the photo lands wearing

    //The content's global frame. The flight draws in the content's own space — its overlay, mask and background share
    //it — never in a full-screen layer, whose origin depends on how the safe area resolves (sim-logged: a
    //`.ignoresSafeArea()` layer measured at y 62 while its sibling drew at 0)
    private(set) var contentFrame: CGRect = .zero

    //Measurements and bookkeeping: read, never observed
    @ObservationIgnored weak var windowView: UIView? //The pan probe: the window's bounds, and the display's corners once its safe area is known
    @ObservationIgnored private var targets: [UUID: Target] = [:]
    @ObservationIgnored private var hasOpened = false
    @ObservationIgnored private var flew = false //The open flew (not faded): only then can a drag fold toward the photo or a close fly home
    @ObservationIgnored private var flightDone = false //The open's spring has been removed: the copy is exactly on the photo
    @ObservationIgnored private var settled = false //The open's swell has come to rest: only a still screen is grabbable
    @ObservationIgnored private var finished = false
    @ObservationIgnored private let windDriver = LensCoverWindDriver()

    init(source: LensCoverSource) {
        let flies = source.rect.width > 1 && (source.image?.size.width ?? 0) > 0 && !UIAccessibility.isReduceMotionEnabled //A placeholder UIImage() has nothing to fly
        self.source = source
        self.flies = flies
        sourceRect = source.rect
        coverImage = source.image
        p = flies ? 0 : 1
        fade = flies ? 1 : 0
        coverShown = flies
        targetHidden = flies
        dismissAction = ZoomDismissAction(run: { [weak self] in self?.close() })
    }

    var interactive: Bool { landed && !closing && !dragging }

    //From the flight's arrival, as the pending card is: a swell still settling is let out by the drag's fold
    var canDrag: Bool { flew && flightDone && !closing && !dragging && visibleTarget() != nil }

    var windowBounds: CGRect { windowView?.window?.bounds ?? .zero }

    //The pending card's frost: in on the open's chrome clock, giving way as a drag descends, out on the close's
    var backdropOpacity: Double {
        Double(chrome) * (1 - 0.5 * Double(min(max(Self.rubberBanded(drag.height) / 300, 0), 1)))
    }

    //Read per pose rather than at attach: the window's safe area, which picks the display class, is still zero then
    var displayRadius: CGFloat { windowView.map { estimatedDisplayCornerRadius(around: $0) } ?? 0 }

    fileprivate var morph: LensCoverMorph {
        LensCoverMorph(p: p, breath: breath, landing: landing, drag: drag, wind: wind,
                       closing: closing, resting: landed && !closing, homing: homing,
                       source: sourceRect, target: target, coverImage: coverImage, landingImage: landingImage,
                       coverShown: coverShown, pressPose: pressPose, rimWidth: rimWidth,
                       windowBounds: windowBounds, contentFrame: contentFrame, displayRadius: displayRadius)
    }

    func setContentFrame(_ frame: CGRect) {
        guard frame != contentFrame else { return }
        let first = contentFrame.width <= 1
        withTransaction(instantTransaction()) {
            contentFrame = frame
            //The circle hides in the commit the copy first draws on its pixels — where it is drawn right now, wearing the
            //press it is in (a button releasing around it moves and scales it until then)
            if first, flies, !hasOpened {
                sourceRect = source.rect
                pressPose = source.pressPose
            }
        }
        if first, flies, !hasOpened { source.setVacated(true) }
        openWhenMeasured()
    }

    func windowDidAttach() {
        openWhenMeasured()
    }
}

//The open
extension LensCoverFlight {

    func sceneAppeared() {
        guard flies else {
            hasOpened = true
            withAnimation(.transition) { fade = 1 } completion: { [weak self] in self?.land() }
            return
        }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.targetWait)
            self?.fadeInWithoutTarget()
        }
    }

    func reportTarget(_ key: UUID, rect: CGRect, image: UIImage, cornerRadius: CGFloat) {
        targets[key] = Target(rect: rect, image: image, cornerRadius: cornerRadius)
        openWhenMeasured()
    }

    func removeTarget(_ key: UUID) {
        targets[key] = nil
    }

    private func openWhenMeasured() {
        guard flies, !hasOpened, !closing, contentFrame.width > 1, let target = visibleTarget() else { return }
        hasOpened = true
        withTransaction(instantTransaction()) { self.target = target }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(30)) //One committed frame on the circle before the flight leaves it
            self?.fly()
        }
    }

    private func fly() {
        guard !closing else { return }
        flew = true
        //The live photo takes over once both have finished: the spring's removal, where p is exactly 1, and the swell,
        //which only the flying copy wears — then the copy is the photo's pixels
        var flight = Transaction(animation: Self.openFlight)
        flight.addAnimationCompletion(criteria: .removed) { [weak self] in
            self?.flightDone = true
            self?.land()
        }
        withTransaction(flight) { p = 1 }
        withAnimation(Self.breathRise) { breath = 1 }
        withAnimation(Self.breathSettle, completionCriteria: .logicallyComplete) { breath = 0 } completion: { [weak self] in
            self?.settled = true
            self?.land()
        }
        withAnimation(Self.openChrome) { chrome = 1 }
    }

    //A screen with no marked photo never reports one: it arrives by fade instead, the circle staying put
    private func fadeInWithoutTarget() {
        guard !hasOpened, !closing else { return }
        hasOpened = true
        withTransaction(instantTransaction()) {
            fade = 0
            p = 1
            coverShown = false
            targetHidden = false
        }
        source.setVacated(false)
        withAnimation(.transition) { fade = 1 } completion: { [weak self] in self?.land() }
    }

    private func land() {
        guard !closing, !landed else { return }
        if coverShown, !(flightDone && settled) { return } //The copy is still flying or swelling over the page
        settled = true //A fade had nothing to swell
        withTransaction(instantTransaction()) {
            landed = true
            targetHidden = false //The live photo takes over on identical pixels…
            coverShown = false   //…in the commit the copy leaves
            pressPose = .rest
        }
    }

    //The photo the screen is showing: on screen, and nearest its middle across a pager's pages
    private func visibleTarget() -> Target? {
        let window = windowBounds.offsetBy(dx: -contentFrame.minX, dy: -contentFrame.minY)
        guard window.width > 1, contentFrame.width > 1 else { return nil }
        return targets.values
            .filter { $0.rect.width > 1 && $0.rect.intersects(window) }
            .min { abs($0.rect.midX - window.midX) < abs($1.rect.midX - window.midX) }
    }
}

//The close
extension LensCoverFlight {

    ///Flies the screen home into its circle — or fades it out, with no photo on screen to fly from
    func close() {
        close(velocity: 0, sideVelocity: 0, byDrag: false)
    }

    private func close(velocity: CGFloat, sideVelocity: CGFloat, byDrag: Bool) {
        guard !closing else { return }
        //Where the photo IS: reports carry no ride, so a landed screen's page and scroll are exact even under a live
        //drag; an open still in the air keeps its own target
        let home = landed ? visibleTarget() : target
        let fliesHome = flew && coverImage != nil && source.rect.width > 1 && !UIAccessibility.isReduceMotionEnabled

        guard fliesHome, let home else {
            withTransaction(instantTransaction()) {
                closing = true
                dragging = false
            }
            source.setVacated(false) //The circle is back beneath the fading screen
            withAnimation(.dismiss) { fade = 0 } completion: { [weak self] in self?.finish() }
            return
        }

        let rimWidth = source.ringWidth //The ring as drawn now, where the photo will land
        withTransaction(instantTransaction()) {
            closing = true
            dragging = false
            homing = true //The rim mounts here, dark, before anything moves
            self.rimWidth = rimWidth
            sourceRect = source.rect
            target = home
            coverImage = home.image
            landingImage = source.image
            coverShown = true //Back over the live photo on its own pixels before anything moves
            targetHidden = true
            pressPose = .rest
        }
        source.setVacated(true)
        //The circle's own ring hides in this same turn (the pending lens' `onClosing`), behind the still-full frost: the
        //circle stays bare until the photo lands its own rim on it
        if rimWidth > 0 { source.setRingHidden(true) }

        //The pending lens' split: a flick flies the wind's arc, a finger let go slowly takes the plain morph home, and
        //a tap lands with the dip
        if velocity >= DragTuning.arcSlowMorphCeil {
            closeWithWind(velocity: velocity, sideVelocity: sideVelocity, home: home)
        } else if byDrag {
            withAnimation(Self.closeChrome) { chrome = 0 }
            withAnimation(Self.closeFlight, completionCriteria: .removed) { p = 0 } completion: { [weak self] in
                self?.finish()
            }
        } else {
            withAnimation(Self.closeChrome) { chrome = 0 }
            withAnimation(Self.closeFlight) { p = 0 }
            withAnimation(Self.landingDipIn) { landing = Self.landingDip }
            //Logically complete: the rebound's sub-percent tail is invisible on a 32pt circle, and the cover must not
            //swallow taps on the screen beneath while it creeps
            withAnimation(Self.landingRebound, completionCriteria: .logicallyComplete) { landing = 1 } completion: { [weak self] in
                self?.finish()
            }
        }
    }

    //A flick's close: the pending lens' wind (`EventZoomChoreo.closeWithWind`) on the WindFlightPlan the profile zoom
    //flies too. The photo carries on down with the finger's speed, is gusted home, and brakes into the circle with a
    //bounce its arrival earns; size and fold run on the plan's geometry clock, done by arrival, the backdrop on its pace
    //clock. The plan owns the vertical, a Hermite the horizontal, and the morph draws both as the arc's deviation from
    //its straight path.
    private func closeWithWind(velocity: CGFloat, sideVelocity: CGFloat, home: Target) {
        //In the morph's space, with the drag's ride folded in: where the finger let the photo go
        let origin = contentFrame.origin
        let src = sourceRect.offsetBy(dx: -origin.x, dy: -origin.y)
        let ride = Self.ride(drag)
        let dest = home.rect.offsetBy(dx: ride.width, dy: ride.height)
        let lensCenter = CGPoint(x: src.midX, y: src.midY)
        let slope: CGFloat = drag.height <= 0 ? 0.2 : (drag.height < 150 ? 1 : 0.55) //The band's give where the finger let go
        let plan = WindFlightPlan.solve(
            u0: dest.midY - lensCenter.y,
            v0: velocity * DragTuning.lerp(slope, 1, DragTuning.windFingerFollow),
            fingerVy: velocity,
            uCap: windowBounds.height - DragTuning.windDiveVisibleBand - max(sourceRect.midY, 0),
            aboveScreenExtra: DragTuning.aboveScreenTime(destinationTop: sourceRect.minY),
            durationScale: 1) //Never timeScale: the solve is physics — `-eventZoomSlow` slows the clock below instead
        let x0 = dest.midX
        let xT = lensCenter.x
        let vx0 = min(max(sideVelocity * DragTuning.rubberBandSlope(drag.width, limit: 160, response: 0.8), -900), 900)
        let driver = windDriver

        driver.run { [weak self] raw in
            guard let self else { return driver.stop() }
            let elapsed = raw / Self.timeScale
            let (u, du) = plan.state(at: elapsed)
            if plan.shouldLand(elapsed: elapsed, u: u, du: du) {
                driver.stop()
                withTransaction(instantTransaction()) {
                    self.p = 0
                    self.chrome = 0
                    self.wind = LensCoverWind()
                }
                finish()
                return
            }
            let geo = CGFloat(min(max(elapsed / plan.tGeo, 0), 1))
            let flightP = 1 - DragTuning.smoothstep(geo)
            let t2 = geo * geo, t3 = t2 * geo
            let x = (2 * t3 - 3 * t2 + 1) * x0 + (t3 - 2 * t2 + geo) * vx0 * CGFloat(plan.tGeo) + (-2 * t3 + 3 * t2) * xT
            let straight = CGPoint(x: lerp(src.midX, dest.midX, flightP), y: lerp(src.midY, dest.midY, flightP))
            let pace = CGFloat(min(max(elapsed / plan.tPace, 0), 1))
            withTransaction(instantTransaction()) {
                self.p = flightP
                self.chrome = 1 - pace
                self.wind = LensCoverWind(offset: CGSize(width: x - straight.x, height: lensCenter.y + u - straight.y),
                                     pop: plan.settlePop(u: u, at: elapsed))
            }
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        windDriver.stop()
        //The circle takes its pixels back in the commit the copy leaves, on identical pixels — and the scene goes dark in
        //it too, so nothing the cover draws can show while UIKit tears it down (sim: after a swipe close, a copy slid
        //down into the avatar a beat after it had landed)
        withTransaction(instantTransaction()) {
            coverShown = false
            fade = 0
            if homing { homing = false } //The rim leaves with the copy…
        }
        source.setVacated(false)
        source.setRingHidden(false) //…and the circle's ring is back, full-size, in the same commit: identical pixels
        let done = onFinished
        onFinished = {}
        onDragSettled = {}
        done()
    }
}

//The dismiss drag
extension LensCoverFlight {

    func beginDrag() {
        withTransaction(instantTransaction()) { dragging = true }
    }

    func dragChanged(_ translation: CGSize) {
        guard dragging, !closing else { return }
        drag = translation
    }

    func dragEnded(translation: CGSize, velocity: CGSize, cancelled: Bool) {
        guard dragging, !closing else { return }
        let descent = Self.rubberBanded(translation.height)
        if !cancelled, descent > Self.commitDistance || velocity.height > Self.commitVelocity {
            close(velocity: max(velocity.height, 0), sideVelocity: velocity.width, byDrag: true) //The drag stays in the pose: the flight home carries it out
            return
        }
        withTransaction(instantTransaction()) { dragging = false }
        let speed = min(max(-velocity.height, 0) / max(abs(descent), 1), 8)
        withAnimation(.interpolatingSpring(Self.snapBack, initialVelocity: speed), completionCriteria: .logicallyComplete) {
            drag = .zero
        } completion: { [weak self] in
            self?.onDragSettled()
        }
    }

    //Both axes follow the finger: down tracks it for 150pt, then gives; up resists; across is banded harder (the pending card's)
    static func ride(_ drag: CGSize) -> CGSize {
        CGSize(width: DragTuning.rubberBand(drag.width, limit: 160, response: 0.8), height: rubberBanded(drag.height))
    }

    //Down tracks the finger for 150pt, then gives; up resists — there is nothing above (the pending card's band)
    static func rubberBanded(_ dy: CGFloat) -> CGFloat {
        if dy <= 0 { return dy * 0.2 }
        let linear = min(dy, 150)
        return linear + max(dy - 150, 0) * 0.55
    }
}

//MARK: - The morph

//Animatable, so the body re-derives every frame from the interpolated pose: the photo is a circle while it is small
//because its radius comes from its current size, and the window of screen around it is revealed, never scaled.
private struct LensCoverMorph: ViewModifier, Animatable {

    var p: CGFloat
    var breath: CGFloat
    var landing: CGFloat
    var drag: CGSize
    let wind: LensCoverWind //Written per frame, never animated
    let closing: Bool
    let resting: Bool
    let homing: Bool //A close flying home: the only stretch the landing rim grows
    let source: CGRect //Global
    let target: LensCoverFlight.Target? //Content space
    let coverImage: UIImage?
    let landingImage: UIImage?
    let coverShown: Bool
    let pressPose: PressPose
    let rimWidth: CGFloat //The circle's ring: none, unless it sits in glass
    let windowBounds: CGRect
    let contentFrame: CGRect
    let displayRadius: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGSize.AnimatableData>> {
        get { AnimatablePair(AnimatablePair(p, breath), AnimatablePair(landing, drag.animatableData)) }
        set {
            p = newValue.first.first
            breath = newValue.first.second
            landing = newValue.second.first
            drag.animatableData = newValue.second.second
        }
    }

    //The open lands 1% early: SwiftUI removes a spring with a hair of travel left, and the live photo takes over at
    //that removal — the copy must already be exactly on it
    private static let settleShare: CGFloat = 0.99
    private static let collapseDistance: CGFloat = 240 //The descent that folds the whole screen into its photo — the pending card's
    private static let bleed: CGFloat = 1000 //A resting mask this far past the screen masks nothing
    private static let pressShed: CGFloat = 0.15 //The share of the open over which the copy lets go of the circle's press

    func body(content: Content) -> some View {
        let p = closing ? self.p : min(self.p / Self.settleShare, 1)

        //Everything posed in the content's own space, where its overlay, mask and background draw
        let origin = contentFrame.origin
        let bounds = windowBounds.offsetBy(dx: -origin.x, dy: -origin.y) //The whole window, past the safe area
        let src = source.offsetBy(dx: -origin.x, dy: -origin.y)
        let home = target?.rect ?? src
        let homeRadius = target?.cornerRadius ?? min(src.width, src.height) / 2

        //The drag: the screen rides the finger, and keeps its ride through a close as the pending card's column does,
        //while the window and the photo carry theirs out as p runs down. The fold collapses the screen onto its photo —
        //scrubbed by the drag's raw descent, and by a committed close over its first stretch, before the photo alone
        //flies the rest. No photo, no fold.
        let ride = LensCoverFlight.ride(drag)
        let dragFold = target == nil ? 0 : min(max(drag.height / Self.collapseDistance, 0), 1)
        let closeFold = closing ? smoothstep((1 - p) / 0.4) : 0
        let fold = max(closeFold, dragFold)

        //A flick's close flies an arc: its deviation from the straight path, riding the photo and the window alike
        let belly = wind.offset
        let cover = lerp(src, home.offsetBy(dx: ride.width, dy: ride.height), p).offsetBy(dx: belly.width, dy: belly.height)
        let coverRadius = max(lerp(min(cover.width, cover.height) / 2, homeRadius, p), 0)
        let body = lerp(src, bounds.offsetBy(dx: ride.width, dy: ride.height), p).offsetBy(dx: belly.width, dy: belly.height)
        let window = lerp(body, cover, fold)
        let windowRadius = max(lerp(lerp(min(window.width, window.height) / 2, displayRadius, p), coverRadius, fold), 0)
        let still = resting && p >= 1 && abs(drag.width) < 0.5 && abs(drag.height) < 0.5 //Landed and untouched: nothing masked, nothing cast

        //The pending lens' two scales: the wind's landing pop, a tap close's dip and the circle's press (shed over the
        //open's first stretch) about the photo's centre; then the open's swell about the card's centre — here the
        //screen's, so the photo swells up and out as the card does. Both act on what flies — the photo and the window
        //around it — never the live screen: a scaled scroll re-derives its insets and keeps the offset it drifted to
        //(sim-logged: the page settled 4.3pt up after the swell, and the photo's hand-off stepped by as much)
        let shed = closing ? 0 : 1 - smoothstep(p / Self.pressShed)
        let landingScale = wind.pop * landing * (1 + (pressPose.scale - 1) * shed)
        let breathScale = 1 + EventZoomChoreo.breathGain * breath * (1 - fold)
        let pivot = CGPoint(x: cover.midX, y: cover.midY)
        let centre = CGPoint(x: contentFrame.width / 2, y: contentFrame.height / 2)
        let scale = landingScale * breathScale
        let flyingCover = cover.scaled(by: landingScale, about: pivot).scaled(by: breathScale, about: centre)
        let flyingWindow = window.scaled(by: landingScale, about: pivot).scaled(by: breathScale, about: centre)

        //The landing rim, the pending lens' (`EventZoomMorph`): only a close flying home grows it — the open, a drag's scrub
        //and a fade never do. The copy's outline pushed out by a rim that grows over the collapse's back half, so the glass
        //visibly expands out of the photo's edge as it shrinks into its circle; sharing the photo's centre and both its
        //scales, it rides the wind's arc and pop and a tap's dip with it. The circle's own ring is away for exactly this
        //stretch, and back full-size in the commit this leaves
        let rim = homing ? rimWidth * smoothstep((1 - p - 0.55) / 0.4) : 0
        let flyingRim = cover.insetBy(dx: -rim, dy: -rim).scaled(by: landingScale, about: pivot).scaled(by: breathScale, about: centre)

        content
            .offset(ride) //Before the mask: the screen moves under the window that reveals it
            .mask {
                LensCoverShape(rect: still ? bounds.insetBy(dx: -Self.bleed, dy: -Self.bleed) : flyingWindow,
                               radius: still ? 0 : windowRadius * scale)
            }
            .background {
                LensCoverShape(rect: flyingWindow, radius: windowRadius * scale)
                    .shadow(.card, strength: still ? 0 : Double(min(max(self.p, 0), 1))) //The pending card's own, on the raw flight
            }
            .overlay { landingRim(rect: flyingRim, radius: (coverRadius + rim) * scale, rim: rim) } //Beneath the copy: the photo lands in its glass
            .overlay { photoCopy(cover: flyingCover, radius: coverRadius * scale, p: p, shed: shed) }
    }

    //Mounted only while a close flies home — inserted by the close's instant write before anything moves, removed by the
    //landing's — never at rest over the landed screen, which glass would wash even at opacity 0. Unclipped, so it wears
    //the toolbar glass' own halo (sim: within 2/255 of the platter; clipped glass lacks it, and would pop it in at the
    //hand-off). Dark until the rim has width, or its edge would fringe the copy
    @ViewBuilder
    private func landingRim(rect: CGRect, radius: CGFloat, rim: CGFloat) -> some View {
        if homing, rimWidth > 0 {
            Color.clear
                .frame(width: max(rect.width, 1), height: max(rect.height, 1))
                .containerGlassEffect(shape: RoundedRectangle(cornerRadius: radius)) //Concentric: the copy's corner plus the rim
                .opacity(rim > 0 ? 1 : 0)
                .position(x: rect.midX, y: rect.midY)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func photoCopy(cover: CGRect, radius: CGFloat, p: CGFloat, shed: CGFloat) -> some View {
        if let coverImage {
            ZStack {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
                //A close from another page crossfades to the circle's own picture while it is small, so the landing
                //hands off identical pixels
                if closing, let landingImage, landingImage !== coverImage {
                    Image(uiImage: landingImage)
                        .resizable()
                        .scaledToFill()
                        .opacity(smoothstep((0.35 - p) / 0.35))
                }
            }
            .frame(width: max(cover.width, 1), height: max(cover.height, 1))
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .brightness(pressPose.brightness * Double(shed))
            .opacity(coverShown ? 1 - (1 - pressPose.opacity) * Double(shed) : 0)
            .position(x: cover.midX, y: cover.midY)
            .allowsHitTesting(false)
        }
    }
}

//A rounded rect posed in the decorated view's own space; drawn past its bounds where the rect runs past them
private struct LensCoverShape: View {

    //Injected
    let rect: CGRect
    let radius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color.appCanvas) //The mask reads only its alpha; as the background, it is the surface that casts the shadow
            .frame(width: max(rect.width, 1), height: max(rect.height, 1))
            .position(x: rect.midX, y: rect.midY)
    }
}

//A flick's close, per frame: the arc's deviation from the straight path home, and the pop it lands with
private struct LensCoverWind: Equatable {
    var offset: CGSize = .zero
    var pop: CGFloat = 1
}

//The wind's clock (the pending lens' WindCloseDriver): its trajectory is a function of time, not a spring target SwiftUI
//can run
@MainActor
private final class LensCoverWindDriver {
    private var link: CADisplayLink?
    private var start: CFTimeInterval = 0
    private var onTick: ((TimeInterval) -> Void)?

    func run(_ tick: @escaping (TimeInterval) -> Void) {
        stop()
        onTick = tick
        start = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(fire))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120) //ProMotion: unasked, a link runs at 60Hz
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    @objc private func fire(_ link: CADisplayLink) {
        onTick?(link.timestamp - start)
    }

    func stop() {
        link?.invalidate()
        link = nil
        onTick = nil
    }
}

//MARK: - The swipe down

//A pan on the window, beside the content's own scrolls: it takes a drag only when it starts downward from a screen
//scrolled to its top with its photo showing, then holds those scrolls still so the screen moves as one piece (the
//profile zoom's dismiss pan, `ZoomDetailController.handleDismissPan`)
private struct LensCoverPanProbe: UIViewRepresentable {

    //Injected
    let flight: LensCoverFlight

    func makeCoordinator() -> Coordinator { Coordinator(flight: flight) }

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.isUserInteractionEnabled = false
        view.onWindow = { [weak view, coordinator = context.coordinator] window in
            guard let view else { return }
            coordinator.attach(to: window, probe: view)
        }
        return view
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {}

    static func dismantleUIView(_ uiView: ProbeView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class ProbeView: UIView {
        var onWindow: ((UIWindow) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window { onWindow?(window) }
        }
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        private let flight: LensCoverFlight
        private weak var probe: UIView?
        private var pan: UIPanGestureRecognizer?
        private var frozen: [UIScrollView] = []
        private var owned = false
        private var touchDown: CGPoint? //Where the finger landed: the drag's travel is measured from here, as a DragGesture's is

        init(flight: LensCoverFlight) {
            self.flight = flight
        }

        func attach(to window: UIWindow, probe: UIView) {
            self.probe = probe
            flight.windowView = probe
            flight.onDragSettled = { [weak self] in self?.settle() }
            flight.windowDidAttach()
            guard pan?.view !== window else { return }
            detach()
            //Only ever begins on a dismiss drag, so taking the touch — the button the swipe started on — is right
            let pan = UIPanGestureRecognizer(target: self, action: #selector(panned))
            pan.maximumNumberOfTouches = 1
            pan.delaysTouchesBegan = false
            pan.delaysTouchesEnded = false
            pan.delegate = self
            window.addGestureRecognizer(pan)
            self.pan = pan
        }

        func detach() {
            thaw()
            if let pan { pan.view?.removeGestureRecognizer(pan) }
            pan = nil
            owned = false
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if !owned { touchDown = touch.location(in: gestureRecognizer.view) }
            return true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer, flight.canDrag, !dismissalDisabled else { return false }
            let velocity = pan.velocity(in: pan.view)
            guard velocity.y > 0, velocity.y >= abs(velocity.x) else { return false } //Horizontals belong to the pager, ups to the scroll
            let scrolls = pageScrolls()
            return !scrolls.isEmpty && scrolls.allSatisfy { $0.isAtTop }
        }

        //Every reading in `pan.view`, the window's own space: `nil` on a recognizer attached to the window itself reads
        //back the finger's location, not its travel (sim-logged: a 45pt drag ended at "translation" (369, 128))
        @objc private func panned(_ pan: UIPanGestureRecognizer) {
            switch pan.state {
            case .began:
                owned = true
                freeze(pageScrolls() + scrolls(under: pan))
                flight.beginDrag()
            case .changed:
                guard owned else { return }
                flight.dragChanged(travel(pan))
            case .ended, .cancelled, .failed:
                guard owned else { return }
                owned = false
                let velocity = pan.velocity(in: pan.view)
                //A pan the system took away (Control Center, a call) is not a release
                flight.dragEnded(translation: travel(pan),
                                 velocity: CGSize(width: velocity.x, height: velocity.y),
                                 cancelled: pan.state != .ended)
            default:
                break
            }
        }

        //From the touch-down, recognition slop included, as the pending card's DragGesture measures it: the screen picks up
        //under the finger. (A pan's own translation starts where it recognised — sim-logged 20pt short on a 180pt swipe.)
        private func travel(_ pan: UIPanGestureRecognizer) -> CGSize {
            guard let touchDown else {
                let translation = pan.translation(in: pan.view)
                return CGSize(width: translation.x, height: translation.y)
            }
            let location = pan.location(in: pan.view)
            return CGSize(width: location.x - touchDown.x, height: location.y - touchDown.y)
        }

        //The content's own interactiveDismissDisabled, which SwiftUI sets on the presented controller
        private var dismissalDisabled: Bool {
            var responder: UIResponder? = probe
            while let current = responder {
                if let controller = current as? UIViewController {
                    var candidate: UIViewController? = controller
                    while let each = candidate {
                        if each.isModalInPresentation { return true }
                        candidate = each.parent
                    }
                    return false
                }
                responder = current.next
            }
            return false
        }

        //The screen's own vertical scrolls: every one of them must rest at its top for a swipe down to dismiss
        private func pageScrolls() -> [UIScrollView] {
            guard let root = presentedRoot() else { return [] }
            var found: [UIScrollView] = []
            var queue: [UIView] = [root]
            while let view = queue.popLast() {
                if let scroll = view as? UIScrollView, scroll.scrollsVertically, scroll.bounds.height > root.bounds.height / 2 {
                    found.append(scroll)
                }
                queue.append(contentsOf: view.subviews)
            }
            return found
        }

        //The cover's own branch of the window — the probe's ancestor sitting directly in it, its presentation's
        //container — so the screen beneath is never searched. (SwiftUI puts a key-press responder between its hosting
        //view and the presented controller, so a view-controller walk finds nothing.)
        private func presentedRoot() -> UIView? {
            var view: UIView? = probe
            while let current = view, let parent = current.superview {
                if parent is UIWindow { return current }
                view = parent
            }
            return nil
        }

        private func scrolls(under pan: UIPanGestureRecognizer) -> [UIScrollView] {
            guard let window = pan.view else { return [] }
            var view = window.hitTest(pan.location(in: window), with: nil)
            var found: [UIScrollView] = []
            while let current = view {
                if let scroll = current as? UIScrollView { found.append(scroll) }
                view = current.superview
            }
            return found
        }

        private func freeze(_ scrolls: [UIScrollView]) {
            for scroll in scrolls where !frozen.contains(scroll) {
                scroll.panGestureRecognizer.isEnabled = false //Cancels its half-begun pan
                if scroll.scrollsVertically {
                    scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: -scroll.adjustedContentInset.top), animated: false)
                }
                frozen.append(scroll)
            }
        }

        //A drag that sprang home: the screen's ride may have nudged its scrolls, which were at their top when it began
        private func settle() {
            guard !owned else { return } //A new drag already holds them
            for scroll in frozen where scroll.scrollsVertically {
                scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: -scroll.adjustedContentInset.top), animated: false)
            }
            thaw()
        }

        private func thaw() {
            frozen.forEach { $0.panGestureRecognizer.isEnabled = true }
            frozen = []
        }
    }
}

private extension UIScrollView {
    var scrollsVertically: Bool {
        alwaysBounceVertical || contentSize.height > bounds.height - adjustedContentInset.top - adjustedContentInset.bottom + 1
    }

    var isAtTop: Bool { contentOffset.y <= -adjustedContentInset.top + 1 }
}

//MARK: - Helpers

private func instantTransaction() -> Transaction {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    return transaction
}

private func smoothstep(_ t: CGFloat) -> CGFloat {
    let x = min(max(t, 0), 1)
    return x * x * (3 - 2 * x)
}

private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t
}

private func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
    CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
           width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
}

private extension CGRect {
    func scaled(by scale: CGFloat, about pivot: CGPoint) -> CGRect {
        CGRect(x: pivot.x + (minX - pivot.x) * scale, y: pivot.y + (minY - pivot.y) * scale,
               width: width * scale, height: height * scale)
    }
}
