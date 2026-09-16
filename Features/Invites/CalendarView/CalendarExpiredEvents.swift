//
//  CalendarExpiredEvents.swift
//  Scoop
//
//  Created by Art Ostin on 15/09/2026.
//

import SwiftUI

struct CalendarExpiredEvents: View {

    //Injected
    let expiredInvites: [EventProfile]
    let card: (EventProfile) -> AnyView //The same respond card the pending rows open

    //Local view state
    @State private var selectedLensID: String? //Which avatar's card is open

    //Geometry: a primary AvatarFace is 54pt (44pt photo + 5pt ring each side); 4 across + 3 gaps = 288pt, inside the smallest iPhone's 327pt column
    private var columns: [GridItem] {
        //One column per invite, up to 4: the grid centres fixed columns, so up to 3 invites sit as one row in the middle
        Array(repeating: GridItem(.fixed(AvatarFace.lensFrame), spacing: Spacing.lg), count: expiredInvites.count.clamped(to: 1...4))
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.lg) {
            ForEach(expiredInvites) { invite in
                avatarButton(invite: invite)
            }
        }
    }
}

//Views
extension CalendarExpiredEvents {

    private func avatarButton(invite: EventProfile) -> some View {
        Button {
            selectedLensID = invite.id //One avatar per invite here, so its id alone is the lens id
        } label: {
            AvatarFace(image: invite.image, isFirst: true) //An expired invite has no later day to echo onto
        }
        .shrinkButton()
        .instantPressDelivery()
        .accessibilityLabel(invite.profile.name)
        .eventZoom(isPresented: isPresented(invite.id)) {
            card(invite)
        }
    }

    //Clears only if it's still this avatar's, so a card that finishes closing can't close a newer one
    private func isPresented(_ lensID: String) -> Binding<Bool> {
        Binding {
            selectedLensID == lensID
        } set: { presented in
            if presented { selectedLensID = lensID }
            else if selectedLensID == lensID { selectedLensID = nil }
        }
    }
}
