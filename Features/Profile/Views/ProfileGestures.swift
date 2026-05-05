//
//  ProfileGestures.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI


extension ProfileView {

    func imageDetailsDrag(using geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { v in
                if dragType == nil { commitDragType(v: v) }
                switch dragType {
                case .profile:
                    profileOffset = max(0, v.translation.height)
                case .details:
                    detailsOffset = v.translation.height.clamped(to: transition.dragRange)
                default:
                    break
                }
            }
            .onEnded { v in
                let endedType = dragType
                dragType = nil

                let predicted = v.predictedEndTranslation.height
                let translation = v.translation.height

                if endedType == .profile {
                    let dismissSignal = max(translation, predicted)
                    if dismissSignal > 80 {
                        animateProfileDismissal(using: geo)
                        return
                    }
                    withAnimation(ProfileView.toggleAnimation) { profileOffset = 0 }
                    return
                }

                if endedType == .details {
                    let crossedThreshold = max(abs(translation), abs(predicted)) > 75
                    withAnimation(ProfileView.toggleAnimation) {
                        if crossedThreshold { ui.detailsOpen.toggle() }
                        detailsOffset = 0
                    }
                    return
                }

                withAnimation(ProfileView.toggleAnimation) {
                    detailsOffset = 0
                    profileOffset = 0
                }
            }
    }

    var detailsDrag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { v in
                if ui.detailsOpen && (!ui.isTopOfScroll || v.translation.height < 0) { return }
                if dragType == nil { commitDragType(v: v) }
                guard dragType == .details else { return }
                detailsOffset = v.translation.height.clamped(to: transition.dragRange)
            }
            .onEnded { v in
                let endedType = dragType
                dragType = nil

                guard endedType == .details else {
                    withAnimation(ProfileView.toggleAnimation) { detailsOffset = 0 }
                    return
                }

                let predicted = v.predictedEndTranslation.height
                withAnimation(ProfileView.toggleAnimation) {
                    if predicted < -50 && profileOffset == 0 {
                        ui.detailsOpen = true
                    } else if ui.detailsOpen && predicted > 60 {
                        ui.detailsOpen = false
                    }
                    detailsOffset = 0
                }
            }
    }

    func commitDragType(v: DragGesture.Value) {
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
