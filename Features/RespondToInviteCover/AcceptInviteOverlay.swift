//
//  AcceptInviteOverlay.swift
//  Scoop
//
//  Created by Art Ostin on 13/08/2026.
//

import SwiftUI
import CoreHaptics
import os

private let viewEventLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Scoop", category: "viewEventFlight")

/*
 The dismissal's flight (the send flight's shape, reversed): the resting circle grows and
 seats into its event card's image slot in ONE spring — travel, size, clip radii and the
 shadows' dissolve all in the same transaction, so the morph reads as a single movement while
 the glass ring, glow and title dissolve in place and BlurCover's wash clears beneath it.

 The hand-off is seam-free by construction: the card's own image sat hidden the whole flight
 (armed at show(), behind the still-opaque wash), un-hides beneath the fully-settled, still-
 OPAQUE copy in a no-animation transaction, and only then does the copy dissolve — over
 pixel-identical artwork (one ImageLoader cache feeds both sides, and both crop the same
 rect), so no frame exists in which the image doubles, gaps or jumps.

 Geometry-matched hero flight: its measured curves live in-file, per the motion rules.
 */
enum AcceptFlightMotion {
    //THE tuning knob — the flight's clock. Bounce 0 (chosen 2026-08-20 over a landing
    //overshoot): the circle grows and seats into the card top as one continuous settle.
    static let spring = Spring(duration: 0.55, bounce: 0)
    static let flight = Animation.spring(spring)

    //The copy's dissolve over the identical card image beneath — diffuses the sub-pixel
    //corner seam (the copy's .circular clip over the card's continuous one) instead of
    //betting the hand-off on shape identity.
    static let handOff = Animation.smooth(duration: 0.12)

    //Derived, never tuned: .removed — the hand-off's trigger — fires at the spring's
    //SETTLING time (~0.9s here, well past the perceptual 0.55s), so both holds anchor to it
    //and cannot drift under a retune. Teardown covers the hand-off dissolve plus margin;
    //BlurCover's hold outlasts teardown, as BlurCoverMotion.contentHold outlasts the shared exit.
    static var teardown: Duration { .seconds(spring.settlingDuration + 0.25) }
    static var contentHold: Duration { .seconds(spring.settlingDuration + 0.33) }
}

struct AcceptInviteCard: View {

    //Injected
    var flight: AcceptFlightSource? = nil //nil (previews) falls back to the mock hero
    var closing = false
    var destination: CGRect? = nil //The landing rect the presenter resolved as `closing` flipped
    var name: String? = nil
    var onFlightLanded: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    //Local view state
    @State private var angle: Double = 0
    @State private var scale: CGFloat = Entrance.startScale
    @State private var lift: CGFloat = Entrance.liftTravel
    @State private var landed = false
    @State private var hasFired = false
    @State private var buzz = LandingBuzz()

    //Flight state
    @State private var clusterFrame: CGRect = .zero //The cluster's resting global rect — the flight's coordinate bridge
    @State private var departed = false //The ONE flight flag: travel, size, clip and shadows all key on it
    @State private var handedOff = false //The copy dissolving over the identical card image beneath

    static let imageSize: CGFloat = 225
    static let ringSize: CGFloat = 275

    //A close with a resolved landing rect flies; anything else (no destination, reduced
    //motion, an unmeasured cluster) keeps the shared fade exit.
    private var canFly: Bool { destination != nil && clusterFrame != .zero && !reduceMotion }
    private var exitFading: Bool { closing && !canFly }

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            ZStack {
                Circle()
                    .fill(.accent.opacity(0.1))
                    .frame(width: Self.ringSize, height: Self.ringSize)
                    .blur(radius: 50)
                    .opacity(landed && !closing ? 1 : 0)
                    .animation(.quick, value: closing)
                    .allowsHitTesting(false)

                Circle()
                    .fill(.clear)
                    .frame(width: Self.ringSize, height: Self.ringSize)
                    .glassEffectIfAvailable(shape: Circle())
                    .opacity(closing ? 0 : 1)
                    .animation(.quick, value: closing)

                heroImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageRect.width, height: imageRect.height)
                    .clipShape(imageClip)
                    .imageShadow(hide: departed)
                    .modifier(BackfaceCulled(angle: angle))
                    .opacity(handedOff ? 0 : 1)
                    .position(x: imageRect.midX, y: imageRect.midY)
            }
            //The pin matters twice: it keeps the .position-wrapped image from inflating the
            //cluster (VStack layout, and the spin's perspective, stay exactly pre-flight),
            //and the frame is measured BELOW the transforms, so it is the resting layout rect
            //whatever the entrance is doing.
            .frame(width: Self.ringSize, height: Self.ringSize)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { clusterFrame = $0 }
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.1)
            .scaleEffect(scale * (exitFading ? ResponseCoverExit.endScale : 1))
            .offset(y: lift + (exitFading ? ResponseCoverExit.riseTravel : 0))
            .opacity(exitFading ? 0 : 1)
            .animation(ResponseCoverExit.card, value: closing)
            .task { await enter() }
            .onChange(of: closing) { _, isClosing in
                guard isClosing, canFly else { return }
                fly()
            }

            //First out, since it was last in
            Text("You’re Meeting \n \(name ?? "Arthur")!")
                .font(.title(32, .bold))
                .multilineTextAlignment(.center)
                .opacity(landed && !closing ? 1 : 0)
                .offset(y: landed ? (closing ? Spacing.xs : 0) : ResponseCoverEntrance.titleRise)
                .animation(ResponseCoverExit.title, value: closing)
        }
    }
}

