//
//  SendInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 27/07/2026.
//

import SwiftUI

struct SendInviteContainer: View {

    //Flight tuning — a geometry-matched hero flight keeps its measured curves in-file.
    //The close overlaps two clocks, like the profile dismiss: the mask races the chrome
    //down to image-only on `chromeRace` while the image flies home on `closeFlight`.
    static let openFlight = Animation.spring(Spring(duration: 0.4, bounce: 0.1)) //ProfileZoom's open clock (0.4s, dampingRatio 0.9): a gentle settle instead of smooth's front-loaded rush
    static let closeFlight = Animation.smooth(duration: 0.28)
    static let chromeRace = Animation.smooth(duration: 0.15)
    static let sourceChromeExit = Animation.smooth(duration: 0.12) //The meet-card chrome copy only needs to cover frame 1 — then it's out of the flight's way
    static let snapBackSpring = Spring(duration: 0.3, bounce: 0.3) //ProfileZoom's cancel clock, with enough bounce to read (SwiftUI springs damp far harder than UIKit's for the same ratio — Spring.value-probed)
    static let diveFlight = Spring(duration: 0.45, bounce: 0.4) //A committed drag: the carried velocity dives the card past the slot and the spring expands it back in (the profile's landing)
    static let settleFlight = Spring(duration: 0.4, bounce: 0.12) //Button close / slow release: a gentle settle onto the slot

    static let sourceRadius = CornerRadius.image //Source card image clip radius (collapsed state)
    static let cardRadius = CornerRadius.xl //Expanded card surface radius

    //Interactive dismiss tuning (see dismissDrag) — the numbers ProfileZoom's drag proved out
    static let collapseDistance: CGFloat = 300 //Vertical drag that scrubs the collapse 0→1
    static let dismissThreshold: CGFloat = 0.3 //Release past this progress (or a downward flick) dismisses
    static let minDragScale: CGFloat = 0.82 //Progressive shrink of the whole card at full collapse

    //Injected Properties
    let images: [UIImage]
    let name: String

    @Binding var showInvite: Bool

    @State var vm: TimeAndPlaceViewModel

    let onSendInvite: (EventFieldsDraft) -> ()
    let declineProfile: () -> ()

    //The flight's frozen source frame and chrome. Nil outside an .inviteZoom presentation —
    //the profile flow mounts this screen directly and keeps its instant open/close.
    @Environment(InviteZoomPresenter.self) private var zoom: InviteZoomPresenter?

    //Local Properties
    @State var ui = TimeAndPlaceUIState()

    //Same solve the Meet card wears: asked for by profile id, served from the shared cache
    @State private var palette: OverlayPalette = .placeholder

    //Flight state — continuous scalars so the drag scrub, the chrome race and the position
    //flight compose additively on the same geometry (a bool branch can't overlap clocks)
    @State private var closeP: CGFloat = 1 //1 = collapsed at the source image, 0 = landed card
    @State private var chromeRaceP: CGFloat = 0 //The close's fast mask collapse toward image-only
    @State private var expanded = false //The logical presented flag: chrome visibility + hit gates
    @State private var hasOpened = false
    @State private var landed = false //True once the open flight fully lands — a pure interactivity latch (paging, drag-grab)
    @State private var flightGeneration = 0 //Bumped on every close, so a land() scheduled for an earlier flight no-ops
    @State private var cardFrame: CGRect = .zero
    @State private var imageFrame: CGRect = .zero
    @State private var scrollProgress: Double = 0
    @State private var pagerPosition = ScrollPosition()
    @State private var coverPage: Int? //Close off the hero page: the visible page, frozen over the live pager
    @State private var coverFade: Double = 1 //The static hero cover: 1 through flights, faded out at rest
    @State private var blurCover: Double = 0 //The covers' glur layer: 1 only at close start (pager-identical), gone in 0.15s — shaders never fly
    @State private var sourceChromeFade: Double = 1 //Caps the chrome copy's opacity: rushed to 0 at open start, reset for the collapse
    @State private var flightTargets: (card: CGRect, image: CGRect)? //Destination frames frozen per flight: a mid-flight reflow must not retarget the animation

