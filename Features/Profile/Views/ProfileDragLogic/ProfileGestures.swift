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
        
        // 1. Measure the actual drag distance and SwiftUI’s predicted end distance based on velocity
        let predicted = value.predictedEndTranslation.height
        let translation = value.translation.height
        
        switch dragType {
            
        case .profile:
            // 2.1. If the profile dismissal threshold is passed, dismiss it with animation.
            let shouldDismissProfile = max(translation, predicted) > 80
            if shouldDismissProfile {
                animateProfileDismissal(using: geo) ; return //No need to set dragType to nil, as when profile reopens, its sets it to nil
            }
            
        case .details:
            handleDetailsDragEnd(value)
            
        case .horizontal, .none:
            break
        }
        
        //3. At the end, if not returned, put drag type back to nil and reset offsets to 0
        dragType = nil
        withAnimation(ProfileView.toggleAnimation) {
            detailsOffset = 0
            profileOffset = 0
        }
    }

    private func identifyDragType(v: DragGesture.Value) {
        let dy = abs(v.translation.height)
        let dx = abs(v.translation.width)
        guard dy > dx else { dragType = .horizontal; return }
        dragType = (v.translation.height < 0 || ui.detailsOpen) ? .details : .profile
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
        let dragY = value.translation.height
        let predictedY = value.predictedEndTranslation.height
        let threshold: CGFloat = 55
        
        let upwardDrag = min(dragY, predictedY)
        let downwardDrag = max(dragY, predictedY)
        
        let shouldOpenDetails = !ui.detailsOpen && upwardDrag < -threshold
        let shouldCloseDetails = ui.detailsOpen && ui.detailsDragEngaged && downwardDrag > threshold
        
        if shouldOpenDetails {
            ui.detailsOpen = true
        } else if shouldCloseDetails {
            ui.detailsOpen = false
        }
        
        detailsOffset = 0
        ui.detailsDragEngaged = false
    }
}
