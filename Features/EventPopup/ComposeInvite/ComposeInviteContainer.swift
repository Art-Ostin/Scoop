//
//  ComposeInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

struct ComposeInviteContainer: View {
    
    @State var vm: ComposeInviteViewModel
    @State var ui = ComposeInviteUIState()

    let images: [UIImage]
    let name: String
    let onSend: (EventFieldsDraft) -> Void //The confirm screen's Send: the parent sends and closes the card

    //Card content only: `.eventZoom` draws the backdrop, the white surface and the chevron around it
    var body: some View {
        VStack(spacing: 0) {
            imagePager
            inviteDetailsPager
            ctaButton
        }
        .eventZoomChevronHidden(ui.showConfirmScreen == true) //The confirm screen owns the corner
        .eventZoomDragLocked(ui.typePopupOpen || ui.timePopupOpen) //An open menu owns the finger
        .sheet(isPresented: $ui.showInfoScreen) { Text("Event Info Here")}
        .sheet(isPresented: $ui.showMessageScreen) {
            AddMessageView(message: $vm.event.message, isRespondMessage: false, eventType: $vm.event.type)
        }
        .fullScreenCover(isPresented: $ui.showMapView) {
            MapView(defaults: vm.defaults, eventLocation: $vm.event.place)
        }
        .animation(.transition, value: ui.showConfirmScreen)
    }
}

//Logic with the ImagePager
extension ComposeInviteContainer {
    
    private var imagePager: some View {
        let isConfirm = ui.showConfirmScreen == true
        return EventImagePager(images: images, title: isConfirm ? "Confirm Invite" : "Invite \(name)")
        .overlay(alignment: .topLeading) { backButton(visible: isConfirm).eventZoomBandChrome() }
        .overlay(alignment: .topTrailing) { optionsMenu(visible: !isConfirm).eventZoomBandChrome() }
    }
    
    private func optionsMenu(visible: Bool) -> some View {
        OptionsMenu(
            visible: visible,
            hasChanges: vm.event.hasChanges,
            onClear: {vm.event = .init()},
            onDecline: { }
        )
    }
    
    private func backButton(visible: Bool) -> some View {
        EventBackButton(visible: visible, showConfirmScreen: $ui.showConfirmScreen)
    }
}


//Logic with the detailsPager
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
        if let invite = InviteSummary(draft: vm.event) {
            EventTypeTimePlace(invite: invite, actionsBelow: true, openInfo: { ui.showInfoScreen = true })
        }
    }
}



//Logic with the action Button
extension ComposeInviteContainer {
    
    private var ctaButton: some View {
        let isConfirm = ui.showConfirmScreen == true
        
        return VStack {
            if isConfirm { warningMessage }
        
            WideActionButton(
                text: isConfirm ? "Send to \(name)" : "Preview",
                isActive: vm.event.isComplete,
                isDimmed: ui.typePopupOpen || ui.timePopupOpen,
                showShadow: false,
                height: 46,
                onTap: { ctaAction(isConfirm)() }
            )
            .eventZoomDragExclusion()
            
        }
        .padding(.bottom, 16)
        .padding(.horizontal, Spacing.margin) //Each page owns the gap above this button
    }
    
    private var warningMessage: some View {
        Text("* If they accept, not turning up will get you blocked")
            .font(.body(12.5, .regularItalic))
            .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.55))
    }
    
    private func ctaAction(_ isConfirm: Bool) -> () -> Void {
        isConfirm
            ? { onSend(vm.event) }
            //A TRANSACTION, not just the scope on the body: the card's own frame — the white
            //surface, the flight's mask, the column that holds it — is laid out ABOVE this view
            //by `.eventZoom`, and an animation scope only ever reaches downward
            : { withAnimation(.transition) { ui.showConfirmScreen = true } }
    }
}


struct EditTypeTimePlace: View {
    
    @Binding var ui: ComposeInviteUIState
    
    @Binding var draft: EventFieldsDraft
    
    var body: some View {
        VStack(spacing: 18) {
            InviteTypeRow(
                eventType: $draft.type,
                message: $draft.message,
                showMessageScreen: $ui.showMessageScreen,
                showInfoScreen: $ui.showInfoScreen,
                showTypeDropDown: $ui.typePopupOpen,
                timePopupOpen: ui.delayedTimePopupOpen
            )
            
            VeryLightDivider()
            
            InviteTimeRow(
                proposedTimes: $draft.time,
                timeisOpen: $ui.timePopupOpen,
                typePopUpOpen: ui.delayedTypePopupOpen
            )
            
            VeryLightDivider()
            
            InvitePlaceRow(
                popupOpen: ui.delayedTypePopupOpen || ui.delayedTimePopupOpen,
                location: $draft.place,
                showMapView: $ui.showMapView
            )
        }
        .padding(24)
        .padding(.top, -4)//Only 20 padding on the top
    }
}
