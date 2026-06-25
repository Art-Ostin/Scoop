//
//  ProfileMorph.swift
//  Scoop
//
//  Created by Art Ostin on 11/06/2026.
//

import SwiftUI

//Hero-style open and reverse-zoom close for a profile:
//— OPEN: a floating copy of the tapped source image (ProfileMorphLayer) flies from
//  the source frame to the profile pager frame while the profile content fades in.
//  Source and destination hide while the copy is in flight, so exactly one
//  rendering of the image is ever on screen.
//— CLOSE: the whole profile surface shrinks — scale, clip and position interpolate
//  (mirroring the native zoom navigation transition in reverse) until the pager
//  image region maps exactly onto the source frame, cross-dissolving into the real
//  source at the end. The interactive drag is native-style: the card shrinks
//  around the touch (top edge tracks the finger, bottom edge lifts progressively
//  off the screen bottom, never past it), finger-tracked on both axes, fully
//  reversible, with display-radius corners, an elevation shadow and a dim on the
//  screen underneath (ProfileZoomDismissModifier); no vertical slide anywhere.
//OPEN is one 0.3s easeInOut transaction (never altered); CLOSE releases into a
//velocity-carrying spring, like the native dismissal.
//
//Wiring a host container:
//  1. own a `@State private var morph = ProfileMorphState()`
//  2. apply `.profileMorphHost(morph)` to the ZStack that presents ProfileView
//  3. drive the presented ProfileView with `.opacity(morph.contentOpacity)` (no
//     move transition) and seed its images with the tapped one if not yet loaded
//  4. mark the tappable image with `.profileMorphSource(id:radii:)` and call
//     `morph.beginOpen(id:image:)` right before presenting
//  5. if the profile can be torn down programmatically (cleared without going
//     through animateDismiss), call `morph.reset()` at that moment
//ProfileView picks the state up from the environment and routes every dismiss
//path through the reverse zoom (see animateDismiss in ProfileOverlays.swift).
@Observable
final class ProfileMorphState {

    enum Phase: Equatable {
        case inactive   //no profile up
        case opening    //flight: source -> pager, content fading in
        case presented  //profile fully open, floating copy removed
        case closing    //flight: pager -> source, content fading out
    }

    static let duration: Double = 0.2 //Key determines speed.
    static let cardRadii = RectangleCornerRadii(topLeading: 14, bottomLeading: 10, bottomTrailing: 10, topTrailing: 14)
    static let pagerRadii = RectangleCornerRadii(topLeading: 16, bottomLeading: 16, bottomTrailing: 16, topTrailing: 16)

    private(set) var phase: Phase = .inactive

    //Floating copy render state — read only by ProfileMorphLayer.
    private(set) var image: UIImage?
    private(set) var flightRect: CGRect = .zero
    private(set) var flightRadii = ProfileMorphState.cardRadii

    //Whole-profile fade, animated in the same transaction as the open flight.
    private(set) var contentOpacity: Double = 0

    //Reverse-zoom progress (0 = full screen, 1 = collapsed onto the source).
    //Animated by animateDismiss; rendered by ProfileZoomDismissModifier.
    var closeProgress: CGFloat = 0

    //Who hides while the floating copy covers their exact frame.
    private(set) var hiddenSourceId: String?
    private(set) var hiddenDestIndex: Int?

    //Live geometry, reported by the sources and the pager. Layout positions only —
    //visual transforms (details header shift) are snapshotted at close. Not
    //observed: geometry reports during scrolls must never invalidate views.
    @ObservationIgnored private var sourceRects: [String: CGRect] = [:]
    @ObservationIgnored private var sourceRadii: [String: RectangleCornerRadii] = [:]
    @ObservationIgnored private(set) var destRect: CGRect = .zero
    @ObservationIgnored private var sourceId: String?
    @ObservationIgnored private var awaitingDestination = false
    //Vertical offset between the pager's layout rect and where it is drawn (the
    //details-open header shift), captured when the close begins.
    @ObservationIgnored private(set) var closePagerShift: CGFloat = 0

