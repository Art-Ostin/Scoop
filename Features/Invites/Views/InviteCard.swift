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
            showMessageScreen: .constant(false)) {
                DynamicTimeRow(draft: $draft, timePopupOpen: $timePopupOpen, style: .card)
            } showInfo: {
                //Add scrollTo  code here to scroll to section below.
            } openInvite: {
                openInvite = eventProfile
            }
            .padding(.bottom, 28) //The card owns its bottom inset; ConfirmContainer adds none on .card
    }
    
    //The card draws white type only, so the scrim is solved against white
    private func fetchColour(image: UIImage) async {
        palette = await PopupColorExtractor.shared
            .extractPalette(
                image,
                id: eventProfile.profile.id,
                prominence: .white(clearing: 4.5),
                textRegionHeight: BlurAndGradientBackground.textRegion,
                cardAspectRatio: AspectRatio.inviteCard.ratio, //Matches AppImage(type: .invite)
                preferredScrimOpacity: 0.65, //How heavy the scrim rests when contrast doesn't force it
                maximumSurfaceLuminance: 0.05 //Never a pale tint, however light the artwork
            )
    }
}


struct BlurAndGradientBackground: ViewModifier {

    /// Fraction of the card, up from the bottom, that the scrim covers. The gradient
    /// and `extractPalette`'s sampling both derive from this one value.
    static let textRegion: CGFloat = 0.4

    /// Where the blur begins and how far it takes to reach full radius, both measured
    /// down from the top. Their sum is where it lands at full strength — keep it at or
    /// under 1, or the blur is still ramping when it runs out of card.
    static let blurStart: CGFloat = 0.67
    static let blurRamp: CGFloat = 0.32

    let palette: OverlayPalette


    func body(content: Content) -> some View {
        content
            .glur(
                radius: 24,
                offset: Self.blurStart,
                interpolation: Self.blurRamp,
                direction: .down,
                noise: 0
            )
            .overlay { scrimGradient }
            .clipShape(.rect(cornerRadii: .init(top: 0, bottom: CornerRadius.image)))
    }

    //Hand-tuned ramp through the region, reaching the solved veil at the bottom edge
    private var scrimGradient: some View {
        let region = Self.textRegion
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
