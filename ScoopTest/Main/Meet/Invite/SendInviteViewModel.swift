//
//  SendInviteViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation

@Observable final class SendInviteViewModel {
        
    var event: Event
    
    let profile2: UserProfile?
    
    init(profile1: String, profile2: UserProfile) {
        self.event = Event(profile1_id: profile1, profile2_id: profile2.userId)
        self.profile2 = profile2
    }
    
    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
}
