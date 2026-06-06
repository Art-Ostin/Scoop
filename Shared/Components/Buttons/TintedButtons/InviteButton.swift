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
    var isInviteCard: Bool = false
    
    var body: some View {
        ScoopButton(style: .tinted(isInviting ? Color.accent : Color.appGreen, shadow:  isInviteCard ? nil : .high), shape: Circle(), action: action) {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 40, height: 40)
        }
        .inviteIconAnchor(id: morphId)//Shares location for morph
    }
}
