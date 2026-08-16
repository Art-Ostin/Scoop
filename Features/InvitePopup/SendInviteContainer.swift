//
//  SendInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 27/07/2026.
//

import SwiftUI

struct SendInviteContainer: View {

    //Flight tuning — a geometry-matched hero flight keeps its measured curves in-file.
    //The close is ONE clock: mask and image collapse together on the flight spring
    //(launchCloseFlight). `chromeRace` remains only as the cover/blur fade clock.
    static let openSpring = Spring(duration: 0.34, bounce: 0.2) //ProfileZoom's open clock stretched ~12% (was 0.4s, 2026-08-10): a gentle settle instead of smooth's front-loaded rush
    static let openFlight = Animation.spring(openSpring)
    static let chevronInShare: Double = 0.25 //The close chevron arms a quarter into the open — popping from frame 1 read as premature (it zoomed in before the open felt committed), while waiting out 70% left it still popping after the card had settled
    static let closeFlight = Animation.smooth(duration: 0.28)
    static let chromeRace = Animation.smooth(duration: 0.15)
    static let sourceChromeExit = Animation.smooth(duration: 0.12) //The meet-card chrome copy only needs to cover frame 1 — then it's out of the flight's way
    static let settleFlight = Spring(duration: 0.4, bounce: 0.26) //TAP close only: arrives with a small visible pop past the slot (~3% overshoot; 0.12 from rest read dead-beat) — the closeP>1 extrapolation carries it

    //Gesture dismissal tuning lives in DragTuning (ProfileZoomTransition.swift) — the invite's
    //flick dismissal is the profile's, ported; both cards read the same constants and curves.

    static let sourceRadius = CornerRadius.image //Source card image clip radius (collapsed state)
    static let cardRadius = CornerRadius.xl //Expanded card surface radius

    //The flight shadow's two endpoints, lerped on closeP so no frame swaps shadows discretely.
    //Source end: the meet card's UIKit resting shadow (ZoomStyle.cardShadows' two stacked
    //pairs) folded into one pair — two stacked layers of opacity a composite to 1-(1-a)², so
    //2×0.05 → 0.0975 and 2×0.08 → 0.1536 at the pairs' shared radius/offset. Landed end: the
    //card's resting .softFloating (InviteCardBackground). The UIKit shadow's 8pt cast inset
    //(bottom-only pool) has no SwiftUI .shadow equivalent; the hand-off difference is a
    //slightly wider side pool, frame-diffed imperceptible.
    static let sourceShadow = (contact: Elevation.Layer(opacity: 0.0975, radius: 4, y: 3),
                               ambient: Elevation.Layer(opacity: 0.1536, radius: 16, y: 10))
    static let landedShadow = Elevation.softFloating.layers


    //Injected Properties
    let images: [UIImage]
    let name: String

    @Binding var showInvite: Bool

    @State var vm: TimeAndPlaceViewModel

    let onSendInvite: (EventFieldsDraft) -> ()
    let declineProfile: () -> ()

    //Explicit only to seed the band layer from the warm-bake cache SYNCHRONOUSLY: the band
    //must be at full depth on the committed source frame. A bake that instead lands mid-task
    //(cold cache) fades in over the source copy's exit — the fallback, not the design.
    init(images: [UIImage], name: String, showInvite: Binding<Bool>, vm: TimeAndPlaceViewModel,
         onSendInvite: @escaping (EventFieldsDraft) -> (), declineProfile: @escaping () -> ()) {
        self.images = images
        self.name = name
        self._showInvite = showInvite
        self._vm = State(initialValue: vm)
        self.onSendInvite = onSendInvite
        self.declineProfile = declineProfile
        //Views are constructed on the main actor; the cache is main-actor state
        if let hero = images.first,
           let warmed = MainActor.assumeIsolated({ InviteBandBake.cached(for: hero) }) {
            self._blurredHero = State(initialValue: warmed.band)
            self._bakedHero = State(initialValue: hero)
            if warmed.haloName == name {
                self._bakedHalo = State(initialValue: warmed.halo)
            }
        }
    }

    //The flight's frozen source frame and chrome. Nil outside an .inviteZoom presentation —
    //the profile flow mounts this screen directly and keeps its instant open/close.
    @Environment(InviteZoomPresenter.self) private var zoom: InviteZoomPresenter?

    //Local Properties
    @State var ui = TimeAndPlaceUIState()

    //Same solve the Meet card wears: asked for by profile id, served from the shared cache
    @State private var palette: OverlayPalette = .placeholder

    //The hero page's glur baked into pixels (InvitePagePhoto.bakedBottomBlur), so the bottom
    //blur can fade in DURING the open flight as a plain flying image — shaders never fly.
    //Its layer is ALWAYS mounted (rendering the sharp hero until this lands): the bake finishes
    //mid-flight, and a structural insertion there resolves at destination geometry.
    //`bakedHero` records which image the bake came from: when the seed image swaps for the
    //loaded set mid-presentation, the stale bake must drop out instead of riding at full
    //opacity over the new photo (a whole-image mismatch for the rebake's few frames).
    @State private var blurredHero: UIImage?
    @State private var bakedHero: UIImage?

    //The title's halo as baked pixels (BackgroundBlur.bakedHalo, bottom strip only): the live
    //BackgroundBlur is a 40pt shader that mounts with the pager at rest — this copy carries
    //the halo through the flight so the title's backdrop never changes after landing
    @State private var bakedHalo: UIImage?
    @Environment(\.displayScale) private var displayScale

    //Flight state — continuous scalars so the drag scrub, the chrome race and the position
    //flight compose additively on the same geometry (a bool branch can't overlap clocks)
    @State private var closeP: CGFloat = 1 //1 = collapsed at the source image, 0 = landed card
    @State private var chromeRaceP: CGFloat = 0 //The close's mask collapse toward image-only — rides the SAME spring as closeP (one-clock collapse), seeded to the drag's pose on a committed dismiss
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
    @State private var pagerReveal: Double = 0 //The live pager's landing crossfade: faded in over the HELD covers, so the pages' bottom blur arrives smoothly
    @State private var coversDropped = false //Paging latch: a swipe over a held cover double-exposes two photos, so the pager stays inert until the covers are gone
    @State private var blurCover: Double = 0 //The snapshot cover's glur: 1 only at close start (pager-identical), gone in 0.15s — shaders never fly. The hero cover needs none: its baked band layer is already pager-identical
    @State private var sourceChromeFade: Double = 1 //Caps the chrome copy's opacity: rushed to 0 at open start, reset for the collapse
    @State private var chromeIn = false //Destination image chrome (title, options, dots): pops in from the flight's first frame, out at close start
    @State private var bandIn = true //The baked band belongs to the card from its FIRST committed frame (warm bake) — unlike the chrome it must not wait for the launch commit; it exits with the chrome at close start
    @State private var chevronIn = false //The close chevron's late arrival: armed at chevronInShare of the open spring, so it pops only once the open reads committed
    @State private var sourceChromeExiting = false //Drives the source copy's per-element exits (subtitle blur-pop, invite-icon pop) via the inviteChrome environment
    @State private var titleNameSlot: CGRect = .zero //The title name's flight-invariant offsets (leading inset / bottom inset / 22pt size) — the hero's destination derives from these + the frozen carousel target, never from a measured mid-flight position
    @State private var nameLanded = false //Hands the name from the hero text to the real title, a beat after land() so the spring's last sub-pixel settle can't jump the swap
    @State private var heroFadesWithCollapse = false //A close from the confirm screen has no visible title to leave from — the name rides in with the chrome copy instead
    @State private var flightTargets: (card: CGRect, image: CGRect)? //Destination frames frozen per flight: a mid-flight reflow must not retarget the animation

    //Drag Logic
    @State private var dragAxis: Axis?
    //Gesture-flight driver (the ported profile dismissal): the trajectory is evaluated per
    //frame on a display link and written into the SAME model the finger scrubs
    @State private var flightLink = GestureFlightLink()
    @State private var gestureFlight: GestureFlight?
    @State private var dragStart: CGSize = .zero //Slop zeroing: the rule sees translation − dragStart
    @State private var regrabProgress: CGFloat? //A caught cancel spring blends back onto the rule over 120pt
    @State private var regrabOffset: CGSize = .zero
    @State private var cropScrub: CGFloat = 0 //Gesture-close crop morph: 0 = invited aspect, 1 = SOURCE aspect — scrubbed on the dive/race so the ascent flies a rigid frame (the profile's setHeroCropScrub)
    @State private var dragging = false
    @State private var springingBack = false
    @State private var dragOffset: CGSize = .zero
    @State private var dragProgress: CGFloat = 0

    private var sourceFrame: CGRect { zoom?.source ?? .zero }
    private var hasFlight: Bool { sourceFrame.width > 1 } //No measured source: open and close stay instant
    private var shown: Bool { expanded || !hasFlight } //A no-flight mount is presented from its first frame — its chrome must never animate in
    //The hero owns the name through both flights; the real title takes over at rest. A flight
    //with no measured source name (the chrome-less inviteZoom overload — the debug harness)
    //degrades to the plain title: without this gate the ghost hides a name nothing replaces.
    private var nameHeroActive: Bool {
        hasFlight && (zoom?.sourceName.width ?? 0) > 1 && (!nameLanded || !expanded)
    }

