//
//  MeetPlaceholder.swift
//  Scoop
//
//  Created by Art Ostin on 11/07/2026.
//

import SwiftUI

// TEMPORARY DEBUG HARNESS (Claude, 2026-08-08): a Firebase-free meet card on the
// empty Meet tab so the .inviteZoom open flight, drag dismiss and backdrop fade
// can be exercised in the simulator without profile data. Wears the real
// ProfileCardChrome (2026-08-13) so the flight's chrome hand-offs — band exit,
// name hero, invite-icon pop — run exactly as on a live profile card.
// TODO: revert to the plain "Hello World" placeholder before merge.
struct MeetPlaceholder: View {

    //Optional, as MeetContainer holds it: absent in the standalone preview, where a send
    //simply does nothing — the harness only drives the cover inside the real app tree
    @Environment(ResponseCoverPresenter.self) private var responseCover: ResponseCoverPresenter?

    @State private var showInvite = false
    @State private var palette: OverlayPalette = .placeholder
    @State private var vm = TimeAndPlaceViewModel(profileId: "debug-harness",
                                                  defaults: DefaultsManager())

    //Demo5: bright rock texture fills the bottom-left corner AND the blur-band region —
    //the high-contrast content both the band hand-off and the title-halo hand-off must be
    //verified against (dark-bottomed demos physically cannot show either misregistration)
    private var demoImages: [UIImage] { [UIImage(named: "Demo5")].compactMap { $0 } }

    //Geometry: AppImage's containerRelativeFrame collapses inside the placeholder's
    //width-hugging scroll (sim-verified 0×0) — the harness card sizes itself explicitly
    private var cardWidth: CGFloat { UIScreen.main.bounds.width - 32 }

    var body: some View {
        if let demo = demoImages.first {
            Color.clear
                .frame(width: cardWidth, height: cardWidth * 1.2)
                //Warm both palettes AND the band bake before any tap, exactly as ProfileCard
                //does — cold, the flight's first frames are starved of tint and band
                .task {
                    palette = await PopupColorExtractor.shared.extractPalette(demo, id: "debug-harness")
                    _ = await PopupColorExtractor.shared.extractPalette(demo, id: "debug-harness", prominence: .subtle)
                    await InviteBandBake.warm(for: demo, name: "Jason")
                }
                .overlay {
                    Image(uiImage: demo)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(.rect(cornerRadius: CornerRadius.image))
                //The real card's resting shadow is drawn by the zoomTransition marker
                //(ZoomStyle.cardShadows); the harness wears the flight's folded replica of it
                //so the open's frame-one shadow has the same baseline to hand off from
                .shadow(color: .black.opacity(SendInviteContainer.sourceShadow.contact.opacity),
                        radius: SendInviteContainer.sourceShadow.contact.radius,
                        x: 0, y: SendInviteContainer.sourceShadow.contact.y)
                .shadow(color: .black.opacity(SendInviteContainer.sourceShadow.ambient.opacity),
                        radius: SendInviteContainer.sourceShadow.ambient.radius,
                        x: 0, y: SendInviteContainer.sourceShadow.ambient.y)
                .overlay { chrome }
                .inviteZoom(
                    id: "debug-harness",
                    isPresented: $showInvite,
                    sourceChrome: { chrome },
                    sourceNameRect: { ProfileCardChrome.nameRect(in: $0, name: "Jason") }
                ) {
                    SendInviteContainer(
                        images: demoImages,
                        name: "Jason",
                        showInvite: $showInvite,
                        vm: vm,
                        onSendInvite: { _, sendFlight in sendInvite(sendFlight) },
                        declineProfile: { }
                    )
                }
                .padding(.top, Spacing.titleGap)
        }
    }

    //MeetContainer.respondToProfile's cover flow, minus Firebase: the send cover (and its
    //hero flight) runs exactly as on a live profile, the popup leaves under the opaque wash
    private func sendInvite(_ sendFlight: SendInviteFlightSource?) {
        let cover = responseCover?.show(.newInvite, sendFlight: sendFlight)
        Task {
            async let minDelay: Void = Task.sleep(for: .seconds(3.5))
            try? await Task.sleep(for: BlurCoverMotion.coveredAt)
            showInvite = false
            try? await minDelay
            responseCover?.close(cover)
        }
    }

    //The real card chrome, resting and flying — identical construction to ProfileCard's
    private var chrome: some View {
        ProfileCardChrome(
            image: demoImages.first ?? UIImage(),
            name: "Jason",
            subtitle: "U3 · Physics · Montreal",
            palette: palette,
            onInvite: { showInvite = true }
        )
    }
}

#Preview {
    @Previewable @State var presenter = InviteZoomPresenter()

    ZStack {
        ScrollView { MeetPlaceholder() }
        InviteZoomLayer(presenter: presenter)
    }
    .environment(presenter)
}