    //Drag Logic
    @State private var dragAxis: Axis?
    @State private var dragging = false
    @State private var springingBack = false
    @State private var dragOffset: CGSize = .zero
    @State private var dragProgress: CGFloat = 0

    private var sourceFrame: CGRect { zoom?.source ?? .zero }
    private var hasFlight: Bool { sourceFrame.width > 1 } //No measured source: open and close stay instant
    private var shown: Bool { expanded || !hasFlight } //A no-flight mount is presented from its first frame — its chrome must never animate in

    //The drag scrub and the close's mask race share the chrome-collapse axis. max, not a sum:
    //the commit unwinds dragProgress on the flight clock, and a sum would feed that decay back
    //into the mask as a 0.28s re-expansion delta fighting the race (sim-verified as form-row
    //bands surfacing under the flying image). With max, once the race pins the mix at 1 the
    //decaying drag only drives the scale unwind.
    private var chromeMix: CGFloat { max(dragProgress, chromeRaceP) }

    private var currentScreen: InviteScreen { ui.showConfirmScreen == true ? .sendConfirm : .send }
    private var currentImageAspect: AspectRatio {
        ui.showConfirmScreen == true ? .confirmInviteImage : .invitedImage
    }
    private var currentRadius: CGFloat { lerp(Self.cardRadius, Self.sourceRadius, closeP) }

    var body: some View {
        ZStack {
            backdrop
            flightCard
        }
        .animation(.transition, value: ui.showConfirmScreen)
        //A cache hit in practice: ProfileCard extracts the same key when the meet card loads,
        //so the tint is present from the flight's first frame instead of warming up late
        .task(id: vm.profileId) { await fetchColour() }
        .task(id: ui.activePopup) { await ui.syncDelayedPopups() } //Owned here: the delayed mirrors must track on every page, not just the one that hosts a menu

        .fullScreenCover(isPresented: $ui.showMapView) { MapView(defaults: vm.defaults, eventLocation: $vm.event.place) }
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
        .sheet(isPresented: $ui.showMessageScreen) {addMessageView}
    }
}

//The flight chassis: a glass surface, the real layout, and a frame-animated image layer, all
//cut by one mask. The mask's rect blends three anchors — card, image-only, source — driven by
//the chrome axis (drag scrub + close race) and the flight axis (closeP).
extension SendInviteContainer {

    private var backdrop: some View {
        InvitePopupBackground(tint: palette.secondaryText)
            //Pure function of the flight scalars: fades in over the open (closeP 1→0), scrubs
            //1:1 with the drag, and leads the collapse out on the fast chrome-race clock.
            //Clamped: the dive overshoots closeP past 1.
            .opacity(max(0, Double((1 - chromeMix) * (1 - closeP))))
            .animation(.transition, value: palette) //Extraction lands a frame late — the tint fades in rather than snaps
            //No hit-testing gate: the never-hidden tab bar sits beneath this root-plane overlay,
            //so input must stay blocked through the whole close flight — the layer unmounting at
            //completion restores the bar, reproducing the old .hideTabBar guarantee
    }

