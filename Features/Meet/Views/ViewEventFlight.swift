//
//  ViewEventFlight.swift
//  Scoop
//
//  Created by Art Ostin on 17/09/2026.
//

import SwiftUI
import UIKit
import os

private let viewEventLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Scoop", category: "viewEventFlight")

/*
 Calendar View → Events, and Meet's History → Events. A meeting's popup hands its card over in the tap's own turn
 (`.eventZoomLeadingAction`) and the card BECOMES the event's card. In that same turn a copy of the whole popup stands
 over it on identical pixels — its material, the photo as a live aspect-fill layer, everything else the render server's
 own pixels — the popup itself goes, and the copy leaves: the white card travels to the event card's frame and the
 photo grows down over the rows as they fade, all on ONE spring, while the title leaves the photo, the page dots and the
 card's rim arrive on it and both buttons pop away, each on a short clock of its own. Two turns later the cover closes
 and Events opens on the event, unseen under the material, which clears a beat after the event's card is known to be on the glass — and the copy's body clears with
 it, off the event's own card standing under it, so the timer strip sharpens into the card's foot with the rest of the
 screen. The photo lands with a single soft overshoot, and the landing is the accept flight's: the real photo shows
 again beneath the copy, and the copy dissolves off identical pixels.

 Why Core Animation: opening Events costs the main thread a third of a second on a device (device video 2026-09-17:
 0.38s frozen, longer when the pager rested on another event), and everything SwiftUI animates — `withAnimation`, a
 display link writing state — stops for as long as the main thread does. The first flight hid that freeze under a
 still picture of the screen, so the tap read as dead for half a second and the card then skipped the first half of
 its travel. Here every moving thing is a UIKit spring committed to the render server BEFORE the switch is asked for
 (sim-proven through a 3s block, 2026-09-17), so the card leaves in the tap's frame and cannot stall, whatever the
 switch costs. The main thread only ever decides — when to clear the material, whether to re-aim, when to hand off.

 Why an overlay in the app's own window, not a window above it: the popup lives in a fullScreenCover, which draws
 above every root plane, so the stage must stand over the cover while it goes — and a plain view added to the app
 window stays above the cover's transition view through an unanimated dismissal. One window is one render context:
 the popup's hide and the stage's arrival are one commit, the material is the stage's alone from that commit on (so
 it never matters which turn UIKit takes the cover off in), and the landing's un-hide is one commit with the copy
 still over it — none of which two windows ever promised (the first flight spaced every such pair a beat apart).

 Geometry-matched hero flight: its measured curves live in-file, per the motion rules.
 */
enum ViewEventFlightMotion {
    //THE tuning knob — the card's one spring: travel, size and the riders pinned to it all in the same transaction, so
    //every edge overshoots the same 4.6% of its OWN travel (on a 402pt screen the photo's foot dips ~7pt past its slot,
    //its top ~3.5pt) and comes back once. Arthur, 2026-09-17: "one soft overshoot" over the first flight's 16pt sink
    //and 0.7s creep home.
    static let spring = Spring(duration: 0.5, bounce: 0.3)
    static let reaim = Spring(duration: 0.4, bounce: 0) //`.move`'s clock without its bounce: a correction glides, it never adds a second overshoot

    static let chromeFade: TimeInterval = 0.15 //The popup's title and its halo leave the photo
    static let arrival: TimeInterval = 0.25 //The event's own chrome — its dots, its rim — arriving on the card
    static let arrivalDelay: TimeInterval = 0.12 //…once the title has left the photo
    static let buttonPop: TimeInterval = 0.25 //`Animation.transition`, which the popup's own row pops on, mirrored for UIKit
    static let frostBeat: TimeInterval = 0.02 //The material holds this long over the committed switch, so the cut is never seen
    static let frostLift: TimeInterval = 0.26 //Eased out only (see `liftFrost`): legible ~0.13s in, sharp by ~0.19s. 0.3 eased in AND out read a beat late on device (Arthur, 2026-09-17)
    static let frostCap: Duration = .milliseconds(250) //From the cover's going: the material clears even if the event's card has not reported in
    static let handOff: TimeInterval = 0.12 //`Animation.handOff`, mirrored for UIKit
    static let curtainFade: TimeInterval = 0.22 //`Animation.dismiss`, mirrored for UIKit

    //Derived, never tuned: the spring's overshoot at its deepest (0.35s for 0.5/0.3). From there the card only comes
    //home, so the landing may swap pixels as soon as the render server is drawing it within a pixel of its slot —
    //a first pass THROUGH the slot, a tenth of a second earlier, is not a landing
    static var peak: TimeInterval {
        let zeta = 1 - spring.bounce
        return Double.pi / (2 * Double.pi / spring.duration * (1 - zeta * zeta).squareRoot())
    }

    static let commitBeat: Duration = .milliseconds(34) //Two display frames: a commit made now is on screen once it has passed
    static let pageRecheck: Duration = .milliseconds(100)
    static let quiet: TimeInterval = 0.08 //The pad's settle signal — its rect unmoved for this long
    static let listingCap: Duration = .milliseconds(400) //From the switch: an event whose card has not even reported by now is not there to land on
    static let holdCap: Duration = .milliseconds(1200) //A fade's wait for the event's card, from the switch: a first visit mounts the whole tab
    static let landingCap: Duration = .milliseconds(2000) //A flight's: the card is down in well under a second, and the event must be landable by then
    static let watchdog: Duration = .milliseconds(3500) //Past every cap above: whatever else has happened, the stage goes and touches return
    static let aimTolerance: CGFloat = 1 //A pad further off than this is re-aimed at; anything less goes unseen under the landing's dissolve
    static let restTolerance: CGFloat = 0.34 //A device pixel at @3x: the card is home once the render server draws it this close
    static let reaimLimit = 2 //A pad still moving after this many corrections is left to the landing's dissolve
}

//Where the flight lands: the event's photo, and the card it tops
private struct ViewEventFlightAim: Equatable {
    var photo: CGRect
    var card: CGRect

    func matches(_ other: ViewEventFlightAim, within tolerance: CGFloat) -> Bool {
        Self.same(photo, other.photo, tolerance) && Self.same(card, other.card, tolerance)
    }

    //On whole device pixels, as SwiftUI draws what it lays out between them
    func pixelAligned(_ scale: CGFloat) -> ViewEventFlightAim {
        ViewEventFlightAim(photo: photo.pixelAligned(scale), card: card.pixelAligned(scale))
    }

