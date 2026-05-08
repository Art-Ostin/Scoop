//
//  ProfileDetailsTransition.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

struct ProfileDetailsTransition {

    let isOpen: Bool
    let openOffset: CGFloat
    let offset: CGFloat   //absolute current y offset of the details section

    //Resting offset for the current open/closed state.
    var restPos: CGFloat { isOpen ? openOffset : 0 }

    //Signed distance from rest. Negative = pulled toward open, positive = pulled toward closed.
    var dragDelta: CGFloat { offset - restPos }

    //iOS-style logarithmic rubber-band: 1:1 inside [openOffset, 0], asymptotic resistance outside.
    //Mirrors UIScrollView's overscroll feel — the finger keeps moving but visible offset compresses.
    static func rubberBand(_ overshoot: CGFloat, range: CGFloat, coefficient: CGFloat = 0.55) -> CGFloat {
        guard overshoot != 0, range > 0 else { return 0 }
        let sign: CGFloat = overshoot > 0 ? 1 : -1
        let magnitude = abs(overshoot)
        return sign * (1 - 1 / (magnitude * coefficient / range + 1)) * range
    }

    //Maps a raw (finger-tracked) offset to a rubber-banded offset. Natural travel is [openOffset, 0];
    //anything outside is compressed via rubberBand, so the gesture stays continuous past the snap points.
    static func rubberBandedOffset(_ raw: CGFloat, openOffset: CGFloat) -> CGFloat {
        let range = max(abs(openOffset), 1)
        if raw > 0 {
            return rubberBand(raw, range: range)
        } else if raw < openOffset {
            return openOffset + rubberBand(raw - openOffset, range: range)
        }
        return raw
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
