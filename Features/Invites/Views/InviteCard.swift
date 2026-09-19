//
//  InviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 06/06/2026.


import SwiftUI


struct InviteSlot: View {
    
    //Injected Parameters
    let vm: InvitesViewModel
    let eventProfile: EventProfile
    var cardInset: CGFloat? = nil

    let onRespond: (ProfileResponse, SendInviteFlightSource?) -> Void

    @Binding var draft: RespondDraft
    
    @Binding var openInvite: EventProfile?
    @Binding var showInviteHistory: EventProfile?

    //Local Parameters
    @State var palette: OverlayPalette = .placeholder

    var body: some View {
        VStack(spacing: 72) {
            if let image = eventProfile.image {
                profileCard(image: image)
            }
            CustomDivider().padding(.horizontal, 72)
            InviteInfo(event: eventProfile)
        }
    }
}

extension InviteSlot {
    
    private func profileCard(image: UIImage) -> some View {
        AppImage(image: image, type: .invite, insetOverride: cardInset)
            .task(id: eventProfile.id) {await fetchColour(image: image)}
            .zoomTransition(images: profileImages) {
                cardOverlay(image: image)
            } content: {
                profileView
            }
            .eventZoomSource(image) { cardOverlay(image: image) } //The photo lifts off into the card; this copy of the chrome rides it out
            .eventZoom(isPresented: quickResponsePresented, inset: 10) { respondPopup }
    }

    private var quickResponsePresented: Binding<Bool> {
        Binding(
            get: { openInvite?.id == eventProfile.id },
            set: { presented in
                if presented {
                    openInvite = eventProfile
                } else if openInvite?.id == eventProfile.id {
                    openInvite = nil
                }
            }
        )
    }

    //The respond card growing out of this image; the response itself stays the container's
    private var respondPopup: some View {
        RespondToInviteContainer(
            vm: vm.respondVM(for: eventProfile),
            images: profileImages,
            respond: onRespond
        )
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
        .respondToInvite(respondVM: vm.respondVM(for: eventProfile), onResponse: { onRespond($0, nil) })
    }
}


//Overlay on the Card
extension InviteSlot {
    
    //Drawn over the card at rest, and copied onto the event zoom's flying cover
    private func cardOverlay(image: UIImage) -> some View {
        blurAndColour(image: image)
            .overlay(alignment: .bottomLeading) { cardOverlay }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .animation(.transition, value: palette) //Extraction lands a frame late — scrim and tint fade in rather than snap
            .overlay(alignment: .topTrailing) { responseButton } //Outside the clip and the palette's curve: a lens, which neither should touch
    }

    //The invite's history, in the card's corner. On the card rather than the slot so it lifts off with
    //the photo and morphs into the respond card's own corner control (`.eventZoomCornerSource`)
    @ViewBuilder
    private var responseButton: some View {
        if draft.originalInvite.event.pastProposals?.isEmpty == false { //The respond card's own gate, off the same draft
            InviteHistoryButton { showInviteHistory = eventProfile }
                .eventZoomCornerSource { InviteHistoryButton.capsule }
                .padding([.top, .trailing], ZoomStyle.cornerRadius - InviteHistoryButton.height / 2) //Geometry: concentric — the capsule's round end centred on the card corner's arc, whatever the pager's inset
        }
    }
    
    private func blurAndColour(image: UIImage) -> some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .modifier(BlurAndGradientBackground(
                textRegion: BlurAndGradientBackground.inviteRegion,
                blurReach: 0.75, //Lower than the default 0.825 — about 16pt nearer the name
                colourRegion: BlurAndGradientBackground.inviteColourRegion, //The colour reaches higher than the blur
                colour: palette.surface,
                scrimOpacity: palette.scrimOpacity
            ))
    }
    
    private var cardOverlay: some View {
        InviteCardOverlay(draft: draft, name: eventProfile.profile.name) { openInvite = eventProfile }
    }
        
    //The title stays white; the time and place rows wear the artwork's hue, so the scrim is solved against that tint
    private func fetchColour(image: UIImage) async {
        palette = await PopupColorExtractor.shared
            .extractPalette(
                image,
                id: eventProfile.profile.id,
                prominence: .custom(saturation: 0.05, brightness: 1, contrast: 4.5), //Off-white: full brightness, just enough chroma to read as the artwork's hue
                textRegionHeight: BlurAndGradientBackground.inviteColourRegion, //The tone is solved over the area the colour covers
                cardAspectRatio: AspectRatio.inviteCard.ratio, //Matches AppImage(type: .invite)
                maximumDominantLuminance: 0.15, //Prefer a dark tone the photo already has
                minimumSurfaceChroma: 0.4 //Quieter than the standard tint — the rows carry the hue here
            )
        _ = await PopupColorExtractor.shared
            .extractPalette(image, id: eventProfile.profile.id, prominence: .subtle)
    }
}
