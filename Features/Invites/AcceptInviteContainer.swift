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
            
            TabView(selection: $ui.inviteTabSelection) {
                
                AcceptInvitePopup(ui: ui, event: profileEvent.event, image: image, name: name) {onAccept($0)}
                    .tag(0)

                if let image {
                    SelectTimeAndPlace(vm: TimeAndPlaceViewModel(defaults: vm.defaults, sessionManager: vm.s, profile: profileEvent.profile), showInvite: $ui.showInvite, firstImage: image) { onInvite($0)
                    }
                    .tag(1)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}
