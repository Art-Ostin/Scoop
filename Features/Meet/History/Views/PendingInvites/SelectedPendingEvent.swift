//
//  SelectedPendingEvent.swift
//  Scoop
//
//  Created by Art Ostin on 29/08/2026.
//

import SwiftUI

//The detail card a ledger lens opens. The tapped lens hides and the card — content and all,
//laid out at rest — is revealed through an expanding window that grows out of the lens'
//circle, while the photo morphs from the lens into the pager's band above it: the invite
//popup's arrival. Close is the reverse (backdrop tap, Hide, or the invite card's swipe-down),
//the window wiping the card away as it shrinks home onto the lens.
struct SelectedPendingEvent: View {

    //Injected
    let eventProfile: EventProfile
    let images: [UIImage]
    let sourceRect: CGRect //The tapped lens' circle in global space — the flight's home
    let onClosed: () -> Void //The close flight has landed; the owner clears state and pulses

    let rowHeight: CGFloat = 33

    //Local view state
    @State private var prepared: [UIImage] = [] //Pre-decoded copies — a raw UIImage's first draw decodes on main
    @State private var blurredCover: UIImage? = nil //The cover with the pager's glur baked in — the foot rides the flight as pixels, no shader
    @State private var scrollProgress: Double = 0
    @State private var flightP: CGFloat = 0 //0 = at the lens, 1 = the full card
    @State private var chromeP: Double = 0 //Backdrop and Hide — the pieces outside the card
    @State private var coverShown = true //The morphing photo: fades once landed, back instantly at close
    @State private var landed = false
    @State private var closing = false
    @State private var hasOpened = false
    @State private var dragOffset: CGSize = .zero //Raw finger travel, BOTH axes; the card rides it rubber-banded (the profile dismiss's follow)
    @State private var chromeMix: CGFloat = 0 //The close's fold gate — snapped to 1 at close start; the fold's motion derives from the flight's p
    @State private var landingScale: CGFloat = 1 //The close's landing breath — compress into touchdown, rebound past rest, settle
    @State private var closeDive: CGFloat = 0 //How far the close's path bellies downward — fed by the release velocity
    @State private var closeDrift: CGFloat = 0 //The belly's sideways component — signed with the flick's horizontal direction, wind-style
    @State private var cardRect: CGRect = .zero //The card's frame, global — the flight's far end
    @State private var destRect: CGRect = .zero //The pager's frame, global — the photo's landing band

    var body: some View {
        ZStack {
            inviteBackdrop
                .opacity(chromeP * (1 - 0.5 * dragProgress)) //The invite card's backdrop gives way as the drag commits

            VStack(spacing: Spacing.xl) {
                selectedEvent

                backButton
            }
            //Both axes follow the finger (the profile/wind dismiss's model): vertical scrubs
            //the fold and commits; horizontal just tracks, banded harder — same constants as
            //the invite popup's ghostModel, both ported from DragTuning
            .offset(x: DragTuning.rubberBand(dragOffset.width, limit: 160, response: 0.8),
                    y: rubberBanded(dragOffset.height))
            .simultaneousGesture(dismissDrag) //As the invite popup attaches its own — the pager still sees horizontals
        }
        .task { await prepareImages() } //Decodes ride the flight off-main, so the land never hitches
        .task { await bakeCoverBand() } //Its own task: the foot must not queue behind every page's decode
        .onChange(of: cardRect) { _, _ in openWhenMeasured() }
        .onChange(of: destRect) { _, _ in openWhenMeasured() }
    }
}

//The flight clocks and choreography. All geometry lives in PendingFlightMorph below — an
//Animatable modifier, so the window and the photo re-derive from the interpolated progress
//EVERY FRAME: radii genuinely ride the current size instead of sliding between endpoints.
extension SelectedPendingEvent {

    #if DEBUG
    //Geometry-capture runs: -pendingFlightSlow stretches every clock 4× for the camera
    static let timeScale: Double = ProcessInfo.processInfo.arguments.contains("-pendingFlightSlow") ? 4 : 1
    #else
    static let timeScale: Double = 1
    #endif

    //The quick invite popup's open clock (still referenced so a retune there carries over),
    //taken a touch quicker and springier for this smaller flight; chrome trails it a breath
    private static let openFlight = Animation.spring(
        duration: (SendInviteContainer.openSpring.duration - 0.02) * timeScale,
        bounce: SendInviteContainer.openSpring.bounce + 0.05)
    private static let openChrome = Animation.spring(
        duration: SendInviteContainer.openSpring.duration * timeScale,
        bounce: SendInviteContainer.openSpring.bounce + 0.05)
    private static let closeFlight = Animation.spring(duration: 0.36 * timeScale, bounce: 0.03) //0.32 read a tad too snappy on device (2026-08-31)

