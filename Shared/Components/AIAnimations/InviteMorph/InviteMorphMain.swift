//
//  InviteMorphMain.swift
//  Scoop Test
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
    // Sheet-style grabber in this full-screen layer so its drag region isn't clamped to the card frame.
    let showsGrabber: Bool
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
    // Card's live vertical displacement while the grabber is being dragged.
    @State private var dragOffset: CGFloat = 0

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
            .offset(y: dragOffset)
            if showsGrabber { grabber }
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
        // Once the dismiss drag engages, the card's controls go inert so the release can't land as a tap.
        // Inside the drag attachment below, so the drag itself keeps tracking.
        .disabled(dragOffset != 0)
        .opacity(expanded ? 1 : 0)
        .animation(expanded ? .easeIn(duration: 0.14).delay(contentFadeDelay) : nil, value: expanded)
        .allowsHitTesting(expanded)
        // Swipe-down-to-dismiss from anywhere on the card; masked off entirely for flows without the grabber.
        .simultaneousGesture(cardDismissDrag, including: showsGrabber ? .all : .subviews)
    }

    // Sheet-style grabber pinned to the card's top edge; dragging it tracks the card and dismisses past a threshold.
    private var grabber: some View {
        Capsule()
            .fill(Color(red: 0.78, green: 0.78, blue: 0.80))
            .frame(width: 36, height: 4)
            .frame(width: 140, height: 44) // generous drag target around the thin bar
            .contentShape(Rectangle())
            .position(x: expandedRect.midX, y: expandedRect.minY + 12)
            .offset(y: dragOffset)
            .opacity(expanded && !hideCard && !popupOpen ? 1 : 0)
            .animation(expanded ? .easeIn(duration: 0.14).delay(contentFadeDelay) : nil, value: expanded) // fades in with the card content
            .animation(.smooth(duration: 0.2), value: popupOpen)
            .allowsHitTesting(expanded && !hideCard && !popupOpen)
            .gesture(dismissDrag)
    }

    // Immediate tracking from the grabber itself.
    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let dy = value.translation.height
                dragOffset = dy > 0 ? dy : dy / 3 // rubber-band resistance upward
            }
            .onEnded(endDrag)
    }

    // Anywhere on the card: runs alongside the card's own controls, but only captures clearly vertical drags
    // so taps, presses, and horizontal swipes inside the card behave normally.
    // Measured in the morph's stable space — the card itself moves with the drag, so its local space would feed back (jitter).
    private var cardDismissDrag: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .named(morphCoordinateSpace))
            .onChanged { value in
                guard expanded, !hideCard, !popupOpen else { return }
                let t = value.translation
                if dragOffset == 0, abs(t.height) <= abs(t.width) { return }
                dragOffset = t.height > 0 ? t.height : t.height / 3
            }
            .onEnded { value in
                guard dragOffset != 0 else { return }
                endDrag(value)
            }
    }

    private func endDrag(_ value: DragGesture.Value) {
        if value.translation.height > 100 || value.predictedEndTranslation.height > 220 {
            withAnimation(closeAnimation) { dragOffset = 0 } // fold back from the dragged position
            onHide()
        } else {
            withAnimation(.spring(duration: 0.35, bounce: 0.3)) { dragOffset = 0 }
        }
    }

}
