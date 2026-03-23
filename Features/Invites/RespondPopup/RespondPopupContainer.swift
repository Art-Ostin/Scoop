//
//  AcceptInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct RespondPopupContainer: View {
    
    @Binding var showPopup: Bool
    
    @State var image: UIImage?
    @State var showInfo: Bool
    @State var tabSelection: Int

    @State var vm: RespondViewModel
    
    
    var body: some View {
        ZStack {
            CustomScreenCover { showPopup = false }
            if let image {
                                                
                TabView(selection: $tabSelection) {
                    acceptInvitePage
                        .tag(0)
                    counterInvitePage(image)
                        .tag(1)
                }
                .sheet(isPresented: $showInfo) {Text("Info Screen")}
                .tabViewStyle(.page(indexDisplayMode: .never))
                .hideTabBar()
            }
        }
        .task {
            if let url = URL(string: respondDraft.event.otherUserPhoto) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    image = UIImage(data: data)
                } catch {
                    print(error)
                }
            }
        }
    }
}


extension RespondPopupContainer {
    
    private var acceptInvitePage: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}
            
            
            
            
            RespondAcceptContainer(ui: ui, vm: TimeAndPlaceViewModel(defaults: vm.defaults, sessionManager: vm.s, profile: eventProfile.profile), event: eventProfile.event, image: image, name: eventProfile.profile.name) { userEvent in
                onAccept(userEvent)
            } onDecline: { userEvent in
                onDecline(userEvent)
            }            
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
            SelectTimeAndPlace(vm: TimeAndPlaceViewModel(defaults: vm.defaults, sessionManager: vm.s, profile: eventProfile.profile), showInvite: $ui.showRespondPopup, firstImage: image, isCounterInvite: true) {onInvite($0)}
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