    static func same(_ a: CGRect, _ b: CGRect, _ tolerance: CGFloat) -> Bool {
        abs(a.minX - b.minX) <= tolerance && abs(a.minY - b.minY) <= tolerance
            && abs(a.maxX - b.maxX) <= tolerance && abs(a.maxY - b.maxY) <= tolerance
    }
}

@MainActor @Observable final class ViewEventFlight {

    struct Request {
        let eventId: String
        let departure: EventZoomDeparture
        let flies: Bool //False under Reduce Motion, or for a card handed over before it could stand still: a picture of the screen fades onto the event instead
    }

    struct Handlers {
        let closeCalendar: () -> Void
        let openEvent: () -> Void
        let stillTargeted: () -> Bool //Nothing newer (a deep link, a pushed chat) has taken the Events tab since
    }

    private struct PadReport {
        var photo = CGRect.zero
        var card = CGRect.zero
        var progress = 0.0
        var dotsWindow = 0 //Where the page indicator's run of full-size dots starts: it remembers how it was paged, and a twin must too
        var images: [WeakImage] = [] //Weak: kept for the card's lifetime, never for its photos'
        var at = Date.distantPast //The last time any of it CHANGED: a re-assertion of the same page or rect is not motion
    }

    private struct WeakImage {
        weak var image: UIImage?
    }

    private enum Verdict { case wait, land(ViewEventFlightAim), miss }

    //The landing pad, read by EventImageCard
    private(set) var padEventId: String? //Arming it is what turns the card
    private(set) var padHidesImage = false //A flight owns the photo's pixels from the switch to the landing
    private(set) var padLanded = false //The copy sits on the photo: it shows again, beneath the copy
    @ObservationIgnored private var padSource: UIImage? //The popup's photo as its caller holds it
    @ObservationIgnored private var padIndex = 0
    @ObservationIgnored private var padCount = 0
    @ObservationIgnored private var reports: [String: PadReport] = [:] //Every card's latest, kept: a warm card that never moves never reports again

    //The stage
    @ObservationIgnored private var request: Request?
    @ObservationIgnored private var handlers: Handlers?
    @ObservationIgnored private var stage: ViewEventFlightStage?
    @ObservationIgnored private weak var appWindow: UIWindow?
    @ObservationIgnored private weak var tabs: UITabBarController? //The TabView's controller, for UIKit's own word on which tab is on the glass
    @ObservationIgnored private weak var originTab: UIViewController? //…and the tab the popup's cover was presented from
    @ObservationIgnored private var generation = 0 //Every turn, beat and completion is checked against it: a newer run, or a teardown, owns the stage
    @ObservationIgnored private var run: Task<Void, Never>?
    @ObservationIgnored private var background: NSObjectProtocol?
    @ObservationIgnored private var aim: ViewEventFlightAim?
    @ObservationIgnored private var leftAt: CFTimeInterval = 0 //The tap's turn, on the render server's clock
    @ObservationIgnored private var switchAskedAt: CFTimeInterval = 0
    @ObservationIgnored private var switchedAt: ContinuousClock.Instant?
    @ObservationIgnored private var coverGoneAt: ContinuousClock.Instant?
    @ObservationIgnored private var calendarClosed = false
    @ObservationIgnored private var frostLifting = false
    @ObservationIgnored private var frostClearAt: CFTimeInterval? //When the lifting material has wholly gone: the landing swaps no pixels under a blur
    @ObservationIgnored private var commits: CFRunLoopObserver? //Watches every commit from the switch until the material lifts
    @ObservationIgnored private var switchStillsUIKit = false //UIKit's animations are off, app-wide, for the turns of the switch — and MUST come back on
    @ObservationIgnored private var stageSize = CGSize.zero //A rotation or a split-view resize ends the flight
    @ObservationIgnored private var appWasHiddenFromAccessibility = false //The app window's own setting, put back at teardown

    private static var instant: Transaction {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        return transaction
    }
}

//The landing pad: EventImageCard reports where it is and what it shows, turns to the popup's page, and hides its
//photo while the flight owns those pixels
extension ViewEventFlight {

    ///The page a card turns to before the flight lands on it: the popup's own photo, matched by identity (one
    ///ImageLoader cache feeds both screens), else by index when both sets are the same length
    func landingPage(for id: String, in images: [UIImage]) -> Int? {
        guard padEventId == id else { return nil }
        return Self.landingIndex(count: images.count, source: padSource, index: padIndex, of: padCount) { images[$0] }
    }

    private static func landingIndex(count: Int, source: UIImage?, index: Int, of sourceCount: Int, image: (Int) -> UIImage?) -> Int? {
        guard count > 0 else { return nil }
        if let source, let match = (0..<count).first(where: { image($0) === source }) { return match }
        return count == sourceCount && index < count ? index : nil
    }

    func imageHidden(_ id: String) -> Bool {
        padEventId == id && padHidesImage && !padLanded
    }

    func padProgress(for id: String) -> Double? {
        reports[id]?.progress
    }

    func reportPad(frame: CGRect, id: String) {
        let moved = !ViewEventFlightAim.same(reports[id]?.photo ?? .null, frame, 0.5)
        reports[id, default: PadReport()].photo = frame
        if moved { reports[id]?.at = Date() }
    }

    ///The whole card the photo tops — what the popup's card becomes
    func reportPad(card: CGRect, id: String) {
        let moved = !ViewEventFlightAim.same(reports[id]?.card ?? .null, card, 0.5)
        reports[id, default: PadReport()].card = card
        if moved { reports[id]?.at = Date() }
    }

    func reportPad(progress: Double, id: String) {
        let moved = abs((reports[id]?.progress ?? -1) - progress) > 0.001
        reports[id, default: PadReport()].progress = progress
        if moved { reports[id]?.at = Date() }
    }

    func reportPad(dotsWindow: Int, id: String) {
        reports[id, default: PadReport()].dotsWindow = dotsWindow
    }

    func reportPad(images: [UIImage], id: String) {
        let changed = reports[id]?.images.count != images.count
        reports[id, default: PadReport()].images = images.map { WeakImage(image: $0) }
        if changed { reports[id]?.at = Date() }
    }

    private static let slotKey = "viewEventFlight.landingSlot"

    //Self-calibrating, as MapSheetFlight's sheet frame is: every landing records where the event's photo was, so from
    //the second flight on a device the card aims true before the Events tab has laid out at all
    private static func recordSlot(_ rect: CGRect) {
        UserDefaults.standard.set([rect.minX, rect.minY, rect.width, rect.height].map(Double.init), forKey: slotKey)
    }

