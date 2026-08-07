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
            .modifier(BlurAndGradientBackground(
                textRegion: BlurAndGradientBackground.inviteRegion,
                colour: palette.surface,
                scrimOpacity: palette.scrimOpacity
            ))
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
                maximumDominantLuminance: 0.15, //Prefer a dark tone the photo already has
                minimumSurfaceChroma: 0.4 //Quieter than the standard tint — the rows carry the hue here
            )
    }
}


