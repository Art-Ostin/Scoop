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
    
    
    func addUserEvent() {
        let recipientId = recipient.id
        let inviteeId = dep.userManager.user?.userId ?? ""
        
        let eventId = event.id ?? ""
        
        Task {
            try? await dep.profileManager.addUserEvent(userId: recipientId, eventId: eventId)
            try? await dep.profileManager.addUserEvent(userId: inviteeId, eventId: eventId)

        }
    }
    
    
    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
}