    private static var recordedSlot: CGRect? {
        guard let values = UserDefaults.standard.array(forKey: slotKey) as? [Double], values.count == 4 else { return nil }
        return CGRect(x: values[0], y: values[1], width: values[2], height: values[3])
    }

    //A page's photo on this screen, full size, where a landing can be seen: clear of the status bar and of the tab bar
    private static func isSlot(_ rect: CGRect, in window: UIWindow) -> Bool {
        let width = window.bounds.width - 2 * Spacing.gutter
        return abs(rect.minX - Spacing.gutter) < 2 && abs(rect.width - width) < 2 && rect.height > 150
            && rect.minY >= window.safeAreaInsets.top && rect.maxY <= window.bounds.maxY - Spacing.clearance
    }

    //The card the photo tops: the reported one when it is that — the photo edge to edge along its top, a timer strip's
    //depth under it — else the photo with the strip worked out. The two rects arrive a layout pass apart
    private static func card(around photo: CGRect, reported: CGRect) -> CGRect {
        let strip = reported.height - photo.height
        if abs(reported.minX - photo.minX) < 1, abs(reported.minY - photo.minY) < 1, abs(reported.width - photo.width) < 1,
           abs(strip - EventImageCard.timerStripHeight) < 12 {
            return reported
        }
        return CGRect(x: photo.minX, y: photo.minY, width: photo.width, height: photo.height + EventImageCard.timerStripHeight)
    }

    //Where the event's photo will rest, asked BEFORE Events is on screen: the card's own report where it already rests
    //about there (one left scrolled, or paged away, reports a rect the switch is about to move), else the last landing's
    //slot — every event's photo rests there once `focusEvent` has scrolled to the top — else the Events tab's layout
    //worked out. Any miss is re-aimed in flight
    private func predictedAim(for id: String, in window: UIWindow) -> ViewEventFlightAim {
        let width = window.bounds.width - 2 * Spacing.gutter
        //Geometry: the large title's bar (106 under iOS 26's taller bar row, 96 before it) and the tab's title padding
        //above the first slot; the photo's 1:1.02 (EventImageCarousel)
        let bar: CGFloat = if #available(iOS 26.0, *) { 106 } else { 96 }
        let estimate = CGRect(x: Spacing.gutter, y: window.safeAreaInsets.top + bar + Spacing.titlePadding,
                              width: width, height: width * 1.02)
        let rest = Self.recordedSlot.flatMap { Self.isSlot($0, in: window) ? $0 : nil } ?? estimate
        if let report = reports[id], Self.isSlot(report.photo, in: window), abs(report.photo.minY - rest.minY) <= 40 {
            return ViewEventFlightAim(photo: report.photo, card: Self.card(around: report.photo, reported: report.card))
        }
        return ViewEventFlightAim(photo: rest, card: Self.card(around: rest, reported: .zero))
    }
}

//The flight: raised over the popup in the tap's turn, taken down on the event
extension ViewEventFlight {

