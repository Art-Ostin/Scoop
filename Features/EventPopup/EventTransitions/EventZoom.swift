//
//  EventZoom.swift
//  Scoop
//
//  Created by Art Ostin on 31/08/2026.
//

import SwiftUI


extension View {

    func eventZoomHost(_ host: EventZoomHost) -> some View {
        modifier(EventZoomHostModifier(host: host))
    }
    func eventZoomSource(_ image: UIImage, shape: EventZoomSourceShape = .rounded()) -> some View {
        modifier(EventZoomSourceModifier(image: image, shape: shape, chrome: nil))
    }

    func eventZoomSource<Chrome: View>(_ image: UIImage, shape: EventZoomSourceShape = .rounded(),
                                       @ViewBuilder chrome: @escaping () -> Chrome) -> some View {
        modifier(EventZoomSourceModifier(image: image, shape: shape, chrome: { AnyView(chrome()) }))
    }

    func eventZoomTitleSource(_ name: String) -> some View {
        modifier(EventZoomTitleSourceModifier(name: name))
    }

    func eventZoomTimeSource(_ text: String) -> some View {
        modifier(EventZoomRowSourceModifier(kind: .time, text: text))
    }

    func eventZoomPlaceSource(_ text: String) -> some View {
        modifier(EventZoomRowSourceModifier(kind: .place, text: text))
    }

    func eventZoomRowTarget(_ kind: EventZoomRowKind, text: String, active: Bool = true) -> some View {
        modifier(EventZoomRowTargetModifier(kind: kind, text: text, active: active))
    }

    func eventZoomButtonSource() -> some View {
        modifier(EventZoomButtonSourceModifier())
    }

    func eventZoomButtonTarget(text: String, fill: Color,
                               font: Font = .body(18, .bold), lineLimit: Int = 1) -> some View {
        modifier(EventZoomButtonTargetModifier(text: text, fill: fill, font: font, lineLimit: lineLimit))
    }

    func eventZoomCornerSource<Look: View>(@ViewBuilder look: @escaping () -> Look) -> some View {
        modifier(EventZoomCornerSourceModifier(look: { AnyView(look()) }))
    }

    func eventZoomCornerTarget<Look: View>(inset: EdgeInsets = EdgeInsets(), visible: Bool = true,
                                           @ViewBuilder look: @escaping () -> Look) -> some View {
        modifier(EventZoomCornerTargetModifier(inset: inset, visible: visible, look: { AnyView(look()) }))
    }

    func eventZoom<Card: View>(isPresented: Binding<Bool>, inset: CGFloat = Spacing.gutter,
                               @ViewBuilder card: @escaping () -> Card) -> some View {
        modifier(EventZoomModifier(isPresented: isPresented, inset: inset, card: { AnyView(card()) }))
    }

    func eventZoomChevronHidden(_ hidden: Bool = true) -> some View {
        modifier(EventZoomChevronHiddenModifier(hidden: hidden))
    }

    func eventZoomLeadingAction(_ title: String, action: @escaping (EventZoomDeparture) -> Void) -> some View {
        modifier(EventZoomLeadingActionModifier(title: title, action: action))
    }

    func eventZoomDragLocked(_ locked: Bool) -> some View {
        modifier(EventZoomDragLockedModifier(locked: locked))
    }

    func eventZoomDragExclusion() -> some View {
        modifier(EventZoomDragExclusionModifier())
    }

    //`focused` is the body's raw focus: what holds the drag and the chevron and hands the backdrop's tap to `resign`.
    //`riding` is the body's own flag for the MOTION, flipped in the commit its contents start to move in: the shell
    //raises and widens the card in that same commit, on `.keyboard`, so the card and what is in it are one ride
    func eventZoomKeyboardFocus(_ focused: Bool, riding: Bool, extraLift: CGFloat = 0, resign: @escaping () -> Void) -> some View {
        modifier(EventZoomKeyboardFocusModifier(focused: focused, riding: riding, extraLift: extraLift, resign: resign))
    }

    //Marks where a body's lowest control would end once its field has the card: the shell lifts the card until that
    //foot clears the keyboard. A measure only — it moves nothing
    func eventZoomKeyboardClearance() -> some View {
        modifier(EventZoomKeyboardClearanceModifier())
    }

    //A control on the KEYBOARD's line (the respond note's Done). The shell draws it, in the plane, its foot a
    //clearance above the keyboard — never in the card, which is mid-ride whenever the control has to appear
    func eventZoomKeyboardAccessory(_ title: String, visible: Bool, action: @escaping () -> Void) -> some View {
        modifier(EventZoomKeyboardAccessoryModifier(title: title, visible: visible, action: action))
    }

    func eventZoomBandChrome(visible: Bool = true) -> some View {
        modifier(EventZoomBandChromeModifier(onPage: visible, corner: nil, copy: nil))
    }

    func eventZoomBandChrome<Copy: View>(visible: Bool = true, corner: EventZoomBandCorner,
                                         @ViewBuilder copy: @escaping () -> Copy) -> some View {
        modifier(EventZoomBandChromeModifier(onPage: visible, corner: corner, copy: { AnyView(copy()) }))
    }

    func eventZoomAlert(
        isPresented: Binding<Bool>,

        title: String,
        emoji: String = "🦥",
        message: String,

        cancelTitle: String = "Cancel",
        okTitle: String = "OK",

        offset: CGFloat = 0,

        onOK: @escaping () -> Void,
        onCancel: (() -> ())? = nil
    ) -> some View {
        modifier(
            EventZoomAlertModifier(
                isPresented: isPresented,
                alert: AlertRequest(
                    title: title,
                    emoji: emoji,
                    message: message,
                    cancelTitle: cancelTitle,
                    okTitle: okTitle,
                    offset: offset,
                    onOK: onOK,
                    onCancel: onCancel
                )
            )
        )
    }
}

enum EventZoomSourceShape: Equatable {
    case circle(ring: CGFloat = 0, tint: Color? = nil)
    case rounded(CGFloat = CornerRadius.image)

    var ring: CGFloat {
        if case .circle(let ring, _) = self { ring } else { 0 }
    }

    ///The lens' glass tint — the close's rim fades it in, so the photo lands on the resting ring's own colour. Nil for a plain lens and every card
    var tint: Color? {
        if case .circle(_, let tint) = self { tint } else { nil }
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

///A card handed over by its leading action (`.eventZoomLeadingAction`), as it stands on screen: what a
///caller needs to carry it onto another plane. Rects are global and at rest, the column's lift included
struct EventZoomDeparture {
    let ready: Bool //Landed on a whole page, everything below measured; false: a caller may only fade
    let waited: Duration //How long the tap waited for that landing: zero when the card went in the tap's own turn
    let card: CGRect //As DRAWN: at rest, but for the open's breath while it lasts — a card taken in its first second is still swollen a few points
    let band: CGRect //The pager band, as drawn
    let photo: UIImage? //The page on screen, as the pager draws it (decoded)
    let source: UIImage? //The caller's own image at that page: the identity a landing matches
    let page: Int
    let pageCount: Int
    let chevronSlotY: CGFloat //Global top of the chevron's row, where the buttons stood when tapped
    let leadingTitle: String? //The leading action's label, so a copy of the row can pop away as the card leaves
    let hide: @MainActor () -> Void //Hides the card, its buttons and its material, in the turn a caller's copy of all three stands over them
    let restore: @MainActor () -> Void //Hands the card back before anything left: card, buttons and material show again, touches return
}

///What the morph drew last frame beyond the rects it was handed: the open's breath. A caller that takes the card while it
///still breathes must leave from where the card IS, not from where it will rest (`EventZoomDeparture.card`)
final class EventZoomDrawnBreath {
    private(set) var scale = CGSize(width: 1, height: 1) //About the card's centre
    private(set) var shift = CGSize.zero
    private(set) var lift: CGFloat = 0 //A card source's contents, this high inside the outline

    func record(scale: CGSize, shift: CGSize, lift: CGFloat) {
        (self.scale, self.shift, self.lift) = (scale, shift, lift)
    }

    ///`rect` (global, at rest) as the breath draws it this frame, about `centre`
    func drawn(_ rect: CGRect, about centre: CGPoint, lifted: Bool = false) -> CGRect {
        let rect = lifted ? rect.offsetBy(dx: 0, dy: -lift) : rect
        return CGRect(x: centre.x + (rect.minX - centre.x) * scale.width + shift.width,
                      y: centre.y + (rect.minY - centre.y) * scale.height + shift.height,
                      width: rect.width * scale.width, height: rect.height * scale.height)
    }
}

///The page an `EventImagePager` shows, pushed to its flight on every change
struct EventZoomVisiblePage: Equatable {
    let index: Int
    let count: Int
    let photo: UIImage
    let source: UIImage?
    let atRest: Bool //Settled on a whole page, the live carousel mounted
}

///Which corner of the pager band a chrome piece hangs from — the alignment its `.overlay` takes, and
///so the corner of the flying cover its twin is held against. Pinned, never scaled: the cover does not
///merely travel, it SHRINKS (an invite card's 1/1.55 into the band's 1/0.8), and a rect lerp would leave
///the piece hanging off the artwork for most of the flight before snapping home (`EventZoomTitleMorph`'s
///rule, and `bandTitle`'s).
enum EventZoomBandCorner {
    case topLeading, topTrailing, bottomLeading, bottomTrailing

    var alignment: Alignment {
        switch self {
        case .topLeading: .topLeading
        case .topTrailing: .topTrailing
        case .bottomLeading: .bottomLeading
        case .bottomTrailing: .bottomTrailing
        }
    }

    ///The corner as unit factors of a rect — 0 leading/top, 1 trailing/bottom. LTR: `Alignment` is
    ///layout-direction-aware and this is not, so under RTL a twin would be pinned to the opposite edge
    ///of its box mid-flight. Harmless at the seam either way — at p = 1 the box IS the band, where both
    ///resolve to the live overlay — and the app ships no RTL layout; flip x here if it ever does.
    var unit: CGPoint {
        switch self {
        case .topLeading: CGPoint(x: 0, y: 0)
        case .topTrailing: CGPoint(x: 1, y: 0)
        case .bottomLeading: CGPoint(x: 0, y: 1)
        case .bottomTrailing: CGPoint(x: 1, y: 1)
        }
    }
}

///One piece of band chrome, twinned to ride the flying cover. Built ONCE, at takeoff — the source
///chrome copy's rule: the same value every frame, so the twin's body never re-runs in flight.
struct EventZoomBandChromeCopy: Identifiable {
    let id: UUID
    let corner: EventZoomBandCorner
    let view: AnyView
    let popsIn: Bool //A takeoff's twin arrives on the house pop; a close's only fades — no lens resized per frame on the way out
}

///What a band-chrome piece is doing this frame.
///`.arriving` is the state only a twinned piece has: painted at full, behind a twin that still owns the
///corner, so its glass takes its first paint under the cover. A lens held at opacity 0 never samples a
///backdrop and warms up on screen when revealed (+35 levels, sim 2026-09-04) — the very reason the card's
///own CTA is un-ghosted at the landing behind an opaque capsule. It is NOT hit-testable there: the finger
///can only see the twin.
enum EventZoomBandChromePhase: Equatable { case hidden, arriving, live }

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
    ///As above, for the source's time and place lines while the row heroes own them
    @Entry var eventZoomRowsFlying = false
    ///The source's corner capsule inside that copy (`.eventZoomCornerSource`): `.inert` draws its look with no
    ///Button under it — interactive glass claims taps whatever the cover yields — and `.ghost` keeps only its
    ///slot while the corner hero draws it. The resting source is `.live`
    @Entry var eventZoomCornerSource = EventZoomCopyRole.live
    ///True on the band's flying twins while the corner hero draws their landing disc: the twin keeps its slot, no glass
    @Entry var eventZoomCornerMorphing = false
    ///The band-chrome piece a view is laid out in — what a corner landing measures itself against
    @Entry var eventZoomBandPiece: EventZoomBandPiece? = nil
}

///How a piece a flight copies draws on this frame
enum EventZoomCopyRole { case live, inert, ghost }

//MARK: - The corner a flight morphs

///How the corner hero leaves on a close. `.morph` flies the landing disc back into the source's capsule (a tap,
///a programmatic close); `.fade` lets the landing control fade out with the band's twins while the capsule
///fades back in over the collapse's last stretch (a swipe — the finger's close keeps its calm morph home)
enum EventZoomCornerMode { case morph, fade }

///The disc the source's corner capsule lands on, as the body lays it out: its inset from the corner its band
///piece hangs from, and its size. Measured inside the band-chrome modifier's own coordinate space, so the
///piece's pop scale — 0.4 for the whole open — never reaches the numbers
struct EventZoomCornerLanding: Equatable {
    let corner: EventZoomBandCorner
    let inset: CGSize //From that corner, along each axis
    let size: CGSize
    let visible: Bool //The body's own hide (a popup, a focused note): nothing flies back to a corner nobody can see
}

///The band-chrome piece a view sits in: the corner it hangs from and its laid-out size
struct EventZoomBandPiece: Equatable {
    let corner: EventZoomBandCorner
    let size: CGSize
}

///The corner hero on this frame, resolved by the choreography from what it took at takeoff or at the close's
///start. No landing means nothing to morph into: the hero then only carries the capsule on its source insets,
///fading with the collapse exactly where the chrome copy's own capsule would have
struct EventZoomCornerFlight {
    let mode: EventZoomCornerMode
    let source: CGRect //Global — where the source card draws the capsule
    let sourceLook: AnyView
    let landing: EventZoomCornerLanding?
    let landingLook: AnyView?

