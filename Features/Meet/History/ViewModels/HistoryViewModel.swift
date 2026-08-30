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
    
    var expiredInvites: [EventProfile] {
        let now = Date()

        return sentInvites
            .filter { $0.event.proposedTimes.isExpired(asOf: now) }
            .sorted { $0.event.proposedTimes.lastProposedDate > $1.event.proposedTimes.lastProposedDate }
    }
    
    
    
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
                let ordered = entries.sorted { $0.time < $1.time }.map(\.invite)
                var seen = Set<String>()
                return InviteDay(day: day, invites: ordered.filter { seen.insert($0.id).inserted })
            }
            .sorted { $0.day < $1.day }
    }
    
    
    var imageLoader: ImageLoading { session.imageLoader }
    var defaults: DefaultsManaging { session.defaultsManager }

    var profileImages: [String: [UIImage]] = [:]

    func loadProfileImages(_ profile: UserProfile) async {
        profileImages[profile.id] = await imageLoader.loadProfileImages(profile)
    }

    //The invite's own card image stands in until that profile's full set has loaded, so a
    //detail opened the instant the page appears never shows an empty pager
    func images(for invite: EventProfile) -> [UIImage] {
        let loaded = profileImages[invite.profile.id] ?? []
        return loaded.isEmpty ? invite.image.map { [$0] } ?? [] : loaded
    }
}


struct InviteDay: Identifiable {
    let day: Date //Start of day — the bucket key and the row's label
    let invites: [EventProfile]

    var id: Date { day }
}


@Observable
final class HistoryUIState {
    var pagerProgress: Double = 0

    ///The invite whose detail card is open over the page — nil when the ledger is at rest
    var selectedPending: EventProfile?

    ///The tapped lens' face circle in global space — the flight's home, captured at the tap
    var pendingSource: CGRect = .zero

    ///The invite whose lenses ring together after its card closes — the echo's teaching beat
    var pulsedInvite: String?

    var expandedInvite: String?

    var expandedExpired: String?

    var showsExpired = false

    var pageIconFrames: [CGRect] = [.zero, .zero]
}
