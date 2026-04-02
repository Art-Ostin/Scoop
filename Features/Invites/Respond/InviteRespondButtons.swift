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

/*
 
 struct OpenMessageButton: View {
     let isEdit: Bool
     @Binding var showMessageView: Bool
     
     var body: some View {
         Button {
             showMessageView = true
         } label:  {
             HStack(spacing: 6) {
                 Image(systemName: isEdit ? "square.and.pencil" : "plus")
                     .font(.system(size: 10, weight: .bold))
                 
                 Text(isEdit ? "Edit note" : "Add note")
                     .font(.custom("SFProRounded-Bold", size: 11))
                     .kerning(0.4)
             }
             .foregroundStyle(Color.grayText)
             .padding(.horizontal, 8)
             .padding(.vertical, 4)
             .background {
                 Capsule(style: .continuous)
                     .fill(isEdit ? Color.accent.opacity(0.08) : Color.white.opacity(0.92))
             }
             .overlay {
                 Capsule(style: .continuous)
                     .stroke(isEdit ? Color.accent.opacity(0.18) : Color.grayBackground, lineWidth: 1)
             }
         }
         .offset(y: isEdit ? 0 : 20)
     }
 }
 */



/*
 extension View {
     func respondTextFormat(showTimePopup: Bool) -> some View {
         self
             .font(.footnote)
             .foregroundStyle(.gray)
             .opacity(showTimePopup ? 0.1 : 1)
             .lineLimit(nil)
             .fixedSize(horizontal: false, vertical: true)
             .layoutPriority(1)
             .italic()
             .multilineTextAlignment(.leading)
             .frame(maxWidth: .infinity, alignment:.leading)
     }
 }


 */
//Respond Text View
