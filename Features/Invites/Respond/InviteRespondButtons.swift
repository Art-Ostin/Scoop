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
            Text(isModified ? "Invite with new time" + "s" : "Accept")
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

struct AddMessageButton: View {

    @Binding var showMessageScreen: Bool
    
    var body: some View {
        Button {
            showMessageScreen = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName:"plus")
                    .font(.system(size: 10, weight: .bold))
                
                Text("Add note")
                    .font(.custom("SFProRounded-Medium", size: 11))
                    .kerning(0.4)
            }
            .foregroundStyle(Color.grayText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.92))
            }
            .stroke(24, lineWidth: 1, color: Color.grayBackground)
            .surfaceShadow(.floating, strength: 0.5)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(.rect)
        }
        .offset(y: 20)
    }
}
