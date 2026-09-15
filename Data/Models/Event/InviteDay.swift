//
//  InviteDay.swift
//  Scoop
//
//  Created by Art Ostin on 14/09/2026.
//

import SwiftUI

struct InviteDay: Identifiable {
    let day: Date //Start of day — the bucket key and the row's label
    let invites: [EventProfile]

    var id: Date { day }
}



//Functions that can be applied to EventProfile array
extension Array where Element == EventProfile {
    
    
    func expired(asOf now: Date = .now) -> [EventProfile] {
        filter { $0.event.proposedTimes.isExpired(asOf: now) }
            .sorted { $0.event.proposedTimes.lastProposedDate > $1.event.proposedTimes.lastProposedDate }
    }
    
    //One row per day an invite can still be accepted on; an expired invite adds no days, so no pre-filter
    func invitedDays(asOf now: Date = .now) -> [InviteDay] {
        let calendar = Calendar.current
        var byDay: [Date: [(time: Date, invite: EventProfile)]] = [:]

        for invite in self {
            for time in invite.event.proposedTimes.acceptableTimes(asOf: now) {
                //Keyed by start of day: 19:00 and 21:30 on the 7th are one row, not two
                byDay[calendar.startOfDay(for: time.date), default: []].append((time.date, invite))
            }
        }
        return byDay
            .map { day, entries in
                let ordered = entries.sorted { $0.time < $1.time }.map(\.invite)
                var seen = Set<String>()
                return InviteDay(day: day, invites: ordered.filter { seen.insert($0.id).inserted })
            }
            .sorted { $0.day < $1.day }
    }
}