    //The drag scrub and the close's mask race share the chrome-collapse axis. max, not a sum:
    //the commit unwinds dragProgress on the flight clock, and a sum would feed that decay back
    //into the mask as a 0.28s re-expansion delta fighting the race (sim-verified as form-row
    //bands surfacing under the flying image). With max, once the race pins the mix at 1 the
    //decaying drag only drives the scale unwind.
    //Clamped: chromeRaceP rides the bouncy close spring and overshoots 1 with it — the
    //card's BOUNCE lives in the rect's closeP>1 extrapolation, while the mask pins at
    //image-only instead of extrapolating past the image
    private var chromeMix: CGFloat { min(max(dragProgress, chromeRaceP), 1) }

    private var currentScreen: InviteScreen { ui.showConfirmScreen == true ? .sendConfirm : .send }
    private var currentImageAspect: AspectRatio {
        ui.showConfirmScreen == true ? .confirmInviteImage : .invitedImage
    }

    //The bake is usable only while it matches the current hero — a mid-presentation image
    //swap (seed → loaded set) makes it stale until the rebake lands
    private var bakeReady: Bool { blurredHero != nil && bakedHero == images.first }

    //A committed gesture dismissal in flight (never the tap close, never pre-open rest)
    private var gestureClosing: Bool { gestureFlight != nil && !expanded && hasOpened }

    //The baked band's single opacity scope: at full depth from the committed source frame
    //when the bake is warm (bandIn starts true — keyed on chromeIn it would fade in on the
    //launch commit and under-blur the bottom while the source copy exits), fading in mid-
    //flight only on the cold-cache fallback, out with the chrome at close start, and
    //crossfaded (not popped) when the confirm swap flips blursBottom.
    private var bandVisible: Bool {
        currentScreen.blursBottom && bandIn && bakeReady
    }
    private var currentRadius: CGFloat { lerp(Self.cardRadius, Self.sourceRadius, closeP) }

    var body: some View {
        ZStack {
            backdrop
            flightCard
        }
        .animation(.transition, value: ui.showConfirmScreen)
        //A true cache hit: ProfileCard warms THIS key (.subtle prominence — a different cache
        //entry from the card's own palette) when the meet card loads, so the tint family is
        //present from the flight's first frame instead of crossfading in at the end
        .task(id: vm.profileId) { await fetchColour() }
        .task(id: images.first) { await bakeHeroBlur() }
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
            //1:1 with the drag AND the gesture flights: the driver's chromeMix/closeP writes
            //ease this out with the mask's own collapse. (An earlier port of the profile's
            //scrim rule collapsed it on the spring's fast-decaying curve — this backdrop is a
            //full material hiding the whole meet screen, and it vanished almost instantly;
            //device frames, 2026-08-13.) Clamped: the dive overshoots closeP past 1.
            .opacity(max(0, Double((1 - chromeMix) * (1 - closeP))))
            .animation(.transition, value: palette) //Extraction lands a frame late — the tint fades in rather than snaps
            //No hit-testing gate: the never-hidden tab bar sits beneath this root-plane overlay,
            //and the material blocks it while visible. Once the fade reaches ~0 (a landed
            //close), input DOES pass through to the list and bar beneath (device recording,
            //2026-08-14) — which is why the close handback fires at .logicallyComplete: the
            //overlay must become the real list card the moment the spring perceptually rests.
    }

