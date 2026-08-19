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
            .task(id: images().first) {
                guard let hero = images().first else { return }
                await InviteBandBake.warm(for: hero, name: profile.profile.name)
            }
            .zoomTransition(images: images()) {
                cardOverlay
            } content: {
                profileView(profile.profile)
                    .onAppear { isProfilePresented = true }
                    .onDisappear { isProfilePresented = false }
            }
            .inviteZoom(
                id: profile.id,
                isPresented: ui.showInviteBinding(profile: profile),
                sourceChrome: { cardOverlay }, //The flight drives this copy's per-element exits over the flying image
                sourceNameRect: { ProfileCardChrome.nameRect(in: $0, name: profile.profile.name) },
                popup: { invitePopup }
            )
    }
}

extension ProfileCard {
    
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
    @Environment(\.inviteChromeCloseRamp) private var closeRamp
    @Environment(\.inviteChromeNameFlying) private var nameFlying

    var body: some View {
        ZStack {
            blurBand
                //This copy's band is laid out at SOURCE size and transform-squashed over the
                //flight, so its content misregisters against the re-cropping flying image as
                //the aspect departs — visible doubling wherever the band has contrast (device
                //frames, 2026-08-13). It must exit FAST at flight launch, while the two
                //mappings still coincide. On a GESTURE close, `arrived` holds and the return
                //is the geometry-derived closeRamp — the band materialises only over the
                //final approach, where the squash is ~identity (an event fade from commit
                //rode the whole flight visibly stretched — the "squish"). The tap close
                //keeps the event fade: arrived flips and the .transition below runs it.
                .opacity(chromeArrived ? closeRamp : 1)
                .animation(chromeArrived ? SendInviteContainer.sourceChromeExit : .transition, value: chromeArrived)
            blurBackground.scrimGradient
                .opacity(chromeFade) //The colour veil rushes out with the name — a lingering scrim muddied the flight
        }
        .clipShape(.rect(cornerRadii: .init(top: 0, bottom: CornerRadius.image))) //As the modifier drew it
        .overlay(alignment: .bottomLeading) {
            overlayText
                .padding(.horizontal, Self.overlayTextInset)
                .padding(.bottom, Self.overlayBottomInset)
        }
        .animation(.transition, value: palette) //Extraction lands a frame late — the scrim fades in rather than snaps
    }

    //Overlay text geometry, shared with nameRect(in:name:) so the flight's derived anchor
    //can't drift from the layout
    static let overlayTextInset: CGFloat = Spacing.lg
    static let overlayBottomInset: CGFloat = 18 //Geometry: optically balances the side inset against the descender
    static let overlayStackGap: CGFloat = 10

    ///Where the resting card draws its name, derived from the card's frame + the overlay's
    ///constants and font metrics — the invite flight's hero text launches from exactly here.
    ///DERIVED, never measured: it stays consistent with the flight's frozen source rect, and
    ///no preference/hosting boundary can lose it (a measured anchor blanked on device).
    static func nameRect(in card: CGRect, name: String) -> CGRect {
        let nameSize = (name as NSString).size(withAttributes: [.font: UIFont.title(26, .bold)])
        let subtitleHeight = ("X" as NSString).size(withAttributes: [.font: UIFont.body(17, .medium)]).height
        let width = min(nameSize.width, card.width - overlayTextInset * 2) //A long name truncates at the card edge
        let bottom = card.maxY - overlayBottomInset - subtitleHeight - overlayStackGap
        return CGRect(x: card.minX + overlayTextInset, y: bottom - nameSize.height,
                      width: width, height: nameSize.height)
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
                //Feather INSIDE the ramp, so every pixel the mask reveals already carries
                //blur. The old clear-at-blurStart−0.06 start exposed a ~6%-of-card strip of
                //SHARP source-cropped pixels; invisible at rest (identical pixels beneath)
                //but doubled against the invite flight's re-cropping image while this copy
                //is transform-stretched (frame-measured 2026-08-13).
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
        VStack(alignment: .leading, spacing: Self.overlayStackGap) {
            Text(name)
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)
                .lineLimit(1) //The hero text is single-line; a wrapping card name would hand it a two-line frame
                .opacity(nameFlying ? 0 : chromeFade) //While a hero owns the word it never renders here; at rest it rushes out with the wash

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
                declineProfile: { onDecline(nil) } //No measured launch pad from the card's popup
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
        //Warm the invite popup's variant too — it extracts with .subtle, a DIFFERENT cache
        //key. Cold, that extraction lands mid-flight and the whole popup's tint family
        //(backdrop, seam wash) crossfades in at the end of the open — a colour snap.
        _ = await PopupColorExtractor.shared
            .extractPalette(profile.image, id: profile.id, prominence: .subtle)
    }
    
    private func images() -> [UIImage] {
        vm.profileImages[profile.id] ?? seedImages(for: profile.profile)
    }
}
