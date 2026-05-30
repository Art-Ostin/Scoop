//
//  InviteMorph.swift
//  Scoop Test
//
//  Created by Art Ostin on 30/05/2026.
//

import SwiftUI

//AI Code for morphing into quick Invite
struct QuickInviteMorphPresenter<Card: View, Overlay: View>: ViewModifier {
    @Binding var iconId: String?
    @Binding var morphInviteId: String?
    // Hides the morph card (surface + content) while a sibling confirm alert is up,
    // so only the full-screen alert remains visible.
    let hideCard: Bool
    // When the card content carries its own card chrome (e.g. a multi-page pager),
    // the morph surface hands off — it fades out once expanded so it doesn't sit as a
    // ghost behind the content during interaction, then fades back in for the collapse.
    let contentOwnsBackground: Bool
    // Tint of the collapsed surface (the icon state). Must match the real source icon so
    // the morph folds back onto it seamlessly (e.g. green for respond, accent for send).
    let iconTint: Color
    @ViewBuilder let card: (String) -> Card
    // Full-screen sibling of the morph card (e.g. a confirmation alert) that must NOT
    // be clamped to the card's frame, so its dim can cover the whole screen.
    @ViewBuilder let overlay: () -> Overlay

    // Icon frame in GLOBAL coordinates, so the morph (presented in a full-screen cover
    // above the tab bar) starts exactly on the tapped invite button.
    @State private var iconRect: CGRect = .zero

    func body(content: Content) -> some View {
        content
            // Measure the tapped icon's global frame when a quick invite begins.
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
                            contentOwnsBackground: contentOwnsBackground,
                            iconTint: iconTint,
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

    // Presents/dismisses the morph cover WITHOUT the system's slide animation, so the
    // only motion is the morph itself. On present we also capture the icon's global
    // frame; on dismiss we keep the cover mounted briefly so the collapse can play.
    private func handleChange(_ new: String?, anchors: [String: Anchor<CGRect>], proxy: GeometryProxy) {
        if let new, let anchor = anchors[new] {
            let local = proxy[anchor]
            let origin = proxy.frame(in: .global).origin
            iconRect = CGRect(x: local.minX + origin.x, y: local.minY + origin.y,
                              width: local.width, height: local.height)
            withoutCoverAnimation { morphInviteId = new }
        } else {
            Task {
                // Outlast the spring collapse so the cover stays mounted until the
                // morph has fully folded back onto the icon.
                try? await Task.sleep(for: .milliseconds(420))
                if iconId == nil { withoutCoverAnimation { morphInviteId = nil } }
            }
        }
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
    let contentOwnsBackground: Bool
    let iconTint: Color
    @ViewBuilder var card: () -> Card
    @ViewBuilder var overlay: () -> Overlay

    // Drives the entrance/exit animation independently of mount, so the window can
    // start collapsed on the icon and then animate open.
    @State private var expanded = false
    // Hand-off flag: once the open settles, the surface fades out so content with its
    // own chrome owns the card look. Reset before any collapse so the surface is there
    // to fold back onto the icon.
    @State private var surfaceHandedOff = false
    // Measured height of the real card; the window matches it so nothing clips.
    @State private var cardHeight: CGFloat = 360
    // For `contentOwnsBackground`, the actual frame (in morph space) of the real card the
    // surface should morph into, so the entrance lands exactly on it rather than a
    // generic window. Published by the content via `.morphCardAnchor()`.
    @State private var measuredCardRect: CGRect? = nil

    private let sideMargin: CGFloat = 30
    private var cardWidth: CGFloat { containerSize.width - sideMargin * 2 }

    // Vertical lift of the settled morph card (surface + content) from dead-center.
    // The morph still starts on the icon, so only the destination shifts.
    private let verticalOffset: CGFloat = 12

    private var expandedRect: CGRect {
        if contentOwnsBackground, let measuredCardRect { return measuredCardRect }
        return CGRect(x: (containerSize.width - cardWidth) / 2,
                      y: (containerSize.height - cardHeight) / 2 + verticalOffset,
                      width: cardWidth, height: cardHeight)
    }

    private var windowRect: CGRect { expanded ? expandedRect : iconRect }
    private var cornerRadius: CGFloat { expanded ? 30 : iconRect.height / 2 }

    // One spring drives every animated property (frame, corner, fills, content
    // opacity) so the whole morph interpolates together like a `.contentTransition`,
    // rather than a snap followed by a staggered fade. The slight bounce gives the
    // iOS 26 "gel" settle. Close uses the same spring feel, slightly faster with less
    // bounce so the collapse stays crisp.
    private let openAnimation: Animation = .spring(duration: 0.35, bounce: 0.2)
    private let closeAnimation: Animation = .spring(duration: 0.28, bounce: 0.12)
    private var morphAnimation: Animation { expanded ? openAnimation : closeAnimation }

    var body: some View {
        ZStack {
            backdrop
            Group {
                surface
                cardContent
            }
            .opacity(hideCard ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: hideCard)
            overlay()
        }
        .coordinateSpace(name: morphCoordinateSpace)
        .onPreferenceChange(MorphCardFrameKey.self) { rect in
            // Capture the first valid frame (the centered card, laid out before the
            // entrance plays) and freeze it, so the surface lands on the real card size
            // instead of the generic fallback window — and doesn't drift as pages scroll.
            if measuredCardRect == nil, let rect, rect.height > 1 { measuredCardRect = rect }
        }
        .onAppear { DispatchQueue.main.async { expanded = true } }
        .onChange(of: isPresented) { _, presented in
            if !presented { expanded = false }
        }
        .onChange(of: expanded) { _, isExpanded in
            // Hand the card surface off to content that brings its own chrome. Set
            // synchronously; the delayed animation keeps the surface up through the
            // entrance, then fades it. On close it returns instantly to collapse.
            if contentOwnsBackground { surfaceHandedOff = isExpanded }
        }
        .animation(morphAnimation, value: expanded)
        .animation(morphAnimation, value: cardHeight)
    }

    private var backdrop: some View {
        Rectangle()
            .fill(.thinMaterial)
            .ignoresSafeArea()
            .opacity(expanded ? 1 : 0)
            .allowsHitTesting(expanded) //blocks taps to content behind; dismiss is Hide-only
    }

    // The single morphing surface: the accent circle relaxes into the appCanvas card
    // background (frame + corner radius animate, accent tint fades out). No content
    // here — this is purely the card's surface travelling from the icon.
    private var surface: some View {
        ZStack {
            Color.appCanvas
            iconTint.opacity(expanded ? 0 : 1)
        }
        .frame(width: windowRect.width, height: windowRect.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            // Card hairline stroke, faded in once open.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
                .opacity(expanded ? 1 : 0)
        }
        .overlay {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24)
                .foregroundStyle(.white)
                .opacity(expanded ? 0 : 1)
        }
        .shadow(color: iconTint.opacity(0.15), radius: 4, y: 2)
        .shadow(color: .white.opacity(0.2), radius: 7, x: 0, y: 5)
        .position(x: windowRect.midX, y: windowRect.midY)
        .opacity(surfaceHandedOff ? 0 : 1)
        // Keyed on surfaceHandedOff (not expanded) so it doesn't disturb the frame morph.
        // Open: hold through the entrance, then fade. Close: reappear instantly.
        .animation(.easeInOut(duration: 0.15).delay(expanded ? 0.30 : 0), value: surfaceHandedOff)
        .allowsHitTesting(false)
    }

    // The real card content. Opacity is staged off the shared morph curve: it fades in
    // only AFTER the surface has grown behind it, and fades out FAST on close so it's
    // gone before the surface collapses away — otherwise content floats with no
    // background behind it.
    @ViewBuilder private var cardContent: some View {
        if contentOwnsBackground {
            // Content owns its chrome and may span the full screen (e.g. a full-width
            // pager). Fill the container; the surface (faded off after entrance) only
            // handles the icon→card growth.
            card()
                .frame(width: containerSize.width, height: containerSize.height)
                .opacity(expanded ? 1 : 0)
                .animation(expanded ? .easeIn(duration: 0.16).delay(0.14)
                                     : .easeOut(duration: 0.10), value: expanded)
                .allowsHitTesting(expanded)
        } else {
            // No background of its own — pinned at the card's FINAL frame the whole time,
            // with the surface acting as its permanent background.
            card()
                .frame(width: cardWidth)
                .fixedSize(horizontal: false, vertical: true)
                .background(heightReader)
                .opacity(expanded ? 1 : 0)
                .animation(expanded ? .easeIn(duration: 0.14).delay(0.16)
                                     : nil, value: expanded)
                .position(x: expandedRect.midX, y: expandedRect.midY)
                .allowsHitTesting(expanded)
        }
    }

    private var heightReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { cardHeight = proxy.size.height }
                .onChange(of: proxy.size.height) { _, h in cardHeight = h }
        }
    }
}