    //The landing beat (it replaced the lenses' accent-ring pulse): a scale breath about the
    //circle's own centre — compress through the final approach, rebound past resting size,
    //settle onto it. NEVER via bounce on the flight spring itself: extrapolating the morph's
    //rect-lerps past p = 0 re-aims the cover's PATH, not just its size — the circle shoots
    //beyond the lens and swings back as a second ghost circle (sim-traced 2026-08-30).
    private static let landingDip: CGFloat = 0.86 //Compression at touchdown — a notch into the vacated ring, part of the arrival, never a pose it holds
    private static let landingRebound = Animation.spring(duration: 0.32 * timeScale, bounce: 0.55) //A small pop past rest and a short settle — the landing must read as ONE motion
    private static let closeChrome = Animation.smooth(duration: 0.25 * timeScale)

    private var hasFlight: Bool { sourceRect.width > 1 && !UIAccessibility.isReduceMotionEnabled }

    private func openWhenMeasured() {
        guard !hasOpened, cardRect.height > 50, destRect.height > 50 else { return }
        hasOpened = true

        guard hasFlight else { //No anchor, or reduce motion: arrive by fade, already in place
            flightP = 1
            landed = true
            withAnimation(.transition) { chromeP = 1 }
            handOffCover()
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(30)) //One committed frame at the source before the flight leaves it
            withAnimation(Self.openFlight) { flightP = 1 } completion: { land() }
            withAnimation(Self.openChrome) { chromeP = 1 }
        }
    }

    //The rows were already revealed by the window mid-flight, and the blur foot and
    //"Invited …" faded in riding the flight (the morph's arrive ramp); the landing beat only
    //swaps the cover for the live pager over matched pixels
    private func land() {
        guard !landed, !closing else { return }
        landed = true //The pager mounts here, under the still-opaque cover
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
        Task { @MainActor in
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

    private func close(velocity: CGFloat = 0, sideVelocity: CGFloat = 0) {
        guard !closing else { return }
        closing = true

        guard hasFlight else {
            withAnimation(.dismiss) { chromeP = 0 } completion: { onClosed() }
            return
        }
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) { coverShown = true } //Back over the pager on its own pixels before anything moves

        //One clock, the invite popup's lesson: chromeMix is only the GATE — the fold's
        //progress derives from the flight's own p inside the morph, so the white rows
        //provably wipe up into the image over the collapse's first stretch before the
        //pure photo flies home. A second racing clock on the shared animatable pair read
        //as the whole card shrinking in one piece.
        withTransaction(instant) { chromeMix = 1 }

        //The path, not the clock, carries the flick: closeDive bellies the trajectory
        //downward in the release's direction before it curves for home — one continuous
        //arc, never a straight line reversed
        closeDive = velocity > 0 ? min(60 + velocity / 6, 220) : 0 //Steepened 2026-08-31: a fast swipe should visibly carry the card further down before it curves home
        closeDrift = velocity > 0 ? max(min(sideVelocity / 6, 180), -180) : 0 //Signed: the path bends toward the flick, the wind dismiss's read

        //A harder flick earns MORE time, not less: the carry deepens with velocity, and the
        //longer carry-and-return arc must stay legible (device feel, 2026-08-31)
        let flick01 = min(max((velocity - 300) / 1700, 0), 1)
        let duration = (velocity > 0 ? 0.5 + 0.15 * flick01 : 0.36) * Self.timeScale
        let flight: Animation = velocity > 0
            ? .spring(duration: duration, bounce: 0.06)
            : Self.closeFlight

        withAnimation(flight) { flightP = 0 }
        withAnimation(Self.closeChrome) { chromeP = 0 }
        landOnLens(flightDuration: duration)
    }

    //The landing, fused with the arrival — one continuous motion, never two beats (a held
    //dip read as arrive-wait-pop on device, 2026-08-31): the circle compresses through the
    //flight's last stretch and the rebound RETARGETS it exactly at the dip's bottom — both
    //animations issued in one commit, the second delayed to the seam, so additive
    //retargeting blends them into a single squash-and-settle. The owner's swap rides the
    //REBOUND's .removed (not the flight's): cover → lens on near-identical pixels, waited
    //out to the spring's last sub-pixel settle.
    private func landOnLens(flightDuration: Double) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(flightDuration * 0.8))
            let dipTime = flightDuration * 0.2
            withAnimation(.smooth(duration: dipTime)) { landingScale = Self.landingDip }
            withAnimation(Self.landingRebound.delay(dipTime), completionCriteria: .removed) {
                landingScale = 1
            } completion: { onClosed() }
        }
    }
}

