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
            profileDismissButton
        }
        .font(.title(24))
        .padding(.horizontal, Spacing.sm)
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
            InviteButton(isInviting: vm.viewProfileType == .invite) { openInvite() }
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
                    zoomDismiss()
                    onDecline()
                }
            }
            .padding(.horizontal, Spacing.margin)
            .padding(.bottom, Spacing.xs)
            .opacity(ui.showInvite ? 0 : 1)
            .allowsHitTesting(!ui.showInvite)
        }
    }
}

extension ProfileContainer {

    //The mode's send handler — present only when this profile can actually send an invite.
    private var onSendInvite: ((EventFields) -> Void)? {
        if case .sendInvite(let onSend, _) = mode { onSend } else { nil }
    }

    private var onDeclineProfile: (() -> Void)? {
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
            SendInviteView(
                images: invitedImages,
                name: pending.profile.name,
                showInvite: $ui.showInvite,
                vm: TimeAndPlaceViewModel(profileId: pending.profile.id, defaults: vm.defaults),
                onSendInvite: { draft in
                    ui.showInvite = false
                    zoomDismiss()
                    onSend(draft)
                },
                declineProfile: {
                    ui.showInvite = false
                    zoomDismiss()
                    onDecline()
                }
            )
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

/*
 //The card's collapsed caption line — same shape as MeetContainer's ProfileCard info line.
 private func profileDetails(_ p: UserProfile) -> String {
 "\(p.year) | \(p.degree) | \(p.hometown)"
 }

 */
