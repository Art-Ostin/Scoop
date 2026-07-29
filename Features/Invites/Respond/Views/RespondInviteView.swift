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
    
    
    var body: some View {
        
        ZStack {
            Rectangle() //Full Bleed
                .fill(Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Respond")
                inviteCard
                BottomBackButton { showInvitePopup = nil }
            }
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
            .padding(.horizontal, 12)
    }
    
    private var inviteCard: some View {
        VStack(spacing: 0) {
            imageCarousel
            inviteDetailsSection
        }
        .modifier(InviteCardBackground(isConfirming: true))
    }
    
    private var inviteDetailsSection: some View {
        VStack(spacing: 0) {
            confirmInvitePage
            actionMenu
        }
    }
    
    
    private var confirmInvitePage: some View {
        let inviteSummary = InviteSummary(event: vm.respondDraft.originalInvite.event)
        return ConfirmInvitePage(
            event: inviteSummary,
            name: vm.profile.name,
            showMessageScreen: $timeAndPlaceUI.showMessageScreen
        )
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
        let showWhatWhenWhere: Bool = (vm.respondDraft.respondType == .newEvent && !(timeAndPlaceUI.showConfirmScreen ?? true))

        return HStack(spacing: 18) {
            declineButton
            acceptButton
        }
        .padding(.top, showWhatWhenWhere ? 0 : Spacing.md)
        .padding(.horizontal, Spacing.margin)
    }
    
    @ViewBuilder
    private var declineButton: some View {
        if vm.responseType != .newEvent {
            ScoopButton(style: .tinted(Color.appCanvas, shadow: nil), shape: .capsule) {
                respond(.decline)
            } label: {
                Text("Decline")
                    .font(.body(18, .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .capsuleStroke(lineWidth: 1, color: Color(white: 0.75))
                    .geometryGroup()
            }
        }
    }
    
    private var acceptButton: some View {
        let type = vm.respondDraft.respondType
        
        let isActive: Bool = (type == .originalInvite || type == .newTime) ? true : vm.respondDraft.newEvent.isComplete
        
        let showWhatWhenWhere: Bool = (type == .newEvent && !(timeAndPlaceUI.showConfirmScreen ?? true))
        
        let text: String = switch type {
        case .originalInvite: "Accept"
        case .newTime:        "Invite with New Times"
        case .newEvent:       showWhatWhenWhere ? "Invite \(vm.profile.name)" : "Confirm & Send"
        }
        
        let responseType: ProfileResponse = switch type {
        case .originalInvite: .accepted
        case .newTime: .newTime
        case .newEvent: .accepted
        }
        
        return WideActionButton(text: text, isActive: isActive, showShadow: false) {
            if showWhatWhenWhere {
                timeAndPlaceUI.showConfirmScreen = true
            } else {
                respond(responseType)
            }
        }
    }
}

/*
 struct WideActionButton: View {
     
     let text: String
     let isActive: Bool
     var showShadow: Bool = true

     
     let onTap: () -> ()
         
     var body: some View {
         
         if isActive {
             ScoopButton(style: .tinted(.accent, shadow: showShadow ? .button : nil), shape: .capsule, action: onTap) {
                 label
             }
         } else {
             label
                 .foregroundStyle(Color.white)
                 .background(Color.fillGray, in: .capsule)
         }
     }
     
     private var label: some View {
         Text(text)
             .font(.body(18, .bold))
             .frame(maxWidth: .infinity)
             .frame(height: 48)
             .geometryGroup()
     }
 }

 */
