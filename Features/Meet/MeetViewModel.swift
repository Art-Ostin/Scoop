//
//  MeetViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 17/08/2025.

import Foundation
import UIKit
import FirebaseFirestore
import SwiftUI

@MainActor
@Observable final class MeetViewModel {

    //Injected
    let session: Session
    let defaults: DefaultsManaging
    let userRepo: UserRepository
    let profileRepo: ProfilesRepository
    let eventRepo: EventsRepository
    let imageLoader: ImageLoading

    //Cached profile images
    var profileImages: [String: [UIImage]] = [:]

    init(session: Session, defaults: DefaultsManaging, userRepo: UserRepository, profileRepo: ProfilesRepository, eventRepo: EventsRepository, imageLoader: ImageLoading) {
        self.session = session
        self.defaults = defaults
        self.userRepo = userRepo
        self.profileRepo = profileRepo
        self.eventRepo = eventRepo
        self.imageLoader = imageLoader
    }

    var profiles: [PendingProfile] { session.profiles }
    var pendingInvites: [PendingProfile] { session.profiles } // TODO: back with real pending invites
    var user: UserProfile { session.user }
    
    func sendInvite(event: EventFieldsDraft, profile: UserProfile) async throws {
        try await profileRepo.updateProfileRec(userId: user.id, profileId: profile.id, status: .invited)
        try await eventRepo.createEvent(draft: event, user: user, profile: profile)
        defaults.deleteEventDraft(profileId: profile.id)
    }
    
    func declineProfile(profile: UserProfile) async throws {
        try await profileRepo.updateProfileRec(userId: user.id, profileId: profile.id, status: .declined)
        defaults.deleteEventDraft(profileId: profile.id)
    }
    
    func fetchImage(url: URL) async throws -> UIImage {
        try await imageLoader.fetchImage(for: url)
    }
    
    func loadProfileImages(profile: UserProfile) async {
        profileImages[profile.id] = await imageLoader.loadProfileImages(profile)
    }
}

@Observable final class MeetUIState {
    var openProfile: UserProfile? = nil
    var quickInvite: PendingProfile? //Mounted quick-invite card; nil only once the close flight lands
    var quickInviteImage: UIImage?
    var quickInviteSource: CGRect = .zero //Profile card image frame the flight departs from and returns to
    var quickInviteExpanded = false //Drives the open/close flight (see SendInviteCard)
    var quickInviteDismissProgress: Double = 0 //Swipe-dismiss collapse 0→1; fades the meet list back in behind the dragged card
    var showPendingInvites = false
    var showInfo: Bool = false
    var openPastInvites = false
    var respondedToProfile: ProfileResponse?
}
