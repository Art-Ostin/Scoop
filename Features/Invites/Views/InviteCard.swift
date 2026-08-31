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
    @Binding var showInviteHistory: EventProfile?

    //Local Parameters
    @State var palette: OverlayPalette = .placeholder

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
            .inviteZoom(
                id: eventProfile.id,
                isPresented: quickResponsePresented,
                sourceChrome: { cardOverlay(image: image) },
                popup: { respondPopup }
            )
            .overlay(alignment: .topTrailing) {
//                if thereArePastInvites() {
                    inviteHistoryButton
                        .padding()
//                }
            }
    }

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
        let summary = InviteSummary(event: draft.originalInvite.event)
        return ConfirmContainer(
            event: summary,
            name: eventProfile.profile.name,
            style: .card,
            timeOpen: false, //Nothing on the card opens a popup over it any more
            showMessageSection: true,
            color: palette.secondaryText,
            showMessageScreen: .constant(false),
            placeRowFrame: reportsFrames ? $placeRect : nil,
            cardTitleFrame: reportsFrames ? $titleRect : nil,
            chipFrame: reportsFrames ? $chipRect : nil,
            envelopeFrame: reportsFrames ? $envelopeRect : nil) {
                //A plain line, never a menu: choosing a day — and proposing new ones — belongs
                //to the respond popup, the only surface that can commit the choice. One day, not
                //the whole run: three days at 20pt shrink to an unreadable line, and it is the
                //day the popup preselects anyway. (Meet's pending card lists all three at 16.)
                StaticTimeRow(proposedTimes: summary.time, style: .card, namesOneDay: true)
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

