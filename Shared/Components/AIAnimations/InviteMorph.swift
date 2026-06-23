//
//  InviteMorph.swift
//  Scoop Test
//
//  Created by Art Ostin on 30/05/2026.
//

import SwiftUI

// Monotonic ms timestamp for morph timing diagnostics. Remove with the [MORPH] prints.
func morphT() -> String {
    String(format: "%.1fms", Date().timeIntervalSinceReferenceDate * 1000)
}

// MARK: - Style

// Per-flow knobs for a quick-invite morph. Pick a preset (and optionally `.tint`);
// the caller never needs the morph internals — just a start anchor (`inviteIconAnchor`)
// and the destination card.
struct QuickInviteMorphStyle {
    // Tint of the collapsed surface (the icon state). Must match the real source icon so
    // the morph folds back onto it seamlessly.
    var tint: Color = .accent
    // Icon→card open spring duration; lets flows tune snappiness.
    var openDuration: Double = 0.28
    // Whether the collapsed surface shows the letter glyph (off for non-icon sources).
    var showsGlyph: Bool = true
    // When the card content brings its own chrome (e.g. a pager), the surface grows into
    // the content's `.morphCardAnchor()` frame then fades out, handing off the background.
    var contentOwnsBackground: Bool = false
    // Entrance-fallback gap from each screen edge to the settled card. Used only for the first
    // open frame, before the content publishes its real frame via `.morphCardAnchor()`.
    // Content-owns-background styles size themselves, so the live margin lives on the card
    // (e.g. SendInviteContainer.cardMargin, RespondContainer.screenMargin).
    var sideMargin: CGFloat = 30

    // Floats a "Hide" dismiss control below the card. Send/quick-invite flows show it; the
    // respond pager dismisses by responding, so it leaves this off.
    var showsHideButton: Bool = false

    // Mount as a plain SwiftUI overlay instead of a fullScreenCover. Hosts that already cover
    // the tab bar (e.g. ProfileView) opt in via `.presentedAsOverlay()` to skip the cover-
    // presentation latency that makes the morph pop in collapsed before opening.
    var presentsAsOverlay: Bool = false

    func tinted(_ color: Color) -> Self {
        var copy = self
        copy.tint = color
        return copy
    }

    func sideMargin(_ margin: CGFloat) -> Self {
        var copy = self
        copy.sideMargin = margin
        return copy
    }

    func presentedAsOverlay() -> Self {
        var copy = self
        copy.presentsAsOverlay = true
        return copy
    }

    // Send card owns its chrome (`inviteCardBackground` + `.morphCardAnchor()`); the surface
    // grows into it then hands off, so the card owns its width/margin (adaptive — see
    // SendInviteContainer.cardMargin). Shows the Hide control.
    static let send = QuickInviteMorphStyle(contentOwnsBackground: true, showsHideButton: true)
    // Content owns its chrome and tags it with `.morphCardAnchor()`; surface hands off. The
    // pager dismisses by responding, so no Hide control.
    static let respond = QuickInviteMorphStyle(openDuration: 0.28, contentOwnsBackground: true)
    // Bare rounded surface from a non-icon source (no letter glyph); send card owns its
    // background, same as `.send`.
    static let plainCard = QuickInviteMorphStyle(showsGlyph: false, contentOwnsBackground: true, showsHideButton: true)
}

// MARK: - Presenter

struct QuickInviteMorphPresenter<Card: View, Overlay: View>: ViewModifier {
    @Binding var openPopupId: String?
    // Hides the morph card while a sibling confirm alert is up, so only the alert shows.
    let hideCard: Bool
    // Per-flow knobs: Hide control, overlay-vs-cover presentation, tint, margins…
    let style: QuickInviteMorphStyle
    @ViewBuilder let card: (String) -> Card
    // Full-screen sibling of the card (e.g. a confirm alert) so its dim covers the screen
    // rather than being clamped to the card frame.
    @ViewBuilder let overlay: () -> Overlay

    // Tapped icon frame in GLOBAL coords, so the morph (in a full-screen cover above the
    // tab bar) starts exactly on the source button.
    @State private var iconRect: CGRect = .zero

    // Which source id is morphing (mount → end of collapse). Injected into `content` so a
    // matching `.morphSource(id:)` hides itself while its copy is flying. Internal now —
    // callers no longer thread a mount-id binding.
    @State private var morphState = QuickInviteMorphState()

