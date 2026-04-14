//
//  InviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

struct InviteCard: View {
    
    @Binding var showQuickInvite: UserProfile?
    @State private var vm: RespondViewModel
    @Bindable var ui: InvitesUIState
    let eventProfile: EventProfile
    let showTimePopup: Bool
    
    let openProfile: (UserProfile) -> ()
    
    @State private var imageSize: CGFloat = 0
    private let contentPadding: CGFloat = 6
    
    @State var showMessageScreen = false
    
    var dayCount: Int { vm.respondDraft.newTime.proposedTimes.dates.count}
    var type: Event.EventType {vm.respondDraft.originalInvite.event.type}
    var hideInvite: Bool { ((type == .doubleDate || type == .drink) && dayCount == 1) ||  showTimePopup && dayCount >= 2}
    
    
    init(
        showQuickInvite: Binding<UserProfile?>,
        vm: RespondViewModel,
        ui: InvitesUIState,
        eventProfile: EventProfile,
        showTimePopup: Bool,
        openProfile: @escaping (UserProfile) -> ()
    ) {
        _showQuickInvite = showQuickInvite
        _vm = State(initialValue: vm)
        self.ui = ui
        self.eventProfile = eventProfile
        self.showTimePopup = showTimePopup
        self.openProfile = openProfile
    }
    
    var body: some View {
        VStack(spacing: 0) {
            profileImage
                .padding(.horizontal, contentPadding)
                .opacity(showTimePopup ? 0.1 : 1)
                .animation(.easeInOut(duration: 0.25), value: showTimePopup)
            
            CardEventContainer(vm: vm, showQuickInvite: $showQuickInvite, showMessageScreen: $showMessageScreen)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) { cardWidth in
             imageSize = max(cardWidth - (contentPadding * 2), 0)
         }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.background)
                .shadow(color: .black.opacity(0.25), radius: 1.8, x: 0, y: 3.6)
        )
        .stroke(22, lineWidth: 1, color: Color(red: 0.96, green: 0.96, blue: 0.96))
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
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}


struct HideInvitePreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}