//Flight geometry and choreography
extension AcceptInviteCard {

    private var heroImage: Image {
        if let flight { Image(uiImage: flight.image) } else { Image("ProfileMockB") }
    }

    //The flight's two poses in cluster space: the resting circle, and the handed-over global
    //rect brought local through the cluster's own measured origin.
    private var imageRect: CGRect {
        if departed, let destination {
            return destination.offsetBy(dx: -clusterFrame.minX, dy: -clusterFrame.minY)
        }
        let inset = (Self.ringSize - Self.imageSize) / 2
        return CGRect(x: inset, y: inset, width: Self.imageSize, height: Self.imageSize)
    }

    //Sanctioned .circular: at rest the radii are half the frame — a pixel-exact Circle()
    //inside the true-Circle glass ring; in flight they morph continuously to the event
    //card's clip (top corners CornerRadius.image, bottom edge square inside the card).
    private var imageClip: UnevenRoundedRectangle {
        let radii = departed
            ? RectangleCornerRadii(topLeading: CornerRadius.image, bottomLeading: 0,
                                   bottomTrailing: 0, topTrailing: CornerRadius.image)
            : CornerRadius.uniform(Self.imageSize / 2)
        return UnevenRoundedRectangle(cornerRadii: radii, style: .circular)
    }

    //ONE transaction moves every part of the morph. Completion is .removed, not
    //.logicallyComplete: the hand-off swaps pixels, so the copy must sit EXACTLY on the
    //landing rect — the spring's last sub-point of tail included — before it runs.
    private func fly() {
        withAnimation(AcceptFlightMotion.flight, completionCriteria: .removed) {
            departed = true
        } completion: {
            handOff()
        }
    }

    //The destination un-hides beneath the still-opaque copy with animations disabled — no
    //frame exists where the image doubles or gaps — then the copy dissolves over it.
    private func handOff() {
        var settle = Transaction()
        settle.disablesAnimations = true
        withTransaction(settle) { onFlightLanded() }
        withAnimation(AcceptFlightMotion.handOff) { handedOff = true }
    }
}

//Entrance choreography
extension AcceptInviteCard {

    private enum Entrance {
        static let spinTurns: Double = 2 //The tuning knob — 1–4 all read cleanly; spin duration scales with it so the backface blinks never strobe (each ≥ ~85ms)
        static var spinDegrees: Double { spinTurns * 360 } //Multiple of 360 by construction: always lands facing front
        static var coinSpin: Animation { .spring(duration: 0.7 + 0.2 * spinTurns, bounce: 0.15) } //Bounce ≤ 0.15: the ~4.5° over-rotation is invisible at perspective 0.1 — settle physics for the beat, not a visible wobble
        static let coinLanding = Animation.spring(duration: 1.2, bounce: 0.3) //Shared by scale + lift so the pop and the vertical catch are one beat
        static let reveal = ResponseCoverEntrance.titleReveal
        static let startScale: CGFloat = 0.6
        static let liftTravel = Spacing.xxxl
        static let commitGuard: Duration = .milliseconds(30) //One rendered frame so the start pose is committed — a flip fired inside an in-flight parent transaction snaps to destination
    }

    private func enter() async {
        guard !hasFired else { return }
        hasFired = true
        buzz.prepare() //Warm the engine now — it has the whole flight (~0.9s) before the beat
        try? await Task.sleep(for: Entrance.commitGuard)
        if Task.isCancelled { hasFired = false; return }

        if reduceMotion {
            withAnimation(Entrance.coinLanding, completionCriteria: .logicallyComplete) {
                scale = 1
                lift = 0
            } completion: {
                land()
            }
        } else {
            withAnimation(Entrance.coinSpin, completionCriteria: .logicallyComplete) {
                angle = Entrance.spinDegrees
            } completion: {
                land()
            }
            withAnimation(Entrance.coinLanding) {
                scale = 1
                lift = 0
            }
        }
    }

    //The landing beat: title + glow reveal and the buzz fire as one event
    private func land() {
        withAnimation(Entrance.reveal) { landed = true }
        buzz.play()
    }
}


#Preview {
    AcceptInviteCard()
}


//MARK: - View Event flight

