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

    let image: UIImage
    let name: String
    let details: String
    let rect: CGRect //Current image frame in the card's local space
    @Binding var expanded: Bool
    let settled: Bool
    let showsHideButton: Bool
    let hideInvite: () -> Void

    @State private var meetWidth: CGFloat = 0
    @State private var detailsHeight: CGFloat = 0
    @State private var nameSize: CGSize = .zero
    @State private var hideButtonSize: CGSize = .zero
    @State private var inviteButtonPopped = false

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: rect.width, height: rect.height)
            .clipShape(.rect(
                topLeadingRadius: expanded ? SendInviteCard.imageRadius : SendInviteCard.sourceRadius,
                bottomLeadingRadius: expanded ? SendInviteCard.imageBottomRadius : SendInviteCard.sourceRadius,
                bottomTrailingRadius: expanded ? SendInviteCard.imageBottomRadius : SendInviteCard.sourceRadius,
                topTrailingRadius: expanded ? SendInviteCard.imageRadius : SendInviteCard.sourceRadius,
                style: .continuous
            ))
            .onTapGesture { hideInvite() }
            .allowsHitTesting(expanded && !settled)
            .overlay { blur(rect.size) }
            .overlay { chrome }
            .overlay(alignment: .bottomTrailing) { reopenTapTarget }
            .position(x: rect.midX, y: rect.midY)
            .opacity(settled ? 0 : 1) //Carousel takes over once landed
    }
}

extension SendInviteFlight {

    //ProfileCard's BackgroundBlur treatment, rebuilt on the flight's own anchors: measured
    //frames never hold in-flight interpolation, so the halo must ride nameText's animated
    //paddings or it parks at the destination and snaps in at the end.
    private func blur(_ size: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .blur(radius: BackgroundBlur.imageBlurRadius)
            .mask { blurHalo }
            .clipShape(.rect(cornerRadius: SendInviteCard.imageBottomRadius, style: .continuous))
            .allowsHitTesting(false)
            .opacity(expanded ? 1 : 0)
    }

    //Paddings and offset stay in lockstep with nameText's.
    private var blurHalo: some View {
        Color.clear
            .overlay(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: BackgroundBlur.haloCornerRadius)
                    .frame(
                        width: nameSize.width + 2 * BackgroundBlur.haloWidthOutset,
                        height: max(nameSize.height - 2 * SendInviteCard.nameBlurInset, 0)
                    )
                    .blur(radius: BackgroundBlur.haloBlurRadius)
                    .padding(.leading, (expanded ? SendInviteContainer.contentPadding : 16) - BackgroundBlur.haloWidthOutset)
                    .padding(.bottom, (expanded ? SendInviteCard.chromeBottomPadding : 16 + detailsHeight + 8) + SendInviteCard.nameBlurInset)
                    .offset(x: expanded ? 0 : -meetWidth)
            }
    }

    private var chrome: some View {
        Color.clear
            .overlay(alignment: .bottomLeading) { detailsText }
            .overlay(alignment: .bottomLeading) { nameText }
            .overlay(alignment: .bottomTrailing) { inviteButtonReplica }
            .allowsHitTesting(false) //Interaction belongs to the settled carousel
    }

    //Collapsed replicates ProfileCard's infoSection anchors; expanded lands exactly on the carousel's copy.
    private var nameText: some View {
        HStack(spacing: 0) {
            Text("Meet ")
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { meetWidth = $0 }
                .opacity(expanded ? 1 : 0)
            Text(name)
        }
        .font(.title(26))
        .foregroundStyle(Color.white)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { nameSize = $0 }
        .padding(.leading, expanded ? SendInviteContainer.contentPadding : 16)
        .padding(.bottom, expanded ? SendInviteCard.chromeBottomPadding : 16 + detailsHeight + 8)
        .offset(x: expanded ? 0 : -meetWidth) //Collapsed: the bare name sits at the 16pt inset
    }

    private var detailsText: some View {
        Text(details)
            .font(.body(14, .medium))
            .foregroundStyle(Color.white)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { detailsHeight = $0 }
            .padding(.leading, 16)
            .padding(.bottom, 16)
            .opacity(expanded ? 0 : 1)
            .blur(radius: expanded ? 6 : 0)
    }

    //Decorative copy of ProfileCard's invite button: the tap that opened the invite covered
    //the real button mid-press, so the replica starts at the pressed scale and plays the release bounce.
    //On expand it morphs into the Hide pill: both ride this one anchor, cross-fading mid-flight.
    private var inviteButtonReplica: some View {
        InviteButton(isInviting: true, morphId: "quick-invite-flight-copy", action: {})
            .scaleEffect(inviteButtonPopped ? 1 : PressEffect.shrink.scale)
            .opacityPop(visible: !expanded)
            .padding(.trailing, buttonTrailingPadding)
            .padding(.bottom, buttonBottomPadding)
            .task {
                withAnimation(.spring(response: PressEffect.shrink.release.response,
                                      dampingFraction: PressEffect.shrink.release.damping)) {
                    inviteButtonPopped = true
                }
            }
    }


    //Expanded targets land the pill exactly on the carousel's copy (trailing edge at contentPadding,
    //centered on the name line) so the settle handoff is invisible. No pill → fade in place as before.
    private var buttonTrailingPadding: CGFloat {
        guard expanded, showsHideButton else { return 16 }
        return SendInviteContainer.contentPadding + (hideButtonSize.width - InviteButton.diameter) / 2
    }

    private var buttonBottomPadding: CGFloat {
        guard expanded, showsHideButton else { return 16 }
        return SendInviteCard.chromeBottomPadding + (nameSize.height - InviteButton.diameter) / 2
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
