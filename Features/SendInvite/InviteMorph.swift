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
    @ViewBuilder var card: () -> Card
    @ViewBuilder var overlay: () -> Overlay

    // Drives the entrance/exit animation independently of mount, so the window can
    // start collapsed on the icon and then animate open.
    @State private var expanded = false
    // Measured height of the real card; the window matches it so nothing clips.
    @State private var cardHeight: CGFloat = 360

    private let sideMargin: CGFloat = 30
    private var cardWidth: CGFloat { containerSize.width - sideMargin * 2 }

    // Vertical lift of the settled morph card (surface + content) from dead-center.
    // The morph still starts on the icon, so only the destination shifts.
    private let verticalOffset: CGFloat = 12

    private var expandedRect: CGRect {
        CGRect(x: (containerSize.width - cardWidth) / 2,
               y: (containerSize.height - cardHeight) / 2 + verticalOffset,
               width: cardWidth, height: cardHeight)
    }

    private var windowRect: CGRect { expanded ? expandedRect : iconRect }
    private var cornerRadius: CGFloat { expanded ? 30 : iconRect.height / 2 }

    // One spring drives every animated property (frame, corner, fills, content
    // opacity) so the whole morph interpolates together like a `.contentTransition`,
    // rather than a snap followed by a staggered fade. The slight bounce gives the
    // iOS 26 "gel" settle on open. Close uses easeOut so the surface shrinks on frame
    // one (no slow spring onset), matching the instant content removal.
    private let openAnimation: Animation = .spring(duration: 0.35, bounce: 0.2)
    private let closeAnimation: Animation = .easeOut(duration: 0.26)
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
        .onAppear { DispatchQueue.main.async { expanded = true } }
        .onChange(of: isPresented) { _, presented in
            if !presented { expanded = false }
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
            Color.accent.opacity(expanded ? 0 : 1)
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
        .shadow(color: .accent.opacity(0.15), radius: 4, y: 2)
        .shadow(color: .white.opacity(0.2), radius: 7, x: 0, y: 5)
        .position(x: windowRect.midX, y: windowRect.midY)
        .allowsHitTesting(false)
    }

    // The real card content (no background of its own), pinned at the card's FINAL
    // frame the whole time. Opacity is staged off the shared morph curve: it fades in
    // only AFTER the surface has grown behind it, and fades out FAST on close so it's
    // gone before the surface collapses away — otherwise content floats with no
    // background behind it.
    private var cardContent: some View {
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
        @ViewBuilder card: @escaping (String) -> Card,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) -> some View {
        modifier(QuickInviteMorphPresenter(iconId: iconId, morphInviteId: morphInviteId, hideCard: hideCard, card: card, overlay: overlay))
    }
}
