//
//  InviteMorph.swift
//  Scoop
//
//  Created by Art Ostin on 30/05/2026.
//

import SwiftUI

// Diagnostic timestamp; delete with the [MORPH] prints.
func morphT() -> String {
    String(format: "%.1fms", Date().timeIntervalSinceReferenceDate * 1000)
}

// MARK: - Style

// Per-flow knobs for a quick-invite morph; caller supplies a start anchor + destination card.
struct QuickInviteMorphStyle {
    // Collapsed-surface tint; must match the source icon so the morph folds back seamlessly.
    var tint: Color = .accent
    var openDuration: Double = 0.28
    // Show the letter glyph on the collapsed surface (off for non-icon sources).
    var showsGlyph: Bool = true
    // Content brings its own chrome; surface grows into its `.morphCardAnchor()` frame then fades.
    var contentOwnsBackground: Bool = false
    // Entrance-fallback edge gap for the first open frame, before content publishes its real frame.
    var sideMargin: CGFloat = 30

    // Floats a "Hide" dismiss control below the card.
    var showsHideButton: Bool = false

    // Mount as a plain overlay (not a cover) for hosts already above the tab bar, to skip cover latency.
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

    // Send card owns its chrome; adaptive width; shows Hide.
    static let send = QuickInviteMorphStyle(contentOwnsBackground: true, showsHideButton: true)
    // Content owns chrome; pager dismisses by responding, so no Hide.
    static let respond = QuickInviteMorphStyle(openDuration: 0.28, contentOwnsBackground: true)
    // Bare surface from a non-icon source (no glyph); card owns its background.
    static let plainCard = QuickInviteMorphStyle(showsGlyph: false, contentOwnsBackground: true, showsHideButton: true)
}

// MARK: - Presenter

struct QuickInviteMorphPresenter<Card: View, Overlay: View>: ViewModifier {
    @Binding var openPopupId: String?
    // Hides the morph card while a sibling confirm alert is up.
    let hideCard: Bool
    let style: QuickInviteMorphStyle
    @ViewBuilder let card: (String) -> Card
    // Full-screen sibling of the card (e.g. confirm alert) so its dim covers the whole screen.
    @ViewBuilder let overlay: () -> Overlay

    // Tapped icon frame in GLOBAL coords so the morph starts exactly on the source button.
    @State private var iconRect: CGRect = .zero

    // Which source id is morphing (mount→collapse end); injected so a matching `.morphSource` hides itself.
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
            // Surface is on screen collapsed immediately; open spring fires next frame — no cover step.
            anchored.overlay { if morphState.activeId != nil { morphLayer } }
        } else {
            // Cover: floats the morph above a host that still shows the tab bar.
            anchored.fullScreenCover(isPresented: morphPresented) {
                morphLayer.presentationBackground(.clear)
            }
        }
    }

    @ViewBuilder private var morphLayer: some View {
        GeometryReader { geo in
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

    // Capture the icon's global frame and mount the cover without the system slide.
    private func handleChange(_ new: String?, anchors: [String: Anchor<CGRect>], proxy: GeometryProxy) {
        guard let new, let anchor = anchors[new] else { return }
        let local = proxy[anchor]
        let origin = proxy.frame(in: .global).origin
        iconRect = CGRect(x: local.minX + origin.x, y: local.minY + origin.y,
                          width: local.width, height: local.height)
        withoutCoverAnimation { morphState.activeId = new }
    }

    private func withoutCoverAnimation(_ body: () -> Void) {
        var txn = Transaction()
        txn.disablesAnimations = true
        withTransaction(txn, body)
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

// Published by the card when an inner popup is open, so the morph can hide the Hide control.
struct MorphPopupOpenKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    /// END destination: the card the morph surface grows into (content-owns-background flows).
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

    /// Publishes "a popup is open inside me" up to the morph so it can hide the Hide control.
    func morphPopupOpen(_ isOpen: Bool) -> some View {
        preference(key: MorphPopupOpenKey.self, value: isOpen)
    }

    /// Marks this view as a morph source for `id`: publishes its frame and hides it while morphing.
    func morphSource(id: String) -> some View {
        modifier(MorphSourceModifier(id: id))
    }
}

// MARK: - Card tint

private struct InviteCardTintKey: EnvironmentKey {
    static let defaultValue: Color = .clear
}

private struct InviteCardBaseKey: EnvironmentKey {
    static let defaultValue: Color = .appCanvas
}

extension EnvironmentValues {
    /// Dominant color extracted from the morph's source image, shared down to the card so its
    /// background can carry a faint wash matching the backdrop. `.clear` until extraction lands / no image.
    var inviteCardTint: Color {
        get { self[InviteCardTintKey.self] }
        set { self[InviteCardTintKey.self] = newValue }
    }

    /// The card's opaque base fill, published by `inviteCardBackground()` so edge fades inside the card
    /// dissolve into the exact same color. Defaults to `.appCanvas` for everything outside a card.
    var inviteCardBase: Color {
        get { self[InviteCardBaseKey.self] }
        set { self[InviteCardBaseKey.self] = newValue }
    }
}

// MARK: - Source coordination

/// The source id currently morphing (mount→collapse end); owned by the presenter, injected into content.
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
    /// Morphs `card` out of the `.morphSource(id:)` matching `openPopupId`; set to present, nil to collapse.
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