/*
 Calendar View → Events. The calendar's meeting popup hands its card over in the tap's own turn
 (`.eventZoomLeadingAction`), and a window of its own, above every cover, takes the screen with a still picture of the
 app window — the render server's own pixels — over the plane's frost and a copy of the card posed at rest by the popup's
 own morph (`EventZoomMorph`). On the next frame the calendar closes and Events opens on the event's card, unseen, and
 the frame after that the picture goes (only what the frost blurs has changed) and the photo DROPS, on the popup's own
 card landing (through the slot, a short sink, and back), aimed where the event's photo rests (`predictedPad`,
 self-calibrating). The rows fold into it, the buttons pop away, and the frost lifts off the event as the photo lands,
 re-aiming if the card rests elsewhere. The landing is the accept flight's: the event's photo shows again beneath the
 copy, and the copy dissolves off identical pixels.

 Why a window: the popup lives inside the calendar's fullScreenCover, which draws above every root plane and takes the
 tab bar controller out of the window while it is up, so nothing beneath it can be seen until it has gone. A window
 above the cover is the one surface that can stand over it while it goes.
 */
enum ViewEventFlightMotion {
    static let pictureFrames = 2 //Display frames: the picture is on screen before anything changes under it
    static let commitBeat: Duration = .milliseconds(34) //One rendered frame, for a beat between the two windows' commits
    static let holdCap: Duration = .milliseconds(1200) //A fade's wait for the event's card, from opening Events: a first visit mounts the whole tab
    static let landingCap: Duration = .milliseconds(2000) //A drop's: the photo is down in about a second, and the card must be landable by then
    static let frostCap: Duration = .milliseconds(300) //Into the drop, the frost lifts even before the card reports settled: the event shows as the photo lands
    static let retargetSettle: Duration = .milliseconds(450) //A re-aim on `.move` (a 0.4s spring) home, plus a frame
    static let quiet: TimeInterval = 0.15 //The accept pad's settle signal — no report for this long
    static let revealQuiet: TimeInterval = 0.08 //Enough stillness to lift the frost off the event; the landing itself still waits `quiet`
    static let pageRecheck: Duration = .milliseconds(100)
    static let curtainFade: TimeInterval = 0.22 //`Animation.dismiss` (smooth = a bounce-0 spring), mirrored for UIKit
}

@MainActor @Observable final class ViewEventFlight {

    struct Request {
        let eventId: String
        let departure: EventZoomDeparture
        var copy: AnyView? = nil //The card's body as the flight carries it (`ViewInviteFlightCopy`); nil: no flight, the picture fades off the event

        var flies: Bool { copy != nil && departure.photo != nil }
    }

    struct Handlers {
        let closeCalendar: () -> Void
        let openEvent: () -> Void
        let stillTargeted: () -> Bool //Nothing newer (a deep link, a pushed chat) has taken the Events tab since
    }

    private struct PadReport {
        var rect = CGRect.zero
        var progress = 0.0
        var images: [WeakImage] = [] //Weak: kept for the card's lifetime, never for its photos'
        var at = Date.distantPast
    }

    private struct WeakImage {
        weak var image: UIImage?
    }

    private enum Verdict { case wait, land(CGRect), miss }

    //The landing pad, read by EventImageCard
    private(set) var padEventId: String? //Arming it is what turns the card
    private(set) var padHidesImage = false //A flight owns the photo's pixels from the picture's rise to the landing
    private(set) var padLanded = false //The copy sits on the photo: it shows again, beneath the copy
    @ObservationIgnored private var padSource: UIImage? //The popup's photo as its caller holds it
    @ObservationIgnored private var padIndex = 0
    @ObservationIgnored private var padCount = 0
    @ObservationIgnored private var reports: [String: PadReport] = [:] //Every card's latest, kept: a warm card that never moves never reports again

    //What the window draws beneath the picture (`ViewEventFlightScene`)
    private(set) var q: CGFloat = 1 //The card's morph: 1 at rest where the popup stood, 0 folded onto the event's photo, below 0 the landing's sink
    private(set) var frost: Double = 1
    private(set) var copyOpacity: Double = 1
    private(set) var standIn: Double = 0 //One photo standing in for the landed copy, so its dissolve is a single layer
    private(set) var buttonsVisible = true
    private(set) var pad: CGRect = .zero //Where the drop lands — re-aimed, on its own animation, as the event's card settles
    private(set) var sceneOrigin: CGPoint = .zero

    //The plane
    @ObservationIgnored private(set) var request: Request? //Set before the window exists, and read by nothing that needs to follow it
    @ObservationIgnored private var handlers: Handlers?
    @ObservationIgnored private var window: UIWindow?
    @ObservationIgnored private weak var appWindow: UIWindow?
    @ObservationIgnored private var curtain: UIView?
    @ObservationIgnored private var generation = 0 //Every beat and completion is checked against it: a newer run, or a teardown, owns the plane
    @ObservationIgnored private var run: Task<Void, Never>?
    @ObservationIgnored private var background: NSObjectProtocol?
    @ObservationIgnored private let driver = WindCloseDriver() //The landing's per-frame clock — the popup's card landing is a curve, not a spring target
    @ObservationIgnored private var landed = false //The landing's clock has run out: q is exactly 0
    @ObservationIgnored private var calendarClosed = false
    @ObservationIgnored private var eventOpenedAt: ContinuousClock.Instant?
    @ObservationIgnored private var appWasHiddenFromAccessibility = false //The app window's own setting, put back at teardown

