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
    ///grows a glass rim of that width out of the flying photo), `.rounded` for a card. The view
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

    ///Marks the word a source and the card it opens both spell — the meet card's "Sarah" against
    ///the compose title's "Invite Sarah", the invite card's against "Sarah's Invite". Put it on the
    ///source chrome's own name `Text`: the flight measures where that word rests, blanks the copy
    ///riding the cover so it is never drawn twice, and flies ONE `Text` from the card into the
    ///title's name slot while the words around it fade in at theirs. The split, the geometry and
    ///the exits are all this file's — a call site says only which word is the name. A title that
    ///never spells it (a confirm screen's own copy) keeps the plain crossfade.
    func eventZoomTitleSource(_ name: String) -> some View {
        modifier(EventZoomTitleSourceModifier(name: name))
    }

    ///Marks the small round button on the source card that the card's wide CTA takes over from —
    ///the meet card's envelope against the compose card's "Preview". Pair it with
    ///`.eventZoomButtonTarget` on that CTA and the flight widens one into the other: a flat capsule
    ///does the stretching (a glass lens rebuilt at a new size every frame costs about seven eighths
    ///of the frame rate), the real circle rides its trailing cap and leaves with its own icon, and
    ///the tint sheds to reveal the fill the CTA rests at. Without the pair, both buttons keep
    ///today's fades.
    func eventZoomButtonSource() -> some View {
        modifier(EventZoomButtonSourceModifier())
    }

    ///The CTA the `.eventZoomButtonSource` circle widens into. `fill` and `text` are what it rests
    ///at, so the flying capsule wears the landing's own look from its first frame rather than a
    ///guess at it; the real button ghosts for the flight and takes back identical pixels at the cut.
    func eventZoomButtonTarget(text: String, fill: Color) -> some View {
        modifier(EventZoomButtonTargetModifier(text: text, fill: fill))
    }

    ///Presents `card` grown out of the `.eventZoomSource` inside this view when `isPresented`
    ///flips true, and flies it home when it flips false (a Send or an Accept), on the chevron, on
    ///a backdrop tap, or on the card's swipe-down. The binding is written back false only when the
    ///close flight has landed, so a call site never sees the card unmount mid-air. `inset` is the
    ///card's gap to the screen edge, `Spacing.gutter` unless a caller says otherwise — passed in
    ///rather than reached back for, because the card lays out at mount, a frame before any
    ///reach-back lands.
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
    ///pager instead of letting the hand-off fade reveal it. `visible` is the piece's OWN page
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

    ///A lens — the ledger's glass-ringed face — lands with a breath; a card sinks (the close's
    ///landing patterns, `EventZoomChoreo.close`)
    var isLens: Bool {
        if case .circle = self { true } else { false }
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
    ///True only inside the chrome copy riding the flying cover, and only while a name hero is up:
    ///the copy's own name keeps its slot and drops its glyphs, so the word never doubles
    @Entry var eventZoomTitleFlying = false
    ///As above, for the source's round button while the capsule hero owns it
    @Entry var eventZoomButtonFlying = false
}

//MARK: - The host: one per plane, owned by the plane root

///The slot a plane presents into. Owned as `@State` by the plane root, which reads `isPresenting`
///and `chromeHidden` for its own chrome — a container cannot read an environment value it injects.
@MainActor @Observable final class EventZoomHost {

    struct Slot {
        let id: UUID //The anchor's — a card is identified by the modifier that presented it
        let anchor: EventZoomAnchor
        let inset: CGFloat //The card's gap to the screen edge — its horizontal padding
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
///while the flying photo grows its own rim).
@MainActor @Observable final class EventZoomAnchor {

    let id = UUID()

    private(set) var vacated = false
    private(set) var returning = false

    @ObservationIgnored var rect: CGRect = .zero //Global — the flight's home
    @ObservationIgnored var image: UIImage?
    @ObservationIgnored var shape: EventZoomSourceShape = .rounded()
    @ObservationIgnored var chrome: (() -> AnyView)?
    @ObservationIgnored var titleName: String? //The word the card's title repeats — nil unless a source marks one
    @ObservationIgnored var titleRect: CGRect = .zero //Where the source draws it, global — the name hero's home
    @ObservationIgnored var buttonRect: CGRect = .zero //The source's round button, global — the capsule hero's home
    @ObservationIgnored var pressPose: PressPose = .rest //That button's press as rendered — the hero takes off from it
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

private struct EventZoomTitleSourceModifier: ViewModifier {

    //Injected
    @Environment(EventZoomAnchor.self) private var anchor: EventZoomAnchor?
    @Environment(\.eventZoomTitleFlying) private var flying: Bool
    let name: String

    func body(content: Content) -> some View {
        //Refreshed every pass like the source's own palette, and for the same reason. The chrome
        //COPY renders on the flight's plane, where there is no anchor to write to — it reports
        //nothing and reads only the flag below.
        anchor?.titleName = name
        return content
            .opacity(flying ? 0 : 1) //A layout ghost: the hero owns the glyphs, the copy keeps the slot
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { anchor?.titleRect = $0 }
    }
}

private struct EventZoomButtonSourceModifier: ViewModifier {

    //Injected
    @Environment(EventZoomAnchor.self) private var anchor: EventZoomAnchor?
    @Environment(\.eventZoomButtonFlying) private var flying: Bool

    func body(content: Content) -> some View {
        content
            .opacity(flying ? 0 : 1) //A layout ghost: the hero's own lens is the one that flies
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { anchor?.buttonRect = $0 }
            //Per frame of a press (PressPoseReporter): the last value before the action fires is the pose
            //the finger released at, and the flight's first frame wears it
            .onPreferenceChange(PressPoseKey.self) { pose in
                MainActor.assumeIsolated { anchor?.pressPose = pose }
            }
    }
}

//On the card body's own CTA, so it reports to the flight rather than the anchor: the landing pad is
//inside the card, not on the source. It ghosts while the capsule flies and takes the pixels back at
//the hand-off cut.
private struct EventZoomButtonTargetModifier: ViewModifier {

    //Injected
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    let text: String
    let fill: Color

    func body(content: Content) -> some View {
        content
            .opacity(flight?.ctaGhosted == true ? 0 : 1)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(EventZoomChoreo.cardSpace)) } action: { flight?.reportCTA($0) }
            .onChange(of: text, initial: true) { flight?.reportCTALook(text: $1, fill: fill) }
            .onChange(of: fill, initial: true) { flight?.reportCTALook(text: text, fill: $1) }
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
            //A committed close is flying home: a lens' static ring hides (a bare write, behind the
            //still-full backdrop) so the photo lands wearing its own rim on a bare slot
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
            EventBackdrop()
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
        .onAppear {
            let flight = flight
            slot.anchor.requestClose = { [weak flight] flightless in flight?.close(flightless: flightless) ?? false } //How the host closes this card when the binding drops, or its source vanishes
        }
        .onDisappear { flight.unmounted() }
    }
}

extension EventZoomCard {

    //A/B knobs — flip by hand, rebuild. `glassSurface` false is the flat fill the card ships with.
    private static let glassSurface = false
    private static let glassTint: Color = .white //Try `.appCanvas` for the app's warm off-white

    //Glass, not `glassEffectIfAvailable`: this card CONTAINS glass (the back button, the options
    //disc), and a `.glassEffect` on the content pulls them into its group and kills their lens.
    //`clipped` is required, not cosmetic — unclipped .regular glass carries a shadow no API
    //disables, and the card must wear only the `.shadow(.card)` below so the landing can hand
    //shadows off continuously. Fixed radius: the glass draws its OWN rect, so mid-flight it will
    //not fill the morph's smaller window — judge this A/B at rest.
    @ViewBuilder
    private var cardFill: some View {
        if Self.glassSurface {
            Color.clear.containerGlassEffect(tint: Self.glassTint,
                                             clipped: true,
                                             shape: .rect(cornerRadius: CornerRadius.image))
        } else {
            Color.white
        }
    }

