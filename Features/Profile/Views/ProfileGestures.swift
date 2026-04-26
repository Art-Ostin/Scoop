//
//  ProfileGestures.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI


extension ProfileView {
    
    func imageDetailsDrag(using geo: GeometryProxy) -> some Gesture {
    DragGesture(minimumDistance: 5)
        .updating($profileOffset) { value, state, _ in
            if ui.dragType == nil { dragType(v: value) }
            guard ui.dragType == .profile else { return }
            state = value.translation.height
        }
        .updating($detailsOffset) { v, state, _ in
            if ui.dragType == nil { dragType(v: v) }
            guard ui.dragType == .details else { return }
            state = v.translation.height.clamped(to: transition.dragRange)
        }
        .onEnded { v in
            defer { ui.dragType = nil }
            guard ui.dragType != nil && ui.dragType != .horizontal else { return }
            let predicted = abs(v.predictedEndTranslation.height)
            let distance = abs(v.translation.height)
            //Only update if user drags more than 75
            guard max(distance, predicted) > 75 else { return }
            if ui.dragType == .profile {
                dismissOffset = v.translation.height
                withAnimation(.easeInOut(duration: ui.dismissalDuration)) { selectedProfile = nil } //Fixes bug
            } else if ui.dragType == .details {
                ui.detailsOpen.toggle()
            }
        }
}
    
    var detailsDrag: some Gesture {
    DragGesture(minimumDistance: 5)
        .updating($detailsOffset) { v, state, _ in
            if ui.detailsOpen && (!ui.isTopOfScroll || v.translation.height < 0) { return }
            if ui.dragType == nil {dragType(v: v)}
            guard ui.dragType != nil && ui.dragType != .horizontal else { return }
            state = v.translation.height.clamped(to: transition.dragRange)
        }
        .onEnded {
            defer { ui.dragType = nil }
            guard ui.dragType != nil && ui.dragType != .horizontal else { return }
            let predicted = $0.predictedEndTranslation.height
            if predicted < 50 && profileOffset == 0 {
                ui.detailsOpen = true
            } else if ui.detailsOpen && predicted > 60 {
                ui.detailsOpen = false
            }
        }
}
    
    func dragType(v: DragGesture.Value) {
    //If there is already a dragType don't reassign it (here), get y and x drag
    if ui.dragType != nil  {return }
    let dy = abs(v.translation.height)
    let dx = abs(v.translation.width)
    //Ensures user drags at least 5 points, and its a vertical drag
    guard dy > dx else { ui.dragType = .horizontal; return}
    //If it passes conditions updates 'drag type'
    ui.dragType = (v.translation.height < 0 || ui.detailsOpen) ? .details : .profile
}
}