    private static var instant: Transaction {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        return transaction
    }

    //Within a point on every edge: a pixel-snapped report of the same rest
    private static func same(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) < 1 && abs(a.minY - b.minY) < 1 && abs(a.maxX - b.maxX) < 1 && abs(a.maxY - b.maxY) < 1
    }
}

//The landing pad: EventImageCard reports where it is and what it shows, turns to the popup's page, and hides its
//photo while the flight owns those pixels
extension ViewEventFlight {

    ///The page a card turns to before the flight lands on it: the popup's own photo, matched by identity (one
    ///ImageLoader cache feeds both screens), else by index when both sets are the same length
    func landingPage(for id: String, in images: [UIImage]) -> Int? {
        guard padEventId == id else { return nil }
        return landingIndex(count: images.count) { images[$0] }
    }

    private func landingIndex(count: Int, image: (Int) -> UIImage?) -> Int? {
        guard count > 0 else { return nil }
        if let padSource, let index = (0..<count).first(where: { image($0) === padSource }) { return index }
        return count == padCount && padIndex < count ? padIndex : nil
    }

    func imageHidden(_ id: String) -> Bool {
        padEventId == id && padHidesImage && !padLanded
    }

    func padProgress(for id: String) -> Double? {
        reports[id]?.progress
    }

    func reportPad(frame: CGRect, id: String) {
        reports[id, default: PadReport()].rect = frame
        reports[id]?.at = Date()
    }

    func reportPad(progress: Double, id: String) {
        reports[id, default: PadReport()].progress = progress
        reports[id]?.at = Date()
    }

    func reportPad(images: [UIImage], id: String) {
        reports[id, default: PadReport()].images = images.map { WeakImage(image: $0) }
        reports[id]?.at = Date()
    }

    private static let slotKey = "viewEventFlight.landingSlot"

    //Self-calibrating, as MapSheetFlight's sheet frame is: every landing records where the event's photo was, so from
    //the second flight on a device the drop aims true before the Events tab has laid out at all
    private static func recordSlot(_ rect: CGRect) {
        UserDefaults.standard.set([rect.minX, rect.minY, rect.width, rect.height].map(Double.init), forKey: slotKey)
    }

    private static var recordedSlot: CGRect? {
        guard let values = UserDefaults.standard.array(forKey: slotKey) as? [Double], values.count == 4 else { return nil }
        return CGRect(x: values[0], y: values[1], width: values[2], height: values[3])
    }

    //Where the event's photo will rest: its own report if it rests there already, else the last landing's, else the
    //Events tab's layout worked out — a first guess the drop re-aims in flight. Any is validated as a page's photo on
    //this screen: a scrolled or paged-away report, or one recorded on another device size, is no aim
    private func predictedPad(for id: String, in window: UIWindow) -> CGRect {
        let width = window.bounds.width - 2 * Spacing.gutter
        let isSlot = { (rect: CGRect) in
            abs(rect.minX - Spacing.gutter) < 2 && abs(rect.width - width) < 2
                && rect.minY >= window.safeAreaInsets.top && rect.maxY <= window.bounds.maxY
        }
        if let report = reports[id]?.rect, isSlot(report) { return report }
        if let slot = Self.recordedSlot, isSlot(slot) { return slot }
        //Geometry: the large title's bar (96) and the tab's title padding above the first slot; the photo's 1:1.02 (EventImageCarousel)
        return CGRect(x: Spacing.gutter, y: window.safeAreaInsets.top + 96 + Spacing.titlePadding, width: width, height: width * 1.02)
    }
}

//The plane: raised over the popup, taken down on the event
extension ViewEventFlight {

