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
            .onChanged {
                if profileOffsetEnabled {
                    profileOffset = max(0, $0.translation.height)
                }
            }
            .onEnded { value in
                let endSwipe =  max(value.predictedEndTranslation.height, value.translation.height)
                if endSwipe > 100 && profileOffsetEnabled {
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
            .onChanged{
                profileOffsetEnabled = false
                detailsOffset =  $0.translation.height
            }
            .onEnded {value in
                let endUpSwipe =  min(value.predictedEndTranslation.height, value.translation.height)
                let endDownSwipe = max(value.predictedEndTranslation.height, value.translation.height)
                
                let openDetailsThresh: CGFloat = -100
                let closeDetailsThresh: CGFloat = 100
                
                if endUpSwipe < openDetailsThresh {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        detailsOpen = true
                    }
                } else if endDownSwipe > closeDetailsThresh {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        detailsOpen = false
                    }
                }
                withAnimation(.spring()) { detailsOffset = 0}
                Task {
                    try? await Task.sleep(for: .seconds(0.3))
                    profileOffsetEnabled = true
                }
            }
    }
}

