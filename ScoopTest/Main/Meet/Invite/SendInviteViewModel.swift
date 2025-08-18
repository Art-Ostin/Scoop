//
//  SendInviteViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation

@Observable final class SendInviteViewModel {
    
    let recipient: UserProfile
    let dep: AppDependencies
    var event: Event
    

    init(recipient: UserProfile, dep: AppDependencies) {
        self.recipient = recipient
        self.dep = dep
        self.event = Event(recipientId: recipient.id)
    }
    
    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
    
    func sendInvite() async throws {
        try await dep.cycleManager.inviteSent(profileId: recipient.userId)
        try await dep.eventManager.createEvent(event: event)
    }
}
