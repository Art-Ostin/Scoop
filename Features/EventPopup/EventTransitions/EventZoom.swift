//
//  EventZoom.swift
//  Scoop
//
//  Created by Art Ostin on 31/08/2026.
//

import SwiftUI

//MARK: - The API
//
//  Three modifiers present an event card the way the History ledger does: the tapped image
//  lifts off and morphs into the pager's band while the card grows out of it; the swipe-down,
//  the chevron and the backdrop fly it home.
//
//      SomeScreen                                 // once per plane root (AppContainer's ZStack
//          .eventZoomHost(eventZoomHost)          // mounts EventZoomLayer as a sibling instead)
//
//      AppImage(image: photo, type: .meet)
//          .eventZoomSource(photo) { cardChrome } // the image that lifts off (+ a copy of its chrome)
//          .eventZoom(isPresented: $show) {       // the card, grown out of the nearest source
//              ComposeInviteContainer(...)
//          }
//
//  The card body is content only — the frosted backdrop, the white surface, the stationary
//  chevron and the dismiss drag are this file's. A body reaches back with
//  `.eventZoomChevronHidden(_:)`, `.eventZoomDragLocked(_:)`, `.eventZoomDragExclusion()`,
//  `.eventZoomBandChrome()` and `@Environment(\.eventZoomDismiss)`; all of them are no-ops when
//  the body renders without a flight.

extension View {

    ///Installs the plane every `.eventZoom` beneath this view presents on: the card overlays this
    ///view, above its own chrome, and the host is handed down through the environment. Mount it
    ///once at a plane root — a screen presented as its own cover (History) must install its own,
    ///because the app root's host leaks into covers but renders behind them. A screen using this
    ///overlay form must have no text input of its own (see the keyboard rule on the modifier).
    func eventZoomHost(_ host: EventZoomHost) -> some View {
        modifier(EventZoomHostModifier(host: host))
    }

    ///Marks the image that lifts off: its pixels become the flying cover, its global frame the
    ///flight's home, and `shape` its rounding — `.circle(ring:)` for a glass lens (the close
    ///regrows a ring of that width under the landing photo), `.rounded` for a card. The view
    ///hides for the whole presentation, so the photo is never drawn twice.
    func eventZoomSource(_ image: UIImage, shape: EventZoomSourceShape = .rounded()) -> some View {
        modifier(EventZoomSourceModifier(image: image, shape: shape, chrome: nil))
    }

    ///As above, for a source that draws chrome over its image (a name, a blur band, a button):
    ///`chrome` is a copy of it, laid out once at the source's size, riding the flying cover and
    ///fading out over the open's first beat — so the card's chrome never cuts away under the
    ///lifting photo. Build it as its own View struct: environment reads inside it resolve on the
    ///flight's plane, not the card's.
    func eventZoomSource<Chrome: View>(_ image: UIImage, shape: EventZoomSourceShape = .rounded(),
                                       @ViewBuilder chrome: @escaping () -> Chrome) -> some View {
        modifier(EventZoomSourceModifier(image: image, shape: shape, chrome: { AnyView(chrome()) }))
    }

    ///Presents `card` grown out of the `.eventZoomSource` inside this view when `isPresented`
    ///flips true, and flies it home when it flips false (a Send or an Accept), on the chevron, on
    ///a backdrop tap, or on the card's swipe-down. The binding is written back false only when the
    ///close flight has landed, so a call site never sees the card unmount mid-air. `inset` is the
    ///card's gap to the screen edge, `Spacing.gutter` unless a caller says otherwise — passed in
    ///rather than reached back for, because the card lays out and the cover bakes at mount, a
    ///frame before any reach-back lands.
    func eventZoom<Card: View>(isPresented: Binding<Bool>, inset: CGFloat = Spacing.gutter,
                               @ViewBuilder card: @escaping () -> Card) -> some View {
        modifier(EventZoomModifier(isPresented: isPresented, inset: inset, card: { AnyView(card()) }))
    }

    ///A card body's confirm screen hides the shell's chevron (its own back button takes over)
    func eventZoomChevronHidden(_ hidden: Bool = true) -> some View {
        modifier(EventZoomChevronHiddenModifier(hidden: hidden))
    }

    ///While a body's own popup owns the finger (the type or time menu's drag-select), the shell's
    ///dismiss drag stands down and the chevron leaves with it
    func eventZoomDragLocked(_ locked: Bool) -> some View {
        modifier(EventZoomDragLockedModifier(locked: locked))
    }

    ///A control that owns its touch-down (the wide CTA): a drag that starts on it never scrubs the
    ///card
    func eventZoomDragExclusion() -> some View {
        modifier(EventZoomDragExclusionModifier())
    }

    ///Chrome laid over the pager band (a top row, a back button, the page dots) sits under the
    ///flying cover for the whole open; this pops it in the moment the cover hands off to the live
    ///pager instead of letting the hand-off cut reveal it. `visible` is the piece's OWN page
    ///condition, ANDed in here so each piece wears ONE pop on ONE clock: the flight can only ever
    ///subtract, and a page flip made while the cover is still up replays as a single pop.
    func eventZoomBandChrome(visible: Bool = true) -> some View {
        modifier(EventZoomBandChromeModifier(onPage: visible))
    }
}