    ///Raises the plane and runs the flight. False when there is no plane to raise (no active scene, no picture): the
    ///caller cuts straight to the event instead
    func begin(_ request: Request, handlers: Handlers) -> Bool {
        guard self.request == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive }),
              let appWindow = scene.keyWindow else { return false }
        guard let curtain = appWindow.snapshotView(afterScreenUpdates: false) else { return false }
        generation += 1
        self.request = request
        self.handlers = handlers
        self.appWindow = appWindow
        self.curtain = curtain
        //A modal view only hides its siblings: VoiceOver could still reach the app window changing under the plane
        appWasHiddenFromAccessibility = appWindow.accessibilityElementsHidden
        appWindow.accessibilityElementsHidden = true
        let aim = request.flies ? predictedPad(for: request.eventId, in: appWindow) : .zero
        withTransaction(Self.instant) {
            q = 1
            frost = 1
            copyOpacity = 1
            standIn = 0
            buttonsVisible = true
            pad = aim
            padSource = request.departure.source
            padIndex = request.departure.page
            padCount = request.departure.pageCount
            padLanded = false
            padHidesImage = request.flies
            padEventId = request.eventId //Last: the cards' turn reads the fields above
        }
        landed = false
        window = planeWindow(in: scene, over: appWindow, curtain: curtain, drawsScene: request.flies)
        background = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.abandon() }
        }
        viewEventLog.debug("begin \(request.eventId, privacy: .public) page \(request.departure.page) flies \(request.flies)")
        let g = generation
        run = Task { [weak self] in await self?.sequence(g) }
        return true
    }

    ///The calendar cover's onDismiss: UIKit has really taken it off, animated or not
    func coverDidDismiss() {
        guard request != nil, calendarClosed else { return }
        viewEventLog.debug("cover gone")
    }

    func reportSceneOrigin(_ origin: CGPoint) {
        if sceneOrigin != origin { sceneOrigin = origin }
    }

    private func sequence(_ g: Int) async {
        guard let request else { return }
        if request.flies {
            await drop(g)
        } else {
            await Self.frames(ViewEventFlightMotion.pictureFrames) //The picture is on screen before anything changes under it
            guard g == generation else { return }
            openEvent()
            await holdThenLift(g)
        }
    }

    //The calendar closes on the event in one turn, the Events tab opening as the cover goes
    private func openEvent() {
        guard let handlers else { return }
        calendarClosed = true //First: the cover's onDismiss may land inside the close itself
        handlers.closeCalendar()
        handlers.openEvent()
        eventOpenedAt = .now
    }

    //Landable: the card listed, full size, clear of the bars, and quiet — no report since the Events tab opened, the
    //accept pad's settle signal — then holding the popup's photo, turned to it. A card whose set cannot show that photo
    //is a miss, but only once it has settled like the rest
    private func verdict(quiet: TimeInterval = ViewEventFlightMotion.quiet) -> Verdict {
        guard let id = padEventId, let report = reports[id], !report.images.isEmpty, let appWindow else { return .wait }
        let bounds = appWindow.bounds
        let rect = report.rect
        guard rect.width > 150, rect.height > 150,
              bounds.insetBy(dx: -2, dy: -2).contains(rect),
              rect.minY >= appWindow.safeAreaInsets.top,
              rect.maxY <= bounds.maxY - Spacing.clearance,
              Date().timeIntervalSince(report.at) > quiet,
              eventOpenedAt.map({ ContinuousClock.now - $0 > .seconds(quiet) }) ?? false
        else { return .wait }
        guard let page = landingIndex(count: report.images.count, image: { report.images[$0].image }) else { return .miss }
        return abs(report.progress - Double(page)) < 0.01 ? .land(rect) : .wait
    }

    //For one frame the picture stands over the popup, the plane's frost and the card's copy already drawn beneath it. Then,
    //in one turn, the popup's card hides, the calendar closes and Events opens on the event's card — whatever opening Events
    //costs the main thread is paid on that frozen frame, never mid-motion. The picture goes on the next frame and the photo
    //drops at once over the event, the rows folding into it and the buttons popping away; the frost lifts as soon as the
    //event's card has settled (or a beat into the drop, whichever comes first), the drop re-aims if the card rests
    //elsewhere, and the photo hands over once the landing and the aim have both come to rest
    private func drop(_ g: Int) async {
        await Self.frames(1) //The picture on screen
        guard g == generation, let request else { return }
        request.departure.hide()
        openEvent()
        await Self.frames(1) //Events opened, under the picture, on screen
        guard g == generation else { return }
        curtain?.removeFromSuperview()
        curtain = nil
        buttonsVisible = false //Bare: the row's copy pops on its own `.transition` scope
        let landing = EventZoomChoreo.cardLanding(path: hypot(pad.midX - request.departure.band.midX,
                                                              pad.midY - request.departure.band.midY))
        driver.run { [weak self] t in
            MainActor.assumeIsolated {
                guard let self, g == self.generation else { return }
                if let p = landing(t) {
                    withTransaction(Self.instant) { self.q = p }
                } else {
                    self.driver.stop()
                    withTransaction(Self.instant) { self.q = 0 }
                    self.landed = true
                }
            }
        }
        viewEventLog.debug("drop")
        let dropped = ContinuousClock.now
        var aimSettles = dropped
        var frostLifting = false
        func liftFrost() {
            guard !frostLifting else { return }
            frostLifting = true
            withAnimation(.transition) { frost = 0 }
        }
        while g == generation, handlers?.stillTargeted() == true, ContinuousClock.now < dropped + ViewEventFlightMotion.landingCap {
            if case .land = verdict(quiet: ViewEventFlightMotion.revealQuiet) { liftFrost() }
            switch verdict() {
            case .miss:
                abort(g)
                return
            case .land(let rect):
                if !Self.same(rect, pad) {
                    viewEventLog.debug("re-aim \(String(describing: self.pad), privacy: .public) → \(String(describing: rect), privacy: .public)")
                    withAnimation(.move) { pad = rect }
                    aimSettles = .now + ViewEventFlightMotion.retargetSettle
                }
                liftFrost()
                if landed, ContinuousClock.now >= aimSettles {
                    handOff(g)
                    return
                }
            case .wait:
                if ContinuousClock.now >= dropped + ViewEventFlightMotion.frostCap { liftFrost() }
            }
            try? await Task.sleep(for: .milliseconds(16))
        }
        guard g == generation else { return }
        abort(g)
    }

    //The accept flight's landing, one surface revealed at a time and each under something already painted: the event's
    //photo shows again beneath the opaque copy; then one photo stands in beneath the copy too, so it has painted before
    //anything relies on it (a view shown in the same commit that removes its cover showed the pad bare for a frame, sim
    //capture); then the copy goes off identical pixels, and the stand-in dissolves
    private func handOff(_ g: Int) {
        guard g == generation else { return }
        //The card moved since it was aimed at (a list update, a status-bar scroll) or the tab was taken: nothing identical
        //is left to hand off to, so the copy fades off instead
        guard let now = padEventId.flatMap({ reports[$0]?.rect }), Self.same(now, pad), handlers?.stillTargeted() == true else {
            abort(g)
            return
        }
        Self.recordSlot(pad)
        withTransaction(Self.instant) { padLanded = true }
        viewEventLog.debug("hand-off")
        Task { @MainActor [self] in
            try? await Task.sleep(for: ViewEventFlightMotion.commitBeat) //The app window's commit on screen first
            guard g == generation else { return }
            withTransaction(Self.instant) { standIn = 1 }
            try? await Task.sleep(for: ViewEventFlightMotion.commitBeat)
            guard g == generation else { return }
            withTransaction(Self.instant) { copyOpacity = 0 }
            try? await Task.sleep(for: ViewEventFlightMotion.commitBeat) //Never in the swap's own turn, or the dissolve starts from 0
            guard g == generation else { return }
            withAnimation(.handOff, completionCriteria: .removed) {
                standIn = 0
            } completion: {
                self.teardown(g)
            }
        }
    }

    //The event's card could not take the photo — it never settled or listed, its photos differ, or the tab was taken:
    //the photo shows where it is, and the copy and frost fade off it
    private func abort(_ g: Int) {
        guard g == generation else { return }
        driver.stop()
        viewEventLog.debug("abort")
        withTransaction(Self.instant) { padHidesImage = false }
        withAnimation(.dismiss, completionCriteria: .removed) {
            copyOpacity = 0
            frost = 0
        } completion: {
            self.teardown(g)
        }
    }

    //No flight: the picture holds while the event's card settles under it, then fades off the event
    private func holdThenLift(_ g: Int) async {
        let deadline = ContinuousClock.now + ViewEventFlightMotion.holdCap
        while g == generation, handlers?.stillTargeted() == true, ContinuousClock.now < deadline {
            guard case .wait = verdict() else { break }
            try? await Task.sleep(for: .milliseconds(16))
        }
        guard g == generation else { return }
        withTransaction(Self.instant) { padHidesImage = false }
        guard let curtain else { teardown(g); return }
        UIView.animate(springDuration: ViewEventFlightMotion.curtainFade, bounce: 0) {
            curtain.alpha = 0
        } completion: { [weak self] _ in
            MainActor.assumeIsolated { self?.teardown(g) }
        }
    }

    //Backgrounded mid-flight: before the calendar closed, the popup is handed back exactly as it was; after, the Events
    //tab is already open and the plane simply goes
    private func abandon() {
        guard let request else { return }
        if !calendarClosed { request.departure.restore() }
        teardown(generation)
    }

    private func teardown(_ g: Int) {
        guard g == generation, request != nil else { return }
        generation += 1
        run?.cancel()
        run = nil
        driver.stop()
        window?.isHidden = true //Hidden before any observed state resets, so no reset is ever seen
        window?.rootViewController = nil
        window = nil
        curtain = nil
        if let background { NotificationCenter.default.removeObserver(background) }
        background = nil
        withTransaction(Self.instant) {
            padEventId = nil
            padHidesImage = false
            padLanded = false
            q = 1
            frost = 1
            copyOpacity = 1
            standIn = 0
            buttonsVisible = true
            pad = .zero
        }
        padSource = nil
        request = nil
        handlers = nil
        landed = false
        calendarClosed = false
        eventOpenedAt = nil
        appWindow?.accessibilityElementsHidden = appWasHiddenFromAccessibility
        UIAccessibility.post(notification: .screenChanged, argument: nil) //VoiceOver re-reads the event it has landed on
        viewEventLog.debug("teardown")
    }

    //Whole display frames, off the display's own clock: a commit made now has been on screen once the second has fired
    private static func frames(_ count: Int) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            FrameWaiter(frames: count) { continuation.resume() }.start()
        }
    }

    //A window above the app window and every cover it presents, never key: the scene beneath, the picture on top. Its
    //root mirrors the status bar as it stands, so the window never flips it
    private func planeWindow(in scene: UIWindowScene, over appWindow: UIWindow, curtain: UIView, drawsScene: Bool) -> UIWindow {
        let root = ViewEventFlightRootController(statusBarStyle: scene.statusBarManager?.statusBarStyle ?? .default,
                                                 statusBarHidden: scene.statusBarManager?.isStatusBarHidden ?? false)
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .normal + 1
        window.backgroundColor = .clear
        window.frame = appWindow.frame
        window.rootViewController = root
        root.view.frame = window.bounds
        if drawsScene {
            let host = UIHostingController(rootView: ViewEventFlightScene(flight: self))
            host.safeAreaRegions = []
            host.view.backgroundColor = .clear
            root.addChild(host)
            host.view.frame = root.view.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            root.view.addSubview(host.view)
            host.didMove(toParent: root)
            host.view.accessibilityElementsHidden = true //An inert copy: nothing in it to read or activate
        }
        curtain.frame = appWindow.bounds
        curtain.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        root.view.addSubview(curtain) //On top: the scene takes its first layout and paint beneath it
        window.isHidden = false
        root.view.layoutIfNeeded()
        return window
    }
}

