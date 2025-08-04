//
//  SendInviteViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation

@Observable final class SendInviteViewModel {
    
    
    var manager = EventManager()
    
    
    var event: Event
    
    init(profile1: UserProfile, profile2: UserProfile) {
        self.event = Event(from: <#any Decoder#>, profile: profile1, profile2: profile2)
    }
    
    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
    
}