    private var flightCard: some View {
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            ZStack(alignment: .top) {
                cardSurface(origin)
                layoutColumn
                carouselLayer(origin)
                sourceChromeLayer(origin)
                flightTapCatcher(origin)
                reopenTapTarget(origin)
            }
            .scaleEffect(1 - (1 - Self.minDragScale) * dragProgress, anchor: dragAnchor(geo.size, origin))
            .offset(dragOffset)
            .simultaneousGesture(dismissDrag)
            .onChange(of: expanded) { _, isExpanded in expandedChanged(isExpanded) }
        }
    }

    //The card's surface and shadow, worn by the flying rect rather than the content. The FLIGHT
    //flies a plain appCanvas fill (the old animation's surface — a Liquid Glass lens rebuilt at
    //a new size every frame drops the device to ~15fps); the real glass crossfades in at
    //landing over the near-identical fill. The resting shadow crossfades to the source card's
    //image shadow along the flight.
    private func cardSurface(_ origin: CGPoint) -> some View {
        let rect = maskRect(origin)
        return ZStack {
            RoundedRectangle(cornerRadius: currentRadius)
                .fill(Color.appCanvas)
                .opacity(landed ? 0 : 1)
            Color.clear
                .containerGlassEffect(tint: Color.appCanvas, shape: RoundedRectangle(cornerRadius: currentRadius))
                .opacity(landed ? 1 : 0)
        }
        .animation(.transition, value: landed)
        .frame(width: rect.width, height: rect.height)
        .shadow(.softFloating, strength: Double(1 - closeP))
        .shadow(.image, strength: Double(closeP))
        .shadow(.image, strength: Double(closeP))
        .position(x: rect.midX, y: rect.midY)
        .allowsHitTesting(false)
    }

    //The real layout, centred exactly as the static screen was
    private var layoutColumn: some View {
        VStack(spacing: Spacing.xl) {
            cardColumn
            backButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    //The card content at its final layout; the expanding mask reveals it. The image layer is a
    //separate flight layer above — the imageSlot only reserves its place.
    private var cardColumn: some View {
        VStack(spacing: 0) { //Butted: the carousel's bottom fuzz and the rows' wash are the same
                             //colour, so any gap here shows the card's appCanvas glass as a white seam
            imageSlot
            inviteDetailsPager
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.sm)
        .contentShape(Rectangle()) //Whole card is a drag surface, including gaps between rows
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newFrame in
            guard !dragging else { return } //Frames are the drag's model space; frozen while it owns them
            withAnimation(landed ? .transition : nil) { cardFrame = newFrame }
            openWhenMeasured()
        }
        .opacity(cardFrame.height > 1 ? 1 : 0) //Hidden until measured (the cover, valid from frame 1, matches the source meanwhile)
        .mask { maskShape(cardFrame.origin) } //Revealed by the expanding shape
        .allowsHitTesting(expanded && !dragging)
        .padding(.horizontal, InviteCardBackground.horizontalInset)
        .padding(.top, InviteCardBackground.topInset)
    }

    private var imageSlot: some View {
        Color.clear
            .aspectRatio(currentImageAspect.ratio, contentMode: .fit)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newFrame in
                guard !dragging else { return }
                withAnimation(landed ? .transition : nil) { imageFrame = newFrame }
                openWhenMeasured()
            }
    }

    private func carouselLayer(_ origin: CGPoint) -> some View {
        let rect = local(lerp(carouselTargetFrame, sourceFrame, closeP), origin)

        return ZStack {
            flightCovers //Static stand-ins beneath the chrome: the live pager only exists at rest
            imageSection
        }
        .frame(width: rect.width, height: rect.height)
        .geometryGroup() //Children resolve geometry against the in-flight frame, not the destination
        .position(x: rect.midX, y: rect.midY)
        .mask { maskShape(origin) } //Same shape as the surface: cuts page bleed at the card edge, collapses to the source clip
        .allowsHitTesting(expanded && landed && !dragging)
    }

    //A copy of the source card's chrome riding the flying image: fades out over the open,
    //back in over the collapse, so the hidden source card reappears under identical chrome.
    //Laid out ONCE at source size and transform-scaled to the flying rect — its blur wash must
    //render at a fixed size, never re-layout per frame (the stretch hides under the fade).
    @ViewBuilder
    private func sourceChromeLayer(_ origin: CGPoint) -> some View {
        if hasFlight, let chrome = zoom?.slot?.sourceChrome {
            let rect = local(lerp(carouselTargetFrame, sourceFrame, closeP), origin)
            chrome()
                .frame(width: sourceFrame.width, height: sourceFrame.height)
                .clipShape(RoundedRectangle(cornerRadius: Self.sourceRadius))
                .scaleEffect(x: rect.width / max(sourceFrame.width, 1),
                             y: rect.height / max(sourceFrame.height, 1))
                .position(x: rect.midX, y: rect.midY)
                //Open: rushed out on its own 0.12s clock so it never muddies the growing card.
                //Close: the cap sits at 1, so it fades back in with the collapse (closeP).
                .opacity(min(Double(closeP), sourceChromeFade))
                .allowsHitTesting(false)
        }
    }

    private func flightTapCatcher(_ origin: CGPoint) -> some View {
        let rect = local(lerp(targetImageFrame, sourceFrame, closeP), origin)
        return Color.clear
            .contentShape(Rectangle())
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .onTapGesture { closeInvite() }
            .allowsHitTesting(expanded && !landed && !dragging)
    }

    private func reopenTapTarget(_ origin: CGPoint) -> some View {
        let rect = local(sourceFrame, origin)
        return Color.clear
            .frame(width: 56, height: 56)
            .contentShape(Rectangle())
            .onTapGesture { reopen() }
            .position(x: rect.maxX - 36, y: rect.maxY - 36) //Geometry: the 56pt square inset 8 from the corner, where the invite button sits
            .allowsHitTesting(!expanded && hasOpened)
    }

    //The flight's static image layers, pixel-identical to a resting carousel page so every swap
    //between them and the live pager is invisible. Always mounted — views inserted mid-flight
    //resolve at destination geometry. The hero cover carries the whole open flight and the
    //close; the page snapshot freezes a non-hero page so the pager can snap home unseen.
    //Shaders never fly: the base layers are SHARP images (a plain image resize is GPU-cheap; a
    //glur layerEffect at animated size drops frames). The glur variants exist only in `blurCover`
    //— 1 for the single frame the pager unmounts at close start, faded out over the chrome race.
    //The bottom blur "arrives" at landing through the pager under the sharp cover's fade-out.
    @ViewBuilder
    private var flightCovers: some View {
        if !images.isEmpty {
            let snapshotImage = images[min(coverPage ?? 0, images.count - 1)]
            ZStack {
                ZStack {
                    rawCover(snapshotImage)
                    InvitePagePhoto(image: snapshotImage, blursBottom: currentScreen.blursBottom)
                        .opacity(blurCover)
                }
                .opacity(coverPage != nil ? 1 : 0)
                ZStack {
                    rawCover(images[0])
                    InvitePagePhoto(image: images[0], blursBottom: currentScreen.blursBottom)
                        .opacity(blurCover)
                }
                .opacity(coverFade)
            }
            .allowsHitTesting(false)
        }
    }

    //A cover that FLIES carries no shader at all: glur smears while its layer resizes (even at
    //its near-zero resting radius), and the raw image is what the source card shows anyway.
    //At landing the opaque pager covers this layer, so page-fidelity is never needed here.
    private func rawCover(_ image: UIImage) -> some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
    }

    //A flight animates toward FROZEN copies of the measured frames — live measurements resume
    //at landing. A pager-height settle mid-flight must not retarget the animation (each
    //unanimated retarget reads as a jump).
    private var targetCardFrame: CGRect { flightTargets?.card ?? cardFrame }
    private var targetImageFrame: CGRect { flightTargets?.image ?? imageFrame }

    //The carousel's destination frame — height derived from the width and the current aspect,
    //so a confirm-screen swap retargets the flight before the slot finishes measuring
    private var carouselTargetFrame: CGRect {
        var target = targetImageFrame
        target.size.height = targetImageFrame.width / currentImageAspect.ratio
        return target
    }

    //Chrome axis first (card → image-only), flight axis second (→ source)
    private func maskRect(_ origin: CGPoint) -> CGRect {
        let chromeRect = lerp(targetCardFrame, targetImageFrame, chromeMix)
        return local(lerp(chromeRect, sourceFrame, closeP), origin)
    }

    private func maskShape(_ origin: CGPoint) -> some View {
        let rect = maskRect(origin)
        return RoundedRectangle(cornerRadius: currentRadius)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }

    private func local(_ rect: CGRect, _ origin: CGPoint) -> CGRect {
        rect.offsetBy(dx: -origin.x, dy: -origin.y)
    }
}