//What the window draws beneath the picture: the popup's frost, the card's copy, and its row of buttons
private struct ViewEventFlightScene: View {

    //Injected
    let flight: ViewEventFlight

    var body: some View {
        ZStack {
            EventBackdrop()
                .opacity(flight.frost)
            if let request = flight.request, let copy = request.copy, let photo = request.departure.photo {
                ViewEventFlightCard(departure: request.departure, copy: copy, photo: photo, pad: flight.pad, q: flight.q,
                                    copyOpacity: flight.copyOpacity, standIn: flight.standIn, origin: flight.sceneOrigin)
                //The row as it stood when tapped, popping away as the photo drops
                EventDismissButton(visible: flight.buttonsVisible, leadingTitle: request.departure.leadingTitle,
                                   onTap: {}, onLeadingTap: {})
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .offset(y: request.departure.chevronSlotY - flight.sceneOrigin.y)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle()) //Every touch is the flight's while the window is up
        .onGeometryChange(for: CGPoint.self) { $0.frame(in: .global).origin } action: { flight.reportSceneOrigin($0) }
    }
}

//The card on its way down, posed by the popup's own morph: at rest where the popup stood (q = 1), folded onto its photo
//on the event's card (q = 0). Its landing pad animates on this view's own attribute, so a re-aim glides while the
//landing clock goes on writing the morph's p frame by frame
private struct ViewEventFlightCard: View, Animatable {

