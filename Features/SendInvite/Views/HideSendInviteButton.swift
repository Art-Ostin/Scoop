//
//  HideSendInviteButton.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

//One definition for the flight copy and the settled carousel, so the settle handoff renders identically.
struct HideSendInviteButton: View {
    let action: () -> Void

    var body: some View {
        ScoopButton(style: .clearGlass, shape: Capsule(style: .continuous), action: action) {
            HStack(spacing: 6) {
                Text("Hide")
                    .font(.body(13, .bold))

                Image(systemName: "chevron.up")
                    .offset(y: -0.5)
            }
            .font(.body(12, .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}

#Preview {
    HideSendInviteButton(action: {})
}
