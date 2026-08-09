//
//  ProfileCard.swift
//  Scoop
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {
    
    //Injected
    @Bindable var vm: MeetViewModel
    @Bindable var ui: MeetUIState

    let profile: PendingProfile
    let inviteMode: (UserProfile) -> ProfileMode

    @State var palette: OverlayPalette = .placeholder
    @State private var isProfilePresented = false
    
    var body: some View {
        AppImage(image: profile.image, type: .meet)
            .task(id: profile.image) {await fetchColour()}
            .zoomTransition(images: images()) {
                cardOverlay
            } content: {
                profileView(profile.profile)
                    .onAppear { isProfilePresented = true }
                    .onDisappear { isProfilePresented = false }
            }
            //Outside the zoom transition, so hiding the source while the invite is up hides the
            //whole card — image, chrome overlay and resting shadow — never a duplicate
            .inviteZoom(id: profile.id, isPresented: ui.showInviteBinding(profile: profile)) {
                cardOverlay //The flight fades this chrome copy over the flying image, then back in on collapse
            } popup: {
                invitePopup
            }
    }
}

extension ProfileCard {
    
    //All card chrome (blur + scrim + text) lives in the transition's overlay, so the flights fade it as one unit over the flying image
    private var cardOverlay: some View {
        blurAndColour
            .overlay(alignment: .bottomLeading) {
                overlayText
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, 18)
            }
            .animation(.transition, value: palette) //Extraction lands a frame late — the scrim fades in rather than snaps
    }

    //A pixel-aligned copy of the card image wearing the blur + scrim: glur needs image pixels beneath it, and the raw card base then matches the flying image exactly
    private var blurAndColour: some View {
        Color.clear
            .overlay {
                Image(uiImage: profile.image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .modifier(blurBackground)
    }
    
    private var blurBackground: BlurAndGradientBackground {
        BlurAndGradientBackground(
            textRegion: BlurAndGradientBackground.profileRegion,
            blurRadius: 10, //A far shorter ramp than the invite card's — the scrim carries this card, not the blur
            colour: palette.surface,
            scrimOpacity: palette.scrimOpacity
        )
    }
    
    
    private var overlayText: some View {
        let p = profile.profile
        return VStack(alignment: .leading, spacing: 10) {
            Text(profile.profile.name)
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)

            
            Text("\(p.year) · \(p.degree) · \(p.hometown)")
                 .font(.body(17, .medium))
                 .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .overlay(alignment: .bottomTrailing) {inviteButton }
    }

    private var inviteButton: some View {
        InviteButton {
            ui.showInvite = profile
        }
        .offset(y: -3) //Now in line with the content
    }
}

//Functions
extension ProfileCard {

    //The quick-invite popup growing out of this card; send/decline stay MeetContainer's via the mode
    @ViewBuilder
    private var invitePopup: some View {
        if case .sendInvite(let onSend, let onDecline) = inviteMode(profile.profile) {
            SendInviteContainer(
                images: images(),
                name: profile.profile.name,
                showInvite: ui.showInviteBinding(profile: profile),
                vm: TimeAndPlaceViewModel(profileId: profile.profile.id, defaults: vm.defaults),
                onSendInvite: onSend,
                declineProfile: onDecline
            )
        }
    }

    private func profileView(_ profile: UserProfile) -> some View {
        ProfileContainer(
            vm: ProfileViewModel(profile: profile, imageLoader: vm.imageLoader, defaults: vm.defaults),
            profileImages: images(),
            mode: inviteMode(profile)
        )
    }
    
    private func seedImages(for profile: UserProfile) -> [UIImage] {
        vm.profiles.first { $0.profile.id == profile.id }.map { [$0.image] } ?? []
    }
    
    private func fetchColour() async {
        palette = await PopupColorExtractor.shared
            .extractPalette(profile.image, id: profile.id)
    }
    
    private func images() -> [UIImage] {
        vm.profileImages[profile.id] ?? seedImages(for: profile.profile)
    }
}
