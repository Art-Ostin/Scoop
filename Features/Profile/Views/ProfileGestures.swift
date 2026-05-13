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
                detailsOffset = base + $0.translation.height
            }
            .onEnded { value in
                detailsEndDrag(value)
            }
    }


    private func detailsEndDrag(_ value: DragGesture.Value) {
        let currentOffset = value.translation.height

        //To compute how much more needed for offset to open
        let offsetToOpen: CGFloat = (detailsOpenOffset - currentOffset)

        //To compute how much more needs to be offset to close
        let offsetToClose: CGFloat = ( detailsOpenOffset + currentOffset)

        let threshold: CGFloat = 100
        let drag = value.predictedEndTranslation.height

        withAnimation(.smooth(duration: 0.35)) {
            //1. To Close Details
            if detailsOpen, drag > threshold {
                detailsOffset += offsetToClose
                detailsOpen = false
            //2. To Open Details
            } else if !detailsOpen, drag < -threshold {
                detailsOffset += offsetToOpen
                detailsOpen = true
            } else {
                if detailsOpen {
                    detailsOffset = detailsOpenOffset
                } else {
                    detailsOffset = detailsClosedOffset
                }
            }
        }
    }
}


/*
 detailsOpen = true
 */




/*
 let dragUpThresh: CGFloat = -100
 let dragDownThresh: CGFloat = 100
 
 let drag = value.translation.height
 let predictedDrag = value.predictedEndTranslation.height
 
 let dragUp: CGFloat = min(drag, predictedDrag)
 let dragDown: CGFloat = max(drag, predictedDrag)
 
 let animation: Animation = .smooth(duration: 0.35)

 withAnimation(animation) {
     if detailsOpen, dragDown > dragDownThresh {
         detailsOpen = false
     } else if !detailsOpen, dragUp < dragUpThresh {
         detailsOpen = true
     }
//                 detailsOffset = 0 //key Major bug!!! updating this mid transition creates issues.
 }
 
//                        Task {
//                            try? await Task.sleep(for: .seconds(0.4))
//                            enableProfileOffset = true
//                        }
}

 */
