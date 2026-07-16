//
//  InviteCardDragLogic.swift
//  Scoop
//
//  Created by Art Ostin on 11/07/2026.
//

import SwiftUI



extension SendInviteCard {

    var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                //A drag that starts as a send-button press belongs to the button until release.
                //Dragging away cancels that press; it must not also move or dismiss the card.
                guard !sendButtonTouchActive else { return }
                if dragAxis == nil {
                    let vertical = abs(value.translation.height) >= abs(value.translation.width)
                    let canBegin = expanded && landed && !springingBack //Only a landed card is grabbable
                    if vertical && canBegin { dragAxis = .vertical; beginDrag() }
                    else { dragAxis = .horizontal } //Voided: horizontal belongs to the pager
                }
                guard dragAxis == .vertical, dragging, expanded else { return }
                let t = value.translation
                dragProgress = min(max(t.height / Self.collapseDistance, 0), 1)
                onDismissProgress?(dragProgress)
                dragOffset = CGSize(
                    width: rubberBand(t.width, limit: 160, response: 0.8),
                    height: t.height >= 0
                        ? rubberBand(t.height, limit: 700, response: 1)
                        : rubberBand(t.height, limit: 80, response: 0.9) //Upward fights back hard
                )
            }
            .onEnded { value in
                let owned = dragAxis == .vertical && dragging
                dragAxis = nil
                guard owned, expanded else { return }
                let flick = value.predictedEndTranslation.height - value.translation.height
                if dragProgress > Self.dismissThreshold || (value.translation.height > 20 && flick > 90) {
                    finishDismiss()
                } else {
                    cancelDrag()
                }
            }
    }

    private func beginDrag() {
        dragging = true
        snapPager { $0.scrollTo(id: currentPage, anchor: .leading) }
    }

    private func finishDismiss() {
        withAnimation(Self.closeFlight) {
            dragProgress = 0
            dragOffset = .zero
            onDismissProgress?(0)
        }
        closeInvite()
    }

    private func cancelDrag() {
        springingBack = true
        withAnimation(Self.openFlight, completionCriteria: .removed) {
            dragProgress = 0
            dragOffset = .zero
            onDismissProgress?(0)
        } completion: {
            springingBack = false
            guard expanded else { return } //A close started mid-spring; leave state to that flight
            dragging = false
        }
    }

    //Asymptotic rubber band: tracks at ~response·d near zero, saturating at `limit`.
    private func rubberBand(_ d: CGFloat, limit: CGFloat, response: CGFloat) -> CGFloat {
        guard d != 0 else { return 0 }
        let m = abs(d) * response
        return (1 - 1 / (m / limit + 1)) * limit * (d < 0 ? -1 : 1)
    }

    func dragAnchor(_ size: CGSize, _ origin: CGPoint) -> UnitPoint {
        guard imageFrame.height > 1, size.width > 1, size.height > 1 else { return .center }
        return UnitPoint(x: (imageFrame.midX - origin.x) / size.width,
                         y: (imageFrame.midY - origin.y) / size.height)
    }

    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
        CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
               width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
    }
}