    var isMorphing: Bool { phase == .opening || phase == .closing }
    var canMorphClose: Bool { phase == .presented }

    //Where (and with which corners) the reverse zoom lands.
    var closeTargetRect: CGRect? { sourceId.flatMap { sourceRects[$0] } }
    var closeTargetRadii: RectangleCornerRadii {
        sourceId.flatMap { sourceRadii[$0] } ?? Self.cardRadii
    }

    func reportSource(id: String, rect: CGRect, radii: RectangleCornerRadii) {
        sourceRects[id] = rect
        sourceRadii[id] = radii
    }

    //The settled page image sits 6pt inside the pager container.
    func reportDestination(containerRect: CGRect) {
        destRect = containerRect.insetBy(dx: 6, dy: 0)
        startFlightIfReady()
    }

    //Setup only (never animated) — call right before presenting the profile. The
    //flight starts once the pager reports a real destination frame, so async
    //layout/image loading can delay it a frame but never make it jump.
    func beginOpen(id: String, image: UIImage?) {
        guard phase == .inactive else { return }
        sourceId = id
        destRect = .zero
        contentOpacity = 0
        closeProgress = 0
        if let image, let rect = sourceRects[id], rect.width > 1 {
            self.image = image
            flightRect = rect
            flightRadii = sourceRadii[id] ?? Self.cardRadii
            hiddenSourceId = id
            hiddenDestIndex = 0
        } else {
            //Nothing to fly (image missing / source unmeasured) — profile just fades.
            self.image = nil
            hiddenSourceId = nil
            hiddenDestIndex = nil
        }
        awaitingDestination = true
        phase = .opening
    }

    private func startFlightIfReady() {
        guard phase == .opening, awaitingDestination,
              destRect.width > 50, destRect.height > 50 else { return }
        awaitingDestination = false
        withAnimation(.easeInOut(duration: Self.duration)) {
            contentOpacity = 1
            if image != nil {
                flightRect = destRect
                flightRadii = Self.pagerRadii
            }
        } completion: { [weak self] in
            self?.finishOpen()
        }
    }

    //Handoff: the pager image appears in the exact frame the floating copy lands
    //on, in the same non-animated transaction the copy is removed. The source also
    //unhides here — it sits behind the now-opaque profile, ready to be revealed
    //the moment an interactive dismiss starts shrinking the surface.
    private func finishOpen() {
        guard phase == .opening else { return }
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) {
            phase = .presented
            hiddenDestIndex = nil
            hiddenSourceId = nil
            image = nil
        }
    }

    //Arm the reverse zoom (never animated): snapshot how far the pager is drawn
    //from its layout rect (details-open header shift). The caller then animates
    //closeProgress to 1, which ProfileZoomDismissModifier renders as the whole
    //surface shrinking onto the source rect.
    func beginZoomClose(pagerVisualShift: CGFloat) {
        guard phase == .presented else { return }
        closePagerShift = pagerVisualShift
        hiddenSourceId = nil //the surface converges onto the visible source
        phase = .closing
    }

    //Signed remaining travel of the pager toward the source, in screen points —
    //normalizes a release velocity into closeProgress units so momentum carries
    //into the commit spring. The bottom-pinned drag moves the pager by roughly
    //the drag distance; an exact mapping isn't needed for momentum to feel right.
    func closeTravel(currentDrag: CGFloat) -> CGFloat {
        guard let target = closeTargetRect, destRect.height > 1 else { return 0 }
        return target.midY - (destRect.midY + closePagerShift + currentDrag)
    }

    //Call from the animation completion in a disabled-animations transaction,
    //before unmounting the profile.
    func finishClose() {
        guard phase == .closing else { return }
        phase = .inactive
        contentOpacity = 0
        closeProgress = 0
        closePagerShift = 0
        hiddenSourceId = nil
        hiddenDestIndex = nil
        image = nil
        awaitingDestination = false
    }

    //Instant teardown for programmatic dismissals — e.g. a response flow clearing
    //the presented profile behind a covering overlay. No flight, nothing hidden.
    func reset() {
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) {
            phase = .inactive
            contentOpacity = 0
            closeProgress = 0
            closePagerShift = 0
            hiddenSourceId = nil
            hiddenDestIndex = nil
            image = nil
            awaitingDestination = false
        }
    }
}

