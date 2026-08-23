//
//  HistoryViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 20/08/2026.
//

import SwiftUI


@Observable
@MainActor
class HistoryViewModel {
    
    
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
    
    //Sent invites bucketed by the days they propose. An invite offering three days appears under
    //all three, as a separate card each time — availableTimes() rather than availableDates() so
    //each card keeps the option number the recipient sees for that day.
    var invitesByDay: [InviteDay] {
        let calendar = Calendar.current
        let now = Date()
        
        var byDay: [Date: [PendingInvite]] = [:]
        
        for invite in sentInvites {
            for time in invite.event.proposedTimes.availableTimes() {
                //A proposal is live until its own moment passes, matching removePastTimes and
                //UserEvent.isLiveSentInvite. Today counts — its section header reads "Today".
                guard time.date > now else { continue }
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
}

//One card: one invite under one of the days it proposes, carrying that day's proposed time.
//The EventProfile alone can't say which — a three-day invite draws three cards out of one.
struct PendingInvite: Identifiable {
    let day: Date //Start of day — the section this card sits under
    let invite: EventProfile
    let time: ProposedTime

    var id: InviteCardID { InviteCardID(day: day, inviteID: invite.id) }
}

//One card is one invite under one day. An invite proposing three days draws three cards,
//so the invite id alone can't tell them apart — ProposedTimes.updateDate keeps it to one
//time per day, which is what makes the pair unique.
struct InviteCardID: Hashable {
    let day: Date
    let inviteID: String
}


@Observable
final class HistoryUIState {
    var pagerProgress: Double = 0

    //The one card showing its message. Held here rather than per-card so the invite's other
    //days can see it and stand their chevrons down.
    var expandedInvite: InviteCardID?

    //Indexed by page, not named by content: the underline reads position 0 → position 1, so
    //reordering the pager means reordering the icons and nothing else.
    var pageIconFrames: [CGRect] = [.zero, .zero]
}
