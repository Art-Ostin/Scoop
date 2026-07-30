//
//  NewSendInviteCard.swift
//  Scoop Test
//
//  Created by Art Ostin on 27/07/2026.
//

import SwiftUI

struct SendInviteContainer: View {
    
    //Injected Properties
    let images: [UIImage]
    let name: String
    
    @Binding var showInvite: Bool
    
    @State var vm: TimeAndPlaceViewModel

    let onSendInvite: (EventFieldsDraft) -> ()
    let declineProfile: () -> ()
    
    //Local Properties
    @State var ui = TimeAndPlaceUIState()
    
    var body: some View {
        ZStack {
            InvitePopupBackground()
            
            VStack(spacing: 0) {
                inviteCard
                BottomBackButton(visible: !(ui.showConfirmScreen ?? false)) { showInvite = false }
            }
        }
        .animation(.transition, value: ui.showConfirmScreen)
        
        .fullScreenCover(isPresented: $ui.showMapView) { MapView(defaults: vm.defaults, eventLocation: $vm.event.place) }
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
        .sheet(isPresented: $ui.showMessageScreen) {addMessageView}
    }
}

//Top Level Views
extension SendInviteContainer {

    private var inviteCard: some View {
        VStack(spacing: Spacing.hairline) {
            imageSection
            inviteDetailsPager
        }
        .modifier(InviteCardBackground(isConfirming: ui.showConfirmScreen == true))
    }
    
    private var imageSection: some View {
        InviteImageCarousel(
            inviteHasChanges: vm.event.hasChanges,
            isInvite: false, //Sending, not responding — keeps the name overlay and page dots
            name: name,
            images: images,
            isCompact: ui.showConfirmScreen == true,
            showConfirmScreen: $ui.showConfirmScreen,
            showInfoScreen: $ui.showInfoScreen,
            declineProfile: declineProfile,
            clearInvite: { withAnimation(.transition) { vm.deleteEventDefault() } }
        )
    }

    private var inviteDetailsPager: some View {
        VStack(spacing: 0) {
            TwoPageScrollView(
                showSecondScreen: $ui.showConfirmScreen,
                scrollProgress: .constant(0),
                screen1: { timeAndPlacePage },
                screen2: { confirmationPage }
            )
            actionButton
        }
    }
}

//Different Views and Components
extension SendInviteContainer {
    
    private var actionButton: some View {
        let isConfirming = ui.showConfirmScreen == true
        let buttonText = isConfirming ? "Confirm & Send" : "Invite \(name)"
        
        return WideActionButton(text: buttonText, isActive: vm.event.isComplete, showShadow: false) {
            if isConfirming {
                onSendInvite(vm.event)
            } else {
                ui.showConfirmScreen = true
            }
        }
        .padding(.top, isConfirming ? Spacing.md : 0)
        .padding(.horizontal, Spacing.margin)
    }
    
    private var timeAndPlacePage: some View {
        TimeAndPlacePage(ui: ui, draft: $vm.event, showMessageScreen: $ui.showMessageScreen)
            .containerRelativeFrame(.horizontal)
    }
    
    @ViewBuilder
    private var confirmationPage: some View {
        if let inviteSummary = InviteSummary(draft: vm.event) {
            ConfirmContainer(
                event: inviteSummary,
                name: name,
                isCard: false,
                timeOpen: ui.delayedTimePopupOpen,
                showMessageScreen: $ui.showMessageScreen) {
                    StaticTimeRow(proposedTimes: inviteSummary.time)
                } showInfo: {
                    ui.showInfoScreen = true
                }
        }
    }
    
    private var addMessageView: some View {
        AddMessageView(
            message: $vm.event.message,
            isRespondMessage: false,
            eventType: $vm.event.type
        )
    }
}
