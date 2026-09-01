//
//  PendingFlightChoreo.swift
//  Scoop
//
//  Created by Art Ostin on 31/08/2026.
//

import SwiftUI

//The pending card's entire flight — the choreography SelectedPendingEvent renders but never
//drives. The tapped lens hides and the card, laid out at rest, is revealed through an
//expanding window that grows out of the lens' circle, while the photo morphs from the lens
//into the pager's band above it: the invite popup's arrival. Close is the reverse (backdrop
//tap, Hide, or the card's swipe-down), the window wiping the card away as it shrinks home
//onto the lens — and a FLICKED close flies the shared wind trajectory (WindFlightPlan), the
//profile dismissal's exact physics, landing on the circle with its emergent bounce while the
//backdrop fades on the pace clock. The card reads only the surface in the first extension;
//every clock, gesture, and per-frame pose lives below it.
@MainActor @Observable final class PendingFlightChoreo {

    //Injected
    private let source: CGRect //The tapped lens' circle in global space — the flight's home
    private let glassRing: CGFloat //The lens' glass tier — the close regrows the ring at this width
    private let onClosing: () -> Void //A committed close is leaving: the owner hides the ledger's static ring
    private let onChromeReturn: () -> Void //A beat into the close: the screen's own chrome comes back, while the card is still flying
    private let onClosed: () -> Void //The close flight has landed; the owner clears state and pulses

    //Flight state
    private var flightP: CGFloat = 0 //0 = at the lens, 1 = the full card
    private var chromeP: Double = 0 //Backdrop and Hide — the pieces outside the card
    private var coverShown = true //The morphing photo: fades once landed, back instantly at close
    private var landed = false
    private var closing = false
    private var hasOpened = false
    private var dragOffset: CGSize = .zero //Raw finger travel, BOTH axes; the card rides it rubber-banded (the profile dismiss's follow)
    private var chromeMix: CGFloat = 0 //The close's fold gate — snapped to 1 at close start; the fold's motion derives from the flight's p
    private var windRender = WindRender() //The wind close's per-frame pose: trajectory offset + settle-pop, written raw each tick
    private var blurredCover: UIImage? = nil //The cover with the pager's glur baked in — the foot rides the flight as pixels, no shader
    private var cardRect: CGRect = .zero //The card's frame, global — the flight's far end
    private var destRect: CGRect = .zero //The pager's frame, global — the photo's landing band
    private var restingCard: CGRect = .zero //The card's frame at REST — the stationary chevron's slot, held clear of the drag and of the flight home
    private var chevronIn = false //The Hide chevron's late arrival: armed a quarter into the open, so it pops only once the flight reads committed
    private var fingerDown = false //The finger owns the card. Ownership, not motion: the chevron leaves as the drag begins and returns the instant a cancelled release lets go, riding back on screen with the snap-back

    private let windDriver = WindCloseDriver() //The wind close's clock — the trajectory is time-domain, not a spring target

    init(source: CGRect, glassRing: CGFloat,
         onClosing: @escaping () -> Void,
         onChromeReturn: @escaping () -> Void,
         onClosed: @escaping () -> Void) {
        self.source = source
        self.glassRing = glassRing
        self.onClosing = onClosing
        self.onChromeReturn = onChromeReturn
        self.onClosed = onClosed
    }
}

//The card's read surface — everything SelectedPendingEvent needs, and nothing that moves it
extension PendingFlightChoreo {

    //Landed and at rest: the live pager mounts here and the Hide chevron arrives
    var settled: Bool { landed && !closing }

    //An engaged dismiss drag freezes the pager's own axis
    var dragEngaged: Bool { dragOffset != .zero }

    //The Hide chevron: in a quarter into the open, gone at close start and for as long as the
    //finger owns the card
    var chevronVisible: Bool { chevronIn && !closing && !fingerDown }

    //Its stationary home, global — the resting card's foot plus the column's own gap. The
    //chevron never rides the drag or the flight, so the slot has to come from the card at REST:
    //the live frame carries the pose, and the button would fly with it
    var chevronSlotY: CGFloat { restingCard.maxY + Spacing.xl }

    //The slot is only real once the card has been laid out
    var hasChevronSlot: Bool { restingCard.height > 1 }

    //The invite card's backdrop gives way as the drag commits
    var backdropOpacity: Double { chromeP * (1 - 0.5 * dragProgress) }

