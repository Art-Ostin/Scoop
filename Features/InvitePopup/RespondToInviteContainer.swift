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
            InvitePopupBackground()
            
            VStack(spacing: 12) {
                inviteCard
                HStack {
                    changeButton
                    BottomBackButton { showInvitePopup = nil}
                }
            }
        }
        .fullScreenCover(isPresented: $timeAndPlaceUI.showInfoScreen) {Text("How It works")}
        .animation(.move, value: vm.responseType)
        .animation(.move, value: createEventScreen)
        .animation(.toggle, value: vm.respondDraft.newEvent.isComplete)
        .sheet(isPresented: $timeAndPlaceUI.showMessageScreen) {addMessageView }
    }
}

extension RespondInviteContainer {
    
    private var changeButton: some View {
        ScoopButton(shape: .capsule) {
            if vm.respondDraft.respondType != .newEvent {
                vm.respondDraft.respondType = .newEvent
            } else {
                vm.respondDraft.respondType = .originalInvite
            }
            timeAndPlaceUI.showConfirmScreen = false
        } label: {
            Group {
                if vm.respondDraft.respondType != .newEvent {
                    Text("New Event")
                } else {
                    Text("Original Invite")
                }
            }
            .font(.body(14, .bold))
            .padding(.horizontal)
            .padding(.top, 6)
        }
    }

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
        .modifier(InviteCardBackground(isConfirming: timeAndPlaceUI.showConfirmScreen == true))
    }
    
    private var inviteDetailsSection: some View {
        VStack(spacing: 0) {
            ZStack {
                if vm.responseType == .newEvent {
                    newEventPager
                } else {
                    confirmInvitePage
                }
            }
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
            isInvite: vm.responseType != .newEvent,
            name: vm.profile.name,
            images: images,
            isCompact: vm.respondDraft.respondType != .newEvent || timeAndPlaceUI.showConfirmScreen == true,
            showConfirmScreen: $timeAndPlaceUI.showConfirmScreen,
            showInfoScreen: $timeAndPlaceUI.showInfoScreen,
            declineProfile: {respond(.decline)},
            clearInvite: {timeAndPlaceVM.deleteEventDefault()}
        )
    }
    
    private var timeAndPlacePage: some View {
        TimeAndPlacePage(ui: timeAndPlaceUI, draft: $vm.respondDraft.newEvent, showMessageScreen: $timeAndPlaceUI.showMessageScreen)
    }

    private var addMessageView: some View {
        AddMessageView(
            message: $vm.respondDraft.respondMessage,
            isRespondMessage: true,
            eventType: $vm.respondDraft.newEvent.type
        )
    }

    //Pages the new event between editing and confirming, mirroring SendInviteContainer.
    private var newEventPager: some View {
        TwoPageScrollView(
            showSecondScreen: $timeAndPlaceUI.showConfirmScreen,
            scrollProgress: .constant(0),
            screen1: { timeAndPlacePage },
            screen2: { newEventConfirmPage }
        )
    }

    @ViewBuilder
    private var newEventConfirmPage: some View {
        if let inviteSummary = InviteSummary(draft: vm.respondDraft.newEvent) {
            ConfirmContainer(
                event: inviteSummary,
                name: vm.profile.name,
                isCard: false,
                timeOpen: timeAndPlaceUI.delayedTimePopupOpen,
                showMessageScreen: $timeAndPlaceUI.showMessageScreen) {
                    StaticTimeRow(proposedTimes: inviteSummary.time)
                } showInfo: {
                    timeAndPlaceUI.showInfoScreen = true
                }
        }
    }
    
    private var addMessageScreen: some View {
        AddMessageView(
            message: $vm.respondDraft.newEvent.message,
            isRespondMessage: true,
            eventType: $vm.respondDraft.newEvent.type
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
        case .newTime:        "Propose New Times"
        case .newEvent:       createEventScreen ? "Invite \(vm.profile.name)" : "Confirm & Send"
        }
        
        let responseType: ProfileResponse = switch type {
        case .originalInvite: .accepted
        case .newTime: .newTime
        case .newEvent: .accepted
        }
        
        let font: Font = .body(type == .newTime ? 16 : 18, .bold)
        
        return WideActionButton(text: text, isActive: isActive, showShadow: false, font: font) {
            if createEventScreen {
                timeAndPlaceUI.showConfirmScreen = true
            } else {
                respond(responseType)
            }
        }
    }
}
