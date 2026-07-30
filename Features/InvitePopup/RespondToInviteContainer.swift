//
//  RespondContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/07/2026.
//

import SwiftUI

struct RespondInviteContainer: View {
    
    let images: [UIImage]
    
    @State var vm: RespondViewModel
    @State var timeAndPlaceVM: TimeAndPlaceViewModel

    @Binding var showInvitePopup: EventProfile?
    
    let respond: (ProfileResponse) -> ()
    
    @State var ui = RespondUIState()
    @State var timeAndPlaceUI = TimeAndPlaceUIState()
    
    var createEventScreen: Bool {
        (vm.respondDraft.respondType == .newEvent && !(timeAndPlaceUI.showConfirmScreen ?? true))
    }
    
    var body: some View {
        
        ZStack {
            Rectangle() //Full Bleed
                .fill(Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                title
                inviteCard
                BottomBackButton { showInvitePopup = nil }
            }
            .padding(.top, createEventScreen ? 40 : 48)
        }
        .fullScreenCover(isPresented: $timeAndPlaceUI.showInfoScreen) {
            Text("How It works")
        }
    }
}

extension RespondInviteContainer {
    
    private var title: some View {
        Text("Respond")
            .font(.title(18, .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
    
    private var inviteCard: some View {
        VStack(spacing: Spacing.hairline) {
            imageCarousel
            inviteDetailsSection
        }
        .modifier(InviteCardBackground(isConfirming: true, isInvite: true))
    }
    
    private var inviteDetailsSection: some View {
        VStack(spacing: 0) {
            confirmInvitePage
            actionMenu
        }
    }
    
    
    private var confirmInvitePage: some View {
        let inviteSummary = InviteSummary(event: vm.respondDraft.originalInvite.event)
        
        return ConfirmContainer(
            event: inviteSummary,
            name: vm.profile.name,
            isCard: false,
            timeOpen: timeAndPlaceUI.delayedTimePopupOpen,
            showMessageScreen: $timeAndPlaceUI.showMessageScreen) {
                DynamicTimeRow(draft: $vm.respondDraft, timePopupOpen: timeAndPlaceUI.popupBinding(.time))
            } showInfo: {
                timeAndPlaceUI.showInfoScreen = true
            }

    }
    
    private var imageCarousel: some View {
        InviteImageCarousel(
            inviteHasChanges: vm.respondDraft.newEvent.hasChanges,
            isInvite: true,
            name: vm.profile.name,
            images: images,
            isCompact: vm.respondDraft.respondType != .newEvent || timeAndPlaceUI.showConfirmScreen == true,
            showConfirmScreen: $timeAndPlaceUI.showConfirmScreen,
            showInfoScreen: $timeAndPlaceUI.showInfoScreen,
            declineProfile: {respond(.decline)},
            clearInvite: {timeAndPlaceVM.deleteEventDefault()}
        )
    }
}

extension RespondInviteContainer {
    
    private var actionMenu: some View {

        return HStack(spacing: 18) {
            declineButton
            acceptButton
        }
        .padding(.top, createEventScreen ? 0 : Spacing.md)
        .padding(.horizontal, Spacing.margin)
    }
    
    @ViewBuilder
    private var declineButton: some View {
        if vm.responseType != .newEvent {
            Text("Decline")
                .font(.body(18, .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .capsuleStroke(lineWidth: 1, color: Color(white: 0.75))
                .geometryGroup()
                .shrinkPress {respond(.decline)}
        }
    }
    
    private var acceptButton: some View {
        let type = vm.respondDraft.respondType
        let isActive: Bool = (type == .originalInvite || type == .newTime) ? true : vm.respondDraft.newEvent.isComplete
        
        let text: String = switch type {
        case .originalInvite: "Accept"
        case .newTime:        "Invite with New Times"
        case .newEvent:       createEventScreen ? "Invite \(vm.profile.name)" : "Confirm & Send"
        }
        
        let responseType: ProfileResponse = switch type {
        case .originalInvite: .accepted
        case .newTime: .newTime
        case .newEvent: .accepted
        }
        
        return WideActionButton(text: text, isActive: isActive, showShadow: false) {
            if createEventScreen {
                timeAndPlaceUI.showConfirmScreen = true
            } else {
                respond(responseType)
            }
        }
    }
}