//Open/close state machine
extension SendInviteContainer {

    private func openWhenMeasured() {
        guard !hasOpened, imageFrame.height > 50, cardFrame.height > 50 else { return }
        hasOpened = true
        guard hasFlight else { //No source (profile flow): present complete on the first laid-out frame, as before
            expanded = true
            landed = true
            closeP = 0
            coverFade = 0
            return
        }
        flightTargets = (cardFrame, imageFrame) //Freeze the destination for this flight
        let generation = flightGeneration
        Task { @MainActor in //One committed frame at the source rect before the flight animates from it
            withAnimation(Self.sourceChromeExit) { sourceChromeFade = 0 }
            withAnimation(Self.openFlight, completionCriteria: .removed) {
                expanded = true
                closeP = 0
            } completion: {
                land(generation)
            }
        }
    }

    private func expandedChanged(_ isExpanded: Bool) {
        if isExpanded {
            dragging = false //A reopen mid-close revives the card; unfreeze frames and hand hits back
            springingBack = false
            coverFade = 1 //Cover the pager until this flight lands (identical pixels — instant is invisible)
            let generation = flightGeneration
            Task {
                try? await Task.sleep(for: .seconds(0.6)) //Redundant with the flight completion, in case it never fires
                land(generation)
            }
        } else {
            flightGeneration += 1
            landed = false
        }
    }

