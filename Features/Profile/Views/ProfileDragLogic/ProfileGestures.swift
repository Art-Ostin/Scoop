//
//  ProfileGestures.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

// Logic to deal with dragging gestures on the image
extension ProfileView {

    func imageDetailsDrag(using geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                handleImageDrag(value)
            }
            .onEnded { value in
                onImageDragEnd(value, geo: geo)
            }
    }

    private func handleImageDrag(_ value: DragGesture.Value) {
        // 1. Determine the drag type once we have enough movement to read direction.
        if dragType == nil {
            identifyDragType(v: value)
        }
        // 2. Anchor on first identified event so the offset grows from 0 instead
        //    of jumping by whatever translation accumulated before identification.
        guard dragType != nil else { return }
        if dragStart == nil { dragStart = value.translation.height }
        let dy = value.translation.height - (dragStart ?? 0)

        switch dragType {
            // 3. Dragging the profile down dismisses it. Pulling up rubber-bands
            //    against the top instead of hard-flooring at 0.
        case .profile:
            profileOffset = dy >= 0 ? dy : ProfileDetailsTransition.rubberBand(dy, range: 300)

            // 4. Dragging the details view follows the finger 1:1 inside [openOffset, 0]
            //    and rubber-bands logarithmically outside, matching UISheetPresentationController.
        case .details:
            ui.detailsDragEngaged = true
            let restPos: CGFloat = ui.detailsOpen ? ui.detailsOpenOffset : 0
            detailsOffset = ProfileDetailsTransition.rubberBandedOffset(restPos + dy, openOffset: ui.detailsOpenOffset)

            // 5. Ignore horizontal or unidentified drags.
        case .horizontal, .none:
            break
        }
    }

    private func identifyDragType(v: DragGesture.Value) {
        let dy = abs(v.translation.height)
        let dx = abs(v.translation.width)
        // Wait for a few points of clear movement before deciding direction.
        // With minimumDistance: 0, the gesture fires on touch-down where dy=dx=0,
        // which would otherwise mis-classify as horizontal and lock the drag out.
        guard max(dy, dx) > 4 else { return }
        guard dy > dx else { dragType = .horizontal; return }
        dragType = (v.translation.height < 0 || ui.detailsOpen) ? .details : .profile
    }

    private func onImageDragEnd(_ value: DragGesture.Value, geo: GeometryProxy) {
        // 1. Always reset drag state at end of drag so it can be recomputed on next drag
        defer {
            dragType = nil
            dragStart = nil
        }

        // 2. Depending on the dragType on image, do different drag type
        switch dragType {
        case .profile:
            handleProfileDragEnd(value, geo: geo)
        case .details:
            handleDetailsDragEnd(value)
        case .horizontal, .none:
            break
        }
    }

    private func handleProfileDragEnd(_ value: DragGesture.Value, geo: GeometryProxy) {
        // 1. Normalize translation/prediction by the drag anchor so 0 == release-from-rest.
        let anchor = dragStart ?? 0
        let translation = value.translation.height - anchor
        let predicted = value.predictedEndTranslation.height - anchor

        // 2. Create the dismiss threshold to dismiss Profile
        let shouldDismissProfile = translation > 80 || predicted > 160

        // 3. If the drag passes the dismiss threshold, dismiss Profile and end
        if shouldDismissProfile {
            animateProfileDismissal(using: geo)
            return
        }

        // 4. Otherwise, return profileOffset back to 0
        withAnimation(ProfileView.toggleAnimation) {
            profileOffset = 0
        }
    }
}

// Logic to deal with dragging gestures on the details view
extension ProfileView {

