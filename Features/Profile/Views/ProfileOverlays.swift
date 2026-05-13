//
//  ProfileOverlays.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

extension ProfileView {

    func profileTitle(geo: GeometryProxy) -> some View {
        HStack {
            Text(displayProfile.name)
            ForEach (displayProfile.nationality, id: \.self) {flag in Text(flag)}
            Spacer()
            if !isUserProfile {
                ProfileDismissButton(color: .black, isOverlay: false) {
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
                ProfileDismissButton(color: .white, isOverlay: true) { onDismiss() }
                    .padding(6)
                    .glassIfAvailable(Circle())
            }
        }
        .font(.body(24, .bold))
        .contentShape(Rectangle())
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .opacity(ui.detailOpen ? 1 : 0)
    }

    @ViewBuilder var invitePopup: some View {
        switch mode {
        case .respondToInvite(let respondVM, let onResponse):
            RespondPopupContainer(vm: respondVM, showPopup: $ui.showPopup, onResponse: onResponse)

        case .sendInvite(let onSend, _):
            let inviteModel = InviteModel(profileId: vm.profile.id, name: vm.profile.name, image: profileImages.first ?? UIImage())
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(inviteModel: inviteModel, defaults: vm.defaults),
                showInvite: $ui.showPopup.asOptionalString, //converts a bool into an optional string
                sendInvite: onSend
            )
        default:
            EmptyView()
        }
    }

    @ViewBuilder var inviteButton: some View {
        let showInviteButton = vm.viewProfileType != .view && vm.viewProfileType != .accepted && !ui.showPopup
        if showInviteButton {
            InviteButton(vm: vm, showInvite: $ui.showPopup)
                .padding(.horizontal, 24)
                .padding(.bottom, 144)
        }
    }

    @ViewBuilder var declineButton: some View {
        if vm.viewProfileType == .invite {
            EventDeclineButton {
                if case .sendInvite(_, let onDecline) = mode { onDecline() }
            }
            .opacity(ui.showPopup ? 0 : 1)
        }
    }
    
    func dismissProfile(using geo: GeometryProxy) {
        let distance = geo.size.height + geo.safeAreaInsets.bottom
        withAnimation(.snappy(duration: ui.dismissDuration)) {
            dismissOffset = distance
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ui.dismissDuration) {
            selectedProfile = nil
        }
    }
}
