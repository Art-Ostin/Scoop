//
//  InviteButton.swift
//  Scoop
//
//  Created by Art Ostin on 30/05/2026.
//

import SwiftUI


struct InviteButton: View {

    let isInviting: Bool
    let morphId: String
    var isInviteCard: Bool = false

    let action: () -> Void
    
    var body: some View {
        ScoopButton(style: .tinted(isInviting ? Color.accent : Color.successGreen, shadow:  isInviteCard ? nil : .high), shape: Circle(), action: action) {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 40, height: 40)
        }
        .morphSource(id: morphId)//Shares location for morph & hides while morphing
    }
}
