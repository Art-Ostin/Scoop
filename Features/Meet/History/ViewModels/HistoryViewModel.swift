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
    
    var activePendingInviteCount: Int {
        sentInvites.count - expiredInvites.count
    }
    
    var invitesByDay: [InviteDay] {
        let calendar = Calendar.current
        let now = Date()
        
        var byDay: [Date: [PendingInvite]] = [:]
        
        for invite in sentInvites {
            for time in invite.event.proposedTimes.acceptableTimes(asOf: now) {
                let day = calendar.startOfDay(for: time.date)
                
                byDay[day, default: []].append(PendingInvite(day: day, invite: invite, time: time))
            }
        }
        
        return byDay
            .map { day, proposals in
                //The proposed hour sorts within its day
                InviteDay(day: day, invites: proposals.sorted { $0.time.date < $1.time.date })
            }
            .sorted { $0.day < $1.day }
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
    
    
    
    var imageLoader: ImageLoading { session.imageLoader }
    var defaults: DefaultsManaging { session.defaultsManager }

    var profileImages: [String: [UIImage]] = [:]

    func loadProfileImages(_ profile: UserProfile) async {
        profileImages[profile.id] = await imageLoader.loadProfileImages(profile)
    }
}

//For each day Invited
struct InviteDay: Identifiable {
    let day: Date
    let invites: [PendingInvite]
    var id: Date { day }
    var isToday: Bool { Calendar.current.isDateInToday(day) }
    var hasMultipleInvites: Bool { invites.count > 1 }
}

struct PendingInvite: Identifiable {
    let day: Date //Start of day — the section this card sits under
    let invite: EventProfile
    let time: ProposedTime

    var id: InviteCardID { InviteCardID(day: day, inviteID: invite.id) }
}

//One card is one invite under one day. An invite proposing three days draws three cards,
struct InviteCardID: Hashable {
    let day: Date
    let inviteID: String
}

//A pending card is one invite under one day; an expired one has no day left to sit under, so
//the two can't share an id. Held as one value so only ever one card is open on the screen.
enum ExpandedCard: Hashable {
    case pending(InviteCardID)
    case expired(String) //EventProfile.id
}


@Observable
final class HistoryUIState {
    var pagerProgress: Double = 0

    //The one card showing its message — held here so opening a card closes whichever other
    //card was open, in either section.
    var expandedInvite: ExpandedCard?

    //Shut on arrival: these invites have already been seen once. Held here rather than in the
    //view so the container, which owns the scroll, can follow the reveal down it.
    var showsExpired = false

    //Indexed by page, not named by content: the underline reads position 0 → position 1, so
    //reordering the pager means reordering the icons and nothing else.
    var pageIconFrames: [CGRect] = [.zero, .zero]
}