// Full-screen confirm alert for the morph send flow. Used as a `quickInviteMorph`
// overlay so it sits as a sibling of the (frame-clamped) card — its dim covers the
// whole screen. Holds the pending send action; pass-through while idle.
struct MorphConfirmAlert: View {
    @Binding var pending: (() -> Void)?

    var body: some View {
        Color.clear
            .respondCustomAlert(isPresented: $pending.isPresent(), type: .newInvite, hideAnimation: .easeInOut(duration: 0.09)) { pending?() }
            .allowsHitTesting(pending != nil)
    }
}

struct InviteIconBoundsKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

let morphCoordinateSpace = "QuickInviteMorph.space"

// Frame (in QuickInviteMorph's coordinate space) of the real card the morph surface
// should grow into when the content owns its own background.
struct MorphCardFrameKey: PreferenceKey {
    static var defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

extension View {
    /// Tags this view as the card the morph surface should land on (the morph entrance
    /// grows into exactly this frame, then hands the background off to the content).
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
}

extension View {
    /// Tags this view as the morph source for `id`'s invite icon.
    func inviteIconAnchor(id: String) -> some View {
        anchorPreference(key: InviteIconBoundsKey.self, value: .bounds) { [id: $0] }
    }
}


extension View {
    /// Morphs `card` out of the invite icon whose `InviteIconBoundsKey` matches the
    /// driving id. Drive `iconId` with the tapped invite source's id to present, and
    /// set it to nil to collapse the morph back onto the icon. `morphInviteId` is the
    /// cover-mount state, owned by the caller so it can hide the real icon (avoiding a
    /// duplicate) while the morph is live — it outlasts `iconId` through the collapse.
    func quickInviteMorph<Card: View, Overlay: View>(
        iconId: Binding<String?>,
        morphInviteId: Binding<String?>,
        hideCard: Bool = false,
        contentOwnsBackground: Bool = false,
        iconTint: Color = .accent,
        @ViewBuilder card: @escaping (String) -> Card,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) -> some View {
        modifier(QuickInviteMorphPresenter(iconId: iconId, morphInviteId: morphInviteId, hideCard: hideCard, contentOwnsBackground: contentOwnsBackground, iconTint: iconTint, card: card, overlay: overlay))
    }
}