    //Both axes follow the finger (the profile/wind dismiss's model): vertical scrubs the fold
    //and commits; horizontal just tracks, banded harder — same constants as the invite
    //popup's ghostModel, both ported from DragTuning
    var cardOffset: CGSize {
        CGSize(width: DragTuning.rubberBand(dragOffset.width, limit: 160, response: 0.8),
               height: rubberBanded(dragOffset.height))
    }

    //Worn after the morph's mask, so the shadow wears the window's shape — and strength rides
    //the flight: the resting lens casts nothing, so the committed source frames must not
    //bloom a shadow. Clamped: the springs' overshoot carries flightP past both ends of [0, 1]
    var shadowStrength: Double { min(max(Double(flightP), 0), 1) }

    //The measured rects report live, drag folded in; the first pair past layout opens
    func reportCard(_ rect: CGRect) {
        cardRect = rect
        //The chevron's slot takes the RESTING pose only: the live frame folds the drag in, and
        //a committed close keeps that frozen drag for the whole flight home
        if !dragEngaged, !closing { restingCard = rect }
        openWhenMeasured()
    }

    func reportPagerBand(_ rect: CGRect) {
        destRect = rect
        openWhenMeasured()
    }

    //The morph, fed this frame's pose — the card supplies only its pixels and title
    func morph(photo: UIImage, title: String) -> PendingFlightMorph {
        PendingFlightMorph(
            p: flightP,
            chromeMix: chromeMix,
            dragTravel: dragOffset.height,
            flightOffset: windRender.offset,
            pop: windRender.pop,
            source: source,
            glassRing: glassRing,
            card: cardRect,
            pager: destRect,
            photo: photo,
            blurredPhoto: blurredCover,
            title: title,
            coverShown: coverShown)
    }

    //An unmount mid-flight must not leave the link ticking
    func unmounted() { windDriver.stop() }
}

//The flight clocks and choreography. All geometry lives in PendingFlightMorph below — an
//Animatable modifier, so the window and the photo re-derive from the interpolated progress
//EVERY FRAME: radii genuinely ride the current size instead of sliding between endpoints.
extension PendingFlightChoreo {

    #if DEBUG
    //Geometry-capture runs: -pendingFlightSlow stretches every clock 4× for the camera
    static let timeScale: Double = ProcessInfo.processInfo.arguments.contains("-pendingFlightSlow") ? 4 : 1
    #else
    static let timeScale: Double = 1
    #endif

    //The quick invite popup's open clock (still referenced so a retune there carries over),
    //taken a touch quicker and springier for this smaller flight; chrome trails it a breath
    private static let openDuration = (SendInviteContainer.openSpring.duration - 0.02) * timeScale
    private static let openFlight = Animation.spring(
        duration: openDuration,
        bounce: SendInviteContainer.openSpring.bounce + 0.05)
    private static let openChrome = Animation.spring(
        duration: SendInviteContainer.openSpring.duration * timeScale,
        bounce: SendInviteContainer.openSpring.bounce + 0.05)
    //0.32 FLAT read a tad too snappy on device (2026-08-31) and was taken back out to 0.36; it
    //returns quicker with the landing's bounce restored instead. 0.15 (damping .85) overshoots
    //~0.6% of the flight, and p is the whole lens→pager range, so that is ~2pt of inward pulse
    //on the 52pt lens: the cover settles onto the slot rather than stopping dead on it.
    private static let closeFlight = Animation.spring(duration: 0.32 * timeScale, bounce: 0.15)

    private static let closeChrome = Animation.smooth(duration: 0.25 * timeScale)

    private var hasFlight: Bool { source.width > 1 && !UIAccessibility.isReduceMotionEnabled }

    private func openWhenMeasured() {
        guard !hasOpened, cardRect.height > 50, destRect.height > 50 else { return }
        hasOpened = true

        guard hasFlight else { //No anchor, or reduce motion: arrive by fade, already in place
            flightP = 1
            landed = true
            chevronIn = true //Nothing flew, so there is no committed beat to wait out
            withAnimation(.transition) { chromeP = 1 }
            handOffCover()
            return
        }
        Task { @MainActor [self] in
            try? await Task.sleep(for: .milliseconds(30)) //One committed frame at the source before the flight leaves it
            withAnimation(Self.openFlight) { flightP = 1 } completion: { self.land() }
            withAnimation(Self.openChrome) { chromeP = 1 }
            scheduleChevronIn()
        }
    }