///The source's rounding. `.circle` keeps deriving its radius from the CURRENT size as the cover
///grows — a clock-lerped radius reads app-icon-rectangular right beside the lens.
enum EventZoomSourceShape: Equatable {
    case circle(ring: CGFloat = 0)
    case rounded(CGFloat = CornerRadius.image)

    var ring: CGFloat {
        if case .circle(let ring) = self { ring } else { 0 }
    }

    func radius(for size: CGSize) -> CGFloat {
        switch self {
        case .circle: min(size.width, size.height) / 2
        case .rounded(let radius): radius
        }
    }
}

///`@Environment(\.eventZoomDismiss)` inside a card body: flies the card home. A no-op when the
///body renders without a flight.
struct EventZoomDismissAction {
    var action: () -> Void = {}
    func callAsFunction() { action() }
}

extension EnvironmentValues {
    @Entry var eventZoomDismiss = EventZoomDismissAction()
}

//MARK: - The host: one per plane, owned by the plane root

///The slot a plane presents into. Owned as `@State` by the plane root, which reads `isPresenting`
///and `chromeHidden` for its own chrome — a container cannot read an environment value it injects.
@MainActor @Observable final class EventZoomHost {

    struct Slot {
        let id: UUID //The anchor's — a card is identified by the modifier that presented it
        let anchor: EventZoomAnchor
        let inset: CGFloat //The card's gap to the screen edge — its padding AND the cover bake's width
        let card: () -> AnyView
        let dismiss: () -> Void //Writes the call site's binding false once the flight has landed
    }

    private(set) var slot: Slot?

    ///The screen's own chrome stands down from present() until a beat into the close — the flight
    ///writes it, and a fresh presentation takes the corner back
    private(set) var chromeHidden = false

    var isPresenting: Bool { slot != nil }

    func present(anchor: EventZoomAnchor, inset: CGFloat, card: @escaping () -> AnyView, dismiss: @escaping () -> Void) {
        if let live = slot, live.id != anchor.id { clear(live) } //Handoff: presenting over a closing card evicts it
        guard slot == nil else { return } //A same-anchor re-present (a retained view re-appearing: its initial onChange) is a no-op — a view that LOSES identity brings a new anchor and is evicted above, the same cut its onDisappear delivers
        anchor.setVacated(true) //Before the card mounts, so the cover's first frame sits on an already-vacated slot
        if !chromeHidden { chromeHidden = true }
        slot = Slot(id: anchor.id, anchor: anchor, inset: inset, card: card, dismiss: dismiss)
    }

    ///The call site's binding went false: the card flies home (or, if it never mounted, just goes)
    func close(anchor: EventZoomAnchor) {
        guard let slot, slot.id == anchor.id else { return }
        guard let requestClose = anchor.requestClose else { return clear(slot) } //Never mounted: nothing to fly home
        _ = requestClose(false) //Already closing: the flight in progress lands and clears on its own
    }

    ///The source left the screen (a listener pruned its row, a tab switch): there is nothing to
    ///fly home to, so a mounted card leaves by fade — and one already flying home is cut, its
    ///landing target gone
    func clear(anchor: EventZoomAnchor) {
        guard let slot, slot.id == anchor.id else { return }
        if let requestClose = anchor.requestClose, requestClose(true) { return }
        clear(slot)
    }

    //The flight's three beats, each guarded on the slot that scheduled it: an evicted or hard-cut
    //card's still-scheduled callbacks land on nothing. `unmounted()` stops only the wind clock —
    //the choreo's Tasks and spring completions still fire, and these guards are what silence them.

    func returning(for slot: Slot) {
        guard self.slot?.id == slot.id else { return }
        slot.anchor.setReturning(true)
    }

    func chromeReturned(for slot: Slot) {
        guard self.slot?.id == slot.id else { return }
        if chromeHidden { chromeHidden = false }
    }

    func closed(_ slot: Slot) {
        guard self.slot?.id == slot.id else { return }
        clear(slot)
    }

    private func clear(_ slot: Slot) {
        slot.anchor.setVacated(false) //The photo is home: the source takes its pixels back in the same commit
        slot.anchor.setReturning(false)
        slot.anchor.requestClose = nil
        self.slot = nil
        if chromeHidden { chromeHidden = false }
        slot.dismiss() //After the slot is gone: the binding's onChange then finds nothing to close
    }
}

///The plane's card, mounted the moment a slot is filled and unmounted in the commit the flight
///lands. Mount it as a root ZStack sibling above the TabView (AppContainer) — `.eventZoomHost`
///wraps it for a screen that overlays it on itself.
struct EventZoomLayer: View {

    //Injected
    let host: EventZoomHost

    var body: some View {
        if let slot = host.slot {
            EventZoomCard(slot: slot, host: host)
                .id(slot.id)
                .ignoresSafeArea(.keyboard) //A sheet's keyboard must not shift the card on its plane
        }
    }
}

private struct EventZoomHostModifier: ViewModifier {

    //Injected
    let host: EventZoomHost

    func body(content: Content) -> some View {
        content
            .overlay { EventZoomLayer(host: host) }
            //AFTER the overlay: the one placement measured to keep a sheet's keyboard from
            //sliding an overlaid card up — the overlay is centred in the host's region, and a
            //host that shrinks for the keyboard moves the card's origin before the card's own
            //ignore can undo it. Safe only because a screen using this form has no text input.
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .environment(host)
    }
}

