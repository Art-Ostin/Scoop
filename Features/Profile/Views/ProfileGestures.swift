//
//  ProfileGestures.swift
//  Scoop Test
//
//  Created by Art Ostin on 09/05/2026.
//

import SwiftUI


extension ProfileView {

    var detailsDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                // When details is open, only commit to dragging on a downward motion
                // at the top of the scroll. Otherwise let the ScrollView handle it.
                if !ui.isDraggingDetails {
                    let canDrag = !ui.detailsOpen || (ui.isAtTopOfScroll && value.translation.height > 0)
                    guard canDrag else { return }
                    ui.isDraggingDetails = true
                }
                let base = ui.detailsOpen ? ui.detailsOpenOffset : ui.detailsClosedOffset
                let proposed = base + value.translation.height
                ui.detailsOffset = rubberBand(value: proposed,
                                           min: ui.detailsOpenOffset,
                                           max: ui.detailsClosedOffset)
            }
            .onEnded { value in
                guard ui.isDraggingDetails else { return }
                ui.isDraggingDetails = false
                let target = nextDetent(for: value)
                let signedDistance = target - ui.detailsOffset
                let initialV: CGFloat = abs(signedDistance) > 0.001
                    ? value.velocity.height / signedDistance
                    : 0
                withAnimation(.interpolatingSpring(stiffness: 250, damping: 25, initialVelocity: initialV)) {
                    ui.detailsOpen = (target == ui.detailsOpenOffset)
                    ui.detailsOffset = target
                }
            }
    }

    // Create a rubber band
    private func rubberBand(value: CGFloat, min lo: CGFloat, max hi: CGFloat) -> CGFloat {
        let limit: CGFloat = 50
        let c: CGFloat = 0.55
        if value > hi {
            let x = value - hi
            return hi + (1 - 1 / (x * c / limit + 1)) * limit
        } else if value < lo {
            let x = lo - value
            return lo - (1 - 1 / (x * c / limit + 1)) * limit
        }
        return value
    }
    
    // Resolves which detent to snap to from gesture velocity + translation,
    private func nextDetent(for value: DragGesture.Value) -> CGFloat {
        let velocity = value.velocity.height          // pts/sec, + = down, - = up
        let translation = value.translation.height
        let velocityThreshold: CGFloat = 500          // a "flick"
        let distanceThreshold: CGFloat = 100          // a deliberate drag

        var willOpen = ui.detailsOpen
        if abs(velocity) > velocityThreshold {
            willOpen = velocity < 0
        } else if ui.detailsOpen, translation > distanceThreshold {
            willOpen = false
        } else if !ui.detailsOpen, translation < -distanceThreshold {
            willOpen = true
        }
        return willOpen ? ui.detailsOpenOffset : ui.detailsClosedOffset
    }
    
    
    //Details open from 0% to 100%. Many transition occur from 0% (start) to 100% (end) needed at same rate.
    //Function takes start and end value of transition, and make it transition at same rate as % details drag done.
    //impactStart/impactEnd restrict the transition to a sub-range of the drag progress (e.g. 0.5...1 = last 50%).
    func interpolate(from start: CGFloat = 0, to end: CGFloat, impactStart: CGFloat = 0, impactEnd: CGFloat = 1) -> CGFloat {
        let denom = abs(ui.detailsOpenOffset - ui.detailsClosedOffset)
        guard denom > 0.0001 else { return start }
        let progress = min(max(abs(ui.detailsOffset - ui.detailsClosedOffset) / denom, 0), 1)
        let span = impactEnd - impactStart
        guard span > 0.0001 else { return progress >= impactEnd ? end : start }
        let t = min(max((progress - impactStart) / span, 0), 1)
        return start + (end - start) * t
    }
}