    @ViewBuilder
    func body(content: Content) -> some View {
        let anchored = content
            .environment(morphState)
            .overlayPreferenceValue(InviteIconBoundsKey.self) { anchors in
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: openPopupId) { _, new in
                            handleChange(new, anchors: anchors, proxy: proxy)
                        }
                }
            }
        if style.presentsAsOverlay {
            // Renders in the same pass as the tap: the surface is on screen collapsed
            // immediately and the open spring fires the next frame — no cover present step.
            anchored.overlay { if morphState.activeId != nil { morphLayer } }
        } else {
            // Cover: needed when the host still shows the tab bar, so the morph floats above it.
            anchored.fullScreenCover(isPresented: morphPresented) {
                morphLayer.presentationBackground(.clear)
            }
        }
    }

    @ViewBuilder private var morphLayer: some View {
        GeometryReader { geo in
            let _ = print("[MORPH] \(morphT()) morphLayer geo.size=\(geo.size)")
            if let id = morphState.activeId {
                QuickInviteMorph(
                    iconRect: iconRect,
                    isPresented: openPopupId != nil,
                    containerSize: geo.size,
                    hideCard: hideCard,
                    style: style,
                    onCollapsed: { if openPopupId == nil { withoutCoverAnimation { morphState.activeId = nil } } },
                    showsHideButton: style.showsHideButton,
                    onHide: { openPopupId = nil },
                    card: { card(id) },
                    overlay: overlay
                )
            }
        }
        .ignoresSafeArea()
    }

    private var morphPresented: Binding<Bool> {
        Binding(get: { morphState.activeId != nil },
                set: { if !$0 { morphState.activeId = nil } })
    }

    // Present only: capture the icon's global frame and mount the cover WITHOUT the
    // system slide, so the morph is the only motion. Collapse/unmount is driven by
    // QuickInviteMorph's onCollapsed.
    private func handleChange(_ new: String?, anchors: [String: Anchor<CGRect>], proxy: GeometryProxy) {
        guard let new, let anchor = anchors[new] else { return }
        let local = proxy[anchor]
        let origin = proxy.frame(in: .global).origin
        iconRect = CGRect(x: local.minX + origin.x, y: local.minY + origin.y,
                          width: local.width, height: local.height)
        print("[MORPH] \(morphT()) handleChange → set activeId=\(new) iconRect=\(iconRect)")
        withoutCoverAnimation { morphState.activeId = new }
    }

    private func withoutCoverAnimation(_ body: () -> Void) {
        var txn = Transaction()
        txn.disablesAnimations = true
        withTransaction(txn, body)
    }
}

// MARK: - Quick invite morph

struct QuickInviteMorph<Card: View, Overlay: View>: View {

    let iconRect: CGRect
    let isPresented: Bool
    let containerSize: CGSize
    let hideCard: Bool
    let style: QuickInviteMorphStyle
    // Fired the instant the collapse lands, so the caller unmounts the cover exactly as
    // the surface folds back onto the icon.
    let onCollapsed: () -> Void
    // A "Hide" dismiss control floating just below the card. Lives in this full-screen layer
    // (not the card's overlay) so its tap region isn't clamped to the card's fixed frame.
    let showsHideButton: Bool
    let onHide: () -> Void
    @ViewBuilder var card: () -> Card
    @ViewBuilder var overlay: () -> Overlay

    // Drives entrance/exit independently of mount, so the window starts on the icon.
    @State private var expanded = false
    // Lifecycle latch: false while mounted-but-not-yet-opened, flipped true the first time
    // the open commits and kept true through the collapse. Gates the surface so the collapsed
    // icon isn't shown during the pre-open idle frames. The cover path gets this grace period
    // for free (its surface isn't on screen until presented); the overlay path is laid out
    // immediately, so without this the static icon flashes for the frames before the spring
    // fires. Latched off `expanded` (not the open trigger) so it can't reveal on the
    // animation's "from" frame, where the window is still sitting on the icon.
    @State private var revealed = false
    // Once the open settles, fade the surface so content with its own chrome owns the look.
    @State private var surfaceHandedOff = false
    // Measured height of the real card; the generic window matches it so nothing clips.
    @State private var cardHeight: CGFloat = 360
    // Destination frame (morph space) published by content via `.morphCardAnchor()`, so the
    // entrance lands exactly on the real card. Used when the content owns its background.
    @State private var measuredCardRect: CGRect? = nil
    // True while the card has an inner popup open (time/place pickers); hides the floating
    // Hide control so it doesn't sit under the popup. Published up via MorphPopupOpenKey.
    @State private var popupOpen = false

    private var sideMargin: CGFloat { style.sideMargin }
    private var cardWidth: CGFloat { max(0, containerSize.width - sideMargin * 2) }

    // Vertical lift of the settled card from dead-center. The morph still starts on the icon.
    private let verticalOffset: CGFloat = 12

    private var expandedRect: CGRect {
        if style.contentOwnsBackground, let measuredCardRect { return measuredCardRect }
        return CGRect(x: (containerSize.width - cardWidth) / 2,
                      y: (containerSize.height - cardHeight) / 2 + verticalOffset,
                      width: cardWidth, height: cardHeight)
    }

