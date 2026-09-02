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
        
        VStack {
            imagePager
            inviteDetailsPager
            actionButton
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
            actionButton
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
    
    private var actionButton: some View {
        WideActionButton(
            text: ui.showConfirmScreen == true ? "Send to \(name)" : "Preview",
            isActive: vm.event.isComplete,
            isDimmed: ui.typePopupOpen || ui.timePopupOpen,
            showShadow: false,
            height: 46
        ) {
            if ui.showConfirmScreen == true {  } else { ui.showConfirmScreen = true }
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