//Full-screen, non-interactive layer hosting the flying image. flightRect is in
//global screen coordinates, so positions convert through the layer's own origin.
struct ProfileMorphLayer: View {
    var morph: ProfileMorphState

    var body: some View {
        GeometryReader { geo in
            if morph.isMorphing, let image = morph.image {
                let origin = geo.frame(in: .global).origin
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: morph.flightRect.width, height: morph.flightRect.height)
                    .clipShape(UnevenRoundedRectangle(cornerRadii: morph.flightRadii, style: .continuous))
                    .position(x: morph.flightRect.midX - origin.x, y: morph.flightRect.midY - origin.y)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

//Marks a view as the flight source for a profile id: hides it while the floating
//copy is over it and keeps its on-screen frame reported. visualScale compensates
//for a render-only scaleEffect on the content, which geometry readers can't see.
struct ProfileMorphSourceModifier: ViewModifier {
    @Environment(ProfileMorphState.self) private var morph: ProfileMorphState?
    let id: String
    let radii: RectangleCornerRadii
    var visualScale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .opacity(morph?.hiddenSourceId == id ? 0 : 1)
            //Fires on layout and scroll, never mid-drag.
            .onGeometryChange(for: CGRect.self) { geo in
                geo.frame(in: .global)
            } action: { rect in
                morph?.reportSource(id: id, rect: scaled(rect), radii: scaledRadii)
            }
    }

    private func scaled(_ rect: CGRect) -> CGRect {
        guard visualScale != 1 else { return rect }
        return rect.insetBy(dx: rect.width * (1 - visualScale) / 2,
                            dy: rect.height * (1 - visualScale) / 2)
    }

    private var scaledRadii: RectangleCornerRadii {
        guard visualScale != 1 else { return radii }
        return RectangleCornerRadii(
            topLeading: radii.topLeading * visualScale,
            bottomLeading: radii.bottomLeading * visualScale,
            bottomTrailing: radii.bottomTrailing * visualScale,
            topTrailing: radii.topTrailing * visualScale
        )
    }
}

//MARK: - Reverse zoom dismissal

//Replaces the old vertical-slide dismissal. Applied to the whole profile surface:
//— while the dismiss drag tracks the finger (both axes, reversible), the surface
//  shrinks around the touch — bottom gap growing, never crossing the screen
//  bottom — corners curving to the display radius: a native zoom's interactive phase;
//— when the close commits, closeProgress springs 0→1 and the surface scales,
//  clips and repositions so the pager image region maps exactly onto the source
//  rect (scale factor source.width / pager.width), cross-dissolving at the end.
//All output is render-only (clip/scale/offset/shadow/opacity) — a drag or close
//never triggers a layout pass, matching the profile's transform-only philosophy.
struct ProfileZoomDismissModifier: ViewModifier {
    @Environment(ProfileMorphState.self) private var morph: ProfileMorphState?
    var ui: ProfileUIState
    let enabled: Bool

    //Layout frame in global coords + the full screen rect in local coords (the
    //background draws edge-to-edge via ignoresSafeArea, so the clip must start at
    //the true screen bounds, not the safe-area layout bounds).
    @State private var frame: CGRect = .zero
    @State private var screenLocal: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .modifier(ZoomDismissRender(
                dragX: enabled ? ui.profileOffsetX : 0,
                dragY: enabled ? max(ui.profileOffset, 0) : 0,
                progress: morph?.closeProgress ?? 0,
                frame: frame,
                screenLocal: screenLocal,
                pagerRect: morph?.destRect ?? .zero,
                pagerShift: morph?.closePagerShift ?? 0,
                sourceRect: morph?.closeTargetRect,
                sourceRadii: morph?.closeTargetRadii ?? ProfileMorphState.cardRadii,
                ui: ui
            ))
            //Layout geometry only — transforms above are invisible to this, so it
            //never fires mid-drag or mid-close. The screen rect comes from the
            //actual device screen (not reported safe-area insets, which can drift
            //from the physical edges), so the clip's corners land exactly on the
            //physical screen corners and all four round identically.
            .onGeometryChange(for: CGRect.self) { geo in
                geo.frame(in: .global)
            } action: { f in
                frame = f
                let screen = UIScreen.main.bounds
                screenLocal = CGRect(x: screen.minX - f.minX, y: screen.minY - f.minY,
                                     width: screen.width, height: screen.height)
            }
    }
}

//The per-frame renderer. Animatable over (dragX, dragY, progress): a snap-back
//springs the drag home, a committed close springs progress to 1 — both
//interpolate here, so direct manipulation and the completion animation share one
//continuous metric space and hand off without a seam.
//
//Where Apple's zoom parameters are private, the constants below were derived by
//matching the iOS 18 zoom dismissal by eye: shrink around the touch toward ~0.5
//scale with the bottom gap growing, display-radius corner curvature, a soft
//elevation shadow and a subtle dim underneath, all coupled to gesture progress.
struct ZoomDismissRender: ViewModifier, Animatable {
    var dragX: CGFloat
    var dragY: CGFloat
    var progress: CGFloat
    let frame: CGRect
    let screenLocal: CGRect
    let pagerRect: CGRect
    let pagerShift: CGFloat
    let sourceRect: CGRect?
    let sourceRadii: RectangleCornerRadii
    var ui: ProfileUIState?

