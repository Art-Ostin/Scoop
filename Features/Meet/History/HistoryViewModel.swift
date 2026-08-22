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
    
    var sentInvites: [EventProfile] {
        session.sentInvites
    }
    
    var imageLoader: ImageLoading { session.imageLoader }
    var defaults: DefaultsManaging { session.defaultsManager }

    var profileImages: [String: [UIImage]] = [:]

    func loadProfileImages(_ profile: UserProfile) async {
        profileImages[profile.id] = await imageLoader.loadProfileImages(profile)
    }
}

///Ephemeral view state for the History screen. A class so the per-frame pager-progress writes
///invalidate only the views that READ them (the indicator leaf) — progress as @State on the
///container would re-render the whole screen every frame of a drag, re-handing
///ZoomNavigationStack's hosted tree mid-settle (the snap HistoryPager exists to prevent).
@Observable
final class HistoryUIState {
    ///0 at the declines page → 1 at the invites page, written every frame of a drag or settle
    var pagerProgress: Double = 0

    //The icon slots, measured in the selection row's named space — the indicator's two anchors
    var declineIconFrame: CGRect = .zero
    var inviteIconFrame: CGRect = .zero
}