    //Injected
    let departure: EventZoomDeparture
    let copy: AnyView
    let photo: UIImage
    var pad: CGRect
    let q: CGFloat
    let copyOpacity: Double
    let standIn: Double
    let origin: CGPoint

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(pad.minX, pad.minY), AnimatablePair(pad.width, pad.height)) }
        set { pad = CGRect(x: newValue.first.first, y: newValue.first.second, width: newValue.second.first, height: newValue.second.second) }
    }

    var body: some View {
        ZStack {
            //Beneath the copy: it paints while still covered, and is only ever revealed by the copy going
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: max(pad.width, 1), height: max(pad.height, 1))
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: CornerRadius.image, bottomLeadingRadius: 0,
                                                  bottomTrailingRadius: 0, topTrailingRadius: CornerRadius.image))
                .opacity(standIn)
                .position(x: pad.midX - origin.x, y: pad.midY - origin.y)
            copy
                .frame(width: departure.card.width, height: departure.card.height, alignment: .top)
                .modifier(morph)
                .opacity(copyOpacity)
                .position(x: departure.card.midX - origin.x, y: departure.card.midY - origin.y)
        }
        .allowsHitTesting(false)
    }

    //The popup's own card close, driven from outside its choreo: the fold gate open, the rows folding 1:1 with the photo's
    //travel and the sink below 0 as a card's tap close does, the band as the destination's shape — and nothing else
    //flying: no chrome copy, heroes, rim or breath
    private var morph: EventZoomMorph {
        EventZoomMorph(flightP: q, chromeMix: 1, dragTravel: 0, flightOffset: .zero, pop: 1, landingScale: 1,
                       breath: 0, cardLanding: true,
                       source: pad.width > 1 ? pad : departure.band, shape: .band,
                       card: departure.card, pager: departure.band, photo: photo, chrome: nil, bandCopies: [],
                       title: departure.title, pagerTitle: departure.bandTitle, titleName: nil, titleSource: .zero,
                       buttonHero: false, buttonFade: 0, buttonSource: .zero, pressPose: .rest,
                       cta: .zero, ctaText: "", ctaFill: .clear, ctaFont: .body(18, .bold), ctaLineLimit: 1,
                       rows: [], rowFade: 0, corner: nil, coverShown: true, titleShown: false, titleFade: 0,
                       rimMounted: false, rimTint: 0, shadow: Double(min(max(q, 0), 1)))
    }
}

//Counts whole display frames, then calls back once
private final class FrameWaiter {

    private var link: CADisplayLink?
    private var remaining: Int
    private var done: (() -> Void)?

    init(frames: Int, done: @escaping () -> Void) {
        remaining = frames
        self.done = done
    }

    //The link holds the waiter until the last frame has fired
    func start() {
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    @objc private func tick() {
        remaining -= 1
        guard remaining <= 0 else { return }
        link?.invalidate()
        link = nil
        let done = self.done
        self.done = nil
        done?()
    }
}

private final class ViewEventFlightRootController: UIViewController {