    //The top edge tracks the finger exactly down to kneeScale, then rubber-bands
    //toward floorScale — the native card shrinks around the touch point.
    static let kneeScale: CGFloat = 0.62
    static let floorScale: CGFloat = 0.50
    //The bottom edge lifts off the screen bottom at this fraction of the finger
    //speed (native: the gap below the card grows as the swipe deepens, but the
    //card never travels past the screen bottom).
    static let bottomLift: CGFloat = 0.35
    //Damped horizontal follow, like the native card's side-drag.
    static let xFollow: CGFloat = 0.40
    //UIScreen's true display corner radius is private API; 55 sits close enough
    //to the current iPhone families that the curvature reads native.
    static let displayRadius: CGFloat = 55
    static let dimMax: Double = 0.18
    static let shadowOpacity: Double = 0.22
    static let shadowRadius: CGFloat = 35

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(dragX, AnimatablePair(dragY, progress)) }
        set {
            dragX = newValue.first
            dragY = newValue.second.first
            progress = newValue.second.second
            //Mirror spring-interpolated values so a regrab catches a snap-back
            //mid-flight (same pattern as AnimatedCardOffset — render transforms
            //are invisible to geometry, so this is the only true source).
            ui?.presentedProfileOffsetX = dragX
            ui?.presentedProfileOffset = dragY
        }
    }

    func body(content: Content) -> some View {
        let m = metrics()
        content
            .clipShape(ZoomClipShape(rect: m.clip, radii: m.radii))
            .scaleEffect(m.scale, anchor: .topLeading)
            .offset(x: m.offset.width, y: m.offset.height)
            .shadow(color: .black.opacity(m.shadow), radius: Self.shadowRadius, y: 12)
            .opacity(m.opacity)
            //The dim on the screen underneath: a background is laid out in the
            //unscaled frame, so the transforms above never move it.
            .background { Color.black.opacity(m.dim).ignoresSafeArea() }
    }

    private struct Metrics {
        var scale: CGFloat = 1
        var offset: CGSize = .zero
        var clip: CGRect = .zero
        var radii = RectangleCornerRadii()
        var opacity: Double = 1
        var shadow: Double = 0
        var dim: Double = 0
    }

    //Interactive phase, native style: the card shrinks around the touch — the top
    //edge sits at e (equal to the finger's travel until the knee, resisted
    //beyond it) while the bottom edge rises off the screen bottom at
    //bottomLift × e, so the gap below the card grows with the swipe. Scale
    //follows from both edges: s = 1 - e·(1 + bottomLift) / H. Dividing the
    //corner radius by s holds the on-screen curvature at the display radius,
    //identical on all four corners.
    private func dragMetrics() -> (scale: CGFloat, offset: CGSize, radius: CGFloat, chrome: Double) {
        let h = screenLocal.height
        let dy = max(dragY, 0)
        let rate = 1 + Self.bottomLift
        let knee = h * (1 - Self.kneeScale) / rate
        let span = h * (Self.kneeScale - Self.floorScale) / rate
        let e = dy <= knee ? dy : knee + band(dy - knee, limit: span)
        let s = 1 - e * rate / h
        let offset = CGSize(
            width: screenLocal.minX * (1 - s) + screenLocal.width * (1 - s) / 2 + dragX * Self.xFollow,
            height: screenLocal.minY * (1 - s) + e
        )
        //Corners hit the display radius within the first ~12pt, so all four match
        //from the very start of the gesture (the background's own top rounding is
        //smaller and disappears inside this clip immediately).
        let ramp = min(dy / 12, 1)
        return (s, offset, Self.displayRadius * ramp / s, Double(ramp))
    }

    //UIScrollView's rubber band; approaches limit asymptotically.
    private func band(_ x: CGFloat, limit: CGFloat) -> CGFloat {
        let c: CGFloat = 0.55
        return (x * limit * c) / (limit + c * x)
    }

    private func metrics() -> Metrics {
        var m = Metrics()
        m.clip = screenLocal
        guard frame.width > 1, screenLocal.width > 1 else { return m }
        let p = min(max(progress, 0), 1)
        let d = dragMetrics()

        //Shadow and dim track the gesture; a commit raises them quickly (so
        //button dismissals get them too) and fades both with the end dissolve.
        let commitChrome = Double(min(p / 0.12, 1)) * Double(1 - p)
        let chrome = max(d.chrome * Double(1 - p), commitChrome)
        m.shadow = Self.shadowOpacity * chrome
        m.dim = Self.dimMax * chrome

        //A commit from a button tap starts with square corners — raise them to
        //the display radius as fast as the chrome so the card reads native.
        let startRadius = max(d.radius, Self.displayRadius * min(p / 0.12, 1) / d.scale)

        //Committed phase: converge onto the source. The end scale maps the pager
        //image region exactly onto the source rect; the end clip is the source
        //rect carried back into local space, so what remains visible at p = 1 is
        //precisely the pager image standing in the source's frame.
        guard let sourceRect, sourceRect.width > 1, pagerRect.width > 50 else {
            //No measured source (e.g. it left the hierarchy): shrink and dissolve
            //toward the screen center — a zoom, never a slide.
            let s = lerp(d.scale, 0.6, p)
            m.scale = s
            m.offset = CGSize(
                width: lerp(d.offset.width, screenLocal.minX * (1 - s) + screenLocal.width * (1 - s) / 2, p),
                height: lerp(d.offset.height, screenLocal.minY * (1 - s) + screenLocal.height * (1 - s) / 2, p)
            )
            m.radii = uniformRadii(startRadius)
            m.opacity = 1 - Double(p)
            return m
        }

        let pagerLocal = CGRect(
            x: pagerRect.minX - frame.minX,
            y: pagerRect.minY - frame.minY + pagerShift,
            width: pagerRect.width,
            height: pagerRect.height
        )
        let endScale = sourceRect.width / pagerLocal.width
        let endOffset = CGSize(
            width: sourceRect.midX - frame.minX - endScale * pagerLocal.midX,
            height: sourceRect.midY - frame.minY - endScale * pagerLocal.midY
        )
        let endClip = CGRect(
            x: pagerLocal.midX - (sourceRect.width / endScale) / 2,
            y: pagerLocal.midY - (sourceRect.height / endScale) / 2,
            width: sourceRect.width / endScale,
            height: sourceRect.height / endScale
        )
        let endRadii = RectangleCornerRadii(
            topLeading: sourceRadii.topLeading / endScale,
            bottomLeading: sourceRadii.bottomLeading / endScale,
            bottomTrailing: sourceRadii.bottomTrailing / endScale,
            topTrailing: sourceRadii.topTrailing / endScale
        )

        m.scale = lerp(d.scale, endScale, p)
        m.offset = CGSize(width: lerp(d.offset.width, endOffset.width, p),
                          height: lerp(d.offset.height, endOffset.height, p))
        m.clip = lerp(screenLocal, endClip, p)
        m.radii = RectangleCornerRadii(
            topLeading: lerp(startRadius, endRadii.topLeading, p),
            bottomLeading: lerp(startRadius, endRadii.bottomLeading, p),
            bottomTrailing: lerp(startRadius, endRadii.bottomTrailing, p),
            topTrailing: lerp(startRadius, endRadii.topTrailing, p)
        )
        //Frames converge by ~p 0.7; the final stretch cross-dissolves the surface
        //into the real source underneath — like the native zoom's end dissolve.
        m.opacity = p < 0.7 ? 1 : Double(1 - (p - 0.7) / 0.3)
        return m
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    private func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
        CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
               width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
    }

    private func uniformRadii(_ r: CGFloat) -> RectangleCornerRadii {
        RectangleCornerRadii(topLeading: r, bottomLeading: r, bottomTrailing: r, topTrailing: r)
    }
}

