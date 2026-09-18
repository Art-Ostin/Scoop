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
    @State private var titleRect: CGRect = .zero //Where the chrome draws the name, in the card's space

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
        photo(image: image)
            .blurBackground(rect: titleRect, image: image) //The name's own frost, cut from the artwork — the band the event pager's title wears
            .overlay(alignment: .bottomLeading) { cardChrome(image: image) }
            .coordinateSpace(.named(InviteCardOverlay.cardSpace)) //Encloses the chrome, and its bounds are the photo's — what the frost's rect is measured against
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .animation(.transition, value: palette) //Extraction lands a frame late — the pane's tone fades up out of the placeholder's black rather than snapping
            .overlay(alignment: .topTrailing) { responseButton } //Outside the clip: a lens, which it shouldn't touch
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
    
    //The artwork, sharp to the card's foot. Neither the glur nor the scrim gradient runs here any
    //more: the rows' darkening is the overlay's pane, one hard edge instead of a veil under a lens
    private func photo(image: UIImage) -> some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
    }
    
    //The card's chrome — title, rows, envelope, and the frosted window they sit on. Takes the artwork
    //because the pane cuts its blurred backdrop out of it
    private func cardChrome(image: UIImage) -> some View {
        InviteCardOverlay(
            draft: draft,
            name: eventProfile.profile.name,
            image: image,
            surface: palette.surface,
            titleRect: $titleRect
        ) { openInvite = eventProfile }
    }
        
    //Only `surface` is read — the tone the pane wears. Its solved `scrimOpacity` is ignored: the
    //pane's weight is fixed, so the card can never darken a beat after it appears
    private func fetchColour(image: UIImage) async {
        palette = await PopupColorExtractor.shared
            .extractPalette(
                image,
                id: eventProfile.profile.id,
                prominence: .custom(saturation: 0.05, brightness: 1, contrast: 4.5), //Off-white rows: full brightness, a trace of chroma
                textRegionHeight: BlurAndGradientBackground.inviteRegion,
                cardAspectRatio: AspectRatio.inviteCard.ratio, //Matches AppImage(type: .invite)
                maximumDominantLuminance: 0.15, //Prefer a dark tone the photo already has
                minimumSurfaceChroma: 0.4 //Raised, so the hue survives at that luminance
            )
        _ = await PopupColorExtractor.shared
            .extractPalette(image, id: eventProfile.profile.id, prominence: .subtle) //Warms the palette the PROFILE screens solve for the same face (Meet's card, the declined rows)
    }
}
