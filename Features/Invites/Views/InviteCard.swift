//
//  InviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

struct InviteCard: View {
    
    @Bindable var vm: RespondViewModel
    @Bindable var ui: InvitesUIState
    
    @State var showMessageScreen = false
    @State private var imageSize: CGFloat = 0
    
    let eventProfile: EventProfile
        
    let openProfile: (UserProfile) -> ()
    let onDecline: (String) -> ()

    private let contentPadding: CGFloat = 6
    
    var dayCount: Int { vm.respondDraft.newTime.proposedTimes.dates.count}
    var type: Event.EventType {vm.respondDraft.originalInvite.event.type}
    var hideInvite: Bool { ((type == .doubleDate || type == .drink) && dayCount == 1) ||  ui.showTimePopup && dayCount >= 2}
    
    var body: some View {
        VStack(spacing: 0) {
            profileImage
            inviteEventSection
        }
        .modifier(InviteCardStyle())
        .sheet(isPresented: $showMessageScreen) {addMessageView}
        .onTapGesture {if ui.showTimePopup {ui.showTimePopup = false}}
        .overlay(alignment: .top) {addingTimeInfoOverlay}
        .getImageSize(imageSize: $imageSize, horizontalPadding: contentPadding)
        .preference(key: HideInvitePreferenceKey.self, value: hideInvite)
    }
}

extension InviteCard {
    
    private var inviteEventSection: some View {
        CardEventContainer(
            vm: vm,
            invitesUI: ui,
            showMessageScreen: $showMessageScreen) {onDecline($0)}
    }
        
    @ViewBuilder private var addingTimeInfoOverlay: some View {
        let isModifiedMode = vm.responseType == .modified
        
        if isModifiedMode {
            SelectTimeMessage(
                type: vm.respondDraft.originalInvite.event.type,
                dayCount: dayCount,
                showTimePopup: ui.showTimePopup,
                isCardMessage: true
            )
            .padding(.horizontal, -12)
        }
    }
    
    private var addMessageView: some View {
        AddMessageView (
            eventType: .constant(eventProfile.event.type),
            showMessageScreen: $showMessageScreen,
            message: $vm.respondDraft.respondMessage,
            isRespondMessage: true,
            name: vm.respondDraft.newTime.event.otherUserName
        )
        .presentationBackgroundInteraction(.enabled)
    }    
    
    private var profileImage: some View {
        Image(uiImage: eventProfile.image ?? UIImage())
            .resizable()
            .defaultImage(imageSize)
            .contentShape(Rectangle())
            .onTapGesture {openProfile(eventProfile.profile)}
            .padding(.horizontal, contentPadding)
            .opacity(ui.showTimePopup ? 0.2 : 1)
    }
}

struct InviteCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22)
                .foregroundStyle(Color.appCanvas)
            )
            .customShadow(.card, strength: 2)
    }
}

struct HideInvitePreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}