    var detailsDrag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                handleDetailsDrag(value)
            }
            .onEnded { value in
                handleDetailsDragEnd(value)
            }
    }

    private func handleDetailsDrag(_ value: DragGesture.Value) {
        let drag = value.translation

        // 1. Latch engagement on the first valid event. Re-evaluating the canDrag
        //    guard every frame caused jitter: ui.isAtTopOfScroll is updated
        //    asynchronously by onScrollGeometryChange, and could flicker for a
        //    frame or two as the inner ScrollView rubber-banded before
        //    scrollDisabled took effect — flickering the guard skipped offset
        //    updates intermittently. dragStart doubles as the "engaged" marker.
        if dragStart == nil {
            // 1a. Wait for clear movement before deciding (minimumDistance: 0
            //     means the first event has translation 0/0).
            guard max(abs(drag.height), abs(drag.width)) > 4 else { return }

            // 1b. Vertical (not horizontal) drag.
            guard abs(drag.height) > abs(drag.width) else { return }

            // 1c. Allow if details is closed, or open + at top of scroll + pulling down.
            let isDraggingDown = drag.height > 0
            let canDrag = !ui.detailsOpen || (ui.isAtTopOfScroll && isDraggingDown)
            guard canDrag else { return }

            // 1d. Anchor so the offset grows from 0 instead of jumping by the
            //     accumulated translation, and disable the inner ScrollView
            //     for the rest of this drag.
            dragStart = drag.height
            ui.detailsDragEngaged = true
        }

        // 2. Track finger 1:1 inside the natural [openOffset, 0] range; outside
        //    apply iOS-style logarithmic rubber-band. Wrap the write in a
        //    non-animated transaction so it cancels any in-flight spring (from
        //    a prior toggle/close/drag-end) cleanly, rather than letting queued
        //    spring frames render alongside the new direct value — that
        //    interleaving is what produced the back-and-forth jitter on fast
        //    drags 50% of the time.
        let dy = drag.height - (dragStart ?? 0)
        let restPos: CGFloat = ui.detailsOpen ? ui.detailsOpenOffset : 0
        let newOffset = ProfileDetailsTransition.rubberBandedOffset(restPos + dy, openOffset: ui.detailsOpenOffset)
        withTransaction(Transaction(animation: nil)) {
            detailsOffset = newOffset
        }
    }

    private func handleDetailsDragEnd(_ value: DragGesture.Value) {
        // 1. If the drag never engaged (e.g., horizontal, or open-and-not-at-top),
        //    leave state alone. dragStart being nil is the signal.
        guard dragStart != nil else { return }
        dragStart = nil

        // 2. UIScrollView-style velocity projection: where would the offset land
        //    if released with current velocity and decelerated at the standard
        //    rate? Snap to whichever detent the projected end is closer to.
        //    This mirrors UISheetPresentationController: a gentle pull past the
        //    midpoint commits, a fast flick from anywhere can commit, and a
        //    weak flick that doesn't carry past the midpoint snaps back.
        let velocity = value.velocity.height
        let decelerationRate: CGFloat = 0.998
        let projection = velocity / 1000 * decelerationRate / (1 - decelerationRate)
        let projectedOffset = detailsOffset + projection

        let closedSnap: CGFloat = 0
        let openSnap: CGFloat = ui.detailsOpenOffset
        let willOpen = abs(projectedOffset - openSnap) < abs(projectedOffset - closedSnap)
        let target: CGFloat = willOpen ? openSnap : closedSnap

        // 3. Feed raw velocity into the spring (no gating, no cap). The spring
        //    is critically damped, so even a misaligned flick — e.g. pulled up
        //    then released downward without crossing the snap midpoint — gives
        //    a brief follow-through then settles without overshoot. That brief
        //    follow-through is authentic UISheetPresentationController feel.
        let distance = target - detailsOffset
        let initialVelocity = abs(distance) > 0.5 ? Double(velocity / distance) : 0

        // 4. Flip detailsOpen outside the animation transaction so dependents
        //    (colors, scrollDisabled, dismiss button visibility) don't all enroll
        //    in the spring; only detailsOffset is animated, and the transition
        //    struct stays continuous because it's derived from detailsOffset.
        ui.detailsOpen = willOpen

        // 5. damping = 32 for stiffness 246 → ζ ≈ 1.02 (critically damped, no
        //    visible overshoot even with raw uncapped velocity).
        //    detailsDragEngaged is reset in the completion handler so the inner
        //    ScrollView only re-enables once the spring has settled.
        withAnimation(.interpolatingSpring(stiffness: 246, damping: 32, initialVelocity: initialVelocity)) {
            detailsOffset = target
        } completion: {
            ui.detailsDragEngaged = false
            detailsFullyOpen = willOpen
        }
    }
}
