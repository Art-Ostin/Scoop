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
    let onResponse: (ProfileResponse) -> Void

    var body: some View {
        PagerScrollView(peek: Self.screenMargin) {
            
            respondCard
//                .horizontalScrollSlot(id: RespondScrollType.acceptPage, shrinkAnchor: .trailing)

            newInviteCard
//                .horizontalScrollSlot(id: RespondScrollType.counterInvitePage, shrinkAnchor: .leading)
        }
        .scrollPosition(id: $ui.scrollPosition)
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

