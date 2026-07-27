//
//  NewSendInviteCard.swift
//  Scoop Test
//
//  Created by Art Ostin on 27/07/2026.
//

import SwiftUI

struct NewSendInviteCard: View {
    
    //Injected Properties
    let images: [UIImage]
    let defaults: DefaultsManaging
    
    @Binding var draft: EventFieldsDraft
    @Binding var showInvite: Bool
    
    @State var vm: TimeAndPlaceViewModel

    let onSendInvite: () -> ()
    let declineProfile: () -> ()
    
    //Local Properties
    @State var ui = TimeAndPlaceUIState()
    
    var body: some View {
        ZStack {
            //Full BleedBackground
            Rectangle().fill(.regularMaterial).ignoresSafeArea()
            
            VStack(spacing: 0) {
                inviteCard
                dismissButton
            }
        }
        .fullScreenCover(isPresented: $ui.showMapView) { MapView(defaults: defaults, eventLocation: $draft.place) }
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
        .sheet(isPresented: $ui.showMessageScreen) {addMessageView}
    }
}


//Top Level Views
extension NewSendInviteCard {

    private var inviteCard: some View {
        VStack(spacing: Spacing.hairline) {
            imageSection
            inviteDetailsPager
        }
        .modifier(InviteCardBackground(isConfirming: ui.showConfirmScreen == true))
    }
    
    private var imageSection: some View {
        ImageCarouselOld(
            images: images,
            type: .invite,
            aspectRatio: ui.showConfirmScreen == true
                ? .confirmInviteImage
                : .invitedImage
        )
    }

    private var inviteDetailsPager: some View {
        VStack(spacing: 0) {
            TwoPageScrollView(
                showSecondScreen: $ui.showConfirmScreen,
                scrollProgress: .constant(0),
                screen1: { timeAndPlaceSection },
                screen2: { confirmScreen }
            )
            actionButton
        }
    }
    
    
    
    private var dismissButton: some View {
        ScoopButton(shape: Circle(), action: {showInvite = false}) {
            Image(systemName: "chevron.down")
                .font(.body(17))
                .fontWeight(.heavy)
                .frame(width: 45, height: 45)
        }
        .padding(.top, Spacing.xl) // 36
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 10)
        .padding(.horizontal, Spacing.sm) // 12
    }
}

//Different Views and Components
extension NewSendInviteCard {
    
    private var actionButton: some View {
        let isConfirming = ui.showConfirmScreen == true
        
        return WideActionButton(
            text: isConfirming
                ? "Confirm & Send"
                : "Invite \(vm.inviteModel.name)",
            isActive: draft.isComplete
        ) {
            if isConfirming {
                onSendInvite()
            } else {
                ui.showConfirmScreen = true
            }
        }
        .padding(.top, isConfirming ? Spacing.md : 0)
        .padding(.horizontal, Spacing.margin)
    }
    
    private var timeAndPlacePage: some View {
        InviteRowContainer(
            ui: ui,
            draft: $draft,
            showMessageScreen: $ui.showMessageScreen,
        )
    }
    
    private var confirmationPage: some View {
        ConfirmInviteScreen(
            name: vm.inviteModel.name,
            isInvite: false,
            event: $draft,
            showConfirmScreen: $ui.showConfirmScreen,
            showMessageScreen: $ui.showMessageScreen
        )
    }
        
    private var addMessageView: some View {
        AddMessageView(
            message: $draft.message,
            isRespondMessage: false,
            eventType: $draft.type
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