    private var flightCard: some View {
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            ZStack(alignment: .top) {
                cardSurface(origin)
                layoutColumn
                carouselLayer(origin)
                sourceChromeLayer(origin)
                nameFlightLayer(origin)
                flightTapCatcher(origin)
                reopenTapTarget(origin)
            }
            .scaleEffect(1 - (1 - DragTuning.minDragScale) * dragProgress, anchor: dragAnchor(geo.size, origin))
            .offset(dragOffset)
            //ABOVE the pose modifiers, deliberately: the chevron never rides the drag or the
            //flights — it only ever fades in place, holding the spot the frozen card frame
            //gives it while the card moves independently
            .overlay(alignment: .top) { stationaryBackButton(origin) }
            .simultaneousGesture(dismissDrag)
            .onChange(of: expanded) { _, isExpanded in expandedChanged(isExpanded) }
        }
    }

    //The card's surface and shadow, worn by the flying rect rather than the content. The FLIGHT
    //flies a plain appCanvas fill (the old animation's surface — a Liquid Glass lens rebuilt at
    //a new size every frame drops the device to ~15fps); the real glass crossfades in at
    //landing over the near-identical fill (the .animation scope covers only that fill swap —
    //the shadows below ride the flight transaction).
    private func cardSurface(_ origin: CGPoint) -> some View {
        let rect = maskRect(origin)
        let contact = flightShadowLayer(Self.landedShadow.contact, Self.sourceShadow.contact)
        let ambient = flightShadowLayer(Self.landedShadow.ambient, Self.sourceShadow.ambient)
        return ZStack {
            //PERMANENTLY opaque beneath the glass: a fill↔glass cross-dissolve dips the
            //stack's opacity mid-fade and the dimmed backdrop (and the shadow under the card)
            //bleeds through — the landed card visibly darkens then recovers (device-measured
            //2% trough, 2026-08-13). The glass transmits ~3%, so resting it on the fill
            //instead of the backdrop shifts the landed look by under 0.3%.
            RoundedRectangle(cornerRadius: currentRadius)
                .fill(Color.appCanvas)
            Color.clear
                //clipped: the unclipped material carries its own built-in shadow, which
                //arrived WITH the glass at landing and hardened the already-settled
                //.softFloating (device-measured +4.6% under-edge, on the glass's fade clock,
                //2026-08-13). Clipped glass sits at the no-shadow floor: the card wears only
                //its declared elevation, and nothing about the shadow changes after landing.
                .containerGlassEffect(tint: Color.appCanvas, clipped: true, shape: RoundedRectangle(cornerRadius: currentRadius))
                .opacity(landed ? 1 : 0)
        }
        .animation(.transition, value: landed)
        .frame(width: rect.width, height: rect.height)
        //Raw .shadow, sanctioned as a measured spec that interpolates geometry: the source
        //card's resting composite travels into .softFloating with opacity, radius AND offset
        //all lerped on the flight clock, so the shadow is exact at both hand-off frames and
        //continuous between them. (The old form stacked TWO .image strength-crossfades at
        //fixed full-size radii — a frame-one pop ~1.6× the resting card, frame-measured
        //2026-08-13.)
        .shadow(color: .black.opacity(contact.opacity), radius: contact.radius, x: 0, y: contact.y)
        .shadow(color: .black.opacity(ambient.opacity), radius: ambient.radius, x: 0, y: ambient.y)
        .position(x: rect.midX, y: rect.midY)
        .allowsHitTesting(false)
    }

    //lerp(landed, source, closeP): closeP 1 wears the source card's resting shadow, 0 the
    //landed card's. The dive overshoots closeP past 1; .opacity clamps and the radius/offset
    //extrapolation is transient and sub-point.
    private func flightShadowLayer(_ landed: Elevation.Layer, _ source: Elevation.Layer) -> Elevation.Layer {
        Elevation.Layer(opacity: Double(lerp(CGFloat(landed.opacity), CGFloat(source.opacity), closeP)),
                        radius: lerp(landed.radius, source.radius, closeP),
                        y: lerp(landed.y, source.y, closeP))
    }

    //The real layout, centred as the static screen was, lifted 12pt above true centre.
    //The lift sits ABOVE the measuring modifiers, so the flight's destination frames (and
    //everything derived from them — covers, halo pin, name-hero target) follow it for free.
    private var layoutColumn: some View {
        VStack(spacing: Spacing.xl) {
            cardColumn
            //LAYOUT GHOST: reserves the chevron's slot so the column centres exactly as
            //before, but the visible button renders on the STATIONARY layer above the pose
            //(flightCard's overlay) — inside this posed subtree it rode the drag and the
            //flights, and a fast flick carried it off-screen mid-pop (device, 2026-08-13)
            BottomBackButton(visible: false) { }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -Spacing.sm)
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
            guard !dragging, gestureFlight == nil else { return } //Frames are the drag's model space; frozen while the finger OR the flight driver owns them (unfrozen, each tick's pose feeds back into the measurements — the anchor migrates and the dive runs away; device frames, 2026-08-13)
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
        //The wash backstop: the tinted layers all ride the FLYING rect (the carousel wash) or
        //sit below the slot (the rows' seam gradient), so a bouncy open that overshoots the
        //image above its slot exposed a strip of bare appCanvas — a white flash at the
        //overshoot peak (device frames, 2026-08-13). Painting the slot with the seam's own
        //tint makes any overshoot gap read as the wash instead; at rest the opaque image
        //covers it completely.
        palette.secondaryText.opacity(0.45)
            .aspectRatio(currentImageAspect.ratio, contentMode: .fit)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newFrame in
                guard !dragging, gestureFlight == nil else { return } //Same freeze as the card frame above
                withAnimation(landed ? .transition : nil) { imageFrame = newFrame }
                openWhenMeasured()
            }
    }

    private func carouselLayer(_ origin: CGPoint) -> some View {
        let rect = local(lerp(carouselTargetFrame, sourceFrame, closeP), origin)

        return ZStack {
            //The seam wash lives UNDER the covers: the covers' bottom fuzz dissolves into it
            //from mid-flight on, so the landed seam colour is already there when the card
            //arrives (drawn above the covers it pulsed the whole photo during the reveal,
            //and gated on the cover drop it arrived as its own late beat — a colour snap)
            palette.secondaryText.opacity(0.45)
            flightCovers //Static stand-ins beneath the chrome: the live pager only exists at rest
            bakedHaloLayer //The title's halo rides the flight; the live one only exists at rest
            imageSection
        }
        .frame(width: rect.width, height: rect.height)
        .geometryGroup() //Children resolve geometry against the in-flight frame, not the destination
        .position(x: rect.midX, y: rect.midY)
        .mask { maskShape(origin) } //Same shape as the surface: cuts page bleed at the card edge, collapses to the source clip
        .allowsHitTesting(expanded && landed && !dragging)
    }

    //A copy of the source card's chrome riding the flying image: exits over the open,
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
                //Per-element exits, distributed by the chrome itself (ProfileCard.cardOverlay):
                //the scrim + name rush out on sourceChromeFade's 0.12s clock and ride closeP back
                //in over the collapse; the subtitle and invite icon pop away on their own effects,
                //revealed on the way home by the collapse multiplier. The blur band ignores both:
                //it rides the flight full-strength and crossfades against the baked invite blur
                //when the destination chrome arrives (chromeIn) — and back again over the close.
                //That handover waits on the bake as well: the chrome leads the flight now, so it
                //can beat blurredHero to the screen, and exiting into a layer that doesn't exist
                //yet would strand the title on bare artwork for the bake's last few ms.
                .environment(\.inviteChromeFade, min(Double(closeP), sourceChromeFade))
                .environment(\.inviteChromeCollapse, Double(closeP))
                .environment(\.inviteChromeExiting, sourceChromeExiting)
                //bakeReady, not blurredHero alone: a stale bake must not hold the hand-off.
                //`|| landed` keeps the source band OUT at rest — a mid-presentation image
                //swap briefly drops bakeReady, and the landed pager carries its own live
                //glur, so the stretched source band must not fade back in over it. During a
                //GESTURE close, arrived HOLDS (the gestureClosing term): the band's return is
                //driven by the geometry ramp below instead of an event fade, so the squashed
                //copy never rides the flight at strength far from source (the "squish";
                //device frames, 2026-08-13). The tap close keeps the event fade.
                .environment(\.inviteChromeArrived,
                             (chromeIn || gestureClosing) && (bakeReady || landed))
                .environment(\.inviteChromeCloseRamp,
                             gestureClosing ? Double(min(max((closeP - 0.7) / 0.3, 0), 1)) : 0)
                //Conditional, NOT constant true: if the hero can't anchor (no sourceNameRect —
                //the chrome-less harness, or a failed derivation) the copy's name keeps its
                //old chromeFade exits instead of blanking for the whole flight (device video)
                .environment(\.inviteChromeNameFlying, nameHeroActive)
                .scaleEffect(x: rect.width / max(sourceFrame.width, 1),
                             y: rect.height / max(sourceFrame.height, 1))
                .position(x: rect.midX, y: rect.midY)
                .allowsHitTesting(false)
        }
    }

    //The name's own hero flight: the name never blinks — it rides from the meet card's
    //bottom-left (26pt) to its slot beside "Invite" in the title (22pt) as ONE text, scaled
    //along the flight. The title's real name is a layout ghost meanwhile (nameFlying), and
    //the chrome copy's name is env-hidden for the whole presentation. Rendered at the SOURCE
    //size and transform-scaled: the 22pt landing is 26 × ~0.85, sub-pixel from the true title.
    @ViewBuilder
    private func nameFlightLayer(_ origin: CGPoint) -> some View {
        let sourceName = zoom?.sourceName ?? .zero
        if nameHeroActive, sourceName.width > 1 {
            //Destination built declaratively: frozen flight target + the title's invariant
            //offsets. Never a measured global position — those hold model values and would
            //teleport the lerp target mid-flight ([[measured-frames-dont-track-animation]]).
            let target = carouselTargetFrame
            let dest = titleNameSlot.width > 1
                ? CGRect(x: target.minX + titleNameSlot.minX,
                         y: target.maxY - titleNameSlot.minY - titleNameSlot.height,
                         width: titleNameSlot.width, height: titleNameSlot.height)
                : sourceName //First frames only: the title publishes its slot from its first layout pass
            let rect = local(lerp(dest, sourceName, closeP), origin)
            Text(name)
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .fixedSize()
                .scaleEffect(rect.height / max(sourceName.height, 1), anchor: .center)
                .position(x: rect.midX, y: rect.midY)
                .opacity(heroFadesWithCollapse ? Double(closeP) : 1)
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
    //between them and the live pager is invisible. ALWAYS MOUNTED, every one of them: a view
    //inserted while the spring is airborne resolves its layout at DESTINATION geometry and
    //animates there on the insertion transaction's clock, outrunning the flight — geometryGroup
    //does not rescue a newly-inserted child (frame-measured 2026-08-13: the old `if let
    //blurredHero` insertion produced a same-scale, ~30pt-translated destination-crop ghost
    //early in the flight and a leading bottom clip edge — the "detached band" — late in it).
    //The hero cover carries the whole open flight and the close; the page snapshot freezes a
    //non-hero page so the pager can snap home unseen. Shaders never fly: the hero stack is
    //sharp pixels plus the PRE-BAKED band — no live glur (the old glur'd hero cover was
    //pixel-identical to the bake and rode every flight as a resident layerEffect for nothing).
    //The snapshot keeps its glur variant, lit by `blurCover` only for the single frame the
    //pager unmounts at close start, faded out over the chrome race. The pager's real glur
    //refines the baked band invisibly under the landing reveal (pagerReveal).
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
                    rawCover(blurredHero ?? images[0]) //Identical pixels until the bake lands (a leaf content swap under opacity 0, never an insertion); after it, only the bottom band differs
                        .opacity(bandVisible ? 1 : 0)
                        .animation(.transition, value: bandVisible)
                }
                .opacity(coverFade)
            }
            //The pager page's own 2pt bottom fade (InvitePagePhoto's mask), worn once by the
            //whole cover stack: the covers dissolve into the wash beneath exactly like a
            //resting page, so the seam reads the same mid-flight, through the reveal, and at
            //rest — nothing about it changes at landing
            .mask {
                VStack(spacing: 0) {
                    Rectangle()
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 2)
                }
            }
            .allowsHitTesting(false)
        }
    }

    //The title's halo as flat pixels, pinned bottomLeading at its baked (destination) size —
    //the strip rides the flying rect exactly like the title words it backs. In with the
    //chrome, out with it at close start, gone with the title on the confirm screen, and
    //crossfaded out beneath the live BackgroundBlur during the pager reveal — so nothing
    //about the title's backdrop changes after landing. Always mounted: a bake landing
    //mid-flight is a leaf content swap, never an insertion.
    private var bakedHaloLayer: some View {
        Color.clear
            .overlay(alignment: .bottomLeading) {
                Image(uiImage: bakedHalo ?? UIImage())
                    .resizable()
                    .frame(width: bakedHalo?.size.width ?? 0, height: bakedHalo?.size.height ?? 0)
            }
            .opacity(haloVisible ? 1 - pagerReveal : 0)
            .animation(.transition, value: haloVisible)
            .allowsHitTesting(false)
    }

    private var haloVisible: Bool {
        currentScreen.chrome.title && chromeIn && bakedHalo != nil
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
    //so a confirm-screen swap retargets the flight before the slot finishes measuring.
    //A gesture close SCRUBS the height toward the SOURCE aspect during its descent/race
    //(cropScrub), so the ascent lerps between two same-proportion rects — a rigid frame
    //instead of a width-vs-height morph mid-climb (the "squish"; device frames, 2026-08-13).
    //Top-anchored: the crop extends downward, the top edge stays put (the profile's rule).
    private var carouselTargetFrame: CGRect {
        var target = targetImageFrame
        let invited = targetImageFrame.width / currentImageAspect.ratio
        let source = sourceFrame.width > 1
            ? targetImageFrame.width * (sourceFrame.height / sourceFrame.width)
            : invited
        target.size.height = lerp(invited, source, cropScrub)
        return target
    }

    //Chrome axis first (card → image-only), flight axis second (→ source). The image
    //endpoint is the SCRUBBED crop target, in lockstep with the flying image — anchored to
    //the measured slot the mask would crop the crop-extended image's bottom mid-dive
    private func maskRect(_ origin: CGPoint) -> CGRect {
        let chromeRect = lerp(targetCardFrame, carouselTargetFrame, chromeMix)
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
            chromeIn = true
            chevronIn = true
            pagerReveal = 1
            coversDropped = true
            closeP = 0
            coverFade = 0
            return
        }
        flightTargets = (cardFrame, imageFrame) //Freeze the destination for this flight
        let generation = flightGeneration
        Task { @MainActor in //One committed frame at the source rect before the flight animates from it
            sourceChromeExiting = true //Subtitle + invite icon pop away on their own clocks
            heroFadesWithCollapse = false //A fresh open always leaves from the send screen's visible title
            withAnimation(Self.sourceChromeExit) { sourceChromeFade = 0 }
            chromeIn = true //The chrome LEADS the flight: its 0.25s .transition pop runs from frame 1, so the card arrives already dressed
            withAnimation(Self.openFlight, completionCriteria: .removed) {
                expanded = true
                closeP = 0
            } completion: {
                land(generation)
            }
            scheduleChevronIn(generation)
        }
    }

    //The chevron arms a quarter into the open: on the spring's own clock, so the pop begins
    //once the flight reads committed and finishes with the card's settle
    private func scheduleChevronIn(_ generation: Int) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Self.openSpring.duration * Self.chevronInShare))
            guard expanded, generation == flightGeneration else { return } //A close mid-open keeps it away
            chevronIn = true
        }
    }

    private func expandedChanged(_ isExpanded: Bool) {
        if isExpanded {
            //A no-flight mount landed inline in openWhenMeasured: re-covering it here would
            //strand coverFade at 1 forever now that land() is single-shot (!landed latch)
            guard hasFlight else { return }
            dragging = false //A reopen mid-close revives the card; unfreeze frames and hand hits back
            springingBack = false
            bandIn = true //A reopen takes the band back from the source copy
            coverFade = 1 //Cover the pager until this flight lands (identical pixels — instant is invisible)
            let generation = flightGeneration
            Task {
                //Redundant with the flight completion, in case it never fires. Must sit WELL
                //past the spring's settling tail (~0.65s to .removed): at 0.6s this fallback
                //usually WON the race and mounted the pager while the presentation was still
                //1–5pt from home — an offset pager crossfading over the covers for the whole
                //reveal, the rare near-landed double image (device screenshot, 2026-08-13).
                try? await Task.sleep(for: .seconds(1.0))
                land(generation)
            }
        } else {
            flightGeneration += 1
            landed = false
            chromeIn = false //Chrome pops out at close start, ahead of the flight home
            chevronIn = false //Re-armed by the next open/reopen's schedule
            bandIn = false //The baked band exits with it; the source copy's band rides the collapse back in
            pagerReveal = 0 //The pager unmounts in this same commit; reset for the next landing
            coversDropped = false
            nameLanded = false //The hero text takes the name back for the flight home
        }
    }

    private func land(_ generation: Int) {
        //!landed: every flighted open calls land twice (flight completion + the 0.6s fallback,
        //same generation) — the second call's no-change withAnimation fires its completion
        //SYNCHRONOUSLY (sim-probed), which would drop the covers mid-reveal
        guard expanded, !landed, generation == flightGeneration else { return } //A newer close/reopen owns the flight now
        landed = true //Mounts the live pager over the covers, transparent until the reveal below
        chromeIn = true //Normally already in on its own clock — this covers the fallback land
        bandIn = true //As above
        chevronIn = true //As above — the landing must never sit chevron-less
        flightTargets = nil //Live measurements own the geometry again
        blurCover = 0 //The pager carries the bottom blur from here
        Task { @MainActor in //The name swap waits out the spring's last sub-pixel settle — swapping at land() can still jump ~1pt
            try? await Task.sleep(for: .seconds(0.15))
            guard expanded, generation == flightGeneration else { return }
            nameLanded = true
        }
        if let coverPage, images.indices.contains(coverPage) { //A reopen mid-close: give the pager its page back
            snapPager { $0.scrollTo(id: images[coverPage], anchor: .leading) }
        }
        if coverPage != nil {
            //Reopen mid-close from a non-hero page: the snapshot matching the pager sits
            //BENEATH the opaque hero cover, so a reveal here dissolves two different photos.
            //Keep the pre-reveal cut: opaque pager in one frame, covers dropped beneath it.
            pagerReveal = 1
            coversDropped = true
            coverPage = nil
            withAnimation(.transition) { coverFade = 0 } //Under the opaque pager; the wash arrives with it
            return
        }
        //The pager (and the pages' bottom blur) fades in over the HELD covers — fading a cover
        //out under the still-transparent pager dips the composite toward the card fill instead
        //of crossfading, so the covers only drop once the pager above them is opaque.
        withAnimation(.transition, completionCriteria: .removed) { pagerReveal = 1 } completion: {
            guard expanded, generation == flightGeneration else { return } //A close mid-reveal still needs its covers
            coversDropped = true //Paging unlocks with the drop
            coverPage = nil //Dropped under the now-opaque pager…
            withAnimation(.transition) { coverFade = 0 } //…as is the hero cover (the bottom fuzz hands off to the wash)
        }
    }

    private func closeInvite() {
        guard hasFlight else { //No source to collapse into (profile flow): unmount as before
            showInvite = false
            return
        }
        prepareClose()
        expanded = false //Chrome fades out on its own .transition scopes; hit gates drop
        launchCloseFlight() //Mask and image collapse together on the flight spring
    }

    //The TAP close: one clock — the mask (chromeRaceP) and the image (closeP) shrink together
    //on the settle spring, so the card's bottom sweeps up in lockstep with the image's travel.
    //(The old form raced the mask on a separate fast clock — the card visibly emptied first,
    //and the two curves' combined tails left a white strip hovering under the image; device
    //frames, 2026-08-13.) The hop keeps the close's committed from-pose. The spring's small
    //overshoot extrapolates closeP past 1 — the card dips through the slot and expands back.
    //Gesture releases never come here: they fly the ported profile machine (routeRelease).
    //
    //.logicallyComplete, NOT .removed: the handback (showInvite = false → the overlay unmounts
    //and the REAL list card reappears in the same commit) must land at the spring's perceptual
    //rest. .removed waits out the interpolating spring's full physical tail (~1s of sub-1%
    //motion), and the faded backdrop no longer blocks input there — the list scrolled under a
    //landed copy pinned at its frozen frame (device recording, 2026-08-14).
    private func launchCloseFlight() {
        Task { @MainActor in
            withAnimation(Self.chromeRace) { blurCover = 0 } //The glur layers leave before the collapse needs its frames
            withAnimation(.interpolatingSpring(Self.settleFlight, initialVelocity: 0), completionCriteria: .logicallyComplete) {
                closeP = 1
                chromeRaceP = 1
            } completion: {
                guard !expanded else { return } //A reopen mid-close owns the card now
                showInvite = false
            }
        }
    }

    private func reopen() {
        stopGestureFlight() //A gesture flight in progress hands the card to the revival
        sourceChromeExiting = true
        withAnimation(Self.sourceChromeExit) { sourceChromeFade = 0 }
        chromeIn = true //Leads the flight, as on the first open
        withAnimation(Self.chromeRace) { blurCover = 0 } //A reopen inside the close's first beats must not fly the snapshot's live glur at partial opacity
        withAnimation(Self.openFlight) {
            expanded = true
            closeP = 0
            chromeRaceP = 0
            cropScrub = 0 //The crop morphs back to the invited aspect on the revival flight
        }
        scheduleChevronIn(flightGeneration) //Late arrival on the revival too
    }

    private func prepareClose() {
        flightTargets = (cardFrame, imageFrame) //Freeze the collapse's from-geometry
        sourceChromeFade = 1 //The cap steps aside: the chrome copy rides the collapse back in via closeP
        sourceChromeExiting = false //Subtitle + invite icon pop back in, revealed by the collapse
        heroFadesWithCollapse = !currentScreen.chrome.title //No visible title to leave from (confirm screen): the name rides in with the collapse instead
        //The snapshot cover must match the pager on its unmount frame; the race fades the blur
        //out. At rest that pager is fully glur'd. Mid-reveal it is only fraction-opaque, and
        //full glur on top would POP the bottom fifth — the baked band layer (already in via
        //bandVisible) carries the bottom blur there instead. The hero cover never needs this:
        //its baked band is pager-identical at rest by construction.
        blurCover = coversDropped ? 1 : 0
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

//Invite-scale release tuning. The gesture machine is the profile's (DragTuning stays the
//single source for every curve SHAPE, spring and arc — see the MARK below), but the profile's
//scale constants were tuned on a full-screen surface where gestures are naturally long. On
//the smaller card a natural drag is shorter and gentler, and the profile's numbers read as
//too heavy (a release under ~102pt of raw travel with a sub-~180pt/s flick sprang back).
//Only these three SCALE numbers differ; retune feel here, never by forking DragTuning's shapes.
private enum InviteDragTuning {
    /// Vertical drag that scrubs the collapse 0→1 (profile: 300).
    static let collapseDistance: CGFloat = 240
    /// Release past this progress dismisses (profile: 0.3) — ≈48pt of adjusted travel here vs 90.
    static let dismissThreshold: CGFloat = 0.2
    /// Momentum-projected coast (≈0.5·velocity) past this commits a modest-travel flick
    /// (profile: 90) — a release moving ≥ ~120pt/s commits instead of ~180.
    static let flickFloor: CGFloat = 60
    /// The arc's overshoot velocity band, invite scale (profile: 300…3000, blend steep 4 —
    /// a band that pins every realistic invite flick to the gentle edge, so the dive read
    /// as one fixed ~57pt depth). A commit-worthy flick starts deepening immediately and a
    /// genuinely hard card flick reaches the full hard edge; the near-linear blend spreads
    /// the ramp across the band instead of hoarding it at the top.
    static let arcFlickFloor: CGFloat = 120
    static let arcFlickCeil: CGFloat = 1400
    static let arcFlickBlendSteep: CGFloat = 1.5
    /// Releases slower than this morph straight in with no arc (profile: 250). Set AT the
    /// flick-commit floor: any release that commits with real motion earns the dive; only
    /// still let-gos (distance commits) keep the calm morph.
    static let arcSlowMorphCeil: CGFloat = 120
}

//MARK: Interactive dismiss — ProfileZoom's gesture dismissal, ported exactly
//
//Every constant and pure function comes from DragTuning (ProfileZoomTransition.swift): one
//source of truth for both cards. The release routing, the two-beat arc (ghost-finger dive to
//a position-dependent pivot, physical settle spring), the direct/standard/slow-morph
//collapses, the cancel spring and its mid-air catch all mirror the profile's machine. The
//HOST differs: the profile scrubs UIKit transforms from animators; the invite evaluates the
//same closed-form curves per frame on a display link and writes its model — deterministic,
//catchable, frame-verifiable. Committed dismissals refuse the catch, exactly like the
//profile (catchFlight's diveLink/flightIsDismissal guards). The hero CROP scrubs to the
//source aspect during the dive/race (cropScrub — the profile's setHeroCropScrub), so the
//ascent flies a rigid, source-proportioned frame; only the TAP close still morphs its
//aspect across the settle. The arc is defined on the image TOP's trajectory (pivot =
//slotTop + overshoot(D, v)), which this port pins identically.
extension SendInviteContainer {

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if dragAxis == nil {
                    let vertical = abs(value.translation.height) >= abs(value.translation.width)
                    let canBegin = hasFlight && expanded && landed && !springingBack && !ui.isPopupOpen()
                    if vertical, catchCancelSpring() {
                        //A cancel spring mid-air is catchable — the finger re-owns the card.
                        //Committed dismissals refuse the grab and fly home (the profile's rule).
                        dragAxis = .vertical
                        dragStart = slopOrigin(value.translation)
                    } else if vertical && canBegin {
                        dragAxis = .vertical
                        beginDrag()
                        dragStart = slopOrigin(value.translation) //Zero the recognition slop so the card departs from rest (the profile zeroes its pan)
                    } else {
                        dragAxis = .horizontal //Voided: horizontal belongs to the pager
                    }
                }
                guard dragAxis == .vertical, dragging, expanded else { return }
                (dragProgress, dragOffset) = dragModel(for: adjusted(value.translation))
            }
            .onEnded { value in
                let owned = dragAxis == .vertical && dragging
                dragAxis = nil
                guard owned, expanded else { return }
                let t = adjusted(value.translation)
                //flick = the distance the touch would coast from its release velocity
                let flick = DragTuning.projectedTravel(value.velocity.height)
                if dragProgress > InviteDragTuning.dismissThreshold
                    || (t.height > 20 && flick > InviteDragTuning.flickFloor) {
                    dragging = false //The flight owns the card now (the profile clears it at commit)
                    routeRelease(translation: t, velocity: value.velocity)
                } else {
                    cancelDrag(velocity: value.velocity)
                }
            }
    }

    private func adjusted(_ translation: CGSize) -> CGSize {
        CGSize(width: translation.width - dragStart.width,
               height: translation.height - dragStart.height)
    }

    //Zero ONLY the 12pt recognition slop, never the excess: over the rows, button-delayed
    //touch delivery hands the first change 50–100pt of accumulated travel — zeroing all of
    //it swallowed the drag's start (the card lagged the finger) and gutted flick
    //translations so releases under-counted progress and refused to commit. The profile's
    //UIKit pan always fires at its own ~10pt slop, so its full zeroing is equivalent to this.
    private func slopOrigin(_ t: CGSize) -> CGSize {
        let m = max((t.width * t.width + t.height * t.height).squareRoot(), 0.001)
        let s = min(m, 12) / m
        return CGSize(width: t.width * s, height: t.height * s)
    }

    private func beginDrag() {
        dragging = true
        snapPager { $0.scrollTo(id: images[currentPage], anchor: .leading) } //Kill an in-flight flick; frames are frozen from here
    }

    //The drag rule as a pure pose — shared by the live drag and the throw's ghost finger,
    //which replays this same rule along the momentum's decay: a fast dive is pixel-equivalent
    //to a slow drag at every height. A caught cancel spring blends from the seized pose onto
    //the rule over the first ~120pt of new finger travel (the profile's regrab blend).
    private func dragModel(for t: CGSize) -> (progress: CGFloat, offset: CGSize) {
        var (progress, offset) = ghostModel(for: t)
        if let base = regrabProgress {
            let w = min(1, (abs(t.width) + abs(t.height)) / 120)
            progress = lerp(base, progress, w)
            offset = CGSize(width: lerp(regrabOffset.width, offset.width, w),
                            height: lerp(regrabOffset.height, offset.height, w))
            if w >= 1 { regrabProgress = nil }
        }
        return (progress, offset)
    }

    //The rule itself, blend-free — what the ghost finger drives
    private func ghostModel(for t: CGSize) -> (progress: CGFloat, offset: CGSize) {
        let progress = min(max(t.height / InviteDragTuning.collapseDistance, 0), 1)
        let offset = CGSize(
            width: DragTuning.rubberBand(t.width, limit: 160, response: 0.8),
            height: t.height >= 0
                ? DragTuning.rubberBand(t.height, limit: 700, response: 1)
                : DragTuning.rubberBand(t.height, limit: 80, response: 0.9)) //Upward fights back hard
        return (progress, offset)
    }

    //MARK: Release routing — the profile's finishDismiss, verbatim structure

    private func routeRelease(translation t: CGSize, velocity v: CGSize) {
        prepareClose()
        expanded = false //Chrome fades on its own .transition scopes; hit gates drop
        Task { @MainActor in //One committed frame with the covers up, then the glur leaves (as the tap close)
            withAnimation(Self.chromeRace) { blurCover = 0 }
        }
        #if DEBUG
        print(String(format: "INVITE RELEASE minY=%.1f vy=%.0f overshoot=%.1f",
                     sourceFrame.minY, v.height,
                     DragTuning.arcOvershoot(destinationTop: sourceFrame.minY, velocity: v.height,
                                             flickFloor: InviteDragTuning.arcFlickFloor,
                                             flickCeil: InviteDragTuning.arcFlickCeil,
                                             blendSteep: InviteDragTuning.arcFlickBlendSteep)))
        #endif
        if sourceFrame.minY < DragTuning.arcCutoffY {
            runArc(translation: t, velocity: v)
        } else if v.height >= DragTuning.fastFlickVelocity {
            //Direct collapse: the finger's REAL on-screen speed through the band's slope,
            //signed toward the slot by the actual geometry
            let descent = v.height * DragTuning.rubberBandSlope(t.height, limit: 700, response: 1)
            startSpring(duration: DragTuning.closeFlightDuration, zeta: DragTuning.bounceDamping,
                        v0: descentKick(descent, signedDescent: true), race: standardRace())
        } else {
            startSpring(duration: DragTuning.closeFlightDuration, zeta: DragTuning.bounceDamping,
                        v0: normalizedKick(v), race: standardRace())
        }
    }

    //The TWO-BEAT ARC (slots above the 450 line): slow releases morph straight in; a finger
    //already at/past the pivot plays the climb alone; otherwise the ghost finger dives the
    //drag rule to the pivot and the physical spring takes the card up from rest.
    private func runArc(translation t: CGSize, velocity v: CGSize) {
        if v.height < InviteDragTuning.arcSlowMorphCeil {
            //A drag let go, not a flick: the calm slow morph, its mask race spanning its
            //share of the flight instead of the quick openness-scaled race
            startSpring(duration: DragTuning.arcSlowMorphDuration, zeta: DragTuning.bounceDamping,
                        v0: normalizedKick(v),
                        race: DragTuning.arcSlowMorphDuration * DragTuning.arcSlowMorphRaceShare)
            return
        }
        let D = sourceFrame.minY
        let overshootRaw = DragTuning.arcOvershoot(destinationTop: D, velocity: v.height,
                                                   flickFloor: InviteDragTuning.arcFlickFloor,
                                                   flickCeil: InviteDragTuning.arcFlickCeil,
                                                   blendSteep: InviteDragTuning.arcFlickBlendSteep)
        //The pivot pose's card: the flight crop at SOURCE aspect (scrubbed complete by the
        //pivot), deep-scaled — the profile's exact formula (heroWidth·sourceAspect·minScale).
        //The pivot anchors to the destination ON SCREEN so above-screen slots keep the arc.
        let pivotHeight = targetImageFrame.width
            * (sourceFrame.height / max(sourceFrame.width, 1)) * DragTuning.minDragScale
        let pivotAnchor = max(D, 0)
        let room = UIScreen.main.bounds.height - pivotAnchor - pivotHeight
        let overshoot = min(overshootRaw, max(room, 0))
        let pivotTop = pivotAnchor + overshoot
        let targetVirtual = virtualTravel(forImageTop: pivotTop)
        let delta = targetVirtual - t.height
        let pace = DragTuning.travelPaceBoost(destinationTop: D)
        var settle = DragTuning.arcReturnSettle(velocity: v.height) / TimeInterval(pace.squareRoot())
        guard overshoot > 1, delta > 1 else {
            //Deep release: the finger already sits at/past the pivot — the climb plays alone,
            //the downward residual feeding the spring's away-kick. Standard settle,
            //deliberately untrimmed, extended for above-screen slots.
            let deepSettle = DragTuning.throwSettle + DragTuning.aboveScreenTime(destinationTop: D)
            let residual = max(v.height, 0) * DragTuning.rubberBandSlope(t.height, limit: 700, response: 1)
            startSpring(duration: deepSettle, zeta: 1, v0: descentKick(residual), race: standardRace())
            return
        }
        var launch = min(max(v.height * DragTuning.arcPaceScale,
                             DragTuning.arcMinLaunch), DragTuning.arcMaxLaunch) * pace
        //Stiffness from the pivot: T(t) = launch·t·e^{−ωt} tops out at launch/(eω), so
        //ω = launch/(e·Δ) soft-hovers exactly at the pivot's finger-space depth
        var omega = Double(launch) / (M_E * Double(delta))
        var diveDuration = min(1.0 / omega, DragTuning.arcMaxDiveTime)
        //Consistent total: rescale BOTH beats onto the depth-mapped target (proportional
        //split, floored at arcMinDiveShare); the impulse re-derives ω and launch so the peak
        //still lands exactly at Δ. The above-screen extension joins AFTER the split.
        let base = DragTuning.arcTimeMin + (DragTuning.arcTimeMax - DragTuning.arcTimeMin)
            * TimeInterval(min(overshoot / DragTuning.arcMaxOvershoot, 1))
        let natural = diveDuration + settle
        if natural > 0.01 {
            let dive = max(diveDuration * (base / natural), base * DragTuning.arcMinDiveShare)
            diveDuration = dive
            settle = (base - dive) + DragTuning.aboveScreenTime(destinationTop: D)
            omega = 1.0 / dive
            launch = CGFloat(M_E * Double(delta) * omega)
        }
        settle += DragTuning.arcFlickFadeTime(velocity: v.height) //Settle-only: the dive is untouched
        #if DEBUG
        let checkA = targetImageFrame.midY, checkI = targetImageFrame.minY
        let checkP = min(max(targetVirtual / InviteDragTuning.collapseDistance, 0), 1)
        let checkK = 1 - (1 - DragTuning.minDragScale) * checkP
        let checkTop = checkA + checkK * (checkI - checkA)
            + DragTuning.rubberBand(targetVirtual, limit: 700, response: 1)
        print(String(format: "INVITE ARC pivotTop=%.1f virtual=%.1f delta=%.1f A=%.1f I=%.1f poseTop(v)=%.1f",
                     pivotTop, targetVirtual, delta, checkA, checkI, checkTop))
        #endif
        var flight = GestureFlight()
        flight.diveDuration = diveDuration
        flight.omega = omega
        flight.origin = t
        flight.launch = CGPoint(x: v.width, y: launch) //x keeps the finger's actual drift
        flight.springDuration = settle
        flight.zeta = 1 //The throw's return is the PHYSICAL spring (ζω = 6.6/settle)
        flight.raceFrom = max(dragProgress, chromeRaceP)
        flight.total = diveDuration + settle
        startGestureFlight(flight)
    }

    //MARK: Kicks — UIKit's initialVelocity convention (fraction of remaining travel per
    //second, positive toward the target), the profile's exact conversions

    private func normalizedKick(_ v: CGSize) -> CGFloat {
        min(max(v.height / InviteDragTuning.collapseDistance, 0), 4)
    }

    //The flying image centre's remaining travel to the slot under the current pose (scale is
    //anchored at the image centre, so only the offset moves it)
    private var remainingTravel: CGFloat {
        max(abs(sourceFrame.midY - (targetImageFrame.midY + dragOffset.height)), 1)
    }

    private func descentKick(_ descentSpeed: CGFloat, signedDescent: Bool = false) -> CGFloat {
        var dy = -min(max(descentSpeed / remainingTravel, -4), 4) //Downward residual = away-kick
        if signedDescent, sourceFrame.midY > targetImageFrame.midY + dragOffset.height {
            dy = -dy //The slot sits BELOW the release pose: downward is toward the target
        }
        return dy
    }

    //Inverts the drag rule: the ghost-finger travel whose pose puts the flying image's TOP at
    //`screenTop`. In the saturated regime (progress pinned at 1) only the rubber band varies —
    //closed form; shallow targets bisect the exact pose expression. Pure model math.
    private func virtualTravel(forImageTop screenTop: CGFloat) -> CGFloat {
        let A = targetImageFrame.midY //The scale anchor: the image centre stays put under k
        let I = targetImageFrame.minY
        func poseTop(_ y: CGFloat) -> CGFloat {
            let p = min(max(y / InviteDragTuning.collapseDistance, 0), 1)
            let k = 1 - (1 - DragTuning.minDragScale) * p
            return A + k * (I - A) + DragTuning.rubberBand(y, limit: 700, response: 1)
        }
        let deepBase = A + DragTuning.minDragScale * (I - A)
        let bandNeeded = min(screenTop - deepBase, 660) //The band saturates at 700
        let bandAtSaturation = DragTuning.rubberBand(InviteDragTuning.collapseDistance, limit: 700, response: 1)
        if bandNeeded >= bandAtSaturation {
            return min(700 * bandNeeded / (700 - bandNeeded), 2400)
        }
        var lo: CGFloat = 0, hi = InviteDragTuning.collapseDistance
        guard poseTop(hi) > screenTop else { return hi }
        for _ in 0..<20 {
            let mid = (lo + hi) / 2
            if poseTop(mid) < screenTop { lo = mid } else { hi = mid }
        }
        return (lo + hi) / 2
    }

    //MARK: The flight driver — closed-form beats, one display link

    //A commit flight without a dive (standard / direct / slow-morph / deep-release)
    private func startSpring(duration: TimeInterval, zeta: CGFloat, v0: CGFloat, race: TimeInterval) {
        var flight = GestureFlight()
        flight.springDuration = duration
        flight.zeta = zeta
        flight.v0 = v0
        flight.raceFrom = max(dragProgress, chromeRaceP)
        flight.raceDuration = race
        flight.total = duration
        startGestureFlight(flight)
    }

    //The mask race for non-arc commits: openness-scaled so the condense moves at one
    //consistent speed regardless of how deep the drag was. Openness = 1 − chromeMix exactly
    //(the invite's mask height is the card→image lerp on chromeMix).
    private func standardRace() -> TimeInterval {
        DragTuning.maskRaceDuration * max(TimeInterval(1 - chromeMix), 0.2)
    }

    private func startGestureFlight(_ flight: GestureFlight) {
        var f = flight
        f.fromProgress = dragProgress
        f.fromOffset = dragOffset
        f.start = CACurrentMediaTime()
        gestureFlight = f
        flightLink.start { now in flightTick(now) } //@State setters are nonmutating — safe from the escaping tick
    }

    private func stopGestureFlight() {
        flightLink.stop()
        gestureFlight = nil
    }

    private func flightTick(_ now: CFTimeInterval) {
        guard var flight = gestureFlight else { flightLink.stop(); return }
        //Clamped: the link's first timestamp is the PREVIOUS refresh — before start was
        //stamped — and a negative elapsed evaluates the impulse backwards (an upward blip)
        let elapsed = max(now - flight.start, 0)

        //Watchdog: a wedged flight must still resolve (the profile arms one per animator)
        if elapsed > flight.total + 1.0 {
            finishGestureFlight(flight)
            return
        }

        //── Beat 1: the dive (arc flights only) ──
        if flight.diveDuration > 0 {
            let t = min(elapsed, flight.diveDuration)
            let impulse = CGFloat(t * exp(-flight.omega * t))
            let virtual = CGSize(width: flight.origin.width + flight.launch.x * impulse,
                                 height: flight.origin.height + flight.launch.y * impulse)
            let (p, o) = ghostModel(for: virtual)
            dragProgress = p
            dragOffset = o
            //The mask races ahead of the height rule, fully closed by the impulse's peak
            //(the rule is a floor via chromeMix's max, not a ceiling); soft-attack smoothstep
            let f = CGFloat(min(t / max(flight.diveDuration, 0.001), 1))
            let closing = f * f * (3 - 2 * f)
            chromeRaceP = flight.raceFrom + (1 - flight.raceFrom) * closing //The backdrop formula rides this out with the mask
            //Crop scrub — the aspect morphs to the SOURCE proportions on the dive's own
            //clock, complete by 0.8·dive so it stays ahead of the racing mask (the
            //profile's setHeroCropScrub); the ascent then flies a rigid frame
            let cf = CGFloat(min(t / max(flight.diveDuration * 0.8, 0.001), 1))
            cropScrub = cf * cf * (3 - 2 * cf)
            guard elapsed >= flight.diveDuration else { return }
            //Hand over with the ghost's actual signed speed: T′(t) = v·e^{−ωt}(1−ωt) —
            //zero at the designed exit, a real downward residual if arcMaxDiveTime clipped it
            let slope = exp(-flight.omega * t) * (1 - flight.omega * t)
            let residual = flight.launch.y * CGFloat(slope)
                * DragTuning.rubberBandSlope(virtual.height, limit: 700, response: 1)
            #if DEBUG
            let hA = targetImageFrame.midY, hI = targetImageFrame.minY
            let hK = 1 - (1 - DragTuning.minDragScale) * dragProgress
            let modelTop = hA + hK * (hI - hA) + dragOffset.height
            print(String(format: "INVITE HANDOVER t=%.3f residual=%.1f virtual=%.1f modelTop=%.1f",
                         t, residual, virtual.height, modelTop))
            #endif
            flight.diveDuration = 0 //The spring beat owns the clock from here
            flight.start = now
            flight.v0 = descentKick(residual)
            flight.fromProgress = dragProgress
            flight.fromOffset = dragOffset
            flight.raceFrom = chromeRaceP //Raced closed by the dive — the spring's race is a no-op delta
            flight.raceDuration = 0
            flight.total = flight.springDuration
            gestureFlight = flight
            return
        }

        //── Beat 2: the spring (settle / collapse / cancel) ──
        let u = springRemaining(t: elapsed, duration: flight.springDuration,
                                zeta: flight.zeta, v0: flight.v0)
        let poseU = max(u, 0) //The pose unwinds to rest and stays; the overshoot lives in closeP's extrapolation
        dragProgress = flight.fromProgress * poseU
        dragOffset = CGSize(width: flight.fromOffset.width * poseU,
                            height: flight.fromOffset.height * poseU)
        if flight.isCancel {
            //Home is the presented card: closeP stays 0, the backdrop formula tracks the unwind
        } else {
            closeP = 1 - u //Overshoot extrapolates the rect past the slot, as every close here does
            if flight.raceDuration > 0.001 {
                let uR = springRemaining(t: elapsed, duration: flight.raceDuration, zeta: 1, v0: 0)
                let race = 1 - min(max(uR, 0), 1)
                chromeRaceP = flight.raceFrom + (1 - flight.raceFrom) * race
                cropScrub = max(cropScrub, race) //The crop resolves ON the race clock, in lockstep with the mask (the profile's runCollapse rule)
            } else {
                chromeRaceP = 1 //A throw hand-over: the dive already raced the mask and finished the crop
            }
        }
        //Done when the envelope is spent (the fitted curves reach ~0.1% at duration; the
        //physical settle carries a short polynomial tail past it)
        if elapsed >= flight.springDuration, abs(u) < 0.002 || elapsed >= flight.springDuration * 1.5 {
            #if DEBUG
            print(String(format: "INVITE FLIGHT DONE elapsed=%.3f spring=%.3f cancel=%d",
                         elapsed, flight.springDuration, flight.isCancel ? 1 : 0))
            #endif
            finishGestureFlight(flight)
        }
    }

    private func finishGestureFlight(_ flight: GestureFlight) {
        stopGestureFlight()
        dragProgress = 0
        dragOffset = .zero
        if flight.isCancel {
            springingBack = false
            guard expanded else { return } //A close started mid-spring; leave state to that flight
            dragging = false
        } else {
            closeP = 1
            chromeRaceP = 1
            guard !expanded else { return } //A reopen mid-close owns the card now
            showInvite = false
        }
    }

    //MARK: Cancel + catch — the profile's cancelDismiss / catchFlight pair

    private func cancelDrag(velocity: CGSize) {
        springingBack = true
        //Toward-target is UPWARD here: −velocity.y over the pose's own displacement back to
        //rest; a downward release floors to 0 so the spring starts from rest
        let v0 = min(max(-velocity.height, 0) / max(abs(dragOffset.height), 1), 8)
        var flight = GestureFlight()
        flight.isCancel = true
        flight.springDuration = DragTuning.openFlightDuration
        flight.zeta = DragTuning.bounceDamping
        flight.v0 = v0
        flight.total = DragTuning.openFlightDuration
        startGestureFlight(flight)
    }

    //Seizes a cancel spring mid-air and hands the card back to the finger. Committed
    //dismissals deliberately refuse the grab and fly home — the profile's exact rule.
    private func catchCancelSpring() -> Bool {
        guard let flight = gestureFlight, flight.isCancel else { return false }
        stopGestureFlight() //The model IS the presentation under the driver — the pose is already folded
        springingBack = false
        dragging = true
        regrabProgress = dragProgress //Blend baseline: the rule takes over across the first 120pt
        regrabOffset = dragOffset
        return true
    }

    //Closed-form damped spring, normalized: u(0) = 1 remaining, u′(0) = −v0. Envelope rate
    //ζω = 6.6/duration — the fit behind UIKit's duration+dampingRatio initializer, and the
    //constant the profile's own physical spring was built from (its ζ=1 stiffness/damping
    //reduce to exactly this critical form).
    private func springRemaining(t: TimeInterval, duration: TimeInterval,
                                 zeta: CGFloat, v0: CGFloat) -> CGFloat {
        let zw = 6.6 / max(duration, 0.01)
        if zeta >= 0.999 { //Critically damped
            return CGFloat(exp(-zw * t)) * (1 + CGFloat(zw * t) - v0 * CGFloat(t))
        }
        let w = zw / Double(zeta)
        let wd = w * (1 - Double(zeta * zeta)).squareRoot()
        let c2 = (CGFloat(zw) - v0) / CGFloat(wd)
        return CGFloat(exp(-zw * t)) * (cos(CGFloat(wd * t)) + c2 * sin(CGFloat(wd * t)))
    }

    //FROZEN frames, deliberately: the anchor must be flight-invariant — computed from the
    //live measurement it drifts with every posed frame and the pose compounds on itself
    private func dragAnchor(_ size: CGSize, _ origin: CGPoint) -> UnitPoint {
        guard targetImageFrame.height > 1, size.width > 1, size.height > 1 else { return .center }
        return UnitPoint(x: (targetImageFrame.midX - origin.x) / size.width,
                         y: (targetImageFrame.midY - origin.y) / size.height)
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    private func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
        CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
               width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
    }
}

