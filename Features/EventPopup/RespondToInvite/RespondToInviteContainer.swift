//
//  RespondToInviteContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 02/09/2026.
//

import SwiftUI

struct RespondToInviteContainer: View {
    //Injected Properties
    @State var vm: RespondViewModel
    @State var ui = RespondUIState()
    @State var composeUI = ComposeInviteUIState()
    
    @Binding var showInvite: Bool
    
    let images: [UIImage]
    let respond: (ProfileResponse) -> ()
    
    var type: ResponseType { vm.respondDraft.respondType }
    
    var body: some View {
        ZStack {
            EventBackdropV2()
            VStack(spacing: 60) {
                VStack(spacing: 0) {
                    imagePager
                    eventInfoSection
                    actionSection
                }
                .modifier(EventCardSurfaceV2())
                EventDismissButton(visible: !isConfirmNewEvent) { showInvite = false }
            }
        }
        .sheet(isPresented: $composeUI.showInfoScreen) { Text("How it works")}
    }
}

//ImagePager logic
extension RespondToInviteContainer {
    var imagePager: some View {
        EventImagePager(
            images: images,
            title: titleText ,
            showInfo: isComposeInviteScreen ? nil : { composeUI.showInfoScreen = true }
        )
        .overlay(alignment: .topLeading) { isConfirmNewEvent ? backButton : nil }
        .overlay(alignment: .topTrailing) { topRow }
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
            
            if isComposeInviteScreen {
                OptionsMenu(
                    hasChanges: vm.respondDraft.newEvent.hasChanges,
                    onClear: {vm.respondDraft.newEvent = .init()},
                    onDecline: {respond(.decline)}
                )
            }
        }
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
        VStack(spacing: 10) {
            HStack(spacing: 18) {
                if type != .newEvent {declineButton}
                ctaButton
            }
            
            if !isComposeInviteScreen { warningText }
        }
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
    }
    
    var warningText: some View {
        Text("* If they accept, not turning up will get you blocked")
            .font(.body(12.5, .regularItalic))
            .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.55))
            .padding(.horizontal, 12)//Makes it look more aligned
    }
    
}
