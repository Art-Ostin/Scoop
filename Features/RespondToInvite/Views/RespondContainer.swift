//
//  AcceptInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

enum RespondScrollType {
    case acceptPage, counterInvitePage
}

//Here the viewModel, holding and being updated by the user's response is in a higher view, in ViewModel.
//Therefore to trigger response, just pass in what type of response, and parent view triggers what to do.
struct RespondPopupContainer: View {

    @State private var ui = RespondPopupUIState()

    @Bindable var vm: RespondViewModel
    @Binding var showPopup: Bool

    let onResponse: (ProfileResponse) -> Void

    var body: some View {
        ZStack {
            CustomScreenCover { showPopup = false }
            RespondPager(vm: vm, ui: ui, showPopup: $showPopup, onResponse: onResponse)
        }
        .hideTabBar()
        .respondConfirmAlerts(ui: ui, onResponse: onResponse)
    }
}

// The full-screen horizontal accept / counter-invite pager, with no backdrop or confirm
// alerts of its own so it can be dropped into the quick-invite morph as the card content
// (the morph supplies the backdrop and hosts the alerts). The accept card tags itself
// with `.morphCardAnchor()` so the morph surface grows into exactly that card.
struct RespondPager: View {

    @Bindable var vm: RespondViewModel
    @Bindable var ui: RespondPopupUIState
    @Binding var showPopup: Bool

    let onResponse: (ProfileResponse) -> Void

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = proxy.size.width
            let pageWidth = max(cardWidth - 24, 0)

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    acceptInvitePage(cardWidth: cardWidth)
                        .frame(width: pageWidth, alignment: .leading)
                        .id(RespondScrollType.acceptPage)

                    counterInvitePage(cardWidth: cardWidth)
                        .frame(width: pageWidth + 4, alignment: .bottomLeading)
                        .id(RespondScrollType.counterInvitePage)
                }
                .opacity(ui.popupShown || ui.dismissHidePopup ? 0 : 1)
                .scrollTargetLayout()
                .padding(.trailing, 16)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $ui.scrollPosition)
            .onPreferenceChange(IsTimeOpen.self) { isTimeOpen in
                ui.showTimePopup = isTimeOpen
            }
        }
        .overlay(alignment: .top) { timeMessageOverlay }
    }
}

extension RespondPager {

    private func acceptInvitePage(cardWidth: CGFloat) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}
            RespondAcceptContainer(vm: vm, confirmNewTimeInvite: $ui.confirmNewTimeInvite, confirmAcceptInvite: $ui.confirmAcceptInvite) {
                onResponse(.decline)
            }
            .pageScrollTransition(anchor: .trailing, yOffset: 12)
        }
        .frame(width: cardWidth, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private func counterInvitePage(cardWidth: CGFloat) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}

            RespondTimeAndPlaceView(vm: vm, showInvite: $showPopup.asOptionalString) { onResponse(.newInvite)}
                .pageScrollTransition(anchor: .leading, yOffset: 32)
        }
        .frame(width: cardWidth, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private var timeMessageOverlay: some View {
        let dayCount = vm.respondDraft.newTime.proposedTimes.dates.count
        if vm.responseType == .modified {
            SelectTimeMessage(type: vm.respondDraft.originalInvite.event.type, dayCount: dayCount, showTimePopup: ui.showTimePopup)
        }
    }
}

// The three confirm alerts for the respond flow. Hosted as a full-screen sibling of the
// pager (its own modifier) so its dim covers the whole screen rather than being clamped
// to the morph card frame.
struct RespondConfirmAlerts: ViewModifier {
    @Bindable var ui: RespondPopupUIState
    let onResponse: (ProfileResponse) -> Void

    func body(content: Content) -> some View {
        content
            .respondCustomAlert(isPresented: $ui.confirmNewTimeInvite, type: .sendNewTimes) { ui.dismissHidePopup = true ; onResponse(.newTime)}
            .respondCustomAlert(isPresented: $ui.confirmAcceptInvite, type: .acceptInvite) { ui.dismissHidePopup = true ; onResponse(.accepted)}
            .respondCustomAlert(isPresented: $ui.confirmSendNewInvite, type: .newInvite) { ui.dismissHidePopup = true ; onResponse(.newInvite)}
    }
}

extension View {
    func respondConfirmAlerts(ui: RespondPopupUIState, onResponse: @escaping (ProfileResponse) -> Void) -> some View {
        modifier(RespondConfirmAlerts(ui: ui, onResponse: onResponse))
    }
}

private extension View {
    func pageScrollTransition(anchor: UnitPoint, yOffset: CGFloat) -> some View {
        scrollTransition(.interactive, axis: .horizontal) { content, phase in
            let progress = 1 - min(abs(phase.value), 1)
            let scale = CGFloat(0.5 + progress * 0.5)
            return content.scaleEffect(scale, anchor: anchor).offset(y: yOffset)
        }
    }
}