    //The caller's card wearing the flight: the morph's window owns its rounding, and the shadow
    //is worn AFTER the mask so it wears the window's shape. The content is its own equatable
    //view, so the wrapper's per-frame reads (drag, wind ticks) never re-run the body the caller
    //supplied — that body re-evaluates only when data IT observes changes (images loading in).
    private var card: some View {
        EventZoomCardContent(id: slot.id,
                             bandChromeVisible: flight.bandChromeVisible,
                             ctaGhosted: flight.ctaGhosted,
                             card: slot.card)
            .equatable()
            .environment(flight) //How the pager gates its live mount, reports its band and title, and how the body reaches back
            .environment(\.eventZoomDismiss, dismiss)
            //The space the body's band and CTA report their frames in: INSIDE the morph's render
            //transforms, so a breathing, sinking or popping card never feeds its transform back into
            //the poses derived from those frames (see EventZoomChoreo.ctaLocal)
            .coordinateSpace(.named(EventZoomChoreo.cardSpace))
            .background { cardFill }
            .modifier(flight.morph()) //Draws the card's shadow itself, as a shape BEHIND the window — see the morph
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
    //Part of the identity for the same reason: the card's own CTA ghosts for the flight and takes
    //its pixels back at the landing, and an equality blind to that would leave it invisible until
    //something else happened to re-render the card
    let ctaGhosted: Bool
    let card: () -> AnyView

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.bandChromeVisible == rhs.bandChromeVisible
            && lhs.ctaGhosted == rhs.ctaGhosted
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
    private let shape: EventZoomSourceShape //A circle's ring is the glass rim the close grows around the photo; a card has none
    let coverPhoto: UIImage //The source's pixels: the flying cover, and the pager's page when a caller hands it nothing
    private let chrome: AnyView? //The source's chrome, copied once at source size — rides the cover out and back
    private let titleName: String? //The word the source's chrome and the card's title share — nil unless marked
    private var titleRect: CGRect //Where the source draws it, global — re-read with `source` at a landed close
    private var buttonSource: CGRect //The source's round button, global — re-read with `source` too
    private var pressPose: PressPose //Its press at takeoff — the hero relaxes out of it over the shed; rest from the landing on
    //The card's own CTA, in CARD space — measured inside the card's named coordinate space, never
    //through the morph's render transforms (the open's breath, the close's sink, the wind's pop): a
    //global frame read from inside the breathed subtree carried the breath, and the capsule posed
    //from it was then breathed again (sim trace 2026-09-04: the band slid ~4pt against the rows
    //instead of ~1). `ctaRect` derives the global rect from the card's own frame, measured OUTSIDE.
    private var ctaLocal: CGRect = .zero
    private var ctaRect: CGRect { ctaLocal.isEmpty ? .zero : ctaLocal.offsetBy(dx: cardRect.minX, dy: cardRect.minY) }
    private var ctaText: String = "" //What the CTA rests at, so the capsule wears the landing's own look
    private var ctaFill: Color = .clear
    private var ctaHeroShown = true //The capsule stands in for the CTA until its fade is done (see `handOffCTA`)
    private var ctaHeroFade: Double = 1 //The capsule's fill fading off the real button — its label holds until the end
    private let onClosing: () -> Void //A committed close is leaving: the owner hides a lens' static ring
    private let onChromeReturn: () -> Void //A beat into the close: the screen's own chrome comes back, while the card is still flying
    private let onClosed: () -> Void //The close flight has landed; the owner clears state

    //Flight state
    private var flightP: CGFloat = 0 //0 = at the source, 1 = the full card
    private var chromeP: Double = 0 //Backdrop and chevron — the pieces outside the card
    private var coverShown = true //The morphing photo: cut away once landed, back instantly at close
    private var titleHeroFade: Double = 1 //The name morph's OWN hand-off — a fade over the page's line, never a cut (see `handOffCover`)
    private var titleHeroShown = true
    private var landed = false
    private var closing = false
    private var hasOpened = false
    private var dragOffset: CGSize = .zero //Raw finger travel, BOTH axes; the card rides it rubber-banded (the profile dismiss's follow)
    private var chromeMix: CGFloat = 0 //The close's fold gate — snapped to 1 at close start; the fold's motion derives from the flight's p
    private var windRender = WindRender() //The wind close's per-frame pose: trajectory offset + settle-pop, written raw each tick
    private var landingScale: CGFloat = 1 //The tap close's landing breath — compress into touchdown, rebound past rest, settle; the open, the drag and the wind never write it
    private var breath: CGFloat = 0 //The open's over-expansion, 0 → 1 → 0 on its own clock (breathRise/breathSettle)
    private var cardLanding = false //A card's tap close is flying its own landing: the morph folds 1:1 with p and reads p < 0 as the sink
    private var cardRect: CGRect = .zero //The card's frame, global — the flight's far end
    private var destLocal: CGRect = .zero //The pager's frame in card space — see ctaLocal
    private var destRect: CGRect { destLocal.isEmpty ? .zero : destLocal.offsetBy(dx: cardRect.minX, dy: cardRect.minY) } //Global: the photo's landing band
    private var restingCard: CGRect = .zero //The card's frame at REST — the stationary chevron's slot, held clear of the drag and of the flight home
    private var chevronIn = false //The chevron's late arrival: armed a quarter into the open, so it pops only once the flight reads committed
    private var fingerDown = false //The finger owns the card. Ownership, not motion: the chevron leaves as the drag begins and returns the instant a cancelled release lets go, riding back on screen with the snap-back
    private var title: String? //What the pager draws over its band — the cover draws the same, so the hand-off meets identical words
    private var pagerTitle: CGRect = .zero //The title's glyph rect in the band's own space — the frost's capsule, which the cover poses as insets from its foot
    private var bandChromeIn = false //Chrome over the band: in on its own animated write as the hand-off fade begins, out with the close
    private var chevronHiddenByCard = false //A body's confirm screen owns the corner with its own back button
    private var dragLocked = false //A body's popup owns the finger: no dismiss scrub, no chevron
    @ObservationIgnored private var dragExclusions: [UUID: CGRect] = [:] //Global frames of controls that own their touch-down

    private let windDriver = WindCloseDriver() //The wind close's clock — the trajectory is time-domain, not a spring target

    init(anchor: EventZoomAnchor,
         onClosing: @escaping () -> Void,
         onChromeReturn: @escaping () -> Void,
         onClosed: @escaping () -> Void) {
        self.anchor = anchor
        self.source = anchor.rect
        self.shape = anchor.shape
        self.coverPhoto = anchor.image ?? UIImage()
        self.chrome = anchor.chrome?() //Built ONCE: the same value every frame, so the copy's body never re-runs in flight
        self.titleName = anchor.titleName
        self.titleRect = anchor.titleRect
        self.buttonSource = anchor.buttonRect
        self.pressPose = anchor.pressPose
        self.onClosing = onClosing
        self.onChromeReturn = onChromeReturn
        self.onClosed = onClosed
    }
}

//The card's read surface — everything the presented card needs, and nothing that moves it
extension EventZoomChoreo {

    //Landed and at rest: the live pager mounts here
    var settled: Bool { landed && !closing }

    //Chrome over the pager band arrives on its own animated write as the cover fades — it rides in
    //over the hand-off rather than being revealed by it, so the foot and title land once
    var bandChromeVisible: Bool { settled && bandChromeIn }

    //A source button and a flight to fly: the capsule owns the button from the tap to the hand-off
    //cut, and again from the close's first frame. From the TAP — the card's own CTA is measured a
    //frame later, and until then the capsule simply sits on the source (`EventZoomButtonMorph`);
    //waiting for it left the cover's chrome copy showing its own button for a frame between the
    //source and the hero. It is part of the card content's identity below, because an
    //`.equatable()` card swallows an observation the body alone would miss.
    var buttonHeroActive: Bool {
        hasFlight && ctaHeroShown && buttonSource.width > 1
    }

    //The capsule's fill opacity: 1 for the flight, then faded off over the landing (see `handOffCTA`)
    var ctaHeroFill: Double { ctaHeroFade }

    //The real CTA ghosts for the flight — but it comes back at the LANDING, well before the capsule
    //goes, and takes its first paint hidden behind a capsule that covers it (the capsule sits on
    //the button to the pixel from p = 1, its fill opaque until the hand-off). The rule that put it there:
    //reveal a surface behind whatever is covering it, never as the cover leaves — a glass one held
    //at opacity 0 never samples a backdrop and warms up on screen (+35 levels, sim 2026-09-04); the
    //CTA is flat now, and the beat still buys it a first paint before the fade.
    var ctaGhosted: Bool { buttonHeroActive && !settled }

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

    //Cast by a shape of the window BEHIND the card (the morph draws it), so it wears the window's
    //shape — and strength rides the flight: the resting source casts nothing of its own here, so
    //the committed source frames must not bloom a shadow. Clamped: the close spring's rebound and a
    //card landing's excursion carry flightP below 0 (the open, critically damped, never passes 1)
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

    ///In card space (`EventZoomChoreo.cardSpace`)
    func reportPagerBand(_ rect: CGRect) {
        if destLocal != rect { destLocal = rect }
        openWhenMeasured()
    }

    func reportTitle(_ title: String) {
        if self.title != title { self.title = title }
    }

    func reportPagerTitle(_ rect: CGRect) {
        if pagerTitle != rect { pagerTitle = rect }
    }

    //Same-value guards throughout: a redundant write to an @Observable stalls compositing
    ///In card space (`EventZoomChoreo.cardSpace`)
    func reportCTA(_ rect: CGRect) {
        if ctaLocal != rect { ctaLocal = rect }
    }