    ///Raises the stage and runs the flight. False when there is no stage to raise (no active window, no picture): the
    ///caller cuts straight to the event instead
    func begin(_ request: Request, handlers: Handlers) -> Bool {
        guard self.request == nil, let window = Self.tappedWindow(), window.bounds.width > 1 else { return false }
        let tapped = CACurrentMediaTime()
        let aim = predictedAim(for: request.eventId, in: window)
        let stage = (canFly(request, to: aim, in: window) ? request.departure.photo : nil)
            .flatMap { ViewEventFlightStage(flying: request.departure, photo: $0, to: aim, dots: dots(for: request), in: window) }
            ?? ViewEventFlightStage(curtainOver: window)
        guard let stage else { return false }
        generation += 1
        let g = generation
        self.request = request
        self.handlers = handlers
        self.stage = stage
        self.aim = stage.flies ? aim : nil
        appWindow = window
        tabs = window.rootViewController.flatMap(Self.tabBarController(under:))
        originTab = tabs?.selectedViewController
        stageSize = window.bounds.size
        calendarClosed = false
        frostLifting = false
        frostClearAt = nil
        switchedAt = nil
        coverGoneAt = nil
        leftAt = tapped

        window.addSubview(stage.overlay)
        if stage.flies {
            stage.fly()
            request.departure.hide() //Same turn, same render context: the popup — card, buttons and material — goes in the frame its copy appears
        }
        //An inert copy, and two screens changing under it: nothing here is for VoiceOver until the event has landed
        appWasHiddenFromAccessibility = window.accessibilityElementsHidden
        window.accessibilityElementsHidden = true
        background = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.abandon() }
        }
        Task { [weak self] in
            try? await Task.sleep(for: ViewEventFlightMotion.watchdog * EventZoomChoreo.timeScale)
            self?.expire(g)
        }
        viewEventLog.debug("begin \(request.eventId, privacy: .public) page \(request.departure.page) flies \(stage.flies), staged in \(Self.ms(since: tapped)) ms")
        //The switch is asked for only once this turn's commit has gone to the render server — whatever it costs the main
        //thread, the flight is already running there — and one empty turn after that: a popup whose hide rendered a
        //pass late is off the glass too before the long turn begins
        Self.afterCommit { [weak self] in
            guard let self, g == self.generation else { return }
            Self.afterCommit { [weak self] in self?.switchScreens(g) }
        }
        return true
    }

    ///The calendar cover's onDismiss: UIKit has really taken it off, animated or not
    func coverDidDismiss() {
        guard request != nil, calendarClosed else { return }
        viewEventLog.debug("cover gone \(Self.ms(since: self.leftAt)) ms after the tap")
    }

    //A card flies on a portrait phone, to a pad it can be seen landing on, and — where the event's card has already said
    //what it holds — only to one that can show the popup's photo. Anything else fades
    private func canFly(_ request: Request, to aim: ViewEventFlightAim, in window: UIWindow) -> Bool {
        guard request.flies, request.departure.photo != nil, UIView.areAnimationsEnabled,
              window.bounds.width < window.bounds.height, window.traitCollection.horizontalSizeClass == .compact,
              Self.isSlot(aim.photo, in: window), window.bounds.intersects(request.departure.card) else { return false }
        //Only on what the event's card has SAID: one that has not reported yet — a first visit, or an event listed since
        //the tab was last on screen — flies, and the landing sorts out the rest (not listed: `listingCap`; other photos: a miss)
        guard let images = reports[request.eventId]?.images, !images.isEmpty else { return true }
        return Self.landingIndex(count: images.count, source: request.departure.source, index: request.departure.page,
                                 of: request.departure.pageCount, image: { images[$0].image }) != nil
    }

    //The dots the event's card will show under the landed photo: its own count where it has reported one, else the popup's
    private func dots(for request: Request) -> (count: Int, page: Int, window: Int) {
        let departure = request.departure
        let images = reports[request.eventId]?.images ?? []
        let count = images.isEmpty ? departure.pageCount : images.count
        let page = Self.landingIndex(count: images.count, source: departure.source, index: departure.page,
                                     of: departure.pageCount, image: { images[$0].image }) ?? departure.page
        return (count, min(max(page, 0), max(count - 1, 0)), reports[request.eventId]?.dotsWindow ?? 0)
    }

    //One turn: the pad arms, the calendar closes and Events opens on the event's card — under the stage's material, so
    //it never matters which commit UIKit takes the cover off in. Everything this costs the main thread is paid while the
    //card flies on the render server
    private func switchScreens(_ g: Int) {
        guard g == generation, let request, let handlers, let stage else { return }
        withTransaction(Self.instant) {
            padSource = request.departure.source
            padIndex = request.departure.page
            padCount = request.departure.pageCount
            padLanded = false
            padHidesImage = stage.flies
            padEventId = request.eventId //Last: the cards' turn reads the fields above
        }
        calendarClosed = true //First: the cover's onDismiss may land inside the close itself
        switchAskedAt = CACurrentMediaTime()
        switchedAt = .now
        //SwiftUI takes a cover off without its animation only when it acts on the write inside this transaction, and with
        //the Events tab mounting for the first time alongside it does not: the cover's zoom-out then runs for a second
        //under the material (sim-traced 2026-09-17, `isBeingDismissed` from the switch to the teardown). So UIKit is asked
        //first, and the cover is off in this turn's commit whichever way SwiftUI goes; its write then finds nothing to do.
        //And the tab bar controller crossfades its tabs whatever SwiftUI's transaction says (sim-traced: the origin tab
        //under the material for up to eight frames, then a 0.2–0.6s crossfade to Events, which a lifting material would
        //show): UIKit's animations are switched off for the turns the switch is acted on in, and back on before the
        //material's own lift. The flight's springs are with the render server already, and are not touched
        if UIView.areAnimationsEnabled {
            switchStillsUIKit = true
            UIView.setAnimationsEnabled(false)
        }
        appWindow?.rootViewController?.dismiss(animated: false)
        handlers.closeCalendar()
        handlers.openEvent()
        viewEventLog.debug("switch asked \(Self.ms(since: self.leftAt)) ms after the tap")
        //Which turn SwiftUI and UIKit act on those writes in is theirs to choose (sim-measured: not always this one), so
        //the material's lift is decided on evidence, straight after EVERY commit from here on — never a turn later,
        //behind whatever Events queues next
        if stage.flies {
            commits = Self.afterEveryCommit { [weak self] in self?.liftFrostIfShown(g) }
            run = Task { [weak self] in await self?.watchLanding(g) }
        } else {
            run = Task { [weak self] in await self?.holdThenLift(g) }
        }
    }

    private func restoreUIKitAnimations() {
        guard switchStillsUIKit else { return }
        switchStillsUIKit = false
        UIView.setAnimationsEnabled(true)
    }

    //UIKit's own word on the cover, which SwiftUI's onDismiss trails by a turn or more
    private var coverGone: Bool {
        appWindow?.rootViewController?.presentedViewController == nil
    }

    //Events is the tab in the window — UIKit's word again: the pad's report may be one kept from an earlier visit, and says
    //nothing of what is on the glass NOW. No tab bar controller found (a root built some other way): the pad's word stands alone
    private var tabOnGlass: Bool {
        guard let tabs else { return true }
        return tabs.selectedViewController !== originTab && tabs.selectedViewController?.viewIfLoaded?.window != nil
    }

    //The event's card is where a landing can be seen — listed, on its page, full size with its photos in. Not yet still
    private var padOnGlass: Bool {
        guard let id = padEventId, let report = reports[id], !report.images.isEmpty, let appWindow else { return false }
        return Self.isSlot(report.photo, in: appWindow)
    }

    //The material clears off the event once the cover is really gone, Events really the tab in the window and the event's
    //card really there — or, the cover gone, at the cap: a blur pulling focus, which the render server runs. Never over the calendar. Flushed, so it is not
    //held behind Events' next turns
    private func liftFrostIfShown(_ g: Int) {
        guard g == generation, !frostLifting, let stage, let appWindow, coverGone else { return }
        if coverGoneAt == nil {
            coverGoneAt = .now
            appWindow.bringSubviewToFront(stage.overlay) //Whatever the dismissal put back went in beneath the stage; say so again
            viewEventLog.debug("switched in \(Self.ms(since: self.switchAskedAt)) ms, \(Self.ms(since: self.leftAt)) ms after the tap")
        }
        guard (tabOnGlass && padOnGlass) || ContinuousClock.now >= (coverGoneAt ?? .now) + ViewEventFlightMotion.frostCap else { return }
        frostLifting = true
        frostClearAt = CACurrentMediaTime() + (ViewEventFlightMotion.frostBeat + ViewEventFlightMotion.frostLift) * EventZoomChoreo.timeScale + 0.034
        restoreUIKitAnimations()
        if let commits { CFRunLoopObserverInvalidate(commits) }
        commits = nil
        stage.liftFrost()
        CATransaction.flush()
        viewEventLog.debug("frost lifts \(Self.ms(since: self.leftAt)) ms after the tap, pad \(self.padOnGlass ? "on the glass" : "not in yet", privacy: .public)")
    }

    //Landable: on the glass, and quiet — its rect and its page unmoved for `quiet`, and the switch at least that long
    //ago: the accept pad's settle signal — then holding the popup's photo, turned to it. A card whose set cannot show that photo is a miss,
    //but only once it has settled like the rest
    private func verdict() -> Verdict {
        guard padOnGlass, let id = padEventId, let report = reports[id], let switchedAt else { return .wait }
        let quiet = ViewEventFlightMotion.quiet
        guard Date().timeIntervalSince(report.at) > quiet, ContinuousClock.now - switchedAt > .seconds(quiet) else { return .wait }
        let page = Self.landingIndex(count: report.images.count, source: padSource, index: padIndex, of: padCount,
                                     image: { report.images[$0].image })
        guard let page else { return .miss }
        guard abs(report.progress - Double(page)) < 0.01 else { return .wait }
        return .land(ViewEventFlightAim(photo: report.photo, card: Self.card(around: report.photo, reported: report.card)))
    }

    //Nothing on screen waits for this loop — the card is flying, the material clearing — so its pace only decides how
    //soon a miss is corrected and the photo handed over
    private func watchLanding(_ g: Int) async {
        guard let switchedAt else { return }
        let earliest = leftAt + ViewEventFlightMotion.peak * EventZoomChoreo.timeScale
        var reaims = 0
        while g == generation, handlers?.stillTargeted() == true, appWindow?.bounds.size == stageSize,
              ContinuousClock.now < switchedAt + ViewEventFlightMotion.landingCap * EventZoomChoreo.timeScale {
            liftFrostIfShown(g)
            if let stage, let appWindow, appWindow.subviews.last !== stage.overlay { appWindow.bringSubviewToFront(stage.overlay) }
            switch verdict() {
            case .miss:
                abort(g)
                return
            case .land(let pad):
                if let aim, !aim.matches(pad, within: ViewEventFlightMotion.aimTolerance), reaims < ViewEventFlightMotion.reaimLimit {
                    viewEventLog.debug("re-aim \(String(describing: aim.photo), privacy: .public) → \(String(describing: pad.photo), privacy: .public)")
                    stage?.retarget(pad)
                    self.aim = pad
                    reaims += 1
                }
                //Home, and the material wholly gone: the real photo showing through a blur still clearing would blur the landing
                if CACurrentMediaTime() >= max(earliest, frostClearAt ?? .infinity), stage?.isSettled == true {
                    handOff(g, onto: pad)
                    return
                }
            case .wait:
                //An event that is not in the list will never report: better the fade now than a card parked over another's event
                if let id = padEventId, reports[id] == nil, ContinuousClock.now >= switchedAt + ViewEventFlightMotion.listingCap {
                    abort(g)
                    return
                }
            }
            try? await Task.sleep(for: .milliseconds(16))
        }
        guard g == generation else { return }
        abort(g)
    }

    //The accept flight's landing, in one render context: the event's photo and dots show again beneath the opaque copy,
    //that commit reaches the screen — its photo's first decode paid while nothing moves — and the copy, by now only the
    //photo and what rides it, dissolves off identical pixels
    private func handOff(_ g: Int, onto pad: ViewEventFlightAim) {
        guard g == generation, let stage else { return }
        Self.recordSlot(pad.photo)
        stage.settle(on: pad)
        withTransaction(Self.instant) { padLanded = true }
        viewEventLog.debug("hand-off \(Self.ms(since: self.leftAt)) ms after the tap")
        Self.afterCommit { [weak self] in
            guard let self, g == self.generation else { return }
            self.run = Task { [weak self] in
                try? await Task.sleep(for: ViewEventFlightMotion.commitBeat)
                guard let self, g == self.generation else { return }
                stage.dissolve { [weak self] in self?.teardown(g) }
            }
        }
    }

    //The event's card could not take the photo — it never settled or listed, its photos differ, the tab was taken, or
    //the screen changed shape: the photo shows where it is, and the copy and whatever material is left fade off it
    private func abort(_ g: Int) {
        guard g == generation, let stage else { return }
        viewEventLog.debug("abort \(Self.ms(since: self.leftAt)) ms after the tap")
        restoreUIKitAnimations() //Before the fade below, which is UIKit's
        if case .land(let pad) = verdict() { stage.settle(on: pad) } //Fading off the photo it is over, not beside it
        withTransaction(Self.instant) { padHidesImage = false }
        stage.fadeAway { [weak self] in self?.teardown(g) }
    }

    //No flight: the picture holds while the event's card settles under it, then fades off the event
    private func holdThenLift(_ g: Int) async {
        guard let switchedAt else { return }
        while g == generation, handlers?.stillTargeted() == true, ContinuousClock.now < switchedAt + ViewEventFlightMotion.holdCap {
            if coverGone, case .land = verdict() { break }
            if coverGone, case .miss = verdict() { break }
            try? await Task.sleep(for: .milliseconds(16))
        }
        guard g == generation, let stage else { return }
        restoreUIKitAnimations() //Before the fade below, which is UIKit's
        stage.fadeAway { [weak self] in self?.teardown(g) }
    }

    //Backgrounded mid-flight (the render server drops every animation): before the calendar closed, the popup is handed
    //back exactly as it was; after, the Events tab is already open and the stage simply goes
    private func abandon() {
        guard let request else { return }
        if !calendarClosed { request.departure.restore() }
        teardown(generation)
    }

    //The watchdog: the stage takes every touch, so nothing — a turn that never came, a completion that never fired — may
    //leave it up
    private func expire(_ g: Int) {
        guard g == generation, request != nil else { return }
        viewEventLog.error("watchdog: the stage was still up")
        abandon()
    }

    private func teardown(_ g: Int) {
        guard g == generation, request != nil else { return }
        generation += 1
        restoreUIKitAnimations()
        run?.cancel()
        run = nil
        if let commits { CFRunLoopObserverInvalidate(commits) }
        commits = nil
        stage?.overlay.removeFromSuperview() //Gone before any observed state resets, so no reset is ever seen
        stage = nil
        if let background { NotificationCenter.default.removeObserver(background) }
        background = nil
        withTransaction(Self.instant) {
            padEventId = nil
            padHidesImage = false
            padLanded = false
        }
        padSource = nil
        request = nil
        handlers = nil
        aim = nil
        tabs = nil
        originTab = nil
        calendarClosed = false
        switchedAt = nil
        coverGoneAt = nil
        appWindow?.accessibilityElementsHidden = appWasHiddenFromAccessibility
        UIAccessibility.post(notification: .screenChanged, argument: nil) //VoiceOver re-reads the event it has landed on
        viewEventLog.debug("teardown \(Self.ms(since: self.leftAt)) ms after the tap")
    }

    private static func ms(since start: CFTimeInterval) -> Int {
        Int(((CACurrentMediaTime() - start) * 1000).rounded())
    }
}