    private var windowRect: CGRect { expanded ? expandedRect : iconRect }
    private var cornerRadius: CGFloat { expanded ? 30 : iconRect.height / 2 }

    // One spring drives every animated property (frame, corner, fills, opacity) so the
    // morph interpolates together like a `.contentTransition`. The bounce gives the
    // iOS 26 "gel" settle. Close is faster with less bounce so the collapse stays crisp.
    private var openAnimation: Animation { .spring(duration: style.openDuration, bounce: 0.2) }
    private let closeAnimation: Animation = .spring(duration: 0.28, bounce: 0.12)
    private var morphAnimation: Animation { expanded ? openAnimation : closeAnimation }

    // Surface hold + content fade-in are staged as fractions of the open duration so they
    // keep their feel when a flow speeds the open up (tuned at the 0.35 baseline).
    private var handoffDelay: Double { style.openDuration * (0.30 / 0.35) }
    private var contentFadeDelay: Double { style.openDuration * (0.16 / 0.35) }

    var body: some View {
        let _ = print("[MORPH] \(morphT()) render expanded=\(expanded) surfaceHandedOff=\(surfaceHandedOff) windowRect=\(windowRect)")
        return ZStack {
            backdrop
            Group {
                surface
                cardContent
            }
            .opacity(hideCard ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: hideCard)
            if showsHideButton { hideButton }
            overlay()
        }
        .coordinateSpace(name: morphCoordinateSpace)
        .onPreferenceChange(MorphCardFrameKey.self) { rect in
            // Freeze the first valid frame so the surface lands on the real card size and
            // doesn't drift as pages scroll. Animate the arrival so the in-flight open
            // spring redirects smoothly toward the real card instead of hard-snapping.
            guard measuredCardRect == nil, let rect, rect.height > 1 else { return }
            withAnimation(openAnimation) { measuredCardRect = rect }
        }
        .onPreferenceChange(MorphPopupOpenKey.self) { popupOpen = $0 }
        .onAppear {
            print("[MORPH] \(morphT()) QuickInviteMorph.onAppear (expanded=\(expanded)) → set expanded=true")
            withAnimation(openAnimation) { expanded = true }
        }
        .onChange(of: isPresented) { _, presented in
            if presented {
                withAnimation(openAnimation) { expanded = true }
            } else {
                // Drive the collapse so its completion fires exactly when the surface lands.
                withAnimation(closeAnimation) { expanded = false } completion: { onCollapsed() }
            }
        }
        .onChange(of: expanded) { _, isExpanded in
            print("[MORPH] \(morphT()) expanded → \(isExpanded)")
            // Reveal on the first commit of the open and stay revealed through the collapse,
            // so the surface still folds back onto the icon on the way out.
            if isExpanded { revealed = true }
            if style.contentOwnsBackground { surfaceHandedOff = isExpanded }
        }
        .animation(morphAnimation, value: cardHeight)
    }

    private var backdrop: some View {
        Rectangle()
            .fill(.thinMaterial)
            .ignoresSafeArea()
            .opacity(expanded ? 1 : 0)
            .allowsHitTesting(expanded) // dismiss is Hide-only
    }

    // The single morphing surface: the accent circle relaxes into the appCanvas card
    // (frame + corner animate, tint fades). No content here — purely the card's surface
    // travelling from the icon.
    private var surface: some View {
        ZStack {
            Color.appCanvas
        }
        .frame(width: windowRect.width, height: windowRect.height)
        .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
                .opacity(expanded ? 1 : 0)
        }
        .overlay {
            if style.showsGlyph {
                Image("LetterIconProfile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24)
                    .foregroundStyle(.white)
                    .opacity(expanded ? 0 : 1)
            }
        }
//        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
//        .shadow(color: .white.opacity(0.2), radius: 7, x: 0, y: 5)
        .position(x: windowRect.midX, y: windowRect.midY)
        .opacity(surfaceHandedOff ? 0 : 1)
        // Open: hold through the entrance, then fade. Close: reappear instantly (nil
        // animation) so the surface is opaque the moment content vanishes, avoiding a gap.
        .animation(expanded ? .easeInOut(duration: 0.15).delay(handoffDelay) : nil, value: surfaceHandedOff)
        // Grace-period gate (snaps, no animation), chained separately so it multiplies with
        // the handoff fade above instead of fighting it. Hidden until the open commits.
        .opacity(revealed ? 1 : 0)
        .allowsHitTesting(false)
    }

