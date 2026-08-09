//
//  MeetPlaceholder.swift
//  Scoop
//
//  Created by Art Ostin on 11/07/2026.
//

import SwiftUI

// TEMPORARY DEBUG HARNESS (Claude, 2026-08-08): a Firebase-free meet card on the
// empty Meet tab so the .inviteZoom open flight, drag dismiss and backdrop fade
// can be exercised in the simulator without profile data.
// TODO: revert to the plain "Hello World" placeholder before merge.
struct MeetPlaceholder: View {

    @State private var showInvite = false
    @State private var vm = TimeAndPlaceViewModel(profileId: "debug-harness",
                                                  defaults: DefaultsManager())

    private var demoImages: [UIImage] { [UIImage(named: "Demo1")].compactMap { $0 } }

    //Geometry: AppImage's containerRelativeFrame collapses inside the placeholder's
    //width-hugging scroll (sim-verified 0×0) — the harness card sizes itself explicitly
    private var cardWidth: CGFloat { UIScreen.main.bounds.width - 32 }

    var body: some View {
        if let demo = demoImages.first {
            Color.clear
                .frame(width: cardWidth, height: cardWidth * 1.2)
                //Warm the popup's palette before any tap — a cold extraction would starve the
                //flight's frames (ProfileCard does this for the real flow)
                .task { _ = await PopupColorExtractor.shared.extractPalette(demo, id: "debug-harness", prominence: .subtle) }
                .overlay {
                    Image(uiImage: demo)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(.rect(cornerRadius: CornerRadius.image))
                .overlay(alignment: .bottomTrailing) {
                    InviteButton { showInvite = true }
                        .padding(Spacing.lg)
                }
                .inviteZoom(id: "debug-harness", isPresented: $showInvite) {
                    SendInviteContainer(
                        images: demoImages,
                        name: "Jason",
                        showInvite: $showInvite,
                        vm: vm,
                        onSendInvite: { _ in },
                        declineProfile: { }
                    )
                }
                .padding(.top, Spacing.titleGap)
        }
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
