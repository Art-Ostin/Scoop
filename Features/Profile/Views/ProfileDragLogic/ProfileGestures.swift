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
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                handleImageDrag(value)
            }
            .onEnded { value in
                onImageDragEnd(value, geo: geo)
            }
    }

    private func handleImageDrag(_ value: DragGesture.Value) {
        // 1. Determine the drag type once the gesture passes the minimum distance.
        if dragType == nil {
            identifyDragType(v: value)
        }
        // 2. Anchor on first event so the offset grows from 0 instead of jumping
        //    by the gesture's activation distance (minimumDistance: 8).
        if dragStart == nil { dragStart = value.translation.height }
        let dy = value.translation.height - (dragStart ?? 0)

        switch dragType {
            // 3. Dragging the profile down dismisses it.
        case .profile:
            profileOffset = max(0, dy)

            // 4. Dragging the details view moves it within its allowed range.
        case .details:
            ui.detailsDragEngaged = true
            let restPos: CGFloat = ui.detailsOpen ? ui.detailsOpenOffset : 0
            detailsOffset = (restPos + dy).clamped(to: transition.offsetRange)

            // 5. Ignore horizontal or unidentified drags.
        case .horizontal, .none:
            break
        }
    }

    private func identifyDragType(v: DragGesture.Value) {
        let dy = abs(v.translation.height)
        let dx = abs(v.translation.width)
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
        DragGesture(minimumDistance: 8)
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
            // 1a. Vertical (not horizontal) drag.
            guard abs(drag.height) > abs(drag.width) else { return }

            // 1b. Allow if details is closed, or open + at top of scroll + pulling down.
            let isDraggingDown = drag.height > 0
            let canDrag = !ui.detailsOpen || (ui.isAtTopOfScroll && isDraggingDown)
            guard canDrag else { return }

            // 1c. Anchor so the offset grows from 0 instead of jumping by the
            //     gesture's activation distance, and disable the inner ScrollView
            //     for the rest of this drag.
            dragStart = drag.height
            ui.detailsDragEngaged = true
        }

        // 2. Track finger directly; rubber-band/overshoot is handled by the clamp.
        //    Wrap the write in a non-animated transaction so it cancels any
        //    in-flight spring (from a prior toggle/close/drag-end) cleanly,
        //    rather than letting queued spring frames render alongside the new
        //    direct value — that interleaving is what produced the back-and-forth
        //    jitter on fast drags 50% of the time.
        let dy = drag.height - (dragStart ?? 0)
        let restPos: CGFloat = ui.detailsOpen ? ui.detailsOpenOffset : 0
        let newOffset = (restPos + dy).clamped(to: transition.offsetRange)
        withTransaction(Transaction(animation: nil)) {
            detailsOffset = newOffset
        }
    }

    private func handleDetailsDragEnd(_ value: DragGesture.Value) {
        // 1. If the drag never engaged (e.g., horizontal, or open-and-not-at-top),
        //    leave state alone. dragStart being nil is the signal.
        guard let anchor = dragStart else { return }
        dragStart = nil

        // 2. predictedEndTranslation already incorporates flick velocity, so use
        //    it directly for the threshold. The previous min/max approach could
        //    let a reversed drag (e.g. pulled up 100, then flicked down) trigger
        //    the wrong direction because both upward/downward bounds passed.
        let predictedY = value.predictedEndTranslation.height - anchor
        let threshold: CGFloat = 55

        let willOpen: Bool
        if !ui.detailsOpen, predictedY < -threshold {
            willOpen = true
        } else if ui.detailsOpen, predictedY > threshold {
            willOpen = false
        } else {
            willOpen = ui.detailsOpen
        }
        let target: CGFloat = willOpen ? ui.detailsOpenOffset : 0

        // 3. Build a velocity-matched spring so a flick continues smoothly into
        //    the snap. Critical: only feed velocity into the spring when it's
        //    aligned with the snap direction. On a gentle swipe that doesn't
        //    pass the threshold, target is the rest position the finger was
        //    pulling away from, so velocity points opposite to distance — a
        //    signed velocity would push the spring further past rest before
        //    reversing, producing a visible "two-step" stutter on release.
        //    Aligned velocities (committed flicks) keep their momentum.
        let distance = target - detailsOffset
        let velocity = value.velocity.height
        let alignedVelocity: CGFloat = (velocity * distance > 0) ? velocity : 0
        let normalized = abs(distance) > 0.5 ? alignedVelocity / distance : 0
        let initialVelocity = Double(min(30, normalized))

        // 4. Flip detailsOpen outside the animation transaction so dependents
        //    (colors, scrollDisabled, dismiss button visibility) don't all enroll
        //    in the spring; only detailsOffset is animated, and the transition
        //    struct stays continuous because it's derived from detailsOffset.
        ui.detailsOpen = willOpen

        // 5. detailsDragEngaged is reset in the completion handler so the inner
        //    ScrollView only re-enables once the spring has settled — re-enabling
        //    mid-animation causes a visible layout hiccup.
        withAnimation(.interpolatingSpring(stiffness: 246, damping: 28, initialVelocity: initialVelocity)) {
            detailsOffset = target
        } completion: {
            ui.detailsDragEngaged = false
            detailsFullyOpen = willOpen
        }
    }
}
