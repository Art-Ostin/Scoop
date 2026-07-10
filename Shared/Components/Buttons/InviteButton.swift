//
//  InviteButton.swift
//  Scoop
//
//  Created by Art Ostin on 30/05/2026.
//

import SwiftUI


struct InviteButton: View {

    static let diameter: CGFloat = 40

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
                .frame(width: Self.diameter, height: Self.diameter)
        }
    }
}
