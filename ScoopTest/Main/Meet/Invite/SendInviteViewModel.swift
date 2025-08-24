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

    var event: Event
    
    init(eventManager: EventManager, cycleManager: CycleManager, profileModel: ProfileModel, sessionManager: SessionManager) {
        self.eventManager = eventManager
        self.cycleManager = cycleManager
        self.profileModel = profileModel
        self.sessionManager = sessionManager
        self.event = Event(recipientId: profileModel.profile.id)
    }
    
    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
    
    
    func sendInvite() async throws {
        let user = await sessionManager.user
        let cycle = await sessionManager.activeCycle
        guard let profileId = event.recipientId else {return}
        cycleManager.inviteSent(userId: user.id, cycle: cycle, profileId: profileId)
        await sessionManager.loadProfiles()
        Task { try await eventManager.createEvent(event: event, currentUser: user) ; print("Finished task") }
        print("Finished function ")
    }
    
    func acceptInvite(eventId: String) async throws {
        try await eventManager.updateStatus(eventId: eventId, to: .accepted)
    }
}
