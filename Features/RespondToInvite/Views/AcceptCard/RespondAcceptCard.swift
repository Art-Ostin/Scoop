//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct RespondAcceptCard: View {
    
    @Bindable var vm: RespondViewModel
    @Bindable var ui: RespondUIState
    @Binding var confirmNewTimePopup: Bool
    @Binding var confirmAcceptInvite: Bool
    let onDecline: () -> ()
    
    var popupShown: Bool { confirmNewTimePopup || confirmAcceptInvite }
    
    var event: UserEvent { vm.respondDraft.originalInvite.event}
    typealias layout = RespondUIState.PopupLayout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) { //Spacing decided mostly by bottom padding
            respondTitle
                .padding(.bottom, layout.titleToTimeSpacing)
                .opacity(popupShown ? 0 : 1)
            respondTime
                .padding(.bottom, ui.hasBothMessages(vm.respondDraft) ? 12 : layout.timeToPlaceSpacing)
            respondPlace
            respondMessages
                .padding(.top, 20)
            actionSection
                .padding(.top, ui.hasBothMessages(vm.respondDraft) ? 20 : layout.actionTopSpacing) //decrease vertical spacing when there are messages
        }
        .zIndex(1)
        .padding(.horizontal, layout.horizontalPadding)
        .padding(.top, layout.topPadding)
        .padding(.bottom, layout.bottomPadding)
        .frame(maxWidth: .infinity)
        .background(customBackground.morphCardAnchor())
        .padding(.horizontal, ui.hasRespondMessage(vm.respondDraft) ? 24 : 30)
        .animation(.easeInOut(duration: 0.2), value: ui.showTimePopup)
        .animation(.easeInOut(duration: 0.2), value: vm.respondDraft.respondType)
        .animation(.easeInOut(duration: 0.2), value: popupShown)
        .sheet(isPresented: $ui.showMessageScreen) {addMessageView}
    }
}

extension RespondAcceptCard {
    
    private var respondTitle: some View {
        RespondTitle(
            showInfo: $ui.showMeetInfo,
            showTimePopup: ui.showTimePopup,
            event: event,
            image: vm.image
        )
    }
    
    private var respondTime: some View {
        RespondTimeRow(
            vm: vm,
            showTimePopup: $ui.showTimePopup,
            showMessageScreen: $ui.showMessageScreen
        )
    }
    
    private var respondPlace: some View {
        RespondPlaceRow(
            showMessageScreen: $ui.showMessageScreen,
            location: event.location, defaults: vm.defaults, //Defaults needed to open up Maps router
            noEventMessages: (!ui.hasEventMessage(vm.respondDraft) && !ui.hasRespondMessage(vm.respondDraft))
        )
        .disabled(ui.showTimePopup)
    }
    
    private var addMessageView: some View {
        AddMessageView(
            eventType: .constant(event.type),
            showMessageScreen: $ui.showMessageScreen,
            message: $vm.respondDraft.respondMessage,
            isRespondMessage: true,
            name: vm.respondDraft.newTime.event.otherUserName)
    }
    
    
    @ViewBuilder
    private var respondMessages: some View {
        let e = vm.respondDraft
        if ui.hasBothMessages(vm.respondDraft) {
            if let eventMessage = e.originalInvite.event.message, let respondMessage = e.respondMessage {
                VStack(alignment: .leading, spacing: 12) {
                    RespondTextBubble(showMessageScreen: $ui.showMessageScreen, message: eventMessage, isMyChat: false)
                    RespondTextBubble(showMessageScreen: $ui.showMessageScreen, message: respondMessage, isMyChat: true, isNewTime: vm.responseType == .modified)
                }
            }
        }
    }
    
    @ViewBuilder
    private var actionSection: some View {
        HStack {
            DeclineButton { onDecline() }
            Spacer()
            acceptButton
        }
    }
    
    
    private var acceptButton: some View {
        let isModified = vm.respondDraft.respondType != .original
        let isValid = vm.respondDraft.canSendNewTime && !popupShown
        let colour: Color = isModified ? .accent : (isValid ? .appGreen : .grayPlaceholder) 

        return ScoopButton(style: .tinted(colour, shadow: nil), shape: .rect(cornerRadius: 16)) {
            if isModified {
                confirmNewTimePopup = true
            } else {
                confirmAcceptInvite = true
            }
        } label: {
            Text(isModified ? "Invite with new time" + "s" : "Accept")
                .foregroundStyle(Color.white)
                .font(.body(isModified ? 14 : 16, .bold))
                .frame(width: 135)
                .frame(height: 40)
        }
    }
    
    private var customBackground: some View {
        ZStack { //Background done like this to fix bugs when popping up
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.appCanvas)
                .customShadow(.floating, strength: ui.showTimePopup ? 0 : 0.7)
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
            }
    }
}
//Delete Accept Button
/*
 
 */
