//
//  HistoryViewModel.swift
//  Scoop Test
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

    var imageLoader: ImageLoading { session.imageLoader }
    var defaults: DefaultsManaging { session.defaultsManager }

    //The zoom hero's pager is built ONCE from the images handed to `.zoomTransition`, so the full
    //set has to exist before the tap — ProfileContainer's own late load fills the thumbnail strip
    //but can never add a page to the flight. Cached here rather than on the card: LazyVGrid
    //recycles cells, and card-local state would fall back to one image on re-mount.
    var profileImages: [String: [UIImage]] = [:]

    func loadProfileImages(_ profile: UserProfile) async {
        profileImages[profile.id] = await imageLoader.loadProfileImages(profile)
    }
}

