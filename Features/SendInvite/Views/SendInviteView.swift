//
//  NewSendInviteCard.swift
//  Scoop Test
//
//  Created by Art Ostin on 27/07/2026.
//

import SwiftUI

struct SendInviteView: View {
    
    //Injected Properties
    let images: [UIImage]
    let name: String
    
    @Binding var showInvite: Bool
    
    @State var vm: TimeAndPlaceViewModel

    let onSendInvite: (EventFields) -> ()
    let declineProfile: () -> ()
    
    //Local Properties
    @State var ui = TimeAndPlaceUIState()
    
    var body: some View {
        ZStack {
            //Full BleedBackground
            Rectangle()
                .fill(Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                inviteCard
                BottomBackButton(showInvite: $showInvite, visible: !(ui.showConfirmScreen ?? false))
            }
        }
        .animation(.transition, value: ui.showConfirmScreen)

        .fullScreenCover(isPresented: $ui.showMapView) { MapView(defaults: vm.defaults, eventLocation: $vm.event.place) }
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
        .sheet(isPresented: $ui.showMessageScreen) {addMessageView}
    }
}


//Top Level Views
extension SendInviteView {

    private var inviteCard: some View {
        VStack(spacing: Spacing.hairline) {
            imageSection
            inviteDetailsPager
        }
        .modifier(InviteCardBackground(isConfirming: ui.showConfirmScreen == true))
    }
    
    private var imageSection: some View {
        InviteImageCarousel(
            vm: vm,
            ui: ui,
            name: name,
            images: images,
            declineProfile: declineProfile
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
extension SendInviteView {
    
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
        InvitePage(
            ui: ui,
            draft: $vm.event,
            showMessageScreen: $ui.showMessageScreen,
        )
        .containerRelativeFrame(.horizontal)
    }
    
    private var confirmationPage: some View {
        ConfirmInvitePage(
            event: vm.event,
            name: name,
            showConfirmScreen: $ui.showConfirmScreen,
            showMessageScreen: $ui.showMessageScreen
        )
        .containerRelativeFrame(.horizontal)
    }
        
    private var addMessageView: some View {
        AddMessageView(
            message: $vm.event.message,
            isRespondMessage: false,
            eventType: $vm.event.type
        )
    }
}


struct InviteCardBackground: ViewModifier {
    
    private let shape = RoundedRectangle(cornerRadius: CornerRadius.xl)
    var isConfirming: Bool
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.sm)
            .background(Color.appCanvas, in: shape)
            .clipShape(shape)
            .shadow(.softFloating)
            .padding(.horizontal, 10)
            .padding(.top, isConfirming ? 40 : 48)
    }
}

/*
 
 ConfirmInvitePage(
     name: name,
     type: e.type,
     proposedTimes: e.time,
     place: e.place,
     message: e.message,
     showConfirmScreen: e.,
     showMessageScreen: <#T##Binding<Bool>#>
 )
 
 
 
 
 ConfirmInvitePage(
     name: name,
     isInvite: false,
     event: $vm.event,
     showConfirmScreen: $ui.showConfirmScreen,
     showMessageScreen: $ui.showMessageScreen
 )
 */