    private func land(_ generation: Int) {
        guard expanded, generation == flightGeneration else { return } //A newer close/reopen owns the flight now
        landed = true //Mounts the live pager beneath the covers
        flightTargets = nil //Live measurements own the geometry again
        blurCover = 0 //The pager carries the bottom blur from here
        if let coverPage, images.indices.contains(coverPage) { //A reopen mid-close: give the pager its page back…
            snapPager { $0.scrollTo(id: images[coverPage], anchor: .leading) }
        }
        coverPage = nil //…then drop the snapshot over identical pixels
        withAnimation(.transition) { coverFade = 0 }
    }

    private func closeInvite() {
        guard hasFlight else { //No source to collapse into (profile flow): unmount as before
            showInvite = false
            return
        }
        prepareClose()
        expanded = false //Chrome fades out on its own .transition scopes; hit gates drop
        withAnimation(Self.chromeRace) { chromeRaceP = 1 } //The mask races down to image-only…
        launchCloseFlight(launch: 0, dives: false)
    }

    //The image flies home a hop after the chrome race, so the two clocks compose additively.
    //`launch` is the release velocity normalised against the remaining travel (ProfileZoom's
    //clamp): the spring overshoots closeP past 1, which extrapolates the rect lerp beyond the
    //source slot — the card dives through and expands back into place.
    private func launchCloseFlight(launch: Double, dives: Bool) {
        Task { @MainActor in
            withAnimation(Self.chromeRace) { blurCover = 0 } //The glur layers leave before the collapse needs its frames
            let spring = dives ? Self.diveFlight : Self.settleFlight
            withAnimation(.interpolatingSpring(spring, initialVelocity: launch), completionCriteria: .removed) {
                closeP = 1
            } completion: {
                guard !expanded else { return } //A reopen mid-close owns the card now
                showInvite = false
            }
        }
    }

    private func reopen() {
        withAnimation(Self.sourceChromeExit) { sourceChromeFade = 0 }
        withAnimation(Self.openFlight) {
            expanded = true
            closeP = 0
            chromeRaceP = 0
        }
    }

    private func prepareClose() {
        flightTargets = (cardFrame, imageFrame) //Freeze the collapse's from-geometry
        sourceChromeFade = 1 //The cap steps aside: the chrome copy rides the collapse back in via closeP
        blurCover = 1 //The covers must match the glur'd pager on its unmount frame; the race fades the blur out
        guard scrollProgress > 0.001 else { //Resting on the hero page: the hero cover is identical pixels
            coverFade = 1
            return
        }
        coverPage = currentPage //Freeze the visible page over the live pager…
        snapPager { $0.scrollTo(edge: .leading) } //…so the pager is home before it unmounts
        withAnimation(Self.closeFlight) { coverFade = 1 } //…while the hero dissolves in, landing on the source's image
    }

    private var currentPage: Int {
        min(max(Int(scrollProgress.rounded()), 0), images.count - 1)
    }