    func reportCTALook(text: String, fill: Color) {
        if ctaText != text { ctaText = text }
        if ctaFill != fill { ctaFill = fill }
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
            flightP: flightP,
            chromeMix: chromeMix,
            dragTravel: dragOffset.height,
            flightOffset: windRender.offset,
            pop: windRender.pop,
            landingScale: landingScale,
            breath: breath,
            cardLanding: cardLanding,
            source: source,
            shape: shape,
            card: cardRect,
            pager: destRect,
            photo: coverPhoto,
            chrome: chrome,
            title: title,
            pagerTitle: pagerTitle,
            titleName: titleName,
            titleSource: titleRect,
            buttonHero: buttonHeroActive,
            buttonFade: ctaHeroFill,
            buttonSource: buttonSource,
            pressPose: pressPose,
            cta: ctaRect,
            ctaText: ctaText,
            ctaFill: ctaFill,
            coverShown: coverShown,
            titleShown: titleHeroShown,
            titleFade: titleHeroFade,
            rimMounted: landed,
            shadow: shadowStrength)
    }

    //An unmount mid-flight must not leave the link ticking
    func unmounted() { windDriver.stop() }
}

//The flight clocks and choreography. All geometry lives in EventZoomMorph below — an Animatable
//modifier, so the window and the photo re-derive from the interpolated progress EVERY FRAME:
//radii genuinely ride the current size instead of sliding between endpoints.
extension EventZoomChoreo {

    ///The card body's named coordinate space — what the band and the CTA measure themselves in
    static let cardSpace = "eventZoomCard"

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
    //Lightly under-damped (bounce 0.1, damping ratio 0.9): the flight reaches its size ~30ms sooner
    //than critically damped and still carrying speed, which takes the ease-out's slow-looking tail
    //off the end of the expansion (Arthur, 2026-09-04: "a touch quicker towards the end"). Its own
    //overshoot is e^(−πζ/√(1−ζ²)) ≈ 0.15% of the travel — a third of a point — and the morph clamps p
    //at 1 anyway, so the landing geometry (window, cover, title word, capsule) never passes its slot:
    //the wobble an earlier, bouncier flight put on the arriving words cannot return. What the clamp
    //costs is the interior stopping with ~75pt/s left (1pt/frame — modelled, imperceptible); bounce
    //0.15 leaves 125pt/s and reads as text hitting its slot, 0.2 kicks. The card's over-expansion is
    //the breath below, on its own clock, and never touches the landing geometry.
    private static let openFlight = Animation.spring(duration: openDuration, bounce: 0.1)
    //The open's over-expansion (Arthur, 2026-09-04: "expand a bit more and bounce to its final
    //position … slower and larger … it expands up to the size, then the bounce absorbs all its
    //velocity"): the whole landed stack swells past its size and settles, worn by the morph as ONE
    //uniform scale about the card's centre, `breathGain` at the peak (3.3% ≈ 9pt at the top and the
    //bottom of the compose card, ~5pt a side). On its OWN clock, overlapping the flight's tail — a
    //single spring cannot give a quick arrival AND a long absorption, its approach, overshoot and
    //return sharing one period (bounce 0.3 peaked 55ms after the crossing and read as a blip).
    //The rise (timingCurve 0.25, 0, 0.9, 1) starts EARLY at `breathStartTime`, while the flight still
    //has ~40% of its travel and most of its speed, and is long and gentle: the breath's speed ramps up
    //only as fast as the flight's ramps down, so the summed edge speed never rises — modelled against
    //the REAL Meet card (top travels 87pt, bottom 44; device recording 2026-09-04): the edge crosses
    //its size at ~0.20s doing ~190pt/s, brakes ~125ms to the 13pt peak, and sits within a point of
    //the peak for ~48ms before the settle takes it back (return ~300ms, rest ~0.62s). Two device tells drove this: a late, steep
    //rise (start 0.56, rise 0.60) re-accelerated the edge ~30% exactly at the size on the real card
    //(the harness card travels twice as far, which hid it), and a flat-ended rise (c2x 0.15) plus a
    //0.30s settle held the edge at its peak for ~85ms — a hang. More end-curvature on the rise and a
    //0.22s settle make the turnaround read as a turnaround. With 9pt to stop in, arrival speed and
    //brake time are tied: v ≈ 2·A / t_brake. The settle is critically damped from the peak's zero
    //velocity: no undershoot. Both writes go in the flight's commit, the settle
    //delayed to the rise's end — additive retargeting blends them into one motion, the close
    //landing's pattern. Under a close or a drag the morph fades it with the fold. Reduce motion
    //never schedules it.
    static let breathGain: CGFloat = 0.033 //A LENS source's uniform swell; read by the morph. 0.044 (≈12pt) read a touch much on device — Arthur took a quarter off
    static let breathPeak: CGFloat = 13 //A CARD source's farthest-travelling edge at the peak, pt; the other edges follow in proportion to their own travel (9 → 13 by eye, Arthur 2026-09-04)
    //On the FLIGHT's clock, so the bounce reflects the opening (Arthur, 2026-09-04): a critically damped
    //spring's shape depends only on t/openDuration, so its speed at any share of its travel scales
    //with 1/openDuration — trim the open and the card arrives faster. With the overshoot held fixed,
    //the brake that absorbs that speed (t ≈ 2·A / v) and the return that mirrors it must shrink in
    //the same proportion, so all three times are shares of openDuration: trim the open by 0.02s and
    //the whole bounce trims ~6%, arrival ~7% faster, peak height unchanged. (Timed literals here
    //would have left the breath's speed peak drifting off the crossing the moment the open changed.)
    private static let breathStartShare: Double = 0.30 //Early — while the flight still has ~40% of its travel and most of its speed (0.10s of 0.32)
    private static let breathRiseShare: Double = 0.70 //A long, gentle rise (0.22s of 0.32): its speed never exceeds what the flight is shedding
    private static let breathSettleShare: Double = 2 //The return (0.37s of 0.32), critically damped from rest (0.70 → 1.15 by eye, Arthur; the turnaround's crispness comes from the rise's end-curvature, not this)
    private static let breathStartTime: TimeInterval = openDuration * breathStartShare
    private static let breathRiseTime: TimeInterval = openDuration * breathRiseShare
    private static let breathRise = Animation.timingCurve(0.25, 0, 0.9, 1, duration: breathRiseTime).delay(breathStartTime)
    private static let breathSettle = Animation.smooth(duration: openDuration * breathSettleShare).delay(breathStartTime + breathRiseTime)
    private static let openChrome = Animation.spring(
        duration: openSpring.duration * timeScale,
        bounce: openSpring.bounce + 0.05)
    //0.32 FLAT read a tad too snappy on device (2026-08-31) and was taken back out to 0.36; it
    //returns quicker with the landing's bounce restored instead. 0.15 (damping .85) overshoots
    //~0.6% of the flight, and p is the whole source→pager range, so that is ~2pt of inward pulse
    //on the 52pt lens: the cover settles onto the slot rather than stopping dead on it.
    private static let closeDuration = 0.32 * timeScale
    private static let closeFlight = Animation.spring(duration: closeDuration, bounce: 0.15)

    private static let closeChrome = Animation.smooth(duration: 0.25 * timeScale)

    //A LENS' tap close — a chevron or backdrop tap lands with a breath instead of stopping
    //dead: the whole lens compresses into its slot over the flight's last fifth and rebounds past
    //rest on a short spring, ONE motion, direction-free. A positional bounce was tried here and
    //jolted (2026-09-03): the calm flight arrives on a spring with no speed left, so a push past
    //the slot has no momentum to motivate it — only a flick, which arrives fast, earns the
    //wind's overshoot. The rebound is issued in the SAME commit as the dip, delayed to its end:
    //the lens landing's device-verified seam (2026-08-31) — a beat scheduled after the arrival
    //read as arrive-wait-pop, while additive retargeting blends these into one motion. A close
    //the finger let go keeps the plain morph home, as the swipe always landed.
    private static let landingDip: CGFloat = 0.86 //Compression at touchdown — a notch into the slot, part of the arrival, never a pose it holds. Tuned with a steady ring; the rim squashes along now, so it may want 0.9
    private static let landingDipShare: Double = 0.8 //Of the flight, before the dip begins
    private static let landingDipIn = Animation.smooth(duration: closeDuration * (1 - landingDipShare))
        .delay(closeDuration * landingDipShare)
    private static let landingRebound = Animation.spring(duration: 0.32 * timeScale, bounce: 0.55) //A small pop past rest and a short settle
        .delay(closeDuration)

