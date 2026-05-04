//
//  InviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

struct InviteCard: View {
    
    @Binding var showQuickInvite: UserProfile?
    @Bindable var vm: RespondViewModel
    
    @Bindable var ui: InvitesUIState
    let eventProfile: EventProfile
    let showTimePopup: Bool
    
    
    //Need to give the profile id for the Binding, so optional Strings
    @Binding var showAcceptInvite: String?
    @Binding var showNewTimeInvite: String?
    
    let openProfile: (UserProfile) -> ()
    let onDecline: (UserEvent) -> ()

    @State private var imageSize: CGFloat = 0
    private let contentPadding: CGFloat = 6
    @State var showMessageScreen = false
    
    var dayCount: Int { vm.respondDraft.newTime.proposedTimes.dates.count}
    var type: Event.EventType {vm.respondDraft.originalInvite.event.type}
    var hideInvite: Bool { ((type == .doubleDate || type == .drink) && dayCount == 1) ||  showTimePopup && dayCount >= 2}
    
    
    
    var body: some View {
        VStack(spacing: 0) {
            profileImage
                .padding(.horizontal, contentPadding)
                .opacity(showTimePopup ? 0.1 : 1)
                .animation(.easeInOut(duration: 0.25), value: showTimePopup)
            
            CardEventContainer(
                vm: vm,
                showQuickInvite: $showQuickInvite,
                showMessageScreen: $showMessageScreen,
                showConfirmAcceptPopup: $showAcceptInvite,
                showConfirmNewTimePopup: $showNewTimeInvite) { userEvent in
                    onDecline(userEvent)
                }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) { cardWidth in
             imageSize = max(cardWidth - (contentPadding * 2), 0)
         }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .foregroundStyle(Color.background)
        )
        .customSubtleShadow(strength: 0.8)
        .sheet(isPresented: $showMessageScreen) {addMessageView}
        .onTapGesture {
            if ui.showTimePopup {
                withAnimation(.easeInOut(duration: 0.15)) {
                    ui.showTimePopup = false
                }
            }
        }
        .overlay(alignment: .top) {
            let dayCount = vm.respondDraft.newTime.proposedTimes.dates.count
            if vm.responseType == .modified {
                SelectTimeMessage(type: vm.respondDraft.originalInvite.event.type, dayCount: dayCount, showTimePopup: showTimePopup, isCardMessage: true)
                    .padding(.horizontal, -12)
            }
        }
        .preference(key: HideInvitePreferenceKey.self, value: hideInvite)
    }
}

extension InviteCard {
    
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
    }
}


struct HideInvitePreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}