//The run loop's seam
extension ViewEventFlight {

    //Runs `body` in a turn of its own, once the changes made so far are with the render server. Core Animation commits
    //a turn from a run-loop observer (before-waiting, order 2,000,000), so an observer one place behind it sits just
    //after the commit — where a display-link tick proves nothing (sim-measured: it can fire 0.2ms after the build, the
    //commit still to come) and the main queue can be drained BEFORE the observers run. But neither that order nor that
    //pass is promised by anyone, so the seat flushes for itself before it lets `body` go — a no-op when the commit has
    //gone, the commit itself when it has not — and a timer one frame long stands behind the observer: a loop busy with
    //the finger's last touch events skips its before-waiting pass, and every frame waited here is a frame the switch,
    //and so the screen's arrival, starts late. `body` hops to a fresh turn from there: SwiftUI state written inside the
    //observer pass would wait out the next one
    private static func afterCommit(_ body: @escaping @MainActor () -> Void) {
        var pending = true
        let go = {
            guard pending else { return }
            pending = false
            MainActor.assumeIsolated { CATransaction.flush() }
            DispatchQueue.main.async { MainActor.assumeIsolated { body() } }
        }
        let observer = CFRunLoopObserverCreateWithHandler(nil, CFRunLoopActivity.beforeWaiting.rawValue, false, 2_000_001) { _, _ in go() }
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
        CFRunLoopWakeUp(CFRunLoopGetMain()) //A loop already asleep would otherwise hold the observer until something else woke it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.017) {
            if pending, let observer { CFRunLoopObserverInvalidate(observer) }
            go()
        }
    }

    //The same seat, kept, and not hopped from: `body` runs straight after every commit — ahead of whatever is queued
    //behind it — until the observer is invalidated
    private static func afterEveryCommit(_ body: @escaping @MainActor () -> Void) -> CFRunLoopObserver? {
        let observer = CFRunLoopObserverCreateWithHandler(nil, CFRunLoopActivity.beforeWaiting.rawValue, true, 2_000_001) { _, _ in
            MainActor.assumeIsolated { body() }
        }
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
        return observer
    }

    private static func tabBarController(under controller: UIViewController) -> UITabBarController? {
        if let tabs = controller as? UITabBarController { return tabs }
        return controller.children.lazy.compactMap(tabBarController(under:)).first
    }

    //The window the tap landed in: the key one — a touch makes its window key — when it is an ordinary window, else the
    //active scene's first ordinary one (a menu or an alert plane can hold key for a moment)
    private static func tappedWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        let windows = scenes.flatMap(\.windows).filter { $0.windowLevel == .normal && !$0.isHidden }
        return windows.first(where: \.isKeyWindow) ?? windows.first
    }
}

