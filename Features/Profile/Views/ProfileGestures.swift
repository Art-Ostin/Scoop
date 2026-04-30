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
            .updating($detailsOffset) { v, state, _ in
                if ui.dragType == nil { dragType(v: v) }
                guard ui.dragType == .details else { return }
                state = v.translation.height.clamped(to: transition.dragRange)
            }
            .onEnded { _ in
                defer { ui.dragType = nil }
                guard ui.dragType == .details else { return }
                ui.detailsOpen.toggle()
            }
    }

    var detailsDrag: some Gesture {
        DragGesture(minimumDistance: 5)
            .updating($detailsOffset) { v, state, _ in
                if ui.detailsOpen && (!ui.isTopOfScroll || v.translation.height < 0) { return }
                if ui.dragType == nil { dragType(v: v) }
                guard ui.dragType == .details else { return }
                state = v.translation.height.clamped(to: transition.dragRange)
            }
            .onEnded {
                defer { ui.dragType = nil }
                guard ui.dragType == .details else { return }
                let predicted = $0.predictedEndTranslation.height
                if predicted < 50 {
                    ui.detailsOpen = true
                } else if ui.detailsOpen && predicted > 60 {
                    ui.detailsOpen = false
                }
            }
    }

    func dragType(v: DragGesture.Value) {
        if ui.dragType != nil { return }
        let dy = abs(v.translation.height)
        let dx = abs(v.translation.width)
        guard dy > dx else { ui.dragType = .horizontal; return }
        ui.dragType = .details
    }
}
