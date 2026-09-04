//
//  RespondToInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 02/09/2026.
//

import SwiftUI

struct RespondToInviteContainer: View {
    //Injected Properties
    @State var vm: RespondViewModel
    @State var ui = RespondUIState()
    @State var composeUI = ComposeInviteUIState()
    
    let images: [UIImage]
    let respond: (ProfileResponse) -> ()
    
    var type: ResponseType { vm.respondDraft.respondType }
    
    //Card content only: `.eventZoom` draws the backdrop, the white surface and the chevron around it
    var body: some View {
        VStack(spacing: 0) {
            imagePager
            eventInfoSection
            actionSection
        }
        .eventZoomChevronHidden(isConfirmNewEvent) //The confirm screen owns the corner with its back button
        .eventZoomDragLocked(composeUI.typePopupOpen || composeUI.timePopupOpen) //An open menu owns the finger
        .sheet(isPresented: $composeUI.showInfoScreen) { Text("How it works")}
        .animation(.transition, value: composeUI.showConfirmScreen)
        .sheet(isPresented: $composeUI.showMessageScreen) {
            AddMessageView(message: $vm.respondDraft.newEvent.message,
                           isRespondMessage: false,
                           eventType: $vm.respondDraft.newEvent.type)
        }
        .fullScreenCover(isPresented: $composeUI.showMapView) {
            MapView(defaults: vm.defaults, eventLocation: $vm.respondDraft.newEvent.place)
        }
    }
}

//ImagePager logic
extension RespondToInviteContainer {
    var imagePager: some View {
        EventImagePager(images: images, title: titleText, showsPageDots: !isConfirmNewEvent)
        //Under the flying cover until the hand-off: popped in then, never cut in
        .overlay(alignment: .topLeading) { backButton.eventZoomBandChrome(visible: isConfirmNewEvent) }
        .overlay(alignment: .topTrailing) { topRow.eventZoomBandChrome() }
    }
    
    var titleText: String {
        switch type {
        case .originalInvite: "\(vm.profile.name)'s Invite"
        case .newTime: "Invite \(vm.profile.name)"
        case .newEvent: composeUI.showConfirmScreen == true ? "Confirm Invite" : "Invite \(vm.profile.name)"
        }
    }
    
    var backButton: some View {
        EventBackButton(showConfirmScreen: $composeUI.showConfirmScreen)
    }
    
    var topRow: some View {
        HStack(spacing: 6) {
            NewEventToggleButton(
                responseType: $vm.respondDraft.respondType,
                showConfirmScreen: $composeUI.showConfirmScreen
            )
        }
        .animation(.transition, value: isComposeInviteScreen)
    }
    
    var isComposeInviteScreen: Bool { type == .newEvent && composeUI.showConfirmScreen != true }
    var isConfirmNewEvent: Bool { type == .newEvent && composeUI.showConfirmScreen == true }
}


//Event Info Section -> Filling out details and confirm Invite Screen
extension RespondToInviteContainer {
    
    var eventInfoSection: some View {
        ZStack {
            if type == .newEvent {
                inviteDetailsPager
            } else {
                respondToInvite
            }
        }
    }
    
    //Respond To Invite Screen
    var respondToInvite: some View {
        EventTypeTimePlace(
            invite: InviteSummary(event: vm.respondDraft.originalInvite.event),
            respondDraft: $vm.respondDraft,
            actionsBelow: true, //adjusts padding in this view if actions below
            shortSpacing: false,
            largeText: true,
            openInfo: {composeUI.showInfoScreen = true}
        )
    }
    
    //The Compose and Confirm Invite Screens
    private var inviteDetailsPager: some View {
        VStack(spacing: 0) {
            TwoPageScrollView(
                showSecondScreen: $composeUI.showConfirmScreen,
                scrollProgress: .constant(0),
                reflowAnimation: vm.respondDraft.newEvent.hasChanges ? .transition : .dissolve, //An emptied draft is a clear
                screen1: { EditTypeTimePlace(ui: $composeUI, draft: $vm.respondDraft.newEvent) },
                screen2: { confirmEventView }
            )
        }
    }
    
    @ViewBuilder
    private var confirmEventView: some View {
        if let invite = InviteSummary(draft: vm.respondDraft.newEvent) {
            EventTypeTimePlace(invite: invite, actionsBelow: true, openInfo: { composeUI.showInfoScreen = true })
        }
    }
}


//Action Button Section
extension RespondToInviteContainer {
    
    var actionSection: some View {
        VStack {
            if !isComposeInviteScreen { warningText }
            HStack(spacing: 18) {
                if type != .newEvent {declineButton}
                ctaButton
            }
        }
        .padding(.bottom, 12)
        .padding(.horizontal, Spacing.margin) //Each page owns the gap above this button
    }
    
    var ctaButton: some View {
        WideActionButton(
            text: ctaText,
            isActive: type != .newEvent || vm.respondDraft.newEvent.isComplete,
            isDimmed: composeUI.typePopupOpen || composeUI.timePopupOpen,
            showShadow: false,
            height: type == .newEvent ? 46 : 48,
            onTap: ctaAction
        )
        .eventZoomDragExclusion() //A press that slides off the button never scrubs the card
    }
    
    var ctaText: String {
        switch type {
        case .originalInvite: "Accept"
        case .newTime: "Propose \n New Times"
        case .newEvent: isComposeInviteScreen ? "Review" : "Invite \(vm.profile.name)"
        }
    }
    
    var ctaAction: () -> Void {
        switch type {
        case .originalInvite:{ respond(.accepted)}
        case .newTime: {respond(.newTime)}
        case .newEvent: isComposeInviteScreen ? { composeUI.showConfirmScreen = true} : {respond(.newInvite)}
        }
    }
    
    var declineButton: some View {
        Text("Decline")
            .font(.body(18, .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .capsuleStroke(lineWidth: 1, color: .borderStrong)
            .geometryGroup()
            .shrinkPress {respond(.decline)}
            .eventZoomDragExclusion()
    }
    
    var warningText: some View {
        Text("* If you accept & don't turn up you may be blocked")
            .font(.body(12.5, .regularItalic))
            .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.55))
    }
    
}


/*
 //            if isComposeInviteScreen {
 //                OptionsMenu(
 //                    hasChanges: vm.respondDraft.newEvent.hasChanges,
 //                    onClear: {vm.respondDraft.newEvent = .init()},
 //                    onDecline: {respond(.decline)}
 //                )
 //            }

 */