//MARK: - The stage

//Everything the flight draws, in one plain view over the app window's other planes: UIKit views posed once where the
//popup stands and sent on their way by UIKit's own springs, which the render server runs. Nothing here is SwiftUI — a
//hosting controller's first layout costs the tap's turn tens of milliseconds, and its animations stop with the main
//thread
@MainActor
private final class ViewEventFlightStage {

    let overlay = UIView()
    let flies: Bool

    private let wash = UIView() //EventBackdrop's white, which lies UNDER its material
    private let frost = UIVisualEffectView(effect: nil)
    private let card = UIView() //The plate and the clip as one group, so the landing dissolves them as one surface
    private let plate = UIView() //The card's ground and its shadow: a clipped view casts none
    private let clip = UIView()
    private let photo = UIImageView()
    private let dots = UIView()
    private let rim = UIView()
    private var rows: UIView?
    private var chrome: UIView?
    private var buttons: [UIView] = []
    private var curtain: UIView?
    private var aim: ViewEventFlightAim
    private var rest = CGRect.zero //The popup's card, where the stage was posed: the rows stay where it put them
    private var rowsRest = CGRect.zero

    private static let dotsBand: CGFloat = 32 //Geometry: the strip along the photo's foot the dots are laid out in
    private static let rimWidth: CGFloat = 0.85 //`eventCardBackground`'s hairline, which the landed card must already wear
    //Around each button's picture. iOS 26's glass throws its shadow far further than it looks — still ten levels dark
    //14pt out, gone only ~40pt below the lens (sim-measured) — and a picture cut inside it shows as a box from its first
    //frame. So the picture takes the whole shadow, and is feathered out from well clear of the lens
    private static let buttonRoom: (side: CGFloat, below: CGFloat) = (44, 56)
    private static let featherReach: CGFloat = 28 //The mask's edge, this far out from the lens…
    private static let featherRadius: CGFloat = 8 //…and this soft: the lens itself sits in the mask's opaque core
    private static let footFade: CGFloat = 16 //Geometry: the popup photo's blurred foot and edge fade, which the title's picture lets go of first

