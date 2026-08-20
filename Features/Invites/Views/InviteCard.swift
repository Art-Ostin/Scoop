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

    //Where this card ACTUALLY draws its text set, measured on the real resting overlay (global
    //space; the flight copy never reports — reportsFrames gates it). The quick-invite flight's
    //hero anchors come from these — a font-metrics derivation sat ~0.7pt/row high and snapped
    //at the close handback (device video, 2026-08-20); measurement is exact by construction.
    @State private var cardRect: CGRect = .zero
    @State private var titleRect: CGRect = .zero
    @State private var chipRect: CGRect = .zero
    @State private var timeRect: CGRect = .zero
    @State private var placeRect: CGRect = .zero
    @State private var envelopeRect: CGRect = .zero

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
                cardOverlay(image: image, reportsFrames: true) //The REAL overlay — the flight's source anchors measure here
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

    //The measured text set as card-relative offsets — read live at popup construction, so the
    //flight lifts off from wherever the card genuinely drew its words
    private var measuredSourceRects: InviteCardSourceRects {
        guard cardRect.width > 1 else { return InviteCardSourceRects() }
        func rel(_ r: CGRect) -> CGRect {
            r.width > 1 ? r.offsetBy(dx: -cardRect.minX, dy: -cardRect.minY) : .zero
        }
        return InviteCardSourceRects(
            title: rel(titleRect),
            chip: rel(chipRect),
            time: rel(timeRect),
            place: rel(placeRect),
            envelope: rel(envelopeRect)
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
            sourceRects: measuredSourceRects,
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
    
    //reportsFrames: true only on the REAL overlay — the flight's chrome copy renders these
    //same views at the flight layer and must never overwrite the measured source anchors
    private func cardOverlay(image: UIImage, reportsFrames: Bool = false) -> some View {
        blurAndColour(image: image)
            //The flight's copy rushes the blur + scrim out in the launch's first beats (the
            //sharp flying image is what lands) and rides them back in over the collapse; the
            //resting card reads the identity default
            .modifier(InviteChromeFadeOpacity())
            .overlay(alignment: .bottomLeading) {
                inviteOverlay(reportsFrames: reportsFrames)
            }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { rect in
                if reportsFrames { cardRect = rect } //The frame all measured offsets are relative to
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
    
    private func inviteOverlay(reportsFrames: Bool) -> some View {
        //Container has already 24 horizontal padding.
        ConfirmContainer(
            event: InviteSummary(event: draft.originalInvite.event),
            name: eventProfile.profile.name,
            style: .card,
            timeOpen: timePopupOpen,
            showMessageSection: true,
            color: palette.secondaryText,
            showMessageScreen: .constant(false),
            placeRowFrame: reportsFrames ? $placeRect : nil,
            cardTitleFrame: reportsFrames ? $titleRect : nil,
            chipFrame: reportsFrames ? $chipRect : nil,
            envelopeFrame: reportsFrames ? $envelopeRect : nil) {
                DynamicTimeRow(draft: $draft, timePopupOpen: $timePopupOpen, style: .card)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { rect in
                        if reportsFrames { timeRect = rect }
                    }
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


