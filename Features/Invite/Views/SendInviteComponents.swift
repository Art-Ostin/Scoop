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


//Logic for increasing width and padding of elements
extension SendInviteContainer {

    var cardMargin: CGFloat {
        var margin = Self.screenMargin
        
        //1. Decrease if message lines is 1 and more if 3
        if ui.messageLineCount >= 2 { margin -= 2 }
        if ui.messageLineCount == 3 {margin -= 2}
        
        //2. Decrease if times 2 or 3
//        if draft.time.dates.count >= 2 { margin -= 2 }
        if draft.time.dates.count == 3 { margin -= 2 }
        
        //3. if time is greater than 1 and place added decrease
        if draft.place != nil && draft.time.dates.count >= 2 { margin -= 2 }
        return margin
    }

    //2. The Vertical padding for the selectType Row
    //Lines to lay out against; 0 the instant the message is empty so clearing resolves in one render.
    private var typeMessageLines: Int {
        let hasMessage = !(draft.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasMessage ? ui.messageLineCount : 0
    }

    var typeTopPadding: CGFloat {
        if typeMessageLines == 0 {
            32
        } else if typeMessageLines == 1 {
            26
        } else {
            22
        }
    }

    var typeBottomPadding: CGFloat {
        typeMessageLines == 0 ? 30 : 14
    }

    //3. The Vertical padding for the selectTime Row
    var timeTopPadding: CGFloat {
        let count = draft.time.dates.count
        if count <= 1 {
            return 30
        } else if count == 2 {
            return 20
        } else {
            return 16
        }
    }

    var timeBottomPadding: CGFloat {
        let count = draft.time.dates.count
        if count <= 1 {
            return 30
        } else if count == 2 {
            return 18
        } else {
            return 14
        }
    }

    //4. The vertical padding for the selectPlace Row
    var placeTopPadding: CGFloat {
        draft.place != nil ? 16 : 30
    }

    var placeBottomPadding: CGFloat {
        draft.place != nil ? 24 : 32
    }
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


/*
 
 
 
 
 
 //Effective message line count: 0 the instant the message is empty, so clearing resolves the
 //margin in one transaction instead of lagging a step behind ui.messageLineCount.
 let messageLines = hasMessageText ? ui.messageLineCount : 0
 //Tighten if 3 days are proposed
 if draft.time.dates.count == 3 { margin -= 2 }
 //Tighten if a place is added alongside 2+ proposed days
 if draft.place != nil && draft.time.dates.count >= 2 { margin -= 2 }
 //Tighten as the message grows (1 line, then again at 3 lines)
 if messageLines >= 1 { margin -= 2 }
 if messageLines == 3 { margin -= 2 }
 return margin
 */
