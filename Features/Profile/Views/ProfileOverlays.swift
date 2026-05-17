//
//  ProfileOverlays.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

enum ProfileTitleStyle { case base, overlay }

extension ProfileView {

    func profileTitle(geo: GeometryProxy) -> some View {
        titleBar(style: .base, onDismiss: { dismissProfile(using: geo) })
    }

    func overlayTitle(onDismiss: @escaping () -> Void) -> some View {
        titleBar(style: .overlay, onDismiss: onDismiss)
    }

    @ViewBuilder
    private func titleBar(style: ProfileTitleStyle, onDismiss: @escaping () -> Void) -> some View {
        let isOverlay = style == .overlay
        HStack {
            Text(displayProfile.name)
            if !isOverlay {
                ForEach(displayProfile.nationality, id: \.self) { flag in Text(flag) }
            }
            Spacer()
            if !isUserProfile {
                if isOverlay {
                    ProfileDismissButton(color: .white, isOverlay: true, onDismiss: onDismiss)
                        .padding(6)
                        .glassIfAvailable(Circle())
                } else {
                    ProfileDismissButton(color: .black, isOverlay: false, onDismiss: onDismiss)
                }
            }
        }
        .font(.body(24, .bold))
        .foregroundStyle(isOverlay ? Color.white : .primary)
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
        .offset(y: isOverlay ? 0 : 4) // base: hack to align to bottom of HStack
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
            ui.profileOffset = distance
        } completion: {
            onDismiss?()
        }
    }
}
