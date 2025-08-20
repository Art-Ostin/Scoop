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
    let sessionManager: SessionManager
    let profileModel: ProfileModel

    var event: Event
    
    init(eventManager: EventManager, cycleManager: CycleManager, sessionManager: SessionManager, profileModel: ProfileModel) {
        self.eventManager = eventManager
        self.cycleManager = cycleManager
        self.sessionManager = sessionManager
        self.profileModel = profileModel
        self.event = Event(recipientId: profileModel.profile.id)
    }
    
    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
    
    
    func sendInvite() async throws {
        if let cycleId = sessionManager.activeCycle?.id {
            cycleManager.inviteSent(userId: sessionManager.user.userId, cycleId: cycleId, profileId: profileModel.id)
        }
        try await eventManager.createEvent(event: event, currentUser: sessionManager.user)
    }
    
    func acceptInvite(eventId: String) async throws {
        try await eventManager.updateStatus(eventId: eventId, to: .accepted)
    }
}
