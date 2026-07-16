//
//  ProfileOverlays.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

enum ProfileTitleStyle { case base, overlay }

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


    @ViewBuilder var inviteButton: some View {
        let canInvite = vm.viewProfileType != .view && vm.viewProfileType != .accepted
        if canInvite {
            InviteButton(isInviting: vm.viewProfileType == .invite) { openInvite() }
                .opacity(invite.pending == nil ? 1 : 0) //The button becomes the card while it's presented
                .allowsHitTesting(invite.pending == nil) //opacity(0) alone stays tappable: block the invisible button through the collapse window
                .padding(.horizontal, Spacing.margin)
                .padding(.bottom, Spacing.xl)
        }
    }


    @ViewBuilder var declineButton: some View {
        if vm.viewProfileType == .invite {
            DeclineButton {
                if case .sendInvite(_, let onDecline) = mode { onDecline() }
            }
            .padding(.horizontal, Spacing.margin)
            .padding(.bottom, Spacing.xs)
            .opacity(invite.pending == nil ? 1 : 0)
            .allowsHitTesting(invite.pending == nil) //Same: an invisible decline must not fire during the collapse
        }
    }
}

//Invite card presentation. The card presents above the profile through this feature-local
//presenter (the root InviteOverlayLayer sits *below* the profile layer, so it can't be reused
//here). Mirrors MeetContainer's SendInviteOverlay construction; the flight origin is the hero
//image, reported via .sendInviteSource in the header.
extension ProfileContainer {

    //The mode's send handler — present only when this profile can actually send an invite.
    private var onSendInvite: ((EventFieldsDraft) -> Void)? {
        if case .sendInvite(let onSend, _) = mode { onSend } else { nil }
    }

    //Only the send-invite flow presents this card; respond/accept modes leave the button inert.
    //Zooms up from whichever image the header pager is currently showing (not always the first).
    func openInvite() {
        guard onSendInvite != nil, let selected = invitedImages.first else { return }
        invite.open(PendingProfile(profile: vm.profile, image: selected), image: selected)
    }

    //The card's gallery, rotated so the selected header image is page 0. A page-0 flight sits at
    //scroll offset 0 (width-invariant), so it grows cleanly with the animating card — a non-zero
    //start page drifts because the pager is scroll-disabled mid-flight and its offset can't re-anchor.
    private var invitedImages: [UIImage] {
        let imgs = displayImages
        let i = ui.selectedImageIndex
        guard imgs.indices.contains(i) else { return imgs }
        return Array(imgs[i...] + imgs[..<i])
    }

    @ViewBuilder var inviteOverlay: some View {
        if let pending = invite.pending, let image = invite.image, let onSend = onSendInvite {
            SendInviteOverlay(
                presenter: invite,
                vm: TimeAndPlaceViewModel(
                    inviteModel: InviteContext(profileId: pending.id, name: pending.profile.name, image: image),
                    defaults: vm.defaults
                ),
                image: image,
                images: invitedImages.isEmpty ? [image] : invitedImages,
                details: profileDetails(pending.profile),
                sendInvite: onSend,
                showsCollapsedChrome: false //Grows from the plain hero image, not a ProfileCard — no caption/button chrome at the endpoints
            )
            //No .ignoresSafeArea(): like Meet's root presentation, the card lives inside the safe area
            //(its own backdrop bleeds to the edges); ignoring it pushed the image under the status bar.
        }
    }

    //The card's collapsed caption line — same shape as MeetContainer's ProfileCard info line.
    private func profileDetails(_ p: UserProfile) -> String {
        "\(p.year) | \(p.degree) | \(p.hometown)"
    }
}

//Dismissal
extension ProfileContainer {

    //Zoom-presented: hand back to ImageZoom (native zoom-out). Morph-presented:
    //run the reverse-zoom close; without a morph, fall through to plain onDismiss.
    func dismissProfile() {
        guard let morph, morph.canMorphClose else {
            onDismissStart?()
            onDismiss?()
            return
        }
        morph.beginZoomClose(pagerVisualShift: 0)
        let spring = Animation.fluidSpring(response: 0.45, dampingRatio: 1.0, relativeVelocity: 0)
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
}
