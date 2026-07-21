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
    @Binding var showMessageScreen: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            InviteTypeRow(ui: ui, type: $draft.type, unparsedMessage: $draft.message, showMessageScreen: $showMessageScreen)
            InviteTimeRow(ui: ui, proposedTimes: $draft.time)
            InvitePlaceRow(ui: ui, eventLocation: $draft.place)
        }
        .zIndex(1)
    }
}