    //The chevron arms a quarter into the open, on the flight's own clock — the invite popup's
    //tuned share, referenced so a retune there carries over. Popping from frame 1 reads
    //premature (it zooms in before the open feels committed); waiting for the landing leaves it
    //still popping after the card has settled. openDuration carries timeScale, so a slow-motion
    //capture stretches the arm with everything else.
    private func scheduleChevronIn() {
        Task { @MainActor [self] in
            try? await Task.sleep(for: .seconds(Self.openDuration * SendInviteContainer.chevronInShare))
            guard !closing else { return } //A close mid-open keeps it away
            chevronIn = true
        }
    }

    //The screen's own chrome returns a BEAT into the close, never on onClosed: that completion
    //rides the flight spring's `.removed`, which fires at the settling tail — device capture
    //2026-08-31 measured the close starting at 0.28s, ALL motion stopping at 0.90s, and the
    //xmark only beginning to pop at 1.40s: half a second of a frozen screen waiting on a spring
    //nobody can see. onClosed cannot move (the cover→lens swap has to outwait that sub-pixel
    //settle), so the chrome gets its own clock. The beat is one chevron exit long: the chevron's
    //`.transition` pop-out and the backdrop's closeChrome fade both finish at 0.25s, so by 0.30s
    //the corner is empty and the frost has lifted — the xmark starts into clear space, never
    //cross-fading with the chevron 35pt away, and is home just before the card lands.
    private static let chromeBackBeat = Duration.milliseconds(300 * timeScale)

    private func scheduleChromeReturn() {
        Task { @MainActor [self] in
            try? await Task.sleep(for: Self.chromeBackBeat)
            onChromeReturn()
        }
    }

    //The rows were already revealed by the window mid-flight, and the blur foot and
    //"Invited …" faded in riding the flight (the morph's arrive ramp); the landing beat only
    //swaps the cover for the live pager over matched pixels
    private func land() {
        guard !landed, !closing else { return }
        landed = true //The pager mounts here, under the still-opaque cover
        chevronIn = true //Normally already in on its own clock — a landing must never sit chevron-less
        handOffCover()
    }

    //A short beat after the mount (clear of the spring's last sub-pixel settle), then a HARD
    //CUT to the live pager — the close's own hand-off, run forward. Never a fade here: a
    //fully covered pager defers its first real paint, so a crossfade surfaces its glur
    //warm-up mid-fade as the foot and title dipping out and back (sim-traced 2026-08-30);
    //the cut lands on the pager's first correct frame, and the baked foot matches it
    //closely enough that the swap reads as nothing at all.
    private static let handOffBeat = Duration.milliseconds(100 * timeScale)

    private func handOffCover() {
        Task { @MainActor [self] in
            try? await Task.sleep(for: Self.handOffBeat)
            guard !closing else { return } //A close begun during the beat owns the cover now
            if blurredCover != nil { //Matched pixels — cut
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { coverShown = false }
            } else { //The bake lost the race: the cover is raw, so ease it away instead —
                     //the foot then arrives late but once, never dipping out and back
                withAnimation(.transition) { coverShown = false }
            }
        }
    }

    func close(velocity: CGFloat = 0, sideVelocity: CGFloat = 0) {
        guard !closing else { return }
        closing = true
        scheduleChromeReturn()

        guard hasFlight else {
            withAnimation(.dismiss) { chromeP = 0 } completion: { self.onClosed() }
            return
        }
        onClosing() //The ledger's static ring hides in this same turn, behind the still-full backdrop — the flight's expanding glass owns the slot from here to the landed commit

        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) { coverShown = true } //Back over the pager on its own pixels before anything moves

        //One clock, the invite popup's lesson: chromeMix is only the GATE — the fold's
        //progress derives from the flight's own p inside the morph, so the white rows
        //provably wipe up into the image over the collapse's first stretch before the
        //pure photo flies home. A second racing clock on the shared animatable pair read
        //as the whole card shrinking in one piece.
        withTransaction(instant) { chromeMix = 1 }

