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
    
    //Declined profiles and declined invites in one list, oldest decline first. Each drops off when its own window closes
    var declines: [DeclinedProfile] {
        let invites = session.declinedEvents
            .compactMap(DeclinedProfile.init(invite:))
            .filter { $0.expiresAt > .now }
        return (session.recentlyDeclinedProfiles + invites).sorted { $0.declinedAt < $1.declinedAt }
    }
    
    var sentInvites: [EventProfile] {
        session.sentInvites
    }
    
    
    var expiredInvites: [EventProfile] { sentInvites.expired() }

    var invitedDays: [InviteDay] { sentInvites.invitedDays() }
    
    //Accepted events from today on, for the pending calendar's meeting rows. `session.events` keeps
    //an accepted event after its day has passed, and a past one would hold the page out of its empty state
    var upcomingEvents: [EventProfile] {
        let today = Calendar.current.startOfDay(for: .now)
        return session.events.filter { ($0.event.acceptedTime ?? .distantPast) >= today }
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

@Observable
final class HistoryUIState {
    var pagerProgress: Double = 0

    var expandedInvite: String?

    var expandedExpired: String?

    var showsExpired = false

    var pageIconFrames: [CGRect] = [.zero, .zero]
}