    private let statusBarStyle: UIStatusBarStyle
    private let statusBarHidden: Bool

    init(statusBarStyle: UIStatusBarStyle, statusBarHidden: Bool) {
        self.statusBarStyle = statusBarStyle
        self.statusBarHidden = statusBarHidden
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .clear
        view.accessibilityViewIsModal = true //VoiceOver stays on the flight while the app changes under it
        self.view = view
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }
    override var prefersStatusBarHidden: Bool { statusBarHidden }
}


//Landing buzz: a thunk plus a rumble whose decay matches the springs' settle window, and a
//scheduled tap series for choreographies that land on more than one beat
@MainActor
final class LandingBuzz {
    private var engine: CHHapticEngine?
    private var scheduled: CHHapticPatternPlayer?

    //Impacts handed over before the start finished, stamped with their choreography's zero
    private var engineRunning = false
    private var pendingImpacts: (taps: [(time: Double, intensity: Float, sharpness: Float)], zero: Date)?

    //A play() handed over before the start finished, stamped with its landing beat
    private var pendingPlay: (duration: Double, zero: Date)?

    //How late a deferred play() may still fire: within the title reveal it accompanies a
    //slightly late thunk still reads as the landing; past it, as a stray (the schedule()
    //rationale, applied to the beat at zero)
    private static let pendingPlayWindow: TimeInterval = 0.3

    /*
     Call ahead of the beat — a cold engine start adds latency or drops the first pattern.
     The start is asynchronous: the blocking start() holds the main thread for the engine's
     cold spin-up (tens of ms on device), long enough to read as launch lag on paths that
     animate the instant they call this. But a pattern started before the engine finishes is
     rejected outright — the player checks the engine's running state synchronously — so
     impacts that arrive during the warm-up wait in `pendingImpacts` and are rescheduled from
     the completion, beats shifted by the elapsed wait: the taps land on the choreography's
     clock, not a late copy of it.
     */
    func prepare() {
        guard engine == nil, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        engine?.start { [weak self] error in
            guard error == nil else { return }
            Task { @MainActor [weak self] in self?.engineDidStart() }
        }
    }

    private func engineDidStart() {
        engineRunning = true
        if let pendingPlay {
            if Date().timeIntervalSince(pendingPlay.zero) < Self.pendingPlayWindow {
                playNow(duration: pendingPlay.duration)
            }
            self.pendingPlay = nil
        }
        guard let pendingImpacts else { return }
        schedule(pendingImpacts.taps, delayed: Date().timeIntervalSince(pendingImpacts.zero))
        self.pendingImpacts = nil
    }

    /*
     The beat may land before the start finished — SendInviteScreen's flightless covers call
     this ~30ms after prepare() — and a pattern started then is rejected outright, so it
     waits in `pendingPlay` and fires from the completion instead, or is dropped once it
     would read as a stray rather than the landing.
     */
    func play(duration: Double = 1) {
        guard engine != nil else { return }
        if engineRunning {
            playNow(duration: duration)
        } else {
            pendingPlay = (duration, Date())
        }
    }

    private func playNow(duration: Double) {
        let thunk = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
        ], relativeTime: 0)

        let rumble = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
        ], relativeTime: 0, duration: duration)

        let decay = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            .init(relativeTime: 0, value: 1),
            .init(relativeTime: duration, value: 0)
        ], relativeTime: 0)

        guard let engine,
              let pattern = try? CHHapticPattern(events: [thunk, rumble], parameterCurves: [decay]),
              let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    func playImpacts(_ impacts: [(time: Double, intensity: Float, sharpness: Float)]) {
        guard engine != nil else { return }
        if engineRunning {
            schedule(impacts, delayed: 0)
        } else {
            pendingImpacts = (impacts, Date())
        }
    }

    private func schedule(_ impacts: [(time: Double, intensity: Float, sharpness: Float)], delayed: TimeInterval) {
        let events: [CHHapticEvent] = impacts.compactMap {
            let beat = $0.time - delayed
            guard beat > 0 else { return nil } //Its squash frame has passed — a late tap reads as a stray
            return CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: $0.intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: $0.sharpness)
            ], relativeTime: beat)
        }

        guard !events.isEmpty, let engine,
              let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        scheduled = player
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    //A dismissal mid-flight takes the taps still sitting on the schedule with it
    func stop() {
        pendingImpacts = nil
        pendingPlay = nil
        try? scheduled?.stop(atTime: CHHapticTimeImmediate)
        scheduled = nil
    }
}


//Hides it if facing the back
struct BackfaceCulled: ViewModifier, Animatable {
    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private var facingViewer: Bool {
        let turn = angle.truncatingRemainder(dividingBy: 360)
        let normalized = turn < 0 ? turn + 360 : turn
        return normalized <= 90 || normalized >= 270
    }

    func body(content: Content) -> some View {
        content.opacity(facingViewer ? 1 : 0)
    }
}
