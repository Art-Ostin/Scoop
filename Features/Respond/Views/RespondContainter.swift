//
//  NewRespondContainter.swift
//  Scoop Test
//
//  Created by Art Ostin on 15/06/2026.
//

import SwiftUI

struct RespondContainer: View {
    
    @State var cardBottomY: CGFloat = 0

    @Bindable var vm: RespondViewModel
    @Bindable var ui: RespondPopupUIState

    let onHide: () -> Void
    let onResponse: (ProfileResponse) -> Void
    
    var body: some View {
        HorizontalScrollView(peek: 32) {
            respondCard
                .getBottom(coordinateSpace: "RespondSpace", bottom: $cardBottomY) //Bottom of card needed for positioning the 'hide button'
                .horizontalScrollSlot(id: RespondScrollType.acceptPage, shrinkAnchor: .trailing)
            
            newInviteCard
                .horizontalScrollSlot(id: RespondScrollType.counterInvitePage, shrinkAnchor: .leading)
        }
        .scrollPosition(id: $ui.scrollPosition)
        .coordinateSpace(.named("RespondSpace"))
        .overlay(alignment: .top) { hideButton}
        .opacity(ui.popupShown || ui.dismissHidePopup ? 0 : 1) //Hide views when the popup is shown, or dismissing
    }
}

//All Logic for respond Card
extension RespondContainer {
    
    private var respondCard: some View {
        RespondAcceptContainer(
            vm: vm,
            confirmNewTimeInvite: $ui.confirmNewTimeInvite,
            confirmAcceptInvite: $ui.confirmAcceptInvite) {
                onResponse(.decline)
            }
    }
    
    private var newInviteCard: some View {
        RespondTimeAndPlaceView(vm: vm) { onResponse(.newInvite)}
            .offset(y: 48)//Moves it down 30 points so aligned with the Respond Card
    }
    
    private var hideButton: some View {
        HidePopup(onHide: onHide)
            .offset(y: cardBottomY + 96) //Position hide button 96 points below bottom of respond card
    }
}
