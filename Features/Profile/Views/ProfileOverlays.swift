//
//  ProfileOverlays.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

extension ProfileView {
    @ViewBuilder
    var invitePopup: some View {
        switch mode {
        case .respondToInvite(let respondVM, let onResponse):
            RespondPopupContainer(showPopup: $ui.showRespondPopup, vm: respondVM, onResponse: onResponse)

        case .sendInvite(let onSend):
            let inviteModel = InviteModel(profileId: vm.profile.id, name: vm.profile.name, image: profileImages.first ?? UIImage())
            InviteTimeAndPlaceView(
                showInvite: $ui.showInvitePopup,
                inviteModel: inviteModel,
                inviteTitle: "Meet \(vm.profile.name)",
                sendInvite: onSend)
            
        default:
            EmptyView()
        }
    }
    
    func profileTitle(geo: GeometryProxy) -> some View {
        HStack {
            Text(displayProfile.name)
            ForEach (displayProfile.nationality, id: \.self) {flag in Text(flag)}
            Spacer()
            if !isUserProfile {
                ProfileDismissButton(color: .black, detailsOpen: ui.detailsOpen) {
                    dismissProfile(using: geo)
                }
            }
        }
        .offset(y: 4) // Hack to align to bottom of HStack
        .font(.body(24, .bold))
        .padding(.horizontal)
    }
    
    func overlayTitle(onDismiss: @escaping () -> Void) -> some View {
        HStack {
            Text(displayProfile.name)
            Spacer()
            if !isUserProfile {
                ProfileDismissButton(color: .white, detailsOpen: ui.detailsOpen) { onDismiss() }
                    .padding(6)
                    .glassIfAvailable(Circle())
            }
        }
        .font(.body(24, .bold))
        .contentShape(Rectangle())
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .opacity(transition.overlayTitleOpacity)
    }
}
