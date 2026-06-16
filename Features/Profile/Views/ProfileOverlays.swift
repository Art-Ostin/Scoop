//
//  ProfileOverlays.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

enum ProfileTitleStyle { case base, overlay }

//Overlay title
extension ProfileView {
    
    var overlayTitle: some View {
    HStack {
        overlayName
        Spacer()
        if !isUserProfile {overlayDismissButton} //Hide if it is
    }
    .padding([.top, .horizontal], 12)
    .modifier(DetailsFadeEffect(ui: ui, from: 0, to: 1, impactStart: 0.5))
}
    
    private var overlayName: some View {
        Text(displayProfile.name)
            .offset(x: isUserProfile ? 36 : 0)//Shifts it as back button is in right corner here
            .font(.title(24))
            .foregroundStyle(Color.white)
    }
    
    private var overlayDismissButton: some View {
        ScoopButton(shape: Circle(), size: .medium) {
            dismissProfile()
        } label: {
            Image(systemName: "xmark")
                .font(.body(18, .bold))
                .foregroundStyle(Color.white)
        }
    }
}
    
extension ProfileView {
    
    var profileTitle: some View {
        HStack{
            Text(displayProfile.name)
            ForEach(displayProfile.nationality, id: \.self) { flag in Text(flag) }
            Spacer()
            profileDismissButton
        }
        .font(.title(24))
        .padding(.horizontal, 12)
    }
    
    
    private var profileDismissButton: some View {
        Button {
            dismissProfile()
        } label: {
            Image(systemName: "chevron.down")
                .font(.body(18, .bold))
                .foregroundStyle(.black)
        }
        .buttonStyle(.plain)
    }
    
    
    @ViewBuilder var inviteButton: some View {
        let canInvite = vm.viewProfileType != .view && vm.viewProfileType != .accepted
        if canInvite {
            InviteButton(isInviting: vm.viewProfileType == .invite, morphId: vm.profile.id) { ui.showPopup.toggle() }
                .opacity(ui.showPopup || ui.morphInviteId == vm.profile.id ? 0 : 1)
                .padding(.horizontal, 24)
                .padding(.bottom, 144)
                .modifier(InviteButtonDragEffect(ui: ui))
        }
    }

    
    @ViewBuilder var declineButton: some View {
        if vm.viewProfileType == .invite {
            DeclineButton {
                if case .sendInvite(_, let onDecline) = mode { onDecline() }
            }
            .opacity(ui.showPopup ? 0 : 1)
        }
    }
}

//Details and Morph Logic
extension ProfileView {
    
    func animateSnapBack(releaseVelocity: CGFloat) {
        let signedDistance = -ui.profileOffset
        let initialV: CGFloat = abs(signedDistance) > 0.001 ? releaseVelocity / signedDistance : 0
        let spring = Animation.fluidSpring(response: 0.42, dampingRatio: 1.0, relativeVelocity: initialV)
        withAnimation(spring) {
            ui.profileOffset = 0
            ui.profileOffsetX = 0
        } completion: {
            guard ui.dragType != .dismiss else { return }
            ui.isDismissDragging = false
        }
    }

    @ViewBuilder var morphOverlay: some View {
        switch mode {
        case .respondToInvite(_, let onResponse):
            Color.clear.respondConfirmAlerts(ui: respondUI, onResponse: onResponse)
        default:
            MorphConfirmAlert(pending: $pendingInvite)
        }
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
            RespondContainer(vm: respondVM, ui: respondUI, onHide: { ui.showPopup = false }, onResponse: onResponse)
        default:
            EmptyView()
        }
    }
    
    func animateDismiss(releaseVelocity: CGFloat) {
        guard let morph else { onDismissStart?(); onDismiss?(); return }
        guard morph.canMorphClose else { animateSnapBack(releaseVelocity: releaseVelocity); return }
        morph.beginZoomClose(pagerVisualShift: ui.interpolate(from: 0, to: -90))
        let travel = morph.closeTravel(currentDrag: ui.profileOffset)
        let initialV: CGFloat = abs(travel) > 1 ? releaseVelocity / travel : 0
        let spring = Animation.fluidSpring(response: 0.45, dampingRatio: 1.0, relativeVelocity: initialV)
        withAnimation(spring) {
            onDismissStart?()
            morph.closeProgress = 1
        } completion: {
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) {
                morph.finishClose()
                onDismiss?()
            }
        }
    }
    
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
    
    func dismissProfile() {
        animateDismiss(releaseVelocity: 0)
    }
}