    ///A disc was taken and can be seen: the hero draws it — morphing on the open and a tap, fading on a swipe — so a
    ///twin keeps only its slot
    var landingTaken: Bool { landing?.visible == true && landingLook != nil }

    ///The capsule and the disc are one shape changing between the two ends
    var morphs: Bool { mode == .morph && landingTaken }
}

//One corner landing marker's latest reports (`EventZoomChoreo.cornerTargets`)
private struct EventZoomCornerTargetReport {
    let order: Int //When this marker first reported: the newest mount is the disc on screen
    var landing: EventZoomCornerLanding?
    var look: (() -> AnyView)?
}

//MARK: - The rows a flight carries

///Which line a row hero is. The set is open by design — the type chip is the next one — but each
///kind must be marked at BOTH ends before it flies: a kind with only one end measured keeps the
///plain fades, so a source that draws no rows (the meet card) pays nothing for this.
enum EventZoomRowKind: Hashable, CaseIterable {
    case time
    case place

    //The two ends' artwork. The card's is a white template glyph on the photo, the body's is drawn
    //art on paper — a material change, dissolved in one shared slot rather than moved between two.
    var sourceIcon: ImageResource {
        switch self {
        case .time: .whiteClock
        case .place: .whiteMap
        }
    }

    var landingIcon: ImageResource {
        switch self {
        case .time: .eventClockIcon
        case .place: .eventMapIcon
        }
    }
}

///One row's two ends, resolved for this frame: where each draws it and what each says. Built by the
///choreography from the measured stores; the geometry itself is the morph's, per frame.
struct EventZoomRowFlight: Equatable {
    let kind: EventZoomRowKind
    let source: CGRect //Global — where the source card draws the row
    let sourceText: String
    let dest: CGRect //Global, derived from the card's own frame — where the opened card draws it
    let text: String
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
    //The lines the card draws that the opened card draws again, global — each row hero's home, and
    //what the source end says. Keyed rather than one field per line: the set grows (the type chip
    //is next), and a kind absent here simply never flies.
    @ObservationIgnored var rowRects: [EventZoomRowKind: CGRect] = [:]
    @ObservationIgnored var rowTexts: [EventZoomRowKind: String] = [:]
    @ObservationIgnored var pressPose: PressPose = .rest //That button's press as rendered — the hero takes off from it
    @ObservationIgnored var cornerRect: CGRect = .zero //The source's corner capsule, global — the corner hero's home
    @ObservationIgnored var cornerLook: (() -> AnyView)? //That capsule drawn inert, pushed every pass — taken once, at present
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

private struct EventZoomRowSourceModifier: ViewModifier {

    //Injected
    @Environment(EventZoomAnchor.self) private var anchor: EventZoomAnchor?
    @Environment(\.eventZoomRowsFlying) private var flying: Bool
    let kind: EventZoomRowKind
    let text: String

    func body(content: Content) -> some View {
        //Written every pass, like the title's name and for the same reason: the chrome COPY renders
        //on the flight's plane, where there is no anchor to write to — it reports nothing and reads
        //only the flag below.
        anchor?.rowTexts[kind] = text
        return content
            .opacity(flying ? 0 : 1) //A layout ghost: the hero owns the icon and the words
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { anchor?.rowRects[kind] = $0 }
    }
}

//On the card body's own row, so it reports to the flight rather than the anchor: the landing pad is
//inside the card, not on the source. It ghosts while the row flies and takes the pixels back at the
//landing — behind a hero still at full, never as one leaves.
private struct EventZoomRowTargetModifier: ViewModifier {

    //Injected
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    let kind: EventZoomRowKind
    let text: String
    let active: Bool

    //Inert rather than absent when a mount is not the landing: the flag is fixed for the life of a
    //mount, but branching the modifier chain on it would still make two different view identities
    //out of one row for no gain.
    func body(content: Content) -> some View {
        content
            .opacity(active && flight?.rowGhosted(kind) == true ? 0 : 1)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(EventZoomChoreo.cardSpace)) } action: { rect in
                guard active else { return }
                flight?.reportRow(kind, rect: rect)
            }
            .onChange(of: text, initial: true) {
                guard active else { return }
                flight?.reportRowText(kind, text: $1)
            }
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
    let font: Font
    let lineLimit: Int

    func body(content: Content) -> some View {
        content
            .opacity(flight?.ctaGhosted == true ? 0 : 1)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(EventZoomChoreo.cardSpace)) } action: { flight?.reportCTA($0) }
            //One report per look, not one per property: a CTA whose text and font change together
            //(the respond card's type switch) must never leave the capsule wearing half of each
            .onChange(of: Look(text: text, fill: fill, font: font, lineLimit: lineLimit), initial: true) {
                flight?.reportCTALook(text: $1.text, fill: $1.fill, font: $1.font, lineLimit: $1.lineLimit)
            }
    }

    ///The four together, so one `onChange` carries a look that changes as a unit
    private struct Look: Equatable {
        let text: String
        let fill: Color
        let font: Font
        let lineLimit: Int
    }
}

//On the source card's corner capsule. Unlike the button's, it has no ghost of its own: the control draws
//inert, or keeps only its slot, off `eventZoomCornerSource` — a modifier cannot take the Button out from
//under a label. No reset on disappear: the invite card gates it on its draft, which is fixed for the
//anchor's whole life, and a tab switch's disappear would otherwise wipe a rect no layout re-reports.
private struct EventZoomCornerSourceModifier: ViewModifier {

    //Injected
    @Environment(EventZoomAnchor.self) private var anchor: EventZoomAnchor?
    let look: () -> AnyView

    func body(content: Content) -> some View {
        //Pushed every pass, as the source pushes its chrome: present() takes the latest. The copy riding
        //the cover has no anchor, so it reports nothing
        anchor?.cornerLook = look
        return content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { anchor?.cornerRect = $0 }
    }
}

//On the landing disc, inside a band-chrome piece of the card body, so it reports to the flight: where the
//disc sits from the piece's corner, read in the piece's OWN space — the band-chrome modifier installs it
//inside the pop that scales the piece to 0.4 for the whole open, so the numbers never carry that scale.
//Inside a twin there is no flight in the environment, and it reports nothing.
private struct EventZoomCornerTargetModifier: ViewModifier {

    //Injected
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    @Environment(\.eventZoomBandPiece) private var piece: EventZoomBandPiece?
    let inset: EdgeInsets
    let visible: Bool
    let look: () -> AnyView

    //Local view state
    @State private var id = UUID() //Its claim on the landing: a type switch mounts the next disc before this one leaves
    @State private var frame: CGRect = .zero //The marked view, in its piece's space

    func body(content: Content) -> some View {
        flight?.reportCornerLook(id: id, look: look) //Pushed every pass, unobserved — the flight takes it once per flight
        return content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(EventZoomChoreo.bandPieceSpace)) } action: { rect in
                frame = rect
                report(rect)
            }
            .onChange(of: piece) { report(frame) }
            .onChange(of: visible) { report(frame) }
            .onDisappear { flight?.dropCornerTarget(id: id) }
    }

    private func report(_ rect: CGRect) {
        guard let flight, let piece, piece.size.width > 1, rect.width > 1 else { return }
        let disc = CGRect(x: rect.minX + inset.leading, y: rect.minY + inset.top,
                          width: rect.width - inset.leading - inset.trailing,
                          height: rect.height - inset.top - inset.bottom)
        let unit = piece.corner.unit
        flight.reportCornerLanding(id: id, EventZoomCornerLanding(
            corner: piece.corner,
            inset: CGSize(width: unit.x == 1 ? piece.size.width - disc.maxX : disc.minX,
                          height: unit.y == 1 ? piece.size.height - disc.maxY : disc.minY),
            size: disc.size,
            visible: visible))
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

private struct EventZoomLeadingActionModifier: ViewModifier {

    //Injected
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    let title: String
    let action: (EventZoomDeparture) -> Void

    func body(content: Content) -> some View {
        flight?.reportLeadingAction(action) //Pushed every pass, unobserved like the band's builders: a tap runs what the LATEST body built
        return content.onChange(of: title, initial: true) { _, title in flight?.setLeadingActionTitle(title) }
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

private struct EventZoomKeyboardFocusModifier: ViewModifier {

    //Injected
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    let focused: Bool
    let riding: Bool
    let extraLift: CGFloat
    let resign: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: focused, initial: true) { _, focused in flight?.setKeyboardFocus(focused, extraLift: extraLift, resign: resign) }
            .onChange(of: riding, initial: true) { _, riding in flight?.setKeyboardRide(riding) }
    }
}

private struct EventZoomKeyboardClearanceModifier: ViewModifier {

    //Injected
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?

    //Local view state
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            //As a height above the CARD's own foot, never a place on the screen: a global foot carries the column's raise
            //as it stands that frame, mid-spring, against the model's whole raise
            .background {
                Color.clear
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        //The card's bounds come back in THIS view's own space, where its foot is its height
                        guard let card = proxy.bounds(of: .named(EventZoomChoreo.cardSpace)) else { return .nan }
                        return card.maxY - proxy.size.height
                    } action: { flight?.reportKeyboardFoot(id: id, aboveCardFoot: $0.isNaN ? nil : $0) }
            }
            .onDisappear { flight?.reportKeyboardFoot(id: id, aboveCardFoot: nil) }
    }
}

private struct EventZoomKeyboardAccessoryModifier: ViewModifier {

    //Injected
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    let title: String
    let visible: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        flight?.reportKeyboardAccessory(action) //Pushed every pass, unobserved like the leading action's: a tap runs what the LATEST body built
        return content
            .onChange(of: title, initial: true) { _, title in flight?.setKeyboardAccessory(title: title) }
            .onChange(of: visible, initial: true) { _, visible in flight?.setKeyboardAccessory(visible: visible) }
            .onDisappear { flight?.setKeyboardAccessory(title: nil) }
    }
}

///The keyboard accessory's face. The body lays a hidden one out where the control would hang in the card (its
///`.eventZoomKeyboardClearance()` slot), so the slot and the control the shell draws can never disagree on a size
struct EventKeyboardAccessoryLabel: View {

    //Injected
    let title: String

    var body: some View {
        Text(title)
            .font(.body(14, .bold))
            .padding(Spacing.sm)
            .padding(.horizontal, Spacing.xxs)
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
    let corner: EventZoomBandCorner? //Where it hangs — nil unless a twin of it flies
    let copy: (() -> AnyView)?

    //Local view state
    @State private var id = UUID() //Its claim on the flight's twin list (the drag exclusions' pattern)
    @State private var size: CGSize = .zero //Its laid-out size, for a corner landing measured inside it

    func body(content: Content) -> some View {
        //Pushed every pass and stored unobserved, exactly as the source pushes its own chrome closure
        //(`EventZoomSourceModifier`): the flight takes what the card's LATEST body built and calls it
        //ONCE, before takeoff. A closure captured at appearance would fly a stale page. Free only
        //because the store is @ObservationIgnored — an observed write from inside a body would loop.
        if let copy, let corner {
            flight?.reportBandChrome(id: id, corner: corner, onPage: onPage, copy: copy)
        }
        let phase = flight?.bandChrome(twinnedId: copy == nil ? nil : id) ?? .live //No flight: the piece simply rests
        let visible = onPage && phase != .hidden
        return content
            //Its own space and size, INSIDE the pop: a corner landing measured in here never carries the 0.4 the
            //piece wears for the whole open (`.eventZoomCornerTarget`)
            .coordinateSpace(.named(EventZoomChoreo.bandPieceSpace))
            .environment(\.eventZoomBandPiece, corner.map { EventZoomBandPiece(corner: $0, size: size) })
            .onGeometryChange(for: CGSize.self) { $0.size } action: { if size != $0 { size = $0 } }
            .opacityPop(visible: visible)
            //Opacity 0 still takes taps under the cover — and so does a piece `.arriving` behind its
            //own twin, which is the one the finger can actually see
            .allowsHitTesting(phase == .live && onPage)
            //Its OWN scope: the hand-off and close start are bare or instant writes on purpose. The
            //reveal behind a twin takes no curve at all — the pop the user saw was the twin's, on the
            //flight's ramp, and a curve here would run the real lens up from 0.4 behind a twin already
            //at full, so the cut would step. Everything else keeps the pop it always had, the close's
            //pop-out and a landed page flip included (`.arriving` is unreachable without a flight).
            .animation(phase == .arriving ? nil : .transition, value: visible)
            .onDisappear { flight?.dropBandChrome(id: id) }
    }
}

private struct EventZoomAlertModifier: ViewModifier {

    //Injected
    @Environment(AlertHost.self) private var host: AlertHost? //The card's plane; absent when the body renders without a flight
    @Binding var isPresented: Bool
    let alert: AlertRequest

    //Local view state
    @State private var id = UUID() //This modifier's claim on the plane, so a stale close never clears a live alert

