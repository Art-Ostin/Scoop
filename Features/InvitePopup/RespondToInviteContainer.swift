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
                HStack(alignment: .bottom) { //Bottom-aligned: BottomBackButton carries a 36pt top pad the change button doesn't
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
    
    //Wears BottomBackButton's circle, so the two read as a matched pair on the bottom row
    private var changeButton: some View {
        ScoopButton(shape: Circle()) {
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
            .font(.body(10, .bold)) //Largest size whose widest word ("Original", 36.3pt) clears the circle's edge
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .frame(width: 38) //Geometry: wraps both labels onto two lines, still wider than "Original"
            .frame(width: 45, height: 45) //Geometry: BottomBackButton's circle
        }
        .padding(.leading, 22) //Geometry: mirrors BottomBackButton's 10 + Spacing.sm edge inset
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
            style: .respondPopup,
            timeOpen: timeAndPlaceUI.delayedTimePopupOpen,
            showMessageScreen: $timeAndPlaceUI.showMessageScreen) {
                DynamicTimeRow(draft: $vm.respondDraft, timePopupOpen: timeAndPlaceUI.popupBinding(.time), style: .respondPopup)
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
                style: .respondPopup,
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
        //Each response gates on its own requirement: without the .newTime gate the button
        //happily posts an empty ProposedTimes, which wipes the invite's times for both users.
        let isActive: Bool = switch type {
        case .originalInvite: vm.respondDraft.originalInvite.selectedDay != nil
        case .newTime:        !vm.respondDraft.newTime.proposedTimes.dates.isEmpty
        case .newEvent:       vm.respondDraft.newEvent.isComplete
        }
        
        let text: String = switch type {
        case .originalInvite: "Accept"
        case .newTime:        "Propose\nNew Times"
        case .newEvent:       createEventScreen ? "Invite \(vm.profile.name)" : "Confirm & Send"
        }
        
        let responseType: ProfileResponse = switch type {
        case .originalInvite: .accepted
        case .newTime: .newTime
        case .newEvent: .accepted
        }
        
        let font: Font = .body(type == .newTime ? 15 : 18, .bold)

        return WideActionButton(text: text, isActive: isActive, showShadow: false, font: font, lineLimit: type == .newTime ? 2 : 1) {
            if createEventScreen {
                timeAndPlaceUI.showConfirmScreen = true
            } else {
                respond(responseType)
            }
        }
    }
}

