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

struct RespondPopupContainer: View {
    
    @Binding var showPopup: Bool
    @Bindable var vm: RespondViewModel
    let onResponse: (ProfileResponse) -> ()

    
    @State var showTimePopup: Bool = false
    @State var scrollPosition: RespondScrollType? = .acceptPage
    
    //Different Custom Popup
    @State var confirmNewTimeInvite: Bool = false
    @State var confirmAcceptInvite: Bool = false
    @State var confirmSendNewInvite: Bool = false
    
    @State var dismissHidePopup: Bool = false
    var popupShown: Bool { confirmNewTimeInvite || confirmAcceptInvite || confirmSendNewInvite}
    
    
    var body: some View {
        ZStack {
            CustomScreenCover { showPopup = false }
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
                    .opacity(popupShown || dismissHidePopup ? 0 : 1)
                    .scrollTargetLayout()
                    .padding(.trailing, 16)
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .scrollPosition(id: $scrollPosition)
                .onPreferenceChange(IsTimeOpen.self) { isTimeOpen in
                    showTimePopup = isTimeOpen
                }
            }
            .hideTabBar()
            .overlay(alignment: .top) {
                let dayCount = vm.respondDraft.newTime.proposedTimes.dates.count
                if vm.responseType == .modified {
                    SelectTimeMessage(type: vm.respondDraft.originalInvite.event.type, dayCount: dayCount, showTimePopup: showTimePopup)
                }
            }
            .customAlert(isPresented: $confirmNewTimeInvite, title: "New Times Proposed", cancelTitle: "Cancel", okTitle: "I Understand", message: "If they accept one of your proposed times & you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) {
                dismissHidePopup = true
                onResponse(.newTime)
            }
            .customAlert(isPresented: $confirmAcceptInvite, title: "Event Commitment", cancelTitle: "Cancel", okTitle: "I Understand", message: "You are committing to meet on \(FormatEvent.dayAndTime(vm.respondDraft.originalInvite.selectedDay ?? Date(), wide: true, withHour: false)) at \(FormatEvent.hourTime(vm.respondDraft.originalInvite.selectedDay ?? Date())). If you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) {
                dismissHidePopup = true
                onResponse(.accepted)
            }
            .customAlert(isPresented: $confirmSendNewInvite, title: "Event Commitment", cancelTitle: "Cancel", okTitle: "I Understand", message: "You are committing to meet on \(FormatEvent.dayAndTime(vm.respondDraft.originalInvite.selectedDay ?? Date(), wide: true, withHour: false)) at \(FormatEvent.hourTime(vm.respondDraft.originalInvite.selectedDay ?? Date())). If you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) {
                dismissHidePopup = true
                onResponse(.newInvite)
            }
        }
    }
}

extension RespondPopupContainer {
    
    private func acceptInvitePage(cardWidth: CGFloat) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}
            RespondAcceptContainer(vm: vm, confirmNewTimeInvite: $confirmNewTimeInvite, confirmAcceptInvite: $confirmAcceptInvite) {
                onResponse(.decline)
            }
                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                    let progress = 1 - min(abs(phase.value), 1)
                    let scale = CGFloat(0.5 + progress * 0.5)
                    return content.scaleEffect(scale, anchor: .trailing).offset(y: 12)
                }
        }
        .frame(width: cardWidth, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func counterInvitePage(cardWidth: CGFloat) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}
            
            
            RespondTimeAndPlaceView(vm: vm, showInvite: $showPopup, showConfirmSendInvite: $confirmSendNewInvite, isNewEvent: true) {eventDraft in}
                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                    let progress = 1 - min(abs(phase.value), 1)
                    let scale = CGFloat(0.5 + progress * 0.5)
                    return content.scaleEffect(scale, anchor: .leading).offset(y: 32)
                }
        }
        .frame(width: cardWidth, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}

/*
 .onChange(of: scrollPosition) { oldValue, newValue in
     guard didAppear, let newValue, newValue != oldValue else { return }
     if newValue == .counterInvitePage {
         lastResponseType = vm.responseType
         vm.respondDraft.respondType = .new
     } else if newValue == .acceptPage {
         vm.respondDraft.respondType = lastResponseType ?? vm.respondDraft.respondType
     }
 }
 
 
 let acceptInvite: (OriginalInvite) -> ()
 let sendNewTime: (NewTimeDraft) -> ()
 let sendNewInvite: (EventDraft) -> ()
 let declineInvite: (_ event: UserEvent) -> ()

 
 */