    ///A flying card, posed exactly where the popup's stands, under the popup's own material. Nil when the render server
    ///will not give up the popup's pixels (the rows or the band): the caller fades instead
    init?(flying departure: EventZoomDeparture, photo image: UIImage, to aim: ViewEventFlightAim,
          dots: (count: Int, page: Int, window: Int), in window: UIWindow) {
        flies = true
        let scale = window.screen.scale
        self.aim = ViewEventFlightAim(photo: aim.photo.pixelAligned(scale), card: aim.card.pixelAligned(scale))
        let cardRect = departure.card.pixelAligned(scale)
        let band = departure.band.pixelAligned(scale)
        let rowsRect = CGRect(x: cardRect.minX, y: band.maxY, width: cardRect.width, height: cardRect.maxY - band.maxY)
        //The render server's own pixels, taken before anything hides: the title and its halo over the photo, the rows
        //in their own type, the glass as it stands under the finger
        guard let chrome = Self.picture(of: band, in: window),
              let rows = rowsRect.height > 1 ? Self.picture(of: rowsRect, in: window) : UIView() else { return nil }
        let buttons = Self.buttonRects(for: departure, in: window).compactMap { Self.picture(ofButton: $0.pixelAligned(scale), in: window) }
        self.chrome = chrome
        self.rows = rows
        self.buttons = buttons
        prepareOverlay(in: window)

        //The popup's material, which is the stage's alone from this turn on: `.systemMaterial` is `.regularMaterial` to
        //within two levels (sim-measured), over EventBackdrop's white
        wash.alpha = 0.2
        frost.effect = UIBlurEffect(style: .systemMaterial)

        card.frame = overlay.bounds
        card.isUserInteractionEnabled = false
        overlay.addSubview(card)

        plate.frame = cardRect
        plate.backgroundColor = .white
        plate.layer.cornerRadius = CornerRadius.image
        plate.layer.cornerCurve = .continuous
        let contact = Elevation.card.layers.contact
        plate.layer.shadowColor = UIColor.black.cgColor
        plate.layer.shadowOpacity = Float(contact.opacity)
        plate.layer.shadowRadius = contact.radius
        plate.layer.shadowOffset = CGSize(width: 0, height: contact.y)
        card.addSubview(plate)

        clip.frame = cardRect
        clip.clipsToBounds = true
        clip.layer.cornerRadius = CornerRadius.image
        clip.layer.cornerCurve = .continuous
        card.addSubview(clip)

        //The rows never travel: the card's frame moves over them, the photo's foot comes down across them, and they fade
        //as they are covered. Their picture's foot carries the material outside the card's old corners, so it is cut to
        //those corners — the card's new ones, a few points on, must not bare it
        rest = cardRect
        rowsRest = rowsRect.offsetBy(dx: -cardRect.minX, dy: -cardRect.minY)
        rows.frame = rowsRest
        rows.layer.cornerRadius = CornerRadius.image
        rows.layer.cornerCurve = .continuous
        rows.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        rows.layer.masksToBounds = true
        clip.addSubview(rows)

        photo.image = image
        photo.contentMode = .scaleAspectFill //Re-cropped by the render server on every frame of the morph: SwiftUI's scaledToFill, at any size
        photo.clipsToBounds = true
        photo.frame = band.offsetBy(dx: -cardRect.minX, dy: -cardRect.minY)
        clip.addSubview(photo)

        //Centred on the photo, where its pixels and the layer's agree; its foot — the band's blur and edge fade, which
        //belong to an edge that is leaving — masked off, so no seam crosses the growing photo as the title goes
        chrome.frame = photo.bounds
        chrome.layer.cornerRadius = CornerRadius.image //Its own top corners: past the card's, the picture holds the material, which sliding down the photo would bare
        chrome.layer.cornerCurve = .continuous
        chrome.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        chrome.layer.masksToBounds = true
        let foot = CAGradientLayer()
        foot.frame = chrome.bounds
        foot.colors = [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        foot.locations = [0, NSNumber(value: Double(1 - Self.footFade / max(chrome.bounds.height, 1))), 1]
        chrome.layer.mask = foot
        photo.addSubview(chrome)

        self.dots.frame = CGRect(x: 0, y: photo.bounds.height - Self.dotsBand, width: photo.bounds.width, height: Self.dotsBand)
        self.dots.alpha = 0
        let cluster = CGSize(width: aim.photo.width, height: Self.dotsBand)
        for dot in EventImageCarousel.restingDots(count: dots.count, page: dots.page, from: dots.window, in: cluster) {
            let layer = CALayer()
            layer.frame = dot.frame
            layer.cornerRadius = dot.frame.height / 2
            layer.backgroundColor = UIColor.white.cgColor
            layer.opacity = Float(dot.opacity)
            self.dots.layer.addSublayer(layer)
        }
        photo.addSubview(self.dots)

        //The event card's hairline, drawn over the photo's edge and outside the card's clip, as `eventCardBackground`
        //draws it — whole pixels, as Strokes.swift snaps them
        rim.frame = cardRect
        rim.layer.cornerRadius = CornerRadius.image
        rim.layer.cornerCurve = .continuous
        rim.layer.borderColor = UIColor(Color.fillGray).cgColor
        rim.layer.borderWidth = max(1, (Self.rimWidth * scale).rounded()) / scale
        rim.alpha = 0
        card.addSubview(rim)

        //The row as it stood when tapped, each button its own picture so each pops about its own centre
        for button in buttons { overlay.addSubview(button) }
    }

    ///No flight: a still picture of the screen, which fades off the event once it has settled underneath
    init?(curtainOver window: UIWindow) {
        flies = false
        aim = ViewEventFlightAim(photo: .zero, card: .zero)
        guard let curtain = window.snapshotView(afterScreenUpdates: false) else { return nil }
        self.curtain = curtain
        prepareOverlay(in: window)
        curtain.frame = overlay.bounds
        curtain.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.addSubview(curtain)
    }

    private func prepareOverlay(in window: UIWindow) {
        overlay.frame = window.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = .clear
        overlay.layer.zPosition = 10_000 //Whatever the dismissal puts back in the window draws beneath the stage
        overlay.isUserInteractionEnabled = true //Every touch is the flight's while the stage is up
        overlay.layer.speed = Float(1 / EventZoomChoreo.timeScale) //-eventZoomSlow stretches playback
        wash.frame = overlay.bounds
        wash.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wash.backgroundColor = .white
        wash.alpha = 0
        frost.frame = overlay.bounds
        frost.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        frost.isUserInteractionEnabled = false
        overlay.addSubview(wash)
        overlay.addSubview(frost)
    }
}

//Motion: every animation here is committed to the render server and the call returns — UIKit springs, additive, so a
//re-aim blends into the flight; the material's lift alone is a cubic, and `settle` commits nothing: it ends what is
//left in one unanimated step
extension ViewEventFlightStage {

    //The card's pose on its landing: the model values every spring below is heading for. Each rider's frame is written
    //here too, inside the same block, so it rides the same spring as the edge it is pinned to
    private func pose(on aim: ViewEventFlightAim) {
        plate.frame = aim.card
        plate.backgroundColor = UIColor(Color.appCanvas)
        clip.frame = aim.card
        let local = aim.photo.offsetBy(dx: -aim.card.minX, dy: -aim.card.minY)
        photo.frame = local
        chrome?.center = CGPoint(x: local.width / 2, y: local.height / 2)
        dots.frame = CGRect(x: 0, y: local.height - Self.dotsBand, width: local.width, height: Self.dotsBand)
        rim.frame = aim.card
        rows?.frame.origin = CGPoint(x: rowsRest.minX - (aim.card.minX - rest.minX), y: rowsRest.minY - (aim.card.minY - rest.minY))
        rows?.alpha = 0 //On the spring itself: they go at the pace the photo's foot crosses them
    }

    func fly() {
        let motion = ViewEventFlightMotion.self
        UIView.animate(springDuration: motion.spring.duration, bounce: motion.spring.bounce) { self.pose(on: self.aim) }
        UIView.animate(springDuration: motion.chromeFade, bounce: 0) { self.chrome?.alpha = 0 }
        UIView.animate(springDuration: motion.arrival, bounce: 0, delay: motion.arrivalDelay) {
            self.dots.alpha = 1
            self.rim.alpha = 1
        }
        UIView.animate(springDuration: motion.buttonPop, bounce: 0) {
            for button in self.buttons {
                button.transform = CGAffineTransform(scaleX: PopMotion.opacityShrunkScale, y: PopMotion.opacityShrunkScale)
                button.alpha = 0
            }
        }
    }

