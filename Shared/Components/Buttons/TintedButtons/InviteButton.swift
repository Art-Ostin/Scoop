//
//  InviteButton.swift
//  Scoop Test
//
//  Created by Art Ostin on 30/05/2026.
//

import SwiftUI


struct InviteButton: View {

    let isInviting: Bool
    let morphId: String
    let action: () -> Void
    var body: some View {
        
        Button {
            action()
        } label: {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(.white)
                .buttonBackground(Circle(), color: .accent)
        }
        .shrinkButton(shadow: .medium)
        .inviteIconAnchor(id: morphId)//Shares location for morph
    }
}
