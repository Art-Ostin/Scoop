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
    
    //All card chrome (blur + scrim + text) lives in the transition's overlay, so the flights
    //fade it as one unit over the flying image. Built as a real View struct: the invite
    //flight's exit drivers arrive by environment, and @Environment only resolves on an
    //installed node — a closure-captured copy silently reads defaults (the CustomMenu gotcha)
    private var cardOverlay: some View {
        let p = profile.profile
        return ProfileCardChrome(
            image: profile.image,
            name: p.name,
            subtitle: "\(p.year) · \(p.degree) · \(p.hometown)",
            palette: palette,
            onInvite: { ui.showInvite = profile }
        )
    }
}

//The card's chrome copy, shared by the resting card and both flights. The invite flight drives
//per-element exits through the inviteChrome… environment (defaults = the resting card): the
//wash + name rush out on the flight's fade, the subtitle blur-pops, the invite icon
//opacity-pops, and the collapse multiplier reveals the pops again on the way home.
struct ProfileCardChrome: View {

    //Injected
    let image: UIImage
    let name: String
    let subtitle: String
    let palette: OverlayPalette
    let onInvite: () -> Void

    //The invite flight's exit drivers; at rest every one is identity
    @Environment(\.inviteChromeFade) private var chromeFade
    @Environment(\.inviteChromeCollapse) private var chromeCollapse
    @Environment(\.inviteChromeExiting) private var chromeExiting
    @Environment(\.inviteChromeArrived) private var chromeArrived

    var body: some View {
        ZStack {
            blurBand
                //The card's blur never exits with the chrome: it rides the flight at full
                //strength — shrinking with the rect — then crossfades against the invite
                //card's baked bottom blur as the destination chrome arrives, and back again
                //over the close. One continuous blur, reshaping.
                .opacity(chromeArrived ? 0 : 1)
                .animation(.transition, value: chromeArrived)
            blurBackground.scrimGradient
                .opacity(chromeFade) //The colour veil rushes out with the name — a lingering scrim muddied the flight
        }
        .clipShape(.rect(cornerRadii: .init(top: 0, bottom: CornerRadius.image))) //As the modifier drew it
        .overlay(alignment: .bottomLeading) {
            overlayText
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 18)
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
                //Soft-topped, tucked just above the glur's start so the mask edge lives in
                //pixels the ramp has already softened
                LinearGradient(stops: [
                    .init(color: .clear, location: spec.blurStart - 0.06), //Geometry: the feather strip hugs the ramp's start
                    .init(color: .black, location: spec.blurStart + 0.02),
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
        VStack(alignment: .leading, spacing: 10) {
            Text(name)
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)
                .opacity(chromeFade) //Rushes out with the wash — the invite title takes its place

            Text(subtitle)
                 .font(.body(17, .medium))
                 .foregroundStyle(palette.secondaryText)
                 .blurPop(visible: !chromeExiting)
                 .opacity(chromeCollapse) //The collapse reveals the pop in step with the flight home
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .overlay(alignment: .bottomTrailing) { inviteButton }
    }

    private var inviteButton: some View {
        InviteButton(onTap: onInvite)
            .offset(y: -3) //Now in line with the content
            .opacityPop(visible: !chromeExiting)
            .animation(.transition, value: chromeExiting)
            .opacity(chromeCollapse)
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
