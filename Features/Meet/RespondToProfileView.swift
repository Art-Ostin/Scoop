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
                Image("CoolGuys")
                Text("Invite Sent")
                    .font(.body(16, .bold))
            } else {
                Image("Monkey")
                Text("Declined")
                    .font(.body(16, .bold))
            }
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.18)))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(Color.background)
        .zIndex(10)
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
