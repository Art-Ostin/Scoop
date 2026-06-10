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
                    ScoopButton(shape: Circle(), size: .medium) {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body(18, .bold))
                            .foregroundStyle(Color.white)
                    }
                } else {
                    profileDismissButton
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
                //Rest at 144, drop to the edge as details open. Offset, not padding,
                //so the drag never triggers a layout pass.
                .padding(.bottom, 144)
                .modifier(InviteButtonDragEffect(ui: ui))
        }
    }

    var isRespondMode: Bool {
        if case .respondToInvite = mode { return true }
        return false
    }

    // Drives the invite morph: non-nil (the profile id) only while a send-invite or
    // respond-to-invite popup is open, so the morph never fires for view/own-profile.
    var sendInviteMorphId: Binding<String?> {
        Binding(
            get: {
                guard ui.showPopup else { return nil }
                switch mode {
                case .sendInvite, .respondToInvite: return vm.profile.id
                default: return nil
                }
            },
            set: { ui.showPopup = ($0 != nil) }
        )
    }

    @ViewBuilder var sendInviteMorphCard: some View {
        switch mode {
        case .sendInvite(let onSend, _):
            let inviteModel = InviteModel(profileId: vm.profile.id, name: vm.profile.name, image: profileImages.first ?? UIImage())
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(inviteModel: inviteModel, defaults: vm.defaults),
                sendInvite: onSend,
                requestConfirm: { pendingInvite = $0 }
            )
        case .respondToInvite(let respondVM, let onResponse):
            RespondPager(vm: respondVM, ui: respondUI, showPopup: $ui.showPopup, onResponse: onResponse)
        default:
            EmptyView()
        }
    }

    // Full-screen sibling of the morph card. Respond mode hosts the three confirm
    // alerts; send-invite mode hosts its single confirm.
    @ViewBuilder var morphOverlay: some View {
        switch mode {
        case .respondToInvite(_, let onResponse):
            Color.clear.respondConfirmAlerts(ui: respondUI, onResponse: onResponse)
        default:
            MorphConfirmAlert(pending: $pendingInvite)
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
        let spring = Animation.fluidSpring(response: 0.45, dampingRatio: 1.0, relativeVelocity: initialV)

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
        let spring = Animation.fluidSpring(response: 0.45, dampingRatio: 1.0, relativeVelocity: initialV)
        withAnimation(spring) { ui.profileOffset = 0 }
    }
    

    private var profileDismissButton: some View {
        Button {
            if let onDismiss {
                onDismiss()
            }
        } label: {
            Image(systemName: "chevron.down")
                .font(.body(18, .bold))
                .foregroundStyle(.black)
        }
        .buttonStyle(.plain)
    }
}
