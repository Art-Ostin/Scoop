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
    
    
    var expiredInvites: [EventProfile] { sentInvites.expired() }

    var invitedDays: [InviteDay] { sentInvites.invitedDays() }

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
