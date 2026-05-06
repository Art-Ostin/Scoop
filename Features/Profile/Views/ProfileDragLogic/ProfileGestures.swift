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
                if dragType == nil { identifyDragType(v: v) }
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
                ui.detailsDragEngaged = false
                withAnimation(ProfileView.toggleAnimation) {
                    if !ui.detailsOpen, predicted < -50 {
                        ui.detailsOpen = true
                    } else if ui.detailsOpen, wasEngaged, predicted > 60 {
                        ui.detailsOpen = false
                    }
                    detailsOffset = 0
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
