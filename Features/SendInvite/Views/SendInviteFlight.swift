//
//  SendInviteFlight.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

//The image + chrome that fly between the profile card and the expanded invite card:
//pixel-identical over ProfileCard's overlay when collapsed and over the carousel's
//chrome when settled, so both handoffs are invisible.
struct SendInviteFlight: View {

    //Injected
    let image: UIImage
    let name: String
    let details: String
    let rect: CGRect //Current image frame in the card's local space
    @Binding var expanded: Bool
    let settled: Bool
    var dragImage: UIImage? = nil //Interactive dismiss: the carousel page the drag picked up
    var dragging: Bool = false //Finger owns the card; the tap-to-close mustn't fire under it
    var optionsVisible: Bool = true //Flips at drag release (not spring completion) so the menu pops back in riding the spring-back
    let hideInvite: () -> Void

    //Local view state
    @State private var detailsHeight: CGFloat = 0
    @State private var topNameSize: CGSize = .zero
    @State private var inviteButtonPopped = false

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: rect.width, height: rect.height)
            .overlay { dragImageOverlay }
            .clipShape(.rect(
                topLeadingRadius: expanded ? 24 : SendInviteCard.sourceRadius,
                bottomLeadingRadius: expanded ? 24 : SendInviteCard.sourceRadius,
                bottomTrailingRadius: expanded ? 24 : SendInviteCard.sourceRadius,
                topTrailingRadius: expanded ? 24 : SendInviteCard.sourceRadius
            ))
            .onTapGesture { hideInvite() }
            .allowsHitTesting(expanded && !settled && !dragging)
            .overlay { blur(rect.size) }
            .overlay { chrome }
            .overlay(alignment: .bottomTrailing) { reopenTapTarget }
            .position(x: rect.midX, y: rect.midY)
            .opacity(settled ? 0 : 1)
    }
}

extension SendInviteFlight {

    @ViewBuilder
    private var dragImageOverlay: some View {
        if let dragImage {
            Image(uiImage: dragImage)
                .resizable()
                .scaledToFill()
                .frame(width: rect.width, height: rect.height)
                .opacity(expanded ? 1 : 0)
        }
    }

    private func blur(_ size: CGSize) -> some View {
        Image(uiImage: dragImage ?? image) //Halo must blur the page actually showing
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .blur(radius: BackgroundBlur.imageBlurRadius)
            .mask { topBlurHalo }
            .clipShape(.rect(cornerRadius: 24))
            .allowsHitTesting(false)
            .opacity(expanded ? 1 : 0)
    }

    //Matches InviteImageCarousel's BackgroundBlur halo behind the top name, so the settle swap is invisible.
    private var topBlurHalo: some View {
        Color.clear
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: BackgroundBlur.haloCornerRadius)
                    .frame(
                        width: topNameSize.width + 2 * BackgroundBlur.haloWidthOutset,
                        height: max(topNameSize.height - 2 * SendInviteCard.nameBlurInset, 0)
                    )
                    .blur(radius: BackgroundBlur.haloBlurRadius)
                    .padding(.leading, InviteImageCarousel.nameLeadingInset - BackgroundBlur.haloWidthOutset)
                    .padding(.top, InviteImageCarousel.nameTopInset + SendInviteCard.nameBlurInset)
            }
    }

    private var chrome: some View {
        Color.clear
            .overlay(alignment: .bottomLeading) { detailsText }
            .overlay(alignment: .bottomLeading) { nameText }
            .overlay(alignment: .topLeading) { topName }
            .overlay(alignment: .bottomTrailing) { inviteButtonReplica }
            .overlay(alignment: .topTrailing) { optionsMenuReplica }
            .allowsHitTesting(false) //Interaction belongs to the settled carousel
    }

    //Collapsed only: the bare name at ProfileCard's 16pt inset, fading out in place as the card opens
    //(the "Meet Name" copy takes over at the top). Kept so the close handoff lands back on ProfileCard.
    private var nameText: some View {
        Text(name)
            .font(.title(26))
            .foregroundStyle(Color.white)
            .padding(.leading, Spacing.md)
            .padding(.bottom, Spacing.md + detailsHeight + Spacing.xs)
            .opacity(expanded ? 0 : 1)
            .blur(radius: expanded ? 6 : 0)
    }

    //The expanded name: pops in over the flight as the card opens and lands exactly on the carousel's
    //top-leading copy at settle. Same HStack structure as the carousel so the glyph layout matches at the handoff.
    private var topName: some View {
        HStack(spacing: Spacing.hairline) { //Must match the carousel's name HStack for the handoff
            Text("Meet")
            Text(name)
        }
        .font(.title(26))
        .foregroundStyle(Color.white)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { topNameSize = $0 }
        .padding(.top, InviteImageCarousel.nameTopInset)
        .padding(.leading, InviteImageCarousel.nameLeadingInset)
        .opacityPop(visible: expanded)
    }

    //Decorative copy of the carousel's options menu: pops with the open/close flight like the top name,
    //and pops out the moment a dismiss drag grabs the card (the live Menu hides with the carousel swap).
    private var optionsMenuReplica: some View {
        InviteOptionsIcon()
            .blurPop(visible: optionsVisible)
            .padding(.top, InviteImageCarousel.nameTopInset)
            .padding(.trailing, InviteImageCarousel.nameLeadingInset)
    }

    private var detailsText: some View {
        Text(details)
            .font(.body(14, .medium))
            .foregroundStyle(Color.white)
            .getHeight($detailsHeight)
            .padding(.leading, Spacing.md)
            .padding(.bottom, Spacing.md)
            .opacity(expanded ? 0 : 1)
            .blur(radius: expanded ? 6 : 0)
    }

    //Decorative copy of ProfileCard's invite button: the tap that opened the invite covered
    //the real button mid-press, so the replica starts at the pressed scale and plays the release
    //bounce. On expand it fades out in place.
    private var inviteButtonReplica: some View {
        InviteButton(isInviting: true, action: {})
            .scaleEffect(inviteButtonPopped ? 1 : PressEffect.shrink.scale)
            .opacityPop(visible: !expanded)
            .padding([.trailing, .bottom], 16)
            .task {
                withAnimation(.spring(response: PressEffect.shrink.release.response,
                                      dampingFraction: PressEffect.shrink.release.damping)) {
                    inviteButtonPopped = true
                }
            }
    }

    //Invisible target over the invite-button replica: the real card button underneath is
    //opacity-0 (takes no hits), so a tap mid-close would otherwise fall through and open the profile.
    private var reopenTapTarget: some View {
        Color.clear
            .frame(width: 56, height: 56)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(SendInviteCard.openFlight) { expanded = true } }
            .padding([.trailing, .bottom], 8)
            .allowsHitTesting(!expanded && !settled)
    }
}
