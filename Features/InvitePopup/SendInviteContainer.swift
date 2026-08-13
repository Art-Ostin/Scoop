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
    static let openFlight = Animation.spring(Spring(duration: 0.34, bounce: 0.2)) //ProfileZoom's open clock stretched ~12% (was 0.4s, 2026-08-10): a gentle settle instead of smooth's front-loaded rush
    static let closeFlight = Animation.smooth(duration: 0.28)
    static let chromeRace = Animation.smooth(duration: 0.15)
    static let sourceChromeExit = Animation.smooth(duration: 0.12) //The meet-card chrome copy only needs to cover frame 1 — then it's out of the flight's way
    static let snapBackSpring = Spring(duration: 0.3, bounce: 0.3) //ProfileZoom's cancel clock, with enough bounce to read (SwiftUI springs damp far harder than UIKit's for the same ratio — Spring.value-probed)
    static let diveFlight = Spring(duration: 0.45, bounce: 0.4) //A committed drag: the carried velocity dives the card past the slot and the spring expands it back in (the profile's landing)
    static let settleFlight = Spring(duration: 0.4, bounce: 0.12) //Button close / slow release: a gentle settle onto the slot

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

    //Interactive dismiss tuning (see dismissDrag) — the numbers ProfileZoom's drag proved out
    static let collapseDistance: CGFloat = 300 //Vertical drag that scrubs the collapse 0→1
    static let dismissThreshold: CGFloat = 0.3 //Release past this progress (or a downward flick) dismisses
    static let minDragScale: CGFloat = 0.82 

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
    @State private var pagerReveal: Double = 0 //The live pager's landing crossfade: faded in over the HELD covers, so the pages' bottom blur arrives smoothly
    @State private var coversDropped = false //Paging latch: a swipe over a held cover double-exposes two photos, so the pager stays inert until the covers are gone
    @State private var blurCover: Double = 0 //The snapshot cover's glur: 1 only at close start (pager-identical), gone in 0.15s — shaders never fly. The hero cover needs none: its baked band layer is already pager-identical
    @State private var sourceChromeFade: Double = 1 //Caps the chrome copy's opacity: rushed to 0 at open start, reset for the collapse
    @State private var chromeIn = false //Destination image chrome (title, options, dots): pops in from the flight's first frame, out at close start
    @State private var bandIn = true //The baked band belongs to the card from its FIRST committed frame (warm bake) — unlike the chrome it must not wait for the launch commit; it exits with the chrome at close start
    @State private var sourceChromeExiting = false //Drives the source copy's per-element exits (subtitle blur-pop, invite-icon pop) via the inviteChrome environment
    @State private var titleNameSlot: CGRect = .zero //The title name's flight-invariant offsets (leading inset / bottom inset / 22pt size) — the hero's destination derives from these + the frozen carousel target, never from a measured mid-flight position
    @State private var nameLanded = false //Hands the name from the hero text to the real title, a beat after land() so the spring's last sub-pixel settle can't jump the swap
    @State private var heroFadesWithCollapse = false //A close from the confirm screen has no visible title to leave from — the name rides in with the chrome copy instead
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
    private var chromeMix: CGFloat { max(dragProgress, chromeRaceP) }

    private var currentScreen: InviteScreen { ui.showConfirmScreen == true ? .sendConfirm : .send }
    private var currentImageAspect: AspectRatio {
        ui.showConfirmScreen == true ? .confirmInviteImage : .invitedImage
    }

    //The bake is usable only while it matches the current hero — a mid-presentation image
    //swap (seed → loaded set) makes it stale until the rebake lands
    private var bakeReady: Bool { blurredHero != nil && bakedHero == images.first }

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
                nameFlightLayer(origin)
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
            backButton
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
        //The wash backstop: the tinted layers all ride the FLYING rect (the carousel wash) or
        //sit below the slot (the rows' seam gradient), so a bouncy open that overshoots the
        //image above its slot exposed a strip of bare appCanvas — a white flash at the
        //overshoot peak (device frames, 2026-08-13). Painting the slot with the seam's own
        //tint makes any overshoot gap read as the wash instead; at rest the opaque image
        //covers it completely.
        palette.secondaryText.opacity(0.45)
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
                //glur, so the stretched source band must not fade back in over it.
                .environment(\.inviteChromeArrived, chromeIn && (bakeReady || landed))
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
            chromeIn = true
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
        sourceChromeExiting = true
        withAnimation(Self.sourceChromeExit) { sourceChromeFade = 0 }
        chromeIn = true //Leads the flight, as on the first open
        withAnimation(Self.chromeRace) { blurCover = 0 } //A reopen inside the close's first beats must not fly the snapshot's live glur at partial opacity
        withAnimation(Self.openFlight) {
            expanded = true
            closeP = 0
            chromeRaceP = 0
        }
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
            //The chrome pops in on its own .transition clock from the flight's first frame, so
            //it grows with the card rather than landing on it. The title's blur halo still waits
            //for the pager (shaders never fly) and fades in at landing. No flight in a no-flight mount.
            chromeVisible: chromeIn,
            showsPager: landed, //The heavy pager mounts only at rest, over the held covers…
            pagerFade: pagerReveal, //…and fades in above them, so the bottom blur arrives smoothly…
            pagerInteractive: coversDropped, //…but can't page until they're gone (double-exposure)
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
