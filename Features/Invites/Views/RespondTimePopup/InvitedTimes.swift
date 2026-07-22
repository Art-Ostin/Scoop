//
//  InvitedTimes.swift
//  Scoop Test
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
            ForEach(Array(orderedTimes.enumerated()), id: \.offset) { idx, time in
                inviteTimeCell(idx, time)
            }
        }
    }
}

extension InvitedTimes {
    
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
    
    //A time might be unavailable either because other user has new commitment or it has expired, this function checks for both
    private func getTimeStatus(_ time: ProposedTime) -> TimeStatus {
        if !time.stillAvailable {
            //1. If it more than six hours in future and not availble it means new commitment. If less than this it was expired.
            if time.date > Date.now.addingTimeInterval(6 * 60 * 60) {
                return .unavailable
            } else {
                return .expired
            }
        }
        return .available
    }
}

enum TimeStatus: String {
    case available, unavailable, expired
}