    // The real card content. Fades in only after the surface has grown behind it, and out
    // fast on close so it's gone before the surface collapses.
    @ViewBuilder private var cardContent: some View {
        Group {
            if style.contentOwnsBackground {
                // Owns its chrome; may span the full screen. Surface only handles the growth.
                card()
                    .frame(width: containerSize.width, height: containerSize.height)
            } else {
                // No background of its own — pinned at the card's final frame, with the
                // surface acting as its permanent background.
                card()
                    .frame(width: cardWidth)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { cardHeight = $0 }
                    .position(x: expandedRect.midX, y: expandedRect.midY)
            }
        }
        .opacity(expanded ? 1 : 0)
        .animation(expanded ? .easeIn(duration: 0.14).delay(contentFadeDelay) : nil, value: expanded)
        .allowsHitTesting(expanded)
    }

    // Pinned to the real card frame so it floats just below the card at any height, with a
    // tap region that lives in the full-screen layer rather than the card's clamped frame.
    private var hideButton: some View {
        HidePopup(onHide: onHide)
            .position(x: expandedRect.midX, y: expandedRect.maxY + 90)
            .opacity(expanded && !hideCard && !popupOpen ? 1 : 0)
            .animation(.easeInOut(duration: 0.05), value: expanded)
            .animation(.smooth(duration: 0.2), value: popupOpen)
            .allowsHitTesting(expanded && !hideCard && !popupOpen)
    }

}

// Full-screen confirm alert for the morph send flow. Used as a `quickInvite` overlay
// so its dim covers the whole screen. Pass-through while idle.
struct MorphConfirmAlert: View {
    @Binding var pending: (() -> Void)?

    var body: some View {
        Color.clear
            .respondCustomAlert(isPresented: $pending.isPresent(), type: .newInvite, hideAnimation: .easeInOut(duration: 0.09)) { pending?() }
            .allowsHitTesting(pending != nil)
    }
}

// MARK: - Anchors

struct InviteIconBoundsKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

let morphCoordinateSpace = "QuickInviteMorph.space"

struct MorphCardFrameKey: PreferenceKey {
    static var defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

// Published by the card when an inner popup (time/place pickers) is open, so the morph can
// hide the floating Hide control while the popup is showing.
struct MorphPopupOpenKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    /// END destination: tags this view as the card the morph surface grows into (used when
    /// the content owns its background, e.g. `.respond`).
    func morphCardAnchor() -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: MorphCardFrameKey.self,
                    value: proxy.frame(in: .named(morphCoordinateSpace))
                )
            }
        )
    }

    /// START destination: tags this view as the morph source for `id`'s invite icon.
    func inviteIconAnchor(id: String) -> some View {
        anchorPreference(key: InviteIconBoundsKey.self, value: .bounds) { [id: $0] }
    }

    /// Publishes "a popup is open inside me" up to the morph, so it can hide the floating
    /// Hide control while the popup is showing.
    func morphPopupOpen(_ isOpen: Bool) -> some View {
        preference(key: MorphPopupOpenKey.self, value: isOpen)
    }

    /// Marks this view as a morph source for `id`: publishes its frame as the morph's
    /// start/end anchor, and hides it while that id is morphing so only the flying surface
    /// shows. Reads the `QuickInviteMorphState` the presenter injects into its content.
    func morphSource(id: String) -> some View {
        modifier(MorphSourceModifier(id: id))
    }
}

// MARK: - Source coordination

/// Which source id is currently morphing — non-nil from the moment the morph mounts through
/// the end of the collapse. Owned by the presenter and injected into its content; a matching
/// `.morphSource(id:)` hides itself while it's set.
@Observable
final class QuickInviteMorphState {
    var activeId: String?
}

private struct MorphSourceModifier: ViewModifier {
    @Environment(QuickInviteMorphState.self) private var morphState: QuickInviteMorphState?
    let id: String

    func body(content: Content) -> some View {
        content
            .opacity(morphState?.activeId == id ? 0 : 1)
            .inviteIconAnchor(id: id)
    }
}

extension View {
    /// Morphs `card` out of the `.morphSource(id:)` whose id matches `openPopupId`. Set
    /// `openPopupId` to the tapped source's id to present, nil to collapse back onto it. The
    /// mount/hide id is tracked internally (a `QuickInviteMorphState` injected into the content)
    /// and outlasts `openPopupId` through the collapse, so the matching source stays hidden
    /// until the surface lands.
    func quickInvite<Card: View, Overlay: View>(
        openPopupId: Binding<String?>,
        hideCard: Bool = false,
        style: QuickInviteMorphStyle = .send,
        @ViewBuilder card: @escaping (String) -> Card,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) -> some View {
        modifier(QuickInviteMorphPresenter(openPopupId: openPopupId, hideCard: hideCard, style: style, card: card, overlay: overlay))
    }
}
