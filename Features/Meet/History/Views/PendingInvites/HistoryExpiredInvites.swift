//
//  HistoryExpiredInvites.swift
//  Scoop
//
//  Created by Art Ostin on 16/09/2026.
//

import SwiftUI

//Meet's expired invites: five avatars to a row, a full row spanning the whole column — the first
//on the calendar card's leading edge, the fifth on its trailing edge — and a short row filling from
//the leading edge. No padding of its own: the owner lines it up with the card above it
struct HistoryExpiredInvites: View {

    //Injected
    let expiredInvites: [EventProfile]
    let card: (EventProfile) -> AnyView //The same sent-invite card the pending calendar opens

    //Local view state
    @State private var selectedLensID: String? //Which avatar's card is open
    @State private var width: CGFloat = 0 //The column's own, measured: the gap is whatever five avatars leave of it

    private static let perRow = 5

    //Geometry: spreads five 54pt avatars edge to edge — 25pt on a 402pt phone, 18pt on the smallest.
    //Spacing.md until the column is measured
    private var gap: CGFloat {
        let slack = width - CGFloat(Self.perRow) * AvatarFace.lensFrame
        return slack > 0 ? slack / CGFloat(Self.perRow - 1) : Spacing.md
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(AvatarFace.lensFrame), spacing: gap), count: Self.perRow)

        LazyVGrid(columns: columns, alignment: .leading, spacing: gap) { //Rows as far apart as columns: an even lattice
            ForEach(expiredInvites) { invite in
                avatarButton(invite: invite)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) //The grid centres its fixed columns: pin them leading, a short last row included
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }
}

//Views
extension HistoryExpiredInvites {

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
