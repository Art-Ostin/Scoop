//
//  ProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/08/2025.
//
import Foundation
import SwiftUI


enum ProfileViewType {
    case invite, accept, view
}


@Observable class ProfileViewModel {
    
    let cacheManager: CacheManaging
    let profileModel: ProfileModel
    
    
    var showInvitePopup: Bool = false
    
    var viewProfileType: ProfileViewType {
        if profileModel.event?.status == .accepted {
            return .view
        } else if profileModel.event?.status == .pending {
            return .accept
        } else {
            return .invite
        }
    }
    
    init(profileModel: ProfileModel, cacheManager: CacheManaging) {
        self.profileModel = profileModel
        self.cacheManager = cacheManager
    }
    
    func loadImages() async -> [UIImage] {
        return await cacheManager.loadProfileImages([profileModel.profile])
    }
    
    
    
    
    func sendInvite(profileId: String) async throws {
        let user = await sessionManager.user
        let cycle = await sessionManager.activeCycle
        cycleManager.inviteSent(userId: user.id, cycle: cycle, profileId: profileId)
        print("invite sent")
        Task { try await eventManager.createEvent(draft: event, user: user, profile: profileModel.profile) ; print("Finished task") }
    }
    
    
    func acceptInvite(eventId: String) async throws {
        try await eventManager.updateStatus(eventId: eventId, to: .accepted)
    }
    
    var event: EventDraft
    
    var receivedEvent: Event?
}