    @ViewBuilder
    func body(content: Content) -> some View {
        if let host {
            content
                //`initial`: a body that mounts with its alert already up still takes the plane
                .onChange(of: isPresented, initial: true) { _, presented in
                    if presented {
                        host.present(id: id, alert: alert, dismiss: { isPresented = false })
                    } else {
                        host.close(id: id)
                    }
                }
                //The plane outlives this body (the card flies home around it): a card closed with its
                //alert up must not leave the plate behind
                .onDisappear { host.close(id: id) }
        } else {
            content.customAlertCard(isPresented: $isPresented,
                                    title: alert.title,
                                    emoji: alert.emoji,
                                    message: alert.message,
                                    cancelTitle: alert.cancelTitle,
                                    okTitle: alert.okTitle,
                                    offset: alert.offset,
                                    onOK: alert.onOK,
                                    onCancel: alert.onCancel)
        }
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
    @State private var alerts = AlertHost() //The card body's own plane: an alert it raises is masked out inside it
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
                .opacity(flight.handedOver ? 0 : flight.backdropOpacity) //Handed over, the material is its caller's too: two of them would stack
                .onTapGesture { flight.tapAway() }

            VStack(spacing: Spacing.xl) {
                card
                EventDismissButton(visible: false, leadingTitle: nil, onTap: {}, onLeadingTap: nil) //A layout ghost: reserves the chevron's slot in the column, which the drag and the flight carry
            }
            //A card with a leading action (the calendar's View Event) rests a step higher; the flight and the chevron's slot read it off the measured card
            .offset(y: flight.leadingActionTitle == nil ? 0 : -Spacing.lg)
            .offset(flight.cardOffset)
            .simultaneousGesture(flight.dismissDrag)
            .allowsHitTesting(!flight.leaving) //Handed over: the pager and the card's own buttons hold still
            .opacity(flight.handedOver ? 0 : 1) //Its caller's copy stands in its place
        }
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { containerTop = $0 }
        //The top safe-area edge in global space, whichever way this plane meets it. NOT the sum: laid out
        //inside the safe area this view reports minY 59 AND safeAreaInsets.top 59 (sim-measured, iPhone 16),
        //so the sum pinned 59pt low and the raise clamped to nothing; spanning it, minY 0 and insets 59
        .onGeometryChange(for: CGFloat.self) { max($0.frame(in: .global).minY, $0.safeAreaInsets.top) } action: { flight.reportPlaneTop($0) }
        //The plane itself, which nothing the card does moves: how wide the card will stand once a field has it, known
        //before it widens, and the line a keyboard's frame has to sit above to be on screen at all
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight.reportPlane($0) }
        //Screen coordinates, which this full-screen plane's global space matches; hidden, the frame sits below the screen
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard (note.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool) ?? true,
                  let end = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            flight.reportKeyboard(end)
        }
        .overlay(alignment: .top) { stationaryChevron }
        .overlay(alignment: .bottomTrailing) { keyboardAccessory }
        //Last, so the card body's alert covers the backdrop, the card and the chevron alike — and sits
        //outside the dismiss drag, which would otherwise scrub the card away under it
        .overlay { AlertLayer(host: alerts) }
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
                             bandChrome: flight.bandChrome(twinnedId: nil),
                             bandChromeTwinned: flight.bandChromeTwinnedPhase,
                             ctaGhosted: flight.ctaGhosted,
                             rowsGhosted: flight.rowsGhosted,
                             card: slot.card)
            .equatable()
            .environment(flight) //How the pager gates its live mount, reports its band and title, and how the body reaches back
            .environment(\.eventZoomDismiss, dismiss)
            .environment(alerts) //Where `.eventZoomAlert` puts its plate — outside the mask below, which is the whole point
            //The space the body's band and CTA report their frames in: INSIDE the morph's render
            //transforms, so a breathing, sinking or popping card never feeds its transform back into
            //the poses derived from those frames (see EventZoomChoreo.ctaLocal)
            .coordinateSpace(.named(EventZoomChoreo.cardSpace))
            .background { cardFill }
            .modifier(flight.morph()) //Draws the card's shadow itself, as a shape BEHIND the window — see the morph
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight.reportCard($0) }
            .padding(.horizontal, flight.keyboardInsetActive ? EventZoomChoreo.keyboardInset : slot.inset) //The card is a full-bleed surface, not a text column; a focused field wears the shell's own gap
    }

    //A body's control on the keyboard's line (`.eventZoomKeyboardAccessory`), in the plane like the chevron: hung in the
    //card it rode the whole ride, some 200pt, while it popped in, and the drop that put it on the line chased a slot
    //no measure could hold still (every read under a widening card is mid-spring). Here it appears where it will stand
    @ViewBuilder
    private var keyboardAccessory: some View {
        if let title = flight.keyboardAccessoryTitle {
            ScoopButton(style: .tinted(.blackFill, shadow: nil, glass: true), shape: Capsule()) {
                flight.tapKeyboardAccessory()
            } label: {
                EventKeyboardAccessoryLabel(title: title)
            }
            .blurPop(visible: flight.keyboardAccessoryVisible)
            .padding(.trailing, Spacing.lg)
            .padding(.bottom, flight.keyboardAccessoryInset)
            .animation(flight.keyboardAccessoryVisible ? .keyboard : nil, value: flight.keyboardAccessoryInset) //A keyboard of another height, mid-note; hidden, it takes its line bare
        }
    }

    //The chevron never rides the drag or the flight: it renders ABOVE the moving column, at the
    //resting card's foot
    @ViewBuilder
    private var stationaryChevron: some View {
        if flight.hasChevronSlot {
            EventDismissButton(visible: flight.chevronVisible,
                               leadingTitle: flight.leadingActionTitle,
                               onTap: { flight.close() },
                               onLeadingTap: { flight.depart() })
                .offset(y: flight.chevronSlotY - containerTop)
                .allowsHitTesting(!flight.leaving) //The leading action was tapped: the row stands inert until its caller takes it
                .opacity(flight.handedOver ? 0 : 1) //Its caller's copy of the row pops away in its place
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
    let bandChrome: EventZoomBandChromePhase
    //The same, for the pieces a twin flies in for (`eventZoomBandChrome(visible:corner:copy:)`): they
    //take their pixels back at the LANDING, behind the twin, and the corner's taps a beat later — two
    //flips per open instead of one, and DELIBERATELY neither of them at the cover's cut. Threading a
    //value that flipped there would put a full rebuild of the caller's card body into the one commit
    //of the whole open that must change nothing (`handOffCover`: 12 pixels by one level), which is the
    //regression `.equatable()` exists to prevent. Pinned identical to the value above whenever no twin
    //flew, so a card that flies none pays nothing for it.
    let bandChromeTwinned: EventZoomBandChromePhase
    //Part of the identity for the same reason: the card's own CTA ghosts for the flight and takes
    //its pixels back at the landing, and an equality blind to that would leave it invisible until
    //something else happened to re-render the card
    let ctaGhosted: Bool
    //And again for the time and place rows, which ghost for the flight and take their pixels back at
    //the landing. ONE value for the whole set, not one per row: the rows read their own kind through
    //the modifier, and this is only what stops `.equatable()` swallowing the invalidation — the same
    //rule `bandChromeTwinnedPhase` is written to ([[project_band_chrome_one_gate]]).
    let rowsGhosted: Bool
    let card: () -> AnyView

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.bandChrome == rhs.bandChrome
            && lhs.bandChromeTwinned == rhs.bandChromeTwinned && lhs.ctaGhosted == rhs.ctaGhosted
            && lhs.rowsGhosted == rhs.rowsGhosted
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
    private var ctaFont: Font = .body(18, .bold) //Its type, so the flying word is the landing's own
    private var ctaLineLimit: Int = 1
    private var ctaHeroShown = true //The capsule stands in for the CTA until its fade is done (see `handOffCTA`)
    private var ctaHeroFade: Double = 1 //The capsule's fill fading off the real button — its label holds until the end
    //The rows the source draws and the card draws again — the flight carries each from one to the
    //other. Sources are global (re-read with `source` at a landed close, like the title's); the
    //landings are in CARD space for the reason `ctaLocal` records, and `rowFlights` re-derives the
    //global pair every frame from the card's own measured frame.
    private var rowSources: [EventZoomRowKind: CGRect] = [:]
    private var rowSourceTexts: [EventZoomRowKind: String] = [:]
    private var rowLocals: [EventZoomRowKind: CGRect] = [:]
    private var rowTexts: [EventZoomRowKind: String] = [:]
    private var rowHeroShown = true //The heroes stand in for the rows until their fade is done (see `handOffRows`)
    private var rowHeroFade: Double = 1
    //The corner capsule the source draws and the disc the card lands it on. The source end is taken at init and
    //re-read with `source` at a landed close; the landing reports live and unobserved (`cornerTargets`, one entry per marker) and is TAKEN
    //twice a flight — as the open leaves the source, and at the close's start — so the hero never chases a disc
    //that moved, or changed kind, in mid-air
    private var cornerSource: CGRect
    private let cornerSourceLook: AnyView? //Built ONCE, like the chrome copy
    @ObservationIgnored private var cornerTargets: [UUID: EventZoomCornerTargetReport] = [:] //Per marker: a type switch has two mounted at once
    @ObservationIgnored private var cornerTargetCount = 0 //Stamps each marker's first report, so the newest mount wins
    private var cornerLanding: EventZoomCornerLanding?
    private var cornerLandingLook: AnyView?
    private var cornerMode: EventZoomCornerMode = .morph //Latched at the close's start; the open always morphs
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
    private var rimTint: CGFloat = 0 //A tinted lens' landing rim, 0 → 1 over its close and full before every landed commit. Written only when the shape has a tint
    private var landingScale: CGFloat = 1 //The tap close's landing breath — compress into touchdown, rebound past rest, settle; the open, the drag and the wind never write it
    @ObservationIgnored private let drawnBreath = EventZoomDrawnBreath() //Written by the morph every frame it draws; read by a departure
    private var breath: CGFloat = 0 //The open's landing bounce, 0 → 1 → 0 on its own clock (breathRise/breathSettle): the outline's give and the contents' lift
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
    //The pieces a twin flies in for. The card body pushes its builders every pass, unobserved (the
    //source chrome's rule — a closure is not Equatable, so no same-value guard is possible and an
    //observed write from inside a body would loop); `captureBandChrome` calls them ONCE, in the
    //measured pass before the flight leaves, and the list then stands for the whole flight: mounted
    //from takeoff, never inserted mid-air (InvitePhotoBand's dropped frame, sim capture 2026-09-04).
    @ObservationIgnored private var bandChromeSources: [UUID: (corner: EventZoomBandCorner, onPage: Bool, copy: () -> AnyView)] = [:]
    private(set) var bandCopies: [EventZoomBandChromeCopy] = [] //What the morph flies; emptied at the hand-off
    //Which pieces a twin was actually TAKEN of, which is not the same as which offered one: a piece off
    //its page at takeoff has nothing to fly, and must keep the plain hand-off rather than take the
    //instant reveal meant for a piece with a twin standing in front of it. Outlives `bandCopies`, which
    //the cut empties — after that the answer is the same either way, and this keeps it from flapping.
    private var bandChromeTwinned: Set<UUID> = []
    private var chevronHiddenByCard = false //A body's confirm screen owns the corner with its own back button
    private(set) var leadingActionTitle: String? //A body's button on the chevron's leading side (`.eventZoomLeadingAction`); nil draws the chevron alone
    @ObservationIgnored private var leadingAction: (EventZoomDeparture) -> Void = { _ in } //Its hand-over: a closure has no same-value guard, so the store stays unobserved
    private(set) var leaving = false //The leading action was tapped: the card and its buttons hold still until they are handed over
    private(set) var handedOver = false //Its caller has taken the card onto a plane of its own: this one draws nothing
    @ObservationIgnored private var visiblePage: EventZoomVisiblePage? //The pager's page as drawn, pushed on change
    private var dragLocked = false //A body's popup owns the finger: no dismiss scrub, no chevron
    private var keyboardFocused = false //A body's text field owns the screen: the backdrop's tap resigns it, no scrub, no chevron
    @ObservationIgnored private var keyboardRiding = false //The body's ride is under way or landed: the card rises to the pin and wears `keyboardInset`. A beat behind `keyboardFocused` on a focus (the body starts its ride on the first frame the keyboard's arrival lets through), with it on a resign
    @ObservationIgnored private var keyboardRidePending = false //Focused, the ride not yet begun: a resize landing in between already belongs to it
    @ObservationIgnored private var keyboardRideEnds: CFTimeInterval = 0 //Until then a landed resize is part of the ride, and wears its clock (`landedResizeClock`)
    private var raise: CGFloat = 0 //The column's lift while `keyboardRiding` — negative, in the same offset the drag rides
    @ObservationIgnored private var keyboardExtraLift: CGFloat = 0 //How far past the pin the body asks the raised card to ride — positive, read only by the pin
    private(set) var keyboardInsetActive = false //The card wears `keyboardInset` in place of its caller's gap: `keyboardRiding` once landed, in the ride's own commit
    private(set) var keyboardAccessoryTitle: String? //A body's control on the keyboard's line (`.eventZoomKeyboardAccessory`); nil draws none
    private(set) var keyboardAccessoryVisible = false
    @ObservationIgnored private var keyboardAccessoryAction: () -> Void = {} //Its tap: a closure has no same-value guard, so the store stays unobserved
    private var accessoryKeyboardTop: CGFloat? //Where a PRESENTED keyboard's top last stood: the accessory's line. A keyboard on its way out never moves it — the control pops away where it stands
    @ObservationIgnored private var keyboardFrameSeen = false //A frame has been reported since the raw focus: the cache below is no longer this focus's best knowledge
    private var planeTop: CGFloat = 0 //Global y of the plane's top safe-area edge, reported by the card view: what the raised card's top pins beneath
    private var planeWidth: CGFloat = 0 //The plane's width: what the focused card's is known from before it widens (`keyboardCardWidth`)
    private var planeBottom: CGFloat = .infinity //Global y of the plane's foot: a keyboard whose top is not above it is off screen
    @ObservationIgnored private var resignKeyboard: (() -> Void)? //How the backdrop's tap-away hands the field back to the body
    private var keyboardTop: CGFloat = .infinity //Global y of the keyboard's top edge (UIKit's will-change-frame); off screen or unknown, nothing to clear
    @ObservationIgnored private var keyboardFeet: [UUID: CGFloat] = [:] //How far above the card's own foot each control that must clear the keyboard ends: no raise, no re-centre, no drag in it, and nothing of a band growing above
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
        self.rowSources = anchor.rowRects
        self.rowSourceTexts = anchor.rowTexts
        self.pressPose = anchor.pressPose
        self.cornerSource = anchor.cornerRect
        self.cornerSourceLook = anchor.cornerLook?()
        self.onClosing = onClosing
        self.onChromeReturn = onChromeReturn
        self.onClosed = onClosed
    }
}

