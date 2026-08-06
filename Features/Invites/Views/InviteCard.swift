//
//  NewInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 06/06/2026.


import SwiftUI
import Glur


struct InviteSlot: View {
    
    //Injected Parameters
    let vm: InvitesViewModel
    let eventProfile: EventProfile
    
    let onRespond: (ProfileResponse) -> Void
    
    @Binding var draft: RespondDraft
    
    @Binding var openInvite: EventProfile?

    //Local Parameters
    @State var palette: OverlayPalette = .placeholder
    @State private var timePopupOpen = false
    
    var body: some View {
        VStack(spacing: 72) {
            if let image = eventProfile.image {
                profileCard(image: image)
            }
            
            CustomDivider().padding(.horizontal, 72)
            InviteInfo(event: eventProfile)
        }
        .padding(.top, -20) //So it appears closer to the top
    }
}

extension InviteSlot {
    
    private func profileCard(image: UIImage) -> some View {
        AppImage(image: image , type: .invite)
            .task(id: eventProfile.id) {await fetchColour(image: image)}
            .zoomTransition(images: profileImages) {
                cardOverlay(image: image)
            } content: {
                profileView
            }
    }
    
    //Profile View overlay
    private var profileView: some View {
        ProfileContainer(
            vm: vm.profileVM(for: eventProfile),
            profileImages: profileImages,
            mode: responseMode
        )
    }
    
    private var profileImages: [UIImage] {
        let loaded = vm.profileImages[eventProfile.profile.id] ?? []
        return loaded.isEmpty ? eventProfile.image.map { [$0] } ?? [] : loaded
    }

    private var responseMode: ProfileMode {
        .respondToInvite(respondVM: vm.respondVM(for: eventProfile), onResponse: onRespond)
    }
}


//Overlay on the Card
extension InviteSlot {
    
    private func cardOverlay(image: UIImage) -> some View {
        blurAndColour(image: image)
            .overlay(alignment: .bottomLeading) {
                inviteOverlay
            }
            .animation(.transition, value: palette) //Extraction lands a frame late — scrim and tint fade in rather than snap
    }
    
    private func blurAndColour(image: UIImage) -> some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .modifier(BlurAndGradientBackground(palette: palette))
    }
    
    private var inviteOverlay: some View {
        //Container has already 24 horizontal padding.
        ConfirmContainer(
            event: InviteSummary(event: draft.originalInvite.event),
            name: eventProfile.profile.name,
            style: .card,
            timeOpen: timePopupOpen,
            showMessageSection: true,
            color: palette.secondaryText,
            showMessageScreen: .constant(false)) {
                DynamicTimeRow(draft: $draft, timePopupOpen: $timePopupOpen, style: .card)
            } showInfo: {
                //Add scrollTo  code here to scroll to section below.
            } openInvite: {
                openInvite = eventProfile
            }
            .padding(.bottom, 28) //The card owns its bottom inset; ConfirmContainer adds none on .card
    }
    
    //The title stays white; the time and place rows wear the artwork's hue, so the scrim is solved against that tint
    private func fetchColour(image: UIImage) async {
        palette = await PopupColorExtractor.shared
            .extractPalette(
                image,
                id: eventProfile.profile.id,
                prominence: .custom(saturation: 0.05, brightness: 1, contrast: 4.5), //Off-white: full brightness, just enough chroma to read as the artwork's hue
                textRegionHeight: BlurAndGradientBackground.inviteRegion,
                cardAspectRatio: AspectRatio.inviteCard.ratio, //Matches AppImage(type: .invite)
                preferredScrimOpacity: 0.9, //How heavy the scrim rests when contrast doesn't force it
                maximumDominantLuminance: 0.15, //Prefer a dark tone the photo already has
                minimumSurfaceChroma: 0.4, //Let the hue read, without lightening the scrim
                maximumSurfaceLuminance: 0.05 //Never a pale tint, however light the artwork
            )
    }
}


struct BlurAndGradientBackground: ViewModifier {

    /// How far up the card the treatment reaches, as a fraction of its height. The one
    /// knob: the blur's start and ramp are held at a fixed ratio to it, and
    /// `extractPalette`'s sampling derives from it too.
    static let inviteRegion: CGFloat = 0.4   //1:1.5 art under a whole confirm block
    static let profileRegion: CGFloat = 0.28 //1:1.2 art under two lines — starts lower, at 0.72

    //Injected Parameters
    var textRegion: CGFloat = Self.inviteRegion
    var blurRadius: CGFloat = 24

    let palette: OverlayPalette

    /// Where the blur begins and how far it takes to reach full radius, both measured
    /// down from the top. Their sum stays just under 1 at any region, so the blur lands
    /// at full strength on the bottom edge instead of running out of card mid-ramp.
    private var blurStart: CGFloat { 1 - textRegion * 0.825 }
    private var blurRamp: CGFloat { textRegion * 0.8 }


    func body(content: Content) -> some View {
        content
            .glur(
                radius: blurRadius,
                offset: blurStart,
                interpolation: blurRamp,
                direction: .down,
                noise: 0
            )
            .overlay { scrimGradient }
            .clipShape(.rect(cornerRadii: .init(top: 0, bottom: CornerRadius.image)))
    }

    //Hand-tuned ramp through the region, reaching the solved veil at the bottom edge
    private var scrimGradient: some View {
        let region = textRegion
        let top = 1 - region
        let colour = palette.surface
        let veil = palette.scrimOpacity

        //Measures top of Colour based of blur
        return LinearGradient(
            stops: [
                .init(color: colour.opacity(0),           location: top),
                .init(color: colour.opacity(veil * 0.67), location: top + region * 0.5),
                .init(color: colour.opacity(veil * 0.78), location: top + region * 0.625),
                .init(color: colour.opacity(veil),        location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}