//The invite card's dismissal drag: vertical, rubber-banded, flick-projected — commit flies
//home from wherever the finger left the card, release short of the line snaps back with the
//invite card's overshoot
extension SelectedPendingEvent {

    private var dragProgress: Double {
        min(max(rubberBanded(dragOffset.height) / 300, 0), 1)
    }

    private func rubberBanded(_ dy: CGFloat) -> CGFloat {
        if dy <= 0 { return dy * 0.2 } //Upward: the card resists — there is nothing above
        let linear = min(dy, 150)
        return linear + max(dy - 150, 0) * 0.55
    }

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard landed, !closing else { return }
                //First movement picks the owner: verticals engage the dismiss, horizontals
                //belong to the pager — the invite popup's axis split. Once owned, BOTH axes track
                if dragOffset == .zero, abs(value.translation.height) <= abs(value.translation.width) { return }
                dragOffset = CGSize(width: value.translation.width, height: value.translation.height)
            }
            .onEnded { value in
                guard landed, !closing, dragOffset != .zero else { dragOffset = .zero; return }

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

extension SelectedPendingEvent {

    //Title over the art, details under it — the invite card at rest, laid out full-size from
    //frame 1. The morph's window masks it (a full-bleed rounded rect once open, so the mask
    //IS the card's clip), and the morphing photo rides above until it fades at land.
    private var selectedEvent: some View {
        VStack(spacing: 0) {
            imagePager

            detailRows
        }
        .background(Color.white)
        .modifier(PendingFlightMorph(
            p: flightP,
            chromeMix: chromeMix,
            landingScale: landingScale,
            dragTravel: dragOffset.height,
            dive: closeDive,
            drift: closeDrift,
            source: sourceRect,
            card: cardRect,
            pager: destRect,
            photo: coverPhoto,
            blurredPhoto: blurredCover,
            title: inviteTitle,
            coverShown: coverShown))
        //After the mask, so it wears the window's shape — and strength rides the flight: the
        //resting lens casts nothing, so the committed source frames must not bloom a shadow.
        //Clamped: the springs' overshoot carries flightP past both ends of [0, 1]
        .shadow(.card, strength: min(max(Double(flightP), 0), 1))
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cardRect = $0 }
        .padding(.horizontal, Spacing.gutter) //The card is a full-bleed surface, not a text column
    }

    //The shared carousel, wearing this card's shape — its blurred foot carries the title.
    //MOUNTED ONLY AT LAND, into a fixed slot: mounting the pager (glur shader, full-res
    //decodes) at tap blocks the main thread while the spring runs on wall time, and the
    //first rendered frame lands mid-flight — the snap. The cover owns the photo until the
    //pager is ready beneath it, and the slot keeps the layout and measurement stable.
    private var imagePager: some View {
        Color.clear
            .aspectRatio(AspectRatio.pendingEvent.ratio, contentMode: .fit)
            .overlay {
                if landed && !closing {
                    InviteCarousel(images: prepared.isEmpty ? images : prepared,
                                   ratio: AspectRatio.pendingEvent.ratio,
                                   blursBottom: true,
                                   scrollProgress: $scrollProgress)
                        .overlay(alignment: .bottomLeading) { profileName }
                        .scrollDisabled(dragOffset != .zero) //An engaged dismiss drag freezes the pager's own axis
                }
            }
            //The photo's landing band — measured before the flight leaves the lens
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { destRect = $0 }
    }

    //byPreparingForDisplay off-main while the flight runs — the land mounts warm bitmaps
    private func prepareImages() async {
        var ready: [UIImage] = []
        for image in images {
            ready.append(await image.byPreparingForDisplay() ?? image)
        }
        prepared = ready
    }

    private var coverPhoto: UIImage { eventProfile.image ?? images.first ?? UIImage() }

    private var inviteTitle: String { "Invited \(eventProfile.profile.name)" }

    //The pager's glur baked into the cover's pixels off-main (InviteBandBake's pattern) — a
    //live glur on the flying cover would compile its shader at tap and snap the spring, the
    //very hitch the deferred pager mount exists to avoid.
    private func bakeCoverBand() async {
        let photo = coverPhoto
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

    private var detailRows: some View {
        //Leading, not centred: the rules already span the card, so the rows must start
        //where they do — a hugging HStack in a full-width column otherwise floats to the middle
        VStack(alignment: .leading, spacing: 19) {
            typeRow
            rowRule
            timeRow
            rowRule
            placeRow
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, 20)
        .padding(.bottom, Spacing.lg)
    }

    private var profileName: some View {
        Text(inviteTitle)
            .font(.title(22)) //The invite card's title type — "Invite <name>" reads the same here
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .padding(.horizontal, 20) //Geometry: the invite card's own title inset from the artwork edge
            .padding(.bottom, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inviteBackdrop: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .background(Color.white.opacity(0.1))
            .ignoresSafeArea()
            .onTapGesture { close() }
    }

    private var typeRow: some View {
        HStack(spacing: iconGap) {
            Text(eventProfile.event.type.emoji)
                .font(.body(16, .bold))
                .detailIconColumn()

            Text(eventProfile.event.type.longTitle)
                .font(.body(16, .bold))
        }
        .frame(height: rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timeRow: some View {
        HStack(spacing: iconGap) {
            Image(.eventClockIcon)
                .detailIconColumn()

            Text(eventProfile.event.proposedTimes.formatMultipleInvitedDays())
                .font(.body(16, .bold))
        }
        .frame(height: rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    private var placeRow: some View {
        let location = eventProfile.event.location
        return HStack(spacing: iconGap) {
            Image(.eventMapIcon)
                .detailIconColumn()

            Text(location.name ?? "View Venue")
                .font(.body(16, .bold))
        }
        .frame(height: rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    //Starts where the words do, never under the art — derived from the column the icons
    //wear, so the two can't drift apart
    private var rowRule: some View {
        VeryLightDivider()
            .padding(.leading, textColumn)
    }

    //The invite popup's own dismiss chevron, arriving at land exactly as it does there
    private var backButton: some View {
        BottomBackButton(visible: landed && !closing) { close() }
    }
}

//The morph itself. Animatable, so this body re-derives per frame from the interpolated
//progress: the reveal window's radius is a true circle at the lens and only relaxes into the
//card's corners as it grows, and the photo band's crop morphs continuously — neither ever
//snaps between endpoints. The card content it masks never re-lays-out: the window and the
//photo are the only things moving, so nothing expensive rides the animation.
private struct PendingFlightMorph: ViewModifier, Animatable {

    var p: CGFloat
    let chromeMix: CGFloat //The close's fold GATE (snaps 0 → 1, never animates): the fold's progress derives from p
    var landingScale: CGFloat //The close's landing breath, applied about the cover's centre
    var dragTravel: CGFloat //The dismiss drag's raw descent — scrubs the fold 1:1 with the finger, and animates home with the snap-back spring
    let dive: CGFloat //The close path's downward belly — the flick's direction, carried by geometry
    let drift: CGFloat //The belly's sideways component — signed with the flick's horizontal velocity, same shape as the dive
    let source: CGRect //The lens circle, global
    let card: CGRect //The card's resting frame, global (drag included — it reports live)
    let pager: CGRect //The pager band, global
    let photo: UIImage
    let blurredPhoto: UIImage? //The photo with its glur foot baked in — crossfaded over the raw pixels as the flight runs
    let title: String //"Invited …" — rides the cover so it arrives with the content, not after it
    let coverShown: Bool

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(p, AnimatablePair(landingScale, dragTravel)) }
        set {
            p = newValue.first
            landingScale = newValue.second.first
            dragTravel = newValue.second.second
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

        //The flick's continuation: zero at both ends, peaking early on the way home, its
        //start tangent pointing down the release DIRECTION — both axes, so a sideways flick
        //bends the whole arc its way (the wind dismiss's read) — one smooth curve
        let bellyY = dive * 6.75 * p * p * (1 - p)
        let bellyX = drift * 6.75 * p * p * (1 - p)

        //max(…, 0): the close's landing overshoot extrapolates p below 0 — the dip under the
        //lens' size is the point — and the radii must not follow the size into the negatives
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

        content
            .mask {
                RoundedRectangle(cornerRadius: windowRadius, style: .continuous)
                    .frame(width: max(window.width, 1), height: max(window.height, 1))
                    .position(x: window.midX, y: window.midY)
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
                        .position(x: cover.midX, y: cover.midY)
                        .allowsHitTesting(false)
                }
            }
            //Window and cover breathe together about the cover's centre — scaling the cover
            //alone would let the masked card's white peek out around the compressed circle.
            //Render-only, so the measured cardRect never feeds back into the flight's frames
            .scaleEffect(landingScale, anchor: UnitPoint(
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

//Geometry: the type emoji's slot — the drawn glyphs centre inside it
private let iconColumn: CGFloat = 16

//Geometry: the icon column ↔ its words. Every row wears it and textColumn is built from
//it, so widening the gap can't leave the rules starting under the art
private let iconGap = Spacing.lg

//Geometry: where every row's text starts — the icon column plus the row's own gap
private let textColumn = iconColumn + iconGap

private extension View {
    func detailIconColumn() -> some View {
        frame(width: iconColumn)
    }
}
