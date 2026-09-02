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

    //An invite can arrive with no days on it (its times were replaced with an empty set).
    //Without a body here the page measures 0pt and the pager falls back to the taller
    //new-time page's height, so the popup reads as broken rather than empty.
    private var emptyState: some View {
        Text("This invite has no times on it — suggest one instead.")
            .font(.body(14, .regular))
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