        //The profile dismiss's split, verbatim: the wind is flick language; a slow let-go
        //(backdrop tap, Hide, a drag simply released past the line) keeps the calm morph.
        if velocity >= DragTuning.arcSlowMorphCeil {
            closeWithWind(velocity: velocity, sideVelocity: sideVelocity)
        } else {
            withAnimation(Self.closeFlight, completionCriteria: .removed) {
                flightP = 0
            } completion: { self.onClosed() }
            withAnimation(Self.closeChrome) { chromeP = 0 }
        }
    }

    //The wind close — the SAME WindFlightPlan the profile zoom's dismissal flies, so the two
    //cannot drift: the honest ride down the flick, the gust home, the character brake whose
    //bounce emerges from the arrival energy, the settle-pop, the sub-pixel commit. The plan
    //owns the vertical; x is the profile's Hermite; the morph renders both as a deviation
    //from its straight lerp path, with size and fold on the geometry clock (done by
    //arrival) and the backdrop fading on the atmosphere clock.
    private func closeWithWind(velocity: CGFloat, sideVelocity: CGFloat) {
        //Release geometry, all global — the measured rects report live, drag folded in.
        //The anchor is the COVER's centre against the lens': the cover is the one object
        //that flies, and the lens circle is its slot.
        let lensCenter = CGPoint(x: source.midX, y: source.midY)
        let u0 = destRect.midY - lensCenter.y
        //This card's own band slope at the release depth, then the shared follow — the
        //same crush-release the profile applies through its own band.
        let slope: CGFloat = dragOffset.height <= 0 ? 0.2
            : (dragOffset.height < 150 ? 1 : 0.55)
        let v0 = velocity * DragTuning.lerp(slope, 1, DragTuning.windFingerFollow)
        let uCap = UIScreen.main.bounds.height - DragTuning.windDiveVisibleBand
            - max(lensCenter.y, 0)
        //durationScale 1, never timeScale: scaling the solve changes the PHYSICS (depth is
        //v·t/2), so a 4× capture would fly a different trajectory — the slow-motion arg
        //slows the CLOCK below instead, replaying the true flight at rate.
        let plan = WindFlightPlan.solve(
            u0: u0, v0: v0, fingerVy: velocity, uCap: uCap,
            aboveScreenExtra: DragTuning.aboveScreenTime(destinationTop: source.minY),
            durationScale: 1)
        let x0 = destRect.midX
        let xT = lensCenter.x
        let vx0 = min(max(sideVelocity * DragTuning.rubberBandSlope(
            dragOffset.width, limit: 160, response: 0.8), -900), 900)
        let dest = destRect //Frozen at release; source is a let and cannot drift under the flight

        windDriver.run { [self] raw in
            let elapsed = raw / Self.timeScale //-pendingFlightSlow stretches playback, not physics
            let (u, du) = plan.state(at: elapsed)
            var instant = Transaction()
            instant.disablesAnimations = true
            if plan.shouldLand(elapsed: elapsed, u: u, du: du) {
                windDriver.stop()
                withTransaction(instant) {
                    flightP = 0
                    chromeP = 0
                    windRender = WindRender()
                }
                onClosed()
                return
            }
            //Size and fold on the geometry clock (complete by arrival, so the bounce
            //plays at final size); the cover's centre on the trajectory; backdrop on
            //the atmosphere clock — the profile's clock split, verbatim.
            let geoRaw = CGFloat(min(max(elapsed / plan.tGeo, 0), 1))
            let p = 1 - DragTuning.smoothstep(geoRaw)
            let t2 = geoRaw * geoRaw, t3 = t2 * geoRaw
            let x = (2 * t3 - 3 * t2 + 1) * x0
                + (t3 - 2 * t2 + geoRaw) * vx0 * CGFloat(plan.tGeo)
                + (-2 * t3 + 3 * t2) * xT
            let lerpCenter = CGPoint(
                x: DragTuning.lerp(source.midX, dest.midX, p),
                y: DragTuning.lerp(source.midY, dest.midY, p))
            let pace = CGFloat(min(max(elapsed / plan.tPace, 0), 1))
            withTransaction(instant) {
                flightP = p
                chromeP = 1 - pace
                windRender = WindRender(
                    offset: CGSize(width: x - lerpCenter.x,
                                   height: lensCenter.y + u - lerpCenter.y),
                    pop: plan.settlePop(u: u, at: elapsed))
            }
        }
    }
}

//The invite card's dismissal drag: vertical, rubber-banded, flick-projected — commit flies
//home from wherever the finger left the card, release short of the line snaps back with the
//invite card's overshoot
extension PendingFlightChoreo {

    private var dragProgress: Double {
        min(max(rubberBanded(dragOffset.height) / 300, 0), 1)
    }

