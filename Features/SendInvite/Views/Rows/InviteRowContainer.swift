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

    private var emptyPlaceBottomAdjustment: CGFloat {
        draft.place == nil ? Spacing.xs - Spacing.hairline : 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            InviteTypeRow(ui: ui, type: $draft.type, unparsedMessage: $draft.message, showMessageScreen: $showMessageScreen)
            InviteTimeRow(ui: ui, proposedTimes: $draft.time)
            InvitePlaceRow(ui: ui, eventLocation: $draft.place)
        }
        .padding(.top, Spacing.hairline)
        .padding(.bottom, emptyPlaceBottomAdjustment)
        .zIndex(1)
    }
}
