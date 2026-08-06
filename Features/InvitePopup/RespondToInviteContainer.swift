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
            
            VStack(spacing: 36) {
                inviteCard
                backButton
            }
        }
        .task(id: timeAndPlaceUI.activePopup) { await timeAndPlaceUI.syncDelayedPopups() } //Owned here: the confirm page carries the time menu but never mounts TimeAndPlacePage
        .sheet(isPresented: $timeAndPlaceUI.showInfoScreen) {Text("How It works")}
        .animation(.move, value: vm.responseType)
        .animation(.move, value: createEventScreen)
        .animation(.toggle, value: vm.respondDraft.newEvent.isComplete)
        .sheet(isPresented: $timeAndPlaceUI.showMessageScreen) {addMessageView }
        .fullScreenCover(isPresented: $timeAndPlaceUI.showMapView) { MapView(defaults: vm.defaults, eventLocation: $vm.respondDraft.newEvent.place) }
    }
}

extension RespondInviteContainer {
    
    private var inviteCard: some View {
        VStack(spacing: 0) { //Butted, same as the send card — a gap here shows the card's glass as a white seam
            imageCarousel
            inviteDetailsSection
        }
        .modifier(InviteCardBackground(tint: .red))
    }

    //Gone while the time or type popup owns the card — the DynamicTimeRow's popup counts on either page
    private var backButton: some View {
        let hide = timeAndPlaceUI.isPopupOpen() || timeAndPlaceUI.showConfirmScreen == true
        
        return BottomBackButton(visible: !hide) { showInvitePopup = nil }
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
            showMessageSection: ui.hasEventMessage(vm.respondDraft),
            showMessageScreen: $timeAndPlaceUI.showMessageScreen) {
                DynamicTimeRow(draft: $vm.respondDraft, timePopupOpen: timeAndPlaceUI.popupBinding(.time), style: .respondPopup)
            } showInfo: {
                timeAndPlaceUI.showInfoScreen = true
            }
    }
    
    //Answering their invite until you counter with an event of your own, which pages like the send card
    private var carouselScreen: InviteScreen {
        guard vm.responseType == .newEvent else { return .accept }
        return timeAndPlaceUI.showConfirmScreen == true ? .newInviteConfirm : .newInvite
    }

    private var imageCarousel: some View {
        InviteImageCarousel(
            screen: carouselScreen,
            name: vm.profile.name,
            images: images,
            inviteHasChanges: vm.respondDraft.newEvent.hasChanges,
            isPopupOpen: timeAndPlaceUI.anyPopupOpenDelayed,
            showConfirmScreen: $timeAndPlaceUI.showConfirmScreen,
            showInfoScreen: $timeAndPlaceUI.showInfoScreen,
            responseType: $vm.respondDraft.respondType,
            declineProfile: {respond(.decline)},
            clearInvite: { withAnimation(.dissolve) { vm.deleteEventDefault() } }
        )
    }
    
    private var timeAndPlacePage: some View {
        TimeAndPlacePage(ui: timeAndPlaceUI, draft: $vm.respondDraft.newEvent, showMessageScreen: $timeAndPlaceUI.showMessageScreen)
    }

    private var addMessageView: some View {
        //Bind to different message in different context
        AddMessageView(
            message: (vm.responseType == .newEvent) ? $vm.respondDraft.newEvent.message : $vm.respondDraft.respondMessage,
            isRespondMessage: true,
            eventType: $vm.respondDraft.newEvent.type
        )
    }

    //Pages the new event between editing and confirming, mirroring SendInviteContainer.
    private var newEventPager: some View {
        TwoPageScrollView(
            showSecondScreen: $timeAndPlaceUI.showConfirmScreen,
            scrollProgress: .constant(0),
            reflowAnimation: vm.respondDraft.newEvent.hasChanges ? .transition : .dissolve, //An emptied draft is a clear
            screen1: { timeAndPlacePage },
            screen2: { newEventConfirmPage }
        )
        //Worn here, not by either page: pinned to the seam, so a page swap can never
        //slide it off the carousel's bottom edge
        .modifier(InviteSeamWash(tint: .red))
    }

    @ViewBuilder
    private var newEventConfirmPage: some View {
        let showMessageSection: Bool = vm.responseType == .originalInvite && ui.hasEventMessage(vm.respondDraft)
        
        
        if let inviteSummary = InviteSummary(draft: vm.respondDraft.newEvent) {
            ConfirmContainer(
                event: inviteSummary,
                name: vm.profile.name,
                style:  .respondPopup,
                timeOpen: timeAndPlaceUI.delayedTimePopupOpen,
                showMessageSection: showMessageSection,
                showMessageScreen: $timeAndPlaceUI.showMessageScreen) {
                    StaticTimeRow(proposedTimes: inviteSummary.time, style: .respondPopup)
                } showInfo:  {
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
        .padding(.horizontal, Spacing.margin) //Each page owns the gap above this row
    }
    
    @ViewBuilder
    private var declineButton: some View {
        if vm.responseType != .newEvent {
            Text("Decline")
                .font(.body(18, .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .capsuleStroke(lineWidth: 1, color: .borderStrong)
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
        case .newEvent:       createEventScreen ? "Invite \(vm.profile.name)" : "Send to \(vm.profile.name)"
        }
        
        let responseType: ProfileResponse = switch type {
        case .originalInvite: .accepted
        case .newTime: .newTime
        case .newEvent: .accepted
        }
        
        let font: Font = .body(type == .newTime ? 15 : 18, .bold)
        
        let isDimmed: Bool = timeAndPlaceUI.isPopupOpenDelayed()
        
        return WideActionButton(text: text, isActive: isActive, isDimmed: isDimmed, showShadow: false, font: font, lineLimit: type == .newTime ? 2 : 1) {
            if createEventScreen {
                timeAndPlaceUI.showConfirmScreen = true
            } else {
                respond(responseType)
            }
        }
        .opacity(isDimmed ? 0.4 : 1)
        .allowsHitTesting(!isDimmed)
        .animation(.transition, value: isDimmed)
    }
}
