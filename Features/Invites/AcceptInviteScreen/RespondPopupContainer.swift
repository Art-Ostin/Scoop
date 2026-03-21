//
//  AcceptInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct RespondPopupContainer: View {
    
    @Bindable var ui: ProfileUIState
    @Bindable var vm: ProfileViewModel
    
    let profileEvent: EventProfile
    let onAccept: (UserEvent) -> ()
    let onInvite: (EventDraft) -> ()
    
    var body: some View {
        if let image = profileEvent.image {
            ZStack {
                CustomScreenCover { ui.showRespondPopup = false }
                TabView(selection: $ui.inviteTabSelection) {
                    acceptInvitePage(image)
                        .tag(0)
                    counterInvitePage(image)
                        .tag(1)
                }
                .sheet(isPresented: $ui.showInfoSheet) {Text("Info Screen")}
                .tabViewStyle(.page(indexDisplayMode: .never))
                .hideTabBar()
            }
        }
    }
}

extension RespondPopupContainer {
    
    private func acceptInvitePage(_ image: UIImage) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    ui.showRespondPopup = false
                }
            RespondCard(ui: ui, event: profileEvent.event, image: image, name: profileEvent.profile.name) { onAccept($0) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func counterInvitePage(_ image: UIImage) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    ui.showRespondPopup = false
                }
            SelectTimeAndPlace(vm: TimeAndPlaceViewModel(defaults: vm.defaults, sessionManager: vm.s, profile: profileEvent.profile), showInvite: $ui.showRespondPopup, firstImage: image, isCounterInvite: true) { onInvite($0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
