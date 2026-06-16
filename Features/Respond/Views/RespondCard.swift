//
//  NewRespondAcceptCard.swift
//  Scoop Test
//
//  Created by Art Ostin on 12/06/2026.
//

import SwiftUI

struct RespondCard: View {
    
    //1. Fetch from vm, the respond draft, what respond mode its in etc.
    @Bindable var vm: RespondViewModel
    
    //2. UI holds which views, and popups are showing
    @Bindable var ui: NewRespondUIState
    
    //3. Actions are controlled in the container so passed up
    @Binding var confirmNewTimePopup: Bool
    @Binding var confirmAcceptInvite: Bool
    let onDecline: () -> ()
    
    
    var body: some View {
        VStack(spacing: 22) {
            respondTitle
            timeAndPlaceSection
            actionSection
        }
        .modifier(RespondCardBackground())
    }
}

//Logic for Title
extension RespondCard {
    
    private var respondTitle: some View {
        HStack(spacing: 12) {
            titleNameAndPhoto
            Spacer()
            EventTypeButton(type: .drink, showInfo: $ui.showMeetInfo)
        }
        .layoutPriority(1)
    }
    
    private var titleNameAndPhoto: some View {
        HStack(spacing: 12) {
            CirclePhoto(image: vm.image, showShadow: false, height: 25).offset(x: -2)
            Text("Meet \(vm.respondDraft.originalInvite.event.otherUserName)")
                .font(.title(22))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

//Logic for time and Place
extension RespondCard {
    
    private var timeAndPlaceSection: some View {
        VStack(spacing: 18) {
            timeRow
            placeRow
        }
        .font(.body(18, .bold))
    }
    
    @ViewBuilder
    private var timeRow: some View {
        if let date = vm.respondDraft.originalInvite.selectedDay {
            Text(FormatEvent.dayAndTime(date, withHour: true))
       }
    }
    
    @ViewBuilder
    private var placeRow: some View {
        let location = vm.respondDraft.originalInvite.event.location
        Button {
            MapsRouter.openMaps(defaults: vm.defaults, item: location.mapItem, withDirections: true)
        } label: {
            Text(location.name ?? "LocationEvent")
                .foregroundStyle(Color.appGreen)
        }
        .shrinkButton(shadow: nil)
    }
}

//Logic for Buttons
extension RespondCard {
        
    private var actionSection: some View {
        HStack {
            declineButton
            Spacer()
            acceptButton
        }
        .padding(.top, 4) //As Image in title, to look equal distance from 'meeting x' and buttons add extra padding.
    }
        
    private var acceptButton: some View {
        let isModified = vm.respondDraft.respondType != .original
        let isValid = vm.respondDraft.originalInvite.selectedDay != nil

        let colour: Color = isModified ? .accent : (isValid ? .appGreen : .grayPlaceholder)

        return ScoopButton(style: .tinted(colour, shadow: nil), shape: .rect(cornerRadius: 16)) {
            if isModified {
                confirmNewTimePopup = true
            } else {
                confirmAcceptInvite = true
            }
        } label: {
            Text(isModified ? "Invite with new time" + "s" : "Accept")
                .foregroundStyle(Color.white)
                .font(.body(isModified ? 14 : 16, .bold))
                .frame(width: 135)
                .frame(height: 40)
        }
    }
    
    private var declineButton: some View {
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

//Card Background
struct RespondCardBackground: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .inviteCardBackground() //Slight green tint for shadow
    }
}


//InviteCardBackground. used for the SendInvite, AcceptInvite popupCards so put in view extension
extension View {
    func inviteCardBackground() -> some View {
        self
            .background(Color.appCanvas, in: .rect(cornerRadius: 30))
            .rectangleStroke(radius: 30, lineWidth: 1, color: .grayBackground)
            .compositingGroup()
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
            .shadow(color: .black.opacity(0.04), radius: 20, x: 0, y: 0)
            .morphCardAnchor() //Sets it as destination view
    }
}
