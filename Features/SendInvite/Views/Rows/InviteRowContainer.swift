//
//  InviteRowContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 02/07/2026.
//

import SwiftUI

struct InviteRowContainer: View {
    
    let rowHeight: CGFloat = 80
    
    @Bindable var ui: TimeAndPlaceUIState
    @Binding var draft: EventFieldsDraft
    
    var body: some View {
        VStack(spacing: 0) {
            InviteTypeRow(ui: ui, type: $draft.type, unparsedMessage: $draft.message)
                .frame(height: rowHeight)
            LightDivider()
            InviteTimeRow(ui: ui, proposedTimes: $draft.time)
                .frame(height: rowHeight)
            LightDivider()
            InvitePlaceRow(ui: ui, eventLocation: $draft.place)
                .frame(height: rowHeight)
        }
        .zIndex(1)
    }
}
