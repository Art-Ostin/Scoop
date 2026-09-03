//
//  ProfileOverlays.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

extension ProfileContainer {

    var profileTitle: some View {
        HStack{
            Text(displayProfile.name)
            ForEach(displayProfile.nationality, id: \.self) { flag in Text(flag) }
            Spacer()
            if !isUserProfile {
                profileDismissButton
            }
        }
        .font(.title(24))
        .padding(.horizontal, Spacing.sm)
        .padding(.leading, showsSaveButton ? Spacing.xxxl : 0) //Steps out from under the Save lens
        .offset(y: showsSaveButton ? -Spacing.hairline : 0) //Rides up onto the lens' optical centre
        .animation(.present, value: showsSaveButton) //Arrives on the lens' own curve
    }


    private var profileDismissButton: some View {
        Button {
            dismissProfile()
        } label: {
            Image(systemName: "chevron.down")
                .font(.body(18, .bold))
                .foregroundStyle(Color.textPrimary)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var inviteOverlay: some View {
        if ui.showInvite, let image = invitedImages.first {
            inviteView(pending: PendingProfile(profile: vm.profile, image: image))
        }
    }


    @ViewBuilder
    var inviteButton: some View {
        let canInvite = vm.viewProfileType != .view && vm.viewProfileType != .accepted
        if canInvite {
            InviteButton { openInvite() }
                .opacity(ui.showInvite ? 0 : 1) //The button becomes the card while it's presented
                .allowsHitTesting(!ui.showInvite) //opacity(0) alone stays tappable: block the invisible button through the collapse window
                .padding(.horizontal, Spacing.margin)
                .padding(.bottom, Spacing.xl)
        }
    }

    @ViewBuilder var declineButton: some View {
        if vm.viewProfileType == .invite {
            DeclineButton {
                if case .sendInvite(_, let onDecline) = mode {
                    ui.didDecline = true //The cover's flying cross takes over from the icon
                    onDecline(ui.declineButtonFrame)
                    Task { //The profile stays put and blurs; it collapses under the opaque wash
                        try? await Task.sleep(for: BlurCoverMotion.coveredAt)
                        zoomDismiss()
                    }
                }
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                ui.declineButtonFrame = $0
            }
            .padding(.horizontal, Spacing.margin)
            .padding(.bottom, Spacing.xs)
            .opacity(ui.showInvite || ui.didDecline ? 0 : 1)
            .allowsHitTesting(!ui.showInvite && !ui.didDecline)
        }
    }
}

extension ProfileContainer {

    //The mode's send handler — present only when this profile can actually send an invite.
    private var onSendInvite: ((EventFieldsDraft, SendInviteFlightSource?) -> Void)? {
        if case .sendInvite(let onSend, _) = mode { onSend } else { nil }
    }

    private var onDeclineProfile: ((CGRect?) -> Void)? {
        if case .sendInvite(_, let onDecline) = mode { onDecline } else { nil }
    }

    //Only the send-invite flow presents this screen; respond/accept modes leave the button inert.
    func openInvite() {
        guard onSendInvite != nil, !invitedImages.isEmpty else { return }
        ui.showInvite = true
    }

    //Rotate the gallery so the selected profile image opens as the invite's first page.
    private var invitedImages: [UIImage] {
        let imgs = displayImages
        let i = ui.selectedImageIndex
        guard imgs.indices.contains(i) else { return imgs }
        return Array(imgs[i...] + imgs[..<i])
    }

    @ViewBuilder
    private func inviteView(pending: PendingProfile) -> some View {
        if let onSend = onSendInvite, let onDecline = onDeclineProfile {
        }
    }
}

//Dismissal
extension ProfileContainer {

    func dismissProfile() {
        if isUserProfile {
            dismiss()
        } else {
            zoomDismiss()
        }
    }
}
