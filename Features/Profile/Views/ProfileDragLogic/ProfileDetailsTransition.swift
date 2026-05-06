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
    let dragOffset: CGFloat

    var dragRange: ClosedRange<CGFloat> {
        let limit = openOffset - Self.overshootPastSnap
        return isOpen ? (-Self.rubberBandFromRest ... -limit) : (limit ... Self.rubberBandFromRest)
    }

    var sectionOffset: CGFloat {
        dragOffset + (isOpen ? openOffset : 0)
    }

    var overlayTitleOpacity: Double {
        let oneThird = max(1, abs(openOffset) / 3)
        let progress = abs(dragOffset)
        if isOpen {
            guard progress < oneThird else { return 0 }
            return 1 - min(abs(dragOffset) / oneThird, 1)
        }
        guard progress >= oneThird else { return 0 }
        return max((progress - oneThird) / oneThird, 0)
    }
    
    //Details open from 0% to 100%. Many transition occur from 0% (start) to 100% (end) needed at same rate.
    //Function takes start and end value of transition, and make it transition at same rate as % details drag done.
    func interpolate(from start: CGFloat = 0, to end: CGFloat) -> CGFloat {
        let denom = max(abs(openOffset), 0.0001)
        let t = min(abs(dragOffset) / denom, 1)
        let delta = (end - start) * t
        let base = isOpen ? end : start
        let dragging = (isOpen && dragOffset > 0) || (!isOpen && dragOffset < 0)
        guard dragging else { return base }
        return isOpen ? base - delta : base + delta
    }
}
