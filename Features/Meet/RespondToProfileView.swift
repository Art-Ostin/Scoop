//
//  RespondToProfileView.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI
import Lottie

struct RespondToProfileView: View {

    let isInvite: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 36) {
            if isInvite {
                Image("Cool Guys")
                Text("Invite Sent")
                    .font(.body(16, .bold))
            } else {
                Image("Monkey")
                Text("Invite Sent")
                    .font(.body(16, .bold))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        .zIndex(10)
        .transition(.opacity.animation(.easeInOut(duration: 0.18)))
    }
}



/*
 
 LottieView(animation: .named("SendAnimation.json"))
     .playbackMode(.playing(.toProgress(1, loopMode: .playOnce)))
     .resizable()
     .scaledToFit()
     .frame(maxWidth: .infinity)
     .frame(height: 250)
     .offset(y: -24)
 */
