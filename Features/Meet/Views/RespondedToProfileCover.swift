//
//  RespondToProfileView.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

enum ProfileResponse {
    case accepted
    case newTime
    case newInvite
    case decline
}

struct RespondedToProfileCover: View {
    let responseType: ProfileResponse
    
    var body: some View {
        VStack(alignment: .center, spacing: Spacing.xl) {
            switch responseType {
            case .accepted:
                Image("DancingCats")
                Text("Accepted")
                    .font(.body(16, .bold))
                    .foregroundStyle(Color.successGreen)
            case .newTime:
                Image("DancingCats")
                Text("NEW TIME SENT")
                    .font(.body(16, .bold))
                    .foregroundStyle(Color.accent)
            case .newInvite:
                Image("CoolGuys")
                Text("Invite Sent")
                    .font(.body(16, .bold))
            case .decline:
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
