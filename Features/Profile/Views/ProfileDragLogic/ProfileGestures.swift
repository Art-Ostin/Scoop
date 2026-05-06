//
//  ProfileGestures.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

//Logic to deal with dragging the image
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
                animateProfileDismissal(using: geo) ; return
            }
            
        case .details:
            // 2.2. If the details threshold is passed, toggle details open or closed.
            let shouldToggleDetails = max(abs(translation), abs(predicted)) > 75
            if shouldToggleDetails {
                ui.detailsOpen.toggle()
            }

        case .horizontal, .none:
            break
        }
        
        //3. At the end put drag type back to nil and reset offsets to 0
        dragType = nil
        withAnimation(ProfileView.toggleAnimation) {
            detailsOffset = 0
            profileOffset = 0
        }
    }
}


extension ProfileView {


    
    
    
    

    var detailsDrag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { v in
                guard abs(v.translation.height) > abs(v.translation.width) else { return }
                if ui.detailsOpen {
                    // Only engage when at top of scroll and pulling down — otherwise the ScrollView scrolls
                    guard ui.isAtTopOfScroll, v.translation.height > 0 else { return }
                }
                ui.detailsDragEngaged = true
                detailsOffset = v.translation.height.clamped(to: transition.dragRange)
            }
            .onEnded { v in
                let predicted = v.predictedEndTranslation.height
                let wasEngaged = ui.detailsDragEngaged
                withAnimation(ProfileView.toggleAnimation) {
                    if !ui.detailsOpen, predicted < -50 {
                        ui.detailsOpen = true
                    } else if ui.detailsOpen, wasEngaged, predicted > 60 {
                        ui.detailsOpen = false
                    }
                    detailsOffset = 0
                    ui.detailsDragEngaged = false
                }
            }
    }

    func identifyDragType(v: DragGesture.Value) {
        let dy = abs(v.translation.height)
        let dx = abs(v.translation.width)
        guard dy > dx else { dragType = .horizontal; return }
        dragType = (v.translation.height < 0 || ui.detailsOpen) ? .details : .profile
    }

    func animateProfileDismissal(using geo: GeometryProxy) {
        let exit = geo.size.height + geo.safeAreaInsets.bottom
        dismissOffset = profileOffset
        profileOffset = 0
        withAnimation(.easeOut(duration: ui.dismissalDuration)) {
            dismissOffset = exit
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ui.dismissalDuration) {
            selectedProfile = nil
        }
    }
}
