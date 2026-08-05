//
//  SendInviteContainer.swift
//  Scoop
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

    //Same solve the Meet card wears: asked for by profile id, served from the shared cache
    @State private var palette: OverlayPalette = .placeholder

    var body: some View {
        ZStack {
            InvitePopupBackground(tint: palette.secondaryText)

            VStack(spacing: 36) {
                inviteCard
                backButton
            }
        }
        .animation(.transition, value: ui.showConfirmScreen)
        .task(id: vm.profileId) { await fetchColour() }
        .task(id: ui.activePopup) { await ui.syncDelayedPopups() } //Owned here: the delayed mirrors must track on every page, not just the one that hosts a menu

        .fullScreenCover(isPresented: $ui.showMapView) { MapView(defaults: vm.defaults, eventLocation: $vm.event.place) }
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
        .sheet(isPresented: $ui.showMessageScreen) {addMessageView}
    }
}

//Top Level Views
extension SendInviteContainer {

    private var inviteCard: some View {
        VStack(spacing: 0) {
            imageSection
            inviteDetailsPager
        }
        .modifier(InviteCardBackground(tint: palette.secondaryText))
    }
    
    private var imageSection: some View {
        InviteImageCarousel(
            inviteHasChanges: vm.event.hasChanges,
            isConfirm: ui.showConfirmScreen == true,
            isPopupOpen: ui.anyPopupOpenDelayed,
            name: name,
            images: images,
            showConfirmScreen: $ui.showConfirmScreen,
            showInfoScreen: $ui.showInfoScreen,
            declineProfile: declineProfile,
            clearInvite: {withAnimation(.dissolve) { vm.deleteEventDefault() } }
        )
        //Sits under the carousel's bottom mask fuzz, so the image dissolves into the same
        //colour the rows' gradient starts on instead of the card behind it.
        .background(palette.secondaryText.opacity(0.45))
    }

    private var inviteDetailsPager: some View {
        VStack(spacing: 0) {
            TwoPageScrollView(
                showSecondScreen: $ui.showConfirmScreen,
                scrollProgress: .constant(0),
                reflowAnimation: vm.event.hasChanges ? .transition : .dissolve, //An emptied draft is a clear
                screen1: { timeAndPlacePage },
                screen2: { confirmationPage }
            )
            actionButton
        }
    }
}

//Different Views and Components
extension SendInviteContainer {

    //Defaults left alone deliberately: every argument is part of the key the Meet card solved under,
    //so this is a cache hit rather than a second extraction
    private func fetchColour() async {
        guard let first = images.first else { return }

        palette = await PopupColorExtractor.shared
            .extractPalette(first, id: vm.profileId, prominence: .subtle)
    }

    //Gone on the confirm screen, and while the time or type popup owns the card
    private var backButton: some View {
        let visible = !(ui.showConfirmScreen ?? false) && !ui.isPopupOpen()

        return BottomBackButton(visible: visible) { showInvite = false }
            .animation(.transition, value: visible) //Scoped here: keying the ZStack on activePopup would retime the menu morphs
    }

    //Smooth impercetible hiding when popup open
    private var actionButton: some View {
        let isConfirming = ui.showConfirmScreen == true
        let buttonText = isConfirming ? "Send to \(name)" : "Invite \(name)"
        let popupDim = !isConfirming && ui.isPopupOpenDelayed()

        return WideActionButton(text: buttonText, isActive: vm.event.isComplete, isDimmed: popupDim, showShadow: false) {
            if isConfirming {
                onSendInvite(vm.event)
            } else {
                ui.showConfirmScreen = true
            }
        }
        .opacity(popupDim ? 0.4 : 1)
        .allowsHitTesting(!popupDim)
        .animation(.transition, value: popupDim)
        .padding(.horizontal, Spacing.margin) //Each page owns the gap above this button
    }
    
    private var timeAndPlacePage: some View {
        TimeAndPlacePage(ui: ui, draft: $vm.event, showMessageScreen: $ui.showMessageScreen, tint: palette.secondaryText)
    }
    
    @ViewBuilder
    private var confirmationPage: some View {
        if let inviteSummary = InviteSummary(draft: vm.event) {
            ConfirmContainer(
                event: inviteSummary,
                name: name,
                style: .popup,
                timeOpen: ui.delayedTimePopupOpen,
                showMessageSection: true,
                showMessageScreen: $ui.showMessageScreen) {
                    StaticTimeRow(proposedTimes: inviteSummary.time)
                } showInfo: {
                    ui.showInfoScreen = true
                }
                //Same top wash as TimeAndPlacePage, so both pages meet the carousel on one colour
                .background(alignment: .top) {
                    LinearGradient(colors: [palette.secondaryText.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 50)
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
