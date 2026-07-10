//
//  NewRespondContainter.swift
//  Scoop
//
//  Created by Art Ostin on 15/06/2026.
//

import SwiftUI

enum RespondScrollType {
    case acceptPage, counterInvitePage
}

struct RespondContainer: View {

    //Gap from each screen edge to the card — the scroll peek owns the card's screen margin
    static let screenMargin: CGFloat = 32

    //Injected
    @Bindable var vm: RespondViewModel
    @Bindable var ui: RespondPopupUIState
    let onHide: () -> Void
    let onResponse: (ProfileResponse) -> Void

    //Local view state
    @State private var cardBottomY: CGFloat = 0

    var body: some View {
        HorizontalScrollView(peek: Self.screenMargin) {
            
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
            .offset(y: 16) //So vertically aligned with respondCard
    }
    
    private var hideButton: some View {
        HidePopup(onHide: onHide)
            .offset(y: cardBottomY + 96) //Position hide button 96 points below bottom of respond card
    }
}


struct RespondConfirmAlerts: ViewModifier {
    @Bindable var ui: RespondPopupUIState
    let onResponse: (ProfileResponse) -> Void

    func body(content: Content) -> some View {
        content
            .respondCustomAlert(isPresented: $ui.confirmNewTimeInvite, type: .sendNewTimes) { ui.dismissHidePopup = true ; onResponse(.newTime) }
            .respondCustomAlert(isPresented: $ui.confirmAcceptInvite, type: .acceptInvite) { ui.dismissHidePopup = true ; onResponse(.accepted) }
    }
}

extension View {
    func respondConfirmAlerts(ui: RespondPopupUIState, onResponse: @escaping (ProfileResponse) -> Void) -> some View {
        modifier(RespondConfirmAlerts(ui: ui, onResponse: onResponse))
    }
}