    private func snapPager(_ move: (inout ScrollPosition) -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { move(&pagerPosition) }
    }
}

//Interactive dismiss — the drag scrub, thresholds and rubber-band feel shared with ProfileZoom
extension SendInviteContainer {

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if dragAxis == nil {
                    let vertical = abs(value.translation.height) >= abs(value.translation.width)
                    let canBegin = hasFlight && expanded && landed && !springingBack && !ui.isPopupOpen()
                    if vertical && canBegin { dragAxis = .vertical; beginDrag() }
                    else { dragAxis = .horizontal } //Voided: horizontal belongs to the pager
                }
                guard dragAxis == .vertical, dragging, expanded else { return }
                let t = value.translation
                dragProgress = min(max(t.height / Self.collapseDistance, 0), 1)
                dragOffset = CGSize(
                    width: rubberBand(t.width, limit: 160, response: 0.8),
                    height: t.height >= 0
                        ? rubberBand(t.height, limit: 700, response: 1)
                        : rubberBand(t.height, limit: 80, response: 0.9) //Upward fights back hard
                )
            }
            .onEnded { value in
                let owned = dragAxis == .vertical && dragging
                dragAxis = nil
                guard owned, expanded else { return }
                let flick = value.predictedEndTranslation.height - value.translation.height
                if dragProgress > Self.dismissThreshold || (value.translation.height > 20 && flick > 90) {
                    finishDismiss(velocity: value.velocity)
                } else {
                    cancelDrag(velocity: value.velocity)
                }
            }
    }

    private func beginDrag() {
        dragging = true
        snapPager { $0.scrollTo(id: images[currentPage], anchor: .leading) } //Kill an in-flight flick; frames are frozen from here
    }

    private func finishDismiss(velocity: CGSize) {
        prepareClose()
        expanded = false
        //Remaining travel to the slot, measured before the unwind resets the model offset
        let travel = max(sourceFrame.midY - (imageFrame.midY + dragOffset.height), 60)
        let launch = min(max(velocity.height, 0) / travel, 8) //Downward release velocity, normalised; upward floors to 0
        withAnimation(Self.chromeRace) { chromeRaceP = 1 } //The mask continues the collapse from the drag's pose (max pins it)…
        withAnimation(Self.closeFlight) { //…while scale and offset unwind over the flight, landing unscaled on the source
            dragProgress = 0
            dragOffset = .zero
        }
        launchCloseFlight(launch: launch, dives: velocity.height > 200)
    }

    private func cancelDrag(velocity: CGSize) {
        springingBack = true
        //An upward flick feeds the snap-back spring so it carries into the return like the
        //profile's; a downward release floors to 0. Velocity is normalised against the travel,
        //matching ProfileZoom's clamp(max(-v.y, 0) / |offset|, 0, 8).
        let travel = max(abs(dragOffset.height), 1)
        let launch = min(max(-velocity.height, 0) / travel, 8)
        withAnimation(.interpolatingSpring(Self.snapBackSpring, initialVelocity: launch), completionCriteria: .removed) {
            dragProgress = 0
            dragOffset = .zero
        } completion: {
            springingBack = false
            guard expanded else { return } //A close started mid-spring; leave state to that flight
            dragging = false
        }
    }

    //Asymptotic rubber band: tracks at ~response·d near zero, saturating at `limit`
    private func rubberBand(_ d: CGFloat, limit: CGFloat, response: CGFloat) -> CGFloat {
        guard d != 0 else { return 0 }
        let m = abs(d) * response
        return (1 - 1 / (m / limit + 1)) * limit * (d < 0 ? -1 : 1)
    }

    private func dragAnchor(_ size: CGSize, _ origin: CGPoint) -> UnitPoint {
        guard imageFrame.height > 1, size.width > 1, size.height > 1 else { return .center }
        return UnitPoint(x: (imageFrame.midX - origin.x) / size.width,
                         y: (imageFrame.midY - origin.y) / size.height)
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    private func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
        CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
               width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
    }
}

//Different Views and Components
extension SendInviteContainer {

