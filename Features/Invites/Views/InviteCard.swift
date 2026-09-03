//
//  InviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 06/06/2026.


import SwiftUI
import Glur


struct InviteSlot: View {
    
    //Injected Parameters
    let vm: InvitesViewModel
    let eventProfile: EventProfile
    ///Set by the container: the lone-invite layout runs its card out to the nav title's edge
    var cardInset: CGFloat? = nil

    let onRespond: (ProfileResponse) -> Void
    
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
            .eventZoom(isPresented: quickResponsePresented) { respondPopup }
            .overlay(alignment: .topTrailing) {
                if thereArePastInvites() {
                    inviteHistoryButton
                        .padding()
                }
            }
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
            showInvite: quickResponsePresented,
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
        .respondToInvite(respondVM: vm.respondVM(for: eventProfile), onResponse: onRespond)
    }
}


//Overlay on the Card
extension InviteSlot {
    
    //Drawn over the card at rest, and copied onto the event zoom's flying cover
    private func cardOverlay(image: UIImage) -> some View {
        blurAndColour(image: image)
            .overlay(alignment: .bottomLeading) { inviteOverlay }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
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
        VStack {
            Text(InviteCardTitle.text(name: name))
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)
            
            
            
            
            
        }
    }
    
    
    private var inviteOverlay: some View {
        let summary = InviteSummary(event: draft.originalInvite.event)
        return ConfirmContainer(
            event: summary,
            name: eventProfile.profile.name,
            style: .card,
            timeOpen: false, //Nothing on the card opens a popup over it any more
            showMessageSection: true,
            color: palette.secondaryText,
            showMessageScreen: .constant(false)) {
                StaticTimeRow(proposedTimes: summary.time, style: .card, namesOneDay: true)
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
        _ = await PopupColorExtractor.shared
            .extractPalette(image, id: eventProfile.profile.id, prominence: .subtle)
    }
}

extension InviteSlot {
    
    func thereArePastInvites() -> Bool {
        eventProfile.event.pastProposals != nil
    }
    
    private var inviteHistoryButton: some View {
        ScoopButton(style: .clearGlass, shape: Capsule()) {
            showInviteHistory = eventProfile
        } label: {
            Text("Respond")
                .frame(width: 40, height: 24)
        }
    }
}
