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
    ///Set by the container: the lone-invite layout runs its card out to the nav title's edge
    var cardInset: CGFloat? = nil

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
            //The quick-respond popup grows out of this card on the root plane; the flight
            //drives the chrome copy's per-element exits while the hero text flies separately
            .inviteZoom(
                id: eventProfile.id,
                isPresented: quickResponsePresented,
                sourceChrome: { cardOverlay(image: image) },
                popup: { respondPopup }
            )
    }

    //The envelope button writes the SHARED EventProfile? slot (openInvite); this narrows it to
    //this card's own Bool for the zoom modifier
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

    //The quick-respond popup: built here (not in InvitesContainer's overlay) so the flight can
    //grow it out of this card. State inside survives re-invocations — the layer keys it by id.
    private var respondPopup: some View {
        RespondInviteContainer(
            images: profileImages,
            vm: vm.respondVM(for: eventProfile),
            timeAndPlaceVM: TimeAndPlaceViewModel(profileId: eventProfile.profile.id, defaults: vm.defaults),
            showInvite: quickResponsePresented,
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
    
    private func cardOverlay(image: UIImage) -> some View {
        blurAndColour(image: image)
            //The flight's copy rushes the blur + scrim out in the launch's first beats (the
            //sharp flying image is what lands) and rides them back in over the collapse; the
            //resting card reads the identity default
            .modifier(InviteChromeFadeOpacity())
            .overlay(alignment: .bottomLeading) {
                inviteOverlay
            }
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
    
    //The scrim's flight exit, as its own modifier DELIBERATELY: the environment must be read
    //by a view INSTALLED in the flight layer's subtree. Read as an InviteSlot property inside
    //the sourceChrome closure, the resting default (1) bakes into the copy at construction and
    //the flight's writes never reach it — the CustomMenu env-scoping rule.
    private struct InviteChromeFadeOpacity: ViewModifier {
        @Environment(\.inviteChromeFade) private var chromeFade

        func body(content: Content) -> some View {
            content.opacity(chromeFade)
        }
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
        //Warm the quick-respond popup's variant too — it extracts with .subtle, a DIFFERENT
        //cache key. Cold, that extraction lands mid-flight and the popup's tint family
        //(backdrop, seam wash) crossfades in at the end of the open — a colour snap.
        _ = await PopupColorExtractor.shared
            .extractPalette(image, id: eventProfile.profile.id, prominence: .subtle)
    }
}


