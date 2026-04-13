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
    
    let hasEventMessage: Bool
    
    var body: some View {
        Button {
            showMessageScreen = true
        } label : {
            Image("AddMessageIcon")
                .padding(12)
                .contentShape(Rectangle())
                .padding(-12)
                .padding(6)
                .background(
                    Circle()
                        .foregroundStyle(Color.white).opacity(hasEventMessage ? 0.7 : 0.3)
                )
                .stroke(100, lineWidth: 0.5, color: .grayPlaceholder.opacity(0.5))
                .shadow(color: .black.opacity(hasEventMessage ? 0 : 0.05), radius: 1, x: 0, y: 1.5)
        }
    }
}

struct ViewMessageButton: View {
    
    let onTap: () -> ()
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {onTap()}
        } label : {
            Image("FilledMessageIcon")
                .scaleEffect(1.07)
                .padding(6)
                .background(
                    Circle().foregroundStyle(.white).opacity(0.7)
                )
                .overlay {
                    Circle()
                        .strokeBorder(Color.grayPlaceholder.opacity(0.3), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                .contentShape(Rectangle())
                .padding(14)
        }
        .buttonStyle(.plain)
        .padding(-14)
    }
}

struct InviteRespondButton: View {
    
    let type: Event.EventType
    
    let onTap: () -> Void
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                onTap()
            }
        } label: {
            HStack(spacing: 0) {
                Text("\(type.description.emoji)\(type.description.label)")
                    .font(.body(14, .bold))
                
                Image(systemName: "info.circle")
                    .font(.body(8, .medium))
                    .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
                    .offset(y: -3)
            }
            .padding(6)
            .padding(.leading, 2)
            .padding(.trailing, 2)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .foregroundStyle(Color(red: 0.94, green: 0.94, blue: 0.94))
            )
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            .frame(maxWidth: 110, alignment: .trailing)
        }
        .fixedSize(horizontal: true, vertical: false)
        .buttonStyle(.plain)
    }

}