    private var imageSection: some View {
        InviteImageCarousel(
            screen: currentScreen,
            name: name,
            images: images,
            inviteHasChanges: vm.event.hasChanges,
            isPopupOpen: ui.anyPopupOpenDelayed,
            showConfirmScreen: $ui.showConfirmScreen,
            showInfoScreen: $ui.showInfoScreen,
            fillsFrame: true, //The flight frames the carousel; self-sizing would fight the animated rect
            scrollProgress: $scrollProgress,
            pagerPosition: $pagerPosition,
            //One coordinated arrival at landing: title, dots, options and the title's halo fade
            //in together (a white title without its halo is invisible on a bright photo — fading
            //it mid-flight read as the halo "snapping" in later). No flight in a no-flight mount.
            chromeVisible: landed,
            showsPager: landed, //The heavy pager mounts only at rest, behind the pixel-identical covers
            declineProfile: declineProfile,
            clearInvite: {withAnimation(.dissolve) { vm.deleteEventDefault() } }
        )
        //Sits under the carousel's bottom mask fuzz, so the image dissolves into the same
        //colour the rows' gradient starts on instead of the card behind it. Only with the
        //pager: while the flight covers stand in beneath this (empty) view, the wash would
        //tint the flying image through it.
        .background {
            palette.secondaryText.opacity(0.45)
                .opacity(landed ? 1 : 0)
                .animation(.transition, value: landed)
        }
    }

    private var inviteDetailsPager: some View {
        VStack(spacing: 0) {
            TwoPageScrollView(
                showSecondScreen: $ui.showConfirmScreen,
                scrollProgress: .constant(0),
                reflowAnimation: vm.event.hasChanges ? .transition : .dissolve, //An emptied draft is a clear
                screen1: { timeAndPlacePage },
                screen2: { confirmationPage }
            )
            .modifier(InviteSeamWash(tint: palette.secondaryText))
            actionButton
        }
    }

    //Defaults left alone deliberately: every argument is part of the key the Meet card solved under,
    //so this is a cache hit rather than a second extraction
    private func fetchColour() async {
        guard let first = images.first else { return }

        palette = await PopupColorExtractor.shared
            .extractPalette(first, id: vm.profileId, prominence: .subtle)
    }

    //Gone until the flight lands its chrome, on the confirm screen, while dragging,
    //and while the time or type popup owns the card
    private var backButton: some View {
        let visible = shown && dragOffset == .zero && !(ui.showConfirmScreen ?? false) && !ui.isPopupOpen()

        return BottomBackButton(visible: visible) { closeInvite() }
            .animation(.transition, value: visible) //Scoped here: keying the ZStack on activePopup would retime the menu morphs
    }

    //Smooth impercetible hiding when popup open
    private var actionButton: some View {
        let isConfirming = ui.showConfirmScreen == true
        let buttonText = isConfirming ? "Send to \(name)" : "Invite \(name)"
        let popupDim = !isConfirming && ui.isPopupOpenDelayed()

        return WideActionButton(text: buttonText, isActive: vm.event.isComplete, isDimmed: popupDim, showShadow: false) {
            if isConfirming {
                onSendInvite(vm.event)
            } else {
                ui.showConfirmScreen = true
            }
        }
        .opacity(popupDim ? 0.4 : 1)
        .allowsHitTesting(!popupDim)
        .animation(.transition, value: popupDim)
        .padding(.horizontal, Spacing.margin) //Each page owns the gap above this button
    }

    private var timeAndPlacePage: some View {
        TimeAndPlacePage(ui: ui, draft: $vm.event, showMessageScreen: $ui.showMessageScreen)
    }

    @ViewBuilder
    private var confirmationPage: some View {
        if let inviteSummary = InviteSummary(draft: vm.event) {
            ConfirmContainer(
                event: inviteSummary,
                name: name,
                style: .popup,
                timeOpen: ui.delayedTimePopupOpen,
                showMessageSection: true,
                showMessageScreen: $ui.showMessageScreen) {
                    StaticTimeRow(proposedTimes: inviteSummary.time, style: ConfirmStyle.popup)
                } showInfo: {
                    ui.showInfoScreen = true
                }
        }
    }