//MARK: - The anchor: what one `.eventZoom` knows about its source

///One per `.eventZoom` modifier, handed to the `.eventZoomSource` beneath it through the
///environment. The source writes its frame every layout pass and its pixels, shape and chrome
///copy every body pass — none of it observed, so a scrolling ledger never invalidates anything.
///What IS observed is the pair the source draws from: `vacated` (the image hides for the whole
///presentation) and `returning` (a committed close is flying home — a lens hides its static ring
///while the flight's own glass regrows it).
@MainActor @Observable final class EventZoomAnchor {

    let id = UUID()

    private(set) var vacated = false
    private(set) var returning = false

    @ObservationIgnored var rect: CGRect = .zero //Global — the flight's home
    @ObservationIgnored var image: UIImage?
    @ObservationIgnored var shape: EventZoomSourceShape = .rounded()
    @ObservationIgnored var chrome: (() -> AnyView)?
    @ObservationIgnored var requestClose: ((_ flightless: Bool) -> Bool)? //Set by the mounted card; the host closes through it — false back means a close is already flying

    func setVacated(_ vacated: Bool) {
        if self.vacated != vacated { self.vacated = vacated }
    }

    func setReturning(_ returning: Bool) {
        if self.returning != returning { self.returning = returning }
    }
}

private struct EventZoomSourceModifier: ViewModifier {

    //Injected
    @Environment(EventZoomAnchor.self) private var anchor: EventZoomAnchor?
    let image: UIImage
    let shape: EventZoomSourceShape
    let chrome: (() -> AnyView)?

    func body(content: Content) -> some View {
        //Refreshed every pass (unobserved, so the writes cost nothing): present() takes what the
        //source's LATEST body built. A chrome copy captured once at appearance would wear the
        //placeholder palette — the real one lands a frame late.
        anchor?.image = image
        anchor?.shape = shape
        anchor?.chrome = chrome
        return content
            .opacity(anchor?.vacated == true ? 0 : 1) //The flight IS the image while a card is up
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { anchor?.rect = $0 }
    }
}

private struct EventZoomModifier: ViewModifier {

    //Injected
    @Environment(EventZoomHost.self) private var host: EventZoomHost?
    @Binding var isPresented: Bool
    let inset: CGFloat
    let card: () -> AnyView

    //Local view state
    @State private var anchor = EventZoomAnchor()

    func body(content: Content) -> some View {
        content
            .environment(anchor)
            .onChange(of: isPresented, initial: true) { _, presented in
                guard let host else { return }
                if presented {
                    host.present(anchor: anchor, inset: inset, card: card) { isPresented = false }
                } else {
                    host.close(anchor: anchor)
                }
            }
            .onDisappear { host?.clear(anchor: anchor) } //A source that unmounts while presented hard-cuts its card
    }
}

//MARK: - The body's reach-backs

private struct EventZoomChevronHiddenModifier: ViewModifier {

    //Injected
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    let hidden: Bool

    func body(content: Content) -> some View {
        content.onChange(of: hidden, initial: true) { _, hidden in flight?.setChevronHiddenByCard(hidden) }
    }
}

private struct EventZoomDragLockedModifier: ViewModifier {

    //Injected
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    let locked: Bool

    func body(content: Content) -> some View {
        content.onChange(of: locked, initial: true) { _, locked in flight?.setDragLocked(locked) }
    }
}

private struct EventZoomDragExclusionModifier: ViewModifier {

    //Injected
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?

    //Local view state
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight?.reportDragExclusion(id: id, rect: $0) }
            .onDisappear { flight?.reportDragExclusion(id: id, rect: nil) }
    }
}

private struct EventZoomBandChromeModifier: ViewModifier {

    //Injected
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    let onPage: Bool //The piece's own page condition; the flight only ever subtracts

    func body(content: Content) -> some View {
        let visible = onPage && (flight?.bandChromeVisible ?? true)
        return content
            .opacityPop(visible: visible)
            .allowsHitTesting(visible) //Opacity 0 still takes taps under the cover
            .animation(.transition, value: visible) //Its OWN scope: the hand-off and close start are bare or instant writes on purpose
    }
}

//MARK: - The presented card: the flight's host

//Mounted the moment the host's slot fills, and unmounted in the same commit the flight lands
//back on the source. The anchor is read ONCE here, at mount: the tap wrote it before the
//selection, and the flight must not follow a later edit of it.
private struct EventZoomCard: View {

    //Injected
    let slot: EventZoomHost.Slot
    let host: EventZoomHost

    //Local view state
    @State private var flight: EventZoomChoreo
    @State private var containerTop: CGFloat = 0 //This view's global origin — the stationary chevron's slot arrives in global space
    private let dismiss: EventZoomDismissAction //Built once with the choreo: a fresh closure per frame would re-run every body reading it