//Different Views and Components
extension SendInviteContainer {

    //The image chrome's drag dissolve: gone exactly at the dismiss threshold, so by the time
    //a release would commit the close the card has already shed its dressing; a cancelled
    //release rides the snap-back spring home (dragProgress unwinds inside its withAnimation).
    //On a committed dismiss the unwind of dragProgress would fade this back IN — chromeIn
    //drops in the same commit, and the pop's zero multiplies it away.
    private var dragChromeFade: Double {
        1 - Double(min(dragProgress / InviteDragTuning.dismissThreshold, 1))
    }

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
            //The chrome pops in on its own .transition clock from the flight's first frame, so
            //it grows with the card rather than landing on it. The title's blur halo still waits
            //for the pager (shaders never fly) and fades in at landing. No flight in a no-flight mount.
            chromeVisible: chromeIn,
            showsPager: landed, //The heavy pager mounts only at rest, over the held covers…
            pagerFade: pagerReveal, //…and fades in above them, so the bottom blur arrives smoothly…
            pagerInteractive: coversDropped && !dragging, //…can't page until they're gone (double-exposure), and never while the dismiss drag owns the card
            chromeOpacity: dragChromeFade,
            nameFlying: nameHeroActive, //The hero text owns the name; the title keeps a layout ghost
            titleNameSlot: $titleNameSlot, //Flight-invariant offsets — no drag/flight freezing needed
            declineProfile: declineProfile,
            clearInvite: {withAnimation(.dissolve) { vm.deleteEventDefault() } }
        )
        //The seam wash the pager's bottom fuzz dissolves into lives in carouselLayer, UNDER
        //the flight covers — present from mid-flight, immune to the reveal (an above-covers
        //wash pulsed the whole photo ~11% while the pager was fraction-opaque, sim-measured),
        //and covered naturally by the opaque covers on every close path.
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

    //Resolves the hero's baked band and halo: a no-op when init already seeded them from the
    //warm cache; otherwise InviteBandBake.warm bakes off-main (the cold fallback — the bakes
    //land a frame or two into the flight and fade in via their own scopes). Re-runs when the
    //hero's identity changes (a seed image swapped for the loaded set mid-presentation).
    //Plain assignments, deliberately: both layers are always mounted, so landing a bake is a
    //leaf content swap — no view is ever inserted mid-flight.
    private func bakeHeroBlur() async {
        guard let hero = images.first else { return }
        guard bakedHero != hero || bakedHalo == nil else { return } //Init-seeded from a warm entry
        if bakedHero != hero { bakedHalo = nil } //A swapped hero drops the stale halo while the rebake runs
        await InviteBandBake.warm(for: hero, name: name)
        guard images.first == hero, let entry = InviteBandBake.cached(for: hero) else { return } //A newer hero owns the slot; its own task rebakes
        blurredHero = entry.band
        bakedHero = hero //bakeReady flips in the same commit — one fade via bandVisible's scope
        if entry.haloName == name { bakedHalo = entry.halo }
    }

    //Gone until the flight lands its chrome, on the confirm screen, while the FINGER owns
    //the card, and while the time or type popup owns it. Keyed on finger ownership, not
    //motion: `dragOffset == .zero` popped it only after the card was already moving (the
    //button visibly rode the pose through its own fade) and kept it away through the whole
    //snap-back spring — it pops the instant a drag begins and returns the instant a
    //cancelled release lets go (the cancel spring plays with it back on screen).
    private var backButton: some View {
        let fingerDragging = dragging && gestureFlight == nil
        let visible = shown && chevronIn && !fingerDragging && !(ui.showConfirmScreen ?? false) && !ui.isPopupOpen()

        return BottomBackButton(visible: visible) { closeInvite() }
            .animation(.transition, value: visible) //Scoped here: keying the ZStack on activePopup would retime the menu morphs
    }

    //The chevron's stationary home: the ghost's slot in the landed column, derived from the
    //frozen card frame so it holds position even while the card flies
    @ViewBuilder
    private func stationaryBackButton(_ origin: CGPoint) -> some View {
        if targetCardFrame.height > 1 {
            backButton
                .offset(y: targetCardFrame.maxY - origin.y + Spacing.xl)
        }
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

//MARK: Gesture-flight primitives — the ported profile dismissal's driver types

//One gesture flight's parameters: the dive beat (arc only) and the spring beat (settle,
//collapse, or cancel), all closed-form — the driver evaluates them per frame and writes the
//drag model, so the model is always the presentation (catchable, deterministic).
struct GestureFlight {
    var start: CFTimeInterval = 0
    //Dive beat (zero duration = no dive)
    var diveDuration: TimeInterval = 0
    var omega: Double = 0
    var origin: CGSize = .zero          //Release translation, finger space
    var launch: CGPoint = .zero         //Impulse launch velocity (finger space)
    //Spring beat
    var springDuration: TimeInterval = 0
    var zeta: CGFloat = 1               //1 = the physical critical settle; 0.8 = the fitted collapse family
    var v0: CGFloat = 0                 //Toward-target fraction/s (UIKit's initialVelocity convention)
    var fromProgress: CGFloat = 0       //Pose to unwind from
    var fromOffset: CGSize = .zero
    var raceFrom: CGFloat = 0           //The mask race's start (chromeMix at commit)
    var raceDuration: TimeInterval = 0  //0 = already raced closed (post-dive)
    var isCancel = false                //Home = the presented card instead of the slot
    var total: TimeInterval = 0         //Whole-flight span (dive + settle) — the watchdog's clock
}

//A minimal display-link pump: ticks the wall clock into a closure. Explicit ProMotion range,
//like the profile's dive link — without it iOS schedules 60Hz on 120Hz panels and the
//scrubbed beats render at half the rate the rest of the UI does.
final class GestureFlightLink {
    private var link: CADisplayLink?
    private var onTick: ((CFTimeInterval) -> Void)?

    func start(_ tick: @escaping (CFTimeInterval) -> Void) {
        stop()
        onTick = tick
        let link = CADisplayLink(target: self, selector: #selector(step))
        #if !targetEnvironment(simulator)
        //ProMotion: without an explicit range iOS schedules 60Hz on 120Hz panels. The
        //SIMULATOR is the opposite: requesting a floor its host display can't honor drops
        //the link to ~25Hz (measured) — leave it at the default there.
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
        #endif
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
        onTick = nil
    }

    @objc private func step(_ link: CADisplayLink) { onTick?(link.timestamp) }
}

//MARK: Warm-bake cache — the flight's band and title halo must be there on frame one

//Bakes of the hero's bottom blur AND the title's halo, warmed at meet-card load
//(ProfileCard) and consulted synchronously in SendInviteContainer.init. Without the warm
//entry the bakes land mid-flight and fade in late — the squashed source band covering the
//band's wait was the residual double image, and the live halo mounting at the reveal was
//the title backdrop's after-landing change (device frames, 2026-08-13). Keyed by image
//identity: the loaded profile images are stable instances. Capped small — the band bake is
//full-resolution.
@MainActor
enum InviteBandBake {

    struct Entry {
        let band: UIImage
        let halo: UIImage? //Bottom strip only (BackgroundBlur.bakedStripHeight), pinned bottomLeading
        let haloName: String //The halo is anchored to the title's word rects — a different name needs a rebake
    }

    private static var cache: [ObjectIdentifier: Entry] = [:]
    private static var order: [ObjectIdentifier] = []
    private static let capacity = 6

    static func cached(for image: UIImage) -> Entry? { cache[ObjectIdentifier(image)] }

    ///Bake ahead of any tap; a no-op when the image is already warm for this name
    static func warm(for image: UIImage, name: String) async {
        if let entry = cached(for: image), entry.haloName == name { return }
        let aspect = AspectRatio.invitedImage.ratio
        let width = UIScreen.main.bounds.width - InviteCardBackground.horizontalInset * 2
        let slot = CGSize(width: width, height: width / aspect)
        let scale = UIScreen.main.scale
        let frames = InviteImageCarousel.titleFrames(name: name, in: slot) //Font metrics on the main actor
        let existingBand = cached(for: image)?.band //A name change reuses the band
        let baked = await Task.detached(priority: .userInitiated) { () -> (UIImage?, UIImage?) in
            let band = existingBand ?? InvitePagePhoto.bakedBottomBlur(for: image, aspect: aspect, displayWidth: width, scale: scale)
            let halo = BackgroundBlur.bakedHalo(for: image, slot: slot, frames: frames, scale: scale)
            return (band, halo)
        }.value
        guard let band = baked.0 else { return }
        let key = ObjectIdentifier(image)
        if cache[key] == nil { order.append(key) }
        cache[key] = Entry(band: band, halo: baked.1, haloName: name)
        if order.count > capacity, let evicted = order.first {
            order.removeFirst()
            cache[evicted] = nil
        }
    }
}

//MARK: InviteZoom — presents the invite popup on the root plane, growing out of a source image

//The flight's drivers for the source chrome copy's per-element exits; defaults are the resting
//card wearing its full chrome. The chrome itself distributes them (ProfileCard.cardOverlay):
//the scrim + name wear `inviteChromeFade`, the subtitle and invite icon pop on
//`inviteChromeExiting` and multiply by `inviteChromeCollapse` so the close reveals them in
//step with the flight home. `inviteChromeArrived` mirrors the destination chrome's arrival:
//the card's blur band rides the flight at full strength until it flips, then crossfades
//against the invite card's baked bottom blur — one continuous blur, reshaping.
extension EnvironmentValues {
    @Entry var inviteChromeFade: Double = 1
    @Entry var inviteChromeCollapse: Double = 1
    @Entry var inviteChromeExiting: Bool = false
    @Entry var inviteChromeArrived: Bool = false
    //A GESTURE close's band return, geometry-derived: 0 through the flight, ramping to 1
    //over the final approach (closeP 0.7→1), where the flying rect has nearly converged to
    //the source and the band copy's transform-squash is ~identity. Driver-scrubbed, so it
    //tracks the spring exactly and lands at 1 in the unmount commit. The tap close keeps
    //the event-flip fade (this stays 0 there).
    @Entry var inviteChromeCloseRamp: Double = 0
    @Entry var inviteChromeNameFlying: Bool = false //The hero text layer owns the name for the whole presentation — the chrome copy's name never renders
}

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
    private(set) var sourceName: CGRect = .zero //The resting name's frozen frame — the hero text flight's source anchor

    @ObservationIgnored private var sourceRects: [String: CGRect] = [:]

    func reportSource(id: String, rect: CGRect) { sourceRects[id] = rect }

    func present(id: String, sourceChrome: @escaping () -> AnyView, sourceNameRect: ((CGRect) -> CGRect)?, view: @escaping () -> AnyView) {
        if let current = slot, current.id != id { clear(id: current.id) } //Handoff: presenting over a closing card evicts it
        guard slot == nil else { return } //A same-id re-present (a remount's initial onChange) is a no-op
        source = sourceRects[id] ?? .zero //Freeze the tapped card's frame for this flight
        //DERIVED from the frozen rect, never measured — a measured anchor proved lossy on device
        sourceName = source.width > 1 ? (sourceNameRect?(source) ?? .zero) : .zero
        slot = Slot(id: id, view: view, sourceChrome: sourceChrome)
    }

    //Id-guarded so a stale clear can't drop a newer card
    func clear(id: String) {
        guard slot?.id == id else { return }
        slot = nil
        source = .zero
        sourceName = .zero
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
    let sourceNameRect: ((CGRect) -> CGRect)?
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
                    presenter.present(id: id, sourceChrome: { AnyView(sourceChrome()) }, sourceNameRect: sourceNameRect) { AnyView(popup()) }
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
    ///card. `sourceChrome` is a copy of the card chrome drawn over the flying image: it must
    ///read the `inviteChrome…` environment drivers to exit over the open and ride the collapse
    ///back in (ProfileCard.cardOverlay is the reference). `sourceNameRect` derives the resting
    ///name's frame from the frozen card rect — the hero text flight's source anchor.
    func inviteZoom(
        id: String,
        isPresented: Binding<Bool>,
        @ViewBuilder sourceChrome: @escaping () -> some View,
        sourceNameRect: ((CGRect) -> CGRect)? = nil,
        @ViewBuilder popup: @escaping () -> some View
    ) -> some View {
        modifier(InviteZoomModifier(id: id, isPresented: isPresented, sourceChrome: sourceChrome, sourceNameRect: sourceNameRect, popup: popup))
    }

    ///For a plain image source with no chrome to fade (the debug harness, a bare photo)
    func inviteZoom(
        id: String,
        isPresented: Binding<Bool>,
        @ViewBuilder popup: @escaping () -> some View
    ) -> some View {
        modifier(InviteZoomModifier(id: id, isPresented: isPresented, sourceChrome: { EmptyView() }, sourceNameRect: nil, popup: popup))
    }
}
