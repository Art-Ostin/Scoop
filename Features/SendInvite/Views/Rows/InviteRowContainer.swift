//
//  InviteRowContainer.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2026.
//

import SwiftUI

struct InviteRowContainer: View {

    @Bindable var ui: TimeAndPlaceUIState
    @Binding var draft: EventFieldsDraft
    
    var body: some View {
        VStack(spacing: 0) {
            InviteTypeRow(ui: ui, type: $draft.type, unparsedMessage: $draft.message)
            LightDivider()
            InviteTimeRow(ui: ui, proposedTimes: $draft.time)
            LightDivider()
            InvitePlaceRow(ui: ui, eventLocation: $draft.place)
        }
        .zIndex(1)
    }
}