//Plain shape: rect and radii arrive already interpolated per frame.
struct ZoomClipShape: Shape {
    let rect: CGRect
    let radii: RectangleCornerRadii

    func path(in bounds: CGRect) -> Path {
        //Geometry not yet measured (first layout frames): don't clip anything.
        guard rect.width > 0, rect.height > 0 else { return Path(bounds) }
        return Path(roundedRect: rect, cornerRadii: radii, style: .continuous)
    }
}

//MARK: - Root overlay presentation

//Presents profile surfaces ABOVE the root TabView, so the real tab bar sits
//behind the profile exactly like a native zoom presentation: covered while the
//profile is open, revealed (and darkened by the surface's own dim layer) as the
//interactive dismissal shrinks the card — no hide/show choreography anywhere.
//Hosts keep owning their state and view construction; they mirror it into these
//slots with .profileView / .responseCover, attaching .environment(morph) since
//the content is evaluated at the root, outside the host's environment.
@MainActor
@Observable
final class ProfileOverlayPresenter {

    struct Slot {
        let id: String
        let view: () -> AnyView
    }

    //The presented profile surface (one app-wide at a time).
    private(set) var profile: Slot?
    //Full-screen response cover — sits above the profile while a respond flow
    //tears the profile down behind it.
    private(set) var cover: Slot?
    //The morph whose open flight is live: the flying image renders at the root
    //so it passes above the tab bar, like the rest of the transition.
    var flightMorph: ProfileMorphState?

