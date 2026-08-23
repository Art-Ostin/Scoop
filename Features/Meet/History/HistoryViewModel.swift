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
    var invitesByDay: [InviteDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var byDay: [Date: [(at: Date, invite: EventProfile)]] = [:]
        
        for invite in sentInvites {
            for date in invite.event.proposedTimes.availableDates() {
                let day = calendar.startOfDay(for: date)
                guard day > today else { continue } //Matches removePastDays: today is already spent
                
                byDay[day, default: []].append((at: date, invite: invite))
            }
        }
        
        return byDay
            .map { day, proposals in
                //The proposed hour sorts within its day; the tuple never escapes this function,
                //so it can carry a time the section model has no use for.
                InviteDay(day: day, invites: proposals.sorted { $0.at < $1.at }.map(\.invite))
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
    let invites: [EventProfile]
    var id: Date { day }
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
