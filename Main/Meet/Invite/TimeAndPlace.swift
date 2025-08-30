//
//  SendInviteViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation

@Observable final class InviteViewModel {
    
    let eventManager: EventManager
    let cycleManager: CycleManager
    let profileModel: ProfileModel
    let sessionManager: SessionManager
    let userManager: UserManager
    
    var event: EventDraft
    
    var receivedEvent: Event?
    
    init(eventManager: EventManager, cycleManager: CycleManager, profileModel: ProfileModel, sessionManager: SessionManager, userManager: UserManager) {
        self.eventManager = eventManager
        self.cycleManager = cycleManager
        self.profileModel = profileModel
        self.userManager = userManager
        self.sessionManager = sessionManager
        self.event = EventDraft()
    }
    
    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
    
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
    
    
    
    func saveIdealMeetUp(event: EventDraft) async throws {
        guard
            let time = event.time,
            let place = event.location,
            let type = event.type,
            let message = event.message
        else { return }
        
        let idealMeetUp = IdealMeetUp(time: time, place: place, type: type, message: message)
        try await userManager.updateUser(values: [UserProfile.Field.idealMeetUp : idealMeetUp])
    }
}