    init(slot: EventZoomHost.Slot, host: EventZoomHost) {
        self.slot = slot
        self.host = host
        let choreo = EventZoomChoreo(
            anchor: slot.anchor,
            inset: slot.inset, //The bake needs the card's real width, and the frame it measures is a layout pass late
            //A committed close is flying home: a lens' static ring hides (a bare write, behind the
            //still-full backdrop) so the flight's expanding glass owns the slot
            onClosing: { host.returning(for: slot) },
            //A beat further into that close: the chevron has popped away and the backdrop's
            //frost has lifted, so the corner is clear and the screen's own chrome comes back
            //over the still-flying card
            onChromeReturn: { host.chromeReturned(for: slot) },
            //The close flight has landed on the source — its overshoot settle IS the landing
            //beat — so the card unmounts and the source returns in the same commit, identical pixels
            onClosed: { host.closed(slot) })
        _flight = State(initialValue: choreo)
        dismiss = EventZoomDismissAction { [weak choreo] in choreo?.close() }
    }

    var body: some View {
        ZStack {
            EventBackdropV2()
                .opacity(flight.backdropOpacity)
                .onTapGesture { flight.close() }

            VStack(spacing: Spacing.xl) {
                card
                EventDismissButton(visible: false) { } //A layout ghost: reserves the chevron's slot in the column, which the drag and the flight carry
            }
            .offset(flight.cardOffset)
            .simultaneousGesture(flight.dismissDrag)
        }
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { containerTop = $0 }
        .overlay(alignment: .top) { stationaryChevron }
        .task { await flight.bakeCoverBand() }
        .onAppear {
            let flight = flight
            slot.anchor.requestClose = { [weak flight] flightless in flight?.close(flightless: flightless) ?? false } //How the host closes this card when the binding drops, or its source vanishes
        }
        .onDisappear { flight.unmounted() }
    }
}

extension EventZoomCard {

    //The caller's card wearing the flight: the morph's window owns its rounding, and the shadow
    //is worn AFTER the mask so it wears the window's shape. The content is its own equatable
    //view, so the wrapper's per-frame reads (drag, wind ticks) never re-run the body the caller
    //supplied — that body re-evaluates only when data IT observes changes (images loading in).
    private var card: some View {
        EventZoomCardContent(id: slot.id, bandChromeVisible: flight.bandChromeVisible, card: slot.card)
            .equatable()
            .environment(flight) //How the pager gates its live mount, reports its band and title, and how the body reaches back
            .environment(\.eventZoomDismiss, dismiss)
            .background(Color.white)
            .modifier(flight.morph())
            .shadow(.card, strength: flight.shadowStrength)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight.reportCard($0) }
            .padding(.horizontal, slot.inset) //The card is a full-bleed surface, not a text column
    }

    //The chevron never rides the drag or the flight: it renders ABOVE the moving column, at the
    //resting card's foot
    @ViewBuilder
    private var stationaryChevron: some View {
        if flight.hasChevronSlot {
            EventDismissButton(visible: flight.chevronVisible) { flight.close() }
                .offset(y: flight.chevronSlotY - containerTop)
        }
    }
}

private struct EventZoomCardContent: View, Equatable {

    //Injected
    let id: UUID
    //Part of the card's identity, and the ONLY per-open flight state that is: the band's chrome
    //arms a beat after the landing, and an equality that ignored it would swallow that
    //invalidation — the body would keep a stale `false` and the dots, the menu and the back
    //button would each appear only if something else happened to re-render the card. It flips
    //once per open, never per frame, so the 120Hz protection below is untouched.
    let bandChromeVisible: Bool
    let card: () -> AnyView

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.bandChromeVisible == rhs.bandChromeVisible
    }

    var body: some View { card() }
}

//MARK: - The choreography

//The card's entire flight — the choreography `.eventZoom` renders but never drives. The source
//image hides and the card, laid out at rest, is revealed through an expanding window that grows
//out of the source's shape, while the photo morphs from the source into the pager's band above
//it: the invite popup's arrival. Close is the reverse (backdrop tap, chevron, or the card's
//swipe-down), the window wiping the card away as it shrinks home onto the source — and a FLICKED
//close flies the shared wind trajectory (WindFlightPlan), the profile dismissal's exact physics,
//landing on the source with its emergent bounce while the backdrop fades on the pace clock. The
//card reads only the surface in the first extension; every clock, gesture, and per-frame pose
//lives below it.
@MainActor @Observable final class EventZoomChoreo {

    //Injected
    private let anchor: EventZoomAnchor //Re-read only at a landed close, for where the source is NOW
    private var source: CGRect //The source's frame in global space — the flight's home
    private let shape: EventZoomSourceShape //A circle's ring is the glass tier the close regrows; a card has none
    let coverPhoto: UIImage //The source's pixels: the flying cover, and the pager's page when a caller hands it nothing
    private let chrome: AnyView? //The source's chrome, copied once at source size — rides the cover out and back
    private let inset: CGFloat //The card's gap to the screen edge — the cover bakes at that width
    private let onClosing: () -> Void //A committed close is leaving: the owner hides a lens' static ring
    private let onChromeReturn: () -> Void //A beat into the close: the screen's own chrome comes back, while the card is still flying
    private let onClosed: () -> Void //The close flight has landed; the owner clears state

