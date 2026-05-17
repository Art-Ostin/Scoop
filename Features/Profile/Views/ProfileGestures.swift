//
//  ProfileGestures.swift
//  Scoop Test
//
//  Created by Art Ostin on 09/05/2026.
//

import SwiftUI

enum DragType {
    case undecided
    case horizontal
    case vertical
    case profileVertical
    case detailsVertical
}

//Logic to deal with ProfileDrag
extension ProfileView {
    
    func profileDrag(geo: GeometryProxy) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                let y = value.translation.height
                let x = value.translation.width

                if ui.dragType == .undecided {
                    if abs(x) > 6 || abs(y) > 6 {
                        ui.dragType = abs(y) > abs(x) ? .vertical : .horizontal
                    }
                }
                guard ui.dragType == .vertical
                    || ui.dragType == .profileVertical
                    || ui.dragType == .detailsVertical else { return }

                if ui.dragType == .vertical {
                    
                    ui.dragType = y > 0  && !ui.detailsOpen ? .profileVertical : .detailsVertical
                    ui.dragCommitTranslation = y
                    if ui.dragType == .detailsVertical {
                        ui.isDraggingDetails = true
                    }
                }

                switch ui.dragType {
                case .profileVertical:
                    ui.profileOffset = max(0, y - ui.dragCommitTranslation)
                case .detailsVertical:
                    let base = ui.detailsOpen ? ui.detailsOpenOffset : ui.detailsClosedOffset
                    let relative = y - ui.dragCommitTranslation
                    ui.detailsOffset = rubberBand(value: base + relative,
                                                  min: ui.detailsOpenOffset,
                                                  max: ui.detailsClosedOffset)
                default:
                    break
                }
            }
            .onEnded { value in
                defer { ui.dragType = .undecided }
                guard ui.dragType != .horizontal && ui.dragType != .undecided else { return }
                if ui.dragType == .profileVertical {
                    onProfileEnded(for: value, geo: geo)
                } else if ui.dragType == .detailsVertical {
                    onDetailsEnded(value: value)
                }
            }
    }
    
    
    private func onProfileEnded(for value: DragGesture.Value, geo: GeometryProxy) {
        if shouldDismiss(for: value, geo: geo) {
            animateDismiss(using: geo, releaseVelocity: value.velocity.height)
        } else {
            animateSnapBack(releaseVelocity: value.velocity.height)
        }
    }

    private func shouldDismiss(for value: DragGesture.Value, geo: GeometryProxy) -> Bool {
        let velocity = value.velocity.height
        let velocityThreshold: CGFloat = 500
        if velocity < -velocityThreshold { return false }
        if velocity > velocityThreshold { return true }
        return value.translation.height > geo.size.height * 0.2
    }
}

//Logic to deal with DetailsDrag
extension ProfileView {

    var detailsDrag: some Gesture {
        DragGesture(coordinateSpace: .named("profileZStack"))
            .onChanged { value in
                // When details is open, only commit to dragging on a downward motion
                // at the top of the scroll. Otherwise let the ScrollView handle it.
                if !ui.isDraggingDetails {
                    let canDrag = ui.detailsOpen
                        ? (ui.isAtTopOfScroll && value.translation.height > 0)
                        : true
                    guard canDrag else { return }
                    ui.isDraggingDetails = true
                    // Snapshot translation at commit so handoff from scroll → drag has no jump
                    ui.dragCommitTranslation = value.translation.height
                }
                let base = ui.detailsOpen ? ui.detailsOpenOffset : ui.detailsClosedOffset
                let relative = value.translation.height - ui.dragCommitTranslation
                let proposed = base + relative
                ui.detailsOffset = rubberBand(value: proposed,
                                           min: ui.detailsOpenOffset,
                                           max: ui.detailsClosedOffset)
            }
            .onEnded { value in
                onDetailsEnded(value: value)
            }
    }
    
    
    private func onDetailsEnded (value: DragGesture.Value) {
        guard ui.isDraggingDetails else { return }
        ui.isDraggingDetails = false
        let target = nextDetent(for: value, commitTranslation: ui.dragCommitTranslation)
        let signedDistance = target - ui.detailsOffset
        let initialV: CGFloat = abs(signedDistance) > 0.001
            ? value.velocity.height / signedDistance
            : 0
        ui.animateDetails(to: target == ui.detailsOpenOffset, initialVelocity: initialV)
    }

    // Create a rubber band
    private func rubberBand(value: CGFloat, min lo: CGFloat, max hi: CGFloat) -> CGFloat {
        let limit: CGFloat = 100
        let c: CGFloat = 0.7
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
    private func nextDetent(for value: DragGesture.Value, commitTranslation: CGFloat) -> CGFloat {
        let velocity = value.velocity.height          // pts/sec, + = down, - = up
        let translation = value.translation.height - commitTranslation
        let velocityThreshold: CGFloat = 250          // a "flick"
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