    func show(_ slot: ProfileOverlaySlotKind, id: String, view: @escaping () -> AnyView) {
        switch slot {
        case .profile: profile = Slot(id: id, view: view)
        case .cover: cover = Slot(id: id, view: view)
        }
    }

    //Id-guarded so a stale clear from one host can't drop another's content.
    func clear(_ slot: ProfileOverlaySlotKind, id: String) {
        switch slot {
        case .profile: if profile?.id == id { profile = nil }
        case .cover: if cover?.id == id { cover = nil }
        }
    }
}

enum ProfileOverlaySlotKind { case profile, cover }

//Renders the presenter's slots. Place as the TabView's sibling at the app root.
struct ProfileOverlayLayer: View {
    var presenter: ProfileOverlayPresenter

    var body: some View {
        ZStack {
            if let p = presenter.profile { p.view().id(p.id).zIndex(1) }
            if let c = presenter.cover { c.view().id(c.id).zIndex(2) }
            if let m = presenter.flightMorph { ProfileMorphLayer(morph: m).zIndex(3) }
        }
    }
}

//Mirrors a host's presentation state into a root slot: a non-nil presentedID
//shows the content, nil clears it. The content closure captures the host's state
//objects, so it stays live across root re-evaluations. Private routing detail —
//hosts call the .profileView / .responseCover wrappers below, never this directly.
private struct ProfileOverlayModifier<Overlay: View>: ViewModifier {
    @Environment(ProfileOverlayPresenter.self) private var presenter: ProfileOverlayPresenter?
    let slot: ProfileOverlaySlotKind
    let presentedID: String?
    @ViewBuilder let overlay: () -> Overlay

