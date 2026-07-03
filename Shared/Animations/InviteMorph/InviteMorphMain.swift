//
//  InviteMorphMain.swift
//  Scoop
//
//  Created by Art Ostin on 01/07/2026.
//

import SwiftUI

// MARK: - Quick invite morph

struct QuickInviteMorph<Card: View, Overlay: View>: View {

    let iconRect: CGRect
    let isPresented: Bool
    let containerSize: CGSize
    let hideCard: Bool
    let style: QuickInviteMorphStyle
    // Source image the background layer blurs behind the card (nil → no image backdrop).
    let image: UIImage?
    // Fires the instant the collapse lands, so the caller unmounts the cover in sync.
    let onCollapsed: () -> Void
    // "Hide" control in this full-screen layer so its tap region isn't clamped to the card frame.
    let showsHideButton: Bool
    let onHide: () -> Void
    @ViewBuilder var card: () -> Card
    @ViewBuilder var overlay: () -> Overlay

    @State private var expanded = false
    @State private var revealed = false
    @State private var surfaceHandedOff = false
    @State private var cardHeight: CGFloat = 360
    @State private var measuredCardRect: CGRect? = nil
    @State private var popupOpen = false
    // Dominant color of `image`, extracted once here and shared with both the backdrop and the card.
    @State private var tint: Color = .clear

    private var sideMargin: CGFloat { style.sideMargin }
    private var cardWidth: CGFloat { max(0, containerSize.width - sideMargin * 2) }

    private let verticalOffset: CGFloat = 12

    private var expandedRect: CGRect {
        if style.contentOwnsBackground, let measuredCardRect { return measuredCardRect }
        return CGRect(x: (containerSize.width - cardWidth) / 2,
                      y: (containerSize.height - cardHeight) / 2 + verticalOffset,
                      width: cardWidth, height: cardHeight)
    }

    private var windowRect: CGRect { expanded ? expandedRect : iconRect }
    private var cornerRadius: CGFloat { expanded ? 30 : iconRect.height / 2 }

    private var openAnimation: Animation { .spring(duration: style.openDuration, bounce: 0.2) }
    private let closeAnimation: Animation = .spring(duration: 0.28, bounce: 0.12)
    private var morphAnimation: Animation { expanded ? openAnimation : closeAnimation }

    private var handoffDelay: Double { style.openDuration * (0.30 / 0.35) }
    private var contentFadeDelay: Double { style.openDuration * (0.16 / 0.35) }

    var body: some View {
        return ZStack {
            if let image {
                InviteMorphBackground(expanded: expanded, image: image, tint: tint)
            }
            Group {
                surface
                cardContent
            }
            .opacity(hideCard ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: hideCard)
            .environment(\.inviteCardTint, tint) // card reads this for its faint background wash
            if showsHideButton { hideButton }
            overlay()
        }
        .task {
            guard let image else { return }
            tint = await InviteMorphBackground.backgroundTint(from: image)
        }
        .coordinateSpace(name: morphCoordinateSpace)
        .onPreferenceChange(MorphCardFrameKey.self) { rect in
            // Freeze the first valid frame so the surface lands on the real card and doesn't drift; animate the arrival.
            guard measuredCardRect == nil, let rect, rect.height > 1 else { return }
            withAnimation(openAnimation) { measuredCardRect = rect }
        }
        .onPreferenceChange(MorphPopupOpenKey.self) { popupOpen = $0 }
        .onAppear {
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
            // Reveal on first open commit and stay revealed through collapse, so it folds back onto the icon.
            if isExpanded { revealed = true }
            if style.contentOwnsBackground { surfaceHandedOff = isExpanded }
        }
        .animation(morphAnimation, value: cardHeight)
    }

    // The single morphing surface: accent circle relaxes into the appCanvas card (frame + corner animate, tint fades).
    private var surface: some View {
        ZStack {
            Color.appCanvas
        }
        .frame(width: windowRect.width, height: windowRect.height)
        .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.border, lineWidth: 0.5)
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
        .position(x: windowRect.midX, y: windowRect.midY)
        .opacity(surfaceHandedOff ? 0 : 1)
        .animation(expanded ? .easeInOut(duration: 0.15).delay(handoffDelay) : nil, value: surfaceHandedOff)
        .opacity(revealed ? 1 : 0)
        .allowsHitTesting(false)
    }

    // Real card content; fades in after the surface grows, out fast on close.
    @ViewBuilder private var cardContent: some View {
        Group {
            if style.contentOwnsBackground {
                // Owns its chrome; may span the full screen. Surface only handles the growth.
                card()
                    .frame(width: containerSize.width, height: containerSize.height)
            } else {
                // No own background — pinned at the final frame; the surface is its permanent background.
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

    // Pinned to the real card frame so it floats just below the card, with a full-screen tap region.
    private var hideButton: some View {
        HidePopup(onHide: onHide)
            .position(x: expandedRect.midX, y: expandedRect.maxY + 48)
            .opacity(expanded && !hideCard && !popupOpen ? 1 : 0)
            .animation(.easeInOut(duration: 0.05), value: expanded)
            .animation(.smooth(duration: 0.2), value: popupOpen)
            .allowsHitTesting(expanded && !hideCard && !popupOpen)
    }

}
