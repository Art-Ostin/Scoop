//
//  SendInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

//The quick-invite card and its open/close flight. The profile image is one
//persistent view that travels between the tapped card's frame (sourceFrame) and
//its slot at the top of the screen, while the card background grows outward from
//it and the content is revealed by that expansion. A single `expanded` Bool
//drives every animatable through a retargetable spring, so closing mid-open (or
//reopening mid-close) reverses smoothly. The profile card hides its own image in
//the exact frame the flight starts over — no crossfade, no reload.
struct SendInviteCard: View {

    static let flight = Animation.smooth(duration: 0.35)

    @State var vm: TimeAndPlaceViewModel

    let image: UIImage
    @Binding var expanded: Bool
    let sourceFrame: CGRect //Profile card image frame, global coords
    let hideInvite: () -> Void
    let sendInvite: (EventFieldsDraft) -> Void

    //Settled layout, measured in global coords from the content below.
    @State private var cardFrame: CGRect = .zero
    @State private var imageFrame: CGRect = .zero
    @State private var hasOpened = false

    var body: some View {
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            ZStack(alignment: .top) {
                cardBackground(origin)
                cardContent
                flightImage(origin)
            }
        }
    }
}

//Card layout — always laid out at its settled position; the flight only moves
//the render-layer background and image, never this.
extension SendInviteCard {

    private var cardContent: some View {
        VStack(spacing: 12) {
            imageSlot
            sendInviteContainer
        }
        .padding(4)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cardFrame = $0 }
        .opacity(cardFrame.height > 1 ? 1 : 0) //Nothing shows until measured
        .mask { backgroundShape(cardFrame.origin) } //Revealed by the expanding background
        .allowsHitTesting(expanded)
    }

    //Reserves the image's place in the card; the image itself renders in flightImage.
    private var imageSlot: some View {
        Color.clear
            .aspectRatio(1/1.08, contentMode: .fit)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                imageFrame = $0
                openWhenMeasured()
            }
    }

    private var sendInviteContainer: some View {
        SendInviteContainer(
            draft: $vm.event,
            name: vm.inviteModel.name,
            isInviteResponse: false,
            defaults: vm.defaults,
            onClearDraft: {vm.deleteEventDefault()},
            hideInvite: hideInvite,
            onSendInvite: {sendInvite(vm.event)}
        )
    }
}

//Flight rendering — everything interpolates between the profile card image frame
//and the settled card layout, driven only by `expanded`.
extension SendInviteCard {

    private func flightImage(_ origin: CGPoint) -> some View {
        let rect = local(expanded ? imageFrame : sourceFrame, origin)
        return Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: rect.width, height: rect.height)
            .clipShape(.rect(cornerRadius: expanded ? 16 : 20, style: .continuous))
            .position(x: rect.midX, y: rect.midY)
            .onTapGesture {hideInvite()}
    }

    private func cardBackground(_ origin: CGPoint) -> some View {
        backgroundShape(origin)
            //Grows in with the flight; zero while collapsed so only the profile
            //card's own shadow sits under the settled image.
            .shadow(color: .black.opacity(expanded ? 0.05 : 0), radius: 3, x: 0, y: 1)
            .shadow(color: .black.opacity(expanded ? 0.04 : 0), radius: 20, x: 0, y: 0)
    }

    //Shared by the background and the content mask, so rows slide out from
    //exactly under the traveling image.
    private func backgroundShape(_ origin: CGPoint) -> some View {
        let rect = local(expanded ? cardFrame : sourceFrame, origin)
        return RoundedRectangle(cornerRadius: expanded ? 24 : 20, style: .continuous)
            .fill(Color.appCanvas)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }

    private func local(_ rect: CGRect, _ origin: CGPoint) -> CGRect {
        rect.offsetBy(dx: -origin.x, dy: -origin.y)
    }

    //The open flight starts once the slot has a real frame — at most one
    //collapsed frame, pixel-identical over the profile card, passes first.
    private func openWhenMeasured() {
        guard !hasOpened, imageFrame.height > 50 else { return }
        hasOpened = true
        withAnimation(sourceFrame.width > 1 ? Self.flight : nil) { expanded = true }
    }
}
