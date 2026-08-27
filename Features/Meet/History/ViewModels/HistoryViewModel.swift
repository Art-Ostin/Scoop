//
//  HistoryViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 20/08/2026.
//

import SwiftUI


@Observable
@MainActor
final class HistoryViewModel {
    
    
    private var session: Session
    
    init(session: Session) {
        self.session = session
    }
    
    //The windowed list, not the raw store: profiles drop off once they're over 5 days old
    var declines: [DeclinedProfile] {
        session.recentlyDeclinedProfiles
    }
    
    var sentInvites: [EventProfile] {
        session.sentInvites
    }
    
    //Every invite still awaiting a reply, one row each — an invite proposing three days is one
    //invite, and the days it offered are spelled out in the row it opens. Soonest acceptable
    //day first, the order the day sections used to give them. The exact complement of
    //expiredInvites: an invite with no acceptable time left is what isExpired reports.
    var activeInvites: [EventProfile] {
        let now = Date()

        return sentInvites
            .compactMap { invite -> (invite: EventProfile, soonest: Date)? in
                guard let soonest = invite.event.proposedTimes.acceptableTimes(asOf: now).first?.date else { return nil }
                return (invite, soonest)
            }
            .sorted { $0.soonest < $1.soonest }
            .map(\.invite)
    }
    
    //Most recently lapsed first: sentInvites arrives in profile-load order, which is whichever
    //fetch finished first and reshuffles every launch — the section reads back two months, so
    //an arbitrary order reads as a list with things missing from it.
    var expiredInvites: [EventProfile] {
        let now = Date()

        return sentInvites
            .filter { $0.event.proposedTimes.isExpired(asOf: now) }
            .sorted { $0.event.proposedTimes.lastProposedDate > $1.event.proposedTimes.lastProposedDate }
    }
    
    
    
    //The same live invites bucketed by the days they propose — one row per day, not per invite:
    //an invite offering three days appears under all three. Built off activeInvites so the
    //calendar and the list beneath it split on the one acceptableTimes predicate; a day can
    //never show here whose invite the section below calls expired.
    var invitedDays: [InviteDay] {
        let calendar = Calendar.current
        let now = Date()

        var byDay: [Date: [(time: Date, invite: EventProfile)]] = [:]

        for invite in activeInvites {
            for time in invite.event.proposedTimes.acceptableTimes(asOf: now) {
                //Keyed by start of day: 19:00 and 21:30 on the 7th are one row, not two
                let day = calendar.startOfDay(for: time.date)
                byDay[day, default: []].append((time.date, invite))
            }
        }

        return byDay
            .map { day, entries in
                //The proposed hour orders within its day; a dictionary has no order of its own,
                //so without the outer sort the list reshuffles on every read.
                InviteDay(day: day, invites: entries.sorted { $0.time < $1.time }.map(\.invite))
            }
            .sorted { $0.day < $1.day }
    }
    
    
    var imageLoader: ImageLoading { session.imageLoader }
    var defaults: DefaultsManaging { session.defaultsManager }

    var profileImages: [String: [UIImage]] = [:]

    func loadProfileImages(_ profile: UserProfile) async {
        profileImages[profile.id] = await imageLoader.loadProfileImages(profile)
    }
}


//One row of the calendar: a day, and everyone you invited on it. Just the profiles — the
//hour they were invited at already ordered them, and the row shows faces, not times.
struct InviteDay: Identifiable {
    let day: Date //Start of day — the bucket key and the row's label
    let invites: [EventProfile]

    var id: Date { day }
}


@Observable
final class HistoryUIState {
    var pagerProgress: Double = 0

    //The one card showing its message, named by its invite id — held here so opening a card
    //closes whichever other card was open, in either section. Pending and expired are
    //complements, so one id can only ever name a card in one of the two.
    var expandedInvite: String?

    //Shut on arrival: these invites have already been seen once. Held here rather than in the
    //view so the container, which owns the scroll, can follow the reveal down it.
    var showsExpired = false

    //Indexed by page, not named by content: the underline reads position 0 → position 1, so
    //reordering the pager means reordering the icons and nothing else.
    var pageIconFrames: [CGRect] = [.zero, .zero]
}
