//
//  ProfileGestures.swift
//  Scoop Test
//
//  Created by Art Ostin on 09/05/2026.
//

import SwiftUI


extension ProfileView {
    
    var profileDrag: some Gesture {
        DragGesture()
            .onChanged {profileOffset = max(0, $0.translation.height)
            }
            .onEnded { value in
                let endSwipe =  max(value.predictedEndTranslation.height, value.translation.height)
                if endSwipe > 100 {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        profileOffset = 0
                        selectedProfile = nil
                    }
                } else {
                    withAnimation(.spring()) { profileOffset = 0 }  // bounce back
                }
            }
    }
    
    var detailsDrag: some Gesture {
        DragGesture()
            .onChanged {
                let base = detailsOpen ? detailsOpenOffset : detailsClosedOffset
                let proposed = base + $0.translation.height
                detailsOffset = rubberBand(value: proposed,
                                           min: detailsOpenOffset,
                                           max: detailsClosedOffset)
            }
            .onEnded { value in
                let target = nextDetent(for: value)
                let signedDistance = target - detailsOffset
                // initialVelocity is in "fractions of remaining distance / sec".
                // Normalize by actual signed distance instead of a fixed 800.
                let initialV: CGFloat = abs(signedDistance) > 0.001
                    ? value.velocity.height / signedDistance
                    : 0
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 25, initialVelocity: initialV)) {
                    detailsOpen = (target == detailsOpenOffset)
                    detailsOffset = target
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

        var willOpen = detailsOpen
        if abs(velocity) > velocityThreshold {
            willOpen = velocity < 0
        } else if detailsOpen, translation > distanceThreshold {
            willOpen = false
        } else if !detailsOpen, translation < -distanceThreshold {
            willOpen = true
        }
        return willOpen ? detailsOpenOffset : detailsClosedOffset
    }
}
