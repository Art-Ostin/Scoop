//
//  ComposeInviteContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

struct ComposeInviteContainer: View {
    
    @State var vm: ComposeInviteViewModel
    @State var ui = ComposeInviteUIState()

    let images: [UIImage]
    let name: String

    var body: some View {
        ZStack {
            EventBackdropV2()
            VStack {
                imagePager
                inviteDetailsPager
                actionButtonAndWarning
            }
            .modifier(EventCardSurfaceV2())
        }
    }
}

extension ComposeInviteContainer {
    
    @ViewBuilder
    private var inviteDetailsPager: some View {
        VStack(spacing: 0) {
            TwoPageScrollView(
                showSecondScreen: $ui.showConfirmScreen,
                scrollProgress: .constant(0),
                reflowAnimation: vm.event.hasChanges ? .transition : .dissolve, //An emptied draft is a clear
                screen1: { EditTypeTimePlace(ui: $ui, draft: $vm.event) },
                screen2: { confirmEventView }
            )
        }
    }
    
    @ViewBuilder
    private var confirmEventView: some View {
        Group {
            if let invite = InviteSummary(draft: vm.event) {
                EventTypeTimePlace(invite: invite, actionsBelow: true, openInfo: { ui.showInfoScreen = true })
            }
        }
    }
    
    private var actionButtonAndWarning: some View {
        let isConfirm = ui.showConfirmScreen == true
        
        return VStack {
            WideActionButton(
                text: isConfirm ? "Send to \(name)" : "Preview",
                isActive: vm.event.isComplete,
                isDimmed: ui.typePopupOpen || ui.timePopupOpen,
                showShadow: false,
                height: 46
            ) {
                if isConfirm { } else { ui.showMessageScreen = true}
            }
            
            if isConfirm {
                Text("* If they accept, not turning up will get you blocked")
                    .font(.body(12.5, .regularItalic))
                    .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.55))
                    .padding(.horizontal, 12)//Makes it look more aligned
            }
        }
        .padding(.horizontal, Spacing.margin) //Each page owns the gap above this button
    }
    
    private var imagePager: some View {
        let isConfirm = ui.showConfirmScreen == true
        return EventImagePager(
            images: images,
            title: isConfirm ? "Confirm Invite" : "Invite \(name)" ,
            showInfo: isConfirm ? nil : { ui.showInfoScreen = true })
    }
}

struct EditTypeTimePlace: View {
    
    @Binding var ui: ComposeInviteUIState
    
    @Binding var draft: EventFieldsDraft
    
    var body: some View {
        VStack {
            InviteTypeRow(
                eventType: $draft.type,
                message: $draft.message,
                showMessageScreen: $ui.showMessageScreen,
                showTypeDropDown: $ui.typePopupOpen,
                timeDropDownOpen: ui.timePopupOpen
            )
            
            VeryLightDivider()
            
            InviteTimeRow(
                proposedTimes: $draft.time,
                timeisOpen: $ui.timePopupOpen,
                typePopUpOpen: ui.typePopupOpen
            )
            
            VeryLightDivider()
            
            InvitePlaceRow(
                popupOpen: ui.typePopupOpen || ui.timePopupOpen,
                location: $draft.place,
                showMapView: $ui.showMapView
            )
        }
        .padding(24)
        .padding(.top, -4)//Only 20 padding on the top
    }
}
