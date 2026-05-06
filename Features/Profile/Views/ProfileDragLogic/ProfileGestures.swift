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
        let isDraggingDown = drag.height > 0

        // 1. Make sure its a vertical (not horizontal) drag if not ignore
        guard abs(drag.height) > abs(drag.width) else { return }

        // 2. Only offset details view, if its closed OR if is at top of scroll view and dragging down
        let canDragDetails = !ui.detailsOpen || (ui.isAtTopOfScroll && isDraggingDown)
        guard canDragDetails else { return }

        // 3. Anchor on first event so the offset grows from 0 (not from the
        //    activation distance), and apply the drag.
        if dragStart == nil { dragStart = drag.height }
        let dy = drag.height - (dragStart ?? 0)

        ui.detailsDragEngaged = true
        let restPos: CGFloat = ui.detailsOpen ? ui.detailsOpenOffset : 0
        detailsOffset = (restPos + dy).clamped(to: transition.offsetRange)
        print("[drag] t=\(value.translation.height) dy=\(dy) -> offset=\(detailsOffset) open=\(ui.detailsOpen)")
    }

    private func handleDetailsDragEnd(_ value: DragGesture.Value) {
        // 1. Normalize translation/prediction by the drag anchor.
        let anchor = dragStart ?? 0
        let dragY = value.translation.height - anchor
        let predictedY = value.predictedEndTranslation.height - anchor
        let threshold: CGFloat = 55
        print("[end] dragY=\(dragY) predY=\(predictedY) currentOffset=\(detailsOffset) open=\(ui.detailsOpen) dragEngaged=\(ui.detailsDragEngaged)")

        // 2. Identify what the upward or downward drag is
        let upwardDrag = min(dragY, predictedY)
        let downwardDrag = max(dragY, predictedY)

        // 3. Open or close details conditions
        let shouldOpenDetails = !ui.detailsOpen && upwardDrag < -threshold
        let shouldCloseDetails = ui.detailsOpen && ui.detailsDragEngaged && downwardDrag > threshold

        // 4. Animate snap and open/close together. detailsOffset is the absolute
        //    y offset, so the spring interpolates a single continuous value from
        //    the current drag position to the new rest position. detailsDragEngaged
        //    is reset in the completion handler so the inner ScrollView only re-enables
        //    once the spring has settled — re-enabling it mid-animation causes a
        //    visible layout hiccup.
        let willOpen: Bool
        if shouldOpenDetails { willOpen = true }
        else if shouldCloseDetails { willOpen = false }
        else { willOpen = ui.detailsOpen }
        let target: CGFloat = willOpen ? ui.detailsOpenOffset : 0
        print("[snap-start] from=\(detailsOffset) to=\(target) willOpen=\(willOpen)")

        withAnimation(ProfileView.toggleAnimation) {
            ui.detailsOpen = willOpen
            detailsOffset = target
        } completion: {
            ui.detailsDragEngaged = false
            detailsFullyOpen = willOpen
            print("[snap-done] offset=\(detailsOffset) open=\(ui.detailsOpen)")
        }
        dragStart = nil
    }
}