    //The event rests elsewhere than it was aimed at: UIKit adds the correction to the spring in flight
    func retarget(_ pad: ViewEventFlightAim) {
        let aim = pad.pixelAligned(overlay.window?.screen.scale ?? 3)
        self.aim = aim
        UIView.animate(springDuration: ViewEventFlightMotion.reaim.duration, bounce: ViewEventFlightMotion.reaim.bounce) {
            self.pose(on: aim)
        }
    }

    //On the glass within a pixel of where it is going: the card's layers as the render server is drawing them
    var isSettled: Bool {
        [plate, photo].allSatisfy { view in
            guard let shown = view.layer.presentation()?.frame else { return true }
            return ViewEventFlightAim.same(shown, view.layer.frame, ViewEventFlightMotion.restTolerance)
        }
    }

    //The last fraction of a point, taken in one step under the landing's dissolve
    func settle(on pad: ViewEventFlightAim) {
        let aim = pad.pixelAligned(overlay.window?.screen.scale ?? 3)
        self.aim = aim
        UIView.performWithoutAnimation { pose(on: aim) }
        for view in [plate, clip, photo, dots, rim] + [chrome, rows].compactMap({ $0 }) { view.layer.removeAllAnimations() }
    }

    //The material clears as a blur pulling focus — the event sharpens in behind the flying card — which UIKit runs on
    //the backdrop's own filters in the render server. Eased OUT only, so the screen starts to come in with the lift's
    //first frame — an ease-in held it back a tenth of a second, which read as the screen arriving late. Its first three
    //frames still sit under a 20pt blur, over whatever Events is still settling (a page turned a frame late)
    //The copy's body clears on the same clock: the event's own card — its ground, its shadow, its timer strip — stands
    //exactly under it by then, so the foot of the card sharpens in with the screen and only the photo is left to land
    func liftFrost() {
        UIView.animate(withDuration: ViewEventFlightMotion.frostLift, delay: ViewEventFlightMotion.frostBeat, options: [.curveEaseOut]) {
            self.frost.effect = nil
            self.wash.alpha = 0
            self.plate.alpha = 0
        }
    }

    func dissolve(_ done: @escaping @MainActor () -> Void) {
        overlay.isUserInteractionEnabled = false //The event is the screen's from here: the copy only has to go
        UIView.animate(springDuration: ViewEventFlightMotion.handOff, bounce: 0) {
            self.card.alpha = 0
        } completion: { _ in done() }
    }

    //An abort's exit, and the curtain's: whatever is up fades off the event
    func fadeAway(_ done: @escaping @MainActor () -> Void) {
        UIView.animate(springDuration: ViewEventFlightMotion.curtainFade, bounce: 0) {
            self.card.alpha = 0
            self.curtain?.alpha = 0
            self.wash.alpha = 0
            self.frost.effect = nil
        } completion: { _ in done() }
    }
}

//Pictures of the popup
extension ViewEventFlightStage {

    //The render server's pixels for `rect` of the window as it stands: no re-render, so the type, the glass and the
    //material under them are exact, and the cost is a couple of milliseconds
    private static func picture(of rect: CGRect, in window: UIWindow) -> UIView? {
        guard rect.width > 1, rect.height > 1, rect.width.isFinite, rect.height.isFinite, window.bounds.intersects(rect),
              let picture = window.resizableSnapshotView(from: rect, afterScreenUpdates: false, withCapInsets: .zero) else { return nil }
        picture.frame = rect
        picture.isUserInteractionEnabled = false
        return picture
    }

    //Where EventDismissButton drew its two buttons
    private static func buttonRects(for departure: EventZoomDeparture, in window: UIWindow) -> [CGRect] {
        let height = EventDismissButton.height
        let inset = EventDismissButton.edgeInset
        var rects = [CGRect(x: window.bounds.width - inset - height, y: departure.chevronSlotY, width: height, height: height)]
        if let title = departure.leadingTitle {
            let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .body(16, .medium)) //`Font.body` follows Dynamic Type
            let text = ceil((title as NSString).size(withAttributes: [.font: font]).width)
            rects.append(CGRect(x: inset, y: departure.chevronSlotY, width: text + 2 * EventDismissButton.labelPadding, height: height))
        }
        return rects
    }

    //A button's picture: the lens with the whole of its shadow, as much of it as the window holds, feathered off into the
    //material around it and hung by the lens' own centre — so it pops about that, however lopsided the room around it
    private static func picture(ofButton lens: CGRect, in window: UIWindow) -> UIView? {
        let room = lens.inset(by: UIEdgeInsets(top: -buttonRoom.side, left: -buttonRoom.side, bottom: -buttonRoom.below, right: -buttonRoom.side))
            .intersection(window.bounds)
        guard let picture = picture(of: room, in: window) else { return nil }
        let local = lens.offsetBy(dx: -room.minX, dy: -room.minY)
        //Shadow only: a filled mask steps from 0.4 to 1 at its own edge (sim-measured); a shadow alone ramps smoothly
        //through a half at the path, and is whole two radii inside it
        let mask = CALayer()
        mask.frame = picture.bounds
        let reach = local.insetBy(dx: -featherReach, dy: -featherReach)
        mask.shadowPath = UIBezierPath(roundedRect: reach, cornerRadius: reach.height / 2).cgPath
        mask.shadowColor = UIColor.black.cgColor
        mask.shadowOpacity = 1
        mask.shadowRadius = featherRadius
        mask.shadowOffset = .zero
        picture.layer.mask = mask
        picture.layer.anchorPoint = CGPoint(x: local.midX / room.width, y: local.midY / room.height)
        picture.frame = room //Again: moving the anchor moved the frame
        return picture
    }
}

fileprivate extension CGRect {

    //On whole device pixels, as SwiftUI places what it draws: a picture taken off the grid is resampled
    func pixelAligned(_ scale: CGFloat) -> CGRect {
        let minX = (self.minX * scale).rounded() / scale
        let minY = (self.minY * scale).rounded() / scale
        let maxX = (self.maxX * scale).rounded() / scale
        let maxY = (self.maxY * scale).rounded() / scale
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
