//
//  InviteMorph.swift
//  Scoop Test
//
//  Created by Art Ostin on 30/05/2026.
//

import SwiftUI

// MARK: - Style

// Per-flow knobs for a quick-invite morph. Pick a preset (and optionally `.tint`);
// the caller never needs the morph internals — just a start anchor (`inviteIconAnchor`)
// and the destination card.
struct QuickInviteMorphStyle {
    // Tint of the collapsed surface (the icon state). Must match the real source icon so
    // the morph folds back onto it seamlessly.
    var tint: Color = .accent
    // Icon→card open spring duration; lets flows tune snappiness.
    var openDuration: Double = 0.35
    // Whether the collapsed surface shows the letter glyph (off for non-icon sources).
    var showsGlyph: Bool = true
    // When the card content brings its own chrome (e.g. a pager), the surface grows into
    // the content's `.morphCardAnchor()` frame then fades out, handing off the background.
    var contentOwnsBackground: Bool = false

    func tinted(_ color: Color) -> Self {
        var copy = self
        copy.tint = color
        return copy
    }

    // Morph surface IS the card; content draws no background of its own.
    static let send = QuickInviteMorphStyle()
    // Content owns its chrome and tags it with `.morphCardAnchor()`; surface hands off.
    static let respond = QuickInviteMorphStyle(openDuration: 0.28, contentOwnsBackground: true)
    // Bare rounded surface morphing from a non-icon source (no letter glyph).
    static let plainCard = QuickInviteMorphStyle(showsGlyph: false)
}

// MARK: - Presenter

struct QuickInviteMorphPresenter<Card: View, Overlay: View>: ViewModifier {
    @Binding var iconId: String?
    @Binding var morphInviteId: String?
    // Hides the morph card while a sibling confirm alert is up, so only the alert shows.
    let hideCard: Bool
    // Floats a "Hide" dismiss control below the card (send flows only).
    let showsHideButton: Bool
    let style: QuickInviteMorphStyle
    @ViewBuilder let card: (String) -> Card
    // Full-screen sibling of the card (e.g. a confirm alert) so its dim covers the screen
    // rather than being clamped to the card frame.
    @ViewBuilder let overlay: () -> Overlay

    // Tapped icon frame in GLOBAL coords, so the morph (in a full-screen cover above the
    // tab bar) starts exactly on the source button.
    @State private var iconRect: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .overlayPreferenceValue(InviteIconBoundsKey.self) { anchors in
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: iconId) { _, new in
                            handleChange(new, anchors: anchors, proxy: proxy)
                        }
                }
            }
            .fullScreenCover(isPresented: morphPresented) {
                GeometryReader { geo in
                    if let id = morphInviteId {
                        QuickInviteMorph(
                            iconRect: iconRect,
                            isPresented: iconId != nil,
                            containerSize: geo.size,
                            hideCard: hideCard,
                            style: style,
                            onCollapsed: { if iconId == nil { withoutCoverAnimation { morphInviteId = nil } } },
                            showsHideButton: showsHideButton,
                            onHide: { iconId = nil },
                            card: { card(id) },
                            overlay: overlay
                        )
                    }
                }
                .ignoresSafeArea()
                .presentationBackground(.clear)
            }
    }

    private var morphPresented: Binding<Bool> {
        Binding(get: { morphInviteId != nil },
                set: { if !$0 { morphInviteId = nil } })
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
        withoutCoverAnimation { morphInviteId = new }
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
    // Once the open settles, fade the surface so content with its own chrome owns the look.
    @State private var surfaceHandedOff = false
    // Measured height of the real card; the generic window matches it so nothing clips.
    @State private var cardHeight: CGFloat = 360
    // Destination frame (morph space) published by content via `.morphCardAnchor()`, so the
    // entrance lands exactly on the real card. Used when the content owns its background.
    @State private var measuredCardRect: CGRect? = nil

    private let sideMargin: CGFloat = 30
    private var cardWidth: CGFloat { containerSize.width - sideMargin * 2 }

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
        ZStack {
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
            // doesn't drift as pages scroll.
            if measuredCardRect == nil, let rect, rect.height > 1 { measuredCardRect = rect }
        }
        .onAppear { DispatchQueue.main.async { withAnimation(openAnimation) { expanded = true } } }
        .onChange(of: isPresented) { _, presented in
            if presented {
                withAnimation(openAnimation) { expanded = true }
            } else {
                // Drive the collapse so its completion fires exactly when the surface lands.
                withAnimation(closeAnimation) { expanded = false } completion: { onCollapsed() }
            }
        }
        .onChange(of: expanded) { _, isExpanded in
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
            style.tint.opacity(expanded ? 0 : 1)
        }
        .frame(width: windowRect.width, height: windowRect.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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
        .shadow(color: style.tint.opacity(0.15), radius: 4, y: 2)
        .shadow(color: .white.opacity(0.2), radius: 7, x: 0, y: 5)
        .position(x: windowRect.midX, y: windowRect.midY)
        .opacity(surfaceHandedOff ? 0 : 1)
        // Open: hold through the entrance, then fade. Close: reappear instantly (nil
        // animation) so the surface is opaque the moment content vanishes, avoiding a gap.
        .animation(expanded ? .easeInOut(duration: 0.15).delay(handoffDelay) : nil, value: surfaceHandedOff)
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
                    .background(heightReader)
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
            .opacity(expanded && !hideCard ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: expanded)
            .allowsHitTesting(expanded && !hideCard)
    }

    private var heightReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { cardHeight = proxy.size.height }
                .onChange(of: proxy.size.height) { _, h in cardHeight = h }
        }
    }
}

// Full-screen confirm alert for the morph send flow. Used as a `quickInviteMorph` overlay
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
}

extension View {
    /// Morphs `card` out of the invite icon matching the driving id. Set `iconId` to the
    /// tapped source's id to present, nil to collapse back onto the icon. `morphInviteId` is
    /// the cover-mount state, owned by the caller so it can hide the real icon while the
    /// morph is live — it outlasts `iconId` through the collapse.
    func quickInviteMorph<Card: View, Overlay: View>(
        iconId: Binding<String?>,
        morphInviteId: Binding<String?>,
        hideCard: Bool = false,
        showsHideButton: Bool = false,
        style: QuickInviteMorphStyle = .send,
        @ViewBuilder card: @escaping (String) -> Card,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) -> some View {
        modifier(QuickInviteMorphPresenter(iconId: iconId, morphInviteId: morphInviteId, hideCard: hideCard, showsHideButton: showsHideButton, style: style, card: card, overlay: overlay))
    }
}
