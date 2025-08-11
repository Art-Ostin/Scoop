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
    
    var event: Event {
        event.recipientId = p.userId
    }

    init(recipient: UserProfile, dep: AppDependencies) {
        self.recipient = recipient
        self.dep = dep
    }
    
    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
}