    //A card source's tap close — the profile card, the invite card — lands by SINKING, on a
    //per-frame curve of its own (`landCard`), the wind's pattern: an under-damped spring carries
    //p from the band THROUGH the slot to a deepest point a fixed distance past it — the spring's
    //own first minimum, so it arrives there with no velocity — and a critically damped rebound
    //brings it back onto the slot: it leaves the deepest point decisively, the way stored squash
    //releases, and eases out into rest. The seam has no velocity on either side. A single
    //SwiftUI spring could not do it, its approach, overshoot and return sharing one period: at
    //0.28s everything happened inside 0.3s and read as a snap; at 0.40s the return was still
    //~0.2s and read as shrink-then-expand in place (device videos 2026-09-03). The morph reads
    //p < 0 as the carry (the centre keeps going along the path it flew) and as the squash (the
    //whole card recedes, deepest at the deepest point), and a card's fold rides p 1:1 so the rows
    //collapse into the photo at the rate the photo travels — never ahead of it. The lens' breath
    //above is a TIMED dip a short flight outruns, and 0.86 is a 26pt collapse on a 373pt card.
    static let cardOvershoot: CGFloat = 16 //pt past the slot at the deepest point — the momentum, Arthur's choice
    private static let cardCrossTime: TimeInterval = 0.2 * timeScale //Tap → the slot: the collapse reads prompt
    private static let cardReturnTime: TimeInterval = 0.7 * timeScale //Deepest point → settled (99%): quite slow by design, the rebound front-loaded inside it
    static let cardSinkDepth: CGFloat = 0.06 //How far the card recedes at the deepest point — the scale-up on the return must read
    private static let cardSettleReach: Double = 6.6 //ωt at which (1 + ωt)·e^(−ωt) is ~1%: the return's clock, so cardReturnTime is its settle

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
            handOffCover(after: Self.handOffBeat) //The cover parks on the band while the pager takes its first paint
            armBandChrome()
            return
        }
        Task { @MainActor [self] in
            try? await Task.sleep(for: .milliseconds(30)) //One committed frame at the source before the flight leaves it
            //Two completions on ONE spring: the landing at its perceptual end, and the cover's
            //hand-off only once it is REMOVED — p is exactly 1 then, so the cover and the live
            //page are the same pixels. At `.logicallyComplete` ~1.4% of the travel is still to
            //come (this spring: 0.332s vs 0.517s to removal), and a swap a beat after it stepped
            //the whole band about a point (sim capture 2026-09-04, `-eventZoomSlow`).
            var flight = Transaction(animation: Self.openFlight)
            flight.addAnimationCompletion(criteria: .logicallyComplete) { self.land() }
            //A lens cuts its cover on the spring's removal as before (its whole stack breathes together,
            //so the cut is on identical pixels whenever it falls). A CARD breathes only its shell while
            //the live page beneath stays put, so its cut waits for the breath's own removal — breath is
            //exactly 0 there, the shell is home, and the cover and the page are the same pixels again.
            flight.addAnimationCompletion(criteria: .removed) {
                self.handOffCTA()
                if self.shape.isLens { self.handOffCover() }
            }
            withTransaction(flight) { flightP = 1 }
            withAnimation(Self.breathRise) { breath = 1 }
            withAnimation(Self.breathSettle, completionCriteria: .removed) { //Same commit, delayed to the rise's end: one blended motion
                breath = 0
            } completion: {
                if !self.shape.isLens { self.handOffCover() }
            }
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

    //The rows were already revealed by the window mid-flight, and the title, its frost and the
    //foot faded in riding the flight (the morph's arrive ramp); the landing mounts the live pager
    //under the still-opaque cover and arms the band's chrome — the cover itself hands off later,
    //on the spring's removal, over identical pixels
    private func land() {
        guard !landed, !closing else { return }
        landed = true //The pager mounts here, under the still-opaque cover
        chevronIn = true //Normally already in on its own clock — a landing must never sit chevron-less
        pressPose = .rest //Spent by the shed's end; a close flies the disc home unpressed
        armBandChrome()
    }

    //The capsule's hand-off, on the spring's removal like the cover's: at p = 1 the capsule sits on
    //the CTA to the pixel, and the CTA is FLAT in the capsule's own colour, painted since the
    //landing — so the capsule's fill fades off an identical fill and nothing arrives. (A glass CTA
    //arrived as a darker sheen plus the lens' own shadow halo — device 2026-09-04.) The capsule's
    //label does NOT fade with it: fading the whole capsule dipped the word a quarter of the way to
    //the fill mid-way — SwiftUI fades layers one by one, so a fading label over a fading fill over
    //the real word composites the fill through. Held opaque over the real word until the fill is
    //gone, it hands off on identical glyphs.
    private func handOffCTA() {
        guard !closing else { return }
        withAnimation(.transition) { ctaHeroFade = 0 } completion: { self.ctaHeroShown = false }
    }

    //The band's chrome arrives a beat after the landing, and a flightless open parks its cover
    //on the band for the same beat: both buy the freshly mounted pager its first real paint.
    private static let handOffBeat = Duration.milliseconds(100 * timeScale)

    //The cover CUTS to the live pager, on identical pixels. The pager's band is a 10pt foot plus
    //a capsule frost behind the title (`InvitePhotoBand`), and the flying cover wears the same
    //view, ridden in on the title's ramp (`arrive` in the morph), posed on the band to the pixel
    //by the time this runs — a flight calls it on its spring's REMOVAL (p exactly 1, the pager
    //painted since the landing), a flightless open after `handOffBeat`. Measured on the sim
    //(2026-09-04): the swap changes 12 pixels by one level. A fade here is WORSE than a cut:
    //SwiftUI fades the cover's layers one by one, so mid-fade the photo, its band and its white
    //foot double-composite over the page and the whole band dips ~20 levels for a few frames.
    //Before the cover flew the band, the fade WAS the arrival: both blurs popped in over its
    //steep front, ~180ms after the card had visibly stopped (device recording 2026-09-04).
    private func handOffCover(after beat: Duration = .zero) {
        Task { @MainActor [self] in
            if beat > .zero { try? await Task.sleep(for: beat) }
            guard !closing else { return } //A close begun meanwhile owns the cover now
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { coverShown = false }
            //The name morph's affix and hero are two Texts standing in for the page's ONE — the
            //same glyphs to the eye, a hair apart at the edges (kerning across a Text boundary).
            //Cut, that hair flickers; faded over the page's line it dissolves. Plain text over
            //identical text, so the layer-by-layer fade has nothing to double-composite.
            withAnimation(.transition) { titleHeroFade = 0 } completion: { self.titleHeroShown = false }
        }
    }

    //Chrome over the band (a back button, the options row) pops in on its own animated write a
    //beat after the landing — over the cover, which by then carries the band it lands on
    private func armBandChrome() {
        Task { @MainActor [self] in
            try? await Task.sleep(for: Self.handOffBeat)
            guard !closing else { return }
            withAnimation(.transition) { bandChromeIn = true }
        }
    }

    //`flightless`: the source is gone (its row was pruned under the card), so there is nothing
    //to fly home to. Returns false when a close is already under way — that one lands on its own.
    @discardableResult
    func close(velocity: CGFloat = 0, sideVelocity: CGFloat = 0, flightless: Bool = false) -> Bool {
        guard !closing else { return false }
        closing = true
        pressPose = .rest //A close before the landing must not re-inflate the flying disc to the takeoff press as its shed returns
        bandChromeIn = false //Under the returning cover from here
        scheduleChromeReturn()

        //A landed close flies home to where the source IS: a list reflow or a rotation since
        //the open may have moved it, and at p = 1 nothing on screen derives from the source, so
        //the swap is invisible. Frozen from here — the wind's trajectory needs one home. Only a
        //flight that flew in flies out: a fade-in must not turn into a flying close.
        if landed, hasFlight, !flightless, anchor.rect.width > 1 {
            source = anchor.rect
            titleRect = anchor.titleRect //The word flies home to where the label IS, for the same reason
            buttonSource = anchor.buttonRect
        }

        guard hasFlight, !flightless else { //No anchor, reduce motion, or a vanished source: leave by fade
            withAnimation(.dismiss) { chromeP = 0 } completion: { self.onClosed() }
            return true
        }
        onClosing() //A lens' static ring hides in this same turn, behind the still-full backdrop — the slot stays bare until the photo lands its own rim on it at the landed commit

        var instant = Transaction()
        instant.disablesAnimations = true
        if !coverShown { //Back over the pager on its own pixels before anything moves
            withTransaction(instant) { coverShown = true }
        }
        withTransaction(instant) { //The name morph's pieces come back with it, over the line they left
            titleHeroFade = 1
            titleHeroShown = true
        }
        //The capsule takes the button back in the same commit the button ghosts, so no frame has neither
        withTransaction(instant) {
            ctaHeroFade = 1
            ctaHeroShown = true
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
        } else if dragEngaged { //Let go by the finger: the plain morph home, as the swipe always landed
            withAnimation(Self.closeFlight, completionCriteria: .removed) {
                flightP = 0
            } completion: { self.onClosed() }
            withAnimation(Self.closeChrome) { chromeP = 0 }
        } else if shape.isLens { //A tap on a lens' card: the flight, and the landing breath that owns the commit
            withAnimation(Self.closeFlight) { flightP = 0 }
            withAnimation(Self.closeChrome) { chromeP = 0 }
            landOnSlot()
        } else { //A tap on a card's: the sink, a per-frame landing that owns the commit
            withTransaction(instant) { cardLanding = true }
            withAnimation(Self.closeChrome) { chromeP = 0 }
            landCard()
        }
        return true
    }

    //The card landing's clock. The spring is solved from the geometry: its damping from the
    //overshoot's share of the travel (an under-damped settle's first minimum is e^(−ζπ/√(1−ζ²))
    //of it), its frequency from the crossing time (the slot crossing sits at ωd·t = π − acos ζ,
    //the minimum at π). Past the minimum the return is a critically damped release of the
    //excursion — (1 + ωt)·e^(−ωt), no velocity at the seam, quickest a beat later, easing out
    //into the slot, 99% settled at cardReturnTime — and the last tick lands p on exactly 0
    //before the commit, so the source takes back identical pixels.
    private func landCard() {
        let path = hypot(destRect.midX - source.midX, destRect.midY - source.midY)
        let share = Double(min(Self.cardOvershoot / max(path, 1), 0.5)) //The excursion as a share of the travel
        let l = log(1 / share)
        let zeta = l / (Double.pi * Double.pi + l * l).squareRoot()
        let omegaD = (Double.pi - acos(zeta)) / Self.cardCrossTime
        let tDeep = Double.pi / omegaD
        let decayRate = zeta * omegaD / (1 - zeta * zeta).squareRoot() //ζω, ω the undamped frequency
        let lean = zeta / (1 - zeta * zeta).squareRoot()
        windDriver.run { [self] raw in
            let t = raw / Self.timeScale //-eventZoomSlow stretches playback
            var instant = Transaction()
            instant.disablesAnimations = true
            if t < tDeep {
                let p = exp(-decayRate * t) * (cos(omegaD * t) + lean * sin(omegaD * t))
                withTransaction(instant) { flightP = CGFloat(p) }
            } else if t < tDeep + Self.cardReturnTime {
                let x = (t - tDeep) / Self.cardReturnTime * Self.cardSettleReach
                withTransaction(instant) { flightP = CGFloat(-share * (1 + x) * exp(-x)) }
            } else {
                windDriver.stop()
                withTransaction(instant) { flightP = 0 }
                onClosed()
            }
        }
    }

    //The landing breath, issued with the flight: the dip rides the flight's last fifth and the
    //rebound takes over the moment it bottoms out. onClosed rides the rebound's `.removed`, the
    //last motion to stop — the cover→source swap has to outwait its sub-pixel tail, exactly as
    //it outwaits the flight's on the drag path.
    private func landOnSlot() {
        withAnimation(Self.landingDipIn) { landingScale = Self.landingDip }
        withAnimation(Self.landingRebound, completionCriteria: .removed) {
            landingScale = 1
        } completion: { self.onClosed() }
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

    var flightP: CGFloat //The flight's raw progress — the open reads it through `p` in the body
    let chromeMix: CGFloat //The close's fold GATE (snaps 0 → 1, never animates): the fold's progress derives from p
    var dragTravel: CGFloat //The dismiss drag's raw descent — scrubs the fold 1:1 with the finger, and animates home with the snap-back spring
    let flightOffset: CGSize //The wind close's deviation from the straight lerp path — written raw per tick, zero for the open and the calm close
    let pop: CGFloat //The wind landing's settle-pop (WindFlightPlan.settlePop), about the cover's centre
    var landingScale: CGFloat //The tap close's landing breath, applied about the cover's centre — 1 for the open, the drag and the wind
    var breath: CGFloat //The open's over-expansion, 0 → 1 → 0 (EventZoomChoreo.breathRise/Settle), worn as a uniform scale about the card's centre
    let cardLanding: Bool //A card's tap-close landing (EventZoomChoreo.landCard): the fold rides p 1:1 and p < 0 is the sink
    let source: CGRect //The source's frame, global
    let shape: EventZoomSourceShape //Its rounding — a circle keeps deriving from the current size; its ring is the glass rim the close grows around the photo
    let card: CGRect //The card's resting frame, global (drag included — it reports live)
    let pager: CGRect //The pager band, global
    let photo: UIImage
    let chrome: AnyView? //The source's chrome copy — laid out at source size, transform-ridden, gone over the open's first beat
    let title: String? //The pager's own title — rides the cover so it arrives with the content, not after it
    let pagerTitle: CGRect //Its glyph rect in the band's own space — the frost capsule's landing, posed on the cover as insets from its foot
    let titleName: String? //The word inside that title the source also draws — the name hero's subject
    let titleSource: CGRect //Where the source draws it, global — the hero's home
    let buttonHero: Bool //The capsule is mounted this frame
    let buttonFade: Double //Its fill's hand-off, faded off the identical real fill; the label holds
    let buttonSource: CGRect //The source's round button, global — the capsule's home
    let pressPose: PressPose //The source button's press at takeoff — the hero relaxes out of it over the shed
    let cta: CGRect //The card's own CTA, global — the capsule's landing
    let ctaText: String
    let ctaFill: Color
    let coverShown: Bool
    let titleShown: Bool //The name morph's pieces outlive the cover's cut by their own fade
    let titleFade: Double
    let rimMounted: Bool //The landing rim's view exists from the landing on — mounted by a bare write, never inserted into a close in flight
    let shadow: Double //The card's resting shadow's strength (EventZoomChoreo.shadowStrength)

    //The dismiss drag scrubs the fold 1:1 with raw descent over this distance — the invite
    //popup's own constant, reused so the cards cannot drift
    private static let collapseDistance: CGFloat = 240

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(flightP, dragTravel), AnimatablePair(landingScale, breath)) }
        set {
            flightP = newValue.first.first
            dragTravel = newValue.first.second
            landingScale = newValue.second.first
            breath = newValue.second.second
        }
    }

    //SwiftUI removes a settled bounce-0 spring with a hair of travel still to come and snaps to
    //the target: ~0.35% of the flight on the sim (a 3px step of the whole band on the lens' 825px
    //descent, 60Hz) — the one visible tick left in an otherwise seamless landing, and one the cover
    //wears whether or not it has handed off. The open therefore poses everything off `p`, which
    //reaches 1 at this share of the raw spring: landed 1% early, at creep speed (~1px/frame), so
    //the removal's snap moves nothing on screen. The close and the drag read the raw value — their
    //landings are per-frame and end exactly on target.
    private static let settleShare: CGFloat = 0.99
    //The flying name is home by this share of the open's p, on a smoothstep — the capsule's own rule.
    //Following p linearly it was still ~7pt left of its slot through p's slow last tenth, jammed
    //against the affix word: "InviteJamie" for four frames before the space appeared (device
    //recording 2026-09-04). A close keeps the linear ride (device-verified).
    private static let heroArrival: CGFloat = 0.85

    func body(content: Content) -> some View {
        let p = chromeMix == 0 && flightP > 0 ? min(flightP / Self.settleShare, 1) : flightP
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

        //The card landing (EventZoomChoreo.landCard): p runs past 0 and the CENTRE carries on
        //through the slot along the path it flew — while the size, the corners and the heroes hold
        //their landed values (extrapolated they would grow, the card being larger than the band) —
        //and the whole stack recedes with the excursion, deepest at the deepest point, rising back
        //as the return eases home. A lens keeps raw p everywhere: its close spring's sub-percent
        //overshoot IS its inward pulse.
        let pLanded = shape.isLens ? p : max(p, 0)
        let travel = hypot(pagerLocal.midX - sourceLocal.midX, pagerLocal.midY - sourceLocal.midY)
        let past = cardLanding ? min(max(-p, 0) * travel / EventZoomChoreo.cardOvershoot, 1) : 0
        let sink = 1 - EventZoomChoreo.cardSinkDepth * past

        //max(…, 0): radii must never follow a degenerate size into the negatives
        let coverPath = lerp(sourceLocal, pagerLocal, p) //The straight path home, its centre free to run past the slot; the wind's belly rides on top
        let coverSize = lerp(sourceLocal, pagerLocal, pLanded).size
        let cover = CGRect(x: coverPath.midX - coverSize.width / 2 + bellyX,
                           y: coverPath.midY - coverSize.height / 2 + bellyY,
                           width: coverSize.width, height: coverSize.height)
        let coverRadius = max(shape.radius(for: cover.size), 0)
        //The source's shape → the pager's band: top corners to the card's, the bottom pair
        //flattening where the rows begin. The landing rim wears the same pair, pushed out
        let coverTopRadius = lerp(coverRadius, CornerRadius.image, pLanded)
        let coverBottomRadius = lerp(coverRadius, 0, pLanded)

        //The name morph, re-derived per frame off the interpolated cover so the word tracks the
        //growing band instead of aiming at a frozen endpoint. Nil — no marked name, or a title
        //that never spells it — leaves the plain title crossfade below exactly as it was.
        let nameMorph = EventZoomTitleMorph(title: title, name: titleName, sourceRect: titleSource,
                                            card: card, source: sourceLocal, cover: cover, p: pLanded,
                                            arrival: chromeMix == 0 ? Self.heroArrival : 1)

        //The fold: the window collapses onto the photo alone — the white rows wiped up into
        //the image. Two drivers, composed by max so the hand-off between them is seamless:
        //the dismiss DRAG scrubs it 1:1 with raw descent (linear, because the finger is
        //direct manipulation) and reverses with the snap-back; the committed CLOSE derives
        //it from the flight's own p (done by p = 0.6, chromeMix gating it to the close) —
        //never its own racing clock, so the rows provably lead the flight home and a
        //mid-fold release never jumps.
        let dragFold = min(max(dragTravel / Self.collapseDistance, 0), 1)
        //A card's tap-close landing folds 1:1 with p instead: the rows collapse into the photo at
        //the rate the photo travels, gone exactly as it reaches the slot — the early fold read as
        //the card collapsing first and the photo leaving after (device video 2026-09-03)
        let closeFold = cardLanding ? min(max(1 - p, 0), 1) : smoothstep((1 - p) / 0.4)
        let fold = max(chromeMix * closeFold, dragFold)
        //The open's breath (see the foot of this body), let out with the fold under a close or a drag. A
        //CARD source continues its own flight: each edge overshoots in proportion to how far IT travelled
        //— the Meet card grows mostly upward, so it keeps going mostly upward — with the farthest-moving
        //edge sized to `breathPeak`; the transform is the body's source→bounds lerp extrapolated past 1
        //(a scale about the centre plus the centre carrying on along its path). A uniform swell read as a
        //puff added at the end (device video 2026-09-04: the sides bulged 6pt having travelled 6pt). A
        //LENS grows out in every direction about equally, so its breath stays the uniform `breathGain`
        //swell — Arthur: the calendar's open is right, don't touch it.
        let (breathScale, breathShift) = Self.breathTransform(
            live: breath * (1 - fold), isLens: shape.isLens, source: sourceLocal, bounds: bounds)
        //A CARD breathes its SHELL only — the white body and its shadow, and the photo band as a header
        //(below) — while the laid-out content (rows, CTA, the title) stays put: the surface relaxes
        //around fixed type, so no word ever changes shape (a whole-stack breath stretched text ~3% at
        //the peak; Arthur, 2026-09-04). A LENS keeps breathing whole, untouched.
        let identity = CGSize(width: 1, height: 1)
        let shellScale = shape.isLens ? identity : breathScale
        let shellShift = shape.isLens ? CGSize.zero : breathShift
        let wholeScale = shape.isLens ? breathScale : identity
        let wholeShift = shape.isLens ? breathShift : CGSize.zero
        //The photo band under a card's shell breath is a HEADER, not a stretched picture: its top edge
        //rises with the card's top (the shell transform applied to the band's top and sides), its
        //FOOT stays fixed on the rows, and the extra height shows more photo — the picture is laid
        //out again in the taller frame and offset by half the growth so the pixels at the foot never
        //move (a portrait photo reveals more of its top; one with no spare height zooms uniformly
        //about the foot). Nothing is scaled non-uniformly, and the title at the foot stays put.
        let coverTopB = bounds.midY + (cover.minY - bounds.midY) * shellScale.height + shellShift.height
        let coverB = CGRect(x: bounds.midX + (cover.minX - bounds.midX) * shellScale.width + shellShift.width,
                            y: coverTopB,
                            width: cover.width * shellScale.width,
                            height: cover.maxY - coverTopB)
        let coverExtra = coverB.height - cover.height //Revealed at the top
        //The unfolded body: normally shrinking from the card's bounds onto the source as p runs
        //out, but a card's tap-close landing carries the WHOLE body down with the photo instead —
        //the drag's own geometry (the column rides the finger while the fold eats the rows) —
        //so the card visibly falls from its spot as it collapses, rather than deflating in place
        //(Arthur's finger demo, device video 2026-09-03)
        let body = cardLanding
            ? bounds.offsetBy(dx: cover.midX - pagerLocal.midX, dy: cover.midY - pagerLocal.midY)
            : lerp(sourceLocal, bounds, p).offsetBy(dx: bellyX, dy: bellyY)
        let window = lerp(body, cover, fold)
        let windowRadius = max(lerp(shape.radius(for: window.size), CornerRadius.image, pLanded), 0)

        //The button morph rides the revealed WINDOW, not the cover: its landing is on the card's
        //white foot rather than the artwork, and the window is exactly what the card is showing
        //this frame — so the capsule can never sit outside it, and a close's fold carries it back
        //onto the photo with the rows.
        let ctaMorph = EventZoomButtonMorph(source: buttonSource, cta: cta, text: ctaText, fill: ctaFill,
                                            card: card, sourceLocal: sourceLocal, bounds: bounds,
                                            window: window, p: pLanded)

        //The landing rim, a lens' alone: only a committed close shows it (chromeMix gates — the
        //open and the drag scrub never do). It is the COVER's own outline pushed out by a rim
        //that grows over the collapse's back half, so the glass visibly expands out of the
        //photo's edge as the photo shrinks into the lens — and, sharing the cover's centre, it
        //rides the wind's trajectory, bounce and settle-pop (which scales this whole stack)
        //with the image. Never anchored on the slot: p is the geometry clock, and the wind
        //close spends it (tGeo) while the cover is still out on the gust, so a slot-anchored
        //pad bloomed at the empty slot and slid out to meet the photo; a calm close from a lens
        //far from the band bloomed it uncovered the same way (device capture 2026-09-03). The
        //ledger's own ring is hidden for exactly this stretch (the anchor's `returning`) and
        //takes back a full-size ring at the landed commit, where the rim is full and the cover
        //is the source.
        let rim = glassRing * chromeMix * smoothstep((1 - p - 0.55) / 0.4)
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
        //The band's own content — the title's words — fades in riding the flight, not after it:
        //this body re-derives per frame, so the opacity genuinely tracks the growing window, full
        //just before touchdown where the land's reveal crossfades over already-identical words.
        //Hoisted out of the cover so the name morph shares one ramp.
        let arrive = smoothstep((p - 0.25) / 0.7)
        //The frost's capsule, posed as INSETS from the cover's foot exactly as the title is (the name
        //morph's rule): the band's measured glyph rect, its leading and bottom insets held against the
        //cover's own edges — never scaled with the cover, because the words it backs never are. At
        //p = 1 the cover is the band, so this IS the live page's capsule. Empty until the pager has
        //measured, which the flight waits out (`openWhenMeasured`).
        let bandTitle: CGRect? = pagerTitle.isEmpty ? nil : CGRect(
            x: pagerTitle.minX,
            y: coverB.height - (pagerLocal.height - pagerTitle.maxY) - pagerTitle.height,
            width: pagerTitle.width, height: pagerTitle.height)

        content
            .mask {
                RoundedRectangle(cornerRadius: windowRadius)
                    .frame(width: max(window.width, 1), height: max(window.height, 1))
                    .position(x: window.midX, y: window.midY)
            }
            //The card's shadow, cast by an opaque copy of the window's shape BEHIND the masked card
            //rather than by a `.shadow` on the card itself: a shadow is a layer effect, and a layer
            //effect above Liquid Glass rasterizes every lens beneath it — the flying button's copy
            //lost its rim against the resting button's (a snap at the tap), and the card's own glass
            //buttons were being flattened the same way. A sibling shape casts the identical shadow
            //and leaves the lenses live ([[project_ios26_glass_shadow_animation_gray]]'s rule).
            .background {
                RoundedRectangle(cornerRadius: windowRadius)
                    .fill(Color.white)
                    .frame(width: max(window.width, 1), height: max(window.height, 1))
                    .position(x: window.midX, y: window.midY)
                    .shadow(.card, strength: shadow)
                    //The shell's breath: about the card's centre — `.position` gave this view the card's
                    //whole frame, so `.center` is the card's, not the shape's
                    .scaleEffect(x: shellScale.width, y: shellScale.height, anchor: .center)
                    .offset(shellShift)
            }
            .overlay {
                //From the landing on (a bare write, no morph in flight), so a close never inserts
                //it mid-spring; dark until the rim has width, or its edge would fringe the cover's
                if glassRing > 0, rimMounted || chromeMix > 0 {
                    Color.clear
                        .frame(width: max(cover.width + 2 * rim, 1), height: max(cover.height + 2 * rim, 1))
                        .containerGlassEffect(clipped: true, shape: UnevenRoundedRectangle( //Clipped: the ledger ring's own no-shadow floor, matched
                            topLeadingRadius: coverTopRadius + rim, //Concentric: the cover's corner plus the rim between them
                            bottomLeadingRadius: coverBottomRadius + rim,
                            bottomTrailingRadius: coverBottomRadius + rim,
                            topTrailingRadius: coverTopRadius + rim))
                        .opacity(rim > 0 ? 1 : 0)
                        .position(x: cover.midX, y: cover.midY)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                if coverShown {
                    //The source end stays the raw photo the resting source shows, so takeoff
                    //matches its pixels too.
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .offset(y: coverExtra / 2) //The foot's pixels hold; the growth is revealed at the top
                        .frame(width: max(coverB.width, 1), height: max(coverB.height, 1))
                        .overlay {
                            if let chrome, chromeCopy > 0 {
                                //Laid out ONCE at the source's size and transform-ridden, never
                                //re-laid-out in flight — a glur or a scrim re-rendered at an
                                //animating size is the jitter the flight was tuned out of
                                chrome
                                    .environment(\.eventZoomTitleFlying, nameMorph != nil)
                                    .environment(\.eventZoomButtonFlying, buttonHero)
                                    .frame(width: max(source.width, 1), height: max(source.height, 1))
                                    .scaleEffect(x: cover.width / max(source.width, 1),
                                                 y: cover.height / max(source.height, 1))
                                    .opacity(chromeCopy)
                            }
                        }
                        .overlay {
                            //The band's own treatment — the capsule frost and the foot the live page
                            //wears — riding the flight on the title's ramp, laid out at the cover's
                            //size so the blur is of the pixels under it. Nothing at the source end
                            //(a raw photo, as the source shows), full before touchdown, and back out
                            //on the same ramp as the close shrinks the cover home.
                            //Mounted from takeoff: inserting it once its ramp began put its first layout
                            //into a mid-flight commit and dropped a frame there (sim capture 2026-09-04)
                            InvitePhotoBand(image: photo, titleRect: bandTitle).opacity(arrive)
                        }
                        .overlay(alignment: .bottomLeading) {
                            //Only when nothing is flying: a name morph draws the same line itself,
                            //in pieces, so the word can leave the rest of it behind
                            if let title, nameMorph == nil {
                                coverTitle(title, width: pager.width).opacity(arrive)
                            }
                        }
                        .invitePhotoEdgeFade(strength: arrive) //The page's softened foot, ridden in with the band
                        //What the fade shows through: the card's white, as on the page. Left open it
                        //showed the live page's OWN faded foot beneath, and two fades stacked read
                        //~40 levels darker than one — a hairline the hand-off then dissolved
                        .background(Color.white)
                        .clipShape(UnevenRoundedRectangle(
                            topLeadingRadius: coverTopRadius,
                            bottomLeadingRadius: coverBottomRadius,
                            bottomTrailingRadius: coverBottomRadius,
                            topTrailingRadius: coverTopRadius))
                        .modifier(CoverShadow(isLens: glassRing > 0, lens: lensShadow, card: cardShadow))
                        .position(x: coverB.midX, y: coverB.midY) //The header's frame under the shell breath (coverB == cover outside it)
                        .allowsHitTesting(false)
                }
            }
            //The name morph rides ABOVE the cover rather than inside it: the word is posed in the
            //card's space, and the cover's own rounded clip would crop it as the window changes
            //shape. It outlives the cover's cut by its own fade, taken away over the live pager's
            //identical line (`handOffCover`).
            .overlay {
                if titleShown, let nameMorph {
                    ZStack {
                        titleAffix(nameMorph).opacity(arrive)
                        titleHero(nameMorph)
                    }
                    .opacity(titleFade) //Posed from the band's fixed foot: stays put through the shell breath
                }
            }
            //The button morph, above the card's foot for the same reason the name is above the
            //cover: it is posed in the card's own space and no clip of the card's should crop it
            .overlay {
                if buttonHero, let ctaMorph { ctaHero(ctaMorph) }
            }
            //Window, cover and rim breathe together about the cover's centre — the wind's
            //settle-pop, the lens' landing breath and the card's sink alike; scaling the cover
            //alone would let the masked card's white peek out around the compressed circle.
            //Render-only, so the measured cardRect never feeds back into the flight's frames
            .scaleEffect(pop * landingScale * sink, anchor: UnitPoint(
                x: bounds.width > 0 ? cover.midX / bounds.width : 0.5,
                y: bounds.height > 0 ? cover.midY / bounds.height : 0.5))
            //The open's breath (breathScale/breathShift above, on EventZoomChoreo's breath clock). A
            //lens carries its whole landed stack past its size and back, a render transform since a
            //window cannot show more card than there is; a card breathes only its shell (see above),
            //so its cover→page cut waits for the breath to end (EventZoomChoreo.openWhenMeasured). The
            //fold fades it: a close or a drag begun mid-breath lets it out with the collapse, never cut.
            .scaleEffect(x: wholeScale.width, y: wholeScale.height, anchor: .center)
            .offset(wholeShift)
    }

    ///The breath's transform for this frame: a lens' uniform swell, or a card's continuation of its own
    ///flight (see the note where it is read in `body`)
    private static func breathTransform(live: CGFloat, isLens: Bool, source: CGRect, bounds: CGRect) -> (CGSize, CGSize) {
        if isLens {
            let k = 1 + EventZoomChoreo.breathGain * live
            return (CGSize(width: k, height: k), .zero)
        }
        let up = source.minY - bounds.minY //Each edge's travel, outward positive
        let down = bounds.maxY - source.maxY
        let leading = source.minX - bounds.minX
        let trailing = bounds.maxX - source.maxX
        let farthest = max(abs(up), abs(down), abs(leading), abs(trailing))
        let e = (farthest > 1 ? EventZoomChoreo.breathPeak / farthest : 0) * live
        let scale = CGSize(width: (bounds.width + e * (leading + trailing)) / max(bounds.width, 1),
                           height: (bounds.height + e * (up + down)) / max(bounds.height, 1))
        let shift = CGSize(width: e * (trailing - leading) / 2, height: e * (down - up) / 2)
        return (scale, shift)
    }

    private func coverTitle(_ title: String, width: CGFloat) -> some View {
        EventTitle(title: title)
            .frame(width: max(width, 1), alignment: .leading)
    }

    //The words either side of the name, held at the title's own slot on the cover. They arrive on
    //the ramp the whole title used to, so nothing about the line's appearance changes — only the
    //name has left it. Posed as ONE frame off the line's leading edge, both words offset inside
    //it, so the pair cannot drift from the single Text the live pager draws.
    private func titleAffix(_ morph: EventZoomTitleMorph) -> some View {
        let slot = morph.slot
        return ZStack(alignment: .topLeading) {
            Text(morph.prefix)
            Text(morph.suffix).offset(x: morph.nameOffset + slot.width)
        }
        .font(.title(morph.size, .bold))
        .foregroundStyle(Color.white)
        .lineLimit(1)
        .fixedSize()
        .frame(width: max(morph.lineWidth, 1), height: max(slot.height, 1), alignment: .topLeading)
        .position(x: slot.minX - morph.nameOffset + morph.lineWidth / 2, y: slot.midY)
        .allowsHitTesting(false)
    }

    //The name itself: ONE Text the whole way, never two replicas crossfading — that renders
    //doubled glyphs mid-flight. Laid out at the size it LANDS at and scaled UP toward the card,
    //so the touchdown the hand-off fades over is an unscaled word and only the takeoff magnifies.
    //A scale, never a font size: a font change snaps.
    //The circle widening into the wide CTA. The BODY is a flat capsule — a glass lens rebuilt at a
    //new size every frame costs about seven eighths of the frame rate (device evidence), so the one
    //lens in this flight is the real 42pt InviteButton riding the trailing cap, carrying its own
    //icon out. Underneath, the CTA's resting fill is there from frame one and the circle's tint
    //sheds off it, so the button never has to guess what it is becoming. The InviteButton is glass
    //over an opaque disc of this very colour, and the compose CTA is flat in it, so this stack IS
    //the resting circle at t = 0 and IS the resting CTA at t = 1 — nothing to reveal at either end.
    //The lens stays LIVE only because nothing above it is a layer effect: the card's shadow is a
    //shape behind the window, not a `.shadow` on the card (see the morph's body).
    private func ctaHero(_ morph: EventZoomButtonMorph) -> some View {
        let rect = morph.rect
        return ZStack {
            Capsule().fill(morph.fill).opacity(buttonFade)
            Capsule().fill(InviteButton.tint).opacity(morph.shed * buttonFade)
        }
        .frame(width: max(rect.width, 1), height: max(rect.height, 1))
        .overlay {
            //The word sits where it LANDS from its first frame, so the capsule's settle plays out
            //around a still label rather than carrying it — a word riding an overshoot wobbles.
            //Arriving late enough that the capsule already reaches past it (see `label`).
            Text(morph.text)
                .font(.body(18, .bold)) //WideActionButton's own default, which this CTA takes
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .fixedSize()
                .scaleEffect(Self.labelShrunkScale + (1 - Self.labelShrunkScale) * morph.label)
                .opacity(morph.label)
                .position(x: morph.labelX - rect.minX, y: rect.height / 2)
        }
        .overlay(alignment: .trailing) {
            //Glass may move, never resize: fixed 42pt. The button pins its own lens look (its white
            //well), so what the capsule and the fading chrome copy beneath do never reaches the lens.
            //It takes off wearing the press the finger released it in — a deliberate press grows the
            //disc 22% and brightens it — and relaxes to rest on the shed's ramp, so no frame steps
            //between the pressed source and the flying copy (a one-frame 8pt snap, sim 2026-09-04)
            InviteButton(onTap: { })
                .scaleEffect(1 + (pressPose.scale - 1) * morph.shed)
                .brightness(pressPose.brightness * morph.shed)
                .opacity(morph.shed)
        }
        .position(x: rect.midX, y: rect.midY)
        .allowsHitTesting(false)
    }

    //The word's arrival scale: a breath, not the house pop's 0.7 — it lands inside a moving shape
    private static let labelShrunkScale: CGFloat = 0.92

    private func titleHero(_ morph: EventZoomTitleMorph) -> some View {
        let hero = morph.hero
        return Text(morph.name)
            .font(.title(morph.size, .bold))
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .fixedSize()
            .scaleEffect(hero.height / max(morph.slot.height, 1), anchor: .center)
            .position(x: hero.midX, y: hero.midY)
            .allowsHitTesting(false)
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

//The name the source card and the card's own title share, and where each piece of the line sits
//this frame. Both ends are DERIVED from the title's insets and the font's metrics rather than
//measured at the far end: a live measurement holds model values, so a rect read mid-flight would
//aim the word at wherever the cover had already reached
//([[measured-frames-dont-track-animation]]). The source end is the one real measurement, taken on
//the resting label before it ever moves.
struct EventZoomTitleMorph {

    let name: String
    let prefix: String
    let suffix: String
    let size: CGFloat //What the title lands at — EventTitle's own rule, so the two cannot drift
    let nameOffset: CGFloat //Line start → name start: what the words before it take up
    let lineWidth: CGFloat //The whole title at the landing size — the affix pair's frame
    let slot: CGRect //The title's name slot on this frame's cover: the affix's line, and the word's landing
    let hero: CGRect //Where the flying word is this frame

    ///nil unless a source marked a name AND this title spells it: a confirm screen's own copy has
    ///no name to fly, and a flight that cannot anchor keeps the plain crossfade rather than
    ///blanking a word it has nothing to replace with
    init?(title: String?, name: String?, sourceRect: CGRect, card: CGRect,
          source: CGRect, cover: CGRect, p: CGFloat, arrival: CGFloat = 1) {
        guard let title, let name, !name.isEmpty, sourceRect.width > 1,
              let range = title.range(of: name) else { return nil }
        self.name = name
        prefix = String(title[title.startIndex..<range.lowerBound])
        suffix = String(title[range.upperBound...])
        size = EventTitle.size(for: title)

        let font = UIFont.title(size, .bold)
        let word = Self.measure(name, font)
        nameOffset = Self.measure(prefix, font).width
        lineWidth = Self.measure(title, font).width

        //imageHorizontalPadding / imageBottomPadding: the title's OWN insets, read from where
        //EventTitle draws them, so the landing cannot drift from the live pager's line
        slot = CGRect(x: cover.minX + imageHorizontalPadding + nameOffset,
                      y: cover.maxY - imageBottomPadding - word.height,
                      width: word.width, height: word.height)

        //The word is posed as INSETS FROM THE COVER, never as a lerp between two screen rects.
        //The cover does not merely travel, it SHRINKS — a 1/1.2 card into a 1/0.8 band — so its
        //foot rises fast, and a straight rect lerp leaves the word hanging below it for most of
        //the flight (white on the card's white rows, invisible) before snapping up at the landing.
        //Held against the cover's own edges it can never leave the artwork.
        let label = card.width > 1 ? sourceRect.offsetBy(dx: -card.minX, dy: -card.minY)
                                   : CGRect(origin: .zero, size: sourceRect.size)
        //Clamped: a lens close keeps raw p, and its spring's rebound carries it below 0 — a word that
        //undershot its own size would read as a wobble. Its position still rides the cover, because
        //the insets hang off `cover`. An open hands `arrival` < 1: the word eases home by that share
        //of p and parks, instead of trailing p's slow last tenth into the affix word.
        let clamped = min(max(p, 0), 1)
        let t = arrival < 1 ? Self.smoothstep(clamped / arrival) : clamped
        let height = Self.lerp(label.height, word.height, t)
        hero = CGRect(
            x: cover.minX + Self.lerp(label.minX - source.minX, imageHorizontalPadding + nameOffset, t),
            y: cover.maxY - Self.lerp(source.maxY - label.maxY, imageBottomPadding, t) - height,
            width: Self.lerp(label.width, word.width, t),
            height: height)
    }

    private static func measure(_ string: String, _ font: UIFont) -> CGSize {
        string.isEmpty ? .zero : (string as NSString).size(withAttributes: [.font: font])
    }

    private static func smoothstep(_ t: CGFloat) -> CGFloat {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }

    private static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

//The source card's round button and the card's own wide CTA, and where the one capsule that stands
//for both sits this frame. Both ends are MEASURED — the old derivation of this rect double-counted
//the button's render offset and shipped 4pt out at both the tap and the hand-off
//([[project_quickinvite_flight]]'s render-offset asymmetry).
struct EventZoomButtonMorph {

    let text: String
    let fill: Color //What the CTA rests at: the capsule wears it from frame one and sheds the tint off it
    let rect: CGRect //Where the capsule is this frame, in the card's space
    let labelX: CGFloat //The word's centre, in the card's space — the CTA's own, from the word's first frame
    let shed: CGFloat //The circle's tint AND its lens leaving together — the button's identity departing
    let label: CGFloat //The CTA's word arriving, 0→1 — on the flight's geometry, never a clock of its own

    //The width's own curve, on the flight's geometry. The flight's spring is critically damped —
    //bounce 0, chosen so the title does not wobble; the card's over-expansion is a separate breath
    //the whole card wears, this capsule included, never a width of its own — and a width that
    //follows p linearly spends its last tenth as a visibly creeping edge (~150ms on device). So
    //the width eases in and out over the WHOLE flight — one smoothstep of p, full exactly at touchdown — and decelerates into place
    //with nothing left to settle: an earlier cut (full at 0.9 of the flight, then a 2% overshoot
    //settle) read as a bounce (Arthur, 2026-09-04) and was taken out. With p already easing, the
    //last tenth of the flight moves under 3% of the travel, so the edge slows rather than creeps.
    //The label is posed at its landing centre, so the edge arrives around a still word.

    ///nil until the source has been measured: a flight that cannot anchor leaves both buttons their
    ///own fades rather than ghosting a CTA it has nothing to replace with. The card's CTA reports a
    ///frame after the mount; until then the capsule sits on the source (p is 0 that early).
    init?(source: CGRect, cta: CGRect, text: String, fill: Color,
          card: CGRect, sourceLocal: CGRect, bounds: CGRect, window: CGRect, p: CGFloat) {
        guard source.width > 1, card.width > 1 else { return nil }
        self.text = text
        self.fill = fill

        let from = source.offsetBy(dx: -card.minX, dy: -card.minY)
        let to = cta.width > 1 ? cta.offsetBy(dx: -card.minX, dy: -card.minY) : from
        let t = cta.width > 1 ? min(max(p, 0), 1) : 0

        //Posed as insets from the revealed window, never as a lerp between two screen rects — the
        //same rule the name morph pays. Both trailing insets are the cards' own 24pt, which is what
        //makes the open read as a pure leftward stretch rather than a slide. At p = 1 the window is
        //the card's bounds and this resolves to the CTA's rect exactly — no pin needed.
        let open = Self.smoothstep(t)
        let width = Self.lerp(from.width, to.width, open)
        let height = Self.lerp(from.height, to.height, open)
        let trailing = Self.lerp(sourceLocal.maxX - from.maxX, bounds.maxX - to.maxX, t)
        let bottom = Self.lerp(sourceLocal.maxY - from.maxY, bounds.maxY - to.maxY, t)
        rect = CGRect(x: window.maxX - trailing - width,
                      y: window.maxY - bottom - height,
                      width: width, height: height)
        labelX = to.midX

        //Tint and lens leave together over the first third: past that the capsule is too far from a
        //circle for the 42pt lens to sit on it honestly
        shed = 1 - Self.smoothstep(t / 0.35)
        //The word arrives once the capsule reaches past its landing centre, and is full by t = 0.95,
        //provably crisp before the landing — see the note on the leaf: a pop with a spring of its
        //own outlives the hand-off
        label = Self.smoothstep((t - 0.7) / 0.25)
    }

    private static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    private static func smoothstep(_ t: CGFloat) -> CGFloat {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
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
