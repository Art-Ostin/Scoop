//
//  TimeAndPlaceComponents.swift
//  Scoop Test
//
//  Created by Art Ostin on 16/06/2026.
//

import SwiftUI


//The Clear and Info Buttons
extension SendInviteContainer {
    
    //1. Clear and Info Button Logic
    var clearAndInfoButtons: some View {
        HStack {
            if hasDraftChanges { clearButton}
            Spacer()
            infoButton
        }
        .offset(y: -4)
        .padding(.horizontal, -4)
    }
    
    var clearButton: some View {
        Button {
            deleteEventDefault()
        } label: {
            Image(systemName: "trash")
                .font(.body(12, .regular))
                .foregroundStyle(Color (red: 0.87, green: 0.87, blue: 0.87))
                .offset(y: 1)
        }
        .growButton()
    }
    
    var infoButton: some View {
        Button {
            ui.showInfoScreen.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.body(12, .medium))
                .foregroundStyle(Color(red: 0.83, green: 0.83, blue: 0.83))
        }
        .growButton()
    }
    
    var hasDraftChanges: Bool {
        !draft.time.dates.isEmpty || draft.place != nil || draft.type != .drink || draft.message != nil
    }
    
}

//Logic for the inviteButton
extension SendInviteContainer {
    @ViewBuilder
    var sendInviteButton: some View {
    let isValid = !ui.showConfirmPopup &&  !draft.time.dates.isEmpty && draft.place != nil
    
    //Don't want glass button when not valid here, as it gives shadow and looks poor. (So given placehodler field)
    if isValid && !ui.popupOpen {
        sendInviteValidButton
    } else {
        sendInvitePlaceholder
    }
}
    
    private var sendInviteValidButton: some View {
        ActionButton(text: "Send Invite", isValid: true, showShadow: false) {
            if let requestConfirm {
                requestConfirm(onSendInvite)
            } else {
                ui.showConfirmPopup = true
            }
        }
    }
    
    private var sendInvitePlaceholder: some View {
        Text("Send Invite")
            .font(.body(18, .bold))
            .padding(.horizontal, 36)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(Color.grayBackground, in: .rect(cornerRadius: 24))
    }
}

//Logic for increasing width
extension SendInviteContainer {
    
    //Max Inset is 26. Min Inset is 16. Things that expand it
    /*
     1 line message
     2 line message
     3 line message
     
     2 proposed times
     3 proposed times
     
     a place is added
     */
    
}




//Used througout code
extension View {
    func inviteTypeText(_ detailFont: DetailFont) -> some View {
        Text(detailFont.rawValue.capitalized)
            .font(.body(13, .regular))
            .foregroundStyle(Color(red: 0.70, green: 0.70, blue: 0.75))
    }
}
enum DetailFont: String {
    case when, `where`, what
}

