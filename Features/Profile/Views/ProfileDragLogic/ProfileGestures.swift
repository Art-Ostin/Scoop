//
//  ProfileGestures.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

//Logic to deal with dragging gestures on the image
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
        switch dragType {
            // 2. Dragging the profile down dismisses it.
        case .profile:
            profileOffset = max(0, value.translation.height)
            
            // 3. Dragging the details view moves it within its allowed range.
        case .details:
            ui.detailsDragEngaged = true
            detailsOffset = value.translation.height.clamped(to: transition.dragRange)
            
            // 4. Ignore horizontal or unidentified drags.
        case .horizontal, .none:
            break
        }
    }
    
    private func onImageDragEnd(_ value: DragGesture.Value, geo: GeometryProxy) {
        //1. Always set dragType to nil at end of drag so can be recomputed on next drag
        defer { dragType = nil}
        
        //2. Depending on the dragType on image, do different drag type
        switch dragType {
        case .profile:
            handleProfileDragEnd(value, geo: geo)
        case .details:
            handleDetailsDragEnd(value)
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
    
    private func handleProfileDragEnd(_ value: DragGesture.Value, geo: GeometryProxy) {
        // 1. Measure the actual drag distance and SwiftUI’s predicted end distance based on velocity
        let predicted = value.predictedEndTranslation.height
        let translation = value.translation.height
        
        // 2. Create the dismiss threshold to dismiss Profile
        let shouldDismissProfile = translation > 80 || predicted > 160
        
        // 3. If the drag passes the dismiss threshold, dismiss Profile and end
        if shouldDismissProfile {
            animateProfileDismissal(using: geo)
            return
        }
        
        // Otherwise, return profileOffset back to 0
        withAnimation(ProfileView.toggleAnimation) {
            profileOffset = 0
        }
    }
}

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
        
        //1. Make sure its a vertical (not horizontal) drag if not ignore
        guard abs(drag.height) > abs(drag.width) else { return }
        
        //2.Only offset details view, if its closed OR if is at top of scroll view and dragging down
        let canDragDetails = !ui.detailsOpen || (ui.isAtTopOfScroll && isDraggingDown)
        guard canDragDetails else { return }
        
        //3.If can drag details update (1) uiState (as this disables scrollView in details) and (2) update detailsOffset to the drag amount
        ui.detailsDragEngaged = true
        detailsOffset = drag.height.clamped(to: transition.dragRange)
    }
    
    private func handleDetailsDragEnd(_ value: DragGesture.Value) {
        
        //1. Get the drag and predicted drag
        let dragY = value.translation.height
        let predictedY = value.predictedEndTranslation.height
        let threshold: CGFloat = 55
        
        //2. Identify what the upward or downward drag is
        let upwardDrag = min(dragY, predictedY)
        let downwardDrag = max(dragY, predictedY)
        
        //3. Open or close details conditions
        let shouldOpenDetails = !ui.detailsOpen && upwardDrag < -threshold
        let shouldCloseDetails = ui.detailsOpen && ui.detailsDragEngaged && downwardDrag > threshold
        
        //4. Actually open or close details with animation
        withAnimation(ProfileView.toggleAnimation) {
            if shouldOpenDetails {
                ui.detailsOpen = true
            } else if shouldCloseDetails {
                ui.detailsOpen = false
            }
            detailsOffset = 0
            ui.detailsDragEngaged = false
        }
    }
}
