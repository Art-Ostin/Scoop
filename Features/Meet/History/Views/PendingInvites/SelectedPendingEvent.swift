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
    @State private var scrollProgress: Double = 0
    @State private var flightP: CGFloat = 0 //0 = at the lens, 1 = the full card
    @State private var chromeP: Double = 0 //Backdrop and Hide — the pieces outside the card
    @State private var coverShown = true //The morphing photo: fades once landed, back instantly at close
    @State private var landed = false
    @State private var closing = false
    @State private var hasOpened = false
    @State private var dragOffset: CGFloat = 0 //Raw finger travel; the card rides it rubber-banded
    @State private var chromeMix: CGFloat = 0 //0 = the full card in the window, 1 = image only — raced to 1 at close, the invite popup's collapse
    @State private var closeDive: CGFloat = 0 //How far the close's path bellies downward — fed by the release velocity
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
            .offset(y: rubberBanded(dragOffset))
            .simultaneousGesture(dismissDrag) //As the invite popup attaches its own — the pager still sees horizontals
        }
        .task { await prepareImages() } //Decodes ride the flight off-main, so the land never hitches
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

    //The app's verified open clock (the invite popup's), and a slightly tighter return
    private static let openFlight = Animation.spring(duration: 0.4 * timeScale, bounce: 0.1)
    private static let openChrome = Animation.spring(duration: 0.42 * timeScale, bounce: 0.12)
    private static let closeFlight = Animation.spring(duration: 0.32 * timeScale, bounce: 0.03)
    private static let closeChrome = Animation.smooth(duration: 0.25 * timeScale)
    private static let reveal = Animation.smooth(duration: 0.25 * timeScale) //The cover's fade over its own pixels: blur foot and title arriving

    private var hasFlight: Bool { sourceRect.width > 1 && !UIAccessibility.isReduceMotionEnabled }

    private func openWhenMeasured() {
        guard !hasOpened, cardRect.height > 50, destRect.height > 50 else { return }
        hasOpened = true

        guard hasFlight else { //No anchor, or reduce motion: arrive by fade, already in place
            flightP = 1
            landed = true
            withAnimation(.transition) {
                chromeP = 1
                coverShown = false
            }
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(30)) //One committed frame at the source before the flight leaves it
            withAnimation(Self.openFlight) { flightP = 1 } completion: { land() }
            withAnimation(Self.openChrome) { chromeP = 1 }
        }
    }

    //The rows were already revealed by the window mid-flight; the landing beat is only the
    //photo cover fading over the pager's identical pixels — the blur foot and "Invited …"
    //arriving as one soft reveal
    private func land() {
        guard !landed, !closing else { return }
        landed = true
        withAnimation(Self.reveal) { coverShown = false }
    }

    private func close(velocity: CGFloat = 0) {
        guard !closing else { return }
        closing = true

        guard hasFlight else {
            withAnimation(.dismiss) { chromeP = 0 } completion: { onClosed() }
            return
        }
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) { coverShown = true } //Back over the pager on its own pixels before anything moves

        //The invite popup's two overlapped clocks, issued together so they compose:
        //the window races to image-only (the white rows wiped in a fast beat) while the
        //spring flies the pure photo home — mid-collapse it is only ever a shrinking image.
        withAnimation(.smooth(duration: 0.15 * Self.timeScale)) { chromeMix = 1 }

        //The path, not the clock, carries the flick: closeDive bellies the trajectory
        //downward in the release's direction before it curves for home — one continuous
        //arc, never a straight line reversed
        closeDive = velocity > 0 ? min(50 + velocity / 9, 180) : 0

        let flight: Animation = velocity > 0
            ? .spring(duration: 0.45 * Self.timeScale, bounce: 0.06)
            : Self.closeFlight

        //.removed, not .logicallyComplete: the owner swaps window → lens on identical pixels,
        //so the hand-off must wait out the spring's last sub-pixel settle
        withAnimation(flight, completionCriteria: .removed) { flightP = 0 } completion: { onClosed() }
        withAnimation(Self.closeChrome) { chromeP = 0 }
    }
}

//The invite card's dismissal drag: vertical, rubber-banded, flick-projected — commit flies
//home from wherever the finger left the card, release short of the line snaps back with the
//invite card's overshoot
extension SelectedPendingEvent {

    private var dragProgress: Double {
        min(max(rubberBanded(dragOffset) / 300, 0), 1)
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
                //belong to the pager — the invite popup's axis split
                if dragOffset == 0, abs(value.translation.height) <= abs(value.translation.width) { return }
                dragOffset = value.translation.height
            }
            .onEnded { value in
                guard landed, !closing, dragOffset != 0 else { dragOffset = 0; return }

                let flick = value.predictedEndTranslation.height - value.translation.height
                if rubberBanded(dragOffset) > 90 || flick > 90 {
                    close(velocity: max(value.velocity.height, 0))
                } else {
                    //The invite card's snap-back: an overshooting spring fed the release speed
                    let speed = min(max(-value.velocity.height, 0) / max(abs(rubberBanded(dragOffset)), 1), 8)
                    withAnimation(.interpolatingSpring(Spring(duration: 0.3, bounce: 0.2), initialVelocity: speed)) {
                        dragOffset = 0
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
            dive: closeDive,
            source: sourceRect,
            card: cardRect,
            pager: destRect,
            photo: eventProfile.image ?? images.first ?? UIImage(),
            coverShown: coverShown))
        //After the mask, so it wears the window's shape — and strength rides the flight: the
        //resting lens casts nothing, so the committed source frames must not bloom a shadow
        .shadow(.card, strength: Double(flightP))
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
                        .scrollDisabled(dragOffset != 0) //An engaged dismiss drag freezes the pager's own axis
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
        Text("Invited \(eventProfile.profile.name)")
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
    var chromeMix: CGFloat //0 = the window holds the whole card, 1 = the photo alone
    let dive: CGFloat //The close path's downward belly — the flick's direction, carried by geometry
    let source: CGRect //The lens circle, global
    let card: CGRect //The card's resting frame, global (drag included — it reports live)
    let pager: CGRect //The pager band, global
    let photo: UIImage
    let coverShown: Bool

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(p, chromeMix) }
        set {
            p = newValue.first
            chromeMix = newValue.second
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
        //start tangent pointing down the release direction — the arc is one smooth curve
        let bellyY = dive * 6.75 * p * p * (1 - p)

        let cover = lerp(sourceLocal, pagerLocal, p).offsetBy(dx: 0, dy: bellyY)
        let coverCircle = min(cover.width, cover.height) / 2

        //chromeMix folds the window down onto the photo alone — the rows wiped in the
        //popup's fast first beat, so mid-collapse only a shrinking image remains
        let window = lerp(lerp(sourceLocal, bounds, p).offsetBy(dx: 0, dy: bellyY), cover, chromeMix)
        let windowRadius = lerp(min(window.width, window.height) / 2, CornerRadius.image, p)

        content
            .mask {
                RoundedRectangle(cornerRadius: windowRadius, style: .continuous)
                    .frame(width: max(window.width, 1), height: max(window.height, 1))
                    .position(x: window.midX, y: window.midY)
            }
            .overlay {
                if coverShown {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: max(cover.width, 1), height: max(cover.height, 1))
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