    private func rubberBanded(_ dy: CGFloat) -> CGFloat {
        if dy <= 0 { return dy * 0.2 } //Upward: the card resists — there is nothing above
        let linear = min(dy, 150)
        return linear + max(dy - 150, 0) * 0.55
    }

    var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { [self] value in
                guard landed, !closing else { return }
                //First movement picks the owner: verticals engage the dismiss, horizontals
                //belong to the pager — the invite popup's axis split. Once owned, BOTH axes track
                if dragOffset == .zero, abs(value.translation.height) <= abs(value.translation.width) { return }
                fingerDown = true //The chevron leaves on ownership, before the card has travelled far
                dragOffset = CGSize(width: value.translation.width, height: value.translation.height)
            }
            .onEnded { [self] value in
                fingerDown = false //A released finger owns nothing: a cancelled release pops the chevron back with the snap-back spring, and a committed close keeps it away through `closing`
                guard landed, !closing, dragOffset != .zero else {
                    //A committed flight measured its geometry with the frozen drag folded
                    //into the live rects — zeroing it mid-flight shifts those rects under
                    //the captured trajectory and the card jumps by the drag × p
                    if !closing { dragOffset = .zero }
                    return
                }

                let flick = value.predictedEndTranslation.height - value.translation.height
                if rubberBanded(dragOffset.height) > 90 || flick > 90 {
                    close(velocity: max(value.velocity.height, 0), sideVelocity: value.velocity.width)
                } else {
                    //The invite card's snap-back: an overshooting spring fed the release speed
                    let speed = min(max(-value.velocity.height, 0) / max(abs(rubberBanded(dragOffset.height)), 1), 8)
                    withAnimation(.interpolatingSpring(Spring(duration: 0.3, bounce: 0.2), initialVelocity: speed)) {
                        dragOffset = .zero
                    }
                }
            }
    }
}

//The cover bake — the pager's glur baked into the cover's pixels off-main
extension PendingFlightChoreo {

    //InviteBandBake's pattern: a live glur on the flying cover would compile its shader at
    //tap and snap the spring, the very hitch the deferred pager mount exists to avoid.
    func bakeCoverBand(photo: UIImage) async {
        guard photo.size.width > 0, photo.size.height > 0 else { return }
        let aspect = AspectRatio.pendingEvent.ratio
        let width = UIScreen.main.bounds.width - Spacing.gutter * 2
        let scale = UIScreen.main.scale
        let baked = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            //Bake at the band's display resolution, not the photo's: the aspect is preserved,
            //so the layer's scaledToFill framing matches the raw cover at every window shape,
            //while the CI blur and the first texture upload shrink to band size — a cold bake
            //beats the arrive ramp instead of racing it (full-res bakes land mid-flight:
            //InviteBandBake's device evidence)
            let pxSize = CGSize(width: photo.size.width * photo.scale, height: photo.size.height * photo.scale)
            let cropWidth = min(pxSize.width, pxSize.height * aspect)
            let factor = min(width * scale / cropWidth, 1)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let target = CGSize(width: pxSize.width * factor, height: pxSize.height * factor)
            let sized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
                photo.draw(in: CGRect(origin: .zero, size: target))
            }
            return InvitePagePhoto.bakedBottomBlur(for: sized, aspect: aspect, displayWidth: width, scale: scale)
        }.value
        //A bake that still lands mid-ramp fades to its arrive opacity instead of stepping
        //there in one frame; one that loses outright degrades to the old land reveal
        withAnimation(.transition) { blurredCover = baked }
    }
}

//The wind close's per-frame pose, one value so each tick commits one write.
private struct WindRender: Equatable {
    var offset: CGSize = .zero //The trajectory's deviation from the straight lerp path
    var pop: CGFloat = 1       //The landing settle-pop (WindFlightPlan.settlePop)
}

//The per-frame clock for the wind close: SwiftUI has no display link of its own, and the
//shared WindFlightPlan is a time-domain trajectory, not a spring target the system can run.
private final class WindCloseDriver {
    private var link: CADisplayLink?
    private var start: CFTimeInterval = 0
    private var onTick: ((TimeInterval) -> Void)?