    //Flight state
    private var flightP: CGFloat = 0 //0 = at the source, 1 = the full card
    private var chromeP: Double = 0 //Backdrop and chevron — the pieces outside the card
    private var coverShown = true //The morphing photo: cut away once landed, back instantly at close
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
    private var chevronIn = false //The chevron's late arrival: armed a quarter into the open, so it pops only once the flight reads committed
    private var fingerDown = false //The finger owns the card. Ownership, not motion: the chevron leaves as the drag begins and returns the instant a cancelled release lets go, riding back on screen with the snap-back
    private var title: String? //What the pager draws over its band — the cover draws the same, so the hand-off cut meets identical pixels
    private var bandChromeIn = false //Chrome over the band: in on its own animated write just after the hand-off cut, out with the close
    private var chevronHiddenByCard = false //A body's confirm screen owns the corner with its own back button
    private var dragLocked = false //A body's popup owns the finger: no dismiss scrub, no chevron
    @ObservationIgnored private var dragExclusions: [UUID: CGRect] = [:] //Global frames of controls that own their touch-down

    private let windDriver = WindCloseDriver() //The wind close's clock — the trajectory is time-domain, not a spring target

    init(anchor: EventZoomAnchor,
         inset: CGFloat,
         onClosing: @escaping () -> Void,
         onChromeReturn: @escaping () -> Void,
         onClosed: @escaping () -> Void) {
        self.anchor = anchor
        self.source = anchor.rect
        self.shape = anchor.shape
        self.coverPhoto = anchor.image ?? UIImage()
        self.chrome = anchor.chrome?() //Built ONCE: the same value every frame, so the copy's body never re-runs in flight
        self.inset = inset
        self.onClosing = onClosing
        self.onChromeReturn = onChromeReturn
        self.onClosed = onClosed
    }
}

//The card's read surface — everything the presented card needs, and nothing that moves it
extension EventZoomChoreo {

    //Landed and at rest: the live pager mounts here
    var settled: Bool { landed && !closing }

    //Chrome over the pager band pops in once the cover has cut away — under the cover it would
    //be invisible anyway, and the cut would otherwise reveal it in one frame
    var bandChromeVisible: Bool { settled && bandChromeIn }

    //An engaged dismiss drag freezes the pager's own axis
    var dragEngaged: Bool { dragOffset != .zero }

    //The chevron: in a quarter into the open, gone at close start, for as long as the finger owns
    //the card, while a body's popup owns it, and on a confirm screen that brings its own
    var chevronVisible: Bool { chevronIn && !closing && !fingerDown && !dragLocked && !chevronHiddenByCard }

    //Its stationary home, global — the resting card's foot plus the column's own gap. The
    //chevron never rides the drag or the flight, so the slot has to come from the card at REST:
    //the live frame carries the pose, and the button would fly with it
    var chevronSlotY: CGFloat { restingCard.maxY + Spacing.xl }

    //The slot is only real once the card has been laid out
    var hasChevronSlot: Bool { restingCard.height > 1 }

    //The card's backdrop gives way as the drag commits
    var backdropOpacity: Double { chromeP * (1 - 0.5 * dragProgress) }

    //Both axes follow the finger (the profile/wind dismiss's model): vertical scrubs the fold
    //and commits; horizontal just tracks, banded harder — same constants as the invite
    //popup's ghostModel, both ported from DragTuning
    var cardOffset: CGSize {
        CGSize(width: DragTuning.rubberBand(dragOffset.width, limit: 160, response: 0.8),
               height: rubberBanded(dragOffset.height))
    }

    //Worn after the morph's mask, so the shadow wears the window's shape — and strength rides
    //the flight: the resting source casts nothing of its own here, so the committed source
    //frames must not bloom a shadow. Clamped: the springs' overshoot carries flightP past both
    //ends of [0, 1]
    var shadowStrength: Double { min(max(Double(flightP), 0), 1) }

    //The measured rects report live, drag folded in; the first pair past layout opens
    func reportCard(_ rect: CGRect) {
        //A measured rect lands in ONE step, never eased, so a LANDED card that RESIZES (a body
        //swapping to its confirm screen) needs the write itself to carry the curve — the mask
        //this feeds IS the card's visible edge, and it would otherwise clip the card to its new
        //height a whole curve before the surface eased there. In flight and under the drag the
        //write stays raw: those read the rect live, per frame.
        withAnimation(landed && !closing && !dragEngaged ? .transition : nil) {
            cardRect = rect
            //The chevron's slot takes the RESTING pose only: the live frame folds the drag in, and
            //a committed close keeps that frozen drag for the whole flight home
            if !dragEngaged, !closing { restingCard = rect }
        }
        openWhenMeasured()
    }

    func reportPagerBand(_ rect: CGRect) {
        destRect = rect
        openWhenMeasured()
    }

    func reportTitle(_ title: String) {
        if self.title != title { self.title = title }
    }

    func setChevronHiddenByCard(_ hidden: Bool) {
        if chevronHiddenByCard != hidden { chevronHiddenByCard = hidden }
    }

    func setDragLocked(_ locked: Bool) {
        if dragLocked != locked { dragLocked = locked }
    }

    func reportDragExclusion(id: UUID, rect: CGRect?) {
        dragExclusions[id] = rect
    }

    //The morph, fed this frame's pose
    func morph() -> EventZoomMorph {
        EventZoomMorph(
            p: flightP,
            chromeMix: chromeMix,
            dragTravel: dragOffset.height,
            flightOffset: windRender.offset,
            pop: windRender.pop,
            source: source,
            shape: shape,
            card: cardRect,
            pager: destRect,
            photo: coverPhoto,
            blurredPhoto: blurredCover,
            chrome: chrome,
            title: title,
            coverShown: coverShown)
    }

