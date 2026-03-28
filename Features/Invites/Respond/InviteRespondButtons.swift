//
//  InviteRespondButtons.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct AcceptButton: View {
    
    var isModified: Bool = false
    let onAccept: () -> Void
    var body: some View {
        Button {
            onAccept()
        } label: {
            Text(isModified ? "Invite With Your Times" : "Accept")
                .foregroundStyle(Color.white)
                .font(.body(isModified ? 14 : 16, .bold))
                .frame(width: 135)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(isModified ? Color.accent : Color.appGreen)
                )
        }
    }
}

struct DeclineButton: View {
    
    let onDecline: () -> Void
    
    var body: some View {
        Button {
            onDecline()
        } label: {
            Text("Decline")
                .font(.body(16, .bold))
                .foregroundStyle(Color(red: 0.36, green: 0.36, blue: 0.36))
                .frame(width: 135)
                .frame(height: 40)
                .stroke(16, lineWidth: 1.5, color: Color(red: 0.84, green: 0.84, blue: 0.84))
        }
    }
}

