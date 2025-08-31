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

@MainActor
@Observable class ProfileViewModel {
    
    let cacheManager: CacheManaging
    let sessionManager: SessionManager
    let cycleManager: CycleManager
    let eventManager: EventManager
    
    
    let profileModel: ProfileModel
    
    var showInvitePopup: Bool = false
    var receivedEvent: UserEvent? { profileModel.event}
    
    var event: EventDraft
    
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
    
    func sendInvite() async throws {
        let user = sessionManager.user
        cycleManager.inviteSent(userId: user.id, cycle: sessionManager.activeCycle, profileId: profileModel.profile.id)
        Task { try await eventManager.createEvent(draft: event, user: user, profile: profileModel.profile) ; print("Finished task") }
    }
    
    func acceptInvite() async throws {
        guard let event = profileModel.event, let id = event.id else { return }
        try await eventManager.updateStatus(eventId: id, to: .accepted)
    }
}