    func run(_ tick: @escaping (TimeInterval) -> Void) {
        stop()
        onTick = tick
        start = CACurrentMediaTime()
        let l = CADisplayLink(target: self, selector: #selector(fire))
        //ProMotion: without an explicit range the link schedules at 60Hz on 120Hz panels
        l.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
        l.add(to: .main, forMode: .common)
        link = l
    }

    @objc private func fire(_ l: CADisplayLink) {
        onTick?(l.timestamp - start)
    }

    func stop() {
        link?.invalidate()
        link = nil
        onTick = nil
    }
}

//The morph itself. Animatable, so this body re-derives per frame from the interpolated
//progress: the reveal window's radius is a true circle at the lens and only relaxes into the
//card's corners as it grows, and the photo band's crop morphs continuously — neither ever
//snaps between endpoints. The card content it masks never re-lays-out: the window and the
//photo are the only things moving, so nothing expensive rides the animation.
struct PendingFlightMorph: ViewModifier, Animatable {

    var p: CGFloat
    let chromeMix: CGFloat //The close's fold GATE (snaps 0 → 1, never animates): the fold's progress derives from p
    var dragTravel: CGFloat //The dismiss drag's raw descent — scrubs the fold 1:1 with the finger, and animates home with the snap-back spring
    let flightOffset: CGSize //The wind close's deviation from the straight lerp path — written raw per tick, zero for the open and the calm close
    let pop: CGFloat //The wind landing's settle-pop (WindFlightPlan.settlePop), about the cover's centre
    let source: CGRect //The lens circle, global
    let glassRing: CGFloat //The lens' glass tier — the close's landing pad grows to source + this ring
    let card: CGRect //The card's resting frame, global (drag included — it reports live)
    let pager: CGRect //The pager band, global
    let photo: UIImage
    let blurredPhoto: UIImage? //The photo with its glur foot baked in — crossfaded over the raw pixels as the flight runs
    let title: String //"Invited …" — rides the cover so it arrives with the content, not after it
    let coverShown: Bool

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(p, dragTravel) }
        set {
            p = newValue.first
            dragTravel = newValue.second
        }
    }

    func body(content: Content) -> some View {
        //Everything in the card's own space: the same math serves rest, flight, and a
        //mid-drag hand-off, because the card's live origin folds the drag in
        let sourceLocal = card.width > 1
            ? source.offsetBy(dx: -card.minX, dy: -card.minY)
            : CGRect(origin: .zero, size: source.size)
        let bounds = CGRect(origin: .zero, size: card.size)
        let pagerLocal = pager.offsetBy(dx: -card.minX, dy: -card.minY)

        //The wind trajectory's deviation from the straight lerp path — the ride down the
        //flick, the gust home, the landing bounce past the lens — injected per tick by the
        //shared WindFlightPlan; zero through the open and the calm close, so those paths
        //are untouched.
        let bellyY = flightOffset.height
        let bellyX = flightOffset.width

        //max(…, 0): radii must never follow a degenerate size into the negatives
        let cover = lerp(sourceLocal, pagerLocal, p).offsetBy(dx: bellyX, dy: bellyY)
        let coverCircle = max(min(cover.width, cover.height) / 2, 0)

        //The fold: the window collapses onto the photo alone — the white rows wiped up into
        //the image. Two drivers, composed by max so the hand-off between them is seamless:
        //the dismiss DRAG scrubs it 1:1 with raw descent (the invite popup's own
        //collapseDistance — linear, because the finger is direct manipulation) and reverses
        //with the snap-back; the committed CLOSE derives it from the flight's own p (done by
        //p = 0.6, chromeMix gating it to the close) — never its own racing clock, so the
        //rows provably lead the flight home and a mid-fold release never jumps.
        let dragFold = min(max(dragTravel / InviteDragTuning.collapseDistance, 0), 1)
        let fold = max(chromeMix * smoothstep((1 - p) / 0.4), dragFold)
        let window = lerp(lerp(sourceLocal, bounds, p).offsetBy(dx: bellyX, dy: bellyY), cover, fold)
        let windowRadius = max(lerp(min(window.width, window.height) / 2, CornerRadius.image, p), 0)

        //The landing pad: only a committed close shows it (chromeMix gates — the open and the
        //drag scrub never do). Anchored on the lens slot, it blooms out from under the
        //arriving cover over the collapse's back half, and over the final approach its centre
        //glues to the cover's — so the wind landing's bounce (position AND the settle-pop,
        //which scales this whole stack) carries the glass with the image. The ledger's own
        //ring is hidden for exactly this stretch (HistoryUIState.lensReturning) and takes
        //back a pixel-identical full-size ring at the landed commit.
        let padGrow = chromeMix * smoothstep((1 - p - 0.55) / 0.4)
        let padAttach = smoothstep((1 - p - 0.88) / 0.12)
        let padSize = CGSize(width: (sourceLocal.width + 2 * glassRing) * padGrow,
                             height: (sourceLocal.height + 2 * glassRing) * padGrow)
        let padCenter = CGPoint(x: lerp(sourceLocal.midX, cover.midX, padAttach),
                                y: lerp(sourceLocal.midY, cover.midY, padAttach))
        //The landing shadow, faded in riding the same collapse (the lens' own lightShadow
        //spec, so the landed photo's shadow arrives over already-identical pixels instead of
        //stepping in at the commit)
        let shadowIn = chromeMix * smoothstep((1 - p - 0.3) / 0.5)

        content
            .mask {
                RoundedRectangle(cornerRadius: windowRadius, style: .continuous)
                    .frame(width: max(window.width, 1), height: max(window.height, 1))
                    .position(x: window.midX, y: window.midY)
            }
            .overlay {
                if padGrow > 0 {
                    Color.clear
                        .frame(width: max(padSize.width, 1), height: max(padSize.height, 1))
                        .containerGlassEffect(clipped: true, shape: Circle()) //Clipped: the ledger ring's own no-shadow floor, matched
                        .position(padCenter)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                if coverShown {
                    //The foot and title fade in riding the flight, not after it: this body
                    //re-derives per frame, so their opacity genuinely tracks the growing
                    //window — full just before touchdown, where the land's reveal then
                    //crossfades over already-identical pixels. The lens end stays the raw
                    //photo the resting lens shows, so takeoff matches its pixels too.
                    let arrive = smoothstep((p - 0.25) / 0.7)
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: max(cover.width, 1), height: max(cover.height, 1))
                        .overlay {
                            if let blurredPhoto { //Same pixels but the foot — the crossfade IS the blur arriving
                                Image(uiImage: blurredPhoto)
                                    .resizable()
                                    .scaledToFill()
                                    .opacity(arrive)
                            }
                        }
                        .overlay(alignment: .bottomLeading) { coverTitle(width: pager.width).opacity(arrive) }
                        //Circle at the lens → the pager's band: top corners to the card's, the
                        //bottom pair flattening where the rows begin
                        .clipShape(UnevenRoundedRectangle(
                            topLeadingRadius: lerp(coverCircle, CornerRadius.image, p),
                            bottomLeadingRadius: lerp(coverCircle, 0, p),
                            bottomTrailingRadius: lerp(coverCircle, 0, p),
                            topTrailingRadius: lerp(coverCircle, CornerRadius.image, p)))
                        .lightShadow(strength: shadowIn) //The landed lens' shadow, arriving with the flight instead of at the commit
                        .position(x: cover.midX, y: cover.midY)
                        .allowsHitTesting(false)
                }
            }
            //Window and cover breathe together about the cover's centre — scaling the cover
            //alone would let the masked card's white peek out around the compressed circle.
            //Render-only, so the measured cardRect never feeds back into the flight's frames
            .scaleEffect(pop, anchor: UnitPoint(
                x: bounds.width > 0 ? cover.midX / bounds.width : 0.5,
                y: bounds.height > 0 ? cover.midY / bounds.height : 0.5))
    }

    //The pager's own title, cloned modifier-for-modifier and laid out at the band's FINAL
    //width from the first frame: a long name ellipsizes exactly where the landed line will,
    //so the land crossfade meets identical pixels even at the tail, and the mid-flight
    //window never re-truncates — the cover's clip owns what the smaller window can't show yet
    private func coverTitle(width: CGFloat) -> some View {
        Text(title)
            .font(.title(22))
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .padding(.horizontal, 20) //Geometry: the landed title's inset from the artwork edge — the crossfade needs the exact spot
            .padding(.bottom, Spacing.sm)
            .frame(width: max(width, 1), alignment: .leading)
    }

    //Soft at both ends, so the fade has no visible start or stop frame
    private func smoothstep(_ t: CGFloat) -> CGFloat {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    private func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
        CGRect(x: lerp(a.minX, b.minX, t),
               y: lerp(a.minY, b.minY, t),
               width: lerp(a.width, b.width, t),
               height: lerp(a.height, b.height, t))
    }
}
