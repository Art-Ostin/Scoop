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
    let showTimePopup: Bool
        
    let openProfile: (UserProfile) -> ()
    let onDecline: (UserEvent) -> ()

    private let contentPadding: CGFloat = 6
    
    
    var dayCount: Int { vm.respondDraft.newTime.proposedTimes.dates.count}
    var type: Event.EventType {vm.respondDraft.originalInvite.event.type}
    var hideInvite: Bool { ((type == .doubleDate || type == .drink) && dayCount == 1) ||  showTimePopup && dayCount >= 2}
    
    var body: some View {
        VStack(spacing: 0) {
            profileImage
            inviteEventSection
        }
        .modifier(InviteCardStyle())
        .sheet(isPresented: $showMessageScreen) {addMessageView}
        .onTapGesture {hideTimePopup()}
        .overlay(alignment: .top) {addingTimeInfoOverlay}
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) {cardWidth in
             imageSize = max(cardWidth - (contentPadding * 2), 0)
         }
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
                showTimePopup: showTimePopup,
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
            .opacity(ui.showTimePopup ? 0.3 : 1)
            .contentShape(Rectangle())
            .onTapGesture {openProfile(eventProfile.profile)}
            .padding(.horizontal, contentPadding)
            .opacity(showTimePopup ? 0.1 : 1)
    }
    
    private func hideTimePopup() {
        if ui.showTimePopup {
            withAnimation(.easeInOut(duration: 0.15)) {
                ui.showTimePopup = false
            }
        }
    }
    
}

struct InviteCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22)
                .foregroundStyle(Color.background)
            )
            .customSubtleShadow(strength: 0.8)
    }
}

struct HideInvitePreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}
