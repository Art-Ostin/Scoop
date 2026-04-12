//
//  RespondToProfileView.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

enum ProfileResponse {
    case invite
    case accepted
    case declined
}

struct RespondedToProfileView: View {
    let response: ProfileResponse
    
    var body: some View {
        VStack(alignment: .center, spacing: 36) {
            switch response {
            case .invite:
                Image("CoolGuys")
                Text("Invite Sent")
                    .font(.body(16, .bold))
            case .accepted:
                Image("DancingCats")
                Text("Accepted")
                    .font(.body(16, .bold))
                    .foregroundStyle(Color(Color.appGreen))
            case .declined:
                Image("Monkey")
                Text("Declined")
                    .font(.body(16, .bold))
            }
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.18)))
        .colorBackground()
        .zIndex(10)
    }
}
