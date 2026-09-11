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
    let onSend: (EventFieldsDraft, SendInviteFlightSource?) -> Void //The confirm screen's Send: the parent sends and closes the card, flying the page it was handed

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
        .onAppear { ui.showConfirmScreen = false} //Fixes bug with back button not showing
        .animation(.transition, value: [ui.delayedTimePopupOpen, ui.delayedTypePopupOpen])
    }
}

//Logic with the ImagePager
extension ComposeInviteContainer {
    
    //One flag drives all three: the dots and the menu belong to compose, the chevron to confirm
    private var imagePager: some View {
        let isConfirm = ui.showConfirmScreen == true
        return EventImagePager(images: images,
                               title: isConfirm ? "Confirm Invite" : "Invite \(name)",
                               showsPageDots: !isConfirm,
                               titleVisible: !ui.delayedTimePopupOpen, //The time platter takes the band
                               bandFilled: ui.timePopupOpen && ui.delayedTimePopupOpen,
                               bandGround: ui.timeBand,
                               visiblePhoto: $ui.visiblePhoto)
        //The pager's frame IS the photo's — its root is the aspect box the carousel overlays
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { ui.photoFrame = $0 }
        .overlay(alignment: .topLeading) { backButton.eventZoomBandChrome(visible: isConfirm) }
    }
    
    private var optionsMenu: some View {
        Text("Hello World")
//        OptionsMenu(
//            hasChanges: vm.event.hasChanges,
//            onClear: {vm.event = .init()},
//            onDecline: { }
//        )
    }
    
    private var backButton: some View {
        EventBackButton(showConfirmScreen: $ui.showConfirmScreen)
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
                .overlay(alignment: .topTrailing) {
                    if invite.message?.isEmpty != false {
                        addNoteButton
                    }
                }
        }
    }
    
    private var addNoteButton: some View {
        ScoopButton(style: .glass, shape: .capsule) {
            ui.showMessageScreen = true
        } label: {
            Text("Add a note")
                .font(.body(14, .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
        .padding(.horizontal, 32)
        .padding(.top, 16)
    }
    
//    private var addMessageButton: some View {
//        ScoopButton(style: .glass, shape: .circle, size: .small) {
//            ui.showMessageScreen = true
//        } label: {
//            Image(.addMessageIcon)
//        }
//        .scaleEffect(1.1)
//        .padding(.horizontal, 32)
//        .padding(.top, 16)
//    }
}



//Logic with the action Button
extension ComposeInviteContainer {
    
    private var ctaButton: some View {
        let isConfirm = ui.showConfirmScreen == true
        let dimmed = ui.delayedTypePopupOpen || ui.delayedTimePopupOpen
        let text = isConfirm ? "Send to \(name)" : "Preview"
        let fill = WideActionButton.restingFill(isActive: vm.event.isComplete, isDimmed: dimmed)

        return VStack {
            if isConfirm { warningMessage }
            WideActionButton(
                text: text,
                isActive: vm.event.isComplete,
                isDimmed: dimmed,
                showShadow: false,
                height: 46,
                glass: false, //The event zoom's capsule lands on this: flat, so it lands on identical pixels
                onTap: { ctaAction(isConfirm)() }
            )
            .eventZoomDragExclusion()
            .eventZoomButtonTarget(text: text, fill: fill) //The card's envelope widens into this
        }
        .padding(.bottom, 12)
        .padding(.horizontal, Spacing.margin) //Each page owns the gap above this button
    }
    
    private var warningMessage: some View {
        Text("* If they accept & you don't show, you may be blocked")
            .font(.body(12.5, .regularItalic))
            .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.55))
    }
    
    private func ctaAction(_ isConfirm: Bool) -> () -> Void {
        isConfirm
            ? { onSend(vm.event, sendFlightSource) }
            : { withAnimation(.transition) { ui.showConfirmScreen = true } }
    }

    private var sendFlightSource: SendInviteFlightSource? {
        guard let image = ui.visiblePhoto, ui.photoFrame.width > 1 else { return nil }
        return SendInviteFlightSource(image: image, frame: ui.photoFrame, cornerRadius: CornerRadius.image)
    }
}


struct EditTypeTimePlace: View {
    
    @Binding var ui: ComposeInviteUIState

    @Binding var draft: EventFieldsDraft

    //An open platter is glass over this section, so everything under it hides but the open menu's own
    //label. Each row carries that hide itself; the seams and the time caption own no menu, so they hide here
    private var popupOpen: Bool { ui.delayedTypePopupOpen || ui.delayedTimePopupOpen }

    var body: some View {
        VStack(spacing: 18) {
            InviteTypeRow(eventType: $draft.type, message: $draft.message, ui: ui, timePopupOpen: ui.delayedTimePopupOpen)

            VeryLightDivider()
                .blurPop(visible: !popupOpen, scale: 1)
            
            InviteTimeRow(
                proposedTimes: $draft.time,
                timeisOpen: $ui.timePopupOpen,
                typePopUpOpen: ui.delayedTypePopupOpen,
                captionHidden: ui.delayedTimePopupOpen,
                bandGround: ui.timeBand
            )
            
            VeryLightDivider()
                .blurPop(visible: !popupOpen, scale: 1)
            
            InvitePlaceRow(
                popupOpen: popupOpen,
                location: $draft.place,
                showMapView: $ui.showMapView
            )
        }
        .padding(24)
        .padding(.top, -4)//Only 20 padding on the top
    }
}