    func body(content: Content) -> some View {
        content
            .onChange(of: presentedID, initial: true) { oldID, newID in
                guard let presenter else { return }
                if let newID {
                    presenter.show(slot, id: newID) { AnyView(overlay()) }
                } else if let oldID {
                    presenter.clear(slot, id: oldID)
                }
            }
            .onDisappear {
                if let presentedID { presenter?.clear(slot, id: presentedID) }
            }
    }
}

extension View {

    //Presents a profile surface at the app root, above the TabView. Pass the id of
    //the profile to show; nil dismisses it. Shares the root presenter with
    //responseCover, which layers above this slot.
    func profileView(presentedID: String?, @ViewBuilder content: @escaping () -> some View) -> some View {
        modifier(ProfileOverlayModifier(slot: .profile, presentedID: presentedID, overlay: content))
    }

    //Presents a full-screen response cover above the profile slot, used while a
    //respond flow tears the profile down behind it. Driven by the response itself:
    //a non-nil response presents (and is handed to the content), nil dismisses —
    //the response's case name is the slot identity.
    func responseCover<Cover: View>(
        presentedID response: ProfileResponse?,
        @ViewBuilder content: @escaping (ProfileResponse) -> Cover
    ) -> some View {
        modifier(ProfileOverlayModifier(
            slot: .cover,
            presentedID: response.map { String(describing: $0) },
            overlay: { response.map(content) }
        ))
    }

    //Injects the morph for this subtree (sources, pager, ProfileView's dismiss all
    //see the same state) and routes the open-flight layer to the root presenter so
    //the flying image renders above the tab bar. Falls back to a local overlay
    //when no presenter is in the environment (previews, isolated hosts).
    func profileMorphHost(_ morph: ProfileMorphState) -> some View {
        modifier(ProfileMorphHostModifier(morph: morph))
    }

    //Apply to the whole profile surface (replaces the old offset-based dismiss
    //drag effect). enabled mirrors the drag gesture's own-profile exclusion.
    func profileZoomDismiss(ui: ProfileUIState, enabled: Bool) -> some View {
        modifier(ProfileZoomDismissModifier(ui: ui, enabled: enabled))
    }
}

struct ProfileMorphHostModifier: ViewModifier {
    @Environment(ProfileOverlayPresenter.self) private var presenter: ProfileOverlayPresenter?
    let morph: ProfileMorphState

    func body(content: Content) -> some View {
        content
            .overlay { if presenter == nil { ProfileMorphLayer(morph: morph) } }
            .environment(morph)
            .onChange(of: morph.isMorphing, initial: true) { _, active in
                guard let presenter else { return }
                if active {
                    presenter.flightMorph = morph
                } else if presenter.flightMorph === morph {
                    presenter.flightMorph = nil
                }
            }
    }
}

extension View {

    func profileMorphSource(id: String, radii: RectangleCornerRadii, visualScale: CGFloat = 1) -> some View {
        modifier(ProfileMorphSourceModifier(id: id, radii: radii, visualScale: visualScale))
    }

    //Uniform-radius convenience; pass size/2 for a circular source.
    func profileMorphSource(id: String, cornerRadius: CGFloat, visualScale: CGFloat = 1) -> some View {
        profileMorphSource(
            id: id,
            radii: RectangleCornerRadii(topLeading: cornerRadius, bottomLeading: cornerRadius, bottomTrailing: cornerRadius, topTrailing: cornerRadius),
            visualScale: visualScale
        )
    }
}
