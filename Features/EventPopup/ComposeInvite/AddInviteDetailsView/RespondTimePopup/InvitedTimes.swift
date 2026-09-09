//
//  InvitedTimes.swift
//  Scoop
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct InvitedTimes: View {
    
    let proposedTimes: ProposedTimes
    
    @Binding var selectedDay: Date?
    @Binding var respondType: ResponseType
    
    var orderedTimes: [ProposedTime] {
        proposedTimes.dates.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if orderedTimes.isEmpty {
                emptyState
            } else {
                ForEach(Array(orderedTimes.enumerated()), id: \.offset) { idx, time in
                    inviteTimeCell(idx, time)
                }
            }
        }
    }
}

extension InvitedTimes {

    private var emptyState: some View {
        Text("This invite has no times on it — suggest one instead.")
            .font(.body(15, .regular))
            .foregroundStyle(Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Spacing.lg)
    }

    private func inviteTimeCell(_ idx: Int, _ time: ProposedTime) -> some View {
        let status = getTimeStatus(time)
        return InvitedTimeCell(
            selectedDay: $selectedDay,
            responseType: $respondType,
            status: status,
            date: time.date,
            idx: idx
        )
    }
    
    //A time might be unavailable either because other user has new commitment or it has expired,
    //this function checks for both. The set of days it calls available is `isSelectable`'s, so the
    //status a cell draws and the day the draft selects can't disagree.
    private func getTimeStatus(_ time: ProposedTime) -> TimeStatus {
        guard !proposedTimes.isSelectable(time.date) else { return .available }
        //A day the other user took back reads "Unavailable"; one only the clock ruled out is "Expired".
        return time.stillAvailable ? .expired : .unavailable
    }
}

enum TimeStatus: String {
    case available, unavailable, expired
}
