//
//  AcceptInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct AcceptInviteContainer: View {
    
    @Bindable var ui: ProfileUIState
    @Bindable var vm: ProfileViewModel
    
    let profileEvent: EventProfile
    let image: UIImage?
    let name: String
    let onAccept: (UserEvent) -> ()
    let onInvite: (EventDraft) -> ()
    
    var body: some View {
        ZStack {
            CustomScreenCover { ui.showRespondPopup = false }
            
            TabView(selection: $ui.inviteTabSelection) {
                acceptInvitePage
                    .tag(0)

                if let image {
                    counterInvitePage(image: image)
                    .tag(1)
                }
            }
            .sheet(isPresented: $ui.showInfoSheet) {Text("Info Screen")}
            .tabViewStyle(.page(indexDisplayMode: .never))
            .hideTabBar()
        }
    }
}

extension AcceptInviteContainer {
    private var tabInfoButton: some View {
        TabInfoButton(showScreen: $ui.showInfoSheet)
            .scaleEffect(0.9)
            .offset(x: -12, y: -48)
    }
    
    
    private var acceptInvitePage: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    ui.showRespondPopup = false
                }
            
            AcceptInvitePopup(ui: ui, event: profileEvent.event, image: image, name: name) { onAccept($0) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func counterInvitePage(image: UIImage) -> some View {
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
