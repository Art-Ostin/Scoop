//
//  ProfileDetailsTransition.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

struct ProfileDetailsTransition {

    static let overshootPastSnap: CGFloat = 80   //how far the user can drag past the destination snap
    static let rubberBandFromRest: CGFloat = 85  //how far the user can drag past the resting position

    let isOpen: Bool
    let openOffset: CGFloat
    let offset: CGFloat   //absolute current y offset of the details section

    //Resting offset for the current open/closed state.
    var restPos: CGFloat { isOpen ? openOffset : 0 }

    //Signed distance from rest. Negative = pulled toward open, positive = pulled toward closed.
    var dragDelta: CGFloat { offset - restPos }

    //Range for the absolute offset during a drag, including overshoot past the destination snap and rubber-band past the resting position.
    var offsetRange: ClosedRange<CGFloat> {
        if isOpen {
            return (openOffset - Self.rubberBandFromRest) ... Self.overshootPastSnap
        } else {
            return (openOffset - Self.overshootPastSnap) ... Self.rubberBandFromRest
        }
    }

    var overlayTitleOpacity: Double {
        let oneThird = max(1, abs(openOffset) / 3)
        let progress = abs(dragDelta)
        if isOpen {
            guard progress < oneThird else { return 0 }
            return 1 - min(progress / oneThird, 1)
        }
        guard progress >= oneThird else { return 0 }
        return max((progress - oneThird) / oneThird, 0)
    }


    //Details open from 0% to 100%. Many transition occur from 0% (start) to 100% (end) needed at same rate.
    //Function takes start and end value of transition, and make it transition at same rate as % details drag done.
    func interpolate(from start: CGFloat = 0, to end: CGFloat) -> CGFloat {
        let denom = max(abs(openOffset), 0.0001)
        let t = min(abs(dragDelta) / denom, 1)
        let delta = (end - start) * t
        let base = isOpen ? end : start
        let dragging = (isOpen && dragDelta > 0) || (!isOpen && dragDelta < 0)
        guard dragging else { return base }
        return isOpen ? base - delta : base + delta
    }
}
