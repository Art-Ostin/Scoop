//
//  ProfileCard.swift
//  Scoop
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI
import Glur

struct ProfileCard : View {

    //Injected
    @Bindable var vm: MeetViewModel
    @Bindable var ui: MeetUIState

    let profile: PendingProfile
    let inviteMode: (UserProfile) -> ProfileMode

    //Local view state
    @State var palette: OverlayPalette = .placeholder

    var body: some View {
        AppImage(image: profile.image, type: .meet)
            .task(id: profile.image) {await fetchColour()}
            .zoomTransition(images: images()) {
                cardOverlay
            } content: {
                profileView(profile.profile)
            }
            .eventZoomSource(profile.image) { cardOverlay } //The photo lifts off into the card; this copy of the chrome rides it out
            .eventZoom(isPresented: ui.showInviteBinding(profile: profile)) { invitePopup }
    }
}

extension ProfileCard {

    private var cardOverlay: some View {
        let p = profile.profile

        //Hide the hometown if degree, year and hometown is long, as it overlaps with like button
        let hometown = p.year.count + p.degree.count + p.hometown.count <= 24 ? "· \(p.hometown)" : ""

        return ProfileCardChrome(
            image: profile.image,
            name: p.name,
            subtitle: "\(p.year) · \(p.degree) \(hometown)",
            palette: palette,
            onInvite: { ui.showInvite = profile }
        )
    }
}

struct ProfileCardChrome: View {

    //Injected
    let image: UIImage
    let name: String
    let subtitle: String
    let palette: OverlayPalette
    let onInvite: () -> Void

    var body: some View {
        ZStack {
            blurBand
            blurBackground.scrimGradient
        }
        .clipShape(.rect(cornerRadii: .init(top: 0, bottom: CornerRadius.image))) //As the modifier drew it
        .overlay(alignment: .bottomLeading) {
            overlayText
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 18) //Geometry: optically balances the side inset against the descender
        }
        .animation(.transition, value: palette) //Extraction lands a frame late — the scrim fades in rather than snaps
    }
}

//The chrome's layers
extension ProfileCardChrome {

    //The image copy wearing ONLY the blur: glur'd from the card's own spec and MASKED to the
    //ramp. The sharp region above shows the true flying image beneath (this copy is
    //transform-scaled in flight — unblurred stretched pixels would double-image against the
    //re-cropping cover), while the band's own blur swallows the stretch.
    private var blurBand: some View {
        let spec = blurBackground
        return Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .glur(radius: spec.blurRadius, offset: spec.blurStart, interpolation: spec.blurRamp, direction: .down, noise: 0)
            .mask {
                LinearGradient(stops: [
                    .init(color: .clear, location: spec.blurStart), //Geometry: the feather starts where the σ ramp starts
                    .init(color: .black, location: spec.blurStart + 0.08),
                    .init(color: .black, location: 1)
                ], startPoint: .top, endPoint: .bottom)
            }
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
        //TODO: 10 is neither a Spacing token nor tied to another measurement — either justify it or take .xs/.sm
        VStack(alignment: .leading, spacing: 10) {
            Text(name)
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)
                .lineLimit(1) //A wrapping card name would hand this line a two-line frame

            Text(subtitle)
                 .font(.body(17, .medium))
                 .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .overlay(alignment: .bottomTrailing) { inviteButton }
    }

    private var inviteButton: some View {
        InviteButton(onTap: onInvite)
            .offset(y: -3) //Geometry: the button's optical raise into line with the text block
    }
}

//Functions
extension ProfileCard {

    //The compose card growing out of this image; the send stays MeetContainer's via the mode.
    //No decline from the card this pass — the profile flow keeps its own.
    @ViewBuilder
    private var invitePopup: some View {
        if case .sendInvite(let onSend, _) = inviteMode(profile.profile) {
            ComposeInviteContainer(
                vm: ComposeInviteViewModel(profileId: profile.profile.id, defaults: vm.defaults),
                images: images(),
                name: profile.profile.name,
                onSend: { onSend($0, nil) } //No hero flight off the card yet — the cover fades in flightless
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
        _ = await PopupColorExtractor.shared
            .extractPalette(profile.image, id: profile.id, prominence: .subtle)
    }

    private func images() -> [UIImage] {
        vm.profileImages[profile.id] ?? seedImages(for: profile.profile)
    }
}