//The card's read surface — everything the presented card needs, and nothing that moves it
extension EventZoomChoreo {

    //Landed and at rest: the live pager mounts here
    var settled: Bool { landed && !closing }

    //How wide the card stands once a body's field has it, known while it still rests at its caller's gap: a body lays
    //out at this width, from the start, whatever must not re-flow while the card widens (the respond note's thread).
    //0 until the plane has laid out
    var keyboardCardWidth: CGFloat { max(planeWidth - 2 * Self.keyboardInset, 0) }

    //The presented keyboard's top edge, global — what a body's own content has to stay above to be read or typed into.
    //nil while none is up (or none is coming: a hardware keyboard reports its frame off screen)
    var keyboardLine: CGFloat? { accessoryKeyboardTop }

    //The accessory's foot above the plane's own: the keyboard as it last stood, and the clearance over it
    var keyboardAccessoryInset: CGFloat {
        guard let top = accessoryKeyboardTop, planeBottom.isFinite else { return Self.keyboardClearance }
        return max(planeBottom - top, 0) + Self.keyboardClearance
    }

    //Chrome over the pager band arrives on its own animated write as the cover fades — it rides in
    //over the hand-off rather than being revealed by it, so the foot and title land once
    var bandChromeVisible: Bool { settled && bandChromeIn }

    ///What a band-chrome piece does this frame. Pass its id if it OFFERED a twin; the answer still turns
    ///on whether one was actually taken of it, because a piece off its page at takeoff has none.
    ///Without one the piece keeps the hand-off it always had: hidden under the cover, popped in a beat
    ///after the landing (`armBandChrome`). With one it takes its pixels back at the LANDING instead,
    ///painted behind a twin already at full — reveal a surface behind whatever is covering it, never as
    ///the cover leaves, the rule the CTA's ghost is built on. It takes the corner's TAPS only when the
    ///band's chrome arms, a beat later: the twin is `.allowsHitTesting(false)` and the cover under it
    ///cannot be tapped either, so the touch would otherwise reach a button nobody can see. Both flips
    ///land on commits that already re-render the card (`land()`, and `armBandChrome`'s write) — never
    ///on the cover's cut, which must stay a pure swap.
    func bandChrome(twinnedId id: UUID?) -> EventZoomBandChromePhase {
        guard let id, bandChromeTwinned.contains(id) else { return bandChromeVisible ? .live : .hidden }
        guard settled else { return .hidden } //A close takes the corner away under the returning cover
        return bandChromeIn ? .live : .arriving
    }

    ///The card's own identity value: whether ANY piece is mid-twinned-arrival. The card content needs
    ///one value that changes on both of a twinned piece's flips, not a value per piece — the pieces read
    ///their own phase through the modifier, and this is only what stops `.equatable()` swallowing the
    ///invalidation ([[project_band_chrome_one_gate]]).
    var bandChromeTwinnedPhase: EventZoomBandChromePhase {
        bandChromeTwinned.isEmpty ? bandChrome(twinnedId: nil) : bandChrome(twinnedId: bandChromeTwinned.first)
    }

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

    //Which rows actually fly this open. A kind needs BOTH ends measured — the landing is what makes
    //a hero landable, and the source is what gives it somewhere to come from — so a card whose body
    //has no matching row (the respond card opened straight onto a persisted new-event draft, whose
    //`EditTypeTimePlace` draws none) flies nothing and, crucially, ghosts nothing: the source's own
    //rows then leave with the chrome copy exactly as they did before this existed. The old flight
    //carried the same guard as `heroesEngaged`. A LENS source is excluded outright: its rows would be
    //posed against a 44pt circle and hang off it into bare backdrop (`captureBandChrome`'s rule).
    var activeRowKinds: [EventZoomRowKind] {
        guard hasFlight, !shape.isLens, rowHeroShown, cardRect.width > 1 else { return [] }
        return EventZoomRowKind.allCases.filter { kind in
            (rowSources[kind]?.width ?? 0) > 1 && (rowLocals[kind]?.width ?? 0) > 1
        }
    }

    var rowHeroActive: Bool { !activeRowKinds.isEmpty }

    //The heroes' fill hand-off, the capsule's rule: 1 for the flight, faded off over the landing
    var rowHeroFill: Double { rowHeroFade }

    ///Whether the card's own row of this kind is standing down for its hero. Like the CTA's, it comes
    ///back at the LANDING — well before the hero goes — and takes its first paint under a hero still
    ///at full opacity, on identical pixels: reveal a surface behind whatever is covering it, never as
    ///the cover leaves.
    func rowGhosted(_ kind: EventZoomRowKind) -> Bool {
        !settled && activeRowKinds.contains(kind)
    }

    ///The card's identity value for the set (see `EventZoomCardContent.rowsGhosted`)
    var rowsGhosted: Bool { !settled && rowHeroActive }

    ///The corner hero this frame: a source that marked a capsule, and a flight to fly — no lens, whose rows and
    ///band chrome would hang off a 44pt face (`captureBandChrome`'s rule). Up from the TAP, the capsule hero's
    ///rule, so the chrome copy never shows its own capsule for a frame before the hero takes it; it morphs only
    ///once a landing has been taken. Nothing in the card body reads it, so it joins no identity below.
    var cornerFlight: EventZoomCornerFlight? {
        guard hasFlight, !shape.isLens, cornerSource.width > 1, let cornerSourceLook else { return nil }
        return EventZoomCornerFlight(mode: cornerMode, source: cornerSource, sourceLook: cornerSourceLook,
                                     landing: cornerLanding, landingLook: cornerLandingLook)
    }

    ///Both ends of every flying row, global, for this frame. The landing is derived from the card's
    ///own frame the same way `ctaRect` is: measured OUTSIDE the morph's render transforms, so a
    ///breathing card never feeds its own breath back into the pose derived from it.
    var rowFlights: [EventZoomRowFlight] {
        activeRowKinds.compactMap { kind in
            guard let source = rowSources[kind], let local = rowLocals[kind] else { return nil }
            return EventZoomRowFlight(kind: kind,
                                      source: source,
                                      sourceText: rowSourceTexts[kind] ?? "",
                                      dest: local.offsetBy(dx: cardRect.minX, dy: cardRect.minY),
                                      text: rowTexts[kind] ?? "")
        }
    }

    //An engaged dismiss drag freezes the pager's own axis
    var dragEngaged: Bool { dragOffset != .zero }

