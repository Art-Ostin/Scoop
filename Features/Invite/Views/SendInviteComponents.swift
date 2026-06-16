//
//  TimeAndPlaceComponents.swift
//  Scoop Test
//
//  Created by Art Ostin on 16/06/2026.
//

import SwiftUI


//Different Buttons file uses
extension SendInviteContainer {
    
    //1. Clear and Info Button Logic
    var clearAndInfoButtons: some View {
        HStack {
            if hasDraftChanges { clearButton}
            Spacer()
            infoButton
        }
        .offset(y: -8)
        .padding(.horizontal, -6)
    }
    
    var clearButton: some View {
        Button {
            deleteEventDefault()
        } label: {
            Text("Clear")
                .font(.body(12, .regular))
                .foregroundStyle(Color (red: 0.8, green: 0.8, blue: 0.8))
                .offset(y: 1) //so inline not on top of info button
        }
        .growButton()
    }
    
    var infoButton: some View {
        Button {
            ui.showInfoScreen.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.body(12, .medium))
                .foregroundStyle(Color(red: 0.7, green: 0.7, blue: 0.7))
        }
        .growButton()
    }
    
    var hasDraftChanges: Bool {
        !draft.time.dates.isEmpty || draft.place != nil || draft.type != .drink || draft.message != nil
    }
    
    //2. Invite Button and valid logic
   var sendInviteButton: some View {
        let isValid = !ui.showConfirmPopup &&  !draft.time.dates.isEmpty && draft.place != nil

       return ActionButton(text: "Send Invite", isValid: isValid, showShadow: false) {
           if let requestConfirm {
               requestConfirm(onSendInvite)
           } else {
               ui.showConfirmPopup = true
           }
       }
    }
    
}


//Used througout code
extension View {
    func inviteTypeText(_ detailFont: DetailFont) -> some View {
        Text(detailFont.rawValue.capitalized)
            .font(.body(14, .regular))
            .foregroundStyle(Color(red: 0.65, green: 0.65, blue: 0.65))
    }
}
enum DetailFont: String {
    case when, `where`, what
}