    private var addMessageView: some View {
        AddMessageView(
            message: $vm.event.message,
            isRespondMessage: false,
            eventType: $vm.event.type
        )
    }
}

//MARK: InviteZoom — presents the invite popup on the root plane, growing out of a source image

@MainActor
@Observable
final class InviteZoomPresenter {

    struct Slot {
        let id: String
        let view: () -> AnyView
        let sourceChrome: () -> AnyView //A copy of the source card's chrome for the flight to fade
    }

    private(set) var slot: Slot?
    private(set) var source: CGRect = .zero //Frozen source frame of the flight in progress

    @ObservationIgnored private var sourceRects: [String: CGRect] = [:]

    func reportSource(id: String, rect: CGRect) { sourceRects[id] = rect }

    func present(id: String, sourceChrome: @escaping () -> AnyView, view: @escaping () -> AnyView) {
        if let current = slot, current.id != id { clear(id: current.id) } //Handoff: presenting over a closing card evicts it
        guard slot == nil else { return } //A same-id re-present (a remount's initial onChange) is a no-op
        source = sourceRects[id] ?? .zero //Freeze the tapped card's frame for this flight
        slot = Slot(id: id, view: view, sourceChrome: sourceChrome)
    }

    //Id-guarded so a stale clear can't drop a newer card
    func clear(id: String) {
        guard slot?.id == id else { return }
        slot = nil
        source = .zero
    }
}

//Mounted once in AppContainer, above the TabView: the popup's backdrop covers the never-hidden
//tab bar and fades it back in with the flight instead of a discrete toolbar flip
struct InviteZoomLayer: View {

    var presenter: InviteZoomPresenter

    var body: some View {
        if let slot = presenter.slot {
            slot.view()
                .id(slot.id)
                .ignoresSafeArea(.keyboard) //A sheet's keyboard must not shift the popup on its root plane
        }
    }
}

private struct InviteZoomModifier<SourceChrome: View, Popup: View>: ViewModifier {

    @Environment(InviteZoomPresenter.self) private var presenter: InviteZoomPresenter?

    let id: String
    @Binding var isPresented: Bool
    @ViewBuilder let sourceChrome: () -> SourceChrome
    @ViewBuilder let popup: () -> Popup

    //The flight IS the card while a slot is live: the source hides for the whole presented
    //lifetime (never a duplicate) and reappears in the same commit the collapsed overlay
    //unmounts over it — never a gap.
    private var isPresenting: Bool { presenter?.slot?.id == id }

    func body(content: Content) -> some View {
        content
            .opacity(isPresenting ? 0 : 1)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { rect in
                presenter?.reportSource(id: id, rect: rect)
            }
            .onChange(of: isPresented, initial: true) { _, presented in
                guard let presenter else { return }
                if presented {
                    presenter.present(id: id, sourceChrome: { AnyView(sourceChrome()) }) { AnyView(popup()) }
                } else {
                    presenter.clear(id: id)
                }
            }
            .onDisappear { presenter?.clear(id: id) }
    }
}

extension View {

    ///Grows the invite popup out of this image when `isPresented` flips true, and collapses it
    ///back on dismissal. The source view hides while the popup is presented — the flight is the
    ///card. `sourceChrome` is a copy of the card chrome drawn over the flying image: the flight
    ///fades it out over the open and back in over the collapse.
    func inviteZoom(
        id: String,
        isPresented: Binding<Bool>,
        @ViewBuilder sourceChrome: @escaping () -> some View,
        @ViewBuilder popup: @escaping () -> some View
    ) -> some View {
        modifier(InviteZoomModifier(id: id, isPresented: isPresented, sourceChrome: sourceChrome, popup: popup))
    }

    ///For a plain image source with no chrome to fade (the debug harness, a bare photo)
    func inviteZoom(
        id: String,
        isPresented: Binding<Bool>,
        @ViewBuilder popup: @escaping () -> some View
    ) -> some View {
        modifier(InviteZoomModifier(id: id, isPresented: isPresented, sourceChrome: { EmptyView() }, popup: popup))
    }
}