    //The chevron: in a quarter into the open, gone at close start, for as long as the finger owns
    //the card, while a body's popup owns it, and on a confirm screen that brings its own
    var chevronVisible: Bool { chevronIn && !closing && !fingerDown && !dragLocked && !keyboardFocused && !chevronHiddenByCard }

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
               height: rubberBanded(dragOffset.height) + raise) //The keyboard raise is a pose of the column, like the drag — the morph never folds for it
    }

    //The raised card's top ↔ the plane's top safe-area edge: flush (Arthur, 2026-09-10 — 12 read as too low)
    static let keyboardPinGap: CGFloat = -Spacing.lg * 2.8
    //The keyboard's top ↔ what stands over it: the accessory's foot exactly, and the least the raise keeps under the lowest clearance slot's
    static let keyboardClearance: CGFloat = Spacing.sm
    //The card's gap to each screen edge while a body's field is focused; at rest it is the caller's `.eventZoom(inset:)` (10 on the respond card)
    static let keyboardInset: CGFloat = 0

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
        //write stays raw: those read the rect live, per frame. A resize inside a keyboard ride is
        //the ride's own (the card widening, the note growing to be written in), so it wears the
        //ride's clock — `landedResizeClock`.
        withAnimation(landed && !closing && !dragEngaged ? landedResizeClock : nil) {
            cardRect = rect
            //The chevron's slot takes the RESTING pose only: the live frame folds the drag in, and
            //a committed close keeps that frozen drag for the whole flight home
            //Clear of the keyboard raise too: the slot the chevron pops back into on unfocus is the RESTING
            //one, and the card comes down onto it (the snap-back's pattern) — reported raised, the slot would
            //slide there beside the descending card. Exact only because the ride writes its gap and its raise in
            //ONE transaction: the rect measured here was laid out under the raise the model holds
            if !dragEngaged, !closing { restingCard = rect.offsetBy(dx: 0, dy: -raise) }
            //A raised card that RESIZES (the note wrapping a line) re-centres under its raise, which would
            //walk its top off the pin by half the delta; re-pin on the same clock as the resize itself
            repin()
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

    ///Pushed from the card body every pass and stored unobserved: the flight needs only the newest
    ///builder and calls it once, at takeoff (`captureBandChrome`). No same-value guard is possible
    ///here — a closure is not Equatable — which is exactly why the store is @ObservationIgnored.
    func reportBandChrome(id: UUID, corner: EventZoomBandCorner, onPage: Bool, copy: @escaping () -> AnyView) {
        bandChromeSources[id] = (corner, onPage, copy)
    }

    func dropBandChrome(id: UUID) {
        bandChromeSources[id] = nil
    }

    //Same-value guards throughout: a redundant write to an @Observable stalls compositing
    ///In card space (`EventZoomChoreo.cardSpace`)
    func reportCTA(_ rect: CGRect) {
        if ctaLocal != rect { ctaLocal = rect }
    }

    ///In card space (`EventZoomChoreo.cardSpace`)
    func reportRow(_ kind: EventZoomRowKind, rect: CGRect) {
        if rowLocals[kind] != rect { rowLocals[kind] = rect }
    }

    func reportRowText(_ kind: EventZoomRowKind, text: String) {
        if rowTexts[kind] != text { rowTexts[kind] = text }
    }

    func reportCTALook(text: String, fill: Color, font: Font, lineLimit: Int) {
        if ctaText != text { ctaText = text }
        if ctaFill != fill { ctaFill = fill }
        if ctaFont != font { ctaFont = font }
        if ctaLineLimit != lineLimit { ctaLineLimit = lineLimit }
    }

    ///Both unobserved, like the band's builders: the flight takes them together, at takeoff and at the close's start
    func reportCornerLook(id: UUID, look: @escaping () -> AnyView) {
        var report = cornerTargets[id] ?? newCornerTarget()
        report.look = look
        cornerTargets[id] = report
    }

    func reportCornerLanding(id: UUID, _ landing: EventZoomCornerLanding) {
        var report = cornerTargets[id] ?? newCornerTarget()
        report.landing = landing
        cornerTargets[id] = report
    }

    //Its own entry only: a disc leaving on a type switch's transition can still report, and must never take the
    //incoming disc's claim with it when it finally goes
    func dropCornerTarget(id: UUID) {
        cornerTargets[id] = nil
    }

    private func newCornerTarget() -> EventZoomCornerTargetReport {
        cornerTargetCount += 1
        return EventZoomCornerTargetReport(order: cornerTargetCount)
    }

    func setChevronHiddenByCard(_ hidden: Bool) {
        if chevronHiddenByCard != hidden { chevronHiddenByCard = hidden }
    }

    func setLeadingActionTitle(_ title: String) {
        if leadingActionTitle != title { leadingActionTitle = title }
    }

    func reportLeadingAction(_ action: @escaping (EventZoomDeparture) -> Void) {
        leadingAction = action
    }

    func reportVisiblePage(_ page: EventZoomVisiblePage) {
        visiblePage = page
    }

    func setDragLocked(_ locked: Bool) {
        if dragLocked != locked { dragLocked = locked }
    }

    func setKeyboardAccessory(title: String?) {
        if keyboardAccessoryTitle != title { keyboardAccessoryTitle = title }
        if title != nil, accessoryKeyboardTop == nil, let cached = cachedKeyboardTop { accessoryKeyboardTop = cached } //On its line from the start: never animated up from the plane's foot
    }

    func setKeyboardAccessory(visible: Bool) {
        if keyboardAccessoryVisible != visible { keyboardAccessoryVisible = visible }
    }

    func reportKeyboardAccessory(_ action: @escaping () -> Void) {
        keyboardAccessoryAction = action
    }

    func tapKeyboardAccessory() {
        keyboardAccessoryAction()
    }

    //The raw focus: the gates only. Nothing moves for it — the motion is the body's ride (`setKeyboardRide`)
    func setKeyboardFocus(_ focused: Bool, extraLift: CGFloat, resign: @escaping () -> Void) {
        resignKeyboard = resign
        keyboardExtraLift = extraLift
        guard keyboardFocused != focused else { return }
        keyboardFocused = focused
        if focused { keyboardFrameSeen = false }
        //A resize the body lands between the focus and its ride is already the ride's; a resign's ride leaves in this same turn
        keyboardRidePending = focused
        if !focused { keyboardRideEnds = CACurrentMediaTime() + Self.keyboardRideSettle }
    }

    //The body's ride begins, or turns for home: the card leaves in the same commit as what is in it
    func setKeyboardRide(_ riding: Bool) {
        guard keyboardRiding != riding else { return }
        keyboardRiding = riding
        keyboardRidePending = false
        //A flight keeps its geometry: a ride begun mid-open waits for `land()`, and a close never re-poses the
        //column under the trajectory it captured — a frozen raise stays folded in, like a frozen drag
        guard landed, !closing else { return }
        rideKeyboard()
    }

    //The ride's shell half, in ONE transaction on the keyboard's own spring: the gap and the pin.
    //They used to leave in two (the gap on `.transition`, the pin on `.move`), which SwiftUI flushes one after the
    //other: the first measured rect then carried the new gap but not the new raise, `restingCard` came out wrong by
    //the whole raise, the pin chased it through four layout passes, and the last corrective write — `reportCard`'s,
    //on `.transition` — took every spring in the commit with it, the body's rows included (rig + device, 2026-09-17)
    private func rideKeyboard() {
        //The keyboard's frame lands a beat after the focus that summons it. It stands where it last stood, nearly
        //always, so the pin and the accessory's line are right from this commit, and the late frame is a same-value
        //no-op — never a second spring (device, 2026-09-17: Done rose 20pt past its line and sank back for 20 frames)
        if keyboardRiding, !keyboardFrameSeen, let cached = cachedKeyboardTop { keyboardTop = cached }
        if keyboardRiding, keyboardTop < planeBottom, accessoryKeyboardTop != keyboardTop { accessoryKeyboardTop = keyboardTop }
        keyboardRideEnds = CACurrentMediaTime() + Self.keyboardRideSettle
        withAnimation(.keyboard) {
            if keyboardInsetActive != keyboardRiding { keyboardInsetActive = keyboardRiding }
            if keyboardRiding { repin() } else if raise != 0 { raise = 0 }
        }
    }

    //A landed resize's clock: `.transition`, the role every body writes one under — but inside a keyboard ride the
    //resize IS the ride (the card widening, the note growing, the re-centre each causes), so the mask, the slot and
    //the re-pin wear the ride's spring. One spring end to end is also what lets the pin's corrections vanish: springs
    //of one kind superpose exactly, and a correction on another clock re-times the whole motion
    private var landedResizeClock: Animation {
        keyboardRidePending || CACurrentMediaTime() < keyboardRideEnds ? .keyboard : .transition
    }

    //How long a ride owns the landed resizes after it leaves: the commit's own passes and the keyboard's late frame all
    //land inside it, and the body's own resizes a beat later (a written note resting as its bubble at 0.3s) do not
    private static let keyboardRideSettle: CFTimeInterval = 0.2
    //Where a presented, docked keyboard's top last stood, in any card, and how wide its plane was: the next focus's best
    //knowledge of where it will stand — in a plane of that width (a rotation, or an iPad, is another keyboard)
    private static var lastShownKeyboard: (top: CGFloat, planeWidth: CGFloat)?
    private var cachedKeyboardTop: CGFloat? {
        guard let cached = Self.lastShownKeyboard, cached.planeWidth == planeWidth else { return nil }
        return cached.top
    }

    func reportPlaneTop(_ y: CGFloat) {
        if planeTop != y { planeTop = y }
    }

    func reportPlane(_ rect: CGRect) {
        if planeWidth != rect.width { planeWidth = rect.width }
        planeBottom = rect.maxY
    }

    //UIKit's keyboard frame, a beat after the focus that summoned it. The ride has usually pinned to where it last
    //stood, so this is a same-value return; a keyboard of another height retargets on the ride's clock. Only a DOCKED
    //keyboard on this plane counts as one: a floating or undocked iPad keyboard reports an empty or narrow frame, and a
    //hardware keyboard none on screen — the card then rides to the pin alone, and the accessory drops to the plane's foot
    func reportKeyboard(_ end: CGRect) {
        let seen = keyboardFrameSeen
        keyboardFrameSeen = true
        let docked = !end.isEmpty && end.maxY >= planeBottom - 1 && end.width >= planeWidth - 1
        let y: CGFloat = docked && end.minY < planeBottom ? end.minY : .infinity
        if y.isFinite {
            Self.lastShownKeyboard = (top: y, planeWidth: planeWidth)
            if accessoryKeyboardTop != y { accessoryKeyboardTop = y }
        } else if keyboardRiding, !seen, accessoryKeyboardTop != nil {
            //This focus's first word from UIKit, and it is "no keyboard": the ride pinned to a cached line that will not come
            withAnimation(.keyboard) { accessoryKeyboardTop = nil }
        }
        guard keyboardTop != y else { return }
        keyboardTop = y
        withAnimation(landedResizeClock) { repin() }
    }

    //A foot moves with a resize of the body, which `reportCard` eases on this clock
    func reportKeyboardFoot(id: UUID, aboveCardFoot height: CGFloat?) {
        guard keyboardFeet[id] != height else { return }
        keyboardFeet[id] = height
        withAnimation(landedResizeClock) { repin() }
    }

    //A tap outside the card: with a body's field up it only resigns the field — the next tap closes
    func tapAway() {
        guard !leaving else { return } //Handed over: the card's next move is its caller's
        if keyboardFocused, let resignKeyboard { resignKeyboard() } else { close() }
    }

    //The leading action's tap. The card and its buttons hold still; once it stands on a whole page — or the
    //cap runs out, when the caller may only fade it — the caller takes it as it stands, buttons and all:
    //a caller that flies the card pops its own pictures of them, so the live row never pops ahead of it
    func depart() {
        guard !leaving, !closing else { return }
        leaving = true
        //Landed — nearly always — the card goes in the tap's own turn: the caller's flight starts from the tap, not a beat after it
        if restingForDeparture {
            leadingAction(departure(waited: .zero))
            return
        }
        Task { @MainActor [self] in
            let tapped = ContinuousClock.now
            let cap = tapped + Self.departureRestCap
            while !restingForDeparture, ContinuousClock.now < cap { try? await Task.sleep(for: .milliseconds(16)) }
            guard leaving, !closing else { return } //A close begun meanwhile (its source vanished) owns the card
            leadingAction(departure(waited: ContinuousClock.now - tapped))
        }
    }

    private static let departureRestCap = Duration.seconds(timeScale)

    //The card has LANDED — its open's flight posed home, the pager mounted and settled on a whole page — and no finger
    //or field holds it. Nothing after the landing is waited out: not the cover's hand-off a quarter-second on, not the
    //breath (each read as a dead tap when "View Event" was tapped soon after the popup opened — device, 2026-09-17).
    //A card taken mid-breath is handed over as DRAWN (`drawnBreath`), so its caller leaves from the swollen outline
    //that is on the screen — posed at rest instead, the outline snapped 4pt inward at the hand-over (sim capture)
    private var restingForDeparture: Bool {
        settled && !fingerDown && !dragEngaged && !keyboardFocused
            && restingCard.height > 1 && !destLocal.isEmpty && (visiblePage?.atRest ?? false)
    }

    private func departure(waited: Duration) -> EventZoomDeparture {
        let page = visiblePage
        let centre = CGPoint(x: restingCard.midX, y: restingCard.midY)
        return EventZoomDeparture(ready: restingForDeparture && page != nil, waited: waited,
                                  card: drawnBreath.drawn(restingCard, about: centre),
                                  band: drawnBreath.drawn(destRect, about: centre, lifted: true),
                                  photo: page?.photo, source: page?.source,
                                  page: page?.index ?? 0, pageCount: page?.count ?? 0,
                                  chevronSlotY: chevronSlotY, leadingTitle: leadingActionTitle,
                                  hide: { [weak self] in
                                      var instant = Transaction()
                                      instant.disablesAnimations = true
                                      withTransaction(instant) { self?.handedOver = true }
                                  },
                                  restore: { [weak self] in
                                      self?.leaving = false
                                      self?.handedOver = false
                                  })
    }

    //The raise that holds the pin, written only when it moves (a same-value write stalls the glass). Reads
    //`restingCard`, held clear of the raise, and the feet as heights above the card's own foot: nothing here ever sees
    //the column mid-spring
    private func repin() {
        guard keyboardRiding, landed, !closing, !dragEngaged else { return }
        let pinned = pinnedRaise()
        if pinned != raise { raise = pinned }
    }

    //The pin: the card's top `keyboardPinGap` below the plane's safe-area edge. Further only if the control
    //hung lowest would still meet the keyboard, and never past the screen's own top; never positive — a card
    //already above the pin stays where it is. The body's `keyboardExtraLift` then carries it on past both
    private func pinnedRaise() -> CGFloat {
        let lift = planeTop + Self.keyboardPinGap - restingCard.minY
        let pinned = min(max(lift, -restingCard.minY), 0) - keyboardExtraLift
        //The clearance acts PAST the screen-top floor, as the extra lift does (the photo slides further off the top): the
        //lowest slot's foot never crosses the accessory's line. Floored with the pin it was a dead term on every iPhone
        guard let foot = restingFoot, keyboardTop < planeBottom else { return pinned }
        return min(pinned, keyboardTop - Self.keyboardClearance - foot)
    }

    //The lowest clearance control's foot on the RESTING card, global
    private var restingFoot: CGFloat? { keyboardFeet.values.min().map { restingCard.maxY - $0 } }

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
            bandCopies: bandCopies,
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
            ctaFont: ctaFont,
            ctaLineLimit: ctaLineLimit,
            rows: rowFlights,
            rowFade: rowHeroFill,
            corner: cornerFlight,
            coverShown: coverShown,
            titleShown: titleHeroShown,
            titleFade: titleHeroFade,
            rimMounted: landed,
            rimTint: rimTint,
            shadow: shadowStrength,
            drawn: drawnBreath)
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
    ///A band-chrome piece's own space — what a corner landing is measured in, clear of the piece's pop
    nonisolated static let bandPieceSpace = "eventZoomBandPiece" //Nonisolated: read from the geometry closure, which is Sendable

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
    //The open's landing (Arthur, 2026-09-04/05, settled on his reference clip): the card's OUTLINE lands
    //with a barely perceptible give — the whole landed stack carried past its size by `breathPeak`
    //(2pt at the farthest edge; a card per-edge in proportion to travel, a lens uniformly by
    //`breathGain`) — while a card's CONTENTS (photo, title, rows, CTA) land `innerLift` points high
    //inside it and settle down as one rigid piece, the outline already still: a small upward bounce of
    //the picture, not a size breath. Both ride ONE value, `breath` (0 → 1 → 0), so they peak and come to
    //rest at the same instant. On its OWN clock,
    //overlapping the flight's tail — a single spring cannot give a quick arrival AND a long
    //absorption, its approach, overshoot and return sharing one period (bounce 0.3 peaked 55ms after
    //the crossing and read as a blip).
    //The rise (timingCurve 0.25, 0, 0.9, 1) starts EARLY at `breathStartTime`, while the flight still
    //has ~40% of its travel and most of its speed, and is long and gentle: the breath's speed ramps up
    //only as fast as the flight's ramps down, so the summed edge speed never rises — modelled against
    //the REAL Meet card (top travels 87pt, bottom 44; device recording 2026-09-04): the edge crosses
    //its size at ~0.20s doing ~160pt/s, brakes ~115ms to the 9pt peak, and sits within a point of
    //the peak for ~48ms before the settle takes it back. Two device tells drove this: a late, steep
    //rise (start 0.56, rise 0.60) re-accelerated the edge ~30% exactly at the size on the real card
    //(the harness card travels twice as far, which hid it), and a flat-ended rise (c2x 0.15) plus a
    //long critically damped settle held the edge at its peak for ~85ms — a hang; the rise's
    //end-curvature is what makes the turnaround read as a turnaround. With `breathPeak` to stop in,
    //arrival speed and brake time are tied: v ≈ 2·A / t_brake. The settle is a lightly under-damped
    //spring (bounce 0.18, `breathSettleShare` of the open) from the peak's zero velocity: it finishes
    //decisively — measured at the real geometry, within 2pt of rest ~125ms after the peak, within 1pt
    //~165ms, settled ~180ms — with a counter-swing of a seventh of a point, invisible. Critically
    //damped it spent its last 2pt crawling for well over 100ms, a lingering tail the eye reads as
    //artificial (device video 2026-09-05). Both writes go in the flight's commit, the settle delayed
    //to the rise's end — additive retargeting blends them into one motion, the close landing's
    //pattern. Under a close or a drag the morph fades it with the fold. Reduce motion never
    //schedules it.
    static let breathGain: CGFloat = 0.033 //A LENS source's uniform swell; read by the morph. 0.044 (≈12pt) read a touch much on device — Arthur took a quarter off
    static let breathPeak: CGFloat = 2 //A CARD outline's farthest-travelling edge at the peak, pt — a give you feel more than see; the other edges follow in proportion to their own travel
    static let innerLift: CGFloat = 5 //How high a card's contents land above their place, pt, before settling down on the breath's clock (card sources only)
    //On the FLIGHT's clock, so the bounce reflects the opening (Arthur, 2026-09-04): a critically damped
    //spring's shape depends only on t/openDuration, so its speed at any share of its travel scales
    //with 1/openDuration — trim the open and the card arrives faster. With the overshoot held fixed,
    //the brake that absorbs that speed (t ≈ 2·A / v) and the return that mirrors it must shrink in
    //the same proportion, so all three times are shares of openDuration: trim the open by 0.02s and
    //the whole bounce trims ~6%, arrival ~7% faster, peak height unchanged. (Timed literals here
    //would have left the breath's speed peak drifting off the crossing the moment the open changed.)
    private static let breathStartShare: Double = 0.30 //Early — while the flight still has ~40% of its travel and most of its speed (0.10s of 0.32)
    private static let breathRiseShare: Double = 0.70 //A long, gentle rise (0.22s of 0.32): its speed never exceeds what the flight is shedding
    private static let breathSettleShare: Double = 1.3 //The return's duration as a share of the open (0.32s at 1), a bounce-0.18 spring from rest — Arthur's value. The turnaround's crispness comes from the rise's end-curvature, not this
    private static let breathStartTime: TimeInterval = openDuration * breathStartShare
    private static let breathRiseTime: TimeInterval = openDuration * breathRiseShare
    private static let breathRise = Animation.timingCurve(0.25, 0, 0.9, 1, duration: breathRiseTime).delay(breathStartTime)
    private static let breathSettle = Animation.spring(duration: openDuration * breathSettleShare, bounce: 0.18).delay(breathStartTime + breathRiseTime)
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
    //A tinted lens' colour lands WITH it: the rim takes the tint from half-way through the flight
    //(the ring ~90% grown) across the dip and the rebound, on a curve that ends exactly — well before
    //the rebound's `.removed`, which owns the commit. It rides the rim's OWN animatable attribute
    //(EventZoomLandingRim), never the morph's vector: the rebound retargets that whole vector, and a
    //tint channel there swung with the breath (1.15 → 0.96) and moved the commit (probe 2026-09-16).
    private static let landingTintIn = Animation.timingCurve(0.35, 0, 0.25, 1, duration: closeDuration * 1.35)
        .delay(closeDuration * 0.5)

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
            if keyboardRiding { rideKeyboard() } //A ride begun before this waited for it
            withAnimation(.transition) { chromeP = 1 }
            handOffCover(after: Self.handOffBeat) //The cover parks on the band while the pager takes its first paint
            armBandChrome()
            return
        }
        captureBandChrome() //Built and laid out in THIS pass, at the source — before the committed frame below
        Task { @MainActor [self] in
            try? await Task.sleep(for: .milliseconds(30)) //One committed frame at the source before the flight leaves it
            guard !closing else { return } //A close inside the wait owns the card: nothing may open over it, or retake its corner
            takeCornerLanding() //Reported in the measured passes the flight just waited out; taken as it leaves
            //Two completions on ONE spring: the landing at its perceptual end, and the cover's
            //hand-off only once it is REMOVED — p is exactly 1 then, so the cover and the live
            //page are the same pixels. At `.logicallyComplete` ~1.4% of the travel is still to
            //come (this spring: 0.332s vs 0.517s to removal), and a swap a beat after it stepped
            //the whole band about a point (sim capture 2026-09-04, `-eventZoomSlow`).
            var flight = Transaction(animation: Self.openFlight)
            flight.addAnimationCompletion(criteria: .logicallyComplete) { self.land() }
            //The cover and the CTA hand off on the spring's removal: the whole stack breathes together,
            //so the cut is on identical pixels whenever it falls.
            flight.addAnimationCompletion(criteria: .removed) { self.handOffCover(); self.handOffCTA(); self.handOffRows() }
            withTransaction(flight) { flightP = 1 }
            withAnimation(Self.breathRise) { breath = 1 }
            withAnimation(Self.breathSettle) { breath = 0 } //Same commit, delayed to the rise's end: one blended motion
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
        if keyboardRiding { rideKeyboard() } //A ride begun mid-flight waited for this
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

    //The rows' hand-off, the capsule's exactly: at p = 1 each hero sits on its row to the pixel and
    //the real row has been painted under it since the landing, so the fade comes off identical
    //glyphs and nothing arrives. Fading the hero rather than cutting it, because unlike the cover
    //the two are not the same pixels to the level — the flying word is the landing's own type
    //scaled by 1, but rasterized through a transform, and a cut showed that difference as a
    //one-frame sharpen on the sim.
    private func handOffRows() {
        guard !closing else { return }
        withAnimation(.transition) { rowHeroFade = 0 } completion: { self.rowHeroShown = false }
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
            //The band's twins go in the SAME instant commit as the cover that carried them: the real
            //pieces have been painted underneath since the landing, so this is the swap, not a removal.
            //A landed close builds its own at its start (`close()`): these were laid out before the card was touched.
            withTransaction(instant) {
                coverShown = false
                bandCopies = []
            }
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

    //The band's chrome, twinned to ride the cover. Built ONCE, in the measured pass before the flight
    //leaves, for the source chrome copy's two reasons: its body must never re-run in flight, and a
    //glass lens rebuilt at a new size every frame costs about seven eighths of the frame rate. Here it
    //takes its first layout in the committed frame the flight waits out above, never in a mid-flight
    //commit. The page as it stands at TAKEOFF: a twin cannot follow a flip it never re-renders for, and
    //a piece off its page has nothing to fly. Built again at a landed close's start (`popsIn` false), from the page as it
    //stands THEN, once the hand-off has spent these.
    //A LENS flies them on the OPEN only, and late: its cover starts at the ledger's 44pt face and keeps
    //corners of half its size until near the landing, so a piece held against that corner on `arrive`
    //would hang off the photo into bare backdrop for most of the flight — the slot-anchored rim's failure
    //([[project_wind_close_p_before_arrival]]). The morph fades a lens' twins in on `lensTwinArrive`
    //instead, once the corner has squared up. A landed close from a lens still flies none, for the same
    //reason in reverse. (A lens card first carried band chrome 2026-09-15: the Invites calendar's respond card.)
    private func captureBandChrome(popsIn: Bool = true) {
        guard hasFlight, popsIn || !shape.isLens else { return }
        let twins = bandChromeSources
            .filter { $0.value.onPage }
            .map { EventZoomBandChromeCopy(id: $0.key, corner: $0.value.corner, view: $0.value.copy(), popsIn: popsIn) }
        guard !twins.isEmpty else { return }
        bandCopies = twins
        bandChromeTwinned = Set(twins.map(\.id))
    }

    //The disc as it stands now, taken for a flight: the newest mounted marker's geometry and look together, or neither
    private func takeCornerLanding() {
        let newest = cornerTargets.values
            .filter { $0.landing != nil && $0.look != nil }
            .max { $0.order < $1.order }
        guard let landing = newest?.landing, let look = newest?.look else {
            if cornerLanding != nil { cornerLanding = nil }
            if cornerLandingLook != nil { cornerLandingLook = nil }
            return
        }
        if cornerLanding != landing { cornerLanding = landing }
        cornerLandingLook = look()
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
            cornerSource = anchor.cornerRect
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
        //The corner flies back on a tap and fades on a swipe (Arthur, 2026-09-13) — decided by the test the dispatch
        //below picks the motion with, so the corner can never disagree with the flight. It takes the disc as it
        //stands NOW, and the band's twins are built fresh when the hand-off already spent the takeoff's: a landed
        //close used to fly none, which cut the corner away on the close's first frame — the cover is back over it —
        //and a twin built at takeoff could spell a word the corner no longer says. Same commit as the cover.
        let swipe = velocity >= DragTuning.arcSlowMorphCeil || dragEngaged
        withTransaction(instant) {
            let mode: EventZoomCornerMode = swipe ? .fade : .morph
            if cornerMode != mode { cornerMode = mode }
            takeCornerLanding()
            if bandCopies.isEmpty { captureBandChrome(popsIn: false) }
        }
        //No capsule on the way OUT (Arthur, 2026-09-05): the reverse morph rode the folding window's foot
        //across the photo while narrowing back to a circle — a button sliding over the picture. The
        //Preview CTA stays part of the card and folds away with the rows; the image's own invite button
        //comes back with the chrome copy's fade (`chromeCopy`, the last stretch of the collapse) and
        //lands on the resting button. A close begun before the open's hand-off drops the capsule here,
        //instantly — a rare early dismissal, and the real CTA is under it.
        withTransaction(instant) {
            ctaHeroFade = 0
            ctaHeroShown = false
            //And no flying rows on the way out, for the capsule's reason and one of their own: the
            //close FOLDS, wiping the white rows up into the photo over its first stretch, and words
            //posed against that folding window would be carried across the picture with it while the
            //real rows are being eaten underneath them. The fold takes the rows, and the card's own
            //lines come back with the chrome copy over the collapse's last stretch (`chromeCopy`) —
            //the same hand-off the envelope already uses.
            rowHeroFade = 0
            rowHeroShown = false
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
                if shape.tint != nil { rimTint = 1 } //The flight's own spring, so the completion waits for both: full at the commit
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
        let landing = Self.cardLanding(path: hypot(destRect.midX - source.midX, destRect.midY - source.midY))
        windDriver.run { [self] raw in
            let t = raw / Self.timeScale //-eventZoomSlow stretches playback
            var instant = Transaction()
            instant.disablesAnimations = true
            if let p = landing(t) {
                withTransaction(instant) { flightP = p }
            } else {
                windDriver.stop()
                withTransaction(instant) { flightP = 0 }
                onClosed()
            }
        }
    }

    ///The card landing's p over time for a flight of `path` points, nil once settled
    private static func cardLanding(path: CGFloat) -> (TimeInterval) -> CGFloat? {
        let share = Double(min(cardOvershoot / max(path, 1), 0.5)) //The excursion as a share of the travel
        let l = log(1 / share)
        let zeta = l / (Double.pi * Double.pi + l * l).squareRoot()
        let omegaD = (Double.pi - acos(zeta)) / cardCrossTime
        let tDeep = Double.pi / omegaD
        let decayRate = zeta * omegaD / (1 - zeta * zeta).squareRoot() //ζω, ω the undamped frequency
        let lean = zeta / (1 - zeta * zeta).squareRoot()
        let returnTime = cardReturnTime, settleReach = cardSettleReach
        return { t in
            if t < tDeep {
                return CGFloat(exp(-decayRate * t) * (cos(omegaD * t) + lean * sin(omegaD * t)))
            }
            if t < tDeep + returnTime {
                let x = (t - tDeep) / returnTime * settleReach
                return CGFloat(-share * (1 + x) * exp(-x))
            }
            return nil
        }
    }

    //The landing breath, issued with the flight: the dip rides the flight's last fifth and the
    //rebound takes over the moment it bottoms out. onClosed rides the rebound's `.removed`, the
    //last motion to stop — the cover→source swap has to outwait its sub-pixel tail, exactly as
    //it outwaits the flight's on the drag path.
    private func landOnSlot() {
        withAnimation(Self.landingDipIn) { landingScale = Self.landingDip }
        if shape.tint != nil { withAnimation(Self.landingTintIn) { rimTint = 1 } }
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
                    if shape.tint != nil { rimTint = 1 }
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
                //Over the arrival's last 40%: every landing tick is past tArrive (shouldLand), so the tint is full at the commit
                if shape.tint != nil { rimTint = DragTuning.smoothstep(CGFloat((elapsed / max(plan.tArrive, 0.001) - 0.6) / 0.4)) }
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
                guard landed, !closing, !dragLocked, !keyboardFocused, !leaving else { return }
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
    var breath: CGFloat //The open's over-expansion, 0 → 1 → 0 (EventZoomChoreo.breathRise/Settle) — the whole stack's scale (per-edge for a card, uniform for a lens) and centre shift, see breathTransform
    let cardLanding: Bool //A card's tap-close landing (EventZoomChoreo.landCard): the fold rides p 1:1 and p < 0 is the sink
    let source: CGRect //The source's frame, global
    let shape: EventZoomSourceShape //Its rounding — a circle keeps deriving from the current size; its ring is the glass rim the close grows around the photo
    let card: CGRect //The card's resting frame, global (drag included — it reports live)
    let pager: CGRect //The pager band, global
    let photo: UIImage
    let chrome: AnyView? //The source's chrome copy — laid out at source size, transform-ridden, gone over the open's first beat
    let bandCopies: [EventZoomBandChromeCopy] //The band's OWN chrome, twinned at takeoff — pops in riding the flight, cut with the cover
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
    let ctaFont: Font //The landing's own type, so the flying word never arrives in a different one
    let ctaLineLimit: Int
    let rows: [EventZoomRowFlight] //The lines the source and the card both draw — empty unless both ends marked and measured
    let rowFade: Double //Their hand-off, faded off the identical real rows painted under them since the landing
    let corner: EventZoomCornerFlight? //The source's corner capsule and the band disc it morphs into — nil unless both a source marked one and a flight flies
    let coverShown: Bool
    let titleShown: Bool //The name morph's pieces outlive the cover's cut by their own fade
    let titleFade: Double
    let rimMounted: Bool //The landing rim's view exists from the landing on — mounted by a bare write, never inserted into a close in flight
    let rimTint: CGFloat //The rim's tint mix, the choreo's model value — deliberately NOT in animatableData: the rim animates it on its own attribute (EventZoomLandingRim)
    let shadow: Double //The card's resting shadow's strength (EventZoomChoreo.shadowStrength)
    let drawn: EventZoomDrawnBreath //Where this frame's breath is left for a departure to read

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
        //A card's contents — photo, title, rows, CTA — land a few points HIGH inside the landed outline
        //and settle down as one rigid piece on the breath's clock (EventZoomChoreo.innerLift): the
        //outline is already still while they settle, the picture's small upward bounce of Arthur's
        //reference clip (device 2026-09-05). Translation only: every shape and gap inside stays
        //constant. The outline itself keeps only a barely perceptible give (breathPeak). A lens has
        //no inner lift. Let out with the fold under a close or a drag.
        let lift = shape.isLens ? 0 : EventZoomChoreo.innerLift * breath * (1 - fold)
        let _ = drawn.record(scale: breathScale, shift: breathShift, lift: lift)
        //The WHOLE landed stack breathes — cover, heroes, rows, CTA together — so the card reads as one
        //rigid object overshooting, the pending calendar's lens included. A shell-only breath with the
        //content held still read as two bodies: the rows and the button froze ~90ms before the frame
        //peaked and the margin under the button visibly grew and shrank (device video 2026-09-05). A
        //card's per-edge breath is anisotropic, so text is stretched ~3% vertically for ~150ms at the
        //peak; measured on device as a 3% edge-contrast dip, below what the eye reports at 60fps, and
        //the price of a card that moves as one.
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
        //this frame — so the capsule can never sit outside it. Open only: a close drops the capsule
        //(EventZoomChoreo.close) and lets the fold take the real CTA away with the rows.
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
        //A lens' band-chrome twins wait for its corners: the cover's radius eases from half its size to the
        //band's only as it lands, so a corner piece shown on `arrive` would sit off the photo. Full at 0.97,
        //before the cut; the 0.8 start is a first tuning, to judge by eye
        let lensTwinArrive = smoothstep((p - 0.8) / 0.17)
        //The frost's capsule, posed as INSETS from the cover's foot exactly as the title is (the name
        //morph's rule): the band's measured glyph rect, its leading and bottom insets held against the
        //cover's own edges — never scaled with the cover, because the words it backs never are. At
        //p = 1 the cover is the band, so this IS the live page's capsule. Empty until the pager has
        //measured, which the flight waits out (`openWhenMeasured`).
        let bandTitle: CGRect? = pagerTitle.isEmpty ? nil : CGRect(
            x: pagerTitle.minX,
            y: cover.height - (pagerLocal.height - pagerTitle.maxY) - pagerTitle.height,
            width: pagerTitle.width, height: pagerTitle.height)

        content
            .offset(y: -lift) //Before the mask: the contents move under a stationary window, the outline stays
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
            }
            .overlay {
                //From the landing on (a bare write, no morph in flight), so a close never inserts
                //it mid-spring; dark until the rim has width, or its edge would fringe the cover's
                if glassRing > 0, rimMounted || chromeMix > 0 {
                    EventZoomLandingRim(tintMix: rimTint, tint: shape.tint,
                                        size: CGSize(width: max(cover.width + 2 * rim, 1), height: max(cover.height + 2 * rim, 1)),
                                        topRadius: coverTopRadius + rim, //Concentric: the cover's corner plus the rim between them
                                        bottomRadius: coverBottomRadius + rim)
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
                        .frame(width: max(cover.width, 1), height: max(cover.height, 1))
                        .overlay {
                            if let chrome, chromeCopy > 0 {
                                //Laid out ONCE at the source's size and transform-ridden, never
                                //re-laid-out in flight — a glur or a scrim re-rendered at an
                                //animating size is the jitter the flight was tuned out of
                                chrome
                                    .environment(\.eventZoomTitleFlying, nameMorph != nil)
                                    .environment(\.eventZoomButtonFlying, buttonHero)
                                    .environment(\.eventZoomRowsFlying, !rows.isEmpty)
                                    .environment(\.eventZoomCornerSource, corner != nil && card.width > 1 ? .ghost : .inert) //Ghosted exactly when the hero draws
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
                        .offset(y: -lift) //With the contents; inside the cover's own clip, its white filling the vacated foot
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
                        .position(x: cover.midX, y: cover.midY)
                        .allowsHitTesting(false)
                }
            }
            //The band's own chrome — the top row, a back button — riding the flight instead of waiting
            //out the landing. ABOVE the cover for the reason the name morph is, and one more: the
            //cover's chain ends in a `.shadow` (`CoverShadow`), and a layer effect above Liquid Glass
            //rasterizes every lens beneath it — and these pieces ARE lenses. Held against the cover's
            //corners and never scaled with it, so at p = 1 the cover is the band and each twin sits on
            //the real piece to the pixel: the hand-off is the cover's own cut, on identical pixels, and
            //the real one has been painted behind it since the landing. Mounted with the cover, from
            //takeoff. On the title's ramp, so everything the band wears lands together.
            //Gated on the LIST, not on `chromeMix`: the hand-off empties it, and a landed close refills it from
            //the page as it stands at its start (`close()`) — the takeoff's were built before the card was
            //ever touched, and the corner's own control can have changed since. A close begun BEFORE the hand-off keeps them, and they ride
            //`arrive` back down with the title, the frost and the foot they arrived with. Cutting those
            //at the close's first frame instead left the corner bare on a photo still fully on screen,
            //with no real piece under it to take over (`settled` is false from `close()`'s first line) —
            //the CTA capsule can be dropped instantly there only because its real button IS underneath.
            .overlay {
                if coverShown, !bandCopies.isEmpty, pagerLocal.width > 1 {
                    ZStack {
                        ForEach(bandCopies) { bandChromeTwin($0, cover: cover, band: pagerLocal, pop: shape.isLens ? lensTwinArrive : arrive) }
                    }
                    .environment(\.eventZoomCornerMorphing, corner?.landingTaken == true) //The corner hero draws the disc: the twin keeps its slot
                    .offset(y: -lift) //With the picture it sits on
                }
            }
            //The corner: the source's capsule morphing into the band's disc, or carried alone on its own insets while
            //the twins fade the disc out (`cornerHero`). Above the cover and the twins — lenses, under no layer effect
            .overlay {
                if coverShown, let corner, card.width > 1 { //The card, not the band: the hero is posed from the card alone
                    cornerHero(corner, cover: cover, sourceLocal: sourceLocal,
                               t: min(max(pLanded, 0), 1), chromeCopy: chromeCopy, arrive: arrive)
                        .offset(y: -lift) //With the picture it sits on
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
                    .opacity(titleFade)
                    .offset(y: -lift) //With the picture it sits on
                }
            }
            //The button morph, above the card's foot for the same reason the name is above the
            //cover: it is posed in the card's own space and no clip of the card's should crop it
            .overlay {
                if buttonHero, let ctaMorph { ctaHero(ctaMorph).offset(y: -lift) } //With the CTA it lands on
            }
            //The rows, above the card's body for the reason the name and the capsule are: each is
            //posed in the card's own space, and the window's mask — which is what the body wears —
            //would crop a word that is still out over the artwork. Their landing pads are inside the
            //card, so they ride the same inner lift as the rows they hand off to.
            .overlay {
                if !rows.isEmpty {
                    ZStack {
                        ForEach(rows, id: \.kind) { row in
                            rowHero(EventZoomRowMorph(row: row, card: card, sourceLocal: sourceLocal,
                                                      bounds: bounds, window: window, cover: cover,
                                                      p: pLanded))
                        }
                    }
                    .opacity(rowFade)
                    .offset(y: -lift) //With the rows they land on
                }
            }
            //Window, cover and rim breathe together about the cover's centre — the wind's
            //settle-pop, the lens' landing breath and the card's sink alike; scaling the cover
            //alone would let the masked card's white peek out around the compressed circle.
            //Render-only, so the measured cardRect never feeds back into the flight's frames
            .scaleEffect(pop * landingScale * sink, anchor: UnitPoint(
                x: bounds.width > 0 ? cover.midX / bounds.width : 0.5,
                y: bounds.height > 0 ? cover.midY / bounds.height : 0.5))
            //The open's breath (breathScale/breathShift above, on EventZoomChoreo's breath clock): the
            //whole landed stack — cover, heroes, the live card — carried past its size and settled, a
            //render transform since a window cannot show more card than there is; everything inside
            //rides it together, so the hand-offs stay on identical pixels whenever they fall. The fold
            //fades it: a close or a drag begun mid-breath lets it out with the collapse, never cut.
            .scaleEffect(x: breathScale.width, y: breathScale.height, anchor: .center)
            .offset(breathShift)
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

    //One twinned band-chrome piece, posed for this frame. Laid out in a box the BAND's size and aligned
    //to its own corner, so the piece's paddings resolve exactly as the live `.overlay(alignment:)`
    //resolves them, and that box held against the matching corner of the cover — insets, never a lerp
    //and never a scale of the box (`bandTitle`'s rule; the source chrome's `scaleEffect` is for chrome
    //that is LEAVING at source size, and would land this one wrong).
    private func bandChromeTwin(_ piece: EventZoomBandChromeCopy, cover: CGRect, band: CGRect, pop: CGFloat) -> some View {
        let size = CGSize(width: max(band.width, 1), height: max(band.height, 1))
        let unit = piece.corner.unit
        return piece.view
            //The house `opacityPop`'s own pose — scale and opacity — driven by the flight's geometry
            //instead of by a curve, so the arrival reads as the pop every other piece of chrome in the
            //app makes. It is not what makes the CUT match: the real piece is revealed at scale 1 and
            //this is at scale 1 from p = 0.95, so the two meet whatever the ramp did before that.
            //The scale re-renders the piece's lens at a new size for the ramp's ~150ms; it is the one
            //thing here that costs, and `Self.twinPopScale` is the knob.
            .scaleEffect(piece.popsIn ? Self.twinPopScale + (1 - Self.twinPopScale) * pop : 1)
            .opacity(pop)
            .frame(width: size.width, height: size.height, alignment: piece.corner.alignment)
            .position(x: cover.minX + unit.x * cover.width + (0.5 - unit.x) * size.width,
                      y: cover.minY + unit.y * cover.height + (0.5 - unit.y) * size.height)
            //A twin is inert by contract (see the modifier's doc), so this only keeps the flight's plane
            //from claiming the tap in SwiftUI's own hit-testing — interactive glass still installs a
            //platform view that claims hitTest regardless ([[project_ios26_glass_hittest_stall]]), which
            //is why the twin must never be a live control
            .allowsHitTesting(false)
    }

    //The twin's arrival scale — the house `opacityPop`'s, so it matches the real piece it hands off to.
    //It is also the one expensive thing in this flight: these pieces are `.clearGlass`, and a lens
    //re-rendered at a new size every frame costs about seven eighths of the frame rate (the reason the
    //CTA flies a FLAT capsule and hands its one real lens off unscaled). These capsules are ~87 × 26 against
    //that CTA's full-width one, and it only scales over `arrive`'s 150ms — but if the open ever drops
    //frames on device, set this to 1 and the twins arrive on opacity alone, exactly as the band's title,
    //its frost capsule and its foot already do. Nothing else has to change: the pop ends at scale 1 well
    //before the cut either way.
    private static let twinPopScale: CGFloat = PopMotion.opacityShrunkScale

    //The corner hero. Glass may move, never resize — a lens re-rendered at a new size every frame costs most of the
    //frame rate (`ctaHero`'s rule) — so the capsule and the disc are each the real control's inert look at its own
    //fixed size, and what changes shape between them is `ScoopGlassStandIn`, glass's own pre-26 material, which may
    //resize, sized to the morph every frame. The capsule and its word leave over the CTA's shed as the stand-in takes
    //the shape; the disc and its glyphs arrive over the CTA word's window as the stand-in gives it back. Each lens
    //exists only inside its own ramp — stacked glass washes the composite even at opacity 0. At t = 0 this IS the
    //resting capsule and at t = 1 the resting disc, on their own lenses, so both ends meet identical pixels: the
    //source's own at the tap and the landing, the real disc (painted under it since `land()`) at the cover's cut.
    //Posed as insets from the cover's corner (`bandChromeTwin`'s rule), so it rides the sink, the wind's belly and
    //the breath with the picture. Without a disc taken it carries the capsule alone on its source insets, fading with
    //the collapse where the chrome copy's own capsule would; on a swipe it fades the taken disc out on the band's own
    //ramp (`arrive`, the twins' clock) as the capsule fades back in. ONE slot per lens, whichever way the flight goes:
    //taking the disc, or a close switching the mode, only moves numbers — never swaps a lens on screen for a fresh one.
    private func cornerHero(_ corner: EventZoomCornerFlight, cover: CGRect, sourceLocal: CGRect,
                            t: CGFloat, chromeCopy: CGFloat, arrive: CGFloat) -> some View {
        let unit = (corner.landing?.corner ?? .topTrailing).unit
        let from = corner.source.offsetBy(dx: -card.minX, dy: -card.minY)
        let fromInset = CGSize(width: unit.x == 1 ? sourceLocal.maxX - from.maxX : from.minX - sourceLocal.minX,
                               height: unit.y == 1 ? sourceLocal.maxY - from.maxY : from.minY - sourceLocal.minY)
        let taken = corner.landingTaken ? corner.landing : nil
        let morph = corner.morphs ? taken : nil
        let open = smoothstep(t)
        let size = morph.map { CGSize(width: lerp(from.width, $0.size.width, open),
                                      height: lerp(from.height, $0.size.height, open)) } ?? from.size
        let inset = morph.map { CGSize(width: lerp(fromInset.width, $0.inset.width, t),
                                       height: lerp(fromInset.height, $0.inset.height, t)) } ?? fromInset
        let centre = Self.cornerCentre(cover: cover, unit: unit, inset: inset, size: size)
        let capsule = morph == nil ? chromeCopy : 1 - smoothstep(t / Self.cornerShedEnd)
        let disc = morph == nil ? arrive : smoothstep((t - Self.cornerArrivalStart) / Self.cornerArrivalSpan)
        let discCentre = taken.map { morph == nil
            ? Self.cornerCentre(cover: cover, unit: unit, inset: $0.inset, size: $0.size) : centre } ?? centre
        return ZStack {
            if morph != nil {
                ScoopGlassStandIn(shape: Capsule())
                    .frame(width: max(size.width, 1), height: max(size.height, 1))
                    .opacity(1 - max(capsule, disc))
                    .position(centre)
            }
            if capsule > 0 {
                corner.sourceLook.fixedSize().opacity(capsule).position(centre)
            }
            if let landingLook = corner.landingLook, taken != nil, disc > 0 {
                landingLook.fixedSize().opacity(disc).position(discCentre)
            }
        }
        .allowsHitTesting(false)
    }

    //A piece `size` big, held `inset` in from the cover's corner `unit`: its centre in the card's space
    private static func cornerCentre(cover: CGRect, unit: CGPoint, inset: CGSize, size: CGSize) -> CGPoint {
        CGPoint(x: unit.x == 1 ? cover.maxX - inset.width - size.width / 2 : cover.minX + inset.width + size.width / 2,
                y: unit.y == 1 ? cover.maxY - inset.height - size.height / 2 : cover.minY + inset.height + size.height / 2)
    }

    //The corner hero's capsule and word are gone by this share of the flight — the CTA capsule's own shed —
    private static let cornerShedEnd: CGFloat = 0.35
    //— and its disc and glyphs arrive over the CTA word's window, crisp and whole just before touchdown
    private static let cornerArrivalStart: CGFloat = 0.62
    private static let cornerArrivalSpan: CGFloat = 0.36

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
            //Arriving late enough that the capsule already reaches past it, and out of focus (see
            //`label` and `labelArrivalBlur`): posed still, its whole arrival IS the pull into focus.
            //The blur goes AFTER the scale, so its radius is in screen points, and BEFORE the
            //`.position`, which would otherwise hand it the capsule's whole frame to filter.
            Text(morph.text)
                .font(ctaFont) //The landing's own, reported by `.eventZoomButtonTarget`
                .foregroundStyle(Color.white)
                .lineLimit(ctaLineLimit)
                .multilineTextAlignment(.center) //A two-line CTA centres its lines; the hero must too
                .fixedSize()
                .scaleEffect(Self.labelShrunkScale + (1 - Self.labelShrunkScale) * morph.label)
                .blur(radius: Self.labelArrivalBlur * (1 - morph.label))
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
    //And its arrival focus, which is what the arrival actually READS as — the scale alone let the
    //word simply appear. Four points, a third of ModernEra Bold 18's 12.6pt cap: the house pop's 8
    //is authored for a whole element popping on a spring of its own, and at this size it welds the
    //two lines of the respond card's CTA (1.5pt of ink between them — ModernEra carries no leading)
    //into one bar for most of the ramp. A radius, never a `blurPop`: driven by `label`, so it is
    //exactly 0 well before the hand-off, and can never go negative on a close's rebounding p.
    private static let labelArrivalBlur: CGFloat = 4

    //One flying row, with every piece the SAME element the whole way — nothing is ever drawn twice at
    //two positions (the doubled text was the old flight's sloppy mid-air frame, device screenshot
    //2026-08-20). One icon slot, where the card's white template glyph dissolves into the card body's
    //drawn art in place; one text column, where the card's medium and the row's 17 bold sit on the
    //SAME leading anchor, size-matched by scale so the glyphs coincide, and cross-fade — a weight
    //cannot be scaled into another weight, and the pair is what makes the change read as one word
    //restyling rather than two words swapping. Both pieces hang out of a zero-size leading-aligned
    //box, so a row's position is one point and its own layout never has to be measured.
    private func rowHero(_ morph: EventZoomRowMorph) -> some View {
        ZStack {
            ZStack {
                Image(morph.kind.sourceIcon)
                    .renderingMode(.template)
                    .foregroundStyle(morph.tint)
                    .opacity(1 - morph.art)
                Image(morph.kind.landingIcon)
                    .renderingMode(.original)
                    .opacity(morph.art)
            }
            .scaleEffect(morph.iconScale) //The card's glyph size at takeoff, the row's at the hand-off
            .frame(width: EventZoomRowMorph.iconWidth)
            .offset(y: morph.iconNudge)
            .frame(width: 0, height: 0)
            .position(morph.icon)

            ZStack(alignment: .leading) {
                //The card's own line, at the card's own type
                Text(morph.sourceText)
                    .font(.body(EventZoomRowMorph.sourceSize, .medium))
                    .frame(width: max(morph.sourceTextWidth, 1), alignment: .leading)
                    .scaleEffect(morph.sourceScale, anchor: .leading)
                    .opacity(1 - morph.weight)

                //The landing's own line, at the landing's own type — and its trailing affordance,
                //which the card has none of to hand over, arriving with the row it belongs to
                HStack(spacing: 12) {
                    Text(morph.text)
                    if morph.kind == .time { DropDownButton(isOpen: false).opacity(morph.arrive) }
                }
                .font(.body(17, .bold))
                //The row's own shrink, so a string that lands scaled down is flown scaled down too:
                //the reported frame is the row box, not the glyph run, and a hero laid out free
                //would hand off to a visibly narrower word
                .frame(width: max(morph.landingTextWidth, 1), alignment: .leading)
                .oneLineLimitAndShrink()
                .scaleEffect(morph.landingScale, anchor: .leading)
                .opacity(morph.weight)
            }
            .foregroundStyle(morph.tint) //One colour for both twins: the word changes weight once and hue once, on separate clocks
            .lineLimit(1)
            .frame(width: 0, height: 0, alignment: .leading)
            .position(morph.textOrigin)
        }
        .allowsHitTesting(false)
    }

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
        //same rule the name morph pays. The CTA sits 24pt in; a source may sit further (the invite
        //card's button rides its glass: inset + padding), so the trailing inset closes by `labelStart`,
        //the moment the word begins to arrive. The word's window was cleared against a capsule already
        //on its landing edge, and from there the open is the pure leftward stretch; a source already at
        //24 (the Meet card) is unchanged. At p = 1 the window is the card's bounds and this resolves to
        //the CTA's rect exactly — no pin needed.
        let open = Self.smoothstep(t)
        let width = Self.lerp(from.width, to.width, open)
        let height = Self.lerp(from.height, to.height, open)
        let trailing = Self.lerp(sourceLocal.maxX - from.maxX, bounds.maxX - to.maxX, Self.smoothstep(t / Self.labelStart))
        let bottom = Self.lerp(sourceLocal.maxY - from.maxY, bounds.maxY - to.maxY, t)
        rect = CGRect(x: window.maxX - trailing - width,
                      y: window.maxY - bottom - height,
                      width: width, height: height)
        labelX = to.midX

        //Tint and lens leave together over the first third: past that the capsule is too far from a
        //circle for the 42pt lens to sit on it honestly
        shed = 1 - Self.smoothstep(t / 0.35)
        //The word arrives once the capsule reaches past its landing centre — by t = 0.62 even the
        //narrowest CTA (the respond card's half-width two-line one) covers its own box with points
        //to spare, blur halo included, which matters because nothing clips that halo: this overlay
        //is applied outside the window's mask. Full at t = 0.98, which buys the arrival ~126ms
        //against the old (0.7, 0.25) window's ~84 — the flight's spring is easing hard through
        //here, so the milliseconds live at the END of the range, and a window widened at the front
        //would still have read as a flash. Crisp a tenth of a second before the landing — see the
        //note on the leaf: a pop with a spring of its own outlives the hand-off
        label = Self.smoothstep((t - Self.labelStart) / 0.36)
    }

    private static let labelStart: CGFloat = 0.62 //Where the word begins to arrive — and where the trailing inset has landed

    private static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    private static func smoothstep(_ t: CGFloat) -> CGFloat {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }
}

///Where each piece of one flying row sits this frame, and how far it is through each of its three
///changes. Posed as INSETS from the revealed window, never as a lerp between two screen rects — the
///rule the name and the capsule both pay: the window is exactly what the card is showing this frame,
///so a row posed against it can never sit outside the card. Leading and vertical-centre insets,
///because a row is laid out from the card's leading edge down its head; both resolve to the measured
///ends exactly at p = 0 and p = 1, so no pin is needed at either end.
struct EventZoomRowMorph {

    //The row's inner geometry at each end. The card's `lineSection` and the body's `iconRow` are each an
    //HStack of a 20pt icon column and a gap; the column is shared, but the card runs a tighter gap and a
    //smaller glyph, so both ride the flight from one end to the other. If either end moves off these, the
    //words and the icon stop landing together — these are the constants to look at.
    static let iconWidth: CGFloat = 20
    static let sourceIconGap: CGFloat = 18 //`InviteCardOverlay.lineSection` reads it
    private static let landingIconGap: CGFloat = 20 //`EventTypeTimePlace`'s `iconGap`
    static let sourceIconScale: CGFloat = 1.1 //`InviteCardOverlay.lineSection` reads it
    private static let landingIconScale: CGFloat = 1.2 //`EventTypeTimePlace.iconRow`'s glyph

    let kind: EventZoomRowKind
    let sourceText: String
    let text: String
    let icon: CGPoint //The icon slot's centre, in the card's space
    let textOrigin: CGPoint //The words' leading-centre, one icon column and gap to its right
    let sourceTextWidth: CGFloat
    let landingTextWidth: CGFloat
    let sourceScale: CGFloat //The card's type scaling toward the row's
    let landingScale: CGFloat //The row's type scaled to meet it, so the two runs coincide
    let iconScale: CGFloat //The glyph's size, the card's toward the row's — on the type's clock
    let weight: CGFloat //0 = the card's look, 1 = the landing's: the twins' cross-fade
    let art: CGFloat //The icon's dissolve, on the same clock as the weight — one material change, not two
    let tint: Color //White on the artwork, the body's own ink on the card: mixed across the WHOLE flight
    let arrive: CGFloat //The chevron the card has none of, arriving with the row
    let iconNudge: CGFloat //The card nudges its glyph 2pt up to centre it; the body's art needs none

    init(row: EventZoomRowFlight, card: CGRect, sourceLocal: CGRect, bounds: CGRect,
         window: CGRect, cover: CGRect, p: CGFloat) {
        kind = row.kind
        sourceText = row.sourceText
        text = row.text

        let from = row.source.offsetBy(dx: -card.minX, dy: -card.minY)
        let to = row.dest.offsetBy(dx: -card.minX, dy: -card.minY)
        let t = min(max(p, 0), 1)
        let open = Self.smoothstep(t)

        let leading = Self.lerp(from.minX - sourceLocal.minX, to.minX - bounds.minX, t)
        let centre = Self.lerp(from.midY - sourceLocal.minY, to.midY - bounds.minY, t)
        let x = window.minX + leading
        let y = window.minY + centre
        //The gap rides the same linear t as the leading inset, so the words' start moves as one line
        let gap = Self.lerp(Self.sourceIconGap, Self.landingIconGap, t)
        icon = CGPoint(x: x + Self.iconWidth / 2, y: y)
        textOrigin = CGPoint(x: x + Self.iconWidth + gap, y: y)

        sourceTextWidth = from.width - Self.iconWidth - Self.sourceIconGap
        landingTextWidth = to.width - Self.iconWidth - Self.landingIconGap

        //One ratio, worn from opposite ends: whichever twin is visible is at scale 1 where it is the
        //truth, so both resting endpoints are the real type rather than a transformed copy of it
        let ratio = Self.landingSize / Self.sourceSize
        sourceScale = Self.lerp(1, ratio, open)
        landingScale = Self.lerp(1 / ratio, 1, open)
        iconScale = Self.lerp(Self.sourceIconScale, Self.landingIconScale, open)

        //The weight swap is EARLY and quick when the two ends say the same words: it is invisible
        //then — same string, same anchor, a hair of weight — and getting it over with while the row
        //is still small and moving fastest keeps the two runs from drifting apart at their tails,
        //which is where a leading-anchored pair of different weights diverges (bold is wider). When
        //the ends say DIFFERENT things the same cross-fade is the only thing carrying the word
        //change, so it takes the long way instead and reads as a dissolve rather than a flicker.
        weight = row.sourceText == row.text
            ? Self.smoothstep((t - 0.08) / 0.22)
            : Self.smoothstep((t - 0.15) / 0.6)
        art = Self.smoothstep((t - 0.08) / 0.22)

        //Geometry, not a clock: the row leaves the artwork as white and arrives on paper as ink, so
        //it turns over exactly where it clears the cover's foot — wherever in the flight that falls.
        //Keyed on p instead, the word spends the middle of every flight a mid-grey, which is muddy
        //on the photo and washed out on the paper; and because the cover's foot is a live rect, this
        //also holds for a drag that stalls the row half over the picture. The 20pt band is the fade's
        //whole width, started a touch before the crossing so no frame lands on a hard switch.
        let clearance = y - cover.maxY
        tint = Color.white.mix(with: .textPrimary, by: Double(Self.smoothstep((clearance + 6) / 20)))

        arrive = Self.smoothstep((t - 0.6) / 0.38)
        iconNudge = Self.lerp(-2, 0, t) //Geometry: the card's own optical centring, released as it lands
    }

    static let sourceSize: CGFloat = 18 //`InviteCardOverlay.lineSection` — its `rowSize`; the source copy draws at it too
    private static let landingSize: CGFloat = 17 //`EventTypeTimePlace`'s rows at `largeText`

    private static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    private static func smoothstep(_ t: CGFloat) -> CGFloat {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }
}

//The close's landing rim: the cover's outline pushed out in clipped glass, posed per frame by the morph. Its own
//Animatable view so the tint mix rides its OWN attribute — the morph's channels share one vector, which the tap's
//rebound spring retargets whole. Untinted until a close begins (the rim sits mounted at opacity 0 over the landed
//band, and glass at opacity 0 still washes what it covers); at full it passes the tint itself — the resting lens'
//own value, so the landed commit swaps identical glass.
private struct EventZoomLandingRim: View, Animatable {
    var tintMix: CGFloat
    let tint: Color?
    let size: CGSize
    let topRadius: CGFloat
    let bottomRadius: CGFloat

    var animatableData: CGFloat {
        get { tintMix }
        set { tintMix = newValue }
    }

    var body: some View {
        let glassTint: Color? = if let tint, tintMix > 0 { tintMix >= 1 ? tint : tint.opacity(Double(min(tintMix, 1))) } else { nil }
        Color.clear
            .frame(width: size.width, height: size.height)
            .containerGlassEffect(tint: glassTint, clipped: true, shape: UnevenRoundedRectangle( //Clipped: the ledger ring's own no-shadow floor, matched
                topLeadingRadius: topRadius,
                bottomLeadingRadius: bottomRadius,
                bottomTrailingRadius: bottomRadius,
                topTrailingRadius: topRadius))
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
