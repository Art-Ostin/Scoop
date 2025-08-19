//
//  SendInviteViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation

@Observable final class SendInviteViewModel {
    

    let eventManager: EventManager
    let cycleManager: CycleManager
    
    let recipient: UserProfile
    var event: Event
    
    init(eventManager: EventManager, cycleManager: CycleManager, recipient: UserProfile) {
        self.eventManager = eventManager
        self.cycleManager = cycleManager
        self.recipient = recipient
        self.event = Event(recipientId: recipient.id)
    }
    
    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
    
    
    func sendInvite() async throws {
        try await cycleManager.inviteSent(profileId: recipient.userId)
        try await eventManager.createEvent(event: event)
    }
    
    func acceptInvite(eventId: String) async throws {
        try await eventManager.updateStatus(eventId: eventId, to: .accepted)
    }
}
