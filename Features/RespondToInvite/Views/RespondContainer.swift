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
    @Binding var showPopup: String?

    let onResponse: (ProfileResponse) -> Void
    
    var body: some View {
        let meetDay = FormatEvent.dayAndTime(vm.respondDraft.originalInvite.selectedDay ?? Date(), wide: true, withHour: false)
        let meetHour = (FormatEvent.hourTime(vm.respondDraft.originalInvite.selectedDay ?? Date()))
        
        ZStack {
            CustomScreenCover { showPopup = nil }
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
            .hideTabBar()
            .overlay(alignment: .top) {timeMessageOverlay}
            
            //The different responses to the invite
            .respondCustomAlert(item: $ui.confirmNewTimeInvite, type: .sendNewTimes) { ui.dismissHidePopup = true ; onResponse(.newTime)}
            .respondCustomAlert(item: $ui.confirmAcceptInvite, type: .acceptInvite) { ui.dismissHidePopup = true ; onResponse(.accepted)}
            .respondCustomAlert(item: $ui.confirmSendNewInvite, type: .newInvite) { ui.dismissHidePopup = true ; onResponse(.newInvite)}
        }
    }
}

extension RespondPopupContainer {
    
    private func acceptInvitePage(cardWidth: CGFloat) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = nil}
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
                .onTapGesture {showPopup = nil}

            RespondTimeAndPlaceView(vm: vm, showInvite: $showPopup) { onResponse(.newInvite)}
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


private extension View {
    func pageScrollTransition(anchor: UnitPoint, yOffset: CGFloat) -> some View {
        scrollTransition(.interactive, axis: .horizontal) { content, phase in
            let progress = 1 - min(abs(phase.value), 1)
            let scale = CGFloat(0.5 + progress * 0.5)
            return content.scaleEffect(scale, anchor: anchor).offset(y: yOffset)
        }
    }
}
