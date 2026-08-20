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
    var declinedProfiles: [PendingProfile] {session.profiles}
    var pendingInvites: [PendingProfile] { session.profiles } // TODO: back with real pending invites
    var user: UserProfile { session.user }
    
    func sendInvite(event: EventFieldsDraft, profile: UserProfile) async throws {
        try await profileRepo.updateProfileRec(userId: user.id, profileId: profile.id, status: .invited)
        try await eventRepo.createEvent(draft: event, user: user, profile: profile)
        defaults.deleteEventDraft(profileId: profile.id)
    }
    
    func declineProfile(profile: UserProfile) async throws {
        //Update its status to declined, in firebase -> listener removes it from the 'Meet' section
        try await profileRepo.updateProfileRec(userId: user.id, profileId: profile.id, status: .declined)
        //Adds it to the 'declineProfile' list
        session.declineProfile(id: profile.id)
        //Delete any eventDraft that was stored on defaults (as that persists between sessions)
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
    var showPendingInvites = false
    var showInfo: Bool = false
    var openPastInvites = false
    var showInvite: PendingProfile?
    var titleTravel: CGFloat = 0   //How far the large title has risen; the ⓘ beside it rides this


    //Custom Binding so can be a bool in the InviteView, but a PendingProfile? in Meet container
    func showInviteBinding(profile: PendingProfile) -> Binding<Bool> {
        Binding {
            self.showInvite?.id == profile.id
        } set: { isPresented in
            if isPresented {
                self.showInvite = profile
            } else if self.showInvite?.id == profile.id {
                self.showInvite = nil
            }
        }
    }
}
