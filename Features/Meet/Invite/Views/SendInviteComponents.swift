//
//  TimeAndPlaceComponents.swift
//  Scoop Test
//
//  Created by Art Ostin on 16/06/2026.
//

import SwiftUI


//Logic for Clear and Info Buttons
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
        .opacity(ui.timePopupOpen ? 0.2 : 1)
        .animation(.snappy(duration: 0.2), value: ui.timePopupOpen)
    }
    
    var clearButton: some View {
        Button {
            //One animation owns the whole clear so every row's content cross-fades together.
            withAnimation(.easeInOut(duration: 0.2)) { deleteEventDefault() }
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
        !draft.time.dates.isEmpty || draft.place != nil || draft.type != .socialMeet || draft.message != nil
    }
    
}

//Logic for the inviteButton
extension SendInviteContainer {
    
    func addTimePopupDelay() async {
        let isOpen = ui.timePopupOpen
        try? await Task.sleep(for: isOpen ? .milliseconds(150) : .milliseconds(40))
        ui.timePopupOpenDelayed = isOpen
    }
    
    func addTypePopupDelay() async {
        let isOpen = ui.typePopupOpen
        try? await Task.sleep(for: isOpen ? .milliseconds(150) : .milliseconds(40))
        ui.typePopupOpenDelayed = isOpen
    }
    
    @ViewBuilder
    var sendInviteButton: some View {
    let isValid = !ui.showConfirmPopup &&  !draft.time.dates.isEmpty && draft.place != nil
    let noPopup = !ui.timePopupOpenDelayed && !ui.typePopupOpenDelayed
        
    //Don't want glass button when not valid here, as it gives shadow and looks poor. (So given placehodler field)
        if isValid && noPopup { //using delay as makes it smoother
        sendInviteValidButton
    } else {
        sendInvitePlaceholder
    }
}
    
    private var sendInviteValidButton: some View {
        ActionButton(text: "Send Invite", isValid: true, showShadow: false, hPadding: 44) {
            if let requestConfirm {
                requestConfirm(onSendInvite)
            } else {
                ui.showConfirmPopup = true
            }
        }
    }    
    
    @ViewBuilder
    private var sendInvitePlaceholder: some View {
        Text("Send Invite")
            .font(.body(18, .bold))
            .padding(.horizontal, 44)
            .frame(height: 44)
            .foregroundStyle(.white)
            .background(Color.grayBackground, in: Capsule())
    }
    
    var cardMargin: CGFloat {
        var margin = Self.screenMargin
        return margin
    }
}


//Logic for increasing width and padding of elements




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
