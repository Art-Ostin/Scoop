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

    @ViewBuilder var inviteButton: some View {
        let canInvite = vm.viewProfileType != .view && vm.viewProfileType != .accepted
        if canInvite {
            InviteButton(isInviting: vm.viewProfileType == .invite, morphId: vm.profile.id) { ui.showPopup.toggle() }
                .opacity(ui.showPopup || ui.morphInviteId == vm.profile.id ? 0 : 1)
                .padding(.horizontal, 24)
                .padding(.bottom, interpolate(from: 144, to: 0)) //144
        }
    }

    // Drives the send-invite morph: non-nil (the profile id) only while a send-invite
    // popup is open, so the morph never fires for respond/own-profile modes.
    var sendInviteMorphId: Binding<String?> {
        Binding(
            get: {
                if case .sendInvite = mode, ui.showPopup { return vm.profile.id }
                return nil
            },
            set: { ui.showPopup = ($0 != nil) }
        )
    }

    @ViewBuilder var sendInviteMorphCard: some View {
        if case .sendInvite(let onSend, _) = mode {
            let inviteModel = InviteModel(profileId: vm.profile.id, name: vm.profile.name, image: profileImages.first ?? UIImage())
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(inviteModel: inviteModel, defaults: vm.defaults),
                showInvite: $ui.showPopup.asOptionalString,
                showBackdrop: false,
                sendInvite: onSend,
                requestConfirm: { pendingInvite = $0 }
            )
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
        animateDismiss(using: geo, releaseVelocity: 0)
    }

    func animateDismiss(using geo: GeometryProxy, releaseVelocity: CGFloat) {
        let target = geo.size.height + geo.safeAreaInsets.bottom + geo.safeAreaInsets.top + 100
        let signedDistance = target - ui.profileOffset
        let initialV: CGFloat = abs(signedDistance) > 0.001 ? releaseVelocity / signedDistance : 0
        let spring = Animation.interpolatingSpring(mass: 1.2, stiffness: 240, damping: 26, initialVelocity: initialV)

        ui.isDismissing = true
        withAnimation(spring) { onDismissStart?() }
        withAnimation(spring) {
            ui.profileOffset = target
        } completion: {
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) { onDismiss?() }
        }
    }

    func animateSnapBack(releaseVelocity: CGFloat) {
        let signedDistance = -ui.profileOffset
        let initialV: CGFloat = abs(signedDistance) > 0.001 ? releaseVelocity / signedDistance : 0
        let spring = Animation.interpolatingSpring(mass: 1.2, stiffness: 240, damping: 26, initialVelocity: initialV)
        withAnimation(spring) { ui.profileOffset = 0 }
    }
}
