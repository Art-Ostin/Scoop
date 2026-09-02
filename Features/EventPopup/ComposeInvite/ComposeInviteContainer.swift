//
//  ComposeInviteContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

struct ConfirmInviteContainer: View {
    
    @State var vm: ComposeInviteViewModel
    @State var ui = ComposeInviteUIState()
    
    let invite: InviteSummary
    
    let openInfo: () -> ()
    
    var body: some View {
        
        EventTypeTimePlace(invite: invite, actionsBelow: true, openInfo: openInfo)
        
        
        
    }
}

extension ConfirmInviteContainer {
    
    
    @ViewBuilder
    private var inviteDetailsPager: some View {
        VStack(spacing: 0) {
            TwoPageScrollView(
                showSecondScreen: $ui.showConfirmScreen,
                scrollProgress: .constant(0),
                reflowAnimation: vm.event.hasChanges ? .transition : .dissolve, //An emptied draft is a clear
                screen1: { ComposeInviteContainer(ui: $ui, draft: $vm.event) },
                screen2: { confirmEventView }
            )
            .modifier(InviteSeamWash(tint: palette.secondaryText))
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
}



//Set up the image section for the scrollView
struct SendInviteImagePager: View {
    
    
    var body: some View {
        
    }
}

struct ComposeInviteContainer: View {
    
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