    //An unmount mid-flight must not leave the link ticking
    func unmounted() { windDriver.stop() }
}

//The flight clocks and choreography. All geometry lives in EventZoomMorph below — an Animatable
//modifier, so the window and the photo re-derive from the interpolated progress EVERY FRAME:
//radii genuinely ride the current size instead of sliding between endpoints.
extension EventZoomChoreo {

    #if DEBUG
    //Geometry-capture runs: -eventZoomSlow stretches every clock 4× for the camera
    static let timeScale: Double = ProcessInfo.processInfo.arguments.contains("-eventZoomSlow") ? 4 : 1
    #else
    static let timeScale: Double = 1
    #endif

    //The quick invite popup's open clock — ProfileZoom's open clock stretched ~12% (was 0.4s,
    //2026-08-10): a gentle settle instead of smooth's front-loaded rush. Taken a touch quicker
    //and springier for this smaller flight; chrome trails it a breath.
    private static let openSpring = Spring(duration: 0.34, bounce: 0.2)
    private static let openDuration = (openSpring.duration - 0.02) * timeScale
    private static let openFlight = Animation.spring(
        duration: openDuration,
        bounce: openSpring.bounce + 0.05)
    private static let openChrome = Animation.spring(
        duration: openSpring.duration * timeScale,
        bounce: openSpring.bounce + 0.05)
    //0.32 FLAT read a tad too snappy on device (2026-08-31) and was taken back out to 0.36; it
    //returns quicker with the landing's bounce restored instead. 0.15 (damping .85) overshoots
    //~0.6% of the flight, and p is the whole source→pager range, so that is ~2pt of inward pulse
    //on the 52pt lens: the cover settles onto the slot rather than stopping dead on it.
    private static let closeFlight = Animation.spring(duration: 0.32 * timeScale, bounce: 0.15)

    private static let closeChrome = Animation.smooth(duration: 0.25 * timeScale)

    //The chevron arms a quarter into the open — popping from frame 1 read as premature (it
    //zoomed in before the open felt committed), while waiting out 70% left it still popping
    //after the card had settled
    private static let chevronInShare: Double = 0.25

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

    //On the flight's own clock: openDuration carries timeScale, so a slow-motion capture
    //stretches the arm with everything else.
    private func scheduleChevronIn() {
        Task { @MainActor [self] in
            try? await Task.sleep(for: .seconds(Self.openDuration * Self.chevronInShare))
            guard !closing else { return } //A close mid-open keeps it away
            chevronIn = true
        }
    }

    //The screen's own chrome returns a BEAT into the close, never on onClosed: that completion
    //rides the flight spring's `.removed`, which fires at the settling tail — device capture
    //2026-08-31 measured the close starting at 0.28s, ALL motion stopping at 0.90s, and the
    //xmark only beginning to pop at 1.40s: half a second of a frozen screen waiting on a spring
    //nobody can see. onClosed cannot move (the cover→source swap has to outwait that sub-pixel
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

    //The rows were already revealed by the window mid-flight, and the blur foot and the title
    //faded in riding the flight (the morph's arrive ramp); the landing beat only swaps the
    //cover for the live pager over matched pixels
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
            //A SEPARATE write: ridden on the cut's transaction the pop would be a cut too
            withAnimation(.transition) { bandChromeIn = true }
        }
    }

    //`flightless`: the source is gone (its row was pruned under the card), so there is nothing
    //to fly home to. Returns false when a close is already under way — that one lands on its own.
    @discardableResult
    func close(velocity: CGFloat = 0, sideVelocity: CGFloat = 0, flightless: Bool = false) -> Bool {
        guard !closing else { return false }
        closing = true
        bandChromeIn = false //Under the returning cover from here
        scheduleChromeReturn()

        //A landed close flies home to where the source IS: a list reflow or a rotation since
        //the open may have moved it, and at p = 1 nothing on screen derives from the source, so
        //the swap is invisible. Frozen from here — the wind's trajectory needs one home. Only a
        //flight that flew in flies out: a fade-in must not turn into a flying close.
        if landed, hasFlight, !flightless, anchor.rect.width > 1 { source = anchor.rect }

        guard hasFlight, !flightless else { //No anchor, reduce motion, or a vanished source: leave by fade
            withAnimation(.dismiss) { chromeP = 0 } completion: { self.onClosed() }
            return true
        }
        onClosing() //A lens' static ring hides in this same turn, behind the still-full backdrop — the flight's expanding glass owns the slot from here to the landed commit

        var instant = Transaction()
        instant.disablesAnimations = true
        if !coverShown { //Back over the pager on its own pixels before anything moves
            withTransaction(instant) { coverShown = true }
        }

        //One clock, the invite popup's lesson: chromeMix is only the GATE — the fold's
        //progress derives from the flight's own p inside the morph, so the white rows
        //provably wipe up into the image over the collapse's first stretch before the
        //pure photo flies home. A second racing clock on the shared animatable pair read
        //as the whole card shrinking in one piece.
        withTransaction(instant) { chromeMix = 1 }

        //The profile dismiss's split, verbatim: the wind is flick language; a slow let-go
        //(backdrop tap, chevron, a drag simply released past the line) keeps the calm morph.
        if velocity >= DragTuning.arcSlowMorphCeil {
            closeWithWind(velocity: velocity, sideVelocity: sideVelocity)
        } else {
            withAnimation(Self.closeFlight, completionCriteria: .removed) {
                flightP = 0
            } completion: { self.onClosed() }
            withAnimation(Self.closeChrome) { chromeP = 0 }
        }
        return true
    }

    //The wind close — the SAME WindFlightPlan the profile zoom's dismissal flies, so the two
    //cannot drift: the honest ride down the flick, the gust home, the character brake whose
    //bounce emerges from the arrival energy, the settle-pop, the sub-pixel commit. The plan
    //owns the vertical; x is the profile's Hermite; the morph renders both as a deviation
    //from its straight lerp path, with size and fold on the geometry clock (done by
    //arrival) and the backdrop fading on the atmosphere clock.
    private func closeWithWind(velocity: CGFloat, sideVelocity: CGFloat) {
        //Release geometry, all global — the measured rects report live, drag folded in.
        //The anchor is the COVER's centre against the source's: the cover is the one object
        //that flies, and the source is its slot.
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
        let dest = destRect //Frozen at release; source is frozen at close() and cannot drift under the flight
        let home = source

        windDriver.run { [self] raw in
            let elapsed = raw / Self.timeScale //-eventZoomSlow stretches playback, not physics
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
                x: DragTuning.lerp(home.midX, dest.midX, p),
                y: DragTuning.lerp(home.midY, dest.midY, p))
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

//The card's dismissal drag: vertical, rubber-banded, flick-projected — commit flies home from
//wherever the finger left the card, release short of the line snaps back with the invite
//card's overshoot
extension EventZoomChoreo {

    private var dragProgress: Double {
        min(max(rubberBanded(dragOffset.height) / 300, 0), 1)
    }

    private func rubberBanded(_ dy: CGFloat) -> CGFloat {
        if dy <= 0 { return dy * 0.2 } //Upward: the card resists — there is nothing above
        let linear = min(dy, 150)
        return linear + max(dy - 150, 0) * 0.55
    }

    var dismissDrag: some Gesture {
        //Global space, so a touch-down can be tested against the controls that own theirs
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .onChanged { [self] value in
                guard landed, !closing, !dragLocked else { return }
                if dragOffset == .zero {
                    //First movement picks the owner: verticals engage the dismiss, horizontals
                    //belong to the pager — the invite popup's axis split. Once owned, BOTH axes track
                    if abs(value.translation.height) <= abs(value.translation.width) { return }
                    //A press that slid off the CTA is the button's, never a scrub
                    if dragExclusions.values.contains(where: { $0.contains(value.startLocation) }) { return }
                }
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
extension EventZoomChoreo {

    //InviteBandBake's pattern: a live glur on the flying cover would compile its shader at
    //tap and snap the spring, the very hitch the deferred pager mount exists to avoid.
    func bakeCoverBand() async {
        let photo = coverPhoto
        guard photo.size.width > 0, photo.size.height > 0 else { return }
        let aspect = AspectRatio.pendingEvent.ratio
        let width = UIScreen.main.bounds.width - inset * 2
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

//MARK: - The morph

//The morph itself. Animatable, so this body re-derives per frame from the interpolated
//progress: the reveal window's radius is the source's own shape at the source and only relaxes
//into the card's corners as it grows, and the photo band's crop morphs continuously — neither
//ever snaps between endpoints. The card content it masks never re-lays-out: the window and the
//photo are the only things moving, so nothing expensive rides the animation.
struct EventZoomMorph: ViewModifier, Animatable {

    var p: CGFloat
    let chromeMix: CGFloat //The close's fold GATE (snaps 0 → 1, never animates): the fold's progress derives from p
    var dragTravel: CGFloat //The dismiss drag's raw descent — scrubs the fold 1:1 with the finger, and animates home with the snap-back spring
    let flightOffset: CGSize //The wind close's deviation from the straight lerp path — written raw per tick, zero for the open and the calm close
    let pop: CGFloat //The wind landing's settle-pop (WindFlightPlan.settlePop), about the cover's centre
    let source: CGRect //The source's frame, global
    let shape: EventZoomSourceShape //Its rounding — a circle keeps deriving from the current size; its ring is the glass pad the close regrows
    let card: CGRect //The card's resting frame, global (drag included — it reports live)
    let pager: CGRect //The pager band, global
    let photo: UIImage
    let blurredPhoto: UIImage? //The photo with its glur foot baked in — crossfaded over the raw pixels as the flight runs
    let chrome: AnyView? //The source's chrome copy — laid out at source size, transform-ridden, gone over the open's first beat
    let title: String? //The pager's own title — rides the cover so it arrives with the content, not after it
    let coverShown: Bool

    //The dismiss drag scrubs the fold 1:1 with raw descent over this distance — the invite
    //popup's own constant, reused so the cards cannot drift
    private static let collapseDistance: CGFloat = 240

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
        let glassRing = shape.ring

        //The wind trajectory's deviation from the straight lerp path — the ride down the
        //flick, the gust home, the landing bounce past the source — injected per tick by the
        //shared WindFlightPlan; zero through the open and the calm close, so those paths
        //are untouched.
        let bellyY = flightOffset.height
        let bellyX = flightOffset.width

        //max(…, 0): radii must never follow a degenerate size into the negatives
        let cover = lerp(sourceLocal, pagerLocal, p).offsetBy(dx: bellyX, dy: bellyY)
        let coverRadius = max(shape.radius(for: cover.size), 0)

        //The fold: the window collapses onto the photo alone — the white rows wiped up into
        //the image. Two drivers, composed by max so the hand-off between them is seamless:
        //the dismiss DRAG scrubs it 1:1 with raw descent (linear, because the finger is
        //direct manipulation) and reverses with the snap-back; the committed CLOSE derives
        //it from the flight's own p (done by p = 0.6, chromeMix gating it to the close) —
        //never its own racing clock, so the rows provably lead the flight home and a
        //mid-fold release never jumps.
        let dragFold = min(max(dragTravel / Self.collapseDistance, 0), 1)
        let fold = max(chromeMix * smoothstep((1 - p) / 0.4), dragFold)
        let window = lerp(lerp(sourceLocal, bounds, p).offsetBy(dx: bellyX, dy: bellyY), cover, fold)
        let windowRadius = max(lerp(shape.radius(for: window.size), CornerRadius.image, p), 0)

        //The landing pad, a lens' alone: only a committed close shows it (chromeMix gates — the
        //open and the drag scrub never do). Anchored on the source slot, it blooms out from
        //under the arriving cover over the collapse's back half, and over the final approach
        //its centre glues to the cover's — so the wind landing's bounce (position AND the
        //settle-pop, which scales this whole stack) carries the glass with the image. The
        //ledger's own ring is hidden for exactly this stretch (the anchor's `returning`) and
        //takes back a pixel-identical full-size ring at the landed commit.
        let padGrow = glassRing > 0 ? chromeMix * smoothstep((1 - p - 0.55) / 0.4) : 0
        let padAttach = smoothstep((1 - p - 0.88) / 0.12)
        let padSize = CGSize(width: (sourceLocal.width + 2 * glassRing) * padGrow,
                             height: (sourceLocal.height + 2 * glassRing) * padGrow)
        let padCenter = CGPoint(x: lerp(sourceLocal.midX, cover.midX, padAttach),
                                y: lerp(sourceLocal.midY, cover.midY, padAttach))
        //The landing shadow. A lens: its own lightShadow spec, faded in riding the collapse so
        //the landed photo's shadow arrives over already-identical pixels instead of stepping
        //in at the commit. A card: the zoom card's resting shadow, geometry-derived in BOTH
        //directions — full on the open's first frame (the hidden source's shadow cannot
        //vanish in the tap commit) and again at the close landing, gone by the time the
        //card's own shadow carries the window.
        let lensShadow = chromeMix * smoothstep((1 - p - 0.3) / 0.5)
        let cardShadow = 1 - smoothstep(p / 0.3)
        //The chrome copy exits over the open's first beat and returns over the close's last —
        //geometry, not a clock, so the wind's per-tick p drives it too
        let chromeCopy = 1 - smoothstep(p / 0.15)

        content
            .mask {
                RoundedRectangle(cornerRadius: windowRadius)
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
                    //crossfades over already-identical pixels. The source end stays the raw
                    //photo the resting source shows, so takeoff matches its pixels too.
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
                        .overlay {
                            if let chrome, chromeCopy > 0 {
                                //Laid out ONCE at the source's size and transform-ridden, never
                                //re-laid-out in flight — a glur or a scrim re-rendered at an
                                //animating size is the jitter the flight was tuned out of
                                chrome
                                    .frame(width: max(source.width, 1), height: max(source.height, 1))
                                    .scaleEffect(x: cover.width / max(source.width, 1),
                                                 y: cover.height / max(source.height, 1))
                                    .opacity(chromeCopy)
                            }
                        }
                        .overlay(alignment: .bottomLeading) {
                            if let title { coverTitle(title, width: pager.width).opacity(arrive) }
                        }
                        //The source's shape → the pager's band: top corners to the card's, the
                        //bottom pair flattening where the rows begin
                        .clipShape(UnevenRoundedRectangle(
                            topLeadingRadius: lerp(coverRadius, CornerRadius.image, p),
                            bottomLeadingRadius: lerp(coverRadius, 0, p),
                            bottomTrailingRadius: lerp(coverRadius, 0, p),
                            topTrailingRadius: lerp(coverRadius, CornerRadius.image, p)))
                        .modifier(CoverShadow(isLens: glassRing > 0, lens: lensShadow, card: cardShadow))
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

    private func coverTitle(_ title: String, width: CGFloat) -> some View {
        EventTitle(title: title)
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

//The cover's landing shadow, one spec per source kind: the lens' own lightShadow, or the zoom
//card's resting shadow. A branch, not two strength-0 passes — the cover is the one surface the
//flight keeps cheap, and the kind never changes mid-flight.
private struct CoverShadow: ViewModifier {
    let isLens: Bool
    let lens: CGFloat
    let card: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if isLens {
            content.lightShadow(strength: lens)
        } else {
            content.shadow(.zoomCard, strength: card)
        }
    }
}
